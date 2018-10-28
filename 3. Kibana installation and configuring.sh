
##### Kibana #####

# Create repository
cd /etc/yum.repos.d/
vim kibana.repo

	[kibana-6.x]
	name=Kibana repository for 6.x packages
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

# Download and install the public signing key
rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch

yum install -y kibana

systemctl daemon-reload
systemctl enable kibana.service
systemctl start kibana.service

# Accessing Kibana
http://192.168.238.143:5601/status
http://192.168.238.143:5601
http://192.168.238.143:5601/api/status

# Secure settings
/usr/share/kibana/bin/kibana-keystore create
/usr/share/kibana/bin/kibana-keystore list

# Configuring Kibana
vim /etc/kibana/kibana.yml

	server.host: 0.0.0.0 #"localhost"
	server.name: "kibana1"
	elasticsearch.url: "http://192.168.238.139:9200"

# Configureing JVM settings
vim /etc/kibana/jvm.options

	-Xms2g 	
	-Xmx2g 						# Set Xmx to no more than 50% of your physical RAM
	-XX:HeapDumpPath=/... 			# JVM to dump the heap - set to a fixed file to prevent accumulating heap dump files, otherwise create cron to delete old dump files if you set a path to directory (default is /var/lib/elasticsearch)
	-XX:ErrorFile=/... 				# JVM error fatal logs if the default /var/log isn't suitable path

# Another way to set JVM heap size
ES_JAVA_OPTS="-Xms2g -Xmx2g" /usr/share/kibana/bin/kibana 
ES_JAVA_OPTS="-Xms2000m -Xmx2000m" /usr/share/kibana/bin/kibana
# Encrypting communication with SSL

...

##### Load balancing across multiple Elasticsearch nodes #####

# Important note!
# Requests like search requests or bulk-indexing requests may involve data held on different data nodes. 
# A search request, for example, is executed in two phases which are coordinated by the node which receives the client request — the coordinating node.
# In the scatter phase, the coordinating node forwards the request to the data nodes which hold the data. 
# Each data node executes the request locally and returns its results to the coordinating node. In the gather phase, the coordinating node reduces each data node’s results into a single global resultset.
# Every node is implicitly a coordinating node. This means that a node that has all three node.master, node.data and node.ingest set to false will only act as a coordinating node, which cannot be disabled. 
# As a result, such a node needs to have enough memory and CPU in order to deal with the gather phase.

# If you have multiple nodes in your Elasticsearch cluster, the easiest way to distribute Kibana requests across the nodes is to run an Elasticsearch Coordinating only node on the same machine as Kibana. 
# Elasticsearch Coordinating only nodes are essentially smart load balancers that are part of the cluster. 
# They process incoming HTTP requests, redirect operations to the other nodes in the cluster as needed, and gather and return the results. For more information, see Node in the Elasticsearch reference.
# To use a local client node to load balance Kibana requests:

# Install Elasticsearch on the same machine as Kibana
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

# Import GPG key
rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch

yum install elasticsearch
systemctl daemon-reload
systemctl enable elasticsearch.service

# Configure the node as a Coordinating only node: in elasticsearch.yml, set node.data, node.master and node.ingest to false:
# You want this node to be neither master nor data node nor ingest node, but to act as a "search load balancer" (fetching data from nodes, aggregating results, etc.)

	node.master: false
	node.data: false
	node.ingest: false
	search.remote.connect: false
	cluster.name: "test" 			# Configure the client node to join your Elasticsearch cluster. In elasticsearch.yml, set the cluster.name to the name of your cluster.
	network.host: localhost 		# Check your transport and HTTP host configs in elasticsearch.yml under network.host and transport.host. The transport.host needs to be on the network reachable to the cluster members, the network.host is the network for the HTTP connection for Kibana (localhost:9200 by default).
	http.port: 9200
	transport.host: <external ip>	# By default transport.host refers to network.host
	transport.tcp.port: 9300 - 9400

systemctl start elasticsearch.service

# Make sure Kibana is configured to point to your local client node: in kibana.yml, the elasticsearch.url should be set to localhost:9200.
vim /etc/kibana/kibana.yml

	elasticsearch.url: "http://localhost:9200"

