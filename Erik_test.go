package main

import "testing"

func TestErik(t *testing.T) {
	erik := New()
	erik.Log("This is a test")

	number := 5
	erik.Dump(number)
}
