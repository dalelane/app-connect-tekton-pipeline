#!/bin/bash

# exit when any command fails
set -e

# Allow this script to be run from other locations,
# despite the relative file paths
if [[ $BASH_SOURCE = */* ]]; then
    cd -- "${BASH_SOURCE%/*}/" || exit
fi

# Common setup
source 0-setup.sh


print_bold "setting up permissions for the image builder pipeline"
oc apply -n pipeline-ace -f ./tekton/1-prepare-builder/permissions
oc adm policy add-scc-to-user privileged -z pipeline-deployer-serviceaccount -n pipeline-ace

print_bold "creating tasks for the image builder pipeline"
oc apply -n pipeline-ace -f ./tekton/1-prepare-builder/tasks

print_bold "creating image builder pipeline"
oc apply -n pipeline-ace -f ./tekton/1-prepare-builder/pipeline.yaml

print_bold "running the image builder pipeline"
PIPELINE_RUN_K8S_NAME=$(oc create -n pipeline-ace -f ./tekton/1-prepare-builder/pipelinerun.yaml -o name)
echo $PIPELINE_RUN_K8S_NAME
PIPELINE_RUN_NAME=${PIPELINE_RUN_K8S_NAME:23}

print_bold "tailing pipeline logs"
tkn pipelinerun logs -n pipeline-ace --follow $PIPELINE_RUN_NAME

print_bold "removing privileged permissions from pipeline"
oc adm policy remove-scc-from-user privileged -z pipeline-deployer-serviceaccount -n pipeline-ace

print_bold "deleting the permissions created for the image builder pipeline"
oc delete -n pipeline-ace --ignore-not-found=true -f ./tekton/1-prepare-builder/permissions

print_bold "pipeline complete"
