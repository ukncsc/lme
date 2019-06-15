# Chapter 3B – Database Custom/Manual Install

## Chapter Overview
In this chapter we will:
* Install a new Linux server for events to be sent to.
* Install Docker
* Secure the machine
* Configure TLS certificates (or you can use your own)
* Configure Docker
* Setup NGINX Reverse Proxy

## 3.1 Patching the Linux Machine
It is important to ensure that this Linux machine remains updated with a minimum of security patches. Below are guides for a selection of the Linux distributions.
### 3.1.1 Ubuntu - Preferred
If you are using the latest Ubuntu or the current LTS version of Ubuntu then the deploy.sh installer will configure updates for you. Alternatively you can follow the guide at https://help.ubuntu.com/lts/serverguide/automatic-updates.html.en
### 3.1.2 Debian - Supported
Debian - https://wiki.debian.org/UnattendedUpgrades

## 3.2 Installing Docker - Manual method
The LME software stack is packaged as Docker images to enable the product to run anywhere Docker can. You can either install Docker Community edition manually  (https://www.docker.com/products/docker-engine) or use the convenience script.

```
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
```

**Note: The Docker install script may prompt you to run 'docker engine activate', to enable
 the paid-for enterprise version. You DO NOT need to do this, the Docker Engine Community Edition is free and sufficient for LME.**

### 3.2.1 Checking Docker & Swarm
LME requires version 18 or higher of Docker. This is the only version that has been tested at this time.

Check Docker version with:
```docker --version```


Enable Docker Swarm mode (this is needed to deploy the software stack)
```sudo docker swarm init```

## 3.3 Configuring Docker
Most of the docker images in the LME stack will work without further settings however to enable the ElasticSearch database to operate properly we need to set a few configuration settings
### 3.3.1 Memory Settings for Elasticsearch and Docker
The following line in sysctl.conf needs to be edited using your prefered editor, such as nano or vi/vim. It is possible that the vm.max_map_count will not exist.
The file sysctl.conf exists in /etc/sysctl.conf

```vm.max_map_count=262144```


The box will need to be rebooted in order for this file to be proccessed. 

Alternatively, to apply this setting instantly, you can run:
```sudo sysctl -w vm.max_map_count=262144```


### 3.3.2 Allow non root users to use Docker
If you would like to use Docker as a non-root user (or without sudo), you should now consider
adding your user to the "docker" group with something like:


```sudo usermod -aG docker your-user```


Remember that you will have to log out and back in for this to take effect!


** WARNING: Adding a user to the "docker" group will grant the ability to run containers which can be used to obtain root privileges on the docker host. **


Refer to https://docs.docker.com/engine/security/security/#docker-daemon-attack-surface 
for more information.

### 3.3.3 Generate Certificates
The generation of TLS certificates for LME is out of scope of this documentation. There is plenty of guides online for this.


You will require certificates for the following:
* Root CA - Certificate only
* Logstash - Server authentication certificate and key
* nginx - Server authentication and key
* Winlogbeat client - Client authentication certificate and key


To load these into Docker, run:
* ca cert:
```
docker secret create ca.crt <Path to your file>
```
* nginx:

```
docker secret create nginx.key <Path to your file>
docker secret create nginx.crt <Path to your file>
```
* logstash:
```
docker secret create logstash.key <Path to your file>
docker secret create logstash.crt <Path to your file>
```




### 3.3.4 Nginx Config


Create an nginx configuration file called nginx.conf (this file can be created anywhere), The contents should be below
```nginx
upstream kibanaus {
  server kibana:5601;
}


server {
    listen                443 ssl;
    server_name           localhost;
    ssl_certificate       /run/secrets/nginx.crt;
    ssl_certificate_key   /run/secrets/nginx.key;
 
    location / {
        auth_basic "LME Admin";
        auth_basic_user_file /run/secrets/nginx_unpw;
        proxy_pass http://kibanaus;
    }
}
```

Add this configuration to the Docker configuration store using the following command:

```docker config create nginx.conf nginx.conf```

### 3.3.5 Docker Swarm Changes
copy [docker-compose-stack.yml](/Chapter%203%20Files/docker-compose-stack.yml) to docker-compose-stack-live.yml

Edit the docker-compose-stack-live.yml 
Replace the two instances of the text “ram-count” on line 10 to your chosen ram usage for elasticsearch.
For example after you have edited the file the line should look similar to below:
```- "ES_JAVA_OPTS=-Xms5g -Xmx5g"``` 

While you are free to use your own judgement, for this we recommend the following values. This is what the [easy option](/docs/chapter3-easy.md) would do for you.

|Host Ram|Enter in config|
|--------|--------|
|Less than 8GB| Not Supported|
|Greater than 8G, less than 16G| Your Ram minus 4|
|Greater than 17G, less than 32G| Your Ram minus 6|
|Greater than 33 less than 49|Your Ram minus 8G|
|Greater than 50G| Ram = 31G|



### 3.3.6 Generate Nginx Password
The following command will hash your chosen password with an appropriate hashing algorithm for Nginx


```openssl passwd -noverify -stdin -apr1```

it will appear to hang, type your password in (it will not be echoed to the terminal) then press enter.
You should then be presented with a file hash.


Create a file named nginx_unpw.txt and into this paste the previously created hash, prefixed with your chosen username and colon. For example:


```myName:$apr1$r31.....$HqJZimcKQFAMYayBlzkrA/```


Now add this file to the docker secrets store with


```docker secret create nginx_unpw nginx_unpw.txt```
### 3.3.7 Logstash Configuration
Copy the logstash configuration obtained from [GitHub](/Chapter%203%20Files/logstash.conf) onto the docker configuration store


```docker config create logstash.conf logstash.conf```

### 3.3.8 Logstash Extra Configuration
Copy the os build version to os friendly name mapping file from [GitHub](/Chapter%203%20Files/osmap.csv) onto the docker configuration store.

```docker config create osmap.csv osmap.csv```

### 3.3.9 Build Curator
You need to manually build the curator service, the files for this docker image can be found in [Chapter 3 Files on GitHub](/Chapter%203%20Files/curator). You can do this by running:

```docker build -t lme/curator curator/ --no-cache```

## 3.4 Deploy the stack
You are now ready to deploy the LME docker stack. Run the following command as root, or with sudo:


```docker stack deploy lme --compose-file docker-compose-stack-live.yml```


## 3.5 Configuring Winlogbeat on Windows Event Collector Server
In order for logs to get from the Windows event collector to the database running on the Linux server you need to install Winlogbeat.


Winlogbeat reads the event logs on the Windows machine according to the configuration file provided to it. Once the event logs have been opened, Winlogbeat sends all of the new logs (and some historic) to your chosen database.

### 3.5.1 Files Required for the Windows server
You need the following files. Some of these you obtained earlier, after running the deploy script, or when manually making certificates. Others are available from the official Winlogbeat zip downloaded from the elastic site.


* root-ca.crt (you should have made these in section 3.3.3)
* wlbclient.key (you should have made these in section 3.3.3)
* wlbclient.crt (you should have made these in section 3.3.3)
* [install-service-winlogbeat.ps1](https://www.elastic.co/downloads/beats/winlogbeat)
* [winlogbeat.yml](/Chapter%203%20Files/winlogbeat.yml)
* [winlogbeat.exe](https://www.elastic.co/downloads/beats/winlogbeat)

### 3.5.2 Winlogbeat Config
Edit the winlogbeat.yml file and add the Linux server DNS name in the appropriate place.
If your certificates are not in the same place as the locations in the file, please change this. Also, pay attention to the double slashes, these are required!

### 3.5.3 Install Winlogbeat
Open PowerShell as an administrator and run 
```./install-service-winlogbeat.ps1```

## 3.6 Configuring retention
If you wish to change the default retention clauses, please edit docker-compose-stack.yml and edit the following lines:
```
RETENTION_DAYS: 180  
RETENTION_GB: 800
```
Once these have been edited, you can update the system with the following command:

```./deploy.sh update```


You can now visit the website https://linux_server_ip/ to view your logs.

# Chapter 3 - Checklist


1. Check Services.msc on the Windows box. Does the winlogbeat show as running and automatic?
2. On the Linux machine check the output of ‘docker stack ps lme’ , You should see lme_elasticsearch/lme_nginx/lme_kibana and lme_logstash all in the current state of ‘running’

## Now move onto [Chapter 4 - Post Install Actions ](chapter4.md)

________________


# Chapter 3 - Troubleshooting
Should problems arise during this phase, the logs can be found in %programdata%/winlogbeat/
