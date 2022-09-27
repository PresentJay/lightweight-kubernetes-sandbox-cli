#!/bin/bash

# Author: PresentJay (정현재, presentj94@gmail.com)

source ./scripts/kubecheats.sh
getEnv ./packages/ansible-awx/.env

case $(checkOpt iu $@) in
    i | install)
        ! checkHelmRepo ${CHART_REPOSITORY_NAME} && \
            helm repo add ${CHART_REPOSITORY_NAME} ${CHART_REGISTRY} && helm repo update
        ! checkNamespace ${INSTALL_NAMESPACE} && \
            kubectl create namespace ${INSTALL_NAMESPACE}
        helm upgrade ${INSTALL_NAME} ${CHART_ORG}/${CHART_NAME} \
            --namespace ${INSTALL_NAMESPACE} \
            --install \
            --set projects_persistence=true \
            --set projects_storage_class=${STORAGE} \
            --set projects_storage_size=${PVC_SIZE} \
            --set admin_user=${ADMIN_USER} \
            --set admin_password_secret=${ADMIN_PASSWORD_SECRET} \
            --set admin_email=${ADMIN_EMAIL}
        applyIngressNginxHTTPS ${INGRESS_HOSTNAME} ${INGRESS_SERVICE} ${INGRESS_PORT} ${PACKAGE_LABEL} ${INSTALL_NAMESPACE}
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
        else
            logKill "please set INGRESS_PROTOCOL to http or https only. (in .env)"
        fi
    ;;
    h | help | ? | *)
        logHelpHead "packages/ansible-awx/helm.sh"
        logHelpContent i install "install awx package"
        logHelpContent u uninstall "uninstall awx package"
        logHelpTail
    ;;
esac