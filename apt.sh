#!/bin/bash
# plugin to set "apt" proxy settings for ProxyMan
# privileges has to be set by the process which starts this script


CONF_FILE=`readlink -f /etc/apt/apt.conf`

fix_new_line() {
    if [[ $(tail -c 1 "$CONF_FILE" | wc --lines ) = 0 ]]; then
        echo >> "$1"
    fi
}

list_proxy() {
    # inefficient way as the file is read twice.. think of some better way
    echo
    echo "${blue}APT proxy settings: ${normal}"
    lines="$(cat $CONF_FILE | grep proxy -i | wc -l)"
    if [ "$lines" -gt 0 ]; then
        cat "$CONF_FILE" | grep proxy -i | sed -e 's/^/ /'
    else
        echo "${red}None${normal}"
    fi
}

unset_proxy() {
    if [ ! -e "$CONF_FILE" ]; then
        return
    fi
    if [ "$(cat $CONF_FILE | grep proxy -i | wc -l)" -gt 0 ]; then
        sed -E "/^Acquire::(.)*::proxy/Id" $CONF_FILE -i
    fi
    echo "${blue}APT proxy unset ${normal}"
}

set_proxy() {
    unset_proxy
    if [ ! -e "$CONF_FILE" ]; then
        touch "$CONF_FILE"
    fi

    local stmt=""
    if [ "$use_auth" = "y" ]; then
        stmt="${username}:${password}@"
    fi

    # caution: do not use / after stmt
    echo "Acquire::HTTP::Proxy \"http://${stmt}${http_host}:${http_port}\";" \
         >> "$CONF_FILE"
    if [ "$USE_HTTP_PROXY_FOR_HTTPS" = "true" ]; then
        echo "Acquire::HTTPS::Proxy \"http://${stmt}${https_host}:${https_port}\";" \
         >> "$CONF_FILE"
    else
        echo "Acquire::HTTPS::Proxy \"https://${stmt}${https_host}:${https_port}\";" \
         >> "$CONF_FILE"
        echo "setting https as https"
    fi
    echo "Acquire::FTP::Proxy \"ftp://${stmt}${ftp_host}:${ftp_port}\";" \
         >> "$CONF_FILE"
    list_proxy
}


which apt &> /dev/null
if [ "$?" != 0 ]; then
    exit
fi

if [ "$#" = 0 ]; then
    exit
fi

what_to_do=$1
case $what_to_do in
    set) set_proxy
         ;;
    unset) unset_proxy
           ;;
    list) list_proxy
          ;;
    *)
          ;;
esac
