#!/bin/bash
function usage()
{
    echo "USAGE"
    echo "./isp.sh --host=domain.com --ip=185.238.137.78 --pass=b25PH8N1xFst --install=7863344-OgCMFrAPwCf6R1It1539255337"

}

if ! [ -x "$(command -v ssh-copy-id)" ]; then
  echo 'Error: ssh-copy-id is not installed.' >&2
  sudo apt install -y ssh-copy-id 
  exit 1
fi

if ! [ -x "$(command -v sshpass)" ]; then
  echo 'Error: askpass is not installed.' >&2
  sudo apt install -y sshpass
  exit 1
fi



hostname=""
ip=""
pass=""
install=0

while [ "$1" != "" ]; do
    PARAM=`echo $1 | awk -F= '{print $1}'`
    VALUE=`echo $1 | awk -F= '{print $2}'`
    case $PARAM in
        -h | --help)
            usage
            exit
            ;;
        --install)
            install=1
            ikey=$VALUE
            ;;
        --host)
            hostname=$VALUE
            ;;
        --ip)
            ip=$VALUE
            ;;
        --pass)
            pass=$VALUE
            ;;        
        *)
            echo "ERROR: unknown parameter \"$PARAM\""
            usage
            exit 1
            ;;
    esac
    shift
done

if ! [ -f "$HOME/.ssh/id_rsa" ]; then
	echo "Generating ssh keys. Press enter everywhere";
	ssh-keygen -t rsa
fi
