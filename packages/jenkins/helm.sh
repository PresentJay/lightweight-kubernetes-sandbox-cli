#!/bin/bash

# Author: PresentJay (정현재, presentj94@gmail.com)

source ./scripts/kubecheats.sh
getEnv ./packages/jenkins/.env

case $(checkOpt iu $@) in
    i | install)
        ! checkHelmRepo ${CHART_REPOSITORY_NAME} && \
            helm repo add ${CHART_REPOSITORY_NAME} ${CHART_REGISTRY} && helm repo update
        ! checkNamespace ${INSTALL_NAMESPACE} && \
            kubectl create namespace ${INSTALL_NAMESPACE}
        helm upgrade ${INSTALL_NAME} ${CHART_REPOSITORY_ORG}/${CHART_REPOSITORY_NAME} \
            --version ${INSTALL_VERSION} \
            --namespace ${INSTALL_NAMESPACE} \
            --install \
            --set persistence.storageClass=${STORAGE} \
            --set controller.adminUser=${ADMIN_USERNAME} \
            --set controller.adminPassword=${ADMIN_PASSWORD}
        applyIngressNginxHTTP ${INGRESS_HOSTNAME} ${INGRESS_SERVICE} ${INGRESS_PORT} ${PACKAGE_LABEL} ${INSTALL_NAMESPACE}
    ;;
    u | uninstall | teardown)
        deleteSequence helm ${INSTALL_NAME} ${INSTALL_NAMESPACE}
        deleteSequence namespace ${INSTALL_NAMESPACE}
        deleteSequence helm-repo ${CHART_REPOSITORY_NAME}
    ;;
    open)
        if checkParamIsInList ${INGRESS_PROTOCOL} http https; then
            _HOSTURL_="${INGRESS_HOSTNAME}.${masterNodeIP}.nip.io"
            _PORT_=$(bash packages/ingress-nginx/helm.sh --${INGRESS_PROTOCOL}Port)
            _OPENURI_="${INGRESS_PROTOCOL}://${_HOSTURL_}:${_PORT_}"
            openURI ${_OPENURI_}
            logInfo "fetching dashboard-k8s login token . . ."
            echo $(bash packages/kubernetes-dashboard/helm.sh --token) 
        else
            logKill "please set INGRESS_PROTOCOL to http or https only. (in .env)"
        fi
    ;;
    h | help | ? | *)
        logHelpHead "packages/jenkins/helm.sh"
        logHelpContent i install "install jenkins package"
        logHelpContent u uninstall "uninstall jenkins package"
        logHelpTail
    ;;
esac