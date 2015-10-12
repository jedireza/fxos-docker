#! /bin/bash -e

# start xvfb in the background (quietly)
Xvfb :10 -nolisten tcp -screen 10 1600x1200x24 2>/dev/null &

# for firefox/mulet
export DISPLAY=:10

# start the shell
$SHELL
