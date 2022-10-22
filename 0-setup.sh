#!/bin/bash

# exit when any command fails
set -e

function print_bold {
    echo -e "\033[1m> ---------------------------------------------------------------\033[0m"
    echo -e "\033[1m> $1\033[0m"
    echo -e "\033[1m> ---------------------------------------------------------------\033[0m"
}

print_bold "checking for tekton CLI"
if ! command -v tkn &> /dev/null
then
    echo "ERROR! This script needs tkn. Install it using:"
    echo "ERROR!      brew install tektoncd-cli"
    exit
fi
print_bold "checking for oc CLI"
if ! command -v oc &> /dev/null
then
    echo "ERROR! This script needs tkn. Install it using:"
    echo "ERROR!      brew install openshift-cli"
    exit
fi

print_bold "creating namespace to run pipelines in"
oc create namespace pipeline-ace --dry-run=client -o yaml | oc apply -f -

print_bold "storing github credentials for cloning the repo from a pipeline"
oc apply -n pipeline-ace -f ./github-credentials.yaml

print_bold "creating service account to run the pipelines as"
oc apply -n pipeline-ace -f ./tekton/0-general/permissions

print_bold "creating common pipeline tasks"
oc apply -n pipeline-ace -f ./tekton/0-general/tasks
oc apply -n pipeline-ace -f https://raw.githubusercontent.com/tektoncd/catalog/main/task/buildah/0.3/buildah.yaml
