#
# Full build image
#
FROM martenseemann/quic-network-simulator-endpoint:latest

# 19.04 repos got moved
#RUN sed -i -re 's/([a-z]{2}\.)?archive.ubuntu.com|security.ubuntu.com/old-releases.ubuntu.com/g' /etc/apt/sources.list
RUN apt-get update

RUN apt-get --yes --fix-missing update

# Get and build proxygen with HTTP/3 support
RUN apt-get install --yes wget net-tools iputils-ping tcpdump ethtool iperf
RUN apt-get install --yes git sudo cmake
RUN git clone https://github.com/facebook/proxygen.git
RUN cd proxygen/proxygen && ./build.sh -q -t
# Cop
RUN ldd /proxygen/proxygen/_build/proxygen/httpserver/hq | grep "=> /" | awk '{print $3}' > libs.txt
RUN tar cvf libs.tar --dereference --files-from=libs.txt

#
# Minimal image
#
FROM martenseemann/quic-network-simulator-endpoint:latest
# copy run scripts
COPY run_endpoint.sh .
RUN chmod +x run_endpoint.sh
COPY setup.sh .
RUN chmod +x setup.sh
COPY wait-for-it.sh .
RUN chmod +x wait-for-it.sh

# Copy HQ
COPY --from=0 /proxygen/proxygen/_build/proxygen/httpserver/hq /proxygen/proxygen/_build/proxygen/httpserver/hq
# Copy shared libs
COPY --from=0 libs.tar /
RUN tar xvf libs.tar
RUN rm libs.tar
# Create the logs directory
RUN mkdir /logs

ENTRYPOINT [ "./run_endpoint.sh" ]
