#!/bin/bash

# Author: PresentJay (정현재, presentj94@gmail.com)

source ./scripts/kubecheats.sh
getEnv ./packages/typescript-web/.env

case $(checkOpt iu $@) in
    init)
        applyPVC git-vol ${STORAGE} ${GIT_PVC_SIZE} ${GIT_PVC_UNIT} ${PACKAGE_LABEL} ${INSTALL_NAMESPACE}
        kubectl apply -f packages/typescript-web/cloner.yaml
    ;;
    clean-job)
        deleteSequence job git-cloner
    ;;
    i | install)
        kubectl apply -f packages/typescript-web/type-web.yaml
        applyIngressNginxHTTP ${INGRESS_HOSTNAME} ${INGRESS_SERVICE} ${INGRESS_PORT} ${PACKAGE_LABEL} ${INSTALL_NAMESPACE}
    ;;
    u | uninstall | teardown)
        deleteSequence ingress ${INGRESS_SERVICE} 
        deleteSequence service ${DOCKERNAME}-svc
        deleteSequence deployment ${DOCKERNAME}
        deleteSequence pvc git-vol
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
        logHelpHead "packages/typescript-web/docker.sh"
        logHelpContent i install "install typescript-web package"
        logHelpContent u uninstall "uninstall typescript-web package"
        logHelpTail
    ;;
esac