#!/usr/bin/env sh
docker build . --progress=tty --squash -t jonrad/profilerate-test-runner:latest
