#!/bin/sh

echo "Open local version here: http://localhost:4000"

docker run -it --rm -v "$PWD":/usr/src/app -p "4000:4000" starefossen/github-pages
