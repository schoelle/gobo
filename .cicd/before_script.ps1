<#
.SYNOPSIS
	To be executed before CI/CD scripts.

.DESCRIPTION
	Check execution environment.
	Make sure that the C compiler is accessible.
	Set environment variables.

.PARAMETER CiTool
	CI tool (azure, github, gitlab).

.EXAMPLE
	# To be executed before CI/CD scripts on GitHub Actions pipeline:
	before_script.ps1 github

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

function Invoke-Environment {
	# See https://stackoverflow.com/questions/4384814/how-to-call-batch-script-from-powershell
	# See https://newbedev.com/how-to-call-batch-script-from-powershell
	<#
	.SYNOPSIS
		Invokes a command and imports its environment variables.

	.DESCRIPTION
		It invokes any cmd shell command (normally a configuration batch file) and
		imports its environment variables to the calling process. Command output is
		discarded completely. It fails if the command exit code is not 0. To ignore
		the exit code use the 'call' command.

	.PARAMETER Command
		Any cmd shell command, normally a configuration batch file.

	.EXAMPLE
		# Invokes Config.bat in the current directory or the system path
		Invoke-Environment Config.bat

	.EXAMPLE
		# Visual Studio environment: works even if exit code is not 0
		Invoke-Environment 'call "%VS100COMNTOOLS%\vsvars32.bat"'

	.EXAMPLE
		# This command fails if vsvars32.bat exit code is not 0
		Invoke-Environment '"%VS100COMNTOOLS%\vsvars32.bat"'
	#>
	param
	(
		[Parameter(Mandatory=$true)]
		[string] $Command
	)
	cmd /c "$Command > nul 2>&1 && set" | .{process{
		if ($_ -match '^([^=]+)=(.*)') {
			[System.Environment]::SetEnvironmentVariable($matches[1], $matches[2])
		}
	}}
}

switch ($CiTool) {
	"azure" {
		$env:GOBO = $env:BUILD_REPOSITORY_LOCALPATH
		switch ($env:AGENT_OS) {
			"Linux" {
				$GOBO_CI_OS = "linux"
			}
			"Darwin" {
				$GOBO_CI_OS = "macos"
			}
			"Windows_NT" {
				$GOBO_CI_OS = "windows"
				# Setting the environment variables for `cl`.
				Invoke-Environment('"C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\VC\Auxiliary\Build\vcvarsx86_amd64.bat"')
			}
			default {
				Write-Error "Platform not supported: $env:AGENT_OS"
				exit 1
			}
		}
	}
	"github" {
		$env:GOBO = $env:GITHUB_WORKSPACE
		switch ($env:RUNNER_OS) {
			"Linux" {
				$GOBO_CI_OS = "linux"
			}
			"MacOS" {
				$GOBO_CI_OS = "macos"
			}
			"Windows" {
				$GOBO_CI_OS = "windows"
				# Setting the environment variables for `cl`.
				Invoke-Environment('"C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\VC\Auxiliary\Build\vcvarsx86_amd64.bat"')
			}
			default {
				Write-Error "Platform not supported: $env:RUNNER_OS"
				exit 1
			}
		}
	}
	"gitlab" {
		$env:GOBO = $env:CI_PROJECT_DIR
		if ($env:CI_RUNNER_EXECUTABLE_ARCH -match '^([^/]+)/.*') {
			switch ($matches[1]) {
				"linux" {
					$GOBO_CI_OS = "linux"
					# Installing `gcc`.
					apt update
					apt install -y build-essential
				}
				"macos" {
					$GOBO_CI_OS = "macos"
				}
				"windows" {
					$GOBO_CI_OS = "windows"
					# Setting the environment variables for `cl`.
					Invoke-Environment('"C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Auxiliary\Build\vcvarsx86_amd64.bat"')
				}
				default {
					Write-Error "Platform not supported: $env:RUNNER_OS"
					exit 1
				}
			}
		}
	}
	default {
		Write-Error "CI tool not supported: $CiTool"
		exit 1
	}
}

switch ($GOBO_CI_OS) {
	"linux" {
		$GOBO_CI_C_COMPILER = "gcc"
		$GOBO_CI_BUILD_SCRIPT = "install.sh"
		Get-Content "/etc/*-release"
		arch
		gcc --version
	}
	"macos" {
		$GOBO_CI_C_COMPILER = "clang"
		$GOBO_CI_BUILD_SCRIPT = "install.sh"
		clang --version
	}
	"windows" {
		$GOBO_CI_C_COMPILER = "cl"
		$GOBO_CI_BUILD_SCRIPT = "install.bat"
	}
}
Write-Host "`$GOBO_CI_C_COMPILER = $GOBO_CI_C_COMPILER"
Write-Host "`$GOBO_CI_BUILD_SCRIPT = $GOBO_CI_BUILD_SCRIPT"

$env:PATH = "$env:GOBO/bin$([IO.Path]::PathSeparator)$env:PATH"
