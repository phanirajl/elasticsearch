
##### Elasticsearch installation and configuration #####

# Create Elasticsearch repository
cd /etc/yum.repos.d/ 
vim elasticsearch.repo

[elasticsearch-6.x]
name=Elasticsearch repository for 6.x packages
baseurl=https://artifacts.elastic.co/packages/6.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md

# Install Java 8 and later
cd ~
wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/8u181-b13/96a7b8442fe848ef90c96a2fad6ed6d1/jdk-8u181-linux-x64.rpm"
yum localinstall jdk-8u181-linux-x64.rpm
java -version
export JAVA_HOME=/usr/java/jdk1.8.0_181-amd64
echo $JAVA_HOME
sh -c "echo export JAVA_HOME=/usr/java/jdk1.8.0_181-amd64 >> /etc/environment"

# Alternative way
yum install -y java
yum install -y java-1.8.0-openjdk
yum install -y java-1.8.0-openjdk-devel

# Import GPG key
rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch

yum install elasticsearch
systemctl daemon-reload
systemctl enable elasticsearch.service

# Specify system limits via systemd
systemctl edit elasticsearch

	[Service]
	LimitMEMLOCK=infinity
	LimitNPROC=4096			# Specifies the maximum number of processes
	LimitAS=infinity 		# Specifies the maximum size of virtual memory
	LimitFSIZE=infinity 	# Specifies the maximum file size
	TimeoutStopSec=0		# Disable timeout logic and wait until process is stopped
	KillSignal=SIGTERM		# SIGTERM signal is used to stop the Java process
	KillMode=process 		# Send the signal only to the JVM rather than its control group
	SendSIGKILL=no 			# Java process is never killed
	SuccessExitStatus=143 	# When a JVM receives a SIGTERM signal it exits with code 143
	LimitNOFILE=65536 		# Specifies the maximum file descriptor number that can be opened by this process

								[Unit]
								Description=Elasticsearch
								Documentation=http://www.elastic.co
								Wants=network-online.target
								After=network-online.target

								[Service]
								Environment=ES_HOME=/usr/share/elasticsearch
								Environment=CONF_DIR=/etc/elasticsearch
								Environment=DATA_DIR=/var/lib/elasticsearch
								Environment=LOG_DIR=/var/log/elasticsearch
								Environment=PID_DIR=/var/run/elasticsearch
								EnvironmentFile=-/etc/default/elasticsearch
								WorkingDirectory=/usr/share/elasticsearch
								User=elasticsearch
								Group=elasticsearch
								StandardOutput=journal
								StandardError=inherit
								
								[Install]
								WantedBy=multi-user.target

systemctl daemon-reload

	# Another way is to add a file /etc/systemd/system/elasticsearch.service.d/override.conf and add a line to it

	vim /etc/systemd/system/elasticsearch.service.d/override.conf

		[Service]
		LimitMEMLOCK=infinity
		...

	systemctl daemon-reload

# Start Elasticsearch
systemctl start elasticsearch.service

# Check logs
journalctl -f
journalctl --unit elasticsearch
journalctl --unit elasticsearch --since  "2016-10-30 18:17:16"

# Check if cluster running
curl -X GET "localhost:9200/"

# Enable bootstrap.memory_lock:
vim /etc/elasticsearch/elasticsearch.yml	# config/elasticsearch.yml

	bootstrap.memory_lock: true

# Check after starting
curl -X GET "localhost:9200/_nodes?filter_path=**.mlockall"

# Another possible reason why mlockall can fail is that the temporary directory (usually /tmp) is mounted with the noexec option. This can be solved by specifying a new temp directory using the ES_JAVA_OPTS environment variable:
export ES_JAVA_OPTS="$ES_JAVA_OPTS -Djava.io.tmpdir=/path/to/temp/dir"
systemctl restart elasticsearch

# Also check file descriptors if unlimited or setted to a maximum 65536
curl -X GET "localhost:9200/_nodes/stats/process?filter_path=**.max_file_descriptors"

# Configure system variables
vim /etc/elasticsearch/elasticsearch.yml

	network.host: 0.0.0.0
	cluster.name: "test"
	node.name: elk1 											# Or ${HOSTNAME}
	discovery.zen.ping.unicast.hosts: ["elk1", "elk2", "elk3"] 	# Or [192.168.238.139:9200, 192...] or [192.168.238.139, ...] (The port will default to transport.profiles.default.port and fallback to transport.tcp.port if not specified.) or FDQN
	bootstrap.memory_lock: true
	node.master: true
	node.data: true
	discovery.zen.minimum_master_nodes: 2 						# To avoid a split brain, this setting should be set to a quorum of master-eligible nodes: (master_eligible_nodes / 2) + 1
	path.data: /var/lib/elasticsearch/
	path.logs: /var/log/elasticsearch
	logger.org.elasticsearch.transport: trace 					# Only for temporarily debugging a problem but are not starting Elasticsearch via the command-line!
	index.number_of_shards: 2
	index.number_of_replicas: 2

# Copy to the next node in a cluster (run it on the node you want to copy to it!)
rsync -avz -e "ssh -p 2322" root@10.36.11.53:/etc/elasticsearch/elasticsearch.yml /etc/elasticsearch/elasticsearch.yml

# Another way to change logging is via cluster settings
curl -X PUT "localhost:9200/_cluster/settings" -H 'Content-Type: application/json' -d'
{
  "transient": {
    "logger.org.elasticsearch.transport": "trace"
  }
}
'

# Rebalancing process after adding a data node
curl -XPUT http://localhost:9200/_cluster/settings -d '{ "transient" : { "cluster.routing.allocation.enable" : "all" } }'

# Configuring a path for config files
export ES_PATH_CONF=/etc/elasticsearch /usr/share/elasticsearch/bin/elasticsearch-keystore create 	# ???
echo $ES_PATH_CONF

# Configureing JVM settings
vim /etc/elasticsearch/jvm.options

	-Xms8g 	
	-Xmx8g 						# Set Xmx to no more than 50% of your physical RAM
	-XX:HeapDumpPath=/... 			# JVM to dump the heap - set to a fixed file to prevent accumulating heap dump files, otherwise create cron to delete old dump files if you set a path to directory (default is /var/lib/elasticsearch)
	-XX:ErrorFile=/... 				# JVM error fatal logs if the default /var/log isn't suitable path

# Copy to the next node in a cluster (run it on the node you want to copy to it!)
rsync -avz -e "ssh -p 2322" root@10.36.11.53:/etc/elasticsearch/jvm.options /etc/elasticsearch/jvm.options

# Another way to set JVM heap size
ES_JAVA_OPTS="-Xms8g -Xmx8g" /usr/share/elasticsearch/bin/elasticsearch 
ES_JAVA_OPTS="-Xms8000m -Xmx8000m" /usr/share/elasticsearch/bin/elasticsearch

# Other settings are expert settings for Java programmers

# Security settings
/usr/share/elasticsearch/bin/elasticsearch-keystore create
/usr/share/elasticsearch/bin/elasticsearch-keystore list

# Logging configurations
vim /etc/elasticsearch/log4j2.properties

	appender.rolling.type = RollingFile 																								# Configure the RollingFile appender
	appender.rolling.name = rolling
	appender.rolling.fileName = ${sys:es.logs.base_path}${sys:file.separator}${sys:es.logs.cluster_name}.log 							# Log to /var/log/elasticsearch/production.log
	appender.rolling.layout.type = PatternLayout
	appender.rolling.layout.pattern = [%d{ISO8601}][%-5p][%-25c{1.}] %marker%.-10000m%n
	appender.rolling.filePattern = ${sys:es.logs.base_path}${sys:file.separator}${sys:es.logs.cluster_name}-%d{yyyy-MM-dd}-%i.log.gz 	# Roll logs to /var/log/elasticsearch/production-yyyy-MM-dd-i.log; logs will be compressed on each roll and i will be incremented
	appender.rolling.policies.type = Policies
	appender.rolling.policies.time.type = TimeBasedTriggeringPolicy 																	# Use a time-based roll policy
	appender.rolling.policies.time.interval = 1 																						# Roll logs on a daily basis 
	appender.rolling.policies.time.modulate = true 																						# Align rolls on the day boundary (as opposed to rolling every twenty-four hours)
	appender.rolling.policies.size.type = SizeBasedTriggeringPolicy																		# Using a size-based roll policy 
	appender.rolling.policies.size.size = 256MB 																						# Roll logs after 256 MB
	appender.rolling.strategy.type = DefaultRolloverStrategy
	appender.rolling.strategy.fileIndex = nomax
	appender.rolling.strategy.action.type = Delete 																						# Use a delete action when rolling logs
	appender.rolling.strategy.action.basepath = ${sys:es.logs.base_path}
	appender.rolling.strategy.action.condition.type = IfFileName 																		# Only delete logs matching a file pattern
	appender.rolling.strategy.action.condition.glob = ${sys:es.logs.cluster_name}-* 													# The pattern is to only delete the main logs
	appender.rolling.strategy.action.condition.nested_condition.type = IfAccumulatedFileSize 											# Only delete if we have accumulated too many compressed logs
	appender.rolling.strategy.action.condition.nested_condition.exceeds = 2GB 															# The size condition on the compressed logs is 2 GB

# If you want to retain log files for a specified period of time, you can use a rollover strategy with a delete action.

	appender.rolling.strategy.type = DefaultRolloverStrategy 								# Configure the DefaultRolloverStrategy
	appender.rolling.strategy.action.type = Delete 											# Configure the Delete action for handling rollovers
	appender.rolling.strategy.action.basepath = ${sys:es.logs.base_path} 					# The base path to the Elasticsearch logs
	appender.rolling.strategy.action.condition.type = IfFileName 							# The condition to apply when handling rollovers
	appender.rolling.strategy.action.condition.glob = ${sys:es.logs.cluster_name}-* 		# Delete files from the base path matching the glob ${sys:es.logs.cluster_name}-*; this is the glob that log files are rolled to; this is needed to only delete the rolled Elasticsearch logs but not also delete the deprecation and slow logs
	appender.rolling.strategy.action.condition.nested_condition.type = IfLastModified 		# A nested condition to apply to files matching the glob
	appender.rolling.strategy.action.condition.nested_condition.age = 7D 					# Retain logs for seven days

# Copy to the next node in a cluster (run it on the node you want to copy to it!)
rsync -avz -e "ssh -p 2322" root@10.36.11.53:/etc/elasticsearch/log4j2.properties /etc/elasticsearch/log4j2.properties

# Check cluster health
curl -XGET localhost:9200/_cluster/health?pretty

# Clear all indexes
curl -XDELETE 'http://localhost:9200/_all'