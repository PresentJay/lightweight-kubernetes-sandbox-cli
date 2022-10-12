#!/bin/bash

# Author: PresentJay (정현재, presentj94@gmail.com)

source ./scripts/kubecheats.sh

INGRESS_HOSTNAME="packages"
INGRESS_SERVICE="packageserver-service"
INGRESS_PORT=5443
PACKAGE_LABEL="olm"
INSTALL_NAMESPACE="olm"
INGRESS_PROTOCOL="https"

case $(checkOpt iu $@) in
    i | install)
        applyIngressNginxHTTPS ${INGRESS_HOSTNAME} ${INGRESS_SERVICE} ${INGRESS_PORT} ${PACKAGE_LABEL} ${INSTALL_NAMESPACE}
    ;;
    u | uninstall | teardown)
        deleteSequence ingress ${INGRESS_SERVICE}
    ;;
    open)
        if checkParamIsInList ${INGRESS_PROTOCOL} http https; then
            _HOSTURL_="${INGRESS_HOSTNAME}.${masterNodeIP}.nip.io"
            _PORT_=$(bash packages/ingress-nginx/helm.sh --${INGRESS_PROTOCOL}Port)
            _OPENURI_="${INGRESS_PROTOCOL}://${_HOSTURL_}:${_PORT_}"
            openURI ${_OPENURI_}
            echo "initialized admin: ${PGADMIN_DEFAULT_EMAIL}"
            echo "initialized password: ${PGADMIN_DEFAULT_PASSWORD}"
        else
            logKill "please set INGRESS_PROTOCOL to http or https only. (in .env)"
        fi
    ;;
    h | help | ? | *)
        logHelpHead "scripts/getOLM.sh"
        logHelpContent i install "install olm package"
        logHelpContent u uninstall "install olm package"
        logHelpContent open "open olm package"
        logHelpTail
    ;;
esac