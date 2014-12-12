PS_sMimeRecovery
================

Powershell 2.0 sMime Recovery Script

The script takes in a (User Logon Name) parameter from AD.

It checks against multiple domains (provided by you), to see if user exists by using Get-ADUser -LDAPFilter "(sAMAccountName=$Lname)".

If the user exists then it starts the process of recovering the sMime certificates.

It is a just a wrapper for certutil.exe! :)
