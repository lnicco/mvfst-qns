#!/bin/bash
set -x
HQ_CLI=/proxygen/proxygen/_build/proxygen/httpserver/hq
# Set up the routing needed for the simulation
/setup.sh

PORT=443

LOGLEVEL=0

# Unless noted otherwise, test cases use HTTP/0.9 for file transfers.
PROTOCOL="hq-23"
if [ ! -z "${TESTCASE}" ]; then
    case "${TESTCASE}" in
        "handshake") ;;
        "transfer") ;;
        "retry")
            exit 127
            ;;
        "throughput") ;;
        "resumption") ;;
        "http3")
             PROTOCOL="h3-23"
             ;;
        *)
            exit 127
            ;;
    esac
fi

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
            --protocol=${PROTOCOL} \
            --path="${FILES}" \
            --conn_flow_control=107374182 \
            --stream_flow_control=107374182 \
            --outdir=/downloads \
            --logdir=/logs \
            --v=${LOGLEVEL}
    fi

elif [ "$ROLE" == "server" ]; then
    echo "Running QUIC server on 0.0.0.0:${PORT}"
    ${HQ_CLI} \
        --mode=server \
        --port=${PORT} \
        --h2port=${PORT} \
        --protocol=${PROTOCOL} \
        --logdir=/logs \
        --host=server \
        --v=${LOGLEVEL}
fi
