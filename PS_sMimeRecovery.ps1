param (
    [Parameter(Mandatory=$True)]
    [string]$Lname
    )

import-module -name ActiveDirectory
$domains = "sub1.something.com","sub2.something.com", "sub3.something.com"
$bunexists = $false
$path = Split-Path -parent $MyInvocation.MyCommand.Definition
$a = "certutil"
$d = "\\(?:.(?!\\))+$"

Foreach($domain in $domains)
{
    If ((Get-ADUser -LDAPFilter "(sAMAccountName=$Lname)" -Server $domain) -ne $Null){$bunexists = $true}
}

If ($bunexists -eq $true)
{
    $email = $Lname + "@something.com"
    #Email is validated and Lname exists in AD.
	$b = ($path + "\" + $Lname + ".bat")
    
    #Run the command of certutil and dump out to a .bat file - Command Original: certutil -v -getkey Lname@something.com > Lname.bat
    & $a -v -getkey $email | out-file $b -encoding "UTF8" #Tested
    
    #Run the Lname.bat file and output the 2>$1 Std. Err & Std. Out to a file to check for sMIME recovery errors
    $c = ($path + "\" + $Lname + ".tmp")
    & $b 2>&1 | out-file $c #Tested
    
    If (Get-Content $c | select-string "CertUtil: -MergePFX command completed successfully.")
    {
        #.p12 created succesful; clean things up.
        #Clean up the .tmp file & Output the password to the screen for the user.
        $f = (Get-Content $c | select-string "PASSWORD:")
        write-host $f
        remove-item $b
        remove-item $c
    }
    else
    {
        ForEach ($str In Get-Content $c) 
        { 
            If (($str | select-string "Could Not Find") -and ($str –match $d))
            {
                #The Std. Err & Std. Out temp  file has an error in it.
                #Regex out the Chuc!002c Chuck-9f422a1b11100000394c.p12 <-Example changed to protect the innocent.
                $e = ([regex]::matches($str, $d) | %{$_.value})
                $e = $e.replace('\','')
                #write-host $e #TEST
                #For each instance of $e in .tmp remove it in the .bat
                (Get-Content $b) | Foreach-Object { 
                    $_ -replace "$e",'' `
                       -replace '"",', '' `
                       -replace '@del ""',''
                } | Set-Content $b #Tested
            }
         }
            #Run that .bat again.
            & $b 2>&1 | Set-Content $c
            $f = (Get-Content $c | select-string "PASSWORD:")
            write-host $f
            Start-Sleep -s 12
            remove-item $b
            remove-item $c
    }
}
else
{
    write-host "$($Lname) was not found in Active Directory!"
    write-host "sMimes are issued for users with emails in the following Domains:something.com, something1.com, something2.com, & something3.com."
}




