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

if [ "$hostname" == "" ] || [ "$pass" == "" ] || [ "$ip" == "" ]; then
	echo "ERROR";
	usage
	exit 1
fi

if ! [ -f "$HOME/.ssh/id_rsa" ]; then
	echo "Generating ssh keys. Press enter everywhere";
	ssh-keygen -t rsa
fi

if ! (cat ~/.ssh/config | grep -q "Host $hostname"); then
	echo "Host $hostname
	HostName $ip
	Port 22
	User root
	Compression yes
	" >> ~/.ssh/config
	#echo sshpass -p "$pass" ssh-copy-id -i ~/.ssh/id_rsa $hostname
fi

sshpass -p "$pass" ssh-copy-id -i ~/.ssh/id_rsa $hostname

if ! (ssh -o PreferredAuthentications=publickey $hostname echo ok); then
echo 'ssh key installation failed';
exit 1
fi

if [ "$install" == "1" ]; then
	
	echo "#!/bin/bash
	export ACTIVATION_KEY=$ikey
	cd
	wget http://cdn.ispsystem.com/install.sh
	(echo s; echo 2) | sh install.sh ISPmanager" | ssh $hostname "cat > /root/ispinst"
	
	ssh $hostname bash /root/ispinst

fi