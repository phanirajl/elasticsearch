##### Filebeats #####

# Download a zip folder
https://www.elastic.co/downloads/beats/filebeat

# Create directory in C:\
New-Item -ItemType directory -Path 'C:\Program files\Filebeat'

# Extract file from a zip fiel and place to the new directory

# Open a PowerShell prompt as an Administrator (right-click the PowerShell icon and select Run As Administrator).
Set-Location -Path 'C:\Program files\Filebeat'
powershell -ExecutionPolicy UnRestricted -Exec bypass -File "C:\Program Files\Filebeat\install-service-filebeat.ps1"
Set-Service -Name "filebeat" -StartupType automatic
Start-Service -Name "filebeat"
Stop-Service -Name "filebeat"

# Configuration file
C:\Program files\Filebeat\filebeat.yaml

filebeat.inputs:

- type: log
  enabled: true
  paths:
    - C:\Program Files (x86)\FileZilla Server\Logs\*
  fields:
    document_type: windows-filezilla

filebeat.config.modules:
  path: ${path.config}/modules.d/*.yml
  reload.enabled: false

setup.template.settings:
  index.number_of_shards: 3

setup.kibana:
  host: "130.117.79.118:5601"

output.logstash:
  hosts: ["130.117.79.119:5047"]
