package config

func (c *Config) AutoSetResources() {
	if c.Resources.RamSize == 0 {
		c.Resources.RamSize = c.ComputeBucketsRamSize()
	}
}

func (c *Config) ComputeBucketsRamSize() uint64 {
	var output uint64

	if c.Buckets != nil {
		for _, bucket := range c.Buckets {
			output += bucket.RamSize
		}
	}

	return output
}
