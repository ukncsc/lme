# Upgrading

## Upgrade Paths
Below you can find the upgrade paths that are currently supported and what steps are required for these upgrades.

### v0.1 - > v0.2
The upgrade path between v0.1 and v0.2 is a little different than going forward due to the installation directory being changed.
To update please do the following on the Linux server:

```
# Change to the lme directory for the Linux server files
cd ~/lme/Chapter\ 3\ Files/
# execute script with root privileges
sudo ./deploy.sh uninstall
```

Then following the standard installation instructions for the Linux server do the following:

```
# Change to the lme directory for the Linux server files
cd /opt/lme/Chapter\ 3\ Files/
# execute script with root privileges
sudo ./deploy.sh install
```

### v0.2 - > v0.3
To upgrade an existing installation of LME to v0.3 run the deployment script with the "update" parameter.

```
# Change to the lme directory for the Linux server files
cd /opt/lme/Chapter\ 3\ Files/
# execute script with root privileges
sudo ./deploy.sh update
```

V0.3 moves a number of settings into pipelines in the kibana gui to make customisation easier. To support this update we require the password of the 'elastic' user which is not saved to disk. Run the below command and enter the elastic user password when prompted.

```
sudo ./deploy.sh pipelineupdate
```

This update also requires manual changes to the winlogbeat service on the windows event collector machine, we recommend that you take this oportunity to ensure that you are running the latest version of winlogbeat also. 

Required manual update steps.

* Download the new winlogbeat.yml file from [here](https://github.com/ukncsc/lme/blob/master/Chapter%203%20Files/winlogbeat.yml)
* Open up the OLD winlogbeat.yml file and copy the DNS name on line 4
* Enter the copied DNS name into the new winlogbeat.yml file on line 14 replacing the "logstash_dns_name" text
* Copy winlogbeat-sysmon.js and winlogbeat-security.js file from the latest winlogbeat download and place them in the directories listed below
```
C:\\Program Files\\lme\\winlogbeat-7.6.1-windows-x86_64\\module\\sysmon\\config\\winlogbeat-sysmon.js
C:\\Program Files\\lme\\winlogbeat-7.6.1-windows-x86_64\\module\\security\\config\\winlogbeat-security.js
``` 

now run
Finally, uninstall and reinstall winlogbeat using the following commands (run powershell as admin)
```
./uninstall-service-winlogbeat.ps1
./install-service-winlogbeat.ps1
```

Now check services.msc or similar and ensure that the winlogbeat service is running. 

To get the most out of LME we strongly recommend you follow chapter 4 again to upload the latest dashboards to your LME instance.
To get the smart 'signals' detection engine working we suggest you follow that section in chapter 4 if you have not already. 


### Versions Earlier than v0.1
Unfortunately due to the disparity of versions before the official v0.1 release there is no formal upgrade path. We recommend running the following commands which should not lose data but there is no guarantee.

Download the latest version of LME
``` 
sudo ./deploy.sh uninstall
sudo ./deploy.sh install
```



You can find basic troubleshooting steps in the [Troubleshooting Guide](troubleshooting.md).


## Finding your LME version (and the components versions)
When reporting an issue or suggesting improvements, it is important to include the versions of all the components, where possible. This ensures that the issue has not already been fixed! 

### Windows Server
* Operating System: Press CTRL+R and type ```winver```
* WEC Config: Open EventViewer > Subscriptions > "LME" > Description should contain version number
* Winlogbeat Config: At the top of the file C:\Program Files\lme\winlogbeat.yml there should be a version number.
* Winlogbeat.exe version: Press CTRL+R and type ```"C:\Program Files\lme\winlogbeat.exe" version```
* Sysmon config: From either the top of the file or look at the status dashboard
* Sysmon executable: Either run sysmon.exe or look at the status dashboard



### Linux Server
* Docker: on the Linux server type ```docker --version```
* Linux: on the Linux server type ```cat /etc/os-release```
* Logstash config: on the Linux server type ```sudo docker config inspect logstash.conf --pretty```
* Nginx config: on the Linux server type ```sudo docker config inspect nginx.conf --pretty```
