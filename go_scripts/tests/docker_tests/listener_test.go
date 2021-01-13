package docker_tests

import (
	"fmt"
	"github.com/a-novel/divanDocker/tests/test_utils"
	"github.com/a-novel/divanDocker/utils"
	"net/http"
	"path"
	"testing"
	"time"
)

func get(u string) (*http.Response, error) {
	req, err := http.NewRequest("GET", u, nil)
	if err != nil {
		return nil, err
	}

	req.Header.Set("Content-Type", "text/plain")

	client := &http.Client{}
	resp, err := client.Do(req)
	return resp, err
}

func TestListener(t *testing.T) {
	ePath, err := getExecPath()
	if err != nil {
		t.Fatalf(err.Error())
	}

	timer := test_utils.Time("building image")
	if _, err := utils.Command("sh", "-c", fmt.Sprintf(
		"cd \"%s\" && docker build -t kushuh/divan:local -f Dockerfile .",
		path.Join(ePath, "../../../"),
	)); err != nil {
		timer.EndWithFatalError(err.Error(), t)
	}
	timer.End("image built successfully")

	timer = test_utils.Time("running container")
	timer.Important = true
	if _, err := utils.Command("sh", "-c", fmt.Sprintf(
		"docker run -d --name divan-test -p '8091-8096:8091-8096' -p '11210-11211:11210-11211' -p '7777:7777' --mount type=bind,source=\"%s\",target=/root/DIVAN_config/config.json kushuh/divan:local",
		path.Join(ePath, "configSample.json"),
	)); err != nil {
		timer.EndWithFatalError(err.Error(), t)
	}
	timer.End("container running")

	timer = test_utils.Time("posting first request")
	timer.Important = true
	var res *http.Response
	tx := time.Now().Second()
	for (time.Now().Second() - tx) < 20 {
		res, err = get("http://localhost:7777")
		if err != nil || res != nil {
			break
		}
	}
	if err != nil {
		timer.EndWithError(err.Error())
	} else if res == nil {
		timer.EndWithError("cannot reach listener (timeout)")
	}
	timer.End("request successful")

	timer = test_utils.Time("posting second request")
	timer.Important = true
	tx = time.Now().Second()
	for (time.Now().Second() - tx) < 180 {
		res, err = get("http://localhost:7777")
		if err != nil || res.StatusCode != 102 {
			break
		}
	}
	if err != nil {
		timer.EndWithError(err.Error())
	} else if res == nil {
		timer.EndWithError("listener not getting ready (timeout)")
	} else if res.StatusCode != 200 {
		timer.EndWithError(fmt.Sprintf("unexpected status code %v", res.StatusCode))
	}
	timer.End("request successful")

	timer = test_utils.Time("killing container")
	timer.Important = true
	if _, err := utils.Command("sh", "-c", "docker kill divan-test && docker rm divan-test"); err != nil {
		timer.EndWithFatalError(err.Error(), t)
	}
	timer.End("container killed")
}
