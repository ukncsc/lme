# Chapter 3 – Database Install

## Chapter Overview
In this chapter we will:
* Install a new Linux server for events to be sent to.
* Run a script to:
    * install Docker.
    * secure the Linux server.
    * secure the elasticsearch server.
    * generate certificates.
    * deploy the LME Docker stack.
* Make the Windows server send logs to the Linux server.

## Introduction
This section covers the installation and configuration of the Database and search functionality on a Linux server. We will install the ‘ELK’ Stack from ElasticSearch for this portion.


What is the ELK Stack?
"ELK" is the acronym for three open source projects: Elasticsearch, Logstash, and Kibana. Elasticsearch is a search and analytics engine. Logstash is a server‑side data processing pipeline that ingests data from multiple sources simultaneously, transforms it, and then sends it to a "stash" like Elasticsearch. Kibana lets users visualise data with charts and graphs in Elasticsearch.


![Elkstack components](elkstack.jpg)
<p align="center">
Figure 1: Elastic Stack components
</p>



## 3.1 Getting Started
During the installation guide below you will see that the majority of steps are carried out automatically. Commands or file paths are highlighted in grey boxes.

You will need a linux box for this portion, **The deploy script is only tested on Ubuntu Long Term Support (LTS) editions that are currently supported by Docker ([see here](https://docs.docker.com/engine/install/ubuntu/)).** In addition, only installation on a single server is supported. Please see [the resilience documentation](resilience.md) for more details.

### 3.1.1 Firewall Rules
You will need port 5044 open for the event collector to send data into the database (on the Linux server). To be able to access the web interface you will need to have firewall rules in place to allow access to port 443 (HTTPS) on the Linux server.

### 3.1.2 Web Proxy Settings
If the ELK stack is being deployed behind a web proxy, and Docker isn't configured to use the proxy, the deploy script can hang without completing due to docker being unable to pull the required images. The deployment script will prompt for the details of a proxy server and perform the necessary configuration. Alternatively to configure Docker to use the web proxy in your environment manually, do the following before running the deployment script.

1) Create a systemd drop-in directory for the Docker service:
```
sudo mkdir -p /etc/systemd/system/docker.service.d
```
2) Create a file named /etc/systemd/system/docker.service.d/http-proxy.conf that adds the HTTP_PROXY and HTTPS_PROXY environment variables (keep/delete as required for your environment):
```
[Service]
Environment="HTTP_PROXY=http://[proxy address or IP]:[proxy port]"
Environment="HTTPS_PROXY=https://[proxy address or IP]:[proxy port]"
```
3) Reload the service daemon:
```
sudo systemctl daemon-reload
```

Check the [official Docker documentation](https://docs.docker.com/config/daemon/systemd/#httphttps-proxy) for this process, including details on how to bypass the proxy if you have internal image registries which need to be reachable from this host.

## 3.2 Install LME the easy way using our script

At the time of writing only security updates are configured on Ubuntu, so please install Ubuntu on a new virtual or physical machine. You may have already done this as part of the pre-requisites in the initial readme file.

SSH into your Linux server and run the following commands:

```
# Install Git client to be able to clone the LME repository
sudo apt update
sudo apt install git -y
# Download a copy of the LME files
sudo git clone https://github.com/ukncsc/lme.git /opt/lme/
# Change to the pre-release branch for testing
sudo git checkout 0.4-pre-release
# Change to the lme directory for the Linux server files
cd /opt/lme/Chapter\ 3\ Files/
# Execute script with root privileges
sudo ./deploy.sh install
```

Running the above commands will:
1) Enable auto security updates (Ubuntu Only)
2) Generate TLS certificates.
3) Install Docker Community Edition.
4) Configure Docker to run ELK.
5) Change Elasticsearch configuration, including retention based upon disk size.


The deploy script will output a number of usernames and passwords for use when accessing the dashboard and for the internal systems.

The usernames and passwords will be provided in a message similar to below.

```
##################################################################################
## Kibana/Elasticsearch Credentials are (these will not be accesible again!!!!) ##
##
## Web Interface login:
## elastic:<PASSWORD>
##
## System Credentials
## kibana:<PASSWORD>
## logstash_system:<PASSWORD>
## logstash_writer:<PASSWORD>
## dashboard_update:<PASSWORD>
##################################################################################
```
**It is important that these are safely stored. Access to these passwords would allow an attacker to erase the logs.**

### 3.2.2 Changing default retention policy
The default retention will be calculated based upon 80% of the machine's disk size. The calculated size will be displayed as an output of the script.

If you wish to change the default retention (e.g. you expanded your disk), please edit ```docker-compose-stack.yml``` and edit the following lines.
```
RETENTION_DAYS: 180
RETENTION_GB: 800
```
Once these have been edited you can update the system with the following command: ```./deploy.sh update```

**Note:** The software starts deleting events based upon whichever retention criteria is met first.

### 3.2.3 Download Files for Windows Event Collector

The deploy.sh script has created files on the Linux server that need to be copied across and used on the Windows Event Collector server.

The files have been zipped for convenience, with the filename and location ``` /opt/lme/files_for_windows.zip ```.

There are many ways you can copy files to and from Linux servers, WinSCP is used in the example below.

![WinSCP Login Prompt](winscp.jpg)
<p align="center">
Figure 2: WinSCP Login Prompt
</p>

If you do not have a password, but a keyfile (for example, AWS servers) then [this article](https://docs.aws.amazon.com/transfer/latest/userguide/getting-started-use-the-service.html) will help.



## 3.3 Configuring Winlogbeat on Windows Event Collector Server

Now you need to install Winlogbeat on the Windows Event Collector. Winlogbeat reads Event Viewer on the Windows Event Collector (based upon a configuration file) and sends them to your Linux server.

### 3.3.1 Files Required

You need the following files which you obtained earlier after running the deploy script or when manually making certificates:

In 'files_for_windows.zip', copied in [step 3.2.3](#323-download-files-for-windows-event-collector)
* root-ca.crt
* wlbclient.key
* wlbclient.crt
* winlogbeat.yml

You will also require the latest supported version of the [Winlogbeat zip](https://www.elastic.co/downloads/past-releases/winlogbeat-7-11-2) downloaded from the Elastic site. **The current version officially supported by LME is 7.11.2.**

### 3.3.2 Install Winlogbeat
On the Windows Event Collector server extract the 'files_for_windows.zip' archive and copy the 'lme' folder (contained within 'tmp' inside the extracted files) to the following location: 

```
C:\Program Files\lme
```
Next, unzip the downloaded winlogbeat zip file and copy its contents into the ```C:\Program Files\lme\``` folder. The resultant folder should look like the image below, noting that the specific version of winlogbeat in use may differ slightly:

![Winlogbeat Install Location](winlogbeat-location.png)
<p align="center">
Figure 3: Winlogbeat Install Location
</p>

Then, move the 'winlogbeat.yml' file located at ```C:\Program Files\lme\winlogbeat.yml``` into the winlogbeat folder ```C:\Program Files\lme\winlogbeat-7.[x].[y]-windows-x86_64```, overwriting the existing file when prompted to do so.

Now, open PowerShell as an administrator and run the following command from the winlogbeat directory, allowing the script to run if prompted to do so: ```./install-service-winlogbeat.ps1```

![Winlogbeat Install Script](winlogbeat-install.png)
<p align="center">
Figure 4: Winlogbeat Install Script

Then in the same PowerShell window start the winlogbeat service by running:

```
Start-Service winlogbeat
```

Lastly, open ```services.msc``` as an administrator, and make sure the winlogbeat service is installed, is set to start automatically, and is running:

![Winlogbeat Service Running](winlogbeat-running.png)
<p align="center">
Figure 4: Winlogbeat Service Running

# Chapter 3 - Checklist

1. Check Services.msc on the Windows box, Does the winlogbeat show as running and automatic?
2. On the Linux machine, check the output of ```docker stack ps lme``` , You should see lme_elasticsearch/lme_kibana and lme_logstash all in the 'current' state of ‘running’
3. You can now visit the website https://your_Linux_server/ and access Kibana. The username and password is provided from the script in [Chapter 3.2](#32-install-lme-the-easy-way-using-our-script).

## Now move onto [Chapter 4 - Post Install Actions ](chapter4.md)


# Chapter 3 - Troubleshooting
Should problems arise during this phase, the logs can be found in ```%programdata%/winlogbeat/```.
