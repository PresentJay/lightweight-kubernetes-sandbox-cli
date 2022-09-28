#!/bin/bash
# awx 관련 치트코드입니다.

# Author: PresentJay (정현재, presentj94@gmail.com)

source scripts/kubecheats.sh
getEnv ./packages/ansible-awx/.env

applyAWX() {
    cat <<EOF | kubectl apply -f -
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: ${INSTALL_NAME}
  namespace: ${INSTALL_NAMESPACE}
  labels:
    package: ${PACKAGE_LABEL}
spec:
  service_type: ClusterIP
  projects_persistence: true
  projects_storage_class: ${STORAGE}
  projects_storage_size: ${WEB_PVC_SIZE}
  postgres_storage_class: ${STORAGE}
  postgres_storage_requirements: { requests: {storage: ${DB_PVC_SIZE}} }
  postgres_extra_args:
    - '-c'
    - 'max_connections=1000'
  admin_user: ${ADMIN_USER}
  admin_password_secret: ${ADMIN_USER}-secret
  admin_email: ${ADMIN_EMAIL}
  security_context_settings:
    runAsGroup: 0
    runAsUser: 0
    fsGroup: 0
    fsGroupChangePolicy: OnRootMismatch
EOF
}