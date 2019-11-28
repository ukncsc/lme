#!/bin/bash
wget https://raw.githubusercontent.com/ukncsc/lme/master/Chapter%204%20Files/dashboards%20v0.2.0.json -O status.json
curl -X POST -k --cacert "/opt/lme/Chapter 3 Files/certs/root-ca.crt" --user elastic:dashboardupdatepassword -H "Content-Type: application/json" -H 'kbn-xsrf: true' --data @status.json "https://127.0.0.1/api/kibana/dashboards/import"
