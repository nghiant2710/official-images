#!/bin/bash
set -e

docker run --rm "$1" echo resin base images test
