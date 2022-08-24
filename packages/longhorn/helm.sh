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
        logHelpHead "packages/longhorn/helm.sh"
        logHelpContent i install "install longhorn package"
        logHelpContent u uninstall "uninstall longhorn package"
        logHelpTail
    ;;
esac