# script to move students and to update server folders

# TODO - create functions for respective tasks so that multiple students can be iterated in a loop from csv

# imports
import-module ActiveDirectory

# array of school site codes for error checking, dont forget to update as schools are added
$schoolArray = @('BAC','BAU','BEA','BEN','BET','BLE','BOL','CHS','CLP','CPE','DUN','EXP','EYE','FCH','FRH','HAR','IRI','JOH','KIN','KRU',
'LAU','LES','LIN','LIV','LNT','LOP','MCG','ODE','OLA','OPT','PCA','PHS','POA','POL','PRE','PUT','RED','RIC','RIF','RMH','SHE','STO',
'TAV','TIM','TRA','WEB','WEL','WER','ZAC')

# some globals
$date = Get-Date -UFormat "%m/%d/%Y"
$OU = 'OU=Students,DC=psdschools,DC=org'

# first error check, validate input of a real student in AD
$StudentExist = $false
while($StudentExist -eq $false){
    $sNum = Read-Host 'Enter the student number'
    try {
        $student = Get-ADUser $sNum 
        Write-Host "Student $snum found."
        $StudentExist = $true
    }catch{
        Write-Host 'Student not found,try again.'
    }
}

# more variables 
$oldOU = $student.DistinguishedName
$simpleOldOU = (($student.DistinguishedName -split ",",2)[1]).Substring(3,3)

# second error check, validate input of site code
$schoolExist = $false
while($schoolExist -eq $false){
    $newOU = (Read-Host 'Enter the school the student needs to be moved to').ToUpper()
    if($schoolArray -contains $newOU){ 
        Move-ADobject -Identity $oldOU -TargetPath "OU=$newOU,$OU"
        $schoolExist = $true 
    }else{
        Write-Host "$newOU doesnt exist, try again."
        $schoolExist = $false
     } 
}

# set the users description 
Set-ADUser $sNum -Description "Moved from $simpleOldOU to $newOU on $date"

# even more variables
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
# TODO - add logic for PGA folders

# if newOU = POA, then dont move folder ? figure out best option for this
# if simpleOldOU = POA, create folder in new path


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

# ignore the error on this, will still set the acl, just doesnt know if admin in AD
Set-Acl $newFolderPath $acl -EA SilentlyContinue

# the path for the students profile in AD
Set-ADUser $sNum -HomeDirectory $newFolderPath

Write-Host "Done"