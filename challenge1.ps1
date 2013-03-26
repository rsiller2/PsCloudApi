Import-Module $PSScriptRoot\get_token.psm1
Get-Token

$imageID = '8a3a9f96-b997-46fd-b7a8-a9e740796ffd'#Ubuntu12
$flavor = 2
$servercount = 2
$commonname = 'apitest'
$endpoint = 'https://dfw.servers.api.rackspacecloud.com/v2'
$i = 1

#Create Object Template and Array
$objProto = New-Object PSObject
$objProto | Add-Member –MemberType NoteProperty –Name Name –Value $null
$objProto | Add-Member –MemberType NoteProperty –Name ID –Value $null
$objProto | Add-Member –MemberType NoteProperty –Name AdminPass –Value $null
$objProto | Add-Member –MemberType NoteProperty –Name PublicIP –Value $null
$objProto | Add-Member –MemberType NoteProperty –Name PrivateIP –Value $null
$objArray = @()

#start of while loop
while ($i -le $servercount){
$name = $commonname + $i
$string0 = '{
    "server" : {
        "name" : "$name",
        "imageRef" : "$imageID",
        "flavorRef" : "$flavor"
    }
}'



$htoken = @{"X-Auth-Token" = "$token"}
$url = '$endpoint/$custDDI/servers'
$url = $ExecutionContext.InvokeCommand.ExpandString($url)
$string = $ExecutionContext.InvokeCommand.ExpandString($string0)

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
$i++}# end of while loop

"Please wait while we get the IP"
Start-Sleep -s 45 #need to add a retry if any IPs come back blank will probably need to add them to an array
#start of while loop to get IP
$j = 1
while ($j -le $servercount){
$url2 = $url + '/detail?name='+ '$commonname' + '$j'
$url2 = $ExecutionContext.InvokeCommand.ExpandString($url2)
$request2 = Invoke-RestMethod -uri  $url2 -Headers $htoken

"name: "+ $request2.servers.name
"id: "+ $request2.servers.id
"Public: " + $request2.servers.addresses.public.addr
"Prifate: " + $request2.servers.addresses.private.addr
"flavor: "+ $request2.servers.flavor.id + " progress: " + $request2.servers.progress
"`n"

#junk will later try to add to the array of objects
#$objArray[i-1].PublicIP = $PublicIP
#$objArray[i-1].PrivateIP = $PrivateIP
#$arrayname = $objArray.name
$j++
}