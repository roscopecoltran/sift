package main

import (
	"fmt"

	pb "./pb"
	"golang.org/x/net/context"
)

func (s *server) In(ctx context.Context, in *pb.AppScannerRequest) (*pb.RPCResponse, error) {
	scanData := make(chan *ScanData)
	go AppScanner(int(in.Port), in.Hosts, scanData)
	for s := range scanData {
		fmt.Println(s)
	}

	return &pb.RPCResponse{}, nil
}
