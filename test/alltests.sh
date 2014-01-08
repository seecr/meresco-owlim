#!/bin/bash

export LANG=en_US.UTF-8
export PYTHONPATH=.:$PYTHONPATH

(
    cd ../src/test
    ./alltests.sh "$@"
)
