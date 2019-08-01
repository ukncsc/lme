# Upgrading

## Upgrade Paths
Below you can find the upgrade paths that are currently supported and what steps are required for these upgrades.

### v0.1 - > v0.2


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
