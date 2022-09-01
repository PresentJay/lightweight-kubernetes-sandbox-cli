#!/bin/bash
# 쿠버네티스 API 치트코드입니다.
# 리소스 관련 스크립트 등이 포함되어 있습니다.

# Author: PresentJay (정현재, presentj94@gmail.com)

source scripts/common.sh

# Prerequisite 검사 (kubectl, helm)
checkPrerequisite helm
checkPrerequisite kubectl

# TODO: pwd가 프로젝트 루트가 아닌 경우 스크립트가 동작하지 않도록 하는 조건문 추가 필요!

if [[ -e ${KUBECONFIG_LOC} ]]; then
    export KUBECONFIG=$(pwd)/${KUBECONFIG_LOC}
    hostEndpointIP=$(kubectl config view -o jsonpath="{.clusters[0].cluster.server}" | cut -d"/" -f3 | cut -d":" -f1)
    _clusterCount_=$(kubectl config view -o jsonpath="{.clusters}" | jq length)
    masterNodeIP=$(kubectl config view -o jsonpath="{.clusters[$((_clusterCount_-1))].cluster.server}" | cut -d"/" -f3 | cut -d":" -f1)
else
    echo "***<SYSLOG>***"
    echo "yet does not configed kubeconfig in your system."
    echo "if you run this system on multipass, try run [sodas-manager --node init]"
    echo "***</SYSLOG>***"
fi

# $1: type of kubernetes object
# $2: name of kubernetes object
# $3: namespace (optional)
checkObject() {
    # Validate
    checkParamOrLog $1 "need param 1: kubernetes object type"
    checkParamOrLog $2 "need param 2: kubernetes object name"

    # Check On Eyes Phase
    local _objType_=$1
    local _objName_=$2
    local _namespace_=$(checkNamespaceOption $3)

    # Do
    if [[ -n $(kubectl get ${_objType_} -n ${_namespace_} | grep ${_objName_}) ]]; then
        return $TRUE
    else
        logInfo "${_objType_}/${_objName_} could not found. . . BREAK"
        return $FALSE
    fi
}

# $1: object type
# $2: object name
# $3: namespace (optional)
deleteSequence() {
    # Validate
    checkParamOrLog $1 "need param 1: object type (ex. pod, namespace ...)"
    checkParamOrLog $2 "need param 2: object name (ex. podnametest1 ...)"

    # Check On Eyes Phase
    local _objectType_=$1
    local _objectName_=$2
    local _namespace_=$(checkNamespaceOption $3)
    
    case ${_objectType_} in
        helm)
            checkHelm ${_objectName_} ${_namespace_} \
                && loopToSuccess "helm uninstall ${_objectName_} -n ${_namespace_}"
        ;;
        helm-repo)
            checkHelmRepo ${_objectName_} \
                && loopToSuccess "helm repo remove ${_objectName_}"
        ;;
        namespace)
            checkNamespace ${_objectName_} \
                && loopToSuccess "kubectl delete ${_objectType_} ${_objectName_}"
        ;;
        serviceaccount | clusterrolebinding)
            checkObject ${_objectType_} ${_objectName_} \
                && loopToSuccess "kubectl delete ${_objectType_} ${_objectName_}"
        ;;
        *)
            checkObject ${_objectType_} ${_objectName_} ${_namespace_} \
                && loopToSuccess "kubectl delete ${_objectType_} ${_objectName_} -n ${_namespace_}"
                
            case ${_objectType_} in
                deployment)
                    # TODO
                ;;
                job)
                    # TODO
                ;;
                statefulset)
                    # TODO
                ;;
                *)
                    # TODO
                ;;
            esac
        ;;
    esac
}


##############
# *namespace #
##############

# $1: namespace name
checkNamespace() {
    if [[ -n $(kubectl get namespace $1) ]]; then
        return $TRUE
    else
        return $FALSE
    fi
}


############
# *ingress #
############

# # # CREATE (apply can create and update) # # #

applyIngressNginxHTTPS() {
    # Validate
    checkParamOrLog $1 "need param 1: hostName (ex. dashboard.kubernetes)"
    checkParamOrLog $2 "need param 2: serviceName (ex. kubernetes-dashboard)"
    checkParamOrLog $3 "need param 3: httpsPort (ex. 443)"
    checkParamOrLog $4 "need param 4: package name"

    # Check On Eyes Phase
    local _hostName_=$1
    local _serviceName_=$2
    local _httpsPort_=$3
    local _packageName_=$4
    local _namespace_=$(checkNamespaceOption $5)

    # Do
    cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ${_serviceName_}
  namespace: ${_namespace_}
  labels:
    package: ${_packageName_}
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/backend-protocol: https
    nginx.ingress.kubernetes.io/proxy-body-size: 1000000m
spec:
  tls:
    - hosts:
      - ${_hostName_}.${masterNodeIP}.nip.io
  rules:
    - host: ${_hostName_}.${masterNodeIP}.nip.io
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: ${_serviceName_}
                port:
                  number: ${_httpsPort_}
EOF
}

applyIngressNginxHTTP() {
    # Validate
    checkParamOrLog $1 "need param 1: hostName (ex. dashboard.kubernetes)"
    checkParamOrLog $2 "need param 2: serviceName (ex. kubernetes-dashboard)"
    checkParamOrLog $3 "need param 3: httpPort (ex. 80)"
    checkParamOrLog $4 "need param 4: package name"

    # Check On Eyes Phase
    local _hostName_=$1
    local _serviceName_=$2
    local _httpPort_=$3
    local _packageName_=$4
    local _namespace_=$(checkNamespaceOption $5)

    cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ${_serviceName_}
  namespace: ${_namespace_}
  labels:
    package: ${_packageName_}
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/proxy-body-size: 1000000m
spec:
  rules:
    - host: ${_hostName_}.${masterNodeIP}.nip.io
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: ${_serviceName_}
                port:
                  number: ${_httpPort_}
EOF
}

# # # GET # # #

# $1: ingress name
# $2: namespace (optional)
getIngressURL() {
    # Validate Phase
    checkParamOrLog $1 "need param 1: ingress name"
    
    # Check On Eyes Phase
    local _ingressName_=$1
    local _namespace_=$(checkNamespaceOption $2)

    # Do
    find=$(kubectl get ingress ${_ingressName_} -n ${_namespace_} | grep ${_ingressName_} | awk '{print $3}')

    if [[ -n ${find} ]]; then
        echo ${find}
    else
        return $FALSE
        logInfo "can't found ingress of ${_ingressName_}"
    fi
}

# TODO: ingress-nginx에 대해서만 로직 구현. traefik 등과 통합해서 쓰일 수 있도록 코드 확장 필요
# $1: http / https
# $2: ingress-controller service name
# $3: ingress-controller namespace (optional)
getIngressPort() {
    # Validate
    checkParamOrLog $1 "need param 1: \"http\" or \"https\""
    ! checkParamIsInList $1 "http" "https" && \
        logKill "param 1 should be  \"http\" or \"https\""    
    checkParamOrLog $2 "need param 2: ingress-controller service name"

    # Check On Eyes Phase
    local _protocol_=$1
    local _serviceName_=$2
    local _namespace_=$(checkNamespaceOption $3)
    case $1 in
        http) local _index_=0 ;;
        https) local _index_=1 ;;
    esac

    # Do
    case ${INGRESS} in
        ingress-nginx)
            find=$(kubectl get svc ${_serviceName_} -n ${_namespace_} -o jsonpath="{.spec.ports[${_index_}].nodePort}")
        ;;
        ? | *)
            logKill "supported ingress controller: \"ingress-nginx\""
        ;;
    esac

    if [[ -n ${find} ]]; then
        echo ${find}
    else
        hide=$(logInfo "can't found $1 port in your kubernetes environment. please check your ingress-controller")
        return $FALSE
    fi
}


############
# *service #
############

# # # CREATE (apply can create and update) # # #

# $1: svc name
# $2: port index
# $3: package name
# $4: namespace (optional)
applyService() {
    # Validate
    checkParamOrLog $1 "need param 1: svc name"
    checkParamOrLog $2 "need param 2: port index"
    checkParamOrLog $3 "need param 3: package name"

    # Check On Eyes Phase
    local _nameAndAppName_=$1
    local _targetPort_=$2
    local _packageName_=$3
    local _namespace_=$(checkNamespaceOption $4)

    # Do
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: ${_nameAndAppName_}
  namespace: ${_namespace_}
  labels:
    package: ${_packageName_}
spec:
  ports:
  - port: ${_targetPort_}
    targetPort: ${_targetPort_}
  selector:
    app: ${_nameAndAppName_}
EOF
}

# $1: svc name
# $2: http port index
# $3: https port index
# $4: package name
# $5: namespace (optional)
applyServiceFull() {
    # Validate
    checkParamOrLog $1 "need param 1: svc name"
    checkParamOrLog $2 "need param 2: http port index"
    checkParamOrLog $3 "need param 3: https port index"
    checkParamOrLog $4 "need param 4: package name"

    # Check On Eyes Phase
    local _nameAndAppName_=$1
    local _httpPort_=$2
    local _httpsPort_=$3
    local _packageName_=$4
    local _namespace_=$(checkNamespaceOption $5)

    # Do
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
    name: ${_nameAndAppName_}
    namespace: ${_namespace_}
    labels:
        package: ${_packageName_}
spec:
    ports:
    - name: http
        port: ${_httpPort_}
        targetPort: ${_httpPort_}
    - name: https
        port: ${_httpsPort_}
        targetPort: ${_httpsPort_}

  selector:
    app: ${_nameAndAppName_}
EOF
}



# # # GET # # #

# $1: svc name
# $2: port index
# #3: namespace name (optional)
getSvcNodePort() {
    # Validate
    checkParamOrLog $1 "need param 1: service name"
    checkParamOrLog $2 "need param 2: port index"

    # Check On Eyes Phase
    local _serviceName_=$1
    local _portIndex_=$2
    local _namespace_=$(checkNamespaceOption $3)

    # Do
    find=$(kubectl get svc $_serviceName_ -n ${_namespace_} -o jsonpath="{.spec.ports[$2].nodePort}")

    if [[ -n ${find} ]]; then
        echo ${find}
    else
        return $FALSE
    fi
}

# $1: svc name
# $2: port index
# #3: namespace name (optional)
getSvcPort() {
    # Validate
    checkParamOrLog $1 "need param 1: service name"
    checkParamOrLog $2 "need param 2: port index"

    # Check On Eyes Phase
    local _serviceName_=$1
    local _portIndex_=$2
    local _namespace_=$(checkNamespaceOption $3)

    # Do
    find=$(kubectl get svc $_serviceName_ -n ${_namespace_} -o jsonpath="{.spec.ports[$_portIndex_].port}")
    if [[ -n ${find} ]]; then
        echo ${find}
    else
        return $FALSE
    fi
}

########
# *pvc #
########

# # # CREATE (apply can create and update) # # #

# $1: pvc name
# $2: storageclass name
# $3: pvc amount
# $4: pvc units (Gi, Mi)
# $5: package name
# $6: namespace (optional)
applyPVC() {
    # Validate
    checkParamOrLog $1 "need param 1: pvc name"
    checkParamOrLog $2 "need param 2: storageclass name"
    checkParamOrLog $3 "need param 3: pvc amount"
    checkParamOrLog $4 "need param 4: pvc unit (Gi, Mi)"
    ! checkParamIsInList $4 "Gi" "Mi" && \
        logKill "param 4: pvc unit should be \"Gi\" or \"Mi\""
    checkParamOrLog $5 "need param 5: package name"
    
    # Check On Eyes Phase
    local _PVCname_=$1
    local _storageClassName_=$2
    local _PVCamount_=$3
    local _PVCunit_=$4
    local _packageName_=$5
    local _namespace_=$(checkNamespaceOption $6)

    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ${_PVCname_}
  namespace: ${_namespace_}
  labels:
    package: ${_packageName_}
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: ${_storageClassName_}
  resources:
    requests:
      storage: ${_PVCamount_}${_PVCunit_}
EOF
}


###################
# *ServiceAccount #
###################

# # # CREATE (apply can create and update) # # #

# param $1: ServiceAccountname
# param $2: namespace (optional)
createSA() {
    # Validate
    checkParamOrLog $1 "need param 1: ServiceAccount name"

    # Check On Eyes Phase
    local _SAname_=$1
    local _namespace_=$(checkNamespaceOption $2)

    # Do
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ${_SAname_}
  namespace: ${_namespace_}
EOF
}


#######################
# *ClusterRoleBinding #
#######################

# # # CREATE (apply can create and update) # # #

# param $1: ServiceAccount name
# param $2: Role name
# param $3: namespace (optional)
createCRB() {
    # Validate
    checkParamOrLog $1 "need param 1: ServiceAccount name"
    checkParamOrLog $2 "need param 2: Role name"

    # Check On Eyes Phase
    local _SAname_=$1
    local _roleName_=$2
    local _namespace_=$(checkNamespaceOption $3)

    # Do
    cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: ${_SAname_}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: ${_roleName_}
subjects:
  - kind: ServiceAccount
    name: ${_SAname_}
    namespace: ${_namespace_}
EOF
}



#########
# *helm #
#########

# param $1: helm repo name
# examples: "helm_repo_check ${somereponame}"
checkHelmRepo() {
    if [[ -n $(helm repo ls | grep $1) ]]; then
        logInfo "helm repo \"$1\" is already installed."
        return $TRUE
    else
        return $FALSE
    fi
}

# param $1: helm chart name
# examples: "helm_check ${somehelmchartname}"
checkHelm() {
    if [[ -n $(helm ls --all-namespaces | grep $1) ]]; then
        logInfo "\"$1\" installation is already in helm."
        return $TRUE
    else
        return $FALSE
    fi
}


###########################
# *Monitoring(Prometheus) #
###########################

applyServiceMonitor() {
    # Validate
    checkParamOrLog $1 "need param 1: monitorName (ex. longhorn-manager-monitor)"
    checkParamOrLog $2 "need param 2: portName (ex. manager)"
    checkParamOrLog $3 "need param 3: labelName (ex. app)"
    checkParamOrLog $4 "need param 4: labelValue (ex. longhorn-manager)"

    # Check On Eyes Phase
    local _monitorName=$1
    local _portName_=$2
    local _labelName_=$3
    local _labelValue_=$4
    local _namespace_=$(checkNamespaceOption $5)

    # Do
    cat <<EOF | kubectl apply -f -
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: ${_monitorName}
  namespace: ${_namespace_}
spec:
  selector:
    matchLabels:
      ${_labelName_}: ${_labelValue_}
  namespaceSelector:
    matchNames:
      - ${_namespace_}
  endpoints:
  - port: ${_portName_}
EOF
}
