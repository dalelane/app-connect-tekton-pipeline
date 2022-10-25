#!/bin/bash

# exit when any command fails
set -e

function print_bold {
    echo -e "\033[1m> ---------------------------------------------------------------\033[0m"
    echo -e "\033[1m> $1\033[0m"
    echo -e "\033[1m> ---------------------------------------------------------------\033[0m"
}


print_bold "removing github credentials"
oc delete -n pipeline-ace --ignore-not-found=true -f ./github-credentials.yaml

print_bold "removing docker credentials"
oc delete -n pipeline-ace --ignore-not-found=true -f ./ibm-entitlement-key.yaml

print_bold "removing image builder permissions"
oc adm policy remove-scc-from-user privileged -z pipeline-deployer-serviceaccount -n pipeline-ace

print_bold "removing deploy pipeline resources"
oc delete -n pipeline-ace -l tekton.dev/pipeline=pipeline-ace-integration-server pipelineruns
oc delete -n pipeline-ace --ignore-not-found=true -f ./tekton/pipeline.yaml
oc delete -n pipeline-ace --ignore-not-found=true -f ./tekton/tasks
oc delete -n pipeline-ace --ignore-not-found=true -f ./tekton/permissions

print_bold "removing pipeline namespace"
oc delete namespace --ignore-not-found=true pipeline-ace

print_bold "pipeline removed"