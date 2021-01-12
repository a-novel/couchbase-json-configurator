package index

type Index struct {
	IndexKey   []string `json:"indexKey"`
	KeyspaceID string   `json:"-"`
	Condition  string   `json:"-"`

	skip     bool
	recreate bool
}

func (i *Index) SetSkip() {
	i.skip = true
}

func (i *Index) SetRecreate() {
	i.recreate = true
}

func (i *Index) Skipped() bool {
	return i.skip
}

func (i *Index) Recreated() bool {
	return i.recreate
}
