#!/bin/bash
GORACE="log_path=./raceLogs" go run -race *.go