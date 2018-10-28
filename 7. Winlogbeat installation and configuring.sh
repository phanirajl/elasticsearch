##### Winlogbeat installation and configuration #####

# Download Winlogbeat
https://www.elastic.co/downloads/beats/winlogbeat

# Create directory in C:\
New-Item -ItemType directory -Path 'C:\Program files\Winlogbeat'

# Install Winlogbeat
Set-Location -Path 'C:\Program files\Winlogbeat'
powershell -ExecutionPolicy UnRestricted -Exec bypass -File "C:\Program Files\Winlogbeat\install-service-winlogbeat.ps1"
Set-Service -Name "winlogbeat" -StartupType automatic
Start-Service -Name "winlogbeat"
Stop-Service -Name "winlogbeat"

Get-EventLog *
Get-WinEvent -ListLog * | Format-List -Property LogName
(Get-WinEvent -ListLog Security).ProviderNames

# Winlogbeat configuration

winlogbeat.event_logs:
  - name: Application
	provider:
      - Application Error
      - ...
    ignore_older: 8760h
    event_id: 4624, 4625, 4634, 4647, 1102, 4720, 4725, 4722, 4781, 4724, 4732, 4733, 4731, 4734 # if exclude: -4444
    processors:
      - drop_event.when.not.or:
        - equals.event_id: ...
        - equals.event_id: ...
        - equals.event_id: ...

  - name: Security
    ignore_older: 8760h
    # include_xml: true

setup.template.settings:
  index.number_of_shards: 3
  #index.codec: best_compression
  #_source.enabled: false

# The name of the shipper that publishes the network data. It can be used to group
# all the transactions sent by a single shipper in the web interface.
#name:

# The tags of the shipper are included in their own field with each
# transaction published.
#tags: ["service-X", "web-tier"]

fields:
  document_type: windows-security

setup.kibana:
  host: "130.117.79.118:5601"

output.logstash:
  hosts: ["130.117.79.119:5046"]

# Sets log level. The default log level is info.
# Available log levels are: error, warning, info, debug
#logging.level: debug

# At debug level, you can selectively enable logging only for some components.
# To enable all selectors use ["*"]. Examples of other selectors are "beat",
# "publish", "service".
#logging.selectors: ["*"]
