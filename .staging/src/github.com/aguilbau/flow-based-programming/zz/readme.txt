to run:
install protobuf : https://developers.google.com/protocol-buffers/docs/downloads

go get ./...
go get -u github.com/golang/protobuf/{proto,protoc-gen-go}
go get -u github.com/BuoyantIO/namerctl
go install github.com/BuoyantIO/namerctl
docker-compose up --build
namerctl dtab update default service.dtab --base-url=http://localhost:4180

the app uses l5d, but for now it is only for testing.
maybe in the future, we will make more use of it.
