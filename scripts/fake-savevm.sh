#!/usr/bin/env sh

install -m 555 scripts/fake-loadvm.sh "stages/`basename $1`"
