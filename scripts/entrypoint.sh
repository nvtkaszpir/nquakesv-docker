A#!/bin/bash

#set -e

# ENV Vars used
: ${GENERATE_NQUAKESV:-"true"}
: ${GENERATE_CONFIGS:-"true"}
: ${SV_HOSTNAME:-"KTX Allround"}
: ${SV_SERVERIP:-"0.0.0.0"}
: ${SV_ADMININFO:-"admin@example.com"}
: ${SV_RCON:-""}
: ${SV_QTVPASS:-""}

# generate nquakesv configs
# see https://github.com/nQuake/server-linux/blob/master/scripts/config.example
function generate_nquakesv() {
  if [[ "$GENERATE_NQUAKESV" != "true" ]]; then
    echo "Skipping generating ~/.nquakesv/config"
    return
  fi

  echo "" > ~/.nquakesv/config
  echo "SV_HOSTNAME=\"${SV_HOSTNAME}\"" >> ~/.nquakesv/config
  echo "SV_SERVERIP=\"${SV_SERVERIP}\"" >> ~/.nquakesv/config
  echo "SV_ADMININFO=\"${SV_ADMININFO}\"" >> ~/.nquakesv/config
  echo "SV_RCON=\"${SV_RCON}\"" >> ~/.nquakesv/config
  echo "SV_QTVPASS=\"${SV_QTVPASS}\"" >> ~/.nquakesv/config

  echo "${SV_SERVERIP}" > ~/.nquakesv/ip
  echo "${SV_ADMININFO}" > ~/.nquakesv/admin

}

function generate_configs() {
  if [[ "$GENERATE_CONFIGS" != "true" ]]; then
    echo "Skipping generating service configs"
    return
  fi
  # generate configs only
  ./start_servers.sh --generate-only --regenerate
  cat  ~/ktx/port_${PORT}.cfg
  cat  ~/qtv/qtv.cfg

}


# redirect stdout and stderr to files
exec >/dev/stdout
exec 2>/dev/stderr

# generate required files, for k8s we do not need it, we will use secrets
generate_nquakesv
generate_configs

# spawn specific service if defined

# notice, we spawn only one server in container
if [ "$1" = 'mvdsv' ]; then
    shift
    : ${PORT:-"28501"}
    exec  ./mvdsv -port ${PORT} -game ktx +exec port_${PORT}.cfg $@ &
fi

if [ "$1" = 'qtv' ]; then
    shift
    cd $(cat ~/.nquakesv/install_dir)/qtv/
    exec ./qtv.bin +exec qtv.cfg ${EXTRA_CMD_ARGS} $@ &
fi

if [ "$1" = 'qwfwd' ]; then
    shift
    cd $(cat ~/.nquakesv/install_dir)/qwfwd/
    exec ./qwfwd.bin ${EXTRA_CMD_ARGS} $@ &
fi

pid="$!"

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
