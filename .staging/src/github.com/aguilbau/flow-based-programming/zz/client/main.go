package main

import (
	"flag"
	"fmt"
	"log"

	pb "./pb"
	"golang.org/x/net/context"
	"google.golang.org/grpc"
)

const (
	address = "localhost:4142"
)

var (
	port int
	cidr string
)

func init() {
	flag.StringVar(&cidr, "c", "", "cidr")
	flag.IntVar(&port, "p", 0, "port")
	flag.Parse()
	if cidr == "" {
		log.Fatalln("cidr is required ! use the -c flag to define it")
	}
	if port == 0 {
		log.Fatalln("port is required ! use the -p flag to define it")
	}
}

func main() {
	// Set up a connection to the server.
	conn, err := grpc.Dial(address, grpc.WithInsecure())
	if err != nil {
		log.Fatalf("did not connect: %v", err)
	}
	defer conn.Close()
	c := pb.NewOrchestratorClient(conn)

	// Contact the server and print out its response.
	r, err := c.In(context.Background(), &pb.OrchestratorRequest{
		Cidr: cidr,
		Port: int32(port),
	})
	if err != nil {
		log.Fatalf("error: %v", err)
	}
	fmt.Println(r)
}
