##### Logstash configuration file for MySQL audit logs #####

input {
  beats {
    port => 5044
    host => "0.0.0.0"
  }
}

filter {
  if [fileset][module] == "mysql" {
    if [fileset][name] == "audit" {
      grok {
        match => { "message" => ["^%{YEAR:year}%{MONTHNUM:month}%{MONTHDAY:day} %{TIME:time},%{GREEDYDATA:host},%{GREEDYDATA:username},
                                  %{GREEDYDATA:client_hostname},%{INT:connection_id},%{INT:query_id},%{GREEDYDATA:operation},%{GREEDYDATA:schema},%{GREEDYDATA:object},%{INT:return_code}"] }
        pattern_definitions => {
          "LOCALDATETIME" => "[0-9]+ %{TIME}"
        }
        remove_field => "message"
      }
    }
  }
}

output {
  elasticsearch {
    sniffing => true
    hosts => ["uk1lv8702:9200", "uk1lv8703:9200", "uk1lv8704:9200"]
    index => "mysql-%{+YYYY.MM.dd}" # days index
    manage_template => false
    #index => "%{[@metadata][beat]}-%{+YYYY.MM.dd}"
  }
}

# http://www.youdidwhatwithtsql.com/grok-expression-mariadb-audit-log/2053/