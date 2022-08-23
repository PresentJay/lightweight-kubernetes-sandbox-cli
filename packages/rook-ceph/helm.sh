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
    conf-update)

    ;;
    conf-delete)

    ;;
    conf-check)

    ;;
    conf-add)

    ;;
esac