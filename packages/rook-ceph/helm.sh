#!/bin/bash

# Author: PresentJay (정현재, presentj94@gmail.com)

source ./scripts/common.sh

# Prerequisite 검사 (kubectl, helm)
checkPrerequisite helm
checkPrerequisite kubectl

case $(checkOpt iub $@) in
    i | install)

    ;;
    u | uninstall | teardown)

    ;;
    h | help | ? | *)
        logHelpHead "packages/rook-ceph/helm.sh"
        logHelpContent i install "install rook-ceph package"
        logHelpContent u uninstall "uninstall rook-ceph package"
        logHelpTail
    ;;
esac