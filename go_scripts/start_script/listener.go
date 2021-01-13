package start_script

import (
	"github.com/gin-gonic/gin"
)

var status string
var r *gin.Engine

const (
	StatusProcessing = "status_processing"
	StatusReady      = "status_ready"
)

func StartListener() {
	if r != nil {
		return
	}

	r = gin.Default()
	r.GET("/", func(c *gin.Context) {
		switch status {
		case StatusReady:
			c.JSON(200, gin.H{"message": "cluster ready"})
		case StatusProcessing:
			c.JSON(102, gin.H{"message": "processing cluster"})
		default:
			c.JSON(500, gin.H{"message": status})
		}
	})

	r.Run(":7777")
}

func MarkAsProcessing() {
	status = StatusProcessing
}

func MarkAsReady() {
	status = StatusReady
}

func MarkAsFaulty(msg string) {
	status = msg
}
