# fxos-docker

A development environment for FxOS.

 - [On Docker Hub](#on-docker-hub)
 - [Host machine](#host-machine)
   - [Install `git`](#install-git)
   - [Fetching the B2G code](#fetching-the-b2g-code)
   - [Fetching the Gaia code](#fetching-the-gaia-code)
   - [Install `adb` and `fastboot`](#install-adb-and-fastboot)
   - [`adb` server](#adb-server)
 - [Development container](#development-container)
   - [Interacting](#interacting)
   - [Connecting visuals](#connecting-visuals)
 - [Working with B2G](#working-with-b2g)
   - [Configure your target](#configure-your-target)
   - [Time to build](#time-to-build)
   - [Flash your device](#flash-your-device)
 - [Working with Gaia](#working-with-gaia)
   - [Running integration tests](#running-integration-tests)
   - [Running unit tests](#running-unit-tests)
     - [The prep work](#the-prep-work)
     - [Multiple ways to run](#multiple-ways-to-run)
   - [Running build tests](#running-build-tests)
   - [Running UI tests](#running-ui-tests)


## On Docker Hub

You can find the [`jedireza/fxos`][11] image on the Docker Hub. And you can pull it via:

[11]: https://hub.docker.com/r/jedireza/fxos/

```bash
$ docker pull jedireza/fxos
```


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
$ git remote add upstream git@github.com:mozilla-b2g/B2G.git
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
$ git remote add upstream git@github.com:mozilla-b2g/gaia.git
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

I found one way of fixing this [by following this StackOverflow answer][8].

[8]: http://stackoverflow.com/a/12664045


## Development container

The `jedireza/fxos` Docker image is our build environment. We'll use it to
configure and build B2G, build Gaia and run tests, as well as flash our device.
It's based on the Ubuntu Trusty (14.04) image with the [build prerequisites
installed][4].

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

### Connecting visuals

You can also connect your local X11 server to the docker image which allows you
to see windows running in the container (if any) on your host machine. For
example you'll see the FxOS Runtime windows open when running integration tests
and also when starting the unit test runner. A great benefit to this is you're
able to interact with the windows like they're running on your host machine.

```bash
$ xhost +
$ docker run -it --rm \
    -v ~/projects/B2G:/B2G \
    -v ~/projects/gaia:/gaia \
    -v /dev/bus/usb:/dev/bus/usb \
    -v ~/.ssh:/home/root/.ssh \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -e DISPLAY=$DISPLAY \
    -e UID=$UID \
    -e GID=$GID \
    --net=host \
    jedireza/fxos
$ xhost -
```

The `xhost` commands:

 - `xhost +` allows all connections to the host machine's X server. There can
   be security implications with such broad access.
 - `xhost -` restricts access to the host machine's X server to only those on
   the access control list.

Differences from our previous `docker run` example:

 - `-v /tmp/.X11-unix:/tmp/.X11-unix` mounts our X server via a unix domain
   socket.
 - `-e DISPLAY=$DISPLAY` sets the `DISPLAY` environment variable to be the same
   as the host machine.
 - `-e UID=$UID` sets the `UID` environment variable to be the same as the host
   machine.
 - `-e GID=$GID` sets the `GID` environment variable to be the same as the host
   machine.

Just like before, once you connect, you'll have an interactive terminal that
looks something like this: (where `hostbox` is your machine's name)

```bash
root@hostbox:/#
```

But now you'll see windows open from within the container. You can test this by
running the FxOS Runtime inside the container like this:

```bash
root@hostbox:/# /gaia/firefox/firefox-bin
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
# ... truncated output ... #
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

Because running integration tests requires a display. When our container is run
it automatically starts up `xvfb` (a display server) and binds it to `:10`
(display 10) and creates the environment variable `DISPLAY=10` (used by the
Firefox binary). Note: You won't actually see a browser running the tests,
`xvfb` is like an in-memory display.

You can run integration tests like this:

```bash
root@hostbox:/gaia# make test-integration
```

This will run all the integration tests, which will take a long time. More
typically you'll just want to run some specific tests, which you can do like
this:

```bash
root@hostbox:/gaia# TEST_FILES="apps/system/test/marionette/apps_test.js" make test-integration

# ... truncated output ... #

mozApps
  getSelf
    ✓ multiple calls should all return


1 passing (16s)
```

For more details see the official MDN docs for ["Gaia Integration tests"][9].

[9]: https://developer.mozilla.org/en-US/docs/Mozilla/Firefox_OS/Automated_testing/Gaia_integration_tests

### Running unit tests

#### The prep work

If you already ran integration tests you probably already have a local copy of
the Firefox (aka Mulet) binary in the `/gaia/firefox` directory. If not, you
can get a copy of Mulet by running:

```bash
root@hostbox:/gaia# make mulet
# ... truncated output ... #
```

Once you have a local Firefox binary you need to export an environment variable
pointing to it:

```bash
root@hostbox:/gaia# export FIREFOX=/gaia/firefox/firefox
```

Running unit tests requires a test server to be running and an instance of the
Firefox binary to be started, this can be done by running:

```bash
root@hostbox:/gaia# ./bin/gaia-test &
# ... truncated output ... #
```

Notice how we sent this process into the background by ending the command with
`&`. This allows us to still enter more commands but still see the output. If
you're not familiar with these concepts search for [manage jobs in linux][13].

[13]: https://www.google.com/search?q=manage+jobs+in+linux

#### Multiple ways to run

Now that we have our test server running there are a couple ways we can run
tests.

Tests will automatically run when you save a file. For example when I save
changes to '/gaia/apps/clock/js/alarm.js' I'll see output from the test server
similar to this:

```bash
root@hostbox:/gaia# Running tests: [ '/clock/test/unit/alarm_test.js' ]
# ... truncated output ... #
[clock-test/unit/alarm_test.js] Alarm Test
[Clock] =====================================

[Clock] Alarm Debug: {"now":"2015-10-14T07:41:20.699Z","tz":0}
    [clock-test/unit/alarm_test.js] Date handling
[Clock] ======= Remaining mozAlarms: ========

[Clock] mozAlarm API invariant failure?
[Clock] -------------------------------------

      ✓ [clock-test/unit/alarm_test.js] basic properties and serialization

  1 passing (188ms)
```

Another way to run tests is by running then manually. Although it will take a
while, you can run all the unit tests like this:

```bash
root@hostbox:/gaia# make test-agent-test
# ... truncated output ... #
```

You can limit the scope of the tests to run by app like this:

```bash
root@hostbox:/gaia# APP=calendar make test-agent-test
# ... truncated output ... #
```

For more details see the official MDN docs for ["Gaia unit tests"][10].

[10]: https://developer.mozilla.org/en-US/docs/Mozilla/Firefox_OS/Automated_testing/Gaia_unit_tests

### Running build tests

You can run the build unit tests like this:

```bash
root@hostbox:/gaia# make build-test-unit
```
You can run the build integration tests like this:

```bash
root@hostbox:/gaia# make build-test-integration
```

Like we've seen before running all the build integration tests can take some
time. We can limit which tests to run using the `TEST_FILES` variable like
this:

```bash
root@hostbox:/gaia# TEST_FILES="apps/keyboard/test/build/integration/keyboard_test.js" make build-test-integration
```

### Running UI tests

Coming soon.
