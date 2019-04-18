#set future index to always have no replicas
curl -X PUT "localhost:9200/_template/number_of_replicas" -H 'Content-Type: application/json' -d' {  "template": "*",  "settings": {    "number_of_replicas": 0  }}'

#set all current indices to have 0 replicas
curl -X PUT "localhost:9200/_all/_settings" -H 'Content-Type: application/json' -d '{"index" : {"number_of_replicas" : 0}}'
