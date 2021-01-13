package start_script

import (
	"github.com/gin-gonic/gin"
)

var status string

const (
	StatusProcessing = "status_processing"
	StatusReady = "status_ready"
)

func StartListener() {
	r := gin.Default()
	r.GET("/", func (c *gin.Context) {
		switch status {
		case StatusReady:
			c.Data(200, "text/plain", []byte("cluster ready"))
		case StatusProcessing:
			c.Data(102, "text/plain", []byte("processing cluster"))
		default:
			c.Data(500, "text/plain", []byte(status))
		}
	})

	r.Run(":7777")
}

func MarkAsReady() {
	status = StatusReady
}

func MarkAsFaulty(msg string) {
	status = msg
}