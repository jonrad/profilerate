#!/usr/bin/env sh
docker build . -f base.Dockerfile -t jonrad/profilerate-bash:v1
docker build . -f no-home.Dockerfile -t jonrad/profilerate-bash-no-home:v1
docker build . -f readonly.Dockerfile -t jonrad/profilerate-bash-readonly:v1
