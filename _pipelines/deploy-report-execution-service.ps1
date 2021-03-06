[cmdletbinding()]
param
(
    [string]$ChocolateySourceUrl = "https://emdat.pkgs.visualstudio.com/_packaging/Chocolatey/nuget/v2",

    [string]$ChocolateyAccessToken = $env:SYSTEM_ACCESSTOKEN,    
    
    [string]$LogFolder = $env:EMDAT_ENV_PATHS_LOGS,      

    [string]$EventLogSource = "Emdat Report Execution Service",
    [string]$LogFolderName = "InVision.SchedulingService",  
      
    [String]$ServiceName = "Emdat Report Execution Service",
    [String]$PathToExecutable = "C:\Program Files\Emdat\Reporting\InVision.SchedulingService.exe",
    [String]$PathToTemp = "C:\Program Files\Emdat\Reporting\Temp",
    [String]$ExecutableArgs = "",
    [String]$DisplayName = "Emdat Report Execution Service",
    [String]$StartMode = $env:Service_StartMode,
    [Boolean]$DesktopInteract = $false,
    [String]$StartName = $env:Emdat_Env_Credentials_ReportExec_Username,
    [String]$StartPassword = $env:Emdat_Env_Credentials_ReportExec_Password,
    [Boolean]$UseInstallUtil = $false,
    [String]$InstallUtilExePath = "",

    [string]$MSDeployPackagesFolder = (join-path $env:SYSTEM_DEFAULTWORKINGDIRECTORY "ReportSchedulingService/packages/InVision.SchedulingService/"),
    [string]$MSDeployPackageFile = "InVision.SchedulingService.zip",
    [string]$MSDeployParametersFile = "MSDeployParameters.xml"
)   

###############################################################################
# install chocolatey packages
###############################################################################
& choco upgrade webdeploy64 --version=1.0.1 --source=$ChocolateySourceUrl --user=dontmatter --password=$ChocolateyAccessToken --confirm --no-progress

###############################################################################
# install configureService module
###############################################################################
import-module (join-path $PSScriptRoot "psmodules\ConfigureService.ps1")

###############################################################################
# uninstall service
###############################################################################
$unInstallParams = @{
    ServiceName         = $ServiceName;
    PathToExecutable    = $PathToExecutable;
    UseInstallUtil      = $UseInstallUtil;
    InstallUtilExePath  = $InstallUtilExePath;
}
Uninstall-Service @unInstallParams

###############################################################################
# deploy the report execution service
###############################################################################
$deployServiceParams = @{
    EventLogSource                 = $EventLogSource;
    LogFolder                      = (join-path $LogFolder $LogFolderName);
    PathToExecutable                = $PathToExecutable;
    MSDeployPackageFile            = (join-path $MSDeployPackagesFolder $MSDeployPackageFile);
    MSDeployParametersFile         = (join-path $MSDeployPackagesFolder $MSDeployParametersFile);
}
& (join-path $PSScriptRoot "deploy-serviceapplication.ps1") @deployServiceParams

###############################################################################
# install and configure service
###############################################################################
$InstallParams = @{
    ServiceName         = $ServiceName;
    PathToExecutable    = $PathToExecutable;
    ExecutableArgs      = $ExecutableArgs;
    DisplayName         = $DisplayName;
    StartMode           = $StartMode;
    DesktopInteract     = $DesktopInteract;
    StartName           = $StartName;
    StartPassword       = $StartPassword;
    UseInstallUtil      = $UseInstallUtil;
    InstallUtilExePath  = $InstallUtilExePath;      
}
Install-Service @InstallParams

###############################################################################
# create temp folder
###############################################################################
if ($PathToTemp) {
    Write-Host "Creating temp folder: $PathToTemp"
    New-Item -Path $PathToTemp -ItemType Directory -Force
}

###############################################################################
# start the service
###############################################################################
if($StartMode -ieq "Automatic") {
    Write-Host "Starting service: $ServiceName"
    Start-Service -Name $ServiceName
}
else {
    Write-Host "Service start mode is $StartMode. Service '$ServiceName' will not be started."
}