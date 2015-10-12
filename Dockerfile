FROM ubuntu:trusty

# the b2g/fxos prereqs
RUN dpkg --add-architecture i386
RUN apt-get update
RUN apt-get install -y --no-install-recommends \
    autoconf2.13 bison bzip2 ccache curl flex gawk \
    gcc g++ g++-multilib gcc-4.7 g++-4.7 g++-4.7-multilib \
    git lib32ncurses5-dev lib32z1-dev libgconf2-dev \
    zlib1g:amd64 zlib1g-dev:amd64 zlib1g:i386 zlib1g-dev:i386 \
    libgl1-mesa-dev libx11-dev make zip libxml2-utils lzop \
    default-jdk wget w3m unzip android-tools-adb xorg openbox \
    python-pip xvfb
RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-4.7 1 \
    && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-4.8 2 \
    && update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-4.7 1 \
    && update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-4.8 2 \
    && update-alternatives --set gcc "/usr/bin/gcc-4.7" \
    && update-alternatives --set g++ "/usr/bin/g++-4.7"

# nvm: replace shell with bash so we can source files
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

# nvm: vars used to install nvm and put that version on our path
ENV NVM_DIR /usr/local/nvm
ENV NODE_VERSION 0.12.7

# nvm: install nvm with node and npm
RUN curl https://raw.githubusercontent.com/creationix/nvm/v0.29.0/install.sh | bash \
    && source $NVM_DIR/nvm.sh \
    && nvm install $NODE_VERSION \
    && nvm alias default $NODE_VERSION \
    && nvm use default

# nvm: set NODE_PATH for nvm and extend our path
ENV NODE_PATH $NVM_DIR/v$NODE_VERSION/lib/node_modules
ENV PATH      $NVM_DIR/v$NODE_VERSION/bin:$PATH

# git will ask who we are
RUN git config --global user.email "fxos@ubuntu-trusty"
RUN git config --global user.name "FxOS"

# setup our entry point
COPY entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]
