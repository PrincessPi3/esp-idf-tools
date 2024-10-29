#!/bin/bash
set -e

echo "Script executed from: ${PWD}"

BASEDIR=$(dirname $0)
echo "Script location: ${BASEDIR}"

DIR="$( cd "$( dirname "$0" )" && pwd )"
echo $DIR