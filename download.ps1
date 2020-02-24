$version_major = "2019"
$version_minor = "3"
$version_x = "1"
$folder = "C:\Downloads\"
$url = "https://downloads.tableau.com/esdalt/"+$version_major+"."+$version_minor+"."+$version_x+"/TableauServer-64bit-"+$version_major+"-"+$version_minor+"-"+$version_x+".exe"
$output = $Folder+"tableau_server.exe"
$start_time = Get-Date

New-Item -Path $Folder -ItemType Directory
#Download file
Invoke-WebRequest -Uri $url -OutFile $output
Write-Output "Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"


