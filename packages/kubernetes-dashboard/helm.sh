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
            --set extraArgs={--token-ttl=${TOKEN_TTL}} \
            --set metadata.labels.package=${PACKAGE_NAME} \
            --install
    ;;
    u | uninstall | teardown)
        deleteSequence ingress ${INSTALL_NAME}
        deleteSequence helm ${INSTALL_NAME} ${INSTALL_NAMESPACE}
        deleteSequence namespace ${INSTALL_NAMESPACE}
    ;;
    h | help | ? | *)
        logHelpHead "packages/kubernetes-dashboard/helm.sh"
        logHelpContent i install "install kubernetes-dashboard package"
        logHelpContent u uninstall "uninstall kubernetes-dashboard package"
        logHelpTail
    ;;
esac