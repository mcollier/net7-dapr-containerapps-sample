#!/bin/bash

# set -o errexit
# set -o pipefail
# set -o nounset

# Dapr initialization
dapr uninstall --all 
dapr init 

#  Restore .NET projects
dotnet restore ./source/cron-publisher 
dotnet restore ./source/signal-receiver
dotnet restore ./source/signal-generator
dotnet restore ./source/subscriber