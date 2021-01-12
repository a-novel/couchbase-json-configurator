package bucket

func (b *Bucket) IsIndexSetup() bool {
	return b.PrimaryIndex != ""
}
