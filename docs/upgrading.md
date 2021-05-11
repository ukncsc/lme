# Upgrading

## Upgrade Paths
Below you can find the upgrade paths that are currently supported and what steps are required for these upgrades. Note that major version upgrades tend to include significant changes, and so will require manual intervention and will not be automatically applied, even if auto-updates are enabled.

### Upgrade From v0.3
#### Index Mapping

When LME was first launched, the index mapping (for Winlogbeat) that was used was predictable. This meant that we did not need to provide the index map, as it was automatically generated when the first bits of data was ingested via Logstash. The map links data fields to data types, so we can search and perform functions on them properly. For example, 'event.provider' is a text field etc. 

As the project has grown, and as Elastic has enhanced the components that we use, it has become necessary to provide this map. 

Additionally, as part of this release we have migrated the GeoIP enrichment feature from Logstash to the Elastic pipeline, and are now making use of a configuration file to store version specific information. 

Applying these changes is automated for any new installations. But, if you have an existing installation, you need to conduct some extra steps. **Before performing any of these steps it is advised to take a backup of the current installation using the method described [here](/docs/backups.md).**

Ensure you have the latest version of LME from the GitHub repository by using the following command:

```
sudo git -C /opt/lme/ pull
```

Then you can begin the process as follows. Make sure you have your LME server's hostname, and the password for both the "elastic" and "dashboard_update" users to hand before you begin [**Note: the dashboard update user may have been previously displayed as "update_user"**]:

```
cd /opt/lme/Chapter\ 3\ Files/
sudo ./deploy.sh upgrade
```

You will be promted to enter your elastic and dashboard_update users' passwords and the server's current hostname, and this will update the relevant settings/files that are now included as part of this project and will be used/supported from now on. 

The WEC configuration file has been updated in this release to include collection for several additional events, and this config change must be manually applied by copying over the [lme_wec_config.xml](/Chapter%201%20Files/lme_wec_config.xml) to the Event Collector server and then updating the event collection settings. This can be done by deleting and then re-creating the event subscription with the following commands from an Administrative command prompt, as discussed in [Chapter 1](chapter1.md#132-windows-collector-box-steps):

```
wecutil ds lme
wecutil cs lme_wec_config.xml
```

You can confirm the LME WEC subscription has been succesfully updated by running the command ```wecutil es``` and ensuring the LME subscription is present, or  by following the [checklist](chapter1.md#chapter-1---checklist) from Chapter 1.

We recommend that you take this opportunity to ensure that you are running the latest version of Winlogbeat officially supported by LME. This is currently version 7.11.2 which can be found [here](https://www.elastic.co/downloads/past-releases/winlogbeat-7-11-2). Steps for installing Winlogbeat can be found in [section 3.3](/docs/chapter3.md#33-configuring-winlogbeat-on-windows-event-collector-server) and a walkthrough of the re-installation process can be found [below](#upgrade-from-v02).

Once this has been completed it should be possible to trigger the rest of the update to complete automatically, using the standard method:

```
cd /opt/lme/Chapter\ 3\ Files/
sudo ./deploy.sh update
```

The rules built-in to the Elastic SIEM can then be updated to the latest version by following the instructions listed in [Chapter 4](chapter4.md#42-enable-the-detection-engine) and selecting the option to update the prebuilt rules when prompted, before making sure all of the rules are activated:

![Update Rules](update-rules.png)

It is worth noting that this will only fix data coming into LME after this is run, so something needs to be done to be fix existing data.

#### So, how do I fix my current data?

You have three options:

##### 1. Re-Index you existing Data (Recommended)

The recommended way to resolve the incorrect mapping applied to the existing data is to manually re-index this data. As the new mapping template is applied to all indices with the "winlogbeat" index pattern, this will ensure that old data is re-indexed with the correct mapping.

The Elastic documentation around re-indexing data can be found [here](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-reindex.html) and includes detailed instructions for migrating existing indices to a new index, along with a [Painless script](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-reindex.html#docs-reindex-daily-indices) which can be used to achieve this. 

A modified version of this script which has been customised to re-index the winlogbeat indices used within LME is included in the repository and available [here](painless-reindex.txt). This script can be adapted into a curl command, or run directly within the Dev Tools section of Kibana, as shown below:

![Dev Tools](dev-tools.jpg)

![Re-index Script](re-index-script.jpg)

This will output a task ID which can then be used to check the progress of the re-index, in the format shown here:

![Task Response](task.png)

This ID can then be used to monitor the status of the task, and ensure it has completed succesfully before moving on to the next step. This can be done by making the below request, substituting in the task ID which you recieved in response to the previous step:

![Task Status](task-status.png)

The output from this command will indicate the current status of the task, allowing you to monitor it for completion:

![Task Complete](task-complete.png)

If successful, this script will make a duplicate of all existing winlogbeat indices with the phrase "-1" appended to their names. As shown within the Index Management section of the Stack Management area of Kibana:

![Deleting Index](stack-management.jpg)

![Deleting Index](index-selection.png)

![Duplicate Indices](duplicate-indices.jpg)

Upon confirming that the script has successfully completed, and that every current index has been re-indexed, the original indices should be deleted to remove the data stored in the old mapping format. This can be done by selecting all of the indices shown that **do not** have "-1" appended to their name and deleting them in the Manage Indices dropdown.

![Delete Originals](delete-originals.png)

***NOTE*** This script should only be used if your LME instance has sufficient spare storage capacity to contain a duplicate version of all existing logs and their originals at the same time, as the script will effectively double the log volume stored until the original indices are deleted. 

If the script causes errors, or you do not have sufficient free storage to re-index in this manner, it may be necessary to modify the script to re-index only a small number of indices at a time. This can be done by changing the wildcard selection to match only specific dates, e.g. a month at a time, as shown below, which would re-index only those log events from October 2020:

```  
"source": {
    "index": "winlogbeat-*-10-2020"
}
```
This will allow the outdated indices to be manually deleted between each run of the script, in order to ensure that the LME instance does not run out of storage space.

In either instance the goal should ultimately be to ensure that all existing data is successfully re-indexed, and the original indices are fully deleted, as LME will be unable to function correctly if both legacy data (with the original index mapping) and newly ingested logs are present in the same install. This should appear as though every currently saved index ends with the characters ```-1```.

##### 2. Delete Existing Data

The simplest method to resolve conflicts with the existing LME data is simply to delete the data in order to avoid conflicts with the newly deployed index mapping. This will clear all existing data, and so will likely only be suitable for development or test installations, where the contents of existing logs are not considered to be of high importance. It may also be suitable for recently deployed LME installations that have not gathered a significant volume of historical logs yet.

To delete the existing records within LME navigate to the Stack Management section of Kibana, which can be found on the left-hand side as shown below:

![Deleting Index](stack-management.jpg)

Then select the Index Management option within the Elasticsearch menu:

![Deleting Index](index-selection.png)

From here it should be possible to select and then delete all of the saved indices, clearing any existing data from LME:

![Deleting Index](delete-indices.jpg)

***WARNING***
This will clear all existing data from LME, only perform this option if you do not care about the data you already have stored, e.g. in a newly deployed or test instance.

##### 3. Do nothing (Not Recommended)

This option is not recommended, and is liable to cause issues when conducting searches or using any of the provided Kibana dashboards, as these will attempt to search both the old and new data which will be in an incompatible format. 

If taking this approach the legacy format data should ultimately be fully replaced by newly created logs which will eventually resolve the issue, but not until the number of days configured within the LME retention policy have passed.

### Upgrade From v0.2
To upgrade an existing installation of LME to v0.4 follow the steps detailed [here](#index-mapping), including resolving any issues with currently saved data.

Updating from an older LME instance also requires manual changes to the winlogbeat service on the Windows Event Collector machine. We also recommend that you take this opportunity to ensure that you are running the latest version of Winlogbeat officially supported by LME. This is currently version 7.11.2 which can be found [here](https://www.elastic.co/downloads/past-releases/winlogbeat-7-11-2).

Required manual update steps:

* Download the new winlogbeat.yml file from [here](https://github.com/ukncsc/lme/blob/master/Chapter%203%20Files/winlogbeat.yml)
* Open up the OLD winlogbeat.yml file and copy the DNS name on line 4
* Enter the copied DNS name into the new winlogbeat.yml file on line 14 replacing the "logstash_dns_name" text
* Copy winlogbeat-sysmon.js and winlogbeat-security.js file from the latest winlogbeat download and place them in the directories listed below, noting that the version numbers in the path may change:
```
C:\\Program Files\\lme\\winlogbeat-7.11.2-windows-x86_64\\module\\sysmon\\config\\winlogbeat-sysmon.js
C:\\Program Files\\lme\\winlogbeat-7.11.2-windows-x86_64\\module\\security\\config\\winlogbeat-security.js
``` 

Finally, uninstall and reinstall winlogbeat using the following commands (run powershell as admin)
```
./uninstall-service-winlogbeat.ps1
./install-service-winlogbeat.ps1
```

Now check services.msc or similar and ensure that the winlogbeat service is running. 

To get the most out of LME we strongly recommend you follow chapter 4 again to upload the latest dashboards to your LME instance.
To get the smart 'signals' detection engine working we suggest you follow that section in chapter 4 if you have not already. 

### Upgrade From v0.1
The upgrade path from v0.1 is a little different than going forward due to the installation directory being changed.

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
Note that re-installing the service will not affect existing data stored within LME, and so once the re-install has been completed it will still be necessary to re-index any existing data stored, as discussed [here](#so-how-do-i-fix-my-current-data). 

### Upgrade From Versions Earlier than v0.1
Unfortunately due to the disparity of versions before the official v0.1 release there is no formal upgrade path. We recommend following the steps outlined in the upgrade path from v0.1 discussed [here](#v01), which should not result in data loss, but there is no guarantee.

You can find basic troubleshooting steps in the [Troubleshooting Guide](troubleshooting.md).


## Finding your LME version (and the components versions)
When reporting an issue or suggesting improvements, it is important to include the versions of all the components, where possible. This ensures that the issue has not already been fixed! 

### Windows Server
* Operating System: Press "Windows Key"+R and type ```winver```
* WEC Config: Open EventViewer > Subscriptions > "LME" > Description should contain version number
* Winlogbeat Config: At the top of the file C:\Program Files\lme\winlogbeat.yml there should be a version number.
* Winlogbeat.exe version: Press "Windows Key"+R and type ```"C:\Program Files\lme\winlogbeat.exe" version```
* Sysmon config: From either the top of the file or look at the status dashboard
* Sysmon executable: Either run sysmon.exe or look at the status dashboard


### Linux Server
* Docker: on the Linux server type ```docker --version```
* Linux: on the Linux server type ```cat /etc/os-release```
* Logstash config: on the Linux server type ```sudo docker config inspect logstash.conf --pretty```
