# Requires: PowerCLI, SSH client (e.g., OpenSSH or plink.exe in PATH)
# Description: This script connects to a vCenter server, retrieves a list of ESXi hosts in a specified cluster,
# and runs a command on each host to create an application account using iLO credentials.   
# Usage: Run this script in PowerShell with administrative privileges. 
# Ensure SSH client (like plink.exe) is available in the PATH
# Download and install VMware PowerCLI if not already installed. Download from https://developer.broadcom.com/tools/vcf-powercli/latest/
# Ensure PowerCLI is installed and imported. Instllation guide: https://developer.broadcom.com/powercli/installation-guide

# Prompt for vCenter and ESXi credentials
$vcenter = Read-Host "Enter vCenter hostname or IP"
$vcUser = Read-Host "Enter vCenter username"
$vcPass = Read-Host "Enter vCenter password" -AsSecureString
$esxiRoot = "root"
$esxiPass = Read-Host "Enter ESXi root password" -AsSecureString
$iloUser = Read-Host "Enter iLO username"
$iloPass = Read-Host "Enter iLO password"
$target = Read-Host "Enter cluster name or ESXi host IP"

# Convert secure strings to plain text for SSH (not recommended for production)
$vcPassPlain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($vcPass))
$esxiPassPlain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($esxiPass))

# Step 1: Create an Application Account on iLO 7
$SutAppAccountCreate = "sut appaccount create -u $iloUser -p $iloPass"

# Step 2: Set iSUT Mode to AutoDeploy
$SutSetMode = "sut -set mode=AutoDeploy"

# Step 3: Create AMS Application Account (for VMware)
$AmsAppAccountCreate = "/opt/amsdv/bin/amsdCli appaccount create -u $iloUser -p $iloPass"

# Connect to vCenter
Import-Module VMware.PowerCLI.vCenter
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false | Out-Null
Connect-VIServer -Server $vcenter -User $vcUser -Password $vcPassPlain | Out-Null

# Helper to run SSH command and capture output
function Run-SSHCommand {
    param($host, $user, $pass, $cmd)
    # Using plink.exe (from PuTTY) for SSH with password
    $plink = "plink.exe"
    $plinkArgs = "-ssh $user@$host -pw $pass $cmd"
    $output = & $plink $plinkArgs 2>&1
    return $output
}

# Get list of hosts
$hosts = @()
if ($target -match "^\d{1,3}(\.\d{1,3}){3}$") {
    # Single host IP
    $hosts += $target
} else {
    # Cluster: get all host IPs in the cluster
    $cluster = Get-Cluster -Name $target -ErrorAction Stop
    $vmhosts = Get-VMHost -Location $cluster
    foreach ($h in $vmhosts) {
        $hosts += $h.Name
    }
}


# Run all CLI commands sequentially on each host and collect results
$cliCommands = @(
    @{ Name = 'SUT AppAccount Create'; Cmd = $SutAppAccountCreate },
    @{ Name = 'SUT Set Mode'; Cmd = $SutSetMode },
    @{ Name = 'AMS AppAccount Create'; Cmd = $AmsAppAccountCreate }
)

$results = @()
foreach ($host in $hosts) {
    foreach ($cli in $cliCommands) {
        Write-Host "Running [$($cli.Name)] on $host ..."
        $output = Run-SSHCommand -host $host -user $esxiRoot -pass $esxiPassPlain -cmd $cli.Cmd
        $results += [PSCustomObject]@{
            Host = $host
            Command = $cli.Name
            Result = $output -join "`n"
        }
    }
}

# Output summary table
$results | Format-Table -Property Host,Command,Result -AutoSize

# Disconnect from vCenter
Disconnect-VIServer -Server $vcenter -Confirm:$false | Out-Null
