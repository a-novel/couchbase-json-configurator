package compaction

func (c *Compaction) IsCompactionSet() bool {
	return c.ParallelCompaction ||
		c.Threshold.IsSet() ||
		c.ViewThreshold.IsSet() ||
		!c.From.Equal(c.To)
}
