#!/bin/bash

# Author: PresentJay (정현재, presentj94@gmail.com)

source ./scripts/kubecheats.sh
getEnv ./packages/kubernetes-dashboard/.env

case $(checkOpt iub $@) in
    i | install)
        ! checkHelmRepo ${CHART_REPOSITORY_NAME} && \
            helm repo add ${CHART_REPOSITORY_NAME} ${CHART_REGISTRY} && helm repo update
        ! checkNamespace ${INSTALL_NAMESPACE} && \
            kubectl create namespace ${INSTALL_NAMESPACE}
        helm upgrade ${INSTALL_NAME} ${CHART_REPOSITORY_NAME}/${CHART_REPOSITORY_ORG} \
            --version ${INSTALL_VERSION} \
            --namespace ${INSTALL_NAMESPACE} \
            --set metadata.labels.package=${PACKAGE_NAME} \
            --set extraArgs=\"{--token-ttl=${TOKEN_TTL}}\" \
            --install
    ;;
    u | uninstall | teardown)
        delete_sequence ingress ${INSTALL_NAME}
        delete_sequence helm ${INSTALL_NAME} ${INSTALL_NAMESPACE}
        delete_sequence namespace ${INSTALL_NAMESPACE}
    ;;
esac