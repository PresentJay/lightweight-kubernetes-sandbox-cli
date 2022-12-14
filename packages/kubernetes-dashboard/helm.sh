#!/bin/bash

# Author: PresentJay (정현재, presentj94@gmail.com)

source ./scripts/kubecheats.sh
getEnv ./packages/kubernetes-dashboard/.env

case $(checkOpt iu $@) in
    i | install)
        ! checkHelmRepo ${CHART_REPOSITORY_NAME} && \
            helm repo add ${CHART_REPOSITORY_NAME} ${CHART_REGISTRY} && helm repo update
        ! checkNamespace ${INSTALL_NAMESPACE} && \
            kubectl create namespace ${INSTALL_NAMESPACE}
        helm upgrade ${INSTALL_NAME} ${CHART_REPOSITORY_ORG}/${CHART_REPOSITORY_NAME} \
            --version ${INSTALL_VERSION} \
            --namespace ${INSTALL_NAMESPACE} \
            --set=extraArgs=${EXTRAARGS} \
            --install \
            --no-hooks
        createSA admin-user ${INSTALL_NAMESPACE}
        createCRB admin-user cluster-admin ${INSTALL_NAMESPACE}
        applyIngressNginxHTTPS ${INGRESS_HOSTNAME} ${INGRESS_SERVICE} ${INGRESS_PORT} ${PACKAGE_LABEL} ${INSTALL_NAMESPACE}
    ;;
    u | uninstall | teardown)
        deleteSequence ingress ${INSTALL_NAME} ${INSTALL_NAMESPACE}
        deleteSequence serviceaccount admin-user ${INSTALL_NAMESPACE}
        deleteSequence clusterrolebinding admin-user
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
    token)
        _secret_=$(kubectl get serviceaccount admin-user -n ${INSTALL_NAMESPACE} -o jsonpath="{.secrets[0].name}")
        getSecretStringData ${_secret_} token ${INSTALL_NAMESPACE}
    ;;
    h | help | ? | *)
        logHelpHead "packages/kubernetes-dashboard/helm.sh"
        logHelpContent i install "install kubernetes-dashboard package"
        logHelpContent u uninstall "uninstall kubernetes-dashboard package"
        logHelpContent open "open kubernetes-dashboard web"
        logHelpContent token "get kubernetes-dashboard admin token"
        logHelpTail
    ;;
esac