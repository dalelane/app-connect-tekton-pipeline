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

print_bold "storing docker credentials for pulling image for BAR file builder"
oc apply -n pipeline-ace -f ./ibm-entitlement-key.yaml

print_bold "creating service account to run the pipelines as"
oc apply -n pipeline-ace -f ./tekton/permissions/serviceaccount.yaml

print_bold "setting up permissions for the deploy pipeline"
oc apply -n pipeline-ace -f ./tekton/permissions

print_bold "adding image builder permissions"
oc adm policy add-scc-to-user privileged -z pipeline-deployer-serviceaccount -n pipeline-ace

print_bold "creating tasks for the deployment pipeline"
oc apply -n pipeline-ace -f ./tekton/tasks

print_bold "creating deployment pipeline"
oc apply -n pipeline-ace -f ./tekton/pipeline.yaml
