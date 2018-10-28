
##### System preparation #####

lsblk

# Disk information
file -s /dev/xvdb
fdisk -l

# Create new partiion
fdisk /dev/xvdb 

# n -create a new partition
# p - choose primary partition (or e - extended)
# [1-4] - choose partition number
# 2048 - set start block
# 22... - set and block or size +200GB
# w - save changes or q - quit without saving

# Format the new partition
mkfs -t ext4  /dev/xvdb1
mkfs.ext4 /dev/xvdb1

# Create a new directory
mkdir /hdfs

# Mount a nre directory to the new created partition
mount /dev/xvdb /hdfs

# Check the new mount
df -Th

# Check the partition UUID
blkid | grep xvdb

# Write UUID to the fstab in order to allow automatic mount at the boot
vim /etc/fstab

# UUID=ea0e300d-8b98-4409-bd1d-d5305688e51c /hdfs                   ext4    defaults,noatime 1 2

# Install additional software
yum update -y
yum install -y epel-release
yum install -y mlocate ncdu htop rsync vim wget

# Disable transparent huge pages
vim /etc/rc.d/rc.local

	echo never > /sys/kernel/mm/transparent_hugepage/enabled
	echo never > /sys/kernel/mm/transparent_hugepage/defrag

chmod 777 /etc/rc.d/rc.local
reboot

cat /sys/kernel/mm/transparent_hugepage/enabled
cat /sys/kernel/mm/transparent_hugepage/defrag

# Limit open files
vim /etc/security/limits.conf

	elasticsearch    -      nofile           65536
	elasticsearch    -      nproc            4096
	elasticsearch    -      as               unlimited
	root             -      as               unlimited
	elasticsearch    -      fsize            unlimited
	root             -      fsize            unlimited

# Disable swap or configure swappiness
vim /etc/fstab
# Comment a line with thw word swap

vim /etc/sysctl.conf

	vm.swappiness = 1
	vm.max_map_count = 262144
	#net.ipv6.conf.all.disable_ipv6 = 1
	#net.ipv6.conf.default.disable_ipv6 = 1

# Verify after reboot
sysctl vm.max_map_count
sysctl vm.swappiness

# Disable SELINUX
setenforce 0 
vim /etc/selinux/config 

	SELINUX=disabled

# Disable firewall
sudo systemctl status firewalld
sudo systemctl stop firewalld
sudo systemctl disable firewalld

# Hostnames
vim /etc/hosts

10.0.0.1	elk1
10.0.0.1	elk2
10.0.0.1	elk3