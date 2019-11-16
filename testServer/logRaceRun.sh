#!/bin/bash
GORACE="log_path=./raceLogs/log" go run -race *.go