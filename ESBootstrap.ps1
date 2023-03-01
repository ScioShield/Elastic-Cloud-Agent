$version = "8.6.1"
$file = Get-Content ./endpoints.txt
$apiKey = Get-Content ./api_key.txt
$kibana  = $file | Select-String -Pattern 'kibana = (.*?)$' | ForEach-Object {$_.Matches.Groups[1].Value}
$elasticsearch = $file | Select-String -Pattern 'elasticsearch = (.*?)$' | ForEach-Object {$_.Matches.Groups[1].Value}
$fleet = $file | Select-String -Pattern 'fleet = (.*?)$' | ForEach-Object {$_.Matches.Groups[1].Value}
$downloadUrlWindowsAgent = "https://artifacts.elastic.co/downloads/beats/elastic-agent/elastic-agent-$version-windows-x86_64.zip"
$downloadUrlSysmon = "https://download.sysinternals.com/files/Sysmon.zip"
$downloadUrlGit = "https://github.com/git-for-windows/git/releases/download/v2.39.2.windows.1/Git-2.39.2-64-bit.exe"
$downloadOutputPath = "/tmp"
$archiveOutputPathSysmon = "/tmp/Sysmon"
$archiveOutputPathElasticAgent = "/tmp/Elastic-Agent"


while (-not (Test-Connection -Count 1 google.com -ErrorAction SilentlyContinue)) {
    Write-Host "Offline, still waiting..."
    Start-Sleep -Seconds 5
}
Write-Host "Online"

Invoke-WebRequest -UseBasicParsing -Uri $downloadUrlWindowsAgent -OutFile "$downloadOutputPath/elastic-agent-$version-windows-x86_64.zip"
Invoke-WebRequest -UseBasicParsing -Uri $downloadUrlSysmon -OutFile "$downloadOutputPath/Sysmon.zip"
Invoke-WebRequest -UseBasicParsing -Uri $downloadUrlGit -OutFile "$downloadOutputPath/Git-2.39.2-64-bit.exe"

# Change dest path to include a folder named the items

Expand-Archive /tmp/elastic-agent-8.6.1-windows-x86_64.zip -DestinationPath "$archiveOutputPathSysmon"
Expand-Archive /tmp/Sysmon.zip -DestinationPath "$archiveOutputPathElasticAgent"

#Invoke-RestMethod -UseBasicParsing -Method Get -uri "$kibana/api/fleet/agent_policies" -Headers @{"Accept" = "application/json"; "Authorization" = "ApiKey $apiKey"}
$fleetAgentPolicies = Invoke-RestMethod -UseBasicParsing -Method Get -uri "$kibana/api/fleet/agent_policies" -Headers @{"Accept" = "application/json"; "Authorization" = "ApiKey $apiKey"}
Write-Host $fleetAgentPolicies.items


# to be done last
#& "$archiveOutputPathElasticAgent\elastic-agent.exe" install -f --url=$fleet --enrollment-token=$(Get-Content C:\vagrant\WAEtoken.txt)
#& "$archiveOutputPathSysmon\Sysmon64.exe" -accepteula -i
