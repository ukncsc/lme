# Chapter 3 – Database Easy Install

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
"ELK" is the acronym for three open source projects: Elasticsearch, Logstash, and Kibana. Elasticsearch is a search and analytics engine. Logstash is a server‑side data processing pipeline that ingests data from multiple sources simultaneously, transforms it, and then sends it to a "stash" like Elasticsearch. Kibana lets users visualize data with charts and graphs in Elasticsearch.
  

![Elkstack components](elkstack.jpg)
<p align="center">
Figure 1: Elastic Stack components
</p>



## 3.1 Getting Started
During the installation guide below you will see that the steps can been carried out automatically using the [Easy method](chapter3-easy.md). Commands are highlighted in grayboxes.

You will need a linux box for this portion, **The deploy script is only tested on Ubuntu 18.04 Long Term Support (LTS).**

### 3.1.1 Firewall Rules
You will need port 5044 open for the event collector to send data into the database (on the Linux server), To be able to access the web interface you will need to have firewall rules in place to allow access to port 443 (HTTPS) on the Linux server.


## 3.2 Install LME the easy way using our script

At the time of writing only security updates are configured on Ubuntu, so please install Ubuntu on a new virtual or physical machine. You may have already done this as part of the pre-requisites in the initial readme file.

SSH into your Linux server and run the 10.following commands:

```
# Install Git client to be able to clone the LME repository
sudo apt update
sudo apt install git -y
# download a copy of the LME files
sudo git clone https://github.com/ukncsc/lme.git /opt/lme/
# Change to the lme directory for the Linux server files
cd /opt/lme/Chapter\ 3\ Files/
# execute script with root privileges
sudo ./deploy.sh install
```

Running the above commands will:
1) Enables auto security updates (Ubuntu Only)
2) Generate TLS certificates.
3) Install Docker Community Edition.
4) Configures Docker to run ELK.
5) Changes Elasticsearch configuration, including retention based upon disk size.


The deploy script will output an number of usernames and passwords for use when accessing the dashboard and for the internal systems. 

The usernames and passwords will be provided in a message similar to below.

```
##################################################################################"
## KIBANA/Elasticsearch Credentials are (these will not be accesible again!!!!) ##"
## elastic:<PASSWORD>"
## kibana_system_pass:<PASSWORD>"
## logstash_system:<PASSWORD>"
## logstash_writer:<PASSWORD>"
##################################################################################"
```
**It is important that these are safely stored. Access to these passwords would allow an attacker to erase the logs.**

### 3.2.2 Changing default retention policy
The default retention will be calculated based upon 80% of the machines disk size. The calculated size will be displayed as an output of the script.

If you wish to change the default retention (e.g. you expanded your disk), please edit ```docker-compose-stack.yml``` and edit the following lines.
```
RETENTION_DAYS: 180  
RETENTION_GB: 800
```
Once these have been edited you can update the system with the following command: ```./deploy.sh update```

**Note:** The software starts deleting events based upon whichever retention criteria is met first.

### 3.2.3 Download Files for Windows Event Collector

The deploy.sh script has created files on the Linux server that need to be copied across and used on the Windows Event Collector server.

The files have been zipped for convenience, with the filename ``` files_for_windows.zip ```.

There are many ways you can copy files to and from Linux servers, WinSCP is used in the example below.

![WinSCP Login Prompt](winscp.jpg)
<p align="center">
Figure 2: WinSCP Login Prompt
</p>

If you do not have a password, but a keyfile (for example, AWS servers) then [this article](https://docs.aws.amazon.com/transfer/latest/userguide/getting-started-use-the-service.html) will help.



## 3.3 Configuring Winlogbeat on Windows Event Collector Server

Now you need to install Winlogbeat on the Windows Event Collector. Winlogbeat reads Event Viewer on the Windows Event Collector (based upon a configuration file) and sends them to your Linux server.

### 3.3.1 Files Required

You need the following files, some of these you obtained earlier after running the deploy script or when manually making certificates, others are available from the official [Winlogbeat zip](https://www.elastic.co/downloads/beats/winlogbeat) downloaded from the elastic site, **This must be version 7 or greater**.

In 'files_for_windows.zip', copied in [step 3.2.2](#323-download-files-for-windows-event-collector)
* root-ca.crt
* wlbclient.key
* wlbclient.crt
* winlogbeat.yml 

In the zip file obtained from https://www.elastic.co/downloads/beats/winlogbeat
* install-service-winlogbeat.ps1
* winlogbeat.exe 

### 3.3.2 Install Winlogbeat
On the windows event collector server unzip the winlogbeat file and replace 'winlogbeat.yml' with the one that came in 'files_for_windows.zip'.
If your certificates are not in the same place as the locations in the file please change this too. Pay attention to the double slashes, these are required!

Now open PowerShell as an administrator and run the following command from the unzipped folder: ```./install-service-winlogbeat.ps1```


# Chapter 3 - Checklist

1. Check Services.msc on the Windows box, Does the winlogbeat show as running and automatic?
2. On the Linux machine, check the output of ```docker stack ps lme``` , You should see lme_elasticsearch/lme_nginx/lme_kibana and lme_logstash all in the 'current' state of ‘running’
3. You can now visit the website https://your_Linux_server/ and access Kibana. The username and password is provided from the script in [Chapter 3.2](#32-install-lme-the-easy-way-using-our-script).

## Now move onto [Chapter 4 - Post Install Actions ](chapter4.md)


# Chapter 3 - Troubleshooting
Should problems arise during this phase, the logs can be found in %programdata%/winlogbeat/
