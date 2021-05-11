#!/bin/bash
if [ -r /opt/lme/lme.conf ]; then
  #reference this file as a source
  . /opt/lme/lme.conf
  #check if the version number is equal to the one we want
  if [ "$version" == "0.4" ]; then
    echo -e "\e[32m[X]\e[0m Updating from git repo"
    git -C /opt/lme/ pull
    #make sure the hostname variable is present
    echo -e "\e[32m[X]\e[0m Updating stored dashboard file"
    if [ -n "$hostname" ]; then
      cp /opt/lme/Chapter\ 4\ Files/dashboards.ndjson /opt/lme/Chapter\ 4\ Files/dashboards-live.ndjson
      sed -i "s/ChangeThisDomain/https:\/\/$hostname\\\/g" /opt/lme/Chapter\ 4\ Files/dashboards-live.ndjson
      echo -e "\e[32m[X]\e[0m Uploading the new dashboards to Kibana"
      curl -X POST -k --user dashboard_update:dashboardupdatepassword -H 'kbn-xsrf: true' --form file="@/opt/lme/Chapter 4 Files/dashboards-live.ndjson" "https://127.0.0.1/api/saved_objects/_import?overwrite=true"
    fi
  fi
fi
