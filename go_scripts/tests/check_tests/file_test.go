package check_tests

import (
	"github.com/a-novel/divanDocker/start_script"
	"github.com/a-novel/divanDocker/tests/test_utils"
	"testing"
)

func TestNonJSONFile(t *testing.T) {
	test_utils.WriteConfigAuto("hello world!", t)
	defer test_utils.DeleteConfigAuto(t)

	timer := test_utils.Time("launching setup script (should fail with non JSON file)...")
	timer.Important = true
	if err := start_script.Start(true); err == nil {
		timer.EndWithError("non json config file should return an error")
	} else {
		timer.End("script failed successfully with non JSON file")
	}
}
