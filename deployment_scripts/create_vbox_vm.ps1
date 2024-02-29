#
# This script is called by the installer to create a VirtualBox VM
#
# The VM created will have the following characteristics
# •	Up-to-date Debian 12 OS;
# •	8GB of RAM;
# •	2 CPUs.

$NB_CPU = 2
$RAM_SIZE = 8192
$HDD_SIZE = 20480

if ($IsLinux) {
    $DEBIAN_ISO_BASEURL = 'https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/'
    $VBOXMANAGE = 'vboxmanage'
}
elseif ($IsMacOS) {
    $DEBIAN_ISO_BASEURL = 'https://cdimage.debian.org/debian-cd/current/arm64/iso-cd/'
    $VBOXMANAGE = 'vboxmanage'
}
elseif ($IsWindows) {
    $DEBIAN_ISO_BASEURL = 'https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/'
    $VBOXMANAGE = 'C:\Progra~1\Oracle\VirtualBox\VBoxManage.exe'
}

# Initialize script variables used in the script
$DEST_PATH = $null
$ISOFILE_DEST = $null

function Invoke-InPowerShellVersion {
    $currentVersion = $PSVersionTable.PSVersion

    # Check if the major version is 6 or higher
    if ($currentVersion.Major -lt 6) {
        Write-Host "You are running PowerShell Version $currentVersion"

        # Check if pwsh exists before upgrading
        try {
            Write-Host "Checking if a newer version of PowerShell is found..."
            Start-Process -FilePath "pwsh" -ArgumentList "-V" -NoNewWindow -Wait
        }
        catch {
            Write-Host "PowerShell will be tentatively upgraded..."
            Install-LatestPowerShell
            if (-not $?) {
                Show-ErrorMessage "Error upgrading PowerShell. Please upgrade PowerShell manually."
                Exit
            }
            else {
                Write-Host "Powershell updated successfully"
                Exit
            }
        }
        finally {
            Write-Host "Restart the install by running the script using pwsh instead of powershell"
            Exit
        }
    }
}

function Install-LatestPowerShell {
    try {
        Start-Process -Wait -FilePath "apt" -ArgumentList "-y install pwsh"
    }
    catch {
        try {
            Start-Process -Wait -FilePath "yum" -ArgumentList "-y install pwsh"
        }
        catch {
            # Both commands failed. We are probably not running Linux
        }
        finally {
            # Extract the download URL for the MSI installer from Github API
            $repoUrl = "https://api.github.com/repos/PowerShell/PowerShell"
            $latestRelease = Invoke-RestMethod -Uri "$repoUrl/releases/latest"
            $downloadUrl = $latestRelease.assets | Where-Object { $_.name -like "*win-x64.msi" } | Select-Object -ExpandProperty browser_download_url

            # Download the MSI installer
            Invoke-WebRequest -Uri $downloadUrl -OutFile "PowerShellInstaller.msi"

            # Install PowerShell using the downloaded installer
            Start-Process -Wait -FilePath "msiexec.exe" -ArgumentList "/i PowerShellInstaller.msi /quiet"

            # Clean up the temporary installer file
            Remove-Item -Path "PowerShellInstaller.msi" -Force
        }
    }
}

function Invoke-VboxManage {
    try {
        if (Start-Process -Wait -FilePath "$VBOXMANAGE" -ArgumentList "-V") {
            Write-Host "VirtualBox is already installed..."
        }
    }
    # If vboxmanage does not exist, try to install VirtualBox
    catch {
        Write-Host "VirtualBox will be tentatively installed..."
        Install-LatestVirtualBox
    }
}

function Install-LatestVirtualBox {
    # Get the latest release information
    $repoUrl = 'https://download.virtualbox.org/virtualbox'
    $LatestVersion = (Invoke-WebRequest -Uri "$repoUrl/LATEST.TXT").Content.Trim()

    # Get the full version including the 6-digit number
    $DownloadPageContent = (Invoke-WebRequest -Uri "https://download.virtualbox.org/virtualbox/$LatestVersion").Content
    $FullVersion = $LatestVersion + '-' + [regex]::Matches($DownloadPageContent, '[0-9]{6,}').Groups[1].Value

    # Build the download URL for the extension pack
    $downloadExtPackUrl = $repoUrl + '/' + $LatestVersion + '/Oracle_VM_VirtualBox_Extension_Pack-' + $LatestVersion + '.vbox-extpack'

    # Download the installer and extension pack
    if ($IsMacOS){
        $FileName = 'VirtualBox-' + $FullVersion + '-OSX.dmg'
        $downloadUrl = $repoUrl + '/' + $LatestVersion + '/' + $FileName
        Invoke-WebRequest -Uri $downloadUrl -OutFile "$FileName"
    }
    Invoke-WebRequest -Uri $downloadExtPackUrl -OutFile "VirtualBox_Extension_Pack.vbox-extpack"

    # Install VirtualBox
    if ($IsWindows) {
        Start-Process -Wait -FilePath "winget" -ArgumentList "install Oracle.Virtualbox --accept-source-agreements"
    }
    elseif ($IsLinux) {
    }
    elseif ($IsMacOS){
        Start-Process -Wait -FilePath "hdiutil" -ArgumentList "attach $FileName"
        Start-Process -Wait -FilePath "sudo" -ArgumentList "installer -pkg /Volumes/VirtualBox/VirtualBox.pkg -target /Volumes/Macintosh\ HD"
        Start-Process -Wait -FilePath "hdiutil" -ArgumentList "detach /Volumes/VirtualBox"
        Remove-Item -Path "$FileName" -Force
    }
    
    # Install the extension pack
    Start-Process -Wait -FilePath "$VBOXMANAGE" -ArgumentList "extpack install VirtualBox_Extension_Pack.vbox-extpack"
    Remove-Item -Path "VirtualBox_Extension_Pack.vbox-extpack" -Force
}

function Show-ErrorMessage {
    param (
        [parameter(mandatory=$true)] $MESSAGE,
        $CMD
    )
    Write-Host "### $MESSAGE. Exiting" -ForegroundColor red
    if (-not ([string]::IsNullOrEmpty($CMD))) {
        Write-Host "Failed command: $CMD" -ForegroundColor red
    }
}

function New-TempFolder {
    if ($IsMacOS){
        $script:DEST_PATH = Join-Path $Env:TMPDIR $(New-Guid)
    }
    elseif ($IsLinux) {
        $script:DEST_PATH = Join-Path $Env:XDG_RUNTIME_DIR $(New-Guid)
    }
    elseif ($IsWindows) {
        $script:DEST_PATH = Join-Path $Env:TEMP $(New-Guid)
    }
    $CMD = 'New-Item -Type Directory -Path $DEST_PATH | Out-Null'
    Invoke-Expression $CMD
    if (-not $?) {
        Show-ErrorMessage "The temporary folder $DEST_PATH could not be created" "$CMD"
        Exit
    }
    else {
        Write-Host "# Temporary folder $DEST_PATH created"
    }
}

function Get-OSIso {
    param (
        [parameter(mandatory=$true)] $URL,
        [parameter(mandatory=$true)] $DEST
    )
    # Download SHA512SUMS file
    if (-not $url.EndsWith('/')) {
        $URL = $URL + "/"
    }
    $SUMFILE_URL = $URL + "SHA512SUMS"
    $SUMFILE_DEST = Join-Path $DEST "SHA512SUMS"
    $CMD = 'Invoke-WebRequest -Uri $SUMFILE_URL -OutFile $SUMFILE_DEST'
    Invoke-Expression $CMD
    if (-not $?) {
        Show-ErrorMessage "The checksum file $SUMFILE_URL could not be downloaded to $SUMFILE_DEST" "$CMD"
        Exit
    }
    $HASH, $ISOFILE = Get-Content $SUMFILE_DEST | Select-Object -First 1 | ForEach-Object { $_.Split(' ',[System.StringSplitOptions]::RemoveEmptyEntries) }
    $ISOFILE_URL = $URL + $ISOFILE
    $script:ISOFILE_DEST = Join-Path $DEST $ISOFILE
    $CMD = 'Invoke-WebRequest -Uri $ISOFILE_URL -OutFile $ISOFILE_DEST'
    Invoke-Expression $CMD
    if (-not $?) {
        Show-ErrorMessage "The ISO file $ISOFILE_URL could not be downloaded to $ISOFILE_DEST" "$CMD"
        Exit
    }
    $DLFILE_HASH = (Get-FileHash $ISOFILE_DEST -Algorithm SHA512).Hash
    if (-not $DLFILE_HASH -ieq $HASH) {
        Show-ErrorMessage "The calculated hash $DLFILE_HASH is different from the hash $HASH in $SUMFILE_DEST"
        Exit
    }
}

function Get-RandomPassword {
    param (
        [int] $length = 12
    )
    $RandomString = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count $length | ForEach-Object {[char]$_})
    return $RandomString
}

function Edit-PreseedFile {
    param (
        [parameter(mandatory=$true)] $DEST,
        [parameter(mandatory=$true)] $UUID
    )
    if ($IsWindows) {
        $script:PreseedFile = 'C:\Progra~1\Oracle\VirtualBox\UnattendedTemplates\debian_preseed.cfg'
    }
    elseif ($IsLinux) {
        # TBD $script:PreseedFile = 'C:\Progra~1\Oracle\VirtualBox\UnattendedTemplates\debian_preseed.cfg'
    }
    elseif ($IsLinux) {
        # TBD $script:PreseedFile = 'C:\Progra~1\Oracle\VirtualBox\UnattendedTemplates\debian_preseed.cfg'
    }
    #$PreseedFile = $DEST + '/Medulla/Unattended-' + $UUID + '-preseed.cfg'
    Copy-Item "$PreseedFile" -Destination "$PreseedFile + '.bak'"
    $NewContent = Get-Content -Path $PreseedFile | ForEach-Object {
        # Output the existing line to the pipeline in any case
        $_
    
        # If the line matches the regex for the target line
        if ($_ -match ('^' + [regex]::Escape('# Network'))) {
            'd-i netcfg/disable_autoconfig boolean true'
            'd-i netcfg/get_ipaddress string 192.168.10.100'
            'd-i netcfg/get_netmask string 255.255.255.0'
            'd-i netcfg/get_gateway string 192.168.10.1'
            'd-i netcfg/get_nameservers string 192.168.10.1'
            'd-i netcfg/confirm_static boolean true'
        }
    }
    $NewContent | Out-File -FilePath $PreseedFile -Encoding Default -Force
}

function New-VBOXVM {
    param (
        [parameter(mandatory=$true)] $ISO_PATH,
        [parameter(mandatory=$true)] $DEST
    )
    $VM_UUID = $(New-Guid)
    if ($IsMacOS){
        $INTERFACE = 'en0: Wi-Fi'
        $TYPE = 'Debian'
    }
    elseif ($IsLinux) {
        $INTERFACE = 'eth0'
        $TYPE = 'Debian_64'
    }
    elseif ($IsWindows) {
        $INTERFACE = 'Red Hat VirtIO Ethernet Adapter'
        $TYPE = 'Debian_64'
    }
    $script:ROOT_PASSWORD = Get-RandomPassword 12
    $CMD = "$VBOXMANAGE createvm --basefolder=$DEST --name Medulla --uuid $VM_UUID --ostype $TYPE --register"
    Invoke-Expression $CMD
    if (-not $?) {
        Show-ErrorMessage "Error creating the VM" "$CMD"
        Exit
    }
    $CMD = "$VBOXMANAGE modifyvm Medulla --cpus $NB_CPU --memory $RAM_SIZE --vram 12 --graphicscontroller VBoxSVGA"
    Invoke-Expression $CMD
    if (-not $?) {
        Show-ErrorMessage "Error setting the VM resources" "$CMD"
        Exit
    }
    $CMD = "$VBOXMANAGE natnetwork add --netname NATMedulla --network '192.168.10.0/24' --dhcp off --enable"
    Invoke-Expression $CMD
    if (-not $?) {
        Show-ErrorMessage "Error creating the NAT network" "$CMD"
        Exit
    }
    $CMD = "$VBOXMANAGE natnetwork start --netname NATMedulla"
    Invoke-Expression $CMD
    if (-not $?) {
        Show-ErrorMessage "Error starting the NAT network" "$CMD"
        Exit
    }
    $CMD = "$VBOXMANAGE modifyvm Medulla --nic1 natnetwork --nat-network1 NATMedulla"
    Invoke-Expression $CMD
    if (-not $?) {
        Show-ErrorMessage "Error creating the VM network settings" "$CMD"
        Exit
    }
    $CMD = "$VBOXMANAGE createmedium disk --filename $DEST/Medulla/Medulla.vdi --size $HDD_SIZE --variant Standard"
    Invoke-Expression $CMD
    if (-not $?) {
        Show-ErrorMessage "Error creating the VM storage file $DEST/Medulla/Medulla.vdi" "$CMD"
        Exit
    }
    $CMD = "$VBOXMANAGE storagectl Medulla --name 'SATA Controller' --add sata --bootable on"
    Invoke-Expression $CMD
    if (-not $?) {
        Show-ErrorMessage "Error adding the VM storage controller" "$CMD"
        Exit
    }
    $CMD = "$VBOXMANAGE storageattach Medulla --storagectl 'SATA Controller' --port 0 --device 0 --type hdd --medium $DEST/Medulla/Medulla.vdi"
    Invoke-Expression $CMD
    if (-not $?) {
        Show-ErrorMessage "Error attaching the VM storage file $DEST/Medulla/Medulla.vdi to the SATA controller" "$CMD"
        Exit
    }
    $CMD = "$VBOXMANAGE storagectl Medulla --name 'IDE Controller' --add ide"
    Invoke-Expression $CMD
    if (-not $?) {
        Show-ErrorMessage "Error adding the VM disk controller" "$CMD"
        Exit
    }
    $CMD = "$VBOXMANAGE storageattach Medulla --storagectl 'IDE Controller' --port 0 --device 0 --type dvddrive --medium $ISO_PATH"
    Invoke-Expression $CMD
    if (-not $?) {
        Show-ErrorMessage "Error attaching the OS ISO image $ISO_PATH to the IDE controller" "$CMD"
        Exit
    }
    Edit-PreseedFile -DEST $DEST_PATH -UUID $VM_UUID
    $CMD = "$VBOXMANAGE unattended install Medulla --iso=$ISO_PATH --user=medulla --password=$ROOT_PASSWORD --country=FR --hostname=medulla.local --install-additions --language=en-US --start-vm=gui"
    #$CMD = "$VBOXMANAGE unattended install Medulla --iso=$ISO_PATH --user=medulla --password=$ROOT_PASSWORD --country=FR --hostname=medulla.local --package-selection-adjustment=minimal --install-additions --language=en-US --start-vm=headless"
    Invoke-Expression $CMD
    if (-not $?) {
        Show-ErrorMessage "Error starting the unattended installation of the OS" "$CMD"
        Exit
    }
    #VBoxManage natnetwork modify --netname NATNetwork101 \
    #--port-forward-4 "ssh:tcp:[]:1022:[192.168.10.5]:22"
}

function Install-Medulla {
    # Nothing for now
    #ssh ${USERNAME}@$1 -p ${PORT} -i ${SSHKEY} -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null 'bash -s' < /var/lib/pulse2/clients/lin/Medulla-Agent-linux-MINIMAL-latest.sh
}

Invoke-InPowerShellVersion
Invoke-VboxManage
New-TempFolder
Get-OSIso -URL $DEBIAN_ISO_BASEURL -DEST $DEST_PATH
New-VBOXVM -ISO_PATH $ISOFILE_DEST -DEST $DEST_PATH
Install-Medulla


# Cleanup
Read-Host -Prompt "Press Enter to delete the VM and temporary files..."
Start-Process -Wait -FilePath "$VBOXMANAGE" -ArgumentList "controlvm Medulla poweroff"
Start-Process -Wait -FilePath "$VBOXMANAGE" -ArgumentList "unregistervm Medulla --delete"
Start-Process -Wait -FilePath "$VBOXMANAGE" -ArgumentList "natnetwork remove --netname NATMedulla"
Remove-Item -LiteralPath "$DEST_PATH" -Force -Recurse
Move-Item -Path "$PreseedFile + '.bak'" -Destination "$PreseedFile" -Force
