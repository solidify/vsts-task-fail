#
# Fail.ps1
#
[CmdletBinding()]
param(
)

function FailByDate ($date, $condition)
{
    $now = get-date
    $faildate = get-date -Date "$date" -Format "yyyy-MM-dd"
    if($condition -eq "From"){
        return ($now -gt $faildate)
    }
    else{
        return ($now -lt $faildate)
    }
}

function Fail($reason){
    Write-Host "##vso[task.complete result=Failed;]Failure triggered. $reason" -ForegroundColor Red
}

function Pass(){
    Write-Host "##vso[task.complete result=Succeeded;]No failure triggered." -ForegroundColor Green
}

Trace-VstsEnteringInvocation $MyInvocation

try {
    [string] $failtype = Get-VstsInput -Name failtype -Require
    [string] $reason = Get-VstsInput -Name reason

    switch ($failtype)
    {
        "Always" {
            Write-Host "##vso[task.logissue type=error;]Always fail"
            Fail -reason $reason
        }
        "Date" {
			[string] $date = Get-VstsInput -Name date
			[string] $datecondition = Get-VstsInput -Name datecondition
            if(FailByDate -date $date -condition $datecondition){
                Write-Host "##vso[task.logissue type=error;]Fail by date: $datecondition $date"
				Fail -reason $reason
            }
            else{
				Write-Host "##vso[task.logissue type=warning;]Fail by date: $datecondition $date"
                Pass
            }
        }
        "Expression" {
			[string] $expression = Get-VstsInput -Name expression
            if(Invoke-Expression $expression){
				Write-Host "##vso[task.logissue type=error;]Fail by expression: $expression"
                Fail -reason $reason
            }
            else{
				Write-Host "##vso[task.logissue type=warning;]Fail by expression: $expression"
                Pass
            }
        }
        Default {
            throw "Unidentified fail type."
        }
    }
} 
catch {
    Write-Host "##vso[task.logissue type=error;]$Error[0]"
    Write-Host "##vso[task.complete result=Failed;]Unintentional failure. Error encountered. Defaulting to always fail." 
} 
finally {
	Trace-VstsLeavingInvocation $MyInvocation
}
