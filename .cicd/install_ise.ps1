<#
.SYNOPSIS
	Install ISE Eiffel tools.

.DESCRIPTION
	Install ISE Eiffel tools.

.PARAMETER CiTool
	CI tool (azure, github, gitlab).

.EXAMPLE
	# Install ISE Eiffel tools from the GitHub Actions pipeline:
	install_ge.ps1 github

.NOTES
	Copyright: "Copyright (c) 2021, Eric Bezault and others"
	License: "MIT License"
#>

param
(
	[Parameter(Mandatory=$true)]
	[ValidateSet("azure", "github", "gitlab")] 
	[string] $CiTool
)

. "$PSScriptRoot/before_script.ps1" $CiTool

$GOBO_CI_ISE_VERSION = "21.11"
$GOBO_CI_ISE_REVISION = "rev_106046"

switch ($GOBO_CI_OS) {
	"linux" {
		$env:ISE_PLATFORM = "linux-x86-64"
		$env:ISE_C_COMPILER = "gcc"
		$GOBO_CI_ISE_ARCHIVE_EXTENSION = ".tar.bz2"
	}
	"macos" {
		$env:ISE_PLATFORM = "macosx-x86-64"
		$env:ISE_C_COMPILER = "clang"
		$GOBO_CI_ISE_ARCHIVE_EXTENSION = ".tar.bz2"
	}
	"windows" {
		$env:ISE_PLATFORM = "win64"
		$env:ISE_C_COMPILER = "msc_vc140"
		$GOBO_CI_ISE_ARCHIVE_EXTENSION = ".7z"
	}
}

$GOBO_CI_ISE_ARCHIVE_FILENAME = "Eiffel_${GOBO_CI_ISE_VERSION}_${GOBO_CI_ISE_REVISION}-$env:ISE_PLATFORM$GOBO_CI_ISE_ARCHIVE_EXTENSION"

Invoke-RestMethod -Method Get -Uri "https://ftp.eiffel.com/pub/beta/nightly/$GOBO_CI_ISE_ARCHIVE_FILENAME" -OutFile "$env:GOBO/$GOBO_CI_ISE_ARCHIVE_FILENAME"
if ($GOBO_CI_OS -eq "windows") {
	Install-Module -Name 7Zip4PowerShell -Force
	Expand-7Zip -ArchiveFileName "$env:GOBO/$GOBO_CI_ISE_ARCHIVE_FILENAME" -TargetPath "$env:GOBO"
} else {
	tar -x -p --bzip2 -f "$env:GOBO/$GOBO_CI_ISE_ARCHIVE_FILENAME"
}
Remove-Item "$env:GOBO/$GOBO_CI_ISE_ARCHIVE_FILENAME"

$env:ISE_EIFFEL = "$env:GOBO/Eiffel_$GOBO_CI_ISE_VERSION"
$env:PATH = "$env:PATH$([IO.Path]::PathSeparator)$env:ISE_EIFFEL/studio/spec/$env:ISE_PLATFORM/bin"

# Use 'ecb' by default to run ISE Eiffel compiler.
# It runs faster and does not require GTK to be installed on Linux and MacOS.
# The generated EIFGEN is not compatible with 'ec', but this is not a problem
# here since we discard the EIFGEN at the end of the compilation.
$env:EC_EXECUTABLE="ecb"

# Make sure that we are using our version of the Gobo tools.
Remove-Item  "$env:ISE_EIFFEL/library/gobo/spec" -Recurse -Force

ecb -version
