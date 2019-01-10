#!/bin/bash

docker build -t mosquitto-with-http-auth .
docker tag mosquitto-with-http-auth:latest datacake/mosquitto-with-http-auth:$(git describe --always)
docker push datacake/mosquitto-with-http-auth:$(git describe --always)