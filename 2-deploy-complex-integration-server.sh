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


print_bold "setting up permissions for the deploy pipeline"
oc apply -n pipeline-ace -f ./tekton/2-deploy-integration-server/permissions

print_bold "creating tasks for the deployment pipeline"
oc apply -n pipeline-ace -f ./tekton/2-deploy-integration-server/tasks

print_bold "creating deployment pipeline"
oc apply -n pipeline-ace -f ./tekton/2-deploy-integration-server/pipeline.yaml

print_bold "running the pipeline"
PIPELINE_RUN_K8S_NAME=$(oc create -n pipeline-ace -f ./complex-pipelinerun.yaml -o name)
echo $PIPELINE_RUN_K8S_NAME
PIPELINE_RUN_NAME=${PIPELINE_RUN_K8S_NAME:23}

print_bold "tailing pipeline logs"
tkn pipelinerun logs -n pipeline-ace --follow $PIPELINE_RUN_NAME

print_bold "pipeline complete"
