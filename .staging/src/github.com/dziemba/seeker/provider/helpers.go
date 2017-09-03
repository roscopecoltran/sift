package provider

func ptrString(s *string) string {
	if s == nil {
		return ""
	}
	return *s
}

func ptrBool(b *bool) bool {
	return b != nil && *b
}
