
#variables to create image
    $imagename = 'testimage'
    $serverID ='90ce0d19-7455-4ffa-a57f-3468afbd15c5'
    $endpoint = 'https://dfw.servers.api.rackspacecloud.com/v2'
    
#variables used to create server
    $flavor = 2
    $newservername = 'finaltest2'
    
#load ini
# This code assumes that no blank lines are in the file--a blank line will cause an early termination of the read loop
#ini values should not be in quotes it will break the request
# Confirm that the file exists on disk

$IniFile_NME="$PSScriptRoot\auth.ini"

dir $IniFile_NME

# Parse the file

$InputFile = [System.IO.File]::OpenText("$IniFile_NME")

while($InputRecord = $InputFile.ReadLine())
    {

        # Determine the position of the equal sign (=)

        $Pos = $InputRecord.IndexOf('=')
        

        # Determine the length of the record

        $Len = $InputRecord.Length
        

        # Parse the record

        $Variable_NME = $InputRecord.Substring(1, $Pos -1)
        $VariableValue_STR = $InputRecord.Substring($Pos + 1, $Len -$Pos -1)

        # Create a new variable based on the parsed information

        new-variable -name $Variable_NME -value $VariableValue_STR -force
        get-variable -name $Variable_NME
    }
#close ini
$InputFile.Close()

#authenticate and return ddi and token
#string
$string = '{"auth" : {"RAX-KSKEY:apiKeyCredentials" : {"username" : "$user", "apiKey" : "$apikey"}}}'

#expands variables within string
$post = $ExecutionContext.InvokeCommand.ExpandString($string) 

#sets request to variable to be used later
$request = Invoke-RestMethod -uri $authurl -Method Post -Body $post -ContentType application/json

$token = $request.access.token.id 
$custDDI = $request.access.token.tenant.id

#reqest to create image
$string = '{
    "createImage" : {
    "name" : "$imagename",
    "metadata": {
    "ImageType": "test"
    }
    }
    }'
$string = $ExecutionContext.InvokeCommand.ExpandString($string)
$htoken = @{"X-Auth-Token" = "$token"}
$url = '$endpoint/$custDDI/servers/$serverID/action'
$url = $ExecutionContext.InvokeCommand.ExpandString($url)
$request = Invoke-WebRequest -uri $url -Method Post -Body $string -ContentType application/json -Headers $htoken
$request  |Format-List -Property RawContent

#request to get image status
$url2 = '$endpoint/$custDDI/images/detail?server=$serverID&name=$imagename'
$url2 = $ExecutionContext.InvokeCommand.ExpandString($url2)
$request2 = Invoke-RestMethod -uri  $url2 -Headers $htoken
$name = $request2.images.name
$id = $request2.images.id
$created = $request2.images.created
$status = $request2.images.status
$progress = $request2.images.progress
$imageID = $request2.images.id
$string2 = '{
    "server" : {
    "name" : "$newservername",
    "imageRef" : "$imageID",
    "flavorRef" : "$flavor"
    }
    }'

'Name: ' + $name
'ID: ' + $id
'Created: ' + $created
'Status: ' + $status
'Progress: ' + $progress

#loop to check image status and then build server
$timeout = new-timespan -Minutes 60
$sw = [diagnostics.stopwatch]::StartNew()
while ($sw.elapsed -lt $timeout){
    if (($progress -eq 100) -and ($status -eq "Active")){
        "Complete"
    
    $string2 = $ExecutionContext.InvokeCommand.ExpandString($string2)
    #request to create server
    
    $url3 = '$endpoint/$custDDI/servers'
    $url3 = $ExecutionContext.InvokeCommand.ExpandString($url3)
    $request3 = Invoke-RestMethod -uri  $url3 -Method POST -Body $string2 -ContentType application/json -Headers $htoken
    $newserverid = $request3.server.id
    $adminpass = $request3.server.adminPass

    "Name: " + $newservername
    "Server ID: " + $newserverid
    "Admin Pass: " + $adminpass

    "Please wait while we get the IP"
    Start-Sleep -s 90
    #request to create server
    $url4 = '$endpoint/$custDDI/servers/$newserverID'
    $url4 = $ExecutionContext.InvokeCommand.ExpandString($url4)
    $request4 = Invoke-RestMethod -uri $url4 -Headers $htoken
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
    
    #reqeust to get image status
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
