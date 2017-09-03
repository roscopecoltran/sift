package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"log"
	"os"
	"strings"

	"github.com/garyburd/redigo/redis"
)

// var (
// 	redisAddress   = flag.String("redis-address", ":6379", "Address to the Redis server")
// 	maxConnections = flag.Int("max-connections", 10, "Max connections to Redis")
// )

var (
	con redis.Conn
)

// http://redis.io/commands
func testRedis() {

	// redisPool := redis.NewPool(func() (redis.Conn, error) {
	// 	c, err := redis.Dial("tcp", url)
	//
	// 	if err != nil {
	// 		return nil, err
	// 	}
	//
	// 	return c, err
	// }, 1)
	// defer redisPool.Close()

	// ok !!!

	// c := redisPool.Get()

	// get
	key := "test2"

	// or use type assertion
	value, err := redis.String(con.Do("GET", key))
	if err != nil {
		log.Println("got err:", err)
		// e.g. got err: redigo: nil returned
	} else {
		log.Println("got:", value)
	}

	// exist
	// exists, err := redis.Bool(c.Do("EXISTS", "foo"))

	// set
	key2 := "test3"
	status, err := con.Do("SET", key2, "body2")
	if err != nil {
		log.Println("set err:", err)
		//		message := fmt.Sprintf("Could not SET %s:%s", key, value)
	} else {
		log.Println("set status:", status)
	}

	// set json
	// key8 := "key8"
	// user := GitHubUser{"1", "1", "1", 8, 3}
	// value3, _ := json.Marshal(user)
	// n, err := con.Do("SET", key8, value3)
	// if err != nil {
	// 	fmt.Println(err)
	// }
	// value7, err := redis.Bytes(con.Do("GET", key8))
	// if err != nil {
	// 	fmt.Println("get json fail:", err)
	// }
	// // 将json解析成map类型
	// var object GitHubUser
	// err = json.Unmarshal(value7, &object)
	// if err != nil {
	// 	fmt.Println("convert fail:", err)
	// } else {
	// 	fmt.Println("json:", object)
	// }

	// values, err := redis.Values(c.Do("SORT", "albums",
	// for len(values) > 0 {
	// values, err = redis.Scan(values, &title, &rating)

	// func (s *Script) Send(c Conn, keysAndArgs ...interface{}) error
	// Send evaluates the script without waiting for the reply.

	// delete
	n, err := con.Do("DEL", "test3")
	if err != nil {
		log.Println("got err:", err)
		//		message := fmt.Sprintf("Could not SET %s:%s", key, value)
	} else {
		log.Println("del status:", n)
	}
	// redis> SET key2 "World"
	// OK
	// redis> DEL key1 key2 key3

}

// type singleton struct {
// }

// var instance *singleton
// var once sync.Once

// func GetInstance() *singleton {
// 	once.Do(func() {
// 		instance = &singleton{}
// 	})
// 	return instance
// }

func close(con redis.Conn) {
	defer con.Close()
}

func connect() redis.Conn {

	// log.Println("redis init")

	db_url := os.Getenv("REDIS_URL")
	i := strings.Index(db_url, "@")
	// log.Println("@ is at:", i)
	j := strings.Index(db_url, "h:")
	redisPWD := db_url[(j + 2):i]
	url := db_url[(i + 1):len(db_url)]

	// log.Println("url:", url)
	// log.Println("pwd:", redisPWD)

	c, err := redis.Dial("tcp", url)
	if err != nil {
		log.Println("redis dial fail")

		return nil //nil, err
	}
	if _, err := c.Do("AUTH", redisPWD); err != nil {
		c.Close()
		log.Println("redis auth fail")

		return nil //nil, err
	}

	// log.Println("redis init ok !!!")

	return c
}

func SetUserOrJustUpdateToken(account string, token string) {
	mux.Lock()

	elem, ok := GetUserFromDB(account)

	var user GitHubUser

	if ok == true {
		log.Println("update a user")

		// update it
		user = *elem
		user.Tokens = append(user.Tokens, token)
	} else {
		// add it
		log.Println("add a new user")
		user = GitHubUser{account, []string{token}, NOTSTART, 0, 0}
	}

	SetUserToDB(account, user)

	mux.Unlock()
}

func SetUser(account string, user GitHubUser) error {
	mux.Lock()
	SetUserToDB(account, user)
	defer mux.Unlock()
	return nil
}

func SetUserToDB(account string, user GitHubUser) error {

	con := connect()
	defer close(con)
	value, _ := json.Marshal(user)
	_, err := con.Do("SET", account, value)
	if err != nil {
		fmt.Println("set user to db error:", err)
	} else {
		fmt.Println("set user to db ok")
	}

	return err
}

func GetUser(account string) (*GitHubUser, error) {

	mux.Lock()
	defer mux.Unlock()

	elem, ok := GetUserFromDB(account) //	elem, ok := userMap[account]

	if ok == true {
		return elem, nil
	}
	return nil, errors.New("user does not exist")
}

func GetUserFromDB(account string) (*GitHubUser, bool) {

	con := connect()
	defer close(con)
	// log.Println("try to get user from db:", account)
	value, err := redis.Bytes(con.Do("GET", account))
	if err != nil {
		fmt.Println("get account json fail:", err)
		return nil, false
	}

	// fmt.Println("user json value:", string(value))

	var object GitHubUser
	err = json.Unmarshal(value, &object)
	if err != nil {
		fmt.Println("convert fail:", err)
	}

	return &object, true
}
