# This script installs the windows puppet agent on windows 
# from the master's pe_repo by downloading it to C:\tmp first and then running
# msiexec on it from there.

$msi_source = "https://downloads.puppetlabs.com/windows/puppet5/puppet-agent-x64-latest.msi"
$msi_dest = "C:\tmp\puppet-agent-x64-latest.msi"

# Start the agent installation process and wait for it to end before continuing.
Write-Host "Installing puppet agent from $msi_source"

# Determine system hostname and primary DNS suffix to determine certname
$objIPProperties = [System.Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties()
$name_components = @($objIPProperties.HostName, $objIPProperties.DomainName) | ? {$_}
$certname = $name_components -Join "."

Function Get-WebPage { Param( $url, $file, [switch]$force)
  if($force) { 
    [Net.ServicePointManager]::ServerCertificateValidationCallback = {$true} 
  }
  $webclient = New-Object system.net.webclient
  $webclient.DownloadFile($url,$file)
}

Get-WebPage -url $msi_source -file $msi_dest -force
$msiexec_path = "C:\Windows\System32\msiexec.exe"
$msiexec_args = "/qn /i $msi_dest"
$msiexec_proc = [System.Diagnostics.Process]::Start($msiexec_path, $msiexec_args)
$msiexec_proc.WaitForExit()
