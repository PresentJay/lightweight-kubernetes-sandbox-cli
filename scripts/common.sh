#!/bin/bash

# Author: PresentJay (정현재, presentj94@gmail.com)

case $(uname -s) in
    "Darwin"* | "Linux"*) export _OS_="linux" ;;
    "MINGW32"* | "MINGW64"* | "CYGWIN" ) export _OS_="windows" ;;
    *) logKill "this OS($(uname -s)) is not supported yet." ;;
esac


#######################
#### Log Functions ####
#######################

logKill() {
    echo >&2 "[ERROR] $@" && exit 1
}

logInfo() {
    echo "[INFO] $@"
}

logSuccess() {
    echo "[SUCCESS] $@"
}

logTest() {
    echo "[TEST] $@"
}

logHelpHead() {
    echo -e "\n$1 [Options ...]"
    logHelpContent h help "print help messages"
}

logHelpContent() {
    if [[ $# -gt 2 ]]; then
        param_cnt=1
        echo -en "\t["
        while (($param_cnt<$#)); do
            case ${param_cnt} in
                1)
                    echo -n "-"
                    echo -n "${!param_cnt}"
                ;;
                *)
                    echo -n ", --${!param_cnt}"
                ;;
            esac
            param_cnt=$((${param_cnt}+1))
        done
        echo -e "]: ${!param_cnt}"
    elif [[ $# -eq 2 ]]; then
        echo -e "\t[--$1]: $2"
    fi
}

logHelpTail() {
    echo -e "\n"
    exit 1
}

#########################
#### Check Functions ####
#########################

# param $1: command 동작을 확인하려는 대상
# example $1: "multipass", "kubectl", ...
checkPrerequisite() {
    silentRun=$($1 | grep "command not found: $1") && logKill "$1 unavailable"
    unset silentRun
}


# param $1: dash-param 인자에 대해서 공백 없이, one character
# example $1: "ie", "a", "iu" ...
checkOpt() {
    checkDash=$1
    shift
    while getopts ${checkDash}h-: OPT; do
        if [ $OPT = "-" ]; then
            OPT=${OPTARG%%=*}
            OPTARG=${OPTARG#$OPT}
            OPTARG=${OPTARG#=}
        fi
        case $OPT in
            *) echo $OPT ;;
            ?) eval "logKill parameter-fault" ;;
        esac
    done
}

# param $1: exist check하려는 env name (Upper-case)
# example $1: "ITER"
checkEnv() {
    [[ -n $(printenv | grep $1) ]] && logTest "$1 is exist" || logTest "$1 is not exist"
}

#########################
#### Shell Functions ####
#########################

deleteCmd() {
    if [[ -e $1 ]]; then
        echo -n "[DELETE] "
        rm -v $1
    fi
    if [[ -e /usr/local/bin/$1 ]]; then
        echo -n "[DELETE] "
        rm -v /usr/local/bin/$1
    fi
}

get_env() {
    ENV_LOC="./docker/.env"

    while read line; do
        if [[ -z $(echo ${line} | grep "#") ]]; then
            eval $line
        fi
    done < ${ENV_LOC}
}

### helm의 config permission error 제거 ###
chmod o-r ${KUBECONFIG_LOC}
chmod g-r ${KUBECONFIG_LOC}

get_env