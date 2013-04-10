#variables

$imageID = '8a3a9f96-b997-46fd-b7a8-a9e740796ffd'#Ubuntu12
$flavor = 2
$servercount = 2
$commonname = 'finaltest'
$endpoint = 'https://dfw.servers.api.rackspacecloud.com/v2'
$i = 1

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

        new-variable -name $Variable_NME -value $VariableValue_STR 
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


#Create Object Template and Array
$objProto = New-Object PSObject
$objProto | Add-Member –MemberType NoteProperty –Name Name –Value $null
$objProto | Add-Member –MemberType NoteProperty –Name ID –Value $null
$objProto | Add-Member –MemberType NoteProperty –Name AdminPass –Value $null
$objProto | Add-Member –MemberType NoteProperty –Name PublicIP –Value $null
$objProto | Add-Member –MemberType NoteProperty –Name PrivateIP –Value $null
$objArray = @()

#start of while loop to build servers
while ($i -le $servercount){
    $name = $commonname + $i
    $string = '{
    "server" : {
        "name" : "$name",
        "imageRef" : "$imageID",
        "flavorRef" : "$flavor"
    }
    }'

    $htoken = @{"X-Auth-Token" = "$token"}
    $url = '$endpoint/$custDDI/servers'
    $url = $ExecutionContext.InvokeCommand.ExpandString($url)
    $string = $ExecutionContext.InvokeCommand.ExpandString($string)

    $request = Invoke-RestMethod -uri  $url -Method POST -Body $string -ContentType application/json -Headers $htoken
    $serverid = $request.server.id
    $adminpass = $request.server.adminPass

    "Name: " + $name
    "Server ID: " + $serverid
    "Admin Pass: " + $adminpass

    #create temp object and insert current info
    $objTemp = $objProto | Select-Object *
    $objTemp.Name = $name
    $objTemp.ID = $serverid
    $objTemp.AdminPass = $adminpass
    $objTemp.PublicIP = $pubicIP
    $objTemp.PrivateIP = $privateIP

    #add object to array of objects
    $objArray += $objTemp
    $i++}
# end of while loop

"Please wait while we get the IP"

Start-Sleep -s 90 
#start of while loop to get IP
$j = 1
while ($j -le $servercount){
    $url2 = $url + '/detail?name='+ '$commonname' + '$j'
    $url2 = $ExecutionContext.InvokeCommand.ExpandString($url2)
    $request2 = Invoke-RestMethod -uri  $url2 -Headers $htoken

    "name: "+ $request2.servers.name
    "id: "+ $request2.servers.id
    "Public: " + $request2.servers.addresses.public.addr
    "Private: " + $request2.servers.addresses.private.addr
    "flavor: "+ $request2.servers.flavor.id + " progress: " + $request2.servers.progress
    "`n"
    $j++
}
