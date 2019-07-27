#!/bin/bash
HQ_CLI=/proxygen/proxygen/_build/proxygen/httpserver/hq
# Set up the routing needed for the simulation
/setup.sh

ROLE=$1
shift

if [ "$ROLE" == "client" ]; then
    echo "Starting QUIC client..."
    ${HQ_CLI} --mode=client --host=server --use_draft=true --draft_version=22 --protocol=h3-22 --port=4433 --path=$(yes '/10000000' | head -n 10 | paste -sd',') --conn_flow_control=1048576 --stream_flow_control=256000 "$@"

elif [ "$ROLE" == "server" ]; then
    echo "Running QUIC server on 0.0.0.0:4433"
    mkdir /logs
    ${HQ_CLI} --mode=server --port=4433 --h2port=4434 --use_draft=true --draft-version=22 --logdir=/logs --host=0.0.0.0 --v=0 "$@"
fi
