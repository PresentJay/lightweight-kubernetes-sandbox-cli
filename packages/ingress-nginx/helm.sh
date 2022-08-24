#!/bin/bash

# Author: PresentJay (정현재, presentj94@gmail.com)

source ./scripts/kubecheats.sh
getEnv ./packages/ingress-nginx/.env

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
            --install
    ;;
    u | uninstall | teardown)

    ;;
    h | help | ? | *)
        logHelpHead "packages/ingress-nginx/helm.sh"
        logHelpContent i install "install ingress-nginx package"
        logHelpContent u uninstall "uninstall ingress-nginx package"
        logHelpTail
    ;;
esac