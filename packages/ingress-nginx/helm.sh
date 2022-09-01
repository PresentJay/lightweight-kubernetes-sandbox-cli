#!/bin/bash

# Author: PresentJay (정현재, presentj94@gmail.com)

source ./scripts/kubecheats.sh
getEnv ./packages/ingress-nginx/.env

case $(checkOpt iu $@) in
    i | install)
        ! checkHelmRepo ${CHART_REPOSITORY_NAME} && \
            helm repo add ${CHART_REPOSITORY_NAME} ${CHART_REGISTRY} && helm repo update
        ! checkNamespace ${INSTALL_NAMESPACE} && \
            kubectl create namespace ${INSTALL_NAMESPACE}
        helm upgrade ${INSTALL_NAME} ${CHART_REPOSITORY_ORG}/${CHART_REPOSITORY_NAME} \
            --version ${INSTALL_VERSION} \
            --namespace ${INSTALL_NAMESPACE} \
            --install
    ;;
    u | uninstall | teardown)
        deleteSequence helm ${INSTALL_NAME} ${INSTALL_NAMESPACE}
        deleteSequence namespace ${INSTALL_NAMESPACE}
        deleteSequence helm-repo ${CHART_REPOSITORY_NAME}
    ;;
    httpsPort)
        echo $(getSvcNodePort ingress-nginx-controller 1 ${INSTALL_NAMESPACE})
    ;;
    httpPort)
        echo $(getSvcNodePort ingress-nginx-controller 0 ${INSTALL_NAMESPACE})
    ;;
    h | help | ? | *)
        logHelpHead "packages/ingress-nginx/helm.sh"
        logHelpContent i install "install ingress-nginx package"
        logHelpContent u uninstall "uninstall ingress-nginx package"
        logHelpContent httpsPort "return https port of ingress-controller"
        logHelpContent httpPort "return http port of ingress-controller"
        logHelpTail
    ;;
esac