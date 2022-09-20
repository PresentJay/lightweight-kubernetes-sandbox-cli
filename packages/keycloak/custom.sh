#!/bin/bash

# Author: PresentJay (정현재, presentj94@gmail.com)

source ./scripts/kubecheats.sh
getEnv ./packages/keycloak/.env

case $(checkOpt iu $@) in
    i | install)
        kubectl apply -f packages/keycloak/CRD.yaml
        kubectl apply -f packages/keycloak/keycloak-operator.yaml
        applyIngressNginxHTTP ${INGRESS_HOSTNAME} ${INGRESS_SERVICE} ${INGRESS_PORT} ${PACKAGE_LABEL}
    ;;
    u | uninstall | teardown)
        
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
        logHelpHead "packages/keycloak/custom.sh"
        logHelpContent i install "install keycloak package"
        logHelpContent u uninstall "uninstall keycloak package"
        logHelpContent open "open keycloak web"
        logHelpContent token "get keycloak admin token"
        logHelpTail
    ;;
esac