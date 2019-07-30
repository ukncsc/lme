#!/bin/bash
wget https://raw.githubusercontent.com/ukncsc/lme/master/Chapter%204%20Files/status.json
curl -X POST --cacert certs/root-ca.crt --user elastic:dashboardupdatepassword -H "Content-Type: application/json" -H 'kbn-xsrf: true' --data @status.json "https://127.0.0.1:5601/api/kibana/dashboards/import?exclude=index-pattern"
