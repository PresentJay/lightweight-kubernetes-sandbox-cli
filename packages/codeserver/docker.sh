#!/bin/bash

# Author: PresentJay (정현재, presentj94@gmail.com)

source ./scripts/kubecheats.sh
getEnv ./packages/codeserver/.env

case $(checkOpt iu $@) in
    i | install)
        kubectl apply -f packages/codeserver/codeserver.yaml
        applyIngressNginxHTTP ${INGRESS_HOSTNAME} ${INGRESS_SERVICE} ${INGRESS_PORT} ${PACKAGE_LABEL} ${INSTALL_NAMESPACE}
    ;;
    u | uninstall | teardown)
        deleteSequence ingress ${INGRESS_SERVICE} 
        deleteSequence service ${DOCKERNAME}-svc
        deleteSequence deployment ${DOCKERNAME}
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
        logHelpHead "packages/codeserver/helm.sh"
        logHelpContent i install "install codeserver package"
        logHelpContent u uninstall "uninstall codeserver package"
        logHelpContent open "open codeserver package"
        logHelpTail
    ;;
esac