param   (
            [Parameter(Mandatory=$true)]  [String]$LicenseKey, 
            [Parameter(Mandatory=$false)] [String]$Version,
            [Parameter(Mandatory=$false)] [String]$Bootstrap=$false,
            [Parameter(Mandatory=$false)] [String]$Help 
)

function func_Version ($Version) {
   
    if(!$Version)
    {
        Write-Host "-Version is missing a value. It should be in the format xxxx.x.x like for example 2019.1.4 or type Trial to active a 14 day trial"
    }
    elseif($version.ToString().Length -ne 8)
    {
        Write-Host "-Version is in the wrong format. It should be in the format xxxx.x.x like for example 2019.1.4"
        
    }

    elseif($version.ToString().Length -eq 8)
            {
            if ($version -like '*.*')
            {
                $major = $version.substring(0,4)
                $minor = $version.substring(0,$version.lastindexof('.')).substring(5)
                $hotfix = $version.substring($version.length-1)
                
            }
            elseif ($version -like '*-*')
            {
                $version = $version.ToString().replace('-','.') 
                $major = $version.substring(0,4)
                $minor = $version.substring(0,$version.lastindexof('.')).substring(5)
                $hotfix = $version.substring($version.length-1)
                
            }
        }
        return $major, $minor, $hotfix
}

function func_Variables()
                            {
                                $github_url = "https://raw.githubusercontent.com/AndrijaMa/Test/master/"
                                $folder = "C:\Downloads\"
                                $reg_file = "reginfo.json"
                                $iDP_config = "iDP_config.json"
                                $log_file = "install.log"
                                $event_file = "event.log"
                                $bootstrapfile = "bootstrapfile.json"
                                return $github_url, $folder, $reg_file, $iDP_config, $log_file, $event_file, $bootstrapfile                           
}
func_Variables

function Write-ToLog ($text) {
    
    $message = "[{0:yyyy/MM/dd/} {0:HH:mm:ss}]" -f (Get-Date) +", "+ $text 
    Write-Host  $message
    Write-Output $message | Out-file $folder$event_file -Append -Encoding default

}

function func_Install(
                    $github_url, 
                    $folder, 
                    $reg_file, 
                    $iDP_config, 
                    $log_file, 
                    $event_file,
                    $version_major, 
                    $version_minor, 
                    $version_hotfix, 
                    $LicenseKey
                ){
    
                        try {
                                #Set the path  to the server version of Tableau that you want to download
                                $url = "https://downloads.tableau.com/esdalt/"+$version_major+"."+$version_minor+"."+$version_hotfix+"/TableauServer-64bit-"+$version_major+"-"+$version_minor+"-"+$version_hotfix+".exe"

                                #Create Download folder if it does not exist
                                (![System.IO.File]::Exists($Folder))
                                    {
                                        
                                        New-Item -Path $Folder -ItemType Directory
                                    }

                                #Download the server installation file
                                Write-ToLog -text "Starting Tableau Server installation media download..." 
                                Invoke-WebRequest -Uri $url -OutFile $folder"tableau_server.exe"
                                Write-ToLog -text "Finnished Tableau Server installation media download"

                                #Download reg_file
                                Write-ToLog -text  "Downloading reg file"
                                Invoke-WebRequest -Uri $github_url$reg_file -OutFile $folder$reg_file
                                Write-ToLog -text "Download of regfile completed successfully"
                                
                                #Download iDP file
                                Write-ToLog -text  "Downloading iDP config file"
                                Invoke-WebRequest -Uri $github_url$iDP_config -OutFile $folder$iDP_config
                                Write-ToLog -text "Download of iDP config file completed successfully"

                                #Install Switches and Properties for Tableau Server
                                #https://help.tableau.com/current/server/en-us/silent_installer_flags.htm
                                #Start silent Tableau server installation
                                Write-ToLog -text  "Starting Tableau Server installation"
                                Start-Process -FilePath $folder"tableau_server.exe" -ArgumentList "/install /silent /ACCEPTEULA = 1 /LOG '$folder$log_file'" -Verb RunAs -Wait
                                Write-ToLog -text  "Tableau Server installation completed successfully"

                                #Identifying path to TSM
                                #Get-ItemProperty -Path HKLM:\SOFTWARE\Tableau $version_full*
                                Write-ToLog -text "Adding TSM to local Windows system PATH"
                                $wd =  'C:\Program Files\Tableau\Tableau Server\packages\'
                                $tsm_path = Get-ChildItem $wd\bin.$version_major$version_minor.$version_hotfix* -Directory | Select-Object -Property name  
                                $tsm_path = $wd+$tsm_path.Name
                                #Add TSM to Windows Path
                                $Env:path += $tsm_path

                                #Activate Tableau Server license
                                Write-ToLog -text  "Registering Tableau Server License"
                                if($LicenseKey -eq '')
                                {
                                    Write-Host "-LicenseKey was empty! Please enter your license key or type Trial to activeate a 14 day trial key."
                                }
                                elseif($LicenseKey.ToLower() -eq "trial")
                                {
                                    Write-ToLog -text "Staring Tableau Server Trial activation"
                                    Invoke-Expression "tsm licenses activate -t"
                                    Write-ToLog -text "Completed Tableau Server Trial activation"
                                }
                                else 
                                {
                                    Write-ToLog -text "Staring Tableau Server activation"
                                    Invoke-Expression "tsm licenses activate -k '$LicenseKey'"
                                    Write-ToLog -text "Completed Tableau Server activation"
                                }
                                
                                #Register Tableau Server
                                Write-ToLog -text "Starting Tableau Server registration"
                                Invoke-Expression "tsm register --file '$Folder$reg_file'"
                                Write-ToLog -text "Completed Tableau Server registration"

                                #Set local repository
                                Write-ToLog -text "Starting Tableau Server local Repository setup"
                                Invoke-Expression "tsm settings import -f '$Folder$iDP_config'"
                                Write-ToLog -text "Completed Tableau Server local Repository setup"

                                #Apply pending changes
                                Write-ToLog -text "Applying pending TSM changes"
                                Invoke-Expression "tsm pending-changes apply"
                                Write-ToLog -text "TSM changes applied successfully."

                                #Initialize configuration
                                Write-ToLog -text "Initializing Tableau Server"
                                Invoke-Expression "tsm initialize"
                                Write-ToLog -text "Tableau Server initialized"

                                #Initialize configuration
                                Write-ToLog -text "Starting Tableau Server"
                                Invoke-Expression "tsm start"
                                Write-ToLog -text "Tableau Server started"

                                #Generate bootstrap file
                                if($Bootstrap -eq $true)
                                {
                                    Invoke-Expression "tsm topology nodes get-bootstrap-file --file '$folder$bootstrapfile'"
                                }
                        }
                        catch
                            {
                                Write-ToLog -text $PSItem.Exception.Message
                            }
}
func_Variables
func_Version -Version $Version
func_Install -github_url $github_url -folder $folder -reg_file $reg_file -iDP_config $iDP_config -log_file $log_file -event_file $event_file -version_major $major -version_minor $minor -version_hotfix $hotfix