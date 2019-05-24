#!/bin/bash
##########################
# LME Deploy Script 	 #
# Version 0.1 - 27/03/19 #
##########################
# This script configures a host for LME including generating certificates and populating configuration files.
# A number of arguments can be passed to this script to override the default options
# "-c true" - use self made certs placed in certs/nginx.crt and certs/nginx.key


function generatepassword() {
nginx_plain_password=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

}

function setpassword() {
	nginx_plain_password=KIBANA_PASSWORD
}

function populatepassword() {
nginx_password=$(echo $nginx_plain_password | openssl passwd -noverify -stdin -apr1)
echo admin:$nginx_password | docker secret create nginx_unpw -
echo $nginx_plain_password | docker secret create nginx_plainpass -	

}

function zipfiles(){
#zip the files to allow the user to download them for the WLB install.
#copy them to home to start with
apt-get install zip -y
mkdir /tmp/lme
cp ~/lme/Chapter\ 3\ Files/winlogbeat.yml /tmp/lme/
cp ~/lme/Chapter\ 3\ Files/certs/wlbclient.crt /tmp/lme/
cp ~/lme/Chapter\ 3\ Files/certs/wlbclient.key /tmp/lme/
cp ~/lme/Chapter\ 3\ Files/certs/root-ca.crt /tmp/lme/
sed -i "s/logstash_dns_name/$logstashcn/g" /tmp/lme/winlogbeat.yml
zip -r ~/files_for_windows.zip /tmp/lme
chown ubuntu:ubuntu ~/files_for_windows.zip
}


function generatecerts() {
#configure certificate authority
mkdir certs

#make a new key for the root ca
echo "making root CA"
openssl genrsa -out certs/root-ca.key 4096

#make a cert signing request for this key 
openssl req -new -key certs/root-ca.key -out certs/root-ca.csr -sha256 -subj '/C=GB/ST=UK/L=London/O=Docker/CN=Swarm'

#Set openssl so that this root can only sign certs and not sign intermediates
echo "[root_ca]" > certs/root-ca.cnf
echo "basicConstraints = critical,CA:TRUE,pathlen:1" >> certs/root-ca.cnf
echo "keyUsage = critical, nonRepudiation, cRLSign, keyCertSign" >> certs/root-ca.cnf
echo "subjectKeyIdentifier=hash" >> certs/root-ca.cnf

#sign the root ca
echo "Sign root CA"
openssl x509 -req  -days 3650  -in certs/root-ca.csr -signkey certs/root-ca.key -sha256 -out certs/root-ca.crt -extfile certs/root-ca.cnf -extensions root_ca

##nginx
#make a new key for nginx (proxy infront of kibana)
echo "Making nginx Cert"
openssl genrsa -out certs/nginx.key 4096

#make a cert signing request for nginx
openssl req -new -key certs/nginx.key -out certs/nginx.csr -sha256 -subj '/C=GB/ST=UK/L=London/O=Docker/CN=Kibana'

#set openssl so that this cert can only perform server auth and cannot sign certs
echo "[server]" > certs/nginx.cnf
echo "authorityKeyIdentifier=keyid,issuer" >> certs/nginx.cnf
echo "basicConstraints = critical,CA:FALSE" >> certs/nginx.cnf
echo "extendedKeyUsage=serverAuth" >> certs/nginx.cnf
echo "keyUsage = critical, digitalSignature, keyEncipherment" >> certs/nginx.cnf
#echo "subjectAltName = DNS:localhost, IP:127.0.0.1" >> certs/nginx.cnf
echo "subjectKeyIdentifier=hash" >> certs/nginx.cnf

#sign the nginx cert
echo "Sign nginx cert"
openssl x509 -req -days 750 -in certs/nginx.csr -sha256 -CA certs/root-ca.crt -CAkey certs/root-ca.key -CAcreateserial -out certs/nginx.crt -extfile certs/nginx.cnf -extensions server


##logstash server
#make a new key for logstash 
echo "Making logstash Cert"
openssl genrsa -out certs/logstash.key 4096

#make a cert signing request for logstash
openssl req -new -key certs/logstash.key -out certs/logstash.csr -sha256 -subj "/C=GB/ST=UK/L=London/O=Docker/CN=$logstashcn"

#set openssl so that this cert can only perform server auth and cannot sign certs
echo "[server]" > certs/logstash.cnf
echo "authorityKeyIdentifier=keyid,issuer" >> certs/logstash.cnf
echo "basicConstraints = critical,CA:FALSE" >> certs/logstash.cnf
echo "extendedKeyUsage=serverAuth" >> certs/logstash.cnf
echo "keyUsage = critical, digitalSignature, keyEncipherment" >> certs/logstash.cnf
echo "subjectAltName = DNS:"$logstashcn", IP:" $logstaship >> certs/logstash.cnf
echo "subjectKeyIdentifier=hash" >> certs/logstash.cnf

#sign the logstash cert
echo "Sign logstash cert"
openssl x509 -req -days 750 -in certs/logstash.csr -sha256 -CA certs/root-ca.crt -CAkey certs/root-ca.key -CAcreateserial -out certs/logstash.crt -extfile certs/logstash.cnf -extensions server
mv certs/logstash.key certs/logstash.key.pem && openssl pkcs8 -in certs/logstash.key.pem -topk8 -nocrypt -out certs/logstash.key

##winlogbeat client
#make a new key for winlogbeat client 
echo "Making wlbclient Cert"
openssl genrsa -out certs/wlbclient.key 4096

#make a cert signing request for wlbclient
openssl req -new -key certs/wlbclient.key -out certs/wlbclient.csr -sha256 -subj '/C=GB/ST=UK/L=London/O=Docker/CN=wlbclient'

#set openssl so that this cert can only perform server auth and cannot sign certs
echo "[server]" > certs/wlbclient.cnf
echo "authorityKeyIdentifier=keyid,issuer" >> certs/wlbclient.cnf
echo "basicConstraints = critical,CA:FALSE" >> certs/wlbclient.cnf
echo "extendedKeyUsage=clientAuth" >> certs/wlbclient.cnf
echo "keyUsage = critical, digitalSignature, keyEncipherment" >> certs/wlbclient.cnf
#echo "subjectAltName = DNS:localhost, IP:127.0.0.1" >> certs/wlbclient.cnf
echo "subjectKeyIdentifier=hash" >> certs/wlbclient.cnf

#sign the wlbclient cert
echo "Sign wlbclient cert"
openssl x509 -req -days 750 -in certs/wlbclient.csr -sha256 -CA certs/root-ca.crt -CAkey certs/root-ca.key -CAcreateserial -out certs/wlbclient.crt -extfile certs/wlbclient.cnf -extensions server


}

function populatecerts() {
#add to docker secrets
echo "add certs and keys"

#ca cert
docker secret create ca.crt certs/root-ca.crt

#nginx
docker secret create nginx.key certs/nginx.key
docker secret create nginx.crt certs/nginx.crt

#logstash
docker secret create logstash.key certs/logstash.key
docker secret create logstash.crt certs/logstash.crt
}

function confignginx() {
#create nginx conf
echo "##########################" > nginx.conf
echo "# LME Deploy Script 	   #" >> nginx.conf
echo "# Version 0.1 - 27/03/19 #" >> nginx.conf
echo "##########################" >> nginx.conf
echo "upstream kibanaus {" >> nginx.conf
echo "server kibana:5601;" >> nginx.conf
echo "}" >> nginx.conf
echo "server {" >> nginx.conf
echo "listen                443 ssl;" >> nginx.conf
echo "server_name           localhost;" >> nginx.conf
echo ""
echo "ssl_protocols TLSv1.2 TLSv1.3;" >> nginx.conf
echo "ssl_prefer_server_ciphers on;" >> nginx.conf
echo "ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384;" >> nginx.conf
echo ""
echo "ssl_certificate       /run/secrets/nginx.crt;" >> nginx.conf
echo "ssl_certificate_key   /run/secrets/nginx.key;" >> nginx.conf
echo " " >> nginx.conf
echo "location / {" >> nginx.conf
echo "auth_basic \"LME Admin\";" >> nginx.conf
echo "auth_basic_user_file /run/secrets/nginx_unpw;" >> nginx.conf
echo "proxy_pass http://kibanaus;" >> nginx.conf
echo "}" >> nginx.conf
echo "}" >> nginx.conf
}

function provisionconfig() {
#add nginx conf to containers
docker config create nginx.conf nginx.conf

#add logstash conf to config
docker config create logstash.conf logstash.conf
}

function configuredocker() {
sysctl -w vm.max_map_count=262144
SYSCTL_STATUS=$( grep vm.max_map_count /etc/sysctl.conf )
if [ SYSCTL_STATUS == "vm.max_map_count=262144" ]; then
	echo "SYSCTL already configured"
else
	echo "vm.max_map_count=262144" >> /etc/sysctl.conf
fi

#RAM_COUNT="$(awk '( $1 == "MemTotal:" ) { print $2/1048576 }' /proc/meminfo | xargs printf "%.*f\n" 0 | xargs -I bob expr bob / 2)"
RAM_COUNT="$(awk '( $1 == "MemAvailable:" ) { print $2/1048576 }' /proc/meminfo | xargs printf "%.*f\n" 0)"
#Table for ES ram
if [ "$RAM_COUNT" -lt 8 ]; then
	echo "LME Requires 8GB of RAM Available for use - Exiting"
	exit
elif [ "$RAM_COUNT" -ge 8 -a "$RAM_COUNT" -le 16 ]; then 
	ES_RAM="$(expr $RAM_COUNT - 4)"
elif [ "$RAM_COUNT" -ge 17 -a "$RAM_COUNT" -le 32 ]; then 
	ES_RAM="$(expr $RAM_COUNT - 6)"
elif [ "$RAM_COUNT" -ge 33 -a "$RAM_COUNT" -le 49 ]; then
	ES_RAM="$(expr $RAM_COUNT - 8)"
elif [ "$RAM_COUNT" -ge 50 ]; then
	ES_RAM=31
else
	echo "Unable to determine RAM"
	exit
fi

sed -i "s/ram-count/$ES_RAM/g" docker-compose-stack-live.yml

#show ext4 disk
DF_OUTPUT="$(df -h -l -t ext4 --output=source,size)"

#pull dev name
DISK_DEV="$(echo $DF_OUTPUT | cut -d ' ' -f 3)"

#pull dev size
DISK_SIZE="$(echo $DF_OUTPUT | cut -d ' ' -f 4)"

#make it stripped disk size
DISK_SIZE_ROUND="$(echo ${DISK_SIZE/G/} | xargs printf "%.*f\n" 0)"

#lets do math to get 75% (%80 is low watermark for ES but as curator uses this we want to delete data *before* the disk gets full)
DISK_80="$(( $DISK_SIZE_ROUND*80/100 ))"



echo "We think your main disk is $DISK_SIZE on $DISK_DEV"
echo "We are assigning $DISK_80 G for log storage"

#lets change the value in the config now
sed -i "s/800/$DISK_80/g" docker-compose-stack-live.yml


}

function installdocker(){
echo "install curl to get the docker convenience script"
apt-get install unattended-upgrades -y
echo "install docker"
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
}

function initdocker(){
echo "Configure docker swarm"
docker swarm init
}

function deploylme() {
docker build -t lme/curator curator/ --no-cache
docker stack deploy lme --compose-file docker-compose-stack-live.yml
docker stack ps lme
docker ps -a
}

get_distribution() {
        lsb_dist=""
        # Every system that we officially support has /etc/os-release
        if [ -r /etc/os-release ]; then
                lsb_dist="$(. /etc/os-release && echo "$ID")"
        fi
        # Returning an empty string here should be alright since the
        # case statements don't act unless you provide an actual value
        echo "$lsb_dist"
}

function autoupdates(){

lin_ver=$( get_distribution )
echo This OS was detected as: $lin_ver
if [ $lin_ver == "ubuntu" ]; then
apt-get install unattended-upgrades -y
sed -i 's#//Unattended-Upgrade::Automatic-Reboot "false";#Unattended-Upgrade::Automatic-Reboot "true";#g' /etc/apt/apt.conf.d/50unattended-upgrades
sed -i 's#//Unattended-Upgrade::Automatic-Reboot-Time "02:00";#Unattended-Upgrade::Automatic-Reboot-Time "02:00";#g' /etc/apt/apt.conf.d/50unattended-upgrades


autoupdatesfile="/etc/apt/apt.conf.d/20auto-upgrades"
apt_UPL_0='APT::Periodic::Update-Package-Lists "0";'
apt_UPL_1='APT::Periodic::Update-Package-Lists "1";'

apt_UU_0='APT::Periodic::Unattended-Upgrade "0";'
apt_UU_1='APT::Periodic::Unattended-Upgrade "1";'

apt_DUP_0='APT::Periodic::Download-Upgradeable-Packages "0";'
apt_DUP_1='APT::Periodic::Download-Upgradeable-Packages "1";'


#check if package list is set to 1 or 0 and then make sure its 1 if its not set then set it
if [ ! -z $( grep "$apt_UPL_0" "$autoupdatesfile" -o grep "$apt_UPL_1" "$autoupdatesfile" ) ]; then
sed -i "s#$apt_UPL_0#$apt_UPL_1#g" $autoupdatesfile
else
echo $apt_UPL_1 >> $autoupdatesfile
fi 

#check unattended upgrade is set to 1 or 0 and then make sure its 1 if its not set then set it
if [ ! -z $( grep "$apt_UU_0" "$autoupdatesfile" -o grep "$apt_UU_1" "$autoupdatesfile" ) ]; then
sed -i "s#$apt_UU_0#$apt_UU_1#g" $autoupdatesfile
else
echo $apt_UU_1 >> $autoupdatesfile
fi 


#check download packages is set to 1 or 0 and then make sure its 1 if its not set then set it
if [ ! -z $( grep "$apt_DUP_0" "$autoupdatesfile" -o grep "$apt_DUP_1" "$autoupdatesfile" ) ]; then
sed -i "s#$apt_DUP_0#$apt_DUP_1#g" $autoupdatesfile
else
echo $apt_DUP_1 >> $autoupdatesfile
fi 



else
	echo "This distribution isn't supported by LME for autoupdates"
fi

}

function configelasticsearch(){
echo "Waiting for 1 minute before configuring elasticsearch"
sleep 60s
	
docker cp elastic_settings.sh $(docker ps -q --filter="NAME=lme_elasticsearch"):/elastic_settings.sh
docker exec -it $(docker ps -q --filter="NAME=lme_elasticsearch") bash -c "chmod +x /elastic_settings.sh"
docker exec -it $(docker ps -q --filter="NAME=lme_elasticsearch") bash -c /elastic_settings.sh
}



function install(){

#install net-tools to allow backwards compatibility
sudo apt-get install net-tools -y
#move configs
cp docker-compose-stack.yml docker-compose-stack-live.yml

#find the IP winlogbeat will use to communicate with the logstash box (on elk)

#get interface name of default route
DEFAULT_IF="$(route | grep '^default' | grep -o '[^ ]*$')"

#get ip of the interface
EXT_IP="$(/sbin/ifconfig $DEFAULT_IF| awk -F ' *|:' '/inet /{print $3}')"

read -e -p "Enter the IP that winlogbeat will use to communicate with this box: " -i "$EXT_IP" logstaship

read -e -p "Enter the DNS name that winlogbeat uses to communicate with this box: " logstashcn
echo "Configuring winlogbeat config and certificates to use $logstaship as the IP and $logstashcn as the DNS"

#enable auto updates if ubuntu
autoupdates

read -e -p "This script will use self signed certificates for communication and encryption, Do you want to continue with self signed certificates? ([y]es/[n]o): " -i "y" selfsignedyn

if [ "$selfsignedyn" == "y" ]; then 
#make certs
generatecerts

#install docker
installdocker

#configure swarm
initdocker

#save certs
populatecerts
elif [ "$selfsignedyn" == "n" ]; then

echo "Please make sure you have the following certificates named correctly"
echo "./certs/root-ca.crt"
echo "./certs/nginx.key"
echo "./certs/nginx.crt"
echo "./certs/logstash.crt"
echo "./certs/logstash.key"

echo "checking for root-ca.crt"
if [ ! -f ./certs/root-ca.crt ]; then
    echo "File not found!"
    exit
fi
echo "checking for nginx.key"
if [ ! -f ./certs/nginx.key ]; then
    echo "File not found!"
    exit
fi
echo "checking for nginx.crt"
if [ ! -f ./certs/nginx.crt ]; then
    echo "File not found!"
    exit
fi
echo "checking for logstash.crt"
if [ ! -f ./certs/logstash.crt ]; then
    echo "File not found!"
    exit
fi
echo "checking for logstash.key"
if [ ! -f ./certs/logstash.key ]; then
    echo "File not found!"
    exit
fi


installdocker
initdocker




populatecerts

else
echo "Not a valid option"
fi

#check if kibana password is manually set
if [ "$KIBANA_PASSWORD" == "NotCurrentlyWorking" ]; then
	echo "Kibana password manually set"
	setpassword
	populatepassword
else
	echo "Generating kibana password"
	generatepassword
	populatepassword
fi


confignginx
provisionconfig
configuredocker
deploylme
configelasticsearch
zipfiles

echo "####################################################################"
echo "## KIBANA Credentials are (these will not be accesible again!!!!) ##"
echo "## User: admin"
echo "## Password: $nginx_plain_password"
echo "####################################################################"
}

function uninstall(){
	docker stack rm lme
	docker secret rm nginx.crt nginx.key nginx_plainpass nginx_unpw winlogbeat.crt winlogbeat.key ca.crt logstash.crt logstash.key
	docker config rm logstash.conf nginx.conf
	rm -r certs
	rm -r nginx.conf
}

function update(){

	git pull
	cp docker-compose-stack.yml docker-compose-stack-live.yml
	docker stack rm lme
	docker config rm logstash.conf nginx.conf
	docker config create logstash.conf logstash.conf
	configuredocker
	deploylme
	configelasticsearch
}

############
#START HERE#
############

#What action is the user wanting to perform
#Install
#Uninstall
#Update

if [ "$1" == "" ]; then
	echo "No operation specified"
	echo "Usage:		./deploy.sh (install/uninstall/update)"
	echo "Example:	./deploy.sh install"
	exit
elif [ "$1" == "install" ]; then
	install
elif [ "$1" == "uninstall" ]; then
	uninstall
elif [ "$1" == "update" ]; then
	update
else
	echo "Invalid operation specified"
	echo "Usage:		./deploy.sh (install/uninstall/update)"
	echo "Example:	./deploy.sh install"
	exit
fi



