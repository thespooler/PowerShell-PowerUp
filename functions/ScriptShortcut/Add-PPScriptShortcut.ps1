<#
$Metadata = @{
	Title = "Add PowerShell PowerUp Script Shortcut"
	Filename = "Add-PPScriptShortcut.ps1"
	Description = ""
	Tags = ""
	Project = ""
	Author = "Janik von Rotz"
	AuthorContact = "http://janikvonrotz.ch"
	CreateDate = "2014-01-09"
	LastEditDate = "2014-01-09"
	Url = ""
	Version = "0.0.0"
	License = @'
This work is licensed under the Creative Commons Attribution-ShareAlike 3.0 Switzerland License.
To view a copy of this license, visit http://creativecommons.org/licenses/by-sa/3.0/ch/ or 
send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
'@
}
#>

function Add-PPScriptShortcut{

<#
.SYNOPSIS
    Add a new PowerShell PowerUp script shortcut.

.DESCRIPTION
	Add a new PowerShell PowerUp script shortcut. Script shortcuts can be used to run a script from script folder where ever it is stored.

.PARAMETER Name
	Name of the script.

.PARAMETER ShortcutKey
	Shortcut key.
    
.PARAMETER ShortcutName
    Name of the Shortcut, by default it's the script name.
        
.EXAMPLE
	PS C:\> Add-PPScriptShortcut -Name Script1.ps1 -ShortcutKey s1

.EXAMPLE
	PS C:\>  Add-PPScriptShortcut -Name Script1.ps1 -ShortcutKey s1 -ShortcutName "Shortcut for Script1"
#>

    [CmdletBinding()]
    param(

        [Parameter(Mandatory=$true)]
		[String]
		$Name,
 
        [Parameter(Mandatory=$false)]
		[String]
		$ShortcutKey,
                 
        [Parameter(Mandatory=$false)]
		[String]
		$ShortcutName
	)
  
    #--------------------------------------------------#
    # main
    #--------------------------------------------------#

    # set default value
    if(-not $ShortcutName){$ShortcutName = $Name}

    # get shortcut data files
    $ShortcutFiles = Get-ChildItem -Path $PSconfigs.Path -Filter $PSconfigs.ScriptShortcut.DataFile -Recurse
        
    # get script
    Get-PPScript -Name $Name | select -First 1 | %{
    
        $Script = $_
    
        # check existing shortcut with same name
        if($ShortcutKey){
            if( (Get-PPScript -Name $Name -Shortcut) -or                
                (Get-PPScript -Name $ShortcutName -Shortcut) -or
                (Get-PPScript -Name $ShortcutKey -Shortcut)
            ){
                throw "This script shortcut name, key or filename already exists, these attributes have to be unique."
            }
        }elseif( (Get-PPScript -Name $Name -Shortcut) -or                
            (Get-PPScript -Name $ShortcutName -Shortcut)        
        ){
            throw "This script shortcut name, filename already exists, these attributes have to be unique."
        }
    
        # update config
        $(if(-not $ShortcutFiles){
        
            Write-Host "Create Shortcut data file in config folder"                     
            Copy-Item -Path (Get-ChildItem -Path $PStemplates.Path -Filter $PSconfigs.ScriptShortcut.DataFile -Recurse).FullName -Destination $PSconfigs.Path -PassThru
            
        }else{
        
            $ShortcutFiles
            
        }) | %{
        
            Write-Host "Adding script shortcut: $ShortcutName refering to: $($Script.Name)"

            $Xml = [xml](get-content $_.Fullname)
            $Element = $Xml.CreateElement("ScriptShortcut")
            $Element.SetAttribute("Key",$ShortcutKey)
            $Element.SetAttribute("Name",$ShortcutName)
            $Element.SetAttribute("Filename", $Script.Name)
            $Content = Select-Xml -Xml $Xml -XPath "//Content"
            $Null = $Content.Node.AppendChild($Element)
            $Xml.Save($_.Fullname)
			
			# output TrueCrypt data
			$_ | select @{L="Key";E={$ShortcutKey}}, @{L="Name";E={$ShortcutName}}, @{L="Filename";E={$Script.Name}}
        }
    }
}