#!/bin/bash

snyk_iac () {
    snyk auth "${SNYK_TOKEN}"
    snyk iac test --report --org="${SNYK_ORG}" --severity-threshold=low --target-name="${SNYK_APP}" "${PWD}"
}

"$@"