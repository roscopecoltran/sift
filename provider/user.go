package provider

import (
	"github.com/google/go-github/github"

	"github.com/dziemba/seeker/data"
)

// GetUserInfo fills in the given User struct with all available data
func GetUserInfo(cli *github.Client, user *data.User) {
	res, _, _ := cli.Users.Get(user.Username)

	user.Name = ptrString(res.Name)
	user.Location = ptrString(res.Location)
	user.Company = ptrString(res.Company)
	user.Email = ptrString(res.Email)
	user.Hireable = ptrBool(res.Hireable)
}
