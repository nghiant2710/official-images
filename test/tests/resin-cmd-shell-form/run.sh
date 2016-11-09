#!/bin/bash
set -e

docker run --rm "$1" bash -c 'echo resin base images test'
