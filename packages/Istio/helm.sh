#!/bin/bash

# Author: PresentJay (정현재, presentj94@gmail.com)

source ./scripts/kubecheats.sh
getEnv ./packages/Istio/.env

case $(checkOpt iu $@) in
    i | install)
        ! checkHelmRepo ${CHART_REPOSITORY_NAME} && \
            helm repo add ${CHART_REPOSITORY_NAME} ${CHART_REGISTRY} && helm repo update
        ! checkNamespace ${INSTALL_NAMESPACE} && \
            kubectl create namespace ${INSTALL_NAMESPACE}

        # Istio's control-plain (cluster resources)
        helm upgrade ${CHART_REPOSITORY_NAME}-${INSTALL_BASE} ${CHART_REPOSITORY_ORG}/${INSTALL_BASE} \
            --namespace ${INSTALL_NAMESPACE} \
            --install \
            --no-hooks

        # Istiod Service)
        helm upgrade ${INSTALL_ISTIOD} ${CHART_REPOSITORY_NAME}/${INSTALL_ISTIOD} \
            --namespace ${INSTALL_NAMESPACE} \
            --install \
            --no-hooks \
            --wait
        
        # Ingress Gateway
        ! checkNamespace ${INSTALL_INGRESS_NAMESPACE} && \
            kubectl create namespace ${INSTALL_INGRESS_NAMESPACE} && \
            kubectl label namespace ${INSTALL_INGRESS_NAMESPACE} istio-injection=enabled
        helm upgrade ${INSTALL_INGRESS_NAMESPACE} ${CHART_REPOSITORY_NAME}/${INSTALL_INGRESS} \
            --namespace ${INSTALL_INGRESS_NAMESPACE} \
            --install \
            --no-hooks \
            --wait \
            --set service.type="NodePort"
    ;;
    u | uninstall | teardown)
        if [[ $2 = "CRD" ]]; then
            kubectl get crd -oname | grep --color=never 'istio.io' | xargs kubectl delete
        else
            deleteSequence helm ${INSTALL_INGRESS_NAMESPACE} ${INSTALL_INGRESS_NAMESPACE}
            deleteSequence namespace ${INSTALL_INGRESS_NAMESPACE}
            deleteSequence helm ${INSTALL_ISTIOD} ${INSTALL_NAMESPACE}
            deleteSequence helm ${INSTALL_NAMESPACE}-${INSTALL_BASE} ${INSTALL_NAMESPACE}
            deleteSequence namespace ${INSTALL_NAMESPACE}
            deleteSequence helm-repo ${CHART_REPOSITORY_NAME}
        fi
    ;;
    httpsPort)
        echo $(getSvcNodePort ${INSTALL_INGRESS_NAMESPACE} 2 ${INSTALL_INGRESS_NAMESPACE})
    ;;
    httpPort)
        echo $(getSvcNodePort ${INSTALL_INGRESS_NAMESPACE} 1 ${INSTALL_INGRESS_NAMESPACE})
    ;;
    status) helm status ${INSTALL_ISTIOD} -n ${INSTALL_NAMESPACE} ;;
    values)
        if checkParamIsInList $2 ${INSTALL_BASE} ${INSTALL_ISTIOD} ${INSTALL_INGRESS}; then
            helm show values ${CHART_REPOSITORY_NAME}/$2
        else
            logKill "only ${INSTALL_BASE}/${INSTALL_ISTIOD}/${INSTALL_INGRESS} available."
        fi
    ;;
    h | help | ? | *)
        logHelpHead "packages/Istio/helm.sh"
        logHelpContent i install "install Istio package"
        logHelpContent u uninstall "uninstall Istio package"
        logHelpContent httpsPort "return https port of Istio Ingress"
        logHelpContent httpPort "return http port of Istio Ingress"
        logHelpContent status "get Istiod's status"
        logHelpContent values "get Istio chart's values"
        logHelpTail
    ;;
esac