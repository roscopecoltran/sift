package main

import (
	"fmt"
	"log"
	"os/exec"
	"strings"

	"google.golang.org/grpc"

	pb "./pb"
	"golang.org/x/net/context"
)

const (
	nextAddress string = "appscanner:4002"
)

func createZmapArgs(in *pb.PortScannerRequest) []string {
	return []string{
		"-o", "-",
		"-p", fmt.Sprintf("%v", in.Port),
		in.Cidr,
	}
}

func RemoveEmpty(s []string) []string {
	res := s
	i := 0
	for i < len(res) {
		if s[i] == "" {
			res[i] = s[len(res)-1]
			res = res[:len(res)-1]
			continue
		}
		i++
	}
	return res
}

func (s *server) In(ctx context.Context, in *pb.PortScannerRequest) (*pb.RPCResponse, error) {
	// Set up a connection to the server.
	conn, err := grpc.Dial(nextAddress, grpc.WithInsecure())
	if err != nil {
		log.Println("did not connect: %v", err)
		return &pb.RPCResponse{RequestId: in.RequestId}, err
	}
	next := pb.NewAppScannerClient(conn)

	go func() {
		// chan can get double close if their is multiple chans !
		defer conn.Close()
		zmapArgs := createZmapArgs(in)
		cmd := exec.Command("zmap", zmapArgs...)
		out, err := cmd.Output()
		if err != nil {
			log.Println("could not execute zmap: %v", err)
			return
		}

		var batchSize int
		if batchSize == 0 {
			batchSize = 1000
		} else {
			batchSize = int(in.BatchSize)
		}
		a := RemoveEmpty(strings.Split(string(out), "\n"))
		for i := 0; i < len(a); i += batchSize {
			var j int
			if i+batchSize > len(a) {
				j = len(a)
			} else {
				j = i + batchSize
			}
			batch := a[i:j]
			next.In(context.Background(), &pb.AppScannerRequest{
				Hosts:     batch,
				Port:      in.Port,
				RequestId: in.RequestId,
			})
		}
	}()
	return &pb.RPCResponse{RequestId: in.RequestId}, nil
}
