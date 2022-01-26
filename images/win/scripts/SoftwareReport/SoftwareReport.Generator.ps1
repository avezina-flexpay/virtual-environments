$global:ErrorActionPreference = "Stop"
$global:ProgressPreference = "SilentlyContinue"
$ErrorView = "NormalView"
Set-StrictMode -Version Latest

Import-Module MarkdownPS
Import-Module (Join-Path $PSScriptRoot "SoftwareReport.Browsers.psm1") -DisableNameChecking
Import-Module (Join-Path $PSScriptRoot "SoftwareReport.CachedTools.psm1") -DisableNameChecking
Import-Module (Join-Path $PSScriptRoot "SoftwareReport.Common.psm1") -DisableNameChecking
Import-Module (Join-Path $PSScriptRoot "SoftwareReport.Helpers.psm1") -DisableNameChecking
Import-Module (Join-Path $PSScriptRoot "SoftwareReport.Tools.psm1") -DisableNameChecking
Import-Module (Join-Path $PSScriptRoot "SoftwareReport.VisualStudio.psm1") -DisableNameChecking

$markdown = ""

$OSName = Get-OSName
$markdown += New-MDHeader "$OSName" -Level 1

$OSVersion = Get-OSVersion
$markdown += New-MDList -Style Unordered -Lines @(
    "$OSVersion"
    "Image Version: $env:IMAGE_VERSION"
)

if ((Test-IsWin19) -or (Test-IsWin22))
{
    $markdown += New-MDHeader "Enabled windows optional features" -Level 2
    $markdown += New-MDList -Style Unordered -Lines @(
        "Windows Subsystem for Linux [WSLv1]"
    )
}

$markdown += New-MDHeader "Installed Software" -Level 2
$markdown += New-MDHeader "Language and Runtime" -Level 3
$languageTools = @(
    (Get-BashVersion)
    (Get-JuliaVersion),
    (Get-LLVMVersion),
    (Get-NodeVersion),
    (Get-PerlVersion)
    (Get-PythonVersion)
)
$markdown += New-MDList -Style Unordered -Lines ($languageTools | Sort-Object)

$packageManagementList = @(
    (Get-ChocoVersion),
    (Get-HelmVersion),
    (Get-NPMVersion),
    (Get-NugetVersion),
    (Get-PipVersion),
    (Get-VcpkgVersion),
    (Get-YarnVersion)
)

$markdown += New-MDHeader "Package Management" -Level 3
$markdown += New-MDList -Style Unordered -Lines ($packageManagementList | Sort-Object)

$markdown += New-MDHeader "Environment variables" -Level 4
$markdown += Build-PackageManagementEnvironmentTable | New-MDTable
$markdown += New-MDNewLine

$markdown += New-MDList -Style Unordered -Lines ($projectManagementTools | Sort-Object)

$markdown += New-MDHeader "Tools" -Level 3
$toolsList = @(
    (Get-7zipVersion),
    (Get-Aria2Version),
    (Get-AzCopyVersion),
    (Get-DockerVersion),
    (Get-DockerComposeVersion),
    (Get-DockerWincredVersion),
    (Get-GHCVersion),
    (Get-GitVersion),
    (Get-GitLFSVersion),
    (Get-KubectlVersion),
    (Get-MinGWVersion),
    (Get-OpenSSLVersion),
    (Get-PackerVersion),
    (Get-VSWhereVersion),
    (Get-WixVersion),
    (Get-YAMLLintVersion)
)
if ((Test-IsWin16) -or (Test-IsWin19)) {
    $toolsList += @(
        (Get-ParcelVersion)
    )
}
$markdown += New-MDList -Style Unordered -Lines ($toolsList | Sort-Object)

$markdown += New-MDHeader "CLI Tools" -Level 3
$cliTools = @(
    (Get-AWSCLIVersion),
    (Get-AWSSAMVersion),
    (Get-AWSSessionManagerVersion),
    (Get-AzureCLIVersion),
    (Get-AzureDevopsExtVersion),
    (Get-GHVersion),
    (Get-HubVersion)
)
if ((Test-IsWin16) -or (Test-IsWin19)) {
    $cliTools += @(
        (Get-CloudFoundryVersion)
    )
}
$markdown += New-MDList -Style Unordered -Lines ($cliTools | Sort-Object)

$markdown += New-MDHeader "Browsers and webdrivers" -Level 3
$markdown += New-MDList -Style Unordered -Lines @(
    (Get-BrowserVersion -Browser "chrome")
    (Get-BrowserVersion -Browser "edge")
)

$markdown += New-MDNewLine

$markdown += New-MDHeader "Shells" -Level 3
$markdown += Get-ShellTarget
$markdown += New-MDNewLine

$markdown += New-MDHeader "MSYS2" -Level 3
$markdown += "$(Get-PacmanVersion)" | New-MDList -Style Unordered
$markdown += New-MDHeader "Notes:" -Level 5
$reportMsys64 = @'
```
Location: C:\msys64

Note: MSYS2 is pre-installed on image but not added to PATH.
```
'@
$markdown += New-MDParagraph -Lines $reportMsys64

if (Test-IsWin19)
{
    $markdown += New-MDHeader "BizTalk Server" -Level 3
    $markdown += "$(Get-BizTalkVersion)" | New-MDList -Style Unordered
}

$markdown += New-MDHeader "Cached Tools" -Level 3
$markdown += (Build-CachedToolsMarkdown)

$markdown += New-MDHeader "Database tools" -Level 3
$markdown += New-MDList -Style Unordered -Lines (@(
    (Get-AzCosmosDBEmulatorVersion),
    (Get-DacFxVersion)
    (Get-SQLPSVersion)
    ) | Sort-Object
)

$vs = Get-VisualStudioVersion
$markdown += New-MDHeader "$($vs.Name)" -Level 3
$markdown += $vs | New-MDTable
$markdown += New-MDNewLine

$markdown += New-MDHeader "Workloads, components and extensions:" -Level 4
$markdown += ((Get-VisualStudioComponents) + (Get-VisualStudioExtensions)) | New-MDTable
$markdown += New-MDNewLine

$markdown += New-MDHeader "Microsoft Visual C++:" -Level 4
$markdown += Get-VisualCPPComponents | New-MDTable
$markdown += New-MDNewLine

$markdown += New-MDHeader ".NET Core SDK" -Level 3
$sdk = Get-DotnetSdks
$markdown += "``Location $($sdk.Path)``"
$markdown += New-MDNewLine
$markdown += New-MDList -Lines $sdk.Versions -Style Unordered

$markdown += New-MDHeader ".NET Core Runtime" -Level 3
Get-DotnetRuntimes | Foreach-Object {
    $path = $_.Path
    $versions = $_.Versions
    $markdown += "``Location: $path``"
    $markdown += New-MDNewLine
    $markdown += New-MDList -Lines $versions -Style Unordered
}

$markdown += New-MDHeader ".NET Framework" -Level 3
$frameworks = Get-DotnetFrameworkTools
$markdown += "``Type: Developer Pack``"
$markdown += New-MDNewLine
$markdown += "``Location $($frameworks.Path)``"
$markdown += New-MDNewLine
$markdown += New-MDList -Lines $frameworks.Versions -Style Unordered

$markdown += New-MDHeader ".NET tools" -Level 3
$tools = Get-DotnetTools
$markdown += New-MDList -Lines $tools -Style Unordered

# PowerShell Tools
$markdown += New-MDHeader "PowerShell Tools" -Level 3
$markdown += New-MDList -Lines (Get-PowershellCoreVersion) -Style Unordered

$markdown += New-MDHeader "Azure Powershell Modules" -Level 4
$markdown += Get-PowerShellAzureModules | New-MDTable
$reportAzPwsh = @'
```
Azure PowerShell module 2.1.0 and AzureRM PowerShell module 2.1.0 are installed
and are available via 'Get-Module -ListAvailable'.
All other versions are saved but not installed.
```
'@
$markdown += New-MDParagraph -Lines $reportAzPwsh

$markdown += New-MDHeader "Powershell Modules" -Level 4
$markdown += Get-PowerShellModules | New-MDTable
$markdown += New-MDNewLine

# Docker images section
$cachedImages = Get-CachedDockerImagesTableData
if ($cachedImages) {
    $markdown += New-MDHeader "Cached Docker images" -Level 3
    $markdown += $cachedImages | New-MDTable
}

Test-BlankElement -Markdown $markdown
$markdown | Out-File -FilePath "C:\InstalledSoftware.md"
