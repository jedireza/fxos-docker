# fxos-docker

A development environment for FxOS.


## Host machine

Your host machine is where our code resides and where we make changes to the
code base. It's also the place we execute `git` commands.

### Install `git`

We fetch code using `git`. If you don't have `git` already, you'll need to
install it.

```bash
$ sudo apt-get install git
```

Note: You may need to [setup your `ssh` keys on GitHub too][1].

[1]: https://help.github.com/articles/generating-ssh-keys/

### Fetching the B2G code

First [fork the mozilla/B2G repo][2].

[2]: https://github.com/mozilla-b2g/B2G

Then we clone our fork.

```bash
$ cd ~/projects/
$ git clone git://github.com/<username>/B2G.git
$ cd B2G
```

Next we can add an `upstream` remote:

```bash
$ git remote add upstream https://github.com/mozilla-b2g/B2G
```

### Fetching the Gaia code

First [fork the mozilla/gaia repo][3].

[3]: https://github.com/mozilla-b2g/gaia

Then we clone our fork. (This will take a long time.)

```bash
$ cd ~/projects/
$ git clone git://github.com/<username>/gaia.git
$ cd gaia
```

Next we can add an `upstream` remote:

```bash
$ git remote add upstream https://github.com/mozilla-b2g/gaia
```

### Install `adb` and `fastboot`

Many aspects of FxOS development require using `adb` (Android Debug Bridge) and
`fastboot`.

```bash
$ sudo apt-get install android-tools-adb android-tools-fastboot
```

### `adb` server

Your host machine is also where you should run the `adb` server. This is often
done automatically if you use WebIDE and the ADB Helper plugin. Later we'll
make sure our container shares the host network so it will be able to access
our `adb` server and usb devices too.

```bash
$ adb start-server
* daemon not running. starting it now on port 5037 *
* daemon started successfully *
```

It's ideal to run `adb` without using sudo. One reason is because WebIDE's ADB
Helper Add-on will start a server if there isn't one running and it can't use
`sudo`.  A symptom I've seen with incorrect adb permissions is:

```bash
$ adb devices
List of devices attached 
????????????    no permissions
```

I found one way of fixing this [with this StackOverflow answer][8].

[8]: http://stackoverflow.com/a/12664045


## Build container

The `fxos-docker` image is our build container. We'll be using it to configure,
build and run tests. It's based on the Ubuntu Trusty (14.04) image with [build
prerequisites installed][4].

[4]: https://developer.mozilla.org/en-US/docs/Mozilla/Firefox_OS/Firefox_OS_build_prerequisites

### Interacting

When we connect to the container it needs some important resources.

```bash
$ docker run -it \
    -v ~/projects/B2G:/B2G \
    -v ~/projects/gaia:/gaia \
    -v /dev/bus/usb:/dev/bus/usb \
    -v ~/.ssh:/home/root/.ssh \
    --net=host \
    jedireza/fxos
```

What's happening here?

 - `-v ~/projects/B2G:/B2G` mounts our B2G code directory.
 - `-v ~/projects/gaia:/gaia` mounts our Gaia code directory.
 - `-v /dev/bus/usb:/dev/bus/usb` mounts our usb devices.
 - `-v ~/.ssh:/home/root/.ssh` mounts our ssh keys. Primarily used for fetching
   code using `git`. Your GitHub `ssh` key is the important one.
 - `--net=host` lets the container share the host netowrk. This is important
   for `adb` to see the server we're running on the host machine.

Once you connect, you'll have an interactive terminal that looks something like
this: (where `hostbox` is your machine's name)

```bash
root@hostbox:/#
```


## Working with B2G

Building B2G means building the entire FxOS stack. Configuring the build takes
quite a long time. The first time you build for a device a considerable amount
of time is spent fetching the neccessary code.

### Configure your target

In this example we're configuring for an Aries (Sony Z3C) device.

```bash
root@hostbox:/# cd /B2G
root@hostbox:/B2G# ./config.sh aries
# expect lots of output
```

Note: Depending on your internet connection, the configuration step takes a
number of hours to download the files necessary to build B2G.

For more details see the official MDN docs for ["Preparing for your first B2G
build"][5].

[5]: https://developer.mozilla.org/en-US/docs/Mozilla/Firefox_OS/Preparing_for_your_first_B2G_build

### Time to build

Once the configuration step is done, we can build B2G. You should have your
device plugged in in order for proprietary blobs to be pulled from the device.

```bash
root@hostbox:/B2G# ./build.sh
```

You may see interactive messages like an EULA to download proprietary software
from manufacturers, just follow the instructions.

For more details see the official MDN docs for ["Building Firefox OS"][6].

[6]: https://developer.mozilla.org/en-US/Firefox_OS/Building

### Flash your device

Once the build completes we can flash our device.

```bash
root@hostbox:/B2G# ./flash.sh
```

For more details see the official MDN docs for ["Installing Firefox OS on a
mobile device"][7].

[7]: https://developer.mozilla.org/en-US/Firefox_OS/Installing_on_a_mobile_device


## Working with Gaia

Working with Gaia is usually easier than building the entire B2G stack.

### Running integration tests

Running integration tests inside the container requires us to use `xvfb` as a
display server. So you won't actually see a browser running the tests.

You can run integration tests like this:

```bash
root@hostbox:/gaia# make test-integration
```

This will run all the integration tests, which will take a long time. More
typically you'll just want to run some specific tests, which you can do like
this:

```bash
root@hostbox:/gaia# TEST_FILES="apps/system/test/marionette/apps_test.js" make test-integration

# ... lots of output ... #

mozApps
  getSelf
    ✓ multiple calls should all return


1 passing (16s)
```
