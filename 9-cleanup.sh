#!/bin/bash

# exit when any command fails
set -e

function print_bold {
    echo -e "\033[1m> ---------------------------------------------------------------\033[0m"
    echo -e "\033[1m> $1\033[0m"
    echo -e "\033[1m> ---------------------------------------------------------------\033[0m"
}


print_bold "removing image builder pipeline resources"
oc delete -n pipeline-ace -l tekton.dev/pipeline=pipeline-docker-build pipelineruns
oc delete -n pipeline-ace --ignore-not-found=true -f ./tekton/1-prepare-builder/pipeline.yaml
oc delete -n pipeline-ace --ignore-not-found=true -f ./tekton/1-prepare-builder/tasks
oc delete -n pipeline-ace --ignore-not-found=true -f ./tekton/1-prepare-builder/permissions

print_bold "removing deploy pipeline resources"
oc delete -n pipeline-ace -l tekton.dev/pipeline=pipeline-ace-integration-server pipelineruns
oc delete -n pipeline-ace --ignore-not-found=true -f ./tekton/2-deploy-integration-server/pipeline.yaml
oc delete -n pipeline-ace --ignore-not-found=true -f ./tekton/2-deploy-integration-server/tasks
oc delete -n pipeline-ace --ignore-not-found=true -f ./tekton/2-deploy-integration-server/permissions

print_bold "removing common pipeline tasks"
oc delete -n pipeline-ace --ignore-not-found=true -f ./tekton/0-general/tasks
oc delete -n pipeline-ace --ignore-not-found=true -f https://raw.githubusercontent.com/tektoncd/catalog/main/task/buildah/0.3/buildah.yaml

print_bold "removing service account"
oc delete -n pipeline-ace --ignore-not-found=true -f ./tekton/0-general/permissions

print_bold "removing github credentials"
oc delete -n pipeline-ace --ignore-not-found=true -f ./github-credentials.yaml

print_bold "removing pipeline namespace"
oc delete namespace --ignore-not-found=true pipeline-ace

print_bold "pipeline removed"