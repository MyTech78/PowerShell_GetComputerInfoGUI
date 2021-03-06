<#
.SYNOPSIS
 	
	<Overview of script>

.DESCRIPTION

	This PowerShell Script will open a XAML Form to gather information from remote computers via WinRM.
		
.PARAMETER Version

	This displays the current Script version.
	
.INPUTS
	
	None

.OUTPUTS
	
	Grid View information report

.NOTES
	
	Version:			0.1
	Author:             Filipe Soares
	Github Repo:		https://github.com/MyTech78/PowerShell_GetComputerInfoGUI
	Creation Date:		15/05/2021  
	Purpose/Change:	    Initial script development
  
	
#>

#--------------------------------------------------------[ Initialisations ]-------------------------------------------------------

Param(
	[Switch]$Version
)

#----------------------------------------------------------[Declarations]----------------------------------------------------------

#Script Version
$sScriptVersion = "0.1"
$sScriptAuthor = 'Filipe Soares'
$sScripGithubRepo =	'https://github.com/MyTech78/PowerShell_GetComputerInfoGUI'
$sFile = $MyInvocation.MyCommand.Name

#----------------------------------------------------------[ Functions ]-----------------------------------------------------------

# Get Script File Version
Function sVersion {
	Write-Host ''
	Write-Host 'File:' $sFile
	Write-Host 'Version:' $sScriptVersion
	Write-Host 'Author:' $sScriptAuthor
	Write-Host 'GitHub Repo:' $sScripGithubRepo
	Write-Host ''
}

Function  loadDialog {
    [CmdletBinding()]
    Param(
    [Parameter(Mandatory=$True,Position=1)]
    [string]$XamlPath
    )
    
    [xml]$Global:xmlWPF = Get-Content -Path $XamlPath
    
    #Add WPF and Windows Forms assemblies
    try{
    Add-Type -AssemblyName PresentationCore,PresentationFramework,WindowsBase,system.windows.forms
    } catch {
    Throw "Failed to load Windows Presentation Framework assemblies."
    }
    
    #Create the XAML reader using a new XML node reader
    $Global:xamGUI = [Windows.Markup.XamlReader]::Load((new-object System.Xml.XmlNodeReader $xmlWPF))
    
    #Create hooks to each named object in the XAML
    $xmlWPF.SelectNodes("//*[@Name]") | %{
    Set-Variable -Name ($_.Name) -Value $xamGUI.FindName($_.Name) -Scope Global
    }
} 

#----------------------------------------------------------[ Execution ]-----------------------------------------------------------

#Required to load the XAML form and create the PowerShell Variables
loadDialog -XamlPath '.\MyForm.xaml'

[Void]$TextBox1.focus()

#---------------------------------------------------------[ Event Handler ]--------------------------------------------------------

  
$TextBox1.add_MouseDoubleClick({
	$TextBox1.Clear()
   })
   

$Button1.add_Click({
    $strComputer = $TextBox1.Text
	Get-Service -ComputerName $strComputer | 
		#Where-Object {$_.Status -EQ "Running"}| 
			Out-GridView -Title "List of running services" -PassThru | 
				Select -ExpandProperty Name
   })
   
$Button2.add_Click({
	$strComputer = $TextBox1.Text
	Get-CimInstance Win32_LogicalDisk -Computer $strComputer  |
		Select-Object SystemName, DeviceID,
		        		@{n='FreeSpace GB';e={[int]($_.FreeSpace/1GB)}},
		        		@{n='Size GB';e={[int]($_.Size/1GB)}} | 
						Out-GridView -Title "List of Logiccal Disks"
	
   })
   
$Button3.add_Click({
	$strComputer = $TextBox1.Text
	Get-CimInstance Win32_OperatingSystem -Namespace 'root\CIMV2' -ComputerName $strComputer | 
		Select-Object @{n='SystemName';e={$_.PSComputerName}}, 
					Caption, Version, OSArchitecture| 
						Out-GridView -Title "Operating System Info"
	
   })

$Button4.add_Click({
	$strComputer = $TextBox1.Text
	Get-CimInstance Win32_NetworkAdapterConfiguration -Namespace 'root\CIMV2' -ComputerName $strComputer | 
		Select-Object @{n='SystemName';e={$_.PSComputerName}}, 
					index, Description, IPEnabled, DHCPEnabled, DNSDomain, IPAddress, DefaultIPGateway, 
						DNSServerSearchOrder, DHCPServer, IPSubnet, MACAddress, ServiceName | 
							Out-GridView -Title "Network Adapter Configuration"
	
   })

$Button5.add_Click({
	$strComputer = $TextBox1.Text
	$strCommand = '/offerra ' + $strComputer
	Start-Process -FilePath msra -ArgumentList $strCommand
	
   })
   
$Button6.add_Click({
	$strComputer = $TextBox1.Text
	$strCommand = '/v:' + $strComputer + ' /Prompt'
	Start-Process -FilePath mstsc -ArgumentList $strCommand
   }) 

#-----------------------------------------------------------[Reporting]------------------------------------------------------------

if ($Version) {
	# Display Version Info
	sVersion
	exit 0
	}
	
#-----------------------------------------------------------[ Show GUI ]-----------------------------------------------------------

#Launch the window
$xamGUI.ShowDialog() | out-null