package index

type BackendData struct {
	ID          string   `json:"id"`
	Name        string   `json:"name"`
	IndexKey    []string `json:"index_key"`
	Using       string   `json:"using"`
	State       string   `json:"state"`
	KeyspaceID  string   `json:"keyspace_id"`
	NamespaceID string   `json:"namespace_id"`
	DatastoreID string   `json:"datastore_id"`
	Condition   string   `json:"condition"`
	IsPrimary   bool     `json:"is_primary"`
}
