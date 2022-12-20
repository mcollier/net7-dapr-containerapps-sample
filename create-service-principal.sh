#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset

az ad sp create-for-rbac \
    --name 'mcsamplecontributor' \
    --role 'Contributor' \
    --scopes '/subscriptions/462f9d9d-6656-4251-b417-118072689b2d/resourceGroups/rg-mcnet7dapracasample'


