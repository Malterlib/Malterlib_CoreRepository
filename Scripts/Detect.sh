#!/bin/bash
# Copyright © 2015-2018 Nonna Holding AB
# Distributed under the MIT license, see license text in LICENSE.Malterlib

function DoDetect()
{
	local DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

	set -e

	local SysName=$(uname -s)
	local ProcessorArch=$(uname -m)

	if [[ $SysName ==  MINGW* ]] || [[ $SysName ==  CYGWIN* ]] || [[ $SysName ==  windows* ]] ; then
		if ([[ $SysName ==  MINGW* ]] || [[ $SysName ==  CYGWIN* ]]) && [[ "$TERM" != "dumb" ]] ; then
			export MalterlibTerminalWidth=`tput cols`
			export MalterlibTerminalHeight=`tput lines`
		fi
		MalterlibPlatform=Windows
		if [[ $ProcessorArch == i*86 ]] ; then
			MalterlibArch=x86
		elif [[ $ProcessorArch == x86_64 ]] ; then
			MalterlibArch=x64
		else
			echo $ProcessorArch is not supported
			exit 1
		fi
	elif [[ $SysName ==  Darwin* ]] ; then
		MalterlibPlatform=OSX
		if [[ $ProcessorArch == x86_64 ]] ; then
			MalterlibArch=x64
		elif [[ $ProcessorArch == arm64 ]] ; then
			MalterlibArch=arm64
		else
			echo $ProcessorArch is not supported
			exit 1
		fi
	elif [[ $SysName ==  Linux* ]] ; then
		MalterlibPlatform=Linux
		if [[ $ProcessorArch == i*86 ]] ; then
			MalterlibArch=x86
		elif [[ $ProcessorArch == x86_64 ]] ; then
			if [[ `getconf LONG_BIT` == "32" ]] ; then
				MalterlibArch=x86
			else
				MalterlibArch=x64
			fi
		else
			echo $ProcessorArch is not supported
			exit 1
		fi
	else
		echo $SysName is not supported platform
		exit 1
	fi

	if [[ "$MalterlibPlatform" ==  Windows ]] ; then
		function MalterlibConvertPath()
		{
			cygpath -m "$1"
		}
	else
		function MalterlibConvertPath()
		{
			echo "$1"
		}
	fi

	if [[ "$MalterlibBinariesDir" != "" ]]; then
		export MToolDirectory="$MalterlibBinariesDir"
	else
		RootDir="$( cd "$DIR/../../.." && pwd )"
		export MToolDirectory="$RootDir/Binaries/Malterlib/$MalterlibPlatform/$MalterlibArch"
	fi
}

DoDetect

export MalterlibConvertPath
export MalterlibPlatform
export MalterlibArch
export MToolExecutable="$MToolDirectory/MTool"
export MalterlibExecutable="$MToolDirectory/mib"
