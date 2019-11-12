# modified student move script to move more than one student #

# create function to move the student
# create function for the folder
# iterate through the list of students calling each funciton 

$path = "c:\Users\"
$csv = Import-Csv -path $path
# Import Modules
import-module ActiveDirectory
$date = Get-Date -UFormat "%m/%d/%Y"
# set the OU 
$OU = 'OU=Students,DC=psdschools,DC=org'
# list of schools in an array to compare to for error checking 
$schoolArray = @('BAC','BAU','BEA','BEN','BET','BLE','BOL','CHS','CLP','CPE','DUN','EXP','EYE','FCH','FRH','HAR','IRI','JOH','KIN','KRU',
'LAU','LES','LIN','LIV','LNT','LOP','MCG','ODE','OLA','OPT','PCA','PHS','POA','POL','PRE','PUT','RED','RIC','RIF','RMH','SHE','STO',
'TAV','TIM','TRA','WEB','WEL','WER','ZAC')

# function that finds the student and moves them in AD
function Move-Em() {
    #1. get the snum, old ou, new ou from the .csv
    #2. move the AD object 
    #3. set the AD description
    #4. modify the groups
    #5. set variables for folder paths (add logic for EXP)
    #6. move student folder
    #7. set permissions
    #8. set new folder path (ignore error, script doesnt know admin)
    #9. set the path in AD. 
}





