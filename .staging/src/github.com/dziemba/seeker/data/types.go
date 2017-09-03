package data

// RepoInfo contains information about a repository, including languages and contributors
type RepoInfo struct {
	Owner           string
	Name            string
	Stars           int
	LangPercentages map[string]float64
	Contributions   map[string]int
}

// User contains information about a user and their contributions
type User struct {
	Username string

	Score        float64
	LanguageInfo string

	Name     string
	Location string
	Company  string
	Email    string
	Hireable bool
}
