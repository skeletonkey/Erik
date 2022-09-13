package Erik

import (
	"fmt"
	"os"
)

const logFile = "/tmp/erik.go.out"

func getFileHandler() *os.File {
	var file, err = os.OpenFile(logFile, os.O_CREATE|os.O_APPEND, 0755)
	if err != nil {
		fmt.Println(err.Error())
	}
	defer file.Close()
	return file
}

func Log(msg string) {
	file := getFileHandler()
	fmt.Fprintln(file, msg)
}

func Dump(variable any) {
	file := getFileHandler()
	fmt.Fprintf(file, "%#v\n", variable)
}
