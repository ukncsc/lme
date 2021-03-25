![N|Solid](https://www.ncsc.gov.uk/static-assets/images/ncsc_larger_strap.png)
# Logging Made Easy

Copyright 2018-2021 Crown Copyright
 
Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 
http://www.apache.org/licenses/LICENSE-2.0
 
Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.


## What is Logging Made Easy (LME)?

Logging Made Easy is a self-install tutorial for small organisations to gain a basic level of centralised security logging for Windows clients and provide functionality to detect attacks. It's the coming together of multiple free and open-source software (some which is covered under licences other than Apache V2), where LME helps the reader integrate them together to produce an end-to-end logging capability. We also provide some pre-made configuration files and scripts, although there is the option to do it on your own. 

Logging Made Easy can:
- Tell you about software patch levels on enrolled devices
- Show where administrative commands are being run on enrolled devices
- See who is using which machine
- In conjunction with threat reports, it is possible to query for the presence of an attacker in the form of Tools, Techniques and Procedures (TTPs)

## Disclaimer

**LME is currently still early in development, and as such we are marking it as [Alpha](https://www.gov.uk/service-manual/agile-delivery). The current release is version 0.4.**

***If you have an existing install of the LME Alpha (v0.3 or older) some manual intervention will be required in order to upgrade to the latest version, please see [Upgrading](/docs/upgrading.md) for further information.*** 

**This is not a professional tool, and should not be used as a [SIEM](https://en.wikipedia.org/wiki/Security_information_and_event_management).**

**LME is a 'homebrew' way of gathering logs and querying for attacks.**

We have done the hard work to make things simple. We will tell you what to download, which configurations to use and have created convenience scripts to auto-configure wherever possible.

The current architecture is based upon Windows Clients, Microsoft Sysmon, Windows Event Forwarding and the ELK stack.

We are **not** able to comment on or troubleshoot individual installations. If you believe you have have found an issue with the LME code or documentation please submit a [GitHub issue](https://github.com/ukncsc/lme/issues).

## Who is Logging Made Easy for?

From single IT administrators with a handful devices to look after, through to larger organisations.

LME is for you if:


*	You don’t have a [SOC](https://en.wikipedia.org/wiki/Information_security_operations_center), SIEM or any monitoring in place at the moment.
*	You lack the budget, time or understanding to set up your own logging system.
*	You recognise the need to begin gathering logs and monitoring your IT.
*	You understand that LME has limitations, and is better than nothing - but no match for a professional tool.

If any, or all, of these criteria fit, then LME is a step in the right direction for you.

LME could also be useful for:

*	Small isolated networks where corporate monitoring doesn’t reach.

## Who is the NCSC and why did they create LME?
The National Cyber Security Centre (NCSC) is a UK Government department with the mission of:

  **"Helping to make the UK the safest place to live and work online."**

..more can be found on www.ncsc.gov.uk.

We recognise the importance of gathering the right logs for security monitoring and post incident purposes, but we also recognise the pressures that face organisations. Budgets, deadlines and expertise. By producing LME we are attempting to reduce the barrier to entry for small organisations who don’t know where to start. LME may not be a fully-featured professional offering, but a step in the right direction that will make a difference in a cyber incident scenario.

Although in it’s infancy, we are hoping that LME will help organisations to make themselves more secure now and encourage better security monitoring in the future.

## Table of contents

[Prerequisites - Start deployment here](/docs/prerequisites.md)

[Chapter 1 - Set up Windows Event Forwarding](/docs/chapter1.md)

[Chapter 2 – Sysmon Install](/docs/chapter2.md)

[Chapter 3 – Database Install](/docs/chapter3.md)

[Chapter 4 - Post Install Actions ](/docs/chapter4.md)

[FAQ](/docs/faq.md)

[Troubleshooting](/docs/troubleshooting.md)

[Upgrading](/docs/upgrading.md)

## Credits
### Core Team
* Richard W, NCSC Project Lead.
* Adam B, NCSC Technical Lead.
* Martin W, NCSC Technical support / Customer Liaison.
* Jordan C, NCSC Visual Support.
* Michael H, NCSC Business Analyst.
* Rob B, NCSC Project Manager.
* Shane M, Previous NCSC Technical Lead.
* Lucy A, David L and Oli T, Cabinet Office Government Security Group, funding and project management.
* Duncan A, NCC Group, Lead Developer.
* Adam B, NCC Group, Developer.
* Harry G and Alfie T, NCSC, creating visualisations.

### Our development partners
These organisations spent time trialing earlier versions of LME which was critical to development and publication.
* Diane L at [Ofqual](http://ofqual.gov.uk)
* Gavin M at [Creative Scotland](https://www.creativescotland.com)
* Carol P and Andy M at [Renfrewshire Council](http://www.renfrewshire.gov.uk)
* Chris B and Andrew H at [Cardiff Council](http://www.cardiff.gov.uk)
* Julian D and the team at [Companies House](https://www.gov.uk/government/organisations/companies-house)
* Martin O at [TeamGB](https://www.teamgb.com/)
* The NCSC CAPRI team
* David C

### The Community
* Roberto Rodriguez ([@Cyb3rWard0g](https://twitter.com/Cyb3rWard0g) and [@THE_HELK](https://twitter.com/THE_HELK)) provided guidance and authored HELK (similar to LME but more featured) [HELK on Github](https://github.com/Cyb3rWard0g/HELK)
* Carl Morris sharing experiences behind his [44Con presentation](https://github.com/SecureDataLabs/44Con-2018-Sysmon)
* [SwiftOnSecurity](https://twitter.com/swiftonsecurity) and [Olaf Harton](https://twitter.com/olafhartong) for creating the open-source Sysmon configurations which we refer to.
* [Jessica Payne](https://twitter.com/jepaynemsft) acknowledging her "WEFFLES" blog highlighting what's possible with in-built Windows functionality.
* [Ryan Watson](https://twitter.com/gentlemanwatson) and [Syspanda](http://www.syspanda.com/) from which the Sysmon install script was adapted from.

### Technology Used
* [Sysmon](https://docs.microsoft.com/en-us/sysinternals/downloads/sysmon) and [Sigcheck](https://docs.microsoft.com/en-us/sysinternals/downloads/sigcheck) from the [Sysinternals team](https://docs.microsoft.com/en-us/sysinternals/) at Microsoft.
* Elasticsearch, Logstash, Kibana and Winlogbeat from [Elastic.co](https://elastic.co/) and their [github](https://github.com/elastic)
* [Docker Community Edition](https://github.com/docker/docker-ce)
