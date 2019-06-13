# Chapter 1 – Set up Windows Event Forwarding

![Event Forwarding overview](eventforwarding_overview.jpg)
<p align="center">  
Figure 1: Finished state of Chapter 1
</p>

## Chapter Overview
In this chapter we will:
* Install a new windows server for events to be sent to (or choose an existing suitable server).
* Add some Group Policy Objects (GPOs) to your Active Directory (AD).
* Configuring the Windows event collector listener service.
* Configure clients to send logs to this box.




## 1.1 Introduction
This chapter will cover setting up the in-built Windows functionality for event forwarding. This effectively takes the individual events (such as a file being opened) and sends them to a central machine for processing. This is similar to the setup discussed in this [Microsoft blog](https://blogs.technet.microsoft.com/jepayne/2017/12/08/weffles/). 


Only a selection of events will be sent from the clients ‘Event Viewer’ to a central ‘Event Collector’. The events will then be uploaded to the database and dashboard in Chapter 3.
This chapter will require the clients and event collector to be Active Directory domain joined and the event collector can be either a Windows server or a Windows client operating system.

## 1.2 Firewall rules and where to host
You will need TCP port 5985 open between the clients and the Windows Event Collector. You also need port 5044 open between the Windows Event Collector and the Linux server.




We recommend that this traffic does not go directly across the Internet, so you should host the Windows Event Collector on the local network, in a similar place to the Active Directory server.
	



## 1.3 Import Group Policy objects
  
![Group Policy Setup](gpo.jpg)
<p align="center">
Figure 2: Setting up Group Policy
</p>


### 1.3.1 Domain Controller/Management Workstation Steps

1. Apply the [LME-WEC-Server GPO](/Chapter%201%20Files/lme_gpo_for_windows.zip) to the Windows Event Collector only (either using OU filtering, security filtering or WMI filter). You can use the group policy management tool, Normally found on your domain controller (or management workstation with Remote Server Administration Tools installed).
	
	* If you are not sure how to do this, here is a [step by step guide to GPOs](/docs/gpo_step_by_step.md)

2. Apply the [LME-WEC-Client GPO](/Chapter%201%20Files/lme_gpo_for_windows.zip) to a test selection of machines. We recommend that you use a test group of machines rather than your whole estate until you have confirmed the GPO is working as intended - as seen in the [Checklist](#chapter-1---checklist). 
3. Edit the [LME-WEC-Client GPO](/Chapter%201%20Files/lme_gpo_for_windows.zip) “Computer Configuration/Policies/Administrative Templates/Windows Components/Event Forwarding/Configure Target Subscription Manager” and change the FQDN to match your windows collector box name, this option can be seen in Figure 3 below.

![Group Policy Server Name](gpoedit.jpg)
<p align="center">
Figure 3: Editing Server Name In Group Policy
</p>

**It is recommended that you now follow the below steps to restrict access to WinRM to specific IP addresses**

Both the LME-WEC-Server and LME-WEC-Client GPOs include a wildcard filter allowing any IP address to connect to the WinRM service, We strongly recommend that this is restricted to specific IP addresses or ranges.

The filter setting is located at "Computer Configuration/Policies/Administrative Templates/Windows Components/Windows Remote Management (WinRM)/WinRM Service/allow remote server management through WinRM"


### 1.3.2 Windows Collector Box Steps

1. Copy the [lme_wec_config.xml](/Chapter%201%20Files/lme_wec_config.xml) file to the windows event collector server.
2. Run a command prompt, change to the directory containing the wec_config.xml file you just copied.
3. Run the command ```wecutil cs lme_wec_config.xml``` as an administrator.

**Note if you are using Windows Server 2016 (version 1903 or greater) or Windows Server 2019 you will probably need to apply the microsoft fix to the Windows collector box**

You can find more details about this issue and the commands to run to fix this [Here](https://support.microsoft.com/en-in/help/4494462/events-not-forwarded-if-the-collector-runs-windows-server-2019-or-2016)
________________

## Chapter 1 - Checklist
1. On the Windows Event Collector, Run Event Viewer by either Start->Run->eventvwr.exe, or under ‘Windows Administrative Tools’ in the start menu.
2. Confirm machines are checking in, as per Figure 3. The 'Source Computers' field should contain the number of machines currently connected.


![Group Policy Setup](eventviewer.jpg)
<p align="center">
Figure 4: Event Log Subscriptions
</p>

## Now move onto [Chapter 2 – Sysmon Install](chapter2.md) 
