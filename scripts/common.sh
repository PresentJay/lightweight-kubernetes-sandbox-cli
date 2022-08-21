#!/bin/bash
# 쉘스크립트 베이스코드입니다.

# Author: PresentJay (정현재, presentj94@gmail.com)


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

cautionRead() {
    echo -n "[CAUTION] $@"
}

bar() {
    echo -e "\n* * * * * * * * * * * * * * * * * * * * *\n"
}

# $1: size of blank line
line() {
    if [[ $# -eq 0 ]]; then
        echo -e "\n"
    elif [[ $# -eq 1 ]]; then
        iter=0
        until [[ $iter -le $1 ]]; do
            echo -e "\n"
            iter=$(( iter+1 ))
        done
    fi
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

# explain: 주어진 param 수를 검사
# $1: param 개수
checkParamAmount() {
    objAmount=$1
    shift
    [[ $# -eq $objAmount ]] && echo $TRUE || echo $FALSE
}

# $1: param
# $2: param이 없을 때 표시할 메세지
checkParamOrLog() {
    param=$1
    message=$2
    [[ -z $param ]] && logKill $message
}

# $1: namespace option
checkNamespaceOption() {
    namespace_option=$1
    if [[ -z $namespace_option ]]; then
        echo "default"
    else
        echo ${namespace_option}
    fi        
}

# explain: OS를 확인하여 mac, linux, windows 구분
# no param
checkOS(){
    case $(uname -s) in
        "Darwin"*) OSname="mac" ;;
        "Linux"*) OSname="linux" ;;
        "MINGW32"* | "MINGW64"* | "CYGWIN" ) OSname="win" ;;
        *) logKill "this OS($(uname -s)) is not supported yet." ;;
    esac
    echo ${OSname}
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

# $1: env file 위치
getEnv() {
    ENV_LOC=$1

    while read line; do
        if [[ -z $(echo ${line} | grep "#") ]]; then
            eval $line
        fi
    done < ${ENV_LOC}
}

# TODO: Kubeconfig 생성 시 그쪽으로 빼기
### helm의 config permission error 제거 ###
chmod o-r ${KUBECONFIG_LOC}
chmod g-r ${KUBECONFIG_LOC}

get_env "./docker/.env"