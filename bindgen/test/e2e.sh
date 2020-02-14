#!/bin/sh
RUN_BINDGEN_E2E=1 pub run test -j 1 -r expanded $1
