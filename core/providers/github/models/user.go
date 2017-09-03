
// https://github.com/dziemba/seeker

package users

// This structure represent a Github user
type User struct {
    Login string `json:"login"`
    ID int `json:"id"`
    AvatarURL string `json:"avatar_url"`
    GravatarID string `json:"gravatar_id"`
    URL string `json:"url"`
    HTMLURL string `json:"html_url"`
    OrganizationsURL string `json:"organizations_url"`
    Type string `json:"type"`
    SiteAdmin bool `json:"site_admin"`
}

