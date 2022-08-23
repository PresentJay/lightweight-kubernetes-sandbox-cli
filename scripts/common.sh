#!/bin/bash
# 쉘스크립트 베이스코드입니다.

# Author: PresentJay (정현재, presentj94@gmail.com)


# explain: ITERATION_LIMIT 회에 걸쳐 성공하기까지 반복하는 function (log 남김)
# $@: command
# examples
# -> "loop_to_success (somecommand)"
loop_to_success() {
    silentMode=$FALSE
    [ $1 = "--silent" ] && silentMode=$TRUE
    ITER=0
    while :
    do
        ITER=$(( ITER+1 ))
        # silentMode &&
        echo "try to exec command: '$@' (${ITER}/${ITERATION_LIMIT} trials)"
        eval $@ && break
        sleep ${ITERATION_LATENCY}
        if [[ ITER -eq ${ITERATION_LIMIT} ]]; then logKill "command iteration is close to limit > exit. (${ITER}/${ITERATION_LIMIT} failed)"; fi;
    done
}

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
        paramCnt=1
        echo -en "\t["
        while (( ${paramCnt} < $# )); do
            case ${{paramCnt}} in
                1)
                    echo -n "-"
                    echo -n "${!{paramCnt}}"
                ;;
                *)
                    echo -n ", --${!{paramCnt}}"
                ;;
            esac
            {paramCnt}=$((${{paramCnt}}+1))
        done
        echo -e "]: ${!{paramCnt}}"
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
    _objAmount_=$1
    shift
    [[ $# -eq $_objAmount_ ]] && echo $TRUE || echo $FALSE
}

# $1: param
# $2: param이 없을 때 표시할 메세지
checkParamOrLog() {
    _param_=$1
    _message_=$2
    [[ -z $_param_ ]] && logKill $_message_
}

# $1: namespace option
checkNamespaceOption() {
    _namespace_option_=$1
    if [[ -z ${_namespace_option_} ]]; then
        echo "default"
    else
        echo ${namespace_option}
    fi        
}

# explain: OS를 확인하여 mac, linux, windows 구분
# no param
checkOS() {
    case $(uname -s) in
        "Darwin"* | "Linux"*) _OSname_="linux" ;;
        "MINGW32"* | "MINGW64"* | "CYGWIN" ) _OSname_="win" ;;
        *) logKill "this OS($(uname -s)) is not supported yet." ;;
    esac
    echo ${_OSname_}
}

# $1: answer variable
checkYorN() {
    if [[ $1 = "y" ]]; then
        return $TRUE
    elif [[ $1 = "n" ]]; then
        return $FALSE
    fi
}

# $1: given param
# $2: array of param available list (separated with a space) : [something1 something2 ...]
checkParamIsInList() {
    _givenParam_=$1
    shift
    _availableParamList_=$@

    for _availableParam_ in ${_availableParamList_[@]}; do
        [ ${_givenParam_} = ${_availableParam_} ] && return $TRUE
    done
    return $FALSE
}


#########################
#### Shell Functions ####
#########################

# $1: delete할 Cmd File (linux의 경우 명령어 설정까지 함께 삭제)
deleteCmd() {
    if [[ -e $1 ]]; then
        echo -n "[DELETE] "
        rm -v $1
    fi
    if [ $(checkOS) = "linux" ] && [ -e /usr/local/bin/$1 ]; then
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

# $1: answer variable (will be export)
# $2: question string
getYorN() {
    unset $1
    while :
    do
        cautionRead "$2 (y/n): "
        read temp
        [[ ${temp} == "y" ]] && break
        [[ ${temp} == "n" ]] && break
        logInfo "write just 'y' or 'n' please"
    done
    eval "$1=${temp}"
}


getEnv "./config/.env"

# TODO: pwd가 프로젝트 루트가 아닌 경우 스크립트가 동작하지 않도록 하는 조건문 추가 필요!
