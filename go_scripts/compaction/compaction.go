package compaction

import (
	"github.com/a-novel/divanDocker/utils"
)

type Compaction struct {
	ParallelCompaction bool            `json:"parallelCompaction"`
	Threshold          utils.Threshold `json:"threshold"`
	ViewThreshold      utils.Threshold `json:"viewThreshold"`
	From               utils.Time      `json:"from"`
	To                 utils.Time      `json:"to"`
	AbortOutside       bool            `json:"abortOutside"`
}
