function Get-XSVMCount {
    <#
    .SYNOPSIS
    Returns count of VM for each XenServer poolmaster.
    .DESCRIPTION
    Returns a count of VM's for each XenServer poolmaster. Script defaults to XenServer root and prompts for password if not present.
    You can enter in your own admin credentials if needed.
    .PARAMETER xenserver_poolmaster
    Optional String array parameter. List of XenServer PoolMasters to query. Default values are set in the script.
    .PARAMETER xenserver_username
    Optional String parameter. XenServer admin username (defaults to root).
    .PARAMETER xenserver_credential_path
    Optional String parameter. Path to XenServer_username password. Created if not present. System.Management.Automation.PSCredential
    .INPUTS
    None
    .OUTPUTS
    System.Management.Automation.PSCredential (XenServer username password if not present)
    .EXAMPLE
    Get-XSVMCount
    Connects to default list of poolmasters using XenServer root account and password. Returns a list of total number of VM's in a XenServer pool.
    .NOTES
    NAME        :  Get-XSVMCount.ps1
    VERSION     :  1.00
    CHANGE LOG - Version - When - What - Who
    1.00 - 07/27/2018 - Initial script - Alain Assaf
    LAST UPDATED:  07/27/2018
    AUTHOR      :  Alain Assaf
    .Link 
    https://www.linkedin.com/in/alainassaf/
    http://xenstuff.blogspot.com/2013/11/how-to-automate-citrix-xenserver-powershell-scripts.html
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    Param(
        [parameter(Position = 0, Mandatory = $False )]
        [array]$xenserver_poolmaster = @("192.168.50.1", "192.168.50.2"),

        [parameter(Mandatory = $false)]
        [string]$xenserver_username = "root",

        [parameter(Mandatory = $false)]
        [string]$xenserver_credential_path = "c:\temp\xenserver_pool.pwd"
    )
    # If Password file does not exist, create it
    if ((Test-Path -Path $xenserver_credential_path) -eq $False) {
        (Get-Credential).Password | ConvertFrom-SecureString | Out-File $xenserver_credential_path
    }

    # Read the password
    $xenserver_password = Get-Content $xenserver_credential_path | ConvertTo-SecureString

    # Create the PSCredential Object
    $xenserver_credential = New-Object -Typename System.Management.Automation.PSCredential -ArgumentList $xenserver_username, $xenserver_password

    # Import the XenServer PSSnapIn
    if ( (get-module -Name "XenServerPSModule" -ErrorAction SilentlyContinue) -eq $Null ) {import-module XenServerPSModule}

    #Initialize results array
    $finalout = @()

    # Loop through list of hosts (poolmaster)
    $xenserver_poolmaster | ForEach-Object {

        # Connect to XenServer pool
        Connect-XenServer -Server $_ -Creds $xenserver_credential -SetDefaultSession -NoWarnNewCertificates

        switch ($_) {
            "192.168.50.1" {$xsn = "XenServerPool1"; break}
            "192.168.50.2" {$xsn = "XenServerPool2"; break}
            default {"UNKNOWN XENSERVER"; break}
        }

        # Retrieve the information
        $XenServerVMs = Get-XenVM | Where-Object {$_.is_a_snapshot -eq $false -and $_.is_a_template -eq $false -and $_.is_control_domain -eq $false -and $_.power_state -eq 'running'} | Select-Object name_label
        $vmCount = $XenServerVMs.count
        $objctxsrv = new-object System.Object
        $objctxsrv | Add-Member -type NoteProperty -name XenServer -value $xsn
        $objctxsrv | Add-Member -type NoteProperty -name 'VM Count' -value ($vmCount)
        $finalout += $objctxsrv
        # Disconnect from the XenServer pool
        Get-XenSession -Server $_ | Disconnect-XenServer
    }
    $finalout
}