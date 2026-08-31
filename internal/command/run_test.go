package command

import (
	"bytes"
	"encoding/json"
	"testing"
)

func TestRunText(t *testing.T) {
	t.Parallel()

	var stdout bytes.Buffer
	var stderr bytes.Buffer
	code := Run([]string{"Roshan"}, Streams{Stdout: &stdout, Stderr: &stderr, Version: "test"})
	if code != 0 || stdout.String() != "hello, Roshan\n" || stderr.Len() != 0 {
		t.Fatalf("Run() = %d, %q, %q", code, stdout.String(), stderr.String())
	}
}

func TestRunJSON(t *testing.T) {
	t.Parallel()

	var stdout bytes.Buffer
	var stderr bytes.Buffer
	code := Run([]string{"--json", "Roshan"}, Streams{Stdout: &stdout, Stderr: &stderr, Version: "test"})
	if code != 0 {
		t.Fatalf("Run() = %d: %s", code, stderr.String())
	}
	var output result
	if err := json.Unmarshal(stdout.Bytes(), &output); err != nil {
		t.Fatalf("decode output: %v", err)
	}
	if output.Message != "hello, Roshan" || output.Status != "done" {
		t.Fatalf("unexpected output: %+v", output)
	}
}

func TestRunRejectsExtraArguments(t *testing.T) {
	t.Parallel()

	var stdout bytes.Buffer
	var stderr bytes.Buffer
	code := Run([]string{"one", "two"}, Streams{Stdout: &stdout, Stderr: &stderr, Version: "test"})
	if code != 2 || stderr.String() != "example accepts at most one name\n" {
		t.Fatalf("Run() = %d, %q", code, stderr.String())
	}
}
