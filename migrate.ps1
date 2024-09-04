# 脚本以 UTF8-BOM 编码格式保存，以兼容 Powershell7 和旧版本的 Powershell

# 设置数据库连接参数
$sourceHost = 'localhost'
$sourcePort = '3306'
$sourceUser = 'root'
$sourcePass = ''

$targetHost = 'localhost'
$targetPort = '3307'
$targetUser = 'root'
$targetPass = ''

# $DBList = @('3dviewserver-ecityos', 'hc7.0', 'hw-platform', 'license_agent', 'nacos', 'xxl_job', 'test_agent')
$DBList = @('hc7.0')

function Save-MySQLDB {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]$DBHost,
        [Parameter(Mandatory)] [int]$DBPort,
        [Parameter(Mandatory)] [string]$DBUser,
        [Parameter(Mandatory)] [string]$DBPassword,
        [Parameter(Mandatory)] [string]$DBName,
        [Parameter(Mandatory)] [string]$BackupPath
    )
    
    try {
        Write-Host "开始备份数据库：$DBName..."

        & '.\mysqldump.exe' --default-character-set=utf8mb4 --skip-triggers -h $DBHost -P $DBPort -u $DBUser --password=$DBPassword -B $DBName -r $BackupPath\$DBName.sql
        
        Write-Host "数据库备份完成，备份文件位于: $BackupPath\$DBName.sql"
    } catch {
        Write-Error "备份过程中发生错误: $_"
    }
}

function Restore-MySQLDB {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]$BackupPath,
        [Parameter(Mandatory)] [string]$DBHost,
        [Parameter(Mandatory)] [int]$DBPort,
        [Parameter(Mandatory)] [string]$DBUser,
        [Parameter(Mandatory)] [string]$DBPassword,
        [Parameter(Mandatory)] [string]$DBName
    )
    
    # 使用Start-Process执行恢复命令，通过管道将备份文件内容传递给mysql命令
    try {
        Write-Host "开始恢复数据库：$DBName..."

        Get-Content "${BackupPath}\${DBName}.sql" -Encoding utf8 | 
        & '.\mysql.exe' --default-character-set=utf8mb4 -h $DBHost -P $DBPort -u $DBUser --password=$DBPassword

        Write-Host "数据库${DBName}恢复完成。"
    } catch {
        Write-Error "恢复过程中发生错误: $_"
    }
}

New-Item -Path 'dump' -ItemType Directory -Force

foreach ($sourceDB in $DBList) {
    Save-MySQLDB -DBHost $sourceHost -DBPort $sourcePort -DBUser $sourceUser -DBPassword $sourcePass -DBName $sourceDB -BackupPath 'dump'
}

foreach ($sourceDB in $DBList) {
    # Restore-MySQLDB -BackupPath 'dump' -DBHost $targetHost -DBPort $targetPort -DBUser $targetUser -DBPassword $targetPass -DBName $sourceDB
}

Write-Host -NoNewLine "迁移完成，按任意键退出..."
[void][System.Console]::ReadKey($true)
