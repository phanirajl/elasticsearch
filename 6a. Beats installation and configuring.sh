##### Beats #####

# Download and install the public signing key
rpm --import https://packages.elastic.co/GPG-KEY-elasticsearch

# Create a repository
cd /etc/yum.repos.d/
vim elastic.repo

[elastic-6.x]
name=Elastic repository for 6.x packages
baseurl=https://artifacts.elastic.co/packages/6.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md

yum install -y filebeat

systemctl enable filebeat
systemctl start filebeat


# Configuration file
vim /etc/filebeat/filebeat.yml

filebeat.inputs:

- type: log
  enabled: true
  paths:
    - /var/log/mysql*.log
  #exclude_lines: ['^Debug', '^!user']
  include_lines: ['.user.']
  exclude_files: ['.gz$']

filebeat.config.modules:
  path: ${path.config}/modules.d/*.yml
  reload.enabled: false

setup.template.settings:
  index.number_of_shards: 3

setup.kibana:
  host: "130.117.79.118:5601"
output.logstash:
  hosts: ["130.117.79.119:5044"]

systemctl restart filebeat
tail -f /var/log/filebeat/filebeat
journalctl -f
