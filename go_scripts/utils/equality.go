package utils

func StrSliceEqual(a, b []string) bool {
	if len(a) != len(b) {
		return false
	}

	for _, x := range a {
		found := false

		for _, y := range b {
			if x == y {
				found = true
				break
			}
		}

		if !found {
			return false
		}
	}

	return true
}
