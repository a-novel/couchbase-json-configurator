package resources

type Resources struct {
	RamSize       uint64  `json:"ramSize"`
	FtsRamSize    uint64  `json:"ftsRamSize"`
	IndexRamSize  uint64  `json:"indexRamSize"`
	PurgeInterval float64 `json:"purgeInterval"`
}
