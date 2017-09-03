package github

import (
       "net/http"
       "io/ioutil"
       "github.com/roscopecoltran/sniperkit-sift/providers/github/utils"
       "errors"
)

// Basic representation of an Api with his base url
type Api struct {
     baseUrl string
     authToken string
}

// Create a new instance of Api
func New(baseUrl string, authToken string) *Api {
     return &Api{baseUrl : baseUrl, authToken : authToken}
}

// Call a get method on the service with the get parameters
// It return the response as an array of bytes
// return an error if something wrong occur
func (api *Api) Get(name string, params map[string]string) ([]byte, error) {
    req, err := http.NewRequest("GET", api.baseUrl + "/" + name, nil)
    client := &http.Client{}

    if err != nil {
       return nil, err
    }
    query := req.URL.Query()
    for key, val := range params {
    	query.Add(key, val)
    }
    query.Add("access_token", api.authToken)
    req.URL.RawQuery = query.Encode()
    utils.Log.Println("Sending request at : ", req.URL.String())
    resp, err := client.Do(req)
    defer resp.Body.Close()
    if err != nil {
       return nil, err
    }
    body, err := ioutil.ReadAll(resp.Body)
    if resp.StatusCode >= 400 {
        utils.Log.Println(string(body))
        return nil, errors.New(http.StatusText(resp.StatusCode))
    }
    if err != nil {
       return nil, err
    }
    return body, nil
}