<#
.SYNOPSIS
Builds a MadCap Flare project using madbuild.exe.

.DESCRIPTION
Builds a product help documentation project written using MadCap Flare. Can build only certain elements of the MadCap Flare project by specifying a target or batch target.

.PARAMETER FlareProjectFile
The MadCap Flare project file to be built.

.PARAMETER Target
The name of the target that controls what portions of the MadCap Flare project are built.

.PARAMETER BatchTarget
The name of the batch target that controls what portions of the MadCap Flare project are built.

.NOTES
The path to the MadCap command-line build executable (madbuild.exe) needs to be in the PATH environment variable on the system this script will run on.

.EXAMPLE
.\Invoke-FlareBuild.ps1 -FlareProjectFile .\MyProductHelp.flprj

Description
-----------
The MadCap Flare project file .\MyProductHelp.flprj is built, involving all targets in the project.
Any warnings generated during the build will not be treated as errors (i.e. build succeeds even if there are warnings).

.EXAMPLE
.\Invoke-FlareBuild.ps1 -FlareProjectFile .\MyProductHelp.flprj -Target build

Description
-----------
The MadCap Flare project file .\MyProductHelp.flprj is built based on the configurations specified by the "build" target (.\Project\Targets\build.fltar).
Any warnings generated during the build will not be treated as errors (i.e. build succeeds even if there are warnings).

.EXAMPLE
.\Invoke-FlareBuild.ps1 -FlareProjectFile .\MyProductHelp.flprj -BatchTarget batch-build

Description
-----------
The MadCap Flare project file .\MyProductHelp.flprj is built based on the configurations specified by the "batch-build" batch target (.\Project\Targets\batch-build.flbat).
Any warnings generated during the build will not be treated as errors (i.e. build succeeds even if there are warnings).

.EXAMPLE
.\Invoke-FlareBuild.ps1 -FlareProjectFile .\MyProductHelp.flprj -BatchTarget build -TreatWarningAsErrors

Description
-----------
The MadCap Flare project file MyProductHelp.flprj is built based on the configurations specified by the "batch-build" batch target (.\Project\Targets\batch-build.flbat).
Any warnings generated during the build will cause the build to fail.
#>
[CmdletBinding()]
Param
(
    [Parameter(Mandatory=$True, ParameterSetName='All')]
    [Parameter(Mandatory=$True, ParameterSetName='Target')]
    [Parameter(Mandatory=$True, ParameterSetName='Batch')]
    [ValidateScript({Test-Path $_ -PathType Leaf})]
    [ValidateScript({![string]::IsNullOrWhitespace($_)})]
    [string]$FlareProjectFile,

    [Parameter(Mandatory=$True, ParameterSetName='Target')]
    [ValidateScript({![string]::IsNullOrWhitespace($_)})]
    [string]$Target,

    [Parameter(Mandatory=$True, ParameterSetName='Batch')]
    [ValidateScript({![string]::IsNullOrWhitespace($_)})]
    [string]$BatchTarget,

    [Switch]$TreatWarningAsErrors
)

<#
.SYNOPSIS
Gets a build status message based on a supplied build status code.

.DESCRIPTION
Gets a build status message based on a supplied build status code.

.NOTES
The list of possible build codes and their applicable messages can be found in the "ERRORLEVEL GLOBAL VARIABLE" section of http://help.madcapsoftware.com/flare2017/Content/Output/Building_Targets_Using_the_Command_Line.htm.

.LINK
http://help.madcapsoftware.com/flare2017/Content/Output/Building_Targets_Using_the_Command_Line.htm

.PARAMETER BuildStatusCode
The build status integer value.

.EXAMPLE
Get-BuildStatusMessage -BuildStatusCode 0

Returns "Success"

.EXAMPLE
Get-BuildStatusMessage -BuildStatusCode 3

Returns "Build completed with compiler warnings"

.EXAMPLE
Get-BuildStatusMessage -BuildStatusCode -1

Returns "Application error - Something critical has forced Flare to close"
#>
Function Get-BuildStatusMessage
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$True)]
        [int]$BuildStatusCode
    )

    $hashTable = @{
        0 = "Success";
        1 = "One or more Target Builds failed - One or more of the targets failed to compile";
        2 = "One or more Publish Targets failed - One or more of the targets failed to compile";
        3 = "Build completed with compiler warnings";
        4 = "Compiler reported errors";
        5 = "Failed to process one or more project import files";
        6 = "Failed to load topic";
        7 = "Missing linked file";
        -1 = "Application error - Something critical has forced Flare to close";
        1000 = "Zero arguments passed in";
        1001 = "Show Help";
        2000 = "Unlicensed Flare";
        2001 = "Flare not activated";
        2002 = "Invalid license activation code";
        2003 = "License expired";
        2004 = "Evaluation expired";
        2005 = "Trial expired";
        2006 = "Project does not exist";
        2007 = "Batch file does not exist";
        2008 = "Floating session request failed";
        2009 = "Floating session timeout";
        2010 = "Target not found"
    }

    $reportStatusCode = $BuildStatusCode

    if (!$TreatWarningAsErrors -and $BuildStatusCode -eq 3)
    {
        $reportStatusCode = 0
    }

    if ($hashTable.ContainsKey($reportStatusCode))
    {
        "Build finished with status code {0} ({1})" -f $reportStatusCode, $hashTable[$reportStatusCode]
    }
    else
    {
        "Build failed with unrecosgnized status code {0}" -f $reportStatusCode
    }
}

$buildArguments = "-project $FlareProjectFile"

if ($Target -and $BatchTarget)
{
    Write-Error "Target and BatchTarget parameters are mutually exclusive -> Cannot build both a Target and a Batch Target. Exiting..."
    exit 1
}
elseif ($Target)
{
    Write-Host "Target specified -> Building '$Target.fltar'..."
    $buildArguments += " -target $Target"
}
elseif ($BatchTarget)
{
    Write-Host "Batch Target specified -> Building '$BatchTarget.flbat'..."
    $buildArguments += " -batch $BatchTarget"
}
else
{
    Write-Host "No Target or Batch Target specified -> Building all targets in projects..."
}

# By specifying the NoNewWindow switch, the current session will receive the output stream from madbuild.exe
$process = Start-Process -FilePath madbuild.exe -ArgumentList $buildArguments -PassThru -Wait -NoNewWindow

Get-BuildStatusMessage -BuildStatusCode $process.ExitCode

if (!$TreatWarningAsErrors -and $process.ExitCode -eq 3)
{
    exit 0
}
else
{
    exit $process.ExitCode
}
