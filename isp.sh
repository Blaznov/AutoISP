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
echo '
#!/bin/bash
apt update 
apt upgrade -y

apt install -y apt-transport-https lsb-release ca-certificates isp-php72 isp-php72-fpm screen vim
wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/php.list

apt update 
apt upgrade -y

echo -n "updating isp... "
/usr/local/mgr5/sbin/pkgupgrade.sh coremanager

echo -n "installing letsencrypt..."
/usr/local/mgr5/sbin/mgrctl -m ispmgr plugin clicked_button=install name=ispmanager-plugin-letsencrypt sok=ok

echo -n "installing ftp... "
/usr/local/mgr5/sbin/mgrctl -m ispmgr feature.edit clicked_button=ok elid=ftp  packagegroup_ftp=proftp  sok=ok

echo -n "installing php... "
/usr/local/mgr5/sbin/mgrctl -m ispmgr feature.edit clicked_button=ok elid=altphp72  packagegroup_altphp72gr=ispphp72 package_ispphp72_fpm=on sok=ok

/usr/local/mgr5/sbin/mgrctl -m ispmgr feature.edit clicked_button=ok elid=ispphp72  packagegroup_altphp72gr=ispphp72 package_ispphp72_fpm=on sok=ok > /dev/null 2>&1

sleep 15

echo -n "enabling php... "
/usr/local/mgr5/sbin/mgrctl -m ispmgr services.enable clicked_button=ok elid=php-fpm72 sok=ok

echo -n "installing nginx... "
/usr/local/mgr5/sbin/mgrctl -m ispmgr feature.edit clicked_button=ok elid=web package_nginx=on package_php=off package_php-fpm=on packagegroup_apache=turn_off  sok=ok

sleep 15

' | ssh $hostname "cat > /root/ispscript"

ssh $hostname bash /root/ispscript

IP=$(ssh $hostname wget -qO- ipinfo.io/ip)
scp tracker root@${IP}:/etc/nginx
echo "https://${IP}:1500/ispmgr?func=auth&authinfo=root:${pass}"
echo "ALL DONE"