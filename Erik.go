package main

import (
	"fmt"
	"os"
)

type Erik struct {
	logFH *os.File
}

const logFile = "/tmp/erik.go.out"

func New() Erik {
	var erik Erik
	fh, err := os.Create(logFile)
	if err != nil {
		fmt.Println(err.Error())
	}
	erik.logFH = fh
	return erik
}

func (e Erik) Log(msg string) {
	fmt.Printf("Writing: %v", msg)
	e.logFH.WriteString(msg + "\n")
}

func (e Erik) Dump(variable any) {
	fmt.Fprintf(e.logFH, "%#v\n", variable)
}
