FROM golang:1.7.3

RUN apt-get update && apt-get install -y zmap git-core curl jq make && apt-get clean
RUN go get -u github.com/BuoyantIO/namerctl
RUN go install github.com/BuoyantIO/namerctl
RUN go get golang.org/x/net/context google.golang.org/grpc github.com/golang/protobuf/proto golang.org/x/\
net/http2
ENV GOBIN=$GOPATH/bin      \
    PATH=$PATH:$GOPATH/bin

ADD . /tmp/port_scanner

RUN cd /tmp/port_scanner && go build

ENTRYPOINT /tmp/port_scanner/port_scanner
EXPOSE 4001
