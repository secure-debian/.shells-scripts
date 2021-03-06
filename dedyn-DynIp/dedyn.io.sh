#!/bin/bash
# this is used to create,update or delete A *and* AAAA records DynIp
# read vars conf file is:
# DOMAIN=xxx.dedyn.io
# TOKEN=123456789123456789


DIR=~/git/dedyn
CONF=$DIR/config.file
# set vars
source $CONF
HOSTNAME=`hostname`
FQDN="$HOSTNAME"."$DOMAIN"


### start define functions ###
function_check_executables () {
    if ! [ -x "$(command -v dig)" ]; then
        echo "freebsd: pkg install bind-tools"
        echo "debian: apt install dnsutils"
        echo 'Error: dig is not installed.' >&2
        exit 1
    fi
    if ! [ -x "$(command -v curl)" ]; then
        echo 'Error: curl is not installed.' >&2
        exit 1
    fi
}

function_get_IPv6 () {
    case $(uname) in
        FreeBSD)
            IPv6=`ifconfig | grep inet6 | grep -v deprecated | awk '{print $2}' | grep '^2'`
            PREFIX=`ndp -p | grep '^2' | awk '{print $1}' | sed 's/::\/64//g'`
            ;;
        Linux)
            IPv6=`ip -6 a | grep inet6 | grep -v deprecated | awk '{print $2}'| grep '^2'  | sed 's/\/64//g'`
            PREFIX=`ip -6 r s | grep '^2' | head -1 | awk '{print $1}' | sed 's/::\/64//g'`
            ;;
        Darwin)
            echo "Der feine Herr :-D"
            exit 1
            ;;
        *)
        echo "OS not supported"
        exit 1
    esac
}

function_update_A () {
    curl -X PATCH https://desec.io/api/v1/domains/$DOMAIN/rrsets/$HOSTNAME/A/ --header "Authorization: Token $TOKEN" --header "Content-Type: application/json" --data @- <<< '{"subname": "'$HOSTNAME'", "type": "A", "ttl": 3600, "records": ["'$IPv4'"]}'
}

function_update_AAAA () {
    curl -X PATCH https://desec.io/api/v1/domains/$DOMAIN/rrsets/$HOSTNAME/AAAA/ --header "Authorization: Token $TOKEN" --header "Content-Type: application/json" --data @- <<< '{"subname": "'$HOSTNAME'", "type": "AAAA", "ttl": 3600, "records": ["'$IPv6'"]}'
    printf "\n"
}

function_create_AAAA () {
    curl -X POST https://desec.io/api/v1/domains/$DOMAIN/rrsets/ --header "Authorization: Token $TOKEN" --header "Content-Type: application/json" --data @- <<< '{"subname": "'$HOSTNAME'", "type": "AAAA", "ttl": 3600, "records": ["'$IPv6'"]}'
    printf "\n"
}

function_create_A () {
    curl -X POST https://desec.io/api/v1/domains/$DOMAIN/rrsets/ --header "Authorization: Token $TOKEN" --header "Content-Type: application/json" --data @- <<< '{"subname": "'$HOSTNAME'", "type": "A", "ttl": 3600, "records": ["'$IPv4'"]}'
}

function_check_AAAA () {
    #change like function_check_A
    dig AAAA $FQDN +short
    if [[ $? -eq 0 ]]; then
        AAAA=`dig AAAA $FQDN +short`
        if [[ $AAAA == *"$PREFIX"* ]]; then
           return 0
           #echo "OK6"
        else
        #   echo "update6"
            function_update_AAAA
        fi
    else
        #echo "create6"
        function_create_AAAA
    fi
}
function_check_A () {
    IPv4=`curl -s https://checkipv4.dedyn.io/`
    currentA=`dig $FQDN +short`
    if [ -z "$currentA" ];then
        #echo "create4"
        function_create_A
    else
        if [[ $IPv4 == $currentA ]];then
            return 0
            #echo "OK4"
        else
        #       echo "update4"
            function_update_A
        fi
    fi
    }
### end define functions ###


function_check_executables
if [ -n "$1" ]; then #not empty
    if [ $1 = 4 ];then
        #echo "IPv4 only"
        function_check_A
        exit 1
    fi
    if [ $1 = 6 ];then
        #echo "IPv6 only"
        function_get_IPv6
        function_check_AAAA 
        exit 1
    fi
    if [ $1 = d ];then
        #echo "dualstack"
        function_get_IPv6
        function_check_AAAA
        function_check_A
        exit 1
    fi
    if [ $1 = s ];then
        SSHFP=`ssh-keygen -r sid | awk '{print $6}' | sed -n '6 p'`
        # 6. ECDSA SHA256
        #echo $SSHFP
        curl -X POST https://desec.io/api/v1/domains/$DOMAIN/rrsets/ --header "Authorization: Token $TOKEN" --header "Content-Type: application/json" --data @- <<< '{"subname": "'$HOSTNAME'", "type": "SSHFP", "ttl": 3600, "records": ["3 2 '$SSHFP'"]}'
        exit 1
    fi
    if [ $1 = X ];then
        echo "delete: just set localhost adresses"
        curl -X PATCH https://desec.io/api/v1/domains/$DOMAIN/rrsets/$HOSTNAME/AAAA/ --header "Authorization: Token $TOKEN" --header "Content-Type: application/json" --data @- <<< '{"subname": "'$HOSTNAME'", "type": "AAAA", "ttl": 3600, "records": ["::1"]}'
        curl -X PATCH https://desec.io/api/v1/domains/$DOMAIN/rrsets/$HOSTNAME/A/ --header "Authorization: Token $TOKEN" --header "Content-Type: application/json" --data @- <<< '{"subname": "'$HOSTNAME'", "type": "A", "ttl": 3600, "records": ["127.0.0.1"]}'
    else
        echo "Variables are 4 6 (d)ualstack (s)SHFP or X delete"
        exit 0
    fi
else
    echo "First parameter not supplied."
    exit 1
fi

# if [[ $DEBUG == "1" ]]; then
#     #detect public IPv4
#     IPv4=`curl https://checkipv4.dedyn.io/`
#     echo "DEBUG"
#     echo "CONF="$CONF
#     echo "DOMAIN="$DOMAIN
#     echo "TOKEN="$TOKEN
#     echo "HOSTNAME="$HOSTNAME
#     echo "IPv6="$IPv6
#     echo "IPv4="$IPv4
#     echo "FQDN="$FQDN
# else
