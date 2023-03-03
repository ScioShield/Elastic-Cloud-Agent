$version = "8.6.2"
$vagrantDirectory = "C:\vagrant"
$file = Get-Content "$vagrantDirectory\endpoints.txt"
$apiKey = Get-Content "$vagrantDirectory\api_key.txt"
$kibana  = $file | Select-String -Pattern 'kibana = (.*?)$' | ForEach-Object {$_.Matches.Groups[1].Value}
$elasticsearch = $file | Select-String -Pattern 'elasticsearch = (.*?)$' | ForEach-Object {$_.Matches.Groups[1].Value}
$fleet = $file | Select-String -Pattern 'fleet = (.*?)$' | ForEach-Object {$_.Matches.Groups[1].Value}
$downloadUrlWindowsAgent = "https://artifacts.elastic.co/downloads/beats/elastic-agent/elastic-agent-$version-windows-x86_64.zip"
$downloadUrlSysmon = "https://download.sysinternals.com/files/Sysmon.zip"
$downloadUrlGit = "https://github.com/git-for-windows/git/releases/download/v2.39.2.windows.1/Git-2.39.2-64-bit.exe"
$downloadOutputPath = $vagrantDirectory
$archiveOutputPathSysmon = "C:\Program Files\Sysmon"
$archiveOutputPathElasticAgent = "C:\Program Files\Elastic-Agent"


while (-not (Test-Connection -Count 1 google.com -ErrorAction SilentlyContinue)) {
    Write-Host "Offline, still waiting..."
    Start-Sleep -Seconds 5
}
Write-Host "Online"

$global:ProgressPreference = 'SilentlyContinue'
Invoke-WebRequest -UseBasicParsing -Uri $downloadUrlWindowsAgent -OutFile "$downloadOutputPath\elastic-agent-$version-windows-x86_64.zip"
Invoke-WebRequest -UseBasicParsing -Uri $downloadUrlSysmon -OutFile "$downloadOutputPath\Sysmon.zip"
Invoke-WebRequest -UseBasicParsing -Uri $downloadUrlGit -OutFile "$downloadOutputPath\Git-2.39.2-64-bit.exe"

# Change dest path to include a folder named the items

Expand-Archive "$downloadOutputPath\elastic-agent-$version-windows-x86_64.zip" -DestinationPath "$archiveOutputPathElasticAgent"
Expand-Archive "$downloadOutputPath\Sysmon.zip" -DestinationPath "$archiveOutputPathSysmon"

$header = @{
    "Accept" = "application/json"
    "Authorization" = "ApiKey $apiKey"
    "Cache-Control" = "no-cache"
    "kbn-xsrf" = "reporting"
    } 

$fleetAgentPolicies = Invoke-RestMethod -UseBasicParsing -Method Get -uri "$kibana/api/fleet/agent_policies" -Headers $header


# Add Windwows Policy
function Send-KibanaRequestWindowsPolicy {
    $json = Get-Content "$vagrantDirectory\windowsPolicy.json" -Raw
    
    Invoke-RestMethod -Uri "$kibana/api/fleet/agent_policies?sys_monitoring=true" `
      -OutFile "$vagrantDirectory\windowsPolicyId.txt" `
      -UseBasicParsing `
      -Method Post `
      -ContentType "application/json" `
      -Headers $header `
      -Body $json
}
Send-KibanaRequestWindowsPolicy

# Add Linux Policy

function Send-KibanaRequestLinuxPolicy {
    $json = Get-Content "$vagrantDirectory\linuxPolicy.json"
    
    Invoke-RestMethod -Uri "$kibana/api/fleet/agent_policies?sys_monitoring=true" `
      -OutFile "$vagrantDirectory\linuxPolicyId.txt" `
      -UseBasicParsing `
      -Method Post `
      -ContentType "application/json" `
      -Headers $header `
      -Body $json
}
Send-KibanaRequestLinuxPolicy

function Send-KibanaRequestWindowsIntegration {
    $obj = Get-Content "$vagrantDirectory\windowsPolicyId.txt" | ConvertFrom-Json
    $json = (Get-Content "$vagrantDirectory\windowsIntegration.json").replace('varWindowsPolicyId',$obj.item.id)
    
    Invoke-RestMethod -Uri "$kibana/api/fleet/package_policies" `
      -OutFile "$vagrantDirectory\windowsIntegration.txt" `
      -UseBasicParsing `
      -Method Post `
      -ContentType "application/json" `
      -Headers $header `
      -Body $json
}
Send-KibanaRequestWindowsIntegration

function Send-KibanaRequestWindowsDefenderIntegration {
    $obj = Get-Content "$vagrantDirectory\windowsPolicyId.txt" | ConvertFrom-Json
    $json = (get-content "$vagrantDirectory\windowsIntegrationDefender.json").replace('varWindowsPolicyId',$obj.item.id)
    
    Invoke-RestMethod -Uri "$kibana/api/fleet/package_policies" `
      -OutFile "$vagrantDirectory\windowsIntegrationDefender.txt" `
      -UseBasicParsing `
      -Method Post `
      -ContentType "application/json" `
      -Headers $header `
      -Body $json
}
Send-KibanaRequestWindowsDefenderIntegration

function Send-KibanaRequestLinuxIntegration {
    $obj = Get-Content "$vagrantDirectory\linuxPolicyId.txt" | ConvertFrom-Json
    $json = (Get-Content "$vagrantDirectory\linuxIntegration.json").replace('varLinuxPolicyId',$obj.item.id)
    
    Invoke-RestMethod -Uri "$kibana/api/fleet/package_policies" `
      -OutFile "$vagrantDirectory\linuxIntegration.txt" `
      -UseBasicParsing `
      -Method Post `
      -ContentType "application/json" `
      -Headers $header `
      -Body $json
}
Send-KibanaRequestLinuxIntegration

# Get the Intigration keys for both Linux and Windows
$fleetAgentEnrollmentApiKeys = Invoke-RestMethod -UseBasicParsing -Method Get -uri "$kibana/api/fleet/enrollment_api_keys" -Headers $header

# Get the policy details 
$windowsPolicy = Get-Content "$vagrantDirectory\windowsPolicyId.txt" | ConvertFrom-Json
$linuxPolicy = Get-Content "$vagrantDirectory\linuxPolicyId.txt" | ConvertFrom-Json


function Get-WindowsEnrollmentToken {
  $agentEnrollmentApiKeys = $fleetAgentEnrollmentApiKeys.items
  $windowsObject = Get-Content "$vagrantDirectory\windowsPolicyId.txt" | ConvertFrom-Json
  $windowsId = $windowsObject.item.id
  $windowsEnrollmentToken = $agentEnrollmentApiKeys | Where-Object {$_ -like "*$windowsId*" }
  Write-Output $windowsEnrollmentToken.api_key
}

$windowsToken = Get-WindowsEnrollmentToken
# to be done last
& "$archiveOutputPathElasticAgent\elastic-agent-$version-windows-x86_64\elastic-agent.exe" install -f --url=$fleet --enrollment-token=$windowsToken
& "$archiveOutputPathSysmon\Sysmon64.exe" -accepteula -i
