#! /bin/bash -e

# if no display is set
if [ -z "$DISPLAY" ]; then
  # start xvfb in the background (quietly)
  Xvfb :10 -nolisten tcp -screen 10 1600x1200x24 2>/dev/null &

  # for firefox/mulet
  export DISPLAY=:10
fi

# start the shell
$SHELL
