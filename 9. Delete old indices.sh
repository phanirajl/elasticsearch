##### Delete old indices #####

rpm --import https://packages.elastic.co/GPG-KEY-elasticsearch

cd /etc/yun.repos.d/
vim curator.repo

	[curator-5]
	name=CentOS/RHEL 7 repository for Elasticsearch Curator 5.x packages
	baseurl=https://packages.elastic.co/curator/5/centos/7
	gpgcheck=1
	gpgkey=https://packages.elastic.co/GPG-KEY-elasticsearch
	enabled=1

yum -y install elasticsearch-curator

touch /var/log/curator.log

vim /opt/elasticsearch-curator/curator.yml
	
	---
	client:
	  hosts:
	    - 127.0.0.1
	  port: 9200
	#  url_prefix:
	  use_ssl: False
	#  certificate:
	#  client_cert:
	#  client_key:
	  ssl_no_validate: False
	#  http_auth:
	  timeout: 30
	  master_only: False

	logging:
	  loglevel: INFO
	  logfile: /var/log/curator.log
	  logformat: default
	  blacklist: ['elasticsearch', 'urllib3']

vim /opt/elasticsearch-curator/action_file.yml
	
	---
	actions:
	  1:
	    action: delete_indices
	    description: >-
		  Delete indices older than 365 days (based on index name), for pci-logs-
		  prefixed indices. Ignore the error if the filter does not result in an
		  actionable list of indices (ignore_empty_list) and exit cleanly.
        options:
          ignore_empty_list: True
          # disable_action: True
	    filters:
	      - filtertype: pattern
	        kind: prefix
	        value: pci-logs-
	        exclude:
	      - filtertype: age
	        source: name
	        timestring: '%Y.%m'
	        unit: days
	        unit_count: 7
	        direction: older

which curator
# /usr/bin/curator

which curator_cli
# /usr/bin/curator_cli

crontab -e

# Add the following line to run curator at 20 minutes past midnight (system time) and connect to the elasticsearch node on 127.0.0.1 
# and delete all indexes older than 365 days and close all indexes older than 90 days.

0 6 * * * /usr/bin/curator --config /opt/elasticsearch-curator/curator.yml /opt/elasticsearch-curator/action_file.yml

# 20 0 * * * /usr/bin/curator_cli show_indices --filter_list '{"filtertype":"age","source":"name","timestring":"pci-logs-%Y.%m","unit":"days","unit_count":30}'


curator_cli --host 127.0.0.1 show_indices