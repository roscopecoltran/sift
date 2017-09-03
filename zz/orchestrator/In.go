package main

import (
	"crypto/rand"
	"encoding/hex"
	"log"

	"google.golang.org/grpc"

	pb "./pb"
	"golang.org/x/net/context"
)

const (
	tokenLength int = 128

	nextAddress string = "portscanner:4001"
)

func newToken() (string, error) {
	token := make([]byte, tokenLength)
	_, err := rand.Read(token)
	return hex.EncodeToString(token), err
}

/*
	this endpoint is responsible for splitting the cidr, and sending requests
	to the port_scanner
	for now, it only pass the cidr and port to the port_scanner
*/
func (s *server) In(ctx context.Context, in *pb.OrchestratorRequest) (*pb.RPCResponse, error) {
	// Set up a connection to the server.
	conn, err := grpc.Dial(nextAddress, grpc.WithInsecure())
	if err != nil {
		log.Println("did not connect: %v", err)
		return &pb.RPCResponse{}, err
	}
	defer conn.Close()
	next := pb.NewPortScannerClient(conn)

	requestID, err := newToken()
	if err != nil {
		log.Println("could not generate token: %v", err)
		return &pb.RPCResponse{}, err
	}

	// Contact the server and print out its response.
	_, err = next.In(context.Background(), &pb.PortScannerRequest{
		Cidr:      in.Cidr,
		Port:      in.Port,
		RequestId: requestID,
	})
	if err != nil {
		log.Println("could not connect to next endpoint: %v", err)
		return &pb.RPCResponse{}, err
	}

	return &pb.RPCResponse{RequestId: requestID}, nil
}
