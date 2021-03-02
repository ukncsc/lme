# FAQ

## Basic Troubleshooting 
You can find basic troubleshooting steps in the [Troubleshooting Guide](troubleshooting.md).

## Finding your LME version (and the components versions)
When reporting an issue or suggesting improvements, it is important to include the versions of all the components, where possible. This ensures that the issue has not already been fixed! 

### Windows Server
* Operating System: Press CTRL+R and type ```winver```
* WEC Config: Open EventViewer > Subscriptions > "LME" > Description should contain version number
* Winlogbeat Config: At the top of the file C:\Program Files\lme\winlogbeat.yml there should be a version number.
* Winlogbeat.exe version: Press "Windows Key"+R and type ```"C:\Program Files\lme\winlogbeat.exe" version```
* Sysmon config: From either the top of the file or look at the status dashboard
* Sysmon executable: Either run sysmon.exe or look at the status dashboard



### Linux Server
* Docker: on the Linux server type ```docker --version```
* Linux: on the Linux server type ```cat /etc/os-release```
* Logstash config: on the Linux server type ```sudo docker config inspect logstash.conf --pretty```
* Nginx config: on the Linux server type ```sudo docker config inspect nginx.conf --pretty```




## Reporting a bug
To report an issue with LME please use the GitHub 'issues' tab at the top of the (GitHub) page.
Where possible use the template seen below when filling out your issue.


### GitHub Issue template

**Describe the issue** 

A clear and concise description of what the issue is.

**To Reproduce**

Steps to reproduce the behavior:
1. Go to '...'
2. Click on '....'
3. Scroll down to '....'
4. See error

**Expected behavior**

A clear and concise description of what you expected to happen.

**Screenshots**

If applicable, add screenshots to help explain your problem.

**Windows Event Collector (please complete the following information):**
 - OS: [e.g. Server 2016 v1607]
 - WEC Config [e.g. V0.1]
 - Winlogbeat Config [e.g. V0.1]
 - Winlogbeat.exe version [e.g. winlogbeat version 6.4.2 (386)]
 - sysmon config [e.g. File hash or Version]
 - sysmon executable [e.g. V8.1]

**Linux Server (please complete the following information):**
 - Docker: [e.g. Docker version 18.09.3]
 - Linux: [e.g. PRETTY_NAME="Ubuntu 18.04.2 LTS"]
 - Logstash Version [e.g. #LME logstash config V0.1]
 - Nginx config [e.g. #LME nginx config V0.1]

**Additional context**
Add any other context about the problem here.



## Requesting a new feature / improvement 
To request a new feature or improvement with LME please use the GitHub 'issues' tab at the top of the (GitHub) page.

Feature requests will be discussed by two working groups to decide if the features are a good fit for the LME project. 
Features can have three states:

* **Pending** - New features not discussed at the working groups yet
* **Accepted** - Feature will be developed - These will be added to the LME roadmap with a priority decided based on an analysis of the effort to reward.
* **Rejected** - This feature will not be developed as it does not fit LME

Please use the following template to submit your feature request via the GitHub issue tab 

### Feature Request Template
**Is your feature request related to a problem? Please describe.**

A clear and concise description of what the problem is. Ex. I'm always frustrated when [...]

**Describe the solution you'd like**

A clear and concise description of what you want to happen.

**Describe alternatives you've considered**

A clear and concise description of any alternative solutions or features you've considered.

**Additional context**

Add any other context or screenshots about the feature request here.
