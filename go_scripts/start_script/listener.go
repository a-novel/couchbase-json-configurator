package start_script

import (
	"github.com/gin-gonic/gin"
	"log"
)

var status string

const (
	StatusProcessing = "status_processing"
	StatusReady      = "status_ready"
)

func StatusHandler(c *gin.Context) {
	switch GetStatus() {
	case StatusReady:
		c.JSON(200, gin.H{"message": "cluster ready"})
	case StatusProcessing:
		c.JSON(503, gin.H{"message": "cluster setup processing"})
	default:
		c.JSON(500, gin.H{"message": GetStatus()})
	}

	return
}

func StartListener() {
	gin.SetMode(gin.ReleaseMode)
	r := gin.Default()
	r.GET("/divan_status", StatusHandler)
	log.Fatal(r.Run("0.0.0.0:8080"))
}

func GetStatus() string {
	return status
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
