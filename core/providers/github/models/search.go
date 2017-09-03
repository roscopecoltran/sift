package models

// Represent data structure GitHub API Search response
type searchResult struct {
	TotalCount 			int 				`json:"total_count"`
	IncompleteResults 	bool 				`json:"incomplete_results"`
	Items 				[]models.Repository `json:"items"`
}

