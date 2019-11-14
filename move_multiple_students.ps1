# modified student move script to move more than one student #

# globals
$path = "C:\Users\tvanveen\csv's\move.csv"
$csv = Import-Csv -path $path
import-module ActiveDirectory
$date = Get-Date -UFormat "%m/%d/%Y"
# set the OU 
$OU = 'OU=Students,DC=psdschools,DC=org'
# list of schools in an array to compare to for error checking 
$schoolArray = @('BAC','BAU','BEA','BEN','BET','BLE','BOL','CHS','CLP','CPE','DUN','EXP','EYE','FCH','FRH','HAR','IRI','JOH','KIN','KRU',
'LAU','LES','LIN','LIV','LNT','LOP','MCG','ODE','OLA','OPT','PCA','PHS','POA','POL','PRE','PUT','RED','RIC','RIF','RMH','SHE','STO',
'TAV','TIM','TRA','WEB','WEL','WER','ZAC')


# iterate through the CSV file to get the 
foreach($line in $csv)
{ 
    $properties = $line | Get-Member -MemberType Properties
    for($i=0; $i -lt $properties.Count;$i++)
    {
        $column = $properties[$i]
        $columnvalue = $line | Select-Object -ExpandProperty $column.Name
        Move-Stu($columnvalue)
    }
} 

# function that finds the student and moves them in AD
function Move-Stu($sNum) {
    #1. get the snum, old ou, new ou from the .csv
    #2. move the AD object 
    #3. set the AD description
    #4. modify the groups

    # first error check, validate input of a real student in AD
    $StudentExist = $false
    while($StudentExist -eq $false){
        try {
            $student = Get-ADUser $sNum
            $StudentExist = $true
        }catch{
            continue
        }
    }
    # variables for the OUs
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

    # variables for student groups
    $oldSGroup = $simpleOldOU + 'Students'
    $newSGroup = $newOU + 'Students'

    # remove student from previous school group and add to new group
    Remove-ADGroupMember -Identity $oldSGroup -Members $sNum -Confirm:$false
    Add-ADGroupMember -Identity $newSGroup -Members $sNum
    }

function Move-Fold($student) {
    #1. 

}




