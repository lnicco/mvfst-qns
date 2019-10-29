[qsim] 0:vi*Z 1:bash-Z
#!/bin/bash

# Extra debugging ?
set -x
set -o nounset

DRAFT=23
HQ_CLI=/proxygen/proxygen/_build/proxygen/httpserver/hq
PORT=443
LOGLEVEL=2

# Set up the routing needed for the simulation
/setup.sh

# Unless noted otherwise, test cases use HTTP/0.9 for file transfers.
PROTOCOL="hq-${DRAFT}"
HTTPVERSION="0.9"

# Default enormous flow control.

CONN_FLOW_CONTROL="107374182"
STREAM_FLOW_CONTROL="107374182"
if [ ! -z "${TESTCASE}" ]; then
    case "${TESTCASE}" in
        "handshake") ;;
        "transfer")
            STREAM_FLOW_CONTROL="262144"
            CONN_FLOW_CONTROL="2621440"
            ;;
        "retry")
            exit 127
            ;;
        "throughput") ;;
        "resumption") ;;
        "http3")
             PROTOCOL="h3-${DRAFT}"
             HTTPVERSION="1.1"
             ;;
        *)
            exit 127
            ;;
    esac
fi

if [ "${ROLE}" == "client" ]; then
    # Wait for the simulator to start up.
    /wait-for-it.sh sim:57832 -s -t 10
    echo "Starting QUIC client..."
    if [ ! -z "${REQUESTS}" ]; then
        FILES=$(echo ${REQUESTS} | tr " " "\n" | awk -F '/' '{ print "/" $4 }' | paste -sd',')
        echo "requesting files '${FILES}'"
        ${HQ_CLI} \
            --mode=client \
            --host=server \
            --port=${PORT} \
            --protocol=${PROTOCOL} \
            --httpversion=${HTTPVERSION} \
            --use_draft=true \
            --draft-version=${DRAFT} \
            --path="${FILES}" \
            --conn_flow_control=${CONN_FLOW_CONTROL} \
            --stream_flow_control=${STREAM_FLOW_CONTROL} \
            --outdir=/downloads \
            --logdir=/logs \
            --v=${LOGLEVEL} 2>&1 | tee /logs/client.log
        # This is the best way to troubleshoot.
        # Just uncomment the line below, run the test, then enter containers with
        # docker exec -it [client|server|sim] /bin/bash
        #/bin/bash
    fi

elif [ "$ROLE" == "server" ]; then
    echo "Running QUIC server on 0.0.0.0:${PORT}"
    ${HQ_CLI} \
        --mode=server \
        --port=${PORT} \
        --httpversion=${HTTPVERSION} \
        --h2port=${PORT} \
        --static_root=/www \
        --use_draft=true \
        --draft-version=${DRAFT} \
        --logdir=/logs \
        --host=server \
        --v=${LOGLEVEL} 2>&1 | tee /logs/server.log
    /bin/bash
fi
