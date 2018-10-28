
##### Logstash #####

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

# Create repository
cd /etc/yum.repos.d/
vim logstash.repo

	[logstash-6.x]
	name=Elastic repository for 6.x packages
	baseurl=https://artifacts.elastic.co/packages/6.x/yum
	gpgcheck=1
	gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
	enabled=1
	autorefresh=1
	type=rpm-md

# Download and install the public signing key:
rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch

yum install -y logstash

systemctl start logstash.service
systemctl enable logstash.service

# Check your installation
/usr/share/logstash/bin/logstash -e 'input { stdin { } } output { stdout {} }'

# Configureing JVM settings
vim /etc/logstash/jvm.options

	-Xms4g 	
	-Xmx4g 						# Set Xmx to no more than 50% of your physical RAM
	-XX:HeapDumpPath=/... 			# JVM to dump the heap - set to a fixed file to prevent accumulating heap dump files, otherwise create cron to delete old dump files if you set a path to directory (default is /var/lib/elasticsearch)
	-XX:ErrorFile=/... 				# JVM error fatal logs if the default /var/log isn't suitable path

# Another way to set JVM heap size
ES_JAVA_OPTS="-Xms4g -Xmx4g" /usr/share/logstash/bin/logstash 
ES_JAVA_OPTS="-Xms4000m -Xmx4000m" /usr/share/logstash/bin/logstash

vim /etc/logstash/logstash.yml

	node.name: uk1lv8706
	path.data: /var/lib/logstash
	pipeline.workers: 4				# Number pof CPU's
	pipeline.unsafe_shutdown: false
	log.level: info
	path.logs: /var/log/logstash
	config.reload.automatic: true
	config.reload.interval: 10s
	slowlog.threshold.warn: 2s
	slowlog.threshold.info: 1s
	slowlog.threshold.debug: 500ms
	slowlog.threshold.trace: 100ms

systemctl logstash configtest
ss -tuna4 | grep 5044

# For each stream in pipeline you need to allocate a different port