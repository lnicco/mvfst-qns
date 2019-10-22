FROM martenseemann/quic-network-simulator-endpoint:latest

# Get and build proxygen with HTTP/3 support
RUN apt-get --yes --fix-missing update
RUN apt-get install --yes git sudo cmake
RUN git clone https://github.com/facebook/proxygen.git
RUN cd proxygen/proxygen && ./build.sh -q -t

# copy run script and run it
COPY run_endpoint.sh .
RUN sudo chmod +x run_endpoint.sh
COPY setup.sh .
RUN sudo chmod +x setup.sh
ENTRYPOINT [ "./run_endpoint.sh" ]
