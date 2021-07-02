$location = Get-Location

Add-Type -AssemblyName System.Windows.Forms
$FileBrowser = New-Object System.Windows.Forms.OpenFileDialog
$FileBrowser.Title = "Открыть txt файл со списком хостов для проверки"
$FileBrowser.Filter = "Текстовые файлы (*.txt)|*.txt|Все файлы (*.*)|*.*"
$null = $FileBrowser.ShowDialog()
$host_list_path = $FileBrowser.FileName.Clone()

$PsBrowser = New-Object System.Windows.Forms.OpenFileDialog
$PsBrowser.Title = "Открыть psexec.exe"
$PsBrowser.Filter = "Исполняемые файлы (*.exe)|*.exe|Все файлы (*.*)|(*.*)"
$null = $PsBrowser.ShowDialog()
$ps_path = $PsBrowser.FileName

$date = Get-Date -Format "dd-MM-yyyy"
$date_time = Get-Date -Format "HH-mm-ss dd-MM-yyyy"

$pc_avail = [System.Collections.Generic.List[string]]::new()
New-Item -Path $location -Name "$date_time.txt" | Out-Null
$out_file = "$location\$date_time.txt"

if($host_list_path.Length -eq 0){
    Write-Host "Пустой файл списка хостов"
    exit
}

if($ps_path.Length -eq 0){
    Write-Host "Не выбран psexec.exe"
    exit
}

if($host_list_path.Substring($host_list_path.Length - 3) -ne "txt"){
    Write-Host "Не верный тип файла списка хостов (не txt)"
    exit
}

if($ps_path.Substring($ps_path.Length - 10).ToLower() -ne "psexec.exe"){
    Write-Host "Не выбран файл psexec.exe"
    exit
}

function test_psexec_connect($val){
    
    $pc_name=$val;
    $test_psexec="/C psexec \\$pc_name -acceptula -s cmd /C ""copy Nul C:\Users\Public\Downloads\Test_connect_psexec.txt""";         
    
    start-process cmd.exe $test_psexec  -WindowStyle Hidden -Wait ;

    if(Test-Path "\\$pc_name\C$\Users\Public\Downloads\Test_connect_psexec.txt"){
        Remove-Item -Path "\\$pc_name\C$\Users\Public\Downloads\Test_connect_psexec.txt" -Force;
        return $true;
    }else{
        return $false; 
    }   
}


foreach($line in Get-Content $host_list_path){
    
    $pc_name = $line.Trim()
    if((Test-NetConnection $pc_name) -and (Test-Path \\$pc_name\c$)){
        $pc_avail.Add($pc_name)
        Add-Content $out_file "$pc_name`tДОСТУПЕН"  -NoNewline
        $pstart = Get-Date -Format "HH-mm dd-MM-yyyy"
        
        if(-Not (test_psexec_connect($pc_name))){
            Add-Content $out_file "`tpsexec`tНЕ ДОСТУПЕН"
            continue
        }else{
            Add-Content $out_file "`tpsexec`tДОСТУПЕН" -NoNewline
        }

        if(-Not (Test-Path "\\$pc_name\c$\Program Files\DrWeb\dwscanner.exe")){
            Add-Content $out_file "`tdwscanner`tНЕ ДОСТУПЕН"
            continue
        }else{
            Add-Content $out_file "`tdwscanner`tДОСТУПЕН" -NoNewline
        }

        Add-Content $out_file "`tпроверка начата в $pstart"
        New-Item -ItemType directory -Path \\$pc_name\c$\Distr -Force | Out-Null
        New-Item -ItemType directory -Path \\$pc_name\c$\Distr\DoctorWebScanResults -Force | Out-Null
        #Start-Process $ps_path "\\$pc_name cmd /C `"ping \\ppp-ms165-usc -t`"" -WindowStyle Hidden 
        Start-Process "$ps_path" "\\$pc_name cmd /C `"`"%programfiles%\drweb\dwscanner.exe`" /QUIT /FULL /AA /RA:`"C:\distr\DoctorWebScanResults\$date.log`" `"" -WindowStyle Hidden
    } else {
        Add-Content $out_file "$pc_name`tНЕ ДОСТУПЕН"
    }

}

$process = "psexec.exe"

<#while(1){
    Write-Host "Узнать состояние проверки"
    $enter = Read-Host
    switch($enter){
        
        "" {
            $pc_avail.ForEach({
                param ($line)
                if((Get-WmiObject Win32_Process -Filter "name = '$process'" | Select-Object CommandLine | Out-String -Stream | Select-String -Pattern $line)){
                    Write-Host "$line`tв работе"
                }else{
                    write-host "$line`tне в работе"
                }
            })
        }
    }
    
}#>
