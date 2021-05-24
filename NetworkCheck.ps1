
$maxpacketloss = 2 
$MinimumDownloadSpeed = 60 
$MinimumUploadSpeed = 7 


$DownloadLocation = "C:\admin\commands"

$PreviousResults = if (test-path "$($DownloadLocation)\LastResults.txt") { get-content "$($DownloadLocation)\LastResults.txt" | ConvertFrom-Json }
$SpeedtestResults = & "$($DownloadLocation)\speedtest.exe" --format=json --accept-license --accept-gdpr
$SpeedtestResults | Out-File "$($DownloadLocation)\LastResults.txt" -Force
$SpeedtestResults = $SpeedtestResults | ConvertFrom-Json
$OUT = $SpeedtestResults | ConvertTo-Html



[PSCustomObject]$SpeedtestObj = @{
    downloadspeed = [math]::Round($SpeedtestResults.download.bandwidth / 1000000 * 8, 2)
    uploadspeed   = [math]::Round($SpeedtestResults.upload.bandwidth / 1000000 * 8, 2)
    packetloss    = [math]::Round($SpeedtestResults.packetLoss)
    isp           = $SpeedtestResults.isp
    ExternalIP    = $SpeedtestResults.interface.externalIp
    InternalIP    = $SpeedtestResults.interface.internalIp
    UsedServer    = $SpeedtestResults.server.host
    ResultsURL    = $SpeedtestResults.result.url
    Jitter        = [math]::Round($SpeedtestResults.ping.jitter)
    Latency       = [math]::Round($SpeedtestResults.ping.latency)
}
$SpeedtestHealth = @()
#Comparing against previous result. Alerting is download or upload differs more than 20%.
if ($PreviousResults) {
    if ($PreviousResults.download.bandwidth / $SpeedtestResults.download.bandwidth * 100 -le 80) { $SpeedtestHealth += "Download speed difference is more than 20%" }
    if ($PreviousResults.upload.bandwidth / $SpeedtestResults.upload.bandwidth * 100 -le 80) { $SpeedtestHealth += "Upload speed difference is more than 20%" }
}

#Comparing against preset variables.
if ($SpeedtestObj.downloadspeed -lt $MinimumDownloadSpeed) { $SpeedtestHealth += "Download speed is lower than $MinimumDownloadSpeed Mbit/ps" }
if ($SpeedtestObj.uploadspeed -lt $MinimumUploadSpeed) { $SpeedtestHealth += "Upload speed is lower than $MinimumUploadSpeed Mbit/ps" }
if ($SpeedtestObj.packetloss -gt $MaxPacketLoss) { $SpeedtestHealth += "Packetloss is higher than $maxpacketloss%" }

if (!$SpeedtestHealth) {
    $SpeedtestHealth = "Healthy"
}

$SpeedtestHealth
#$OUT 
$dl= $SpeedtestObj.downloadspeed 
$ul = $SpeedtestObj.uploadspeed
"Upload Speed: "+$dl
"Download Speed: "+$ul