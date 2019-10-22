#!/bin/bash
set -x
HQ_CLI=/proxygen/proxygen/_build/proxygen/httpserver/hq
# Set up the routing needed for the simulation
/setup.sh

PORT=443

LOGLEVEL=0

if [ ! -z "${TESTCASE}" ]; then
    case "${TESTCASE}" in
        "handshake"|"transfer"|"retry"|"throughput") ;;
        "resumption"|"http3") ;;
        *) exit 127 ;;
    esac
fi

mkdir -p /logs/client
mkdir -p /logs/server

if [ "${ROLE}" == "client" ]; then
    sleep 10
    echo "Starting QUIC client..."
    if [ ! -z "${REQUESTS}" ]; then
        FILES=$(echo ${REQUESTS} | tr " " "\n" | awk -F '/' '{ print "/" $4 }' | paste -sd',')
        echo "requesting files '${FILES}'"
        ${HQ_CLI} \
            --mode=client \
            --host=server \
            --port=${PORT} \
            --path="${FILES}" \
            --conn_flow_control=107374182 \
            --stream_flow_control=107374182 \
            --outdir=/downloads \
            --logdir=/logs/client \
            --v=${LOGLEVEL}
    fi

elif [ "$ROLE" == "server" ]; then
    echo "Running QUIC server on 0.0.0.0:${PORT}"
    ${HQ_CLI} \
        --mode=server \
        --port=${PORT} \
        --h2port=${PORT} \
        --logdir=/logs/server \
        --host=server \
        --v=${LOGLEVEL}
fi
