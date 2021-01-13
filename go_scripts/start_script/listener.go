package start_script

import (
	"log"
	"net/http"
)

var status string

const (
	StatusProcessing = "status_processing"
	StatusReady = "status_ready"
)

func StartListener() {
	http.HandleFunc("/", func (w http.ResponseWriter, r *http.Request) {
		if stc, err := w.Write([]byte(status)); err != nil {
			w.Write([]byte(err.Error()))
			w.WriteHeader(stc)
		} else {
			switch status {
			case StatusReady:
				w.Write([]byte("cluster ready"))
				w.WriteHeader(200)
			case StatusProcessing:
				w.Write([]byte("processing cluster"))
				w.WriteHeader(102)
			default:
				w.Write([]byte(status))
				w.WriteHeader(500)
			}
		}
	})

	log.Fatal(http.ListenAndServe(":7777", nil))
}

func MarkAsReady() {
	status = StatusReady
}

func MarkAsFaulty(msg string) {
	status = msg
}