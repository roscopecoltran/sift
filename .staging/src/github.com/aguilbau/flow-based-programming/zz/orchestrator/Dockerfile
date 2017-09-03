FROM golang:1.7.3

RUN apt-get update && apt-get install -y git-core curl jq make && apt-get clean
RUN go get -u github.com/BuoyantIO/namerctl
RUN go install github.com/BuoyantIO/namerctl
RUN go get golang.org/x/net/context google.golang.org/grpc github.com/golang/protobuf/proto golang.org/x/\
net/http2
ENV GOBIN=$GOPATH/bin      \
    PATH=$PATH:$GOPATH/bin

ADD . /tmp/orchestrator

RUN cd /tmp/orchestrator && go build

ENTRYPOINT /tmp/orchestrator/orchestrator
EXPOSE 4000
