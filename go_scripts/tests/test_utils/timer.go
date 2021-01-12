package test_utils

import (
	"fmt"
	"github.com/a-novel/errors"
	"strings"
	"testing"
	"time"
)

const (
	ColorReset        = "\033[0m"
	ColorBlack        = "\033[39m"
	ColorRed          = "\033[31m"
	ColorGreen        = "\033[32m"
	ColorYellow       = "\033[33m"
	ColorBlue         = "\033[34m"
	ColorMagenta      = "\033[35m"
	ColorCyan         = "\033[36m"
	ColorLightGray    = "\033[37m"
	ColorDarkGray     = "\033[90m"
	ColorLightRed     = "\033[91m"
	ColorLightGreen   = "\033[92m"
	ColorLightYellow  = "\033[93m"
	ColorLightBlue    = "\033[94m"
	ColorLightMagenta = "\033[95m"
	ColorLightCyan    = "\033[96m"
	ColorWhite        = "\033[97m"
)

func PrettyPrint(message string, offset int) string {
	var output string
	length := offset

	for _, word := range strings.Split(message, " ") {
		prefix := ""

		if len(word)+length > 63 {
			prefix = "\n\t" + strings.Repeat(" ", offset)
			length = offset
		} else if length > offset {
			prefix = " "
		}

		length += len(word) + 1
		output += prefix + word
	}

	if length > 64 {
		length = 64
	}

	output += strings.Repeat(" ", 64-length)
	return output
}

type Timer struct {
	Start     int64
	Message   string
	Important bool
}

func Time(message string) *Timer {
	fmt.Printf("%s%s%s", ColorLightGray, message, ColorReset)

	return &Timer{
		Start:   time.Now().UnixNano(),
		Message: message,
	}
}

func (t *Timer) Clean() {
	fmt.Printf("\r%s", strings.Repeat(" ", 128))
	fmt.Printf("\r")
}

func (t *Timer) End(message string) {
	t.Clean()

	color := ColorLightBlue
	color2 := ColorLightGray
	prefix := "- "

	if t.Important {
		color = ColorLightGreen
		color2 = ColorReset
		prefix = ""
	}

	fmt.Printf(
		"\t%s%s%s%s (%v ms)%s\n",
		prefix,
		color,
		PrettyPrint(message, len(prefix)),
		color2,
		(time.Now().UnixNano()-t.Start)/1000,
		ColorReset,
	)
}

func (t *Timer) EndWithError(message string) {
	t.Clean()

	color := ColorRed
	color2 := ColorLightGray
	prefix := "- "

	if t.Important {
		color = ColorRed
		color2 = ColorReset
		prefix = ""
	}

	fmt.Printf(
		"\t%s%s%s%s (%v ms)%s\n",
		prefix,
		color,
		PrettyPrint(message, len(prefix)),
		color2,
		(time.Now().UnixNano()-t.Start)/1000,
		ColorReset,
	)
}

func (t *Timer) EndWithFatalError(message string, tst *testing.T) {
	t.EndWithError(message)
	tst.Fatalf("")
}

func (t *Timer) UnexpectedErrID(expected string, current *errors.Error, message string) {
	t.EndWithError(fmt.Sprintf(
		"unexpected error ID '%s' when %s (should return '%s') %s from : %s",
		current.ID, message, expected, strings.Repeat("─", 62), current.Error(),
	))
}
