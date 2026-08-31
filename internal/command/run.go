package command

import (
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io"

	"github.com/roshbhatia/go-utils/ui"
)

type Streams struct {
	Stdout  io.Writer
	Stderr  io.Writer
	Version string
}

type result struct {
	Message string    `json:"message"`
	Status  ui.Status `json:"status"`
}

func Run(args []string, streams Streams) int {
	flags := flag.NewFlagSet("example", flag.ContinueOnError)
	flags.SetOutput(streams.Stderr)
	jsonOutput := flags.Bool("json", false, "write JSON to stdout")
	showVersion := flags.Bool("version", false, "write the version to stdout")
	if err := flags.Parse(args); err != nil {
		return 2
	}
	if *showVersion {
		fmt.Fprintln(streams.Stdout, streams.Version)
		return 0
	}
	if flags.NArg() > 1 {
		fmt.Fprintln(streams.Stderr, "example accepts at most one name")
		return 2
	}

	name := "world"
	if flags.NArg() == 1 {
		name = flags.Arg(0)
	}
	output := result{Message: "hello, " + name, Status: ui.StatusDone}
	if *jsonOutput {
		if err := json.NewEncoder(streams.Stdout).Encode(output); err != nil {
			fmt.Fprintf(streams.Stderr, "write output: %v\n", err)
			return 1
		}
		return 0
	}
	if _, err := fmt.Fprintln(streams.Stdout, output.Message); err != nil && !errors.Is(err, io.ErrClosedPipe) {
		fmt.Fprintf(streams.Stderr, "write output: %v\n", err)
		return 1
	}
	return 0
}
