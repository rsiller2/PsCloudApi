Import-Module $PSScriptRoot\get_token.psm1 
Get-Token
$imagename = 'testimage'
$serverID ='01f8d216-91cc-4910-b08e-c0cf5a4e51a1'
$string0 = '{
"createImage" : {
"name" : "$imagename",
"metadata": {
"ImageType": "test"
}
}
}'
$string = $ExecutionContext.InvokeCommand.ExpandString($string0)
$endpoint = 'https://dfw.servers.api.rackspacecloud.com/v2'
$htoken = @{"X-Auth-Token" = "$token"}
$url = '$endpoint/$DDI/servers/$serverID/action'
$url = $ExecutionContext.InvokeCommand.ExpandString($url)
$request = Invoke-WebRequest -uri $url -Method Post -Body $string -ContentType application/json -Headers $htoken
$request  |Format-List -Property RawContent

$url2 = '$endpoint/$DDI/images/detail?server=$serverID&name=$imagename'
$url2 = $ExecutionContext.InvokeCommand.ExpandString($url2)
$request2 = Invoke-RestMethod -uri  $url2 -Headers $htoken

$name = $request2.images.name
$id = $request2.images.id
$created = $request2.images.created
$status = $request2.images.status
$progress = $request2.images.progress

'Name: ' + $name
'ID: ' + $id
'Created: ' + $created
'Status: ' + $status
'Progress: ' + $progress

$timeout = new-timespan -Minutes 60
$sw = [diagnostics.stopwatch]::StartNew()
while ($sw.elapsed -lt $timeout){
    if (($progress -eq 100) -and ($status -eq "Active")){
        "Complete"
        
        $imageID = $request2.images.id
        $flavor = 2
        $newservername = 'apitestc2'
        $string1 = '{
        "server" : {
        "name" : "$newservername",
        "imageRef" : "$imageID",
        "flavorRef" : "$flavor"
        }
     }'
$string2 = $ExecutionContext.InvokeCommand.ExpandString($string1)
$url3 = '$endpoint/$custDDI/servers'
$url3 = $ExecutionContext.InvokeCommand.ExpandString($url3)
$request3 = Invoke-RestMethod -uri  $url3 -Method POST -Body $string2 -ContentType application/json -Headers $htoken
$newserverid = $request3.server.id
$adminpass = $request3.server.adminPass

"Name: " + $newservername
"Server ID: " + $newserverid
"Admin Pass: " + $adminpass

"Please wait while we get the IP"
Start-Sleep -s 45

$url4 = '$endpoint/$DDI/servers/$newserverID'
$url4 = $ExecutionContext.InvokeCommand.ExpandString($url4)
$request4 = Invoke-RestMethod -uri  $url4 -Headers $htoken
$newserver = $request4.server
"name: "+ $newserver.name
"status: "  + $newserver.status + " " + "progress: " + $newserver.progress
"id: "+ $newserver.id
"Public IP: "+ $newserver.addresses.public.addr
"Private IP: "+ $newserver.addresses.private.addr
"flavor: "+ $newserver.flavor.id + " metadata: " + $newserver.metadata
        return
          $sw.Stop()
        }
    else{
    $request2 = Invoke-RestMethod -uri  $url2 -Headers $htoken

$name = $request2.images.name
$id = $request2.images.id
$created = $request2.images.created
$status = $request2.images.status
$progress = $request2.images.progress
    
    write-host $status $progress}
        
    
    start-sleep -seconds 20
}
 
write-host "Timed out"
  $sw.Stop()
