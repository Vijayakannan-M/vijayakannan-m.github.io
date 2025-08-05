# vijayakannan-m.github.io

# [precheck.ps1](https://github.com/Vijayakannan-M/vijayakannan-m.github.io/blob/main/precheck-script/precheck.ps1)

## Overview
This PowerShell script automates the process of connecting to a VMware vCenter server, retrieving a list of ESXi hosts in a specified cluster (or a single host), and running a series of commands on each host to create application accounts using HPE iLO credentials. It is designed for use in HPE/VMware environments where automated account setup and configuration is required.

## Features
- Prompts for vCenter, ESXi, and iLO credentials interactively.
- Connects to vCenter using VMware PowerCLI.
- Retrieves all ESXi hosts in a specified cluster or operates on a single ESXi host by IP.
- Uses SSH (via `plink.exe`) to run commands on each ESXi host:
  - Creates an application account on iLO 7.
  - Sets iSUT mode to AutoDeploy.
  - Creates an AMS application account for VMware integration.
- Outputs a summary table of results for each command on each host.
- Disconnects from vCenter at the end of execution.

## Prerequisites
- **PowerShell**: Run the script in Windows PowerShell with administrative privileges.
- **VMware PowerCLI**: Must be installed and imported. [Download PowerCLI](https://developer.broadcom.com/tools/vcf-powercli/latest/)
- **SSH Client**: `plink.exe` (from PuTTY) must be available in your system PATH.
- **ESXi/iLO Credentials**: You will need valid credentials for vCenter, ESXi root, and iLO.

## Usage
1. Open PowerShell as Administrator.
2. Ensure `plink.exe` is in your PATH.
3. Run the script:
   ```powershell
   .\precheck.ps1
   ```
4. Enter the required credentials and target cluster/host when prompted.

## Example Workflow
- The script will prompt for:
  - vCenter hostname or IP
  - vCenter username and password
  - ESXi root password
  - iLO username and password
  - Cluster name or ESXi host IP
- It will then:
  - Connect to vCenter
  - Retrieve the list of ESXi hosts
  - Run the following commands on each host via SSH:
    - `sut appaccount create -u <iLO user> -p <iLO pass>`
    - `sut -set mode=AutoDeploy`
    - `/opt/amsdv/bin/amsdCli appaccount create -u <iLO user> -p <iLO pass>`
  - Output a summary table of results
  - Disconnect from vCenter

## Notes
- **Security Warning**: The script converts secure strings to plain text for SSH command execution. Do not use in production without securing credential handling.
- **Dependencies**: No formal requirements.txt; install dependencies manually.
- **Troubleshooting**: Ensure PowerCLI and plink.exe are installed and accessible. Check permissions and network connectivity to vCenter and ESXi hosts.

## References
- [VMware PowerCLI Installation Guide](https://developer.broadcom.com/powercli/installation-guide)
- [PuTTY Download Page (for plink.exe)](https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html)

---
This script is part of a set of utilities for HPE/VMware automation. See other scripts in this repository for related functionality.
