#!/bin/bash
##########################
# LME Deploy Script      #
# Version 0.4 - 24/03/21 #
##########################
# This script configures a host for LME including generating certificates and populating configuration files.

function customlogstashconf(){

#add option for custom logstash config
CUSTOM_LOGSTASH_CONF=/opt/lme/Chapter\ 3\ Files/logstash_custom.conf
if test -f "$CUSTOM_LOGSTASH_CONF"; then
   echo -e "\e[32m[x]\e[0m Custom logstash config exists, Not creating"
else
   echo -e "\e[32m[x]\e[0m Creating custom logstash conf"
   echo "#custom logstash configuration file" >> /opt/lme/Chapter\ 3\ Files/logstash_custom.conf
fi
}

function generatepasswords() {
elastic_user_pass=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
kibana_system_pass=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
logstash_system_pass=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
logstash_writer=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
update_user_pass=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
kibanakey=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 42 | head -n 1)


echo -e "\e[32m[x]\e[0m Updating logstash configuration with logstash writer"
cp /opt/lme/Chapter\ 3\ Files/logstash.conf /opt/lme/Chapter\ 3\ Files/logstash.edited.conf
sed -i "s/insertlogstashwriterpasswordhere/$logstash_writer/g" /opt/lme/Chapter\ 3\ Files/logstash.edited.conf
}

function setpasswords() {
echo -e "\e[32m[x]\e[0m Waiting for elasticsearch to be ready"
while [[ "$(curl --cacert certs/root-ca.crt --user elastic:temp -s -o /dev/null -w ''%{http_code}'' https://127.0.0.1:9200)" != "200" ]]
do 
sleep 1
done

echo -e "\e[32m[x]\e[0m Setting elastic user password"
curl --cacert certs/root-ca.crt --user elastic:temp -X POST "https://127.0.0.1:9200/_security/user/elastic/_password" -H 'Content-Type: application/json' -d' { "password" : "'"$elastic_user_pass"'"} '

echo -e "\n\e[32m[x]\e[0m Setting kibana system password"
curl --cacert certs/root-ca.crt --user elastic:$elastic_user_pass -X POST "https://127.0.0.1:9200/_security/user/kibana/_password" -H 'Content-Type: application/json' -d' { "password" : "'"$kibana_system_pass"'"} '

echo -e "\n\e[32m[x]\e[0m Setting logstash system password"
curl --cacert certs/root-ca.crt --user elastic:$elastic_user_pass -X POST "https://127.0.0.1:9200/_security/user/logstash_system/_password" -H 'Content-Type: application/json' -d' { "password" : "'"$logstash_system_pass"'"} '

echo -e "\n\e[32m[x]\e[0m Creating logstash writer role"

curl --cacert certs/root-ca.crt --user elastic:$elastic_user_pass -X POST "https://127.0.0.1:9200/_security/role/logstash_writer" -H 'Content-Type: application/json' -d'
{
  "cluster": ["manage_index_templates", "monitor", "manage_ilm"], 
  "indices": [
    {
      "names": [ "logstash-*","winlogbeat-*" ], 
      "privileges": ["write","delete","create_index","manage","manage_ilm"]  
    }
  ]
}
'

echo -e "\n\e[32m[x]\e[0m Creating logstash writer user"


curl --cacert certs/root-ca.crt --user elastic:$elastic_user_pass -X POST "https://127.0.0.1:9200/_security/user/logstash_writer" -H 'Content-Type: application/json' -d'
{
  "password" : "logstash_writer",
  "roles" : [ "logstash_writer"],
  "full_name" : "Internal Logstash User"
  }
'

echo -e "\n\e[32m[x]\e[0m Setting logstash writer password"
curl --cacert certs/root-ca.crt --user elastic:$elastic_user_pass -X POST "https://127.0.0.1:9200/_security/user/logstash_writer/_password" -H 'Content-Type: application/json' -d' { "password" : "'"$logstash_writer"'"} '



#create role, Only needs kibana perms so the other data is just falsified. 
echo -e "\n\e[32m[x]\e[0m Creating update role (dashboards)"
curl --cacert certs/root-ca.crt --user elastic:$elastic_user_pass -X POST "https://127.0.0.1:9200/_security/role/dashboard_update" -H 'Content-Type: application/json' -d'
{
  "cluster":[],
  "indices":[],
  "applications":[{
    "application":"kibana-.kibana",
  "privileges":[
  "feature_canvas.all",
  "feature_savedObjectsManagement.all",
  "feature_indexPatterns.all",
  "feature_dashboard.all",
  "feature_visualize.all"],
  "resources":["*"]}],
  "run_as":[],
  "metadata":{},
  "transient_metadata":{"enabled":true}}
'


echo -e "\n\e[32m[x]\e[0m Creating update user (dashboards)"
curl --cacert certs/root-ca.crt --user elastic:$elastic_user_pass -X POST "https://127.0.0.1:9200/_security/user/dashboard_update" -H 'Content-Type: application/json' -d'
{
  "password" : "dashboard_update",
  "roles" : [ "dashboard_update"],
  "full_name" : "Internal dashboard update User"
  }
'

echo -e "\n\e[32m[x]\e[0m Setting update user password (dashboards)"
curl --cacert certs/root-ca.crt --user elastic:$elastic_user_pass -X POST "https://127.0.0.1:9200/_security/user/dashboard_update/_password" -H 'Content-Type: application/json' -d' { "password" : "'"$update_user_pass"'"} '





}
function zipfiles(){
#zip the files to allow the user to download them for the WLB install.
#copy them to home to start with
echo -e "\n\e[32m[x]\e[0m Generating files_for_windows zip"
apt-get install zip -y -q
mkdir -p /tmp/lme
cp /opt/lme/Chapter\ 3\ Files/winlogbeat.yml /tmp/lme/
cp /opt/lme/Chapter\ 3\ Files/certs/wlbclient.crt /tmp/lme/
cp /opt/lme/Chapter\ 3\ Files/certs/wlbclient.key /tmp/lme/
cp /opt/lme/Chapter\ 3\ Files/certs/root-ca.crt /tmp/lme/
sed -i "s/logstash_dns_name/$logstashcn/g" /tmp/lme/winlogbeat.yml
zip -r /opt/lme/files_for_windows.zip /tmp/lme
}


function generatecerts() {

echo -e "\e[33m[!]\e[0m Note: Depending on your OpenSSL configuration you may see an error opening a .rnd file into RNG, this will not block the installation"

#configure certificate authority
mkdir certs

#make a new key for the root ca
echo -e "\e[32m[x]\e[0m Making root CA"
openssl genrsa -out certs/root-ca.key 4096

#make a cert signing request for this key
openssl req -new -key certs/root-ca.key -out certs/root-ca.csr -sha256 -subj '/C=GB/ST=UK/L=London/O=Docker/CN=Swarm'

#Set openssl so that this root can only sign certs and not sign intermediates
echo "[root_ca]" > certs/root-ca.cnf
echo "basicConstraints = critical,CA:TRUE,pathlen:1" >> certs/root-ca.cnf
echo "keyUsage = critical, nonRepudiation, cRLSign, keyCertSign" >> certs/root-ca.cnf
echo "subjectKeyIdentifier=hash" >> certs/root-ca.cnf

#sign the root ca
echo -e "\e[32m[x]\e[0m Signing root CA"
openssl x509 -req  -days 3650  -in certs/root-ca.csr -signkey certs/root-ca.key -sha256 -out certs/root-ca.crt -extfile certs/root-ca.cnf -extensions root_ca


##logstash server
#make a new key for logstash
echo -e "\e[32m[x]\e[0m Making logstash Cert"
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
echo -e "\e[32m[x]\e[0m Signing logstash cert"
openssl x509 -req -days 750 -in certs/logstash.csr -sha256 -CA certs/root-ca.crt -CAkey certs/root-ca.key -CAcreateserial -out certs/logstash.crt -extfile certs/logstash.cnf -extensions server
mv certs/logstash.key certs/logstash.key.pem && openssl pkcs8 -in certs/logstash.key.pem -topk8 -nocrypt -out certs/logstash.key

##winlogbeat client
#make a new key for winlogbeat client
echo -e "\e[32m[x]\e[0m Making wlbclient Cert"
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
echo -e "\e[32m[x]\e[0m Signing wlbclient cert"
openssl x509 -req -days 750 -in certs/wlbclient.csr -sha256 -CA certs/root-ca.crt -CAkey certs/root-ca.key -CAcreateserial -out certs/wlbclient.crt -extfile certs/wlbclient.cnf -extensions server


##elasticsearch server
#make a new key for elasticsearch
echo -e "\e[32m[x]\e[0m Making logstash Cert"
openssl genrsa -out certs/elasticsearch.key 4096

#make a cert signing request for elasticsearch
openssl req -new -key certs/elasticsearch.key -out certs/elasticsearch.csr -sha256 -subj "/C=GB/ST=UK/L=London/O=Docker/CN=elasticsearch"

#set openssl so that this cert can only perform server auth and cannot sign certs
echo "[server]" > certs/elasticsearch.cnf
echo "authorityKeyIdentifier=keyid,issuer" >> certs/elasticsearch.cnf
echo "basicConstraints = critical,CA:FALSE" >> certs/elasticsearch.cnf
echo "extendedKeyUsage=serverAuth,clientAuth" >> certs/elasticsearch.cnf
echo "keyUsage = critical, digitalSignature, keyEncipherment" >> certs/elasticsearch.cnf
echo "subjectAltName = DNS:elasticsearch, IP:127.0.0.1">> certs/elasticsearch.cnf
echo "subjectKeyIdentifier=hash" >> certs/elasticsearch.cnf

#sign the elasticsearchcert
echo -e "\e[32m[x]\e[0m Sign elasticsearch cert"
openssl x509 -req -days 750 -in certs/elasticsearch.csr -sha256 -CA certs/root-ca.crt -CAkey certs/root-ca.key -CAcreateserial -out certs/elasticsearch.crt -extfile certs/elasticsearch.cnf -extensions server
mv certs/elasticsearch.key certs/elasticsearch.key.pem && openssl pkcs8 -in certs/elasticsearch.key.pem -topk8 -nocrypt -out certs/elasticsearch.key

##kibana server
#make a new key for kibana
echo -e "\e[32m[x]\e[0m Making logstash Cert"
openssl genrsa -out certs/kibana.key 4096

#make a cert signing request for kibana
openssl req -new -key certs/kibana.key -out certs/kibana.csr -sha256 -subj "/C=GB/ST=UK/L=London/O=Docker/CN=kibana"

#set openssl so that this cert can only perform server auth and cannot sign certs
echo "[server]" > certs/kibana.cnf
echo "authorityKeyIdentifier=keyid,issuer" >> certs/kibana.cnf
echo "basicConstraints = critical,CA:FALSE" >> certs/kibana.cnf
echo "extendedKeyUsage=serverAuth" >> certs/kibana.cnf
echo "keyUsage = critical, digitalSignature, keyEncipherment" >> certs/kibana.cnf
echo "subjectAltName = DNS:"$logstashcn", IP:" $logstaship >> certs/kibana.cnf
echo "subjectKeyIdentifier=hash" >> certs/kibana.cnf

#sign the kibanacert
echo -e "\e[32m[x]\e[0m Sign kibana cert"
openssl x509 -req -days 750 -in certs/kibana.csr -sha256 -CA certs/root-ca.crt -CAkey certs/root-ca.key -CAcreateserial -out certs/kibana.crt -extfile certs/kibana.cnf -extensions server
mv certs/kibana.key certs/kibana.key.pem && openssl pkcs8 -in certs/kibana.key.pem -topk8 -nocrypt -out certs/kibana.key

}

function populatecerts() {
#add to docker secrets
echo -e "\e[32m[x]\e[0m Adding certificates and keys to Docker"

#ca cert
docker secret create ca.crt certs/root-ca.crt

#logstash
docker secret create logstash.key certs/logstash.key
docker secret create logstash.crt certs/logstash.crt

#elasticsearch server
docker secret create elasticsearch.key certs/elasticsearch.key
docker secret create elasticsearch.crt certs/elasticsearch.crt

#kibana server
docker secret create kibana.key certs/kibana.key
docker secret create kibana.crt certs/kibana.crt

}


function populatelogstashconfig() {
#add logstash conf to config
docker config create logstash.conf logstash.edited.conf

#add logstash_custom conf to config
customlogstashconf
docker config create logstash_custom.conf logstash_custom.conf

}

function configuredocker() {
sysctl -w vm.max_map_count=262144
SYSCTL_STATUS=$( grep vm.max_map_count /etc/sysctl.conf )
if [ "$SYSCTL_STATUS" == "vm.max_map_count=262144" ]; then
        echo "SYSCTL already configured"
else
        echo "vm.max_map_count=262144" >> /etc/sysctl.conf
fi

RAM_COUNT="$(awk '( $1 == "MemAvailable:" ) { print $2/1048576 }' /proc/meminfo | xargs printf "%.*f\n" 0)"
#Table for ES ram
if [ "$RAM_COUNT" -lt 8 ]; then
        echo -e "\e[31m[X]\e[0m LME Requires 8GB of RAM Available for use - Exiting"
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
        echo -e "\e[33m[x]\e[0m Unable to determine RAM"
        exit
fi

sed -i "s/ram-count/$ES_RAM/g" /opt/lme/Chapter\ 3\ Files/docker-compose-stack-live.yml

sed -i "s/insertkibanapasswordhere/$kibana_system_pass/g" /opt/lme/Chapter\ 3\ Files/docker-compose-stack-live.yml

sed -i "s/kibanakey/$kibanakey/g" /opt/lme/Chapter\ 3\ Files/docker-compose-stack-live.yml



}

function installdocker(){
echo -e "\e[32m[x]\e[0m Installing curl to get the docker convenience script"
apt-get install curl -y -q
echo -e "\e[32m[x]\e[0m Installing docker"
curl -fsSL https://get.docker.com -o get-docker.sh > /dev/null
sh get-docker.sh > /dev/null
}

function initdockerswarm(){
echo -e "\e[32m[x]\e[0m Configuring docker swarm"
docker swarm init
}

function deploylme() {	
docker stack deploy lme --compose-file /opt/lme/Chapter\ 3\ Files/docker-compose-stack-live.yml
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

function dashboard_update(){

if [ -z "$update_user_pass" ]; then
  # $update_user_pass is not set - so this function is not called from an initial install
  read -s -e -p "Enter the password for the existing dashboard_update user: " update_user_pass
fi

cp dashboard_update.sh /opt/lme/
chmod 700 /opt/lme/dashboard_update.sh

echo -e "\e[32m[x]\e[0m Updating dashboard update configuration with dashboard update user credentials"
sed -i "s/dashboardupdatepassword/$update_user_pass/g" /opt/lme/dashboard_update.sh

echo -e "\e[32m[x]\e[0m Creating dashboard update crontab"
crontab -l | { cat; echo "0 1 * * * /opt/lme/dashboard_update.sh"; } | crontab -
}

function auto_lme_update(){
cp lme_update.sh /opt/lme/
chmod 700 /opt/lme/lme_update.sh

echo -e "\e[32m[x]\e[0m Creating LME update crontab"
crontab -l | { cat; echo "30 1 * * * /opt/lme/lme_update.sh"; } | crontab -

}

function indexmappingupdate(){

echo -e "\n\e[32m[x]\e[0m Uploading the LME index template"

if [ -z "$elastic_user_pass" ]; then
  # $elastic_user_pass is not set - so this function is not called from an initial install
  read -s -e -p "Enter the password for the existing elastic user: " elastic_user_pass
fi
curl --cacert certs/root-ca.crt --user elastic:$elastic_user_pass -X PUT "https://127.0.0.1:9200/_template/lme_template" -H 'Content-Type: application/json' --data "@winlog-index-mapping.json"
}

function pipelineupdate(){

echo -e "\n\e[32m[x]\e[0m Creating Elastic pipelines"

if [ -z "$elastic_user_pass" ]; then
  # $elastic_user_pass is not set - so this function is not called from an initial install
  read -s -e -p "Enter the password for the existing elastic user: " elastic_user_pass
fi

#create syslog pipeline
curl --cacert certs/root-ca.crt --user elastic:$elastic_user_pass -X PUT "https://127.0.0.1:9200/_ingest/pipeline/syslog" -H 'Content-Type: application/json' -d'
{
  "processors": [
    {
      "rename": {
        "field": "host",
        "target_field": "old.provider"
      }
    }
  ]
}
'

#create beats pipeline
curl --cacert certs/root-ca.crt --user elastic:$elastic_user_pass -X PUT "https://127.0.0.1:9200/_ingest/pipeline/winlogbeat" -H 'Content-Type: application/json' -d'
{
  "description": "Add geoip info",
  "processors": [
    {
      "geoip": {
        "field": "client.ip",
        "target_field": "client.geo",
        "ignore_missing": true
      }
    },
    {
      "geoip": {
        "field": "source.ip",
        "target_field": "source.geo",
        "ignore_missing": true
      }
    },
    {
      "geoip": {
        "field": "destination.ip",
        "target_field": "destination.geo",
        "ignore_missing": true
      }
    },
    {
      "geoip": {
        "field": "server.ip",
        "target_field": "server.geo",
        "ignore_missing": true
      }
    },
    {
      "geoip": {
        "field": "host.ip",
        "target_field": "host.geo",
        "ignore_missing": true
      }
    }
  ]
}
'
}

function data_retention(){

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



echo -e "\e[32m[x]\e[0m We think your main disk is $DISK_SIZE on $DISK_DEV"
echo -e "\e[32m[x]\e[0m We are assigning $DISK_80 G for log storage"

curl --cacert certs/root-ca.crt --user elastic:$elastic_user_pass -X PUT "https://127.0.0.1:9200/_ilm/policy/lme_ilm_policy" -H 'Content-Type: application/json' -d'
{
    "policy": {
        "phases": {
            "hot": {
                "actions": {}
            },
            "delete": {
                "min_age": "'$DISK_80'd",
                "actions": {
                    "delete": {}
                }
            }
        }
    }
}
'
}


function auto_os_updates(){

lin_ver=$( get_distribution )
echo This OS was detected as: $lin_ver
if [ $lin_ver == "ubuntu" ]; then
echo -e "\e[32m[x]\e[0m Configuring Auto Updates"
apt-get install unattended-upgrades -y -q
sed -i 's#//Unattended-Upgrade::Automatic-Reboot "false";#Unattended-Upgrade::Automatic-Reboot "true";#g' /etc/apt/apt.conf.d/50unattended-upgrades
sed -i 's#//Unattended-Upgrade::Automatic-Reboot-Time "02:00";#Unattended-Upgrade::Automatic-Reboot-Time "02:00";#g' /etc/apt/apt.conf.d/50unattended-upgrades


auto_os_updatesfile='/etc/apt/apt.conf.d/20auto-upgrades'
apt_UPL_0='APT::Periodic::Update-Package-Lists "0";'
apt_UPL_1='APT::Periodic::Update-Package-Lists "1";'

apt_UU_0='APT::Periodic::Unattended-Upgrade "0";'
apt_UU_1='APT::Periodic::Unattended-Upgrade "1";'

apt_DUP_0='APT::Periodic::Download-Upgradeable-Packages "0";'
apt_DUP_1='APT::Periodic::Download-Upgradeable-Packages "1";'


#check if package list is set to 1 or 0 and then make sure its 1 if its not set then set it
if [[ ! -z $( grep "$apt_UPL_0" "$auto_os_updatesfile" ) || ! -z $( grep "$apt_UPL_1" "$auto_os_updatesfile" ) ]]; then
sed -i "s#$apt_UPL_0#$apt_UPL_1#g" $auto_os_updatesfile
else
echo $apt_UPL_1 >> $auto_os_updatesfile
fi

#check unattended upgrade is set to 1 or 0 and then make sure its 1 if its not set then set it
if [[ ! -z $( grep "$apt_UU_0" "$auto_os_updatesfile" ) || ! -z $( grep "$apt_UU_1" "$auto_os_updatesfile" ) ]]; then
sed -i "s#$apt_UU_0#$apt_UU_1#g" $auto_os_updatesfile
else
echo $apt_UU_1 >> $auto_os_updatesfile
fi


#check download packages is set to 1 or 0 and then make sure its 1 if its not set then set it
if [[ ! -z $( grep "$apt_DUP_0" "$auto_os_updatesfile" ) ||  ! -z $( grep "$apt_DUP_1" "$auto_os_updatesfile" ) ]]; then
sed -i "s#$apt_DUP_0#$apt_DUP_1#g" $auto_os_updatesfile
else
echo $apt_DUP_1 >> $auto_os_updatesfile
fi



else
echo -e "\e[33m[x]\e[0m Not configuring automatic updates as this OS is not supported"
fi

}

function configelasticsearch(){
echo -e "\n\e[32m[x]\e[0m Configuring elasticsearch Replica settings"

#set future index to always have no replicas
curl --cacert certs/root-ca.crt --user elastic:$elastic_user_pass  -X PUT "https://127.0.0.1:9200/_template/number_of_replicas" -H 'Content-Type: application/json' -d' {  "template": "*",  "settings": {    "number_of_replicas": 0  }}'
#set all current indices to have 0 replicas
curl --cacert certs/root-ca.crt --user elastic:$elastic_user_pass  -X PUT "https://127.0.0.1:9200/_all/_settings" -H 'Content-Type: application/json' -d '{"index" : {"number_of_replicas" : 0}}'
}

function writeconfig() {

echo -e "\n\e[32m[x]\e[0m Writing LME Config"

#write LME version
echo "version=0.4" > /opt/lme/lme.conf
if [ -z "$logstashcn" ]; then
  # $logstashcn is not not set - so this function is not called from an initial install
  read -e -p "Enter the Fully Qualified Domain Name (FQDN) of this Linux server: " logstashcn
fi
#write elastic hostname
echo "hostname=$logstashcn" >> /opt/lme/lme.conf
}

function uploaddashboards(){

echo -e "\e[32m[x]\e[0m Uploading Kibana dashboards"

cp /opt/lme/Chapter\ 4\ Files/dashboards.ndjson /opt/lme/Chapter\ 4\ Files/dashboards-live.ndjson

if [ -z "$logstashcn" ]; then
  # $logstashcn is not not set - so this function is not called from an initial install
  read -e -p "Enter the Fully Qualified Domain Name (FQDN) of this Linux server: " logstashcn
fi

sed -i "s/ChangeThisDomain/https:\/\/$logstashcn\\\/g" /opt/lme/Chapter\ 4\ Files/dashboards-live.ndjson

if [ -z "$update_user_pass" ]; then
  # $update_user_pass is not set - so this function is not called from an initial install
  read -s -e -p "Enter the password for the existing dashboard_update user: " update_user_pass
fi

sleep 30 #sleep to make sure port is responsive, it seems to not immediately be available sometimes

curl -X POST -k --user dashboard_update:$update_user_pass -H 'kbn-xsrf: true' --form file="@/opt/lme/Chapter 4 Files/dashboards-live.ndjson" "https://127.0.0.1/api/saved_objects/_import?overwrite=true"

}

function install(){

#Set Proxy Server
read -e -p "Do you want to configure a proxy server ([y]es/[n]o): " -i "y" set_proxy
if [ "$set_proxy" == "y" ]; then
   read -e -p "Enter proxy server IP address: " proxy_ip
   read -e -p "Enter proxy server port: "  proxy_port
   echo -e "\e[32m[x]\e[0m Setting proxy details http://$proxy_ip:$proxy_port in file /etc/systemd/system/docker.service.d2/http-proxy.conf"
   sudo mkdir -p /etc/systemd/system/docker.service.d
   sudo cat > /etc/systemd/system/docker.service.d/http-proxy.conf <<PROXY_EOF
[Service]
Environment="HTTP_PROXY=http://$proxy_ip:$proxy_port"
Environment="HTTPS_PROXY=http://$proxy_ip:$proxy_port"
Environment="no-proxy=elasticsearch,localhost,127.0.0.1"
PROXY_EOF

sudo systemctl daemon-reload
fi

echo -e "\e[32m[x]\e[0m Installing prerequisites"
#install net-tools to allow backwards compatibility
sudo apt-get install net-tools -y -q
#move configs
cp docker-compose-stack.yml docker-compose-stack-live.yml

#find the IP winlogbeat will use to communicate with the logstash box (on elk)

#get interface name of default route
DEFAULT_IF="$(route | grep '^default' | grep -o '[^ ]*$')"

#get ip of the interface
EXT_IP="$(/sbin/ifconfig $DEFAULT_IF| awk -F ' *|:' '/inet /{print $3}')"

read -e -p "Enter the IP of this Linux server: " -i "$EXT_IP" logstaship

read -e -p "Enter the Fully Qualified Domain Name (FQDN) of this Linux server. This needs to be resolvable from the Windows Event Collector: " logstashcn
echo -e "\e[32m[x]\e[0m Configuring winlogbeat config and certificates to use $logstaship as the IP and $logstashcn as the DNS"

#enable auto updates if ubuntu
auto_os_updates

read -e -p "This script will use self signed certificates for communication and encryption, Do you want to continue with self signed certificates? ([y]es/[n]o): " -i "y" selfsignedyn

if [ "$selfsignedyn" == "y" ]; then
#make certs
generatecerts





elif [ "$selfsignedyn" == "n" ]; then

echo "Please make sure you have the following certificates named correctly"
echo "./certs/root-ca.crt"
echo "./certs/elasticsearch.key"
echo "./certs/elasticsearch.crt"
echo "./certs/logstash.crt"
echo "./certs/logstash.key"

echo "[x] checking for root-ca.crt"
if [ ! -f ./certs/root-ca.crt ]; then
    echo "File not found!"
    exit
fi
echo "[x] checking for elasticsearch.key"
if [ ! -f ./certs/elasticsearch.key ]; then
    echo -e "\e[31m[X]\e[0m File not found!"
    exit
fi
echo "[x] checking for elasticsearch.crt"
if [ ! -f ./certs/elasticsearch.crt ]; then
    echo -e "\e[31m[X]\e[0m File not found!"
    exit
fi
echo "[x] checking for logstash.crt"
if [ ! -f ./certs/logstash.crt ]; then
    echo -e "\e[31m[X]\e[0m File not found!"
    exit
fi
echo "[x] checking for logstash.key"
if [ ! -f ./certs/logstash.key ]; then
    echo -e "\e[31m[X]\e[0m File not found!"
    exit
fi


else
echo "Not a valid option"
fi

installdocker
initdockerswarm
populatecerts
generatepasswords
populatelogstashconfig
configuredocker
deploylme
setpasswords
configelasticsearch
zipfiles

read -e -p "Do you want to automatically update LME ([y]es/[n]o): " -i "y" autoupdate_enabled

if [ "$autoupdate_enabled" == "y" ]; then
echo -e "\e[32m[x]\e[0m Enabling LME Automatic Update"
#cron lme update
auto_lme_update
fi

read -e -p "Do you want to automatically update Dashboards ([y]es/[n]o): " -i "y" dashboardupdate_enabled

if [ "$dashboardupdate_enabled" == "y" ]; then
echo -e "\e[32m[x]\e[0m Enabling Dashboard Automatic Update"
#cron dash update
dashboard_update
fi

#ILM
data_retention

#index mapping
indexmappingupdate

#pipelines
pipelineupdate

#create config file
writeconfig

#dashboard upload
uploaddashboards

echo ""
echo "##################################################################################"
echo "## Kibana/Elasticsearch Credentials are (these will not be accesible again!!!!) ##"
echo "##"
echo "## Web Interface login:"
echo "## elastic:$elastic_user_pass"
echo "##"
echo "## System Credentials"
echo "## kibana:$kibana_system_pass"
echo "## logstash_system:$logstash_system_pass"
echo "## logstash_writer:$logstash_writer"
echo "## dashboard_update:$update_user_pass"
echo "##################################################################################"
}

function uninstall(){
  echo -e "\e[32m[x]\e[0m Removing docker stack and configuration"
  docker stack rm lme
  docker secret rm ca.crt logstash.crt logstash.key elasticsearch.key elasticsearch.crt
  docker secret rm kibana.crt kibana.key
  docker config rm logstash.conf logstash_custom.conf
  echo -e "\e[32m[x]\e[0m Attempting to remove legacy LME files (this will cause expected errors if these no longer exist)"
  docker secret rm winlogbeat.crt winlogbeat.key nginx.crt nginx.key
  docker config rm osmap.csv
  echo -e "\e[32m[x]\e[0m Leaving docker swarm"
  docker swarm leave --force
  echo -e "\e[32m[x]\e[0m Removing LME config files and configured auto-updates"
  rm -r certs
  crontab -l | sed -E '/lme_update.sh|dashboard_update.sh/d' | crontab -
  echo -e "\e[31m[X]\e[0m NOTICE!"
  echo -e "\e[31m[X]\e[0m No data has been deleted, Run 'sudo docker volume rm lme_esdata' to delete the elasticsearch database"
}

function update(){
#check if the config file we're now creating on new installs exists
if [ -r /opt/lme/lme.conf ]; then
  #reference this file as a source
  . /opt/lme/lme.conf
  #check if the version number is equal to the one we want
  if [ "$version" == "0.4" ]; then

        echo -e "\e[32m[x]\e[0m Updating from git repo"
        git -C /opt/lme/ pull

        echo -e "\e[32m[x]\e[0m Removing existing docker stack"
        docker stack rm lme
        docker config rm logstash.conf logstash_custom.conf
        echo -e "\e[32m[x]\e[0m Attempting to remove legacy LME files (this will cause expected errors if these no longer exist)"
        docker config rm osmap.csv

        echo -e "\e[32m[x]\e[0m Sleeping for one minute to allow docker actions to complete..."
        sleep 1m

        #Update Logstash Config
        echo -e "\e[32m[x]\e[0m Updating current configuration files"

        # mv old config to .old
        mv /opt/lme/Chapter\ 3\ Files/logstash.edited.conf /opt/lme/Chapter\ 3\ Files/logstash.edited.conf.old

        # copy new git version
        cp /opt/lme/Chapter\ 3\ Files/logstash.conf /opt/lme/Chapter\ 3\ Files/logstash.edited.conf

        # copy pass from old config into var
        Logstash_Config_Pass="$(awk '{if(/password/) print $3}' < /opt/lme/Chapter\ 3\ Files/logstash.edited.conf.old | head -1 | tr -d \")"

        # Insert var into new config
        sed -i "s/insertlogstashwriterpasswordhere/$Logstash_Config_Pass/g" /opt/lme/Chapter\ 3\ Files/logstash.edited.conf

        # delete old config
        rm /opt/lme/Chapter\ 3\ Files/logstash.edited.conf.old

        #END Update Logstash Config

        #Update Docker Config

        #Move old docker config to .old
        mv /opt/lme/Chapter\ 3\ Files/docker-compose-stack-live.yml /opt/lme/Chapter\ 3\ Files/docker-compose-stack-live.yml.old

        #copy new git version
        cp /opt/lme/Chapter\ 3\ Files/docker-compose-stack.yml /opt/lme/Chapter\ 3\ Files/docker-compose-stack-live.yml

        # copy ramcount into var
        Ram_from_conf="$(grep -P -o "(?<=Xms)\d+" /opt/lme/Chapter\ 3\ Files/docker-compose-stack-live.yml.old)"

        # update Config file with ramcount
        sed -i "s/ram-count/$Ram_from_conf/g" /opt/lme/Chapter\ 3\ Files/docker-compose-stack-live.yml

        # copy elastic pass into var
        Kibanapass_from_conf="$(grep -P -o "(?<=ELASTICSEARCH_PASSWORD: ).*" /opt/lme/Chapter\ 3\ Files/docker-compose-stack-live.yml.old)"

        #update config with kibana password
        sed -i "s/insertkibanapasswordhere/$Kibanapass_from_conf/g" /opt/lme/Chapter\ 3\ Files/docker-compose-stack-live.yml

	      #copy kibana encryption key
        kibanakey="$(grep -P -o "(?<=XPACK_ENCRYPTEDSAVEDOBJECTS_ENCRYPTIONKEY: ).*" /opt/lme/Chapter\ 3\ Files/docker-compose-stack-live.yml.old)"

        #update config with kibana key
        sed -i "s/kibanakey/$kibanakey/g" /opt/lme/Chapter\ 3\ Files/docker-compose-stack-live.yml

        customlogstashconf

        echo -e "\e[32m[x]\e[0m Recreating docker stack"

        docker config create logstash.conf /opt/lme/Chapter\ 3\ Files/logstash.edited.conf
        docker config create logstash_custom.conf /opt/lme/Chapter\ 3\ Files/logstash_custom.conf
        deploylme

  fi

fi

}


function upgrade(){

#prompt user for passwords and check that they are correct
read -s -e -p "Enter the password for the existing elastic user: " elastic_user_pass
if [[ "$(curl --cacert certs/root-ca.crt --user elastic:$elastic_user_pass -s -o /dev/null -w ''%{http_code}'' https://127.0.0.1:9200)" != "200" ]]; then
  echo -e "\n\e[31m[!]\e[0m The password you have entered was invalid or the elastic service did not respond, please try again."
  exit
fi
echo ""
read -s -e -p "Enter the password for the existing dashboard_update user: " update_user_pass
if [[ "$(curl -k --user dashboard_update:$update_user_pass -s -o /dev/null -w ''%{http_code}'' https://127.0.0.1/status)" != "200" ]]; then
  echo -e "\n\e[31m[!]\e[0m The password you have entered was invalid or the elastic service did not respond, please try again."
  exit
fi

#update the index mapping
indexmappingupdate
#updated the winlogbeat and syslog pipelines
pipelineupdate
#write the LME config file
writeconfig

#upload the Kibana dashboards
uploaddashboards

#remove existing legacy dashboard update calls
crontab -l | sed -E '/dashboard_update.sh/d' | crontab - 

#Re-prompt the user to enable the new automatic dashboard update script
echo ""
read -e -p "Do you want to automatically update Dashboards ([y]es/[n]o): " -i "y" dashboardupdate_enabled

if [ "$dashboardupdate_enabled" == "y" ]; then
echo -e "\e[32m[x]\e[0m Enabling Dashboard Automatic Update"
#cron dash update
dashboard_update
fi

}

############
#START HERE#
############

#What action is the user wanting to perform
#Install
#Uninstall
#Update


#Check the install location
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
if [[ "$DIR" != "/opt/lme/Chapter 3 Files" ]]; then
  echo "The deploy script is not currently within the correct path, please ensure that LME is located in /opt/lme for installation"
  exit
fi

#Change current working directory so relative filepaths work
cd "$DIR"

if [ "$1" == "" ]; then
        echo "No operation specified"
        echo "Usage:            ./deploy.sh (install/uninstall/update/upgrade)"
        echo "Example:  ./deploy.sh install"
        exit
elif [ "$1" == "install" ]; then
        install
elif [ "$1" == "uninstall" ]; then
        uninstall
elif [ "$1" == "update" ]; then
        update
elif [ "$1" == "upgrade" ]; then
        upgrade  
else
        echo "Invalid operation specified"
        echo "Usage:            ./deploy.sh (install/uninstall/update/upgrade)"
        echo "Example:  ./deploy.sh install"
        exit
fi
