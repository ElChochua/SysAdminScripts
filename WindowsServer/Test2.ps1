Import-Module Z:\Functions.psm1 -Force

$group1Users = Get-ADUser -Filter * -SearchBase "OU=group_1,DC=reprobados,DC=com"
$group2Users = Get-ADUser -Filter * -SearchBase "OU=group_2,DC=reprobados,DC=com"
foreach ($user in $group1Users) {
    Set-LogonHours -Identity $($user.SamAccountName)  -TimeIn24Format @(8, 14) -Monday -Tuesday -Wednesday -Thursday -Friday -Saturday -Sunday -NonSelectedDaysare NonWorkingDays
}
$group_2_users = Get-ADUser -Filter * -SearchBase "OU=group_2,DC=reprobados,DC=com"  
foreach ($user in $group2Users) {
    Set-LogonHours -Identity $($user.SamAccountName)   -TimeIn24Format @(15..23 + 0..2) -Monday -Tuesday -Wednesday -Thursday -Friday -Saturday -Sunday -NonSelectedDaysare NonWorkingDays
}
 