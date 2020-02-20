$version_major = "2019"
$version_minor = "3"
$version_x = "1"
$url = "https://downloads.tableau.com/esdalt/"+$version_major+"."+$version_minor+"."+$version_x+"/TableauServer-64bit-"+$version_major+"-"+$version_minor+"-"+$version_x+".exe"
$output = "$PSScriptRoot\tableau_server.exe"
$start_time = Get-Date

Invoke-WebRequest -Uri $url -OutFile $output
Write-Output "Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"


