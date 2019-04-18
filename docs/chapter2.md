# Chapter 2 – Sysmon Install

## Chapter Overview
In this chapter we will:
* Setup a GPO or SCCM job to deploy sysmon across your clients.

## 2.1 Introduction
Sysmon is a Windows service from Microsoft which logs Windows activity to event logs, based of settings defined in an XML configuration file.


**By following this guide and using Sysmon, you are agreeing to the following EULA. 
Please read this before continuing.
https://docs.microsoft.com/en-us/sysinternals/license-terms**
	
LME supports either GPO or SCCM Deployment. It is your choice which of these you use, but you should not use both.

## 2.2 GPO Deployment

Group Policy Object (GPO) deployment involves created a 'scheduled task' that will periodically connect to a network folder location and run update.bat to install Sysmon or modify an existing installation.

Using Microsoft Group Policy to deploy LME requires two main things:
* A location to host the configuration and executables.
* A Group Policy Object (GPO) to create a scheduled task.

### 2.2.1 - Folder Layout
A centralised network folder accessible by all machines that are going to be running sysmon is needed. We suggest inside the sysvol directory as a suitable place since this is configured by default to have very restricted write permissions.
**It is important that the folder contents cannot be modified by users, hence recommending Sysvol folder!**


You will need to download the below files and copy them to an appropriate location such as sysvol located at ``` \\%YourDomainName%\sysvol\%YourDomainName%\Sysmon ```
* Sysmon64.exe - https://docs.microsoft.com/en-us/sysinternals/downloads/sysmon
* sigcheck64.exe  - https://docs.microsoft.com/en-us/sysinternals/downloads/sigcheck
* sysmon.xml - [SwiftOnSecurity is the recommended Sysmon config](https://github.com/SwiftOnSecurity/sysmon-config/blob/master/sysmonconfig-export.xml).
	* **Using the SwiftOnSecurity XML will ensure the best compatability with the pre-made dashboards.**
	* The SwiftOnSecurity configuration is a good starting point, and more advanced users will benefit from customisation to include/exclude events.
	* You will need to rename the downloaded file to sysmon.xml!
* update.bat  - From [Our GIT](/Chapter%202%20Files/GPO%20Deployment/update.bat) (Based on work by Ryan Watson & Syspanda.com)


Looking in the sysvol folder you should now be able to see similar to below. 
  
![Sysvol File Layout](sysvol.jpg)
<p align="center">
Figure 5: Sysvol File Layout
</p>


### 2.2.2 - Scheduled task GPO Policy
This section sets up a scheduled task to run update.bat (stored on a network folder), distributed through Group Policy.

Import the [LME-Sysmon-Task](/Chapter%201%20Files/lme_gpo_for_windows.zip) GPO into group policy management and link the object to a test Organisational Unit (OU). Once the GPO is confirmed as working in your environment then you can link the GPO to a larger OU to deploy LME further.

1. Open up group policy management editor
2. Edit the Lme-Sysmon-Task GPO
3. Change the setting for the batch file network location by navigating to: ```Computer Configuration\Preferences\Control Panel Settings\Scheduled Tasks\lme-sysmon-deploy\Actions``` and then select ```"Start a program" > Edit > Change the Location.```

For example \\ad.testme.local\SYSVOL\ad.testme.local\Sysmon\update.bat


## 2.3 SCCM Deployment
Whilst SCCM deployment is not usually the first choice for the deployment of Sysmon we have included an example install and uninstall powershell along with a detection criteria that works with SCCM.
Files for this portion of the tutorial can be found [here](/Chapter%202%20Files/SCCM%20Deployment/)


Install Program:
```powershell.exe -Executionpolicy unrestricted -file Install_Sysmon64.ps1```


Uninstall program:
```powershell.exe -Executionpolicy unrestricted -file Uninstall_Sysmon64.ps1```


“Detection method”:
File exists - C:\Windows\sysmon64.exe


# Chapter 2 - Checklist
1. Do you have the Sysmon service running on a sample of the clients?
2. Is the Sysmon Eventlog showing data? (It’s located in Applications and Services Logs/Microsoft/Windows/Sysmon/Operational)
3. Are you seeing Sysmon logs in the forwarded events folder on the Windows event forwarder box?

## Now move onto [Chapter 3A - Easy Install](chapter3-easy.md) or [Chapter 3B - Manual Install](chapter3-manual.md)
