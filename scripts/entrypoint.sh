#!/bin/bash

set -e

# ENV Vars used
: ${SV_HOSTNAME:-"KTX Allround"}
: ${SV_ADMININFO:-"admin@example.com"}
: ${SV_RCON:-""}
: ${SV_QTVPASS:-""}

# generate configs only
./start_servers.sh --generate-only --regenerate

# spawn specific service if defined

if [ "$1" = 'server' ]; then
    : ${PORT:-"28501"}
    exec  ./mvdsv -port ${PORT} -game ktx +exec port_${PORT}.cfg &
fi


if [ "$1" = 'qtv' ]; then
    cd $(cat ~/.nquakesv/install_dir)/qtv/
    exec ./qtv.bin +exec qtv.cfg &
fi

if [ "$1" = 'qwfwd' ]; then
    cd $(cat ~/.nquakesv/install_dir)/qwfwd/
    exec ./qwfwd.bin &
fi

pid="$!"
#trap "kill -SIGTERM $pid" INT TERM


function do_int() {
    echo "Processing SIGINT"
    kill -SIGINT $pid
}

function do_term() {
    echo "Processing SIGTERM"
    kill -SIGTERM $pid
}

trap do_int INT
trap do_term TERM

wait
