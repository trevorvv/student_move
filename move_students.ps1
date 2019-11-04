#################################################################
#       This script will move students between OU's             #
#       Written by Trevor van Veen                              #
#                                                               #
#################################################################

# Import Modules
import-module ActiveDirectory
$date = Get-Date -UFormat "%m/%d/%Y"

# list of schools in an array to compare to for error checking 
$schoolArray = @('BAC','BAU','BEA','BEN','BET','BLE','BOL','CHS','CLP','CPE','DUN','EXP','EYE','FCH','FRH','HAR','IRI','JOH','KIN','KRU',
'LAU','LES','LIN','LIV','LNT','LOP','MCG','ODE','OLA','OPT','PCA','PHS','POA','POL','PRE','PUT','RED','RIC','RIF','RMH','SHE','STO',
'TAV','TIM','TRA','WEB','WEL','WER','ZAC')

# set the OU 
$OU = 'OU=Students,DC=psdschools,DC=org'

# get the students number
$sNum = Read-Host 'Enter the student number'

# try/catch to make sure the user exists in AD, if not the program will exit
try {
    $student = Get-ADUser $sNum 
    Write-Host "Student $snum found."
}catch{
    Write-Host 'Student not found, better luck next time.'
    exit
}

# set var for the current students OU
$oldOU = $student.DistinguishedName

# cut the full ou down to just the 3 letter abreviation 
$simpleOldOU = (($student.DistinguishedName -split ",",2)[1]).Substring(3,3)

# get the 3 letter abreviation for the school user is going to move the student to 
$newOU = (Read-Host 'Enter the school the student needs to be moved to').ToUpper()

#check to make sure that the school that was entered matches a school in AD, if not the program will exit
if($schoolArray -contains $newOU){
    ### move student to new OU ###
    Move-ADobject -Identity $oldOU -TargetPath "OU=$newOU,$OU" 
}else{
    Write-Host "Fat finger strikes again, there is no school named $newOU"
    exit
}

# set the users description 
Set-ADUser $sNum -Description "Moved from $simpleOldOU to $newOU on $date"

# variables for the students groups for membership modification
$oldSGroup = $simpleOldOU + 'Students'
$newSGroup = $newOU + 'Students'

# remove student from previous school group 
Remove-ADGroupMember -Identity $oldSGroup -Members $sNum -Confirm:$false

# add studnt to new school group 
Add-ADGroupMember -Identity $newSGroup -Members $sNum

# need this logic since the folder for EXP/PCA are weird
if($newOU -eq 'EXP'){
    $newFolderPath = "\\psdfiles\PCA\EXPStudents\$sNum"
}else{
    $newFolderPath = "\\psdfiles\$newOU\Students\$sNum"
}

if($simpleOldOU -eq 'EXP'){
    $oldFolderPath ="\\psdfiles\PCA\EXPStudents\$sNum"
}else{
    $oldFolderPath = "\\psdfiles\$simpleOldOU\Students\$sNum"
}

# Might need these for the script to reach the network fileserver
# Microsoft.PowerShell.Core\FileSystem::

# move the students folder
Move-Item -Path $oldFolderPath -Destination $newFolderPath

# disable inheritence on the new folder and set proper permissions
$simpleStaff = $newOU + 'Staff'
$acl = Get-Acl $newFolderPath
$acl.SetAccessRuleProtection($True, $True)
$AccessRule1 = New-Object System.Security.AccessControl.FileSystemAccessRule("PSDSCHOOLS.ORG\$sNum",'Modify','ContainerInherit,ObjectInherit','None','Allow')
$AccessRule2 = New-Object System.Security.AccessControl.FileSystemAccessRule("PSDSCHOOLS.ORG\$simpleStaff",'ReadAndExecute','ContainerInherit,ObjectInherit','None','Allow')
$acl.AddAccessRule($AccessRule1)
$acl.AddAccessRule($AccessRule2)

# ignore the error on this, will still set the acl, just doesnt know im admin
Set-Acl $newFolderPath $acl -EA SilentlyContinue

# the path for the students profile in AD
Set-ADUser $sNum -HomeDirectory $newFolderPath

Write-Host "Done"