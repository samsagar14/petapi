Remove-Item apivar.txt -ErrorAction SilentlyContinue
Remove-Variable -Name "apivar" -ErrorAction SilentlyContinue
Remove-Variable -Name "messages" -ErrorAction SilentlyContinue

# get content of output xml and assign values to variables 

$xmlfiles = (Get-Item -Path .\NewmanResults\*.xml).Name
$messages = @()
$messagesSlack = @()
[INT]$totalsum = 0
[INT]$totalfail = 0
[INT]$totalpass = 0

for ($i=0; $i -lt $xmlfiles.Length ; $i++) {   
    
    [INT]$total = 0
    [INT]$fail = 0
    [INT]$pass = 0
    Remove-Variable -Name "testsuiteCount" -ErrorAction SilentlyContinue
    
    $file = $xmlfiles[$i]

    [xml]$outputxml = (Get-Content .\NewmanResults\$file)

    [INT]$testsuiteCount =  ($outputxml.testsuites.testsuite | Measure-Object).Count

    if ($testsuiteCount -gt 1) {

        for ($l=0; $l -lt $outputxml.testsuites.testsuite.Count ; $l++) {
    
            $total += $outputxml.testsuites.testsuite[$l].tests
      
        }

    } else {

        $total = $outputxml.testsuites.testsuite.tests        
    }

    [INT]$fail = (Select-Xml -Xml $outputxml -XPath "//failure" | Measure-Object).Count
    [INT]$pass = $total - $fail
    $filecollection = $file.Replace(".postman_collection.xml","")
    $filehtml = $file.Replace(".xml",".html")

    $message = '"' + $filecollection + ": Total: $total, Pass: $pass, Fail: $fail, Report: <a href=''>Open</a>" + '",'
    $messageslack = '"' + $filecollection + "\nTotal: $total, Pass: $pass, Fail: $fail, Report: <>" + '",'  
    $messages += $message
    $messagesSlack += $messageslack
    $totalsum += $total
    $totalfail += $fail
    $totalpass += $pass

# this HereString will be added to txt file later

$apivar += @"
API_FAILED = $totalfail
API_PASSED = $totalpass
API_TOTAL = $totalsum
MESSAGES = []
MESSAGESSLACK = []
MESSAGES += [
"@

$apivar += $messages + ']'
 
$apivar += @"
`
MESSAGESSLACK += [$messagesSlack
"@

$apivar += ']'

$apivar | Out-File apivar.txt -Encoding ascii