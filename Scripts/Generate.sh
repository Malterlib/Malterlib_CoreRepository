#!/bin/bash
# Copyright © 2015-2018 Nonna Holding AB
# Distributed under the MIT license, see license text in LICENSE.Malterlib

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$DIR/Detect.sh"

set -e

MalterlibXcodeVersion=
MalterlibVisualStudioVersion=

{
	OLDIFS="$IFS"
	IFS=$'\n'
	if [ -f "Repo.conf" ] ; then
		RepoConfig=`cat Repo.conf`
		for Line in $RepoConfig; do
			IFS=' '

			read -a LineCommands <<< "$Line"
			Key=${LineCommands[0]}
			Value=${LineCommands[1]}

			if [[ "$Key" == "XcodeVersion" ]]; then
				MalterlibXcodeVersion=$Value
			fi
			if [[ "$Key" == "VisualStudioVersion" ]]; then
				MalterlibVisualStudioVersion=$Value
			fi
		done
	fi
	IFS="$OLDIFS"
}

if [[ "$MalterlibPlatform" == "OSX" ]] ; then
	if [ ! "$MalterlibXcodeVersion" == "" ]; then
		Conf_Version=$MalterlibXcodeVersion
	else
		Conf_Version=`xcodebuild -version | grep Xcode | awk -F ' ' {'print $2'} | awk -F '.' {'print $1'}`
	fi
elif [[ "$MalterlibPlatform" == "Windows" ]] ; then
	if [ ! "$MalterlibVisualStudioVersion" == "" ]; then
		Conf_Version=$MalterlibVisualStudioVersion
	else
		Conf_Version=
	fi
else
	Conf_Version=
fi

[ "$1" = "--" ] && shift

ToolType=BuildSystemGen
MToolCommand=
if [[ "$MalterlibTool" == "true" ]]; then
	export MToolIsMalterlib="true"
	export MalterlibProtectedEnvironment="MToolIsMalterlib;@MalterlibProtectedEnvironment"
	ToolType=Malterlib
	if (( $# >= 1)); then
		MToolCommand=$1
		shift
	fi
else
	if (( $# >= 1)); then
		Conf_Workspace=$1
		shift
	fi
fi

function RunMTool()
{
	set +e
	"$MToolExecutable" "$@"
	MToolExit=$?
	set -e

	if [[ $MToolExit != 0 ]] ; then
		exit $MToolExit
	fi
}

function GenerateForVersion()
{
	Files=`find . -maxdepth 1 -name '*.MBuildSystem'`

	Generator="$1"
	shift

	for f in $Files ; do
		if [ -x "$MToolDirectory/mib" ]; then
			if [[ "$MalterlibTool" == "true" ]]; then
				"$MToolDirectory/mib" $MToolCommand --build-system "$f" --generator "$Generator" "$@"
			else
				"$MToolDirectory/mib" generate --build-system "$f" --generator "$Generator" "$Conf_Workspace" "$@"
			fi
		else
			if [ "$Conf_Workspace" == "" ] ; then
				RunMTool $ToolType "$f" "Generator=$Generator" "$@"
			else
				RunMTool $ToolType "$f" "Generator=$Generator" "Workspace=$Conf_Workspace" "$@"
			fi
		fi
	done
}

if [[ "$MalterlibPlatform" == "Windows" ]]; then
	if [ ! "$Conf_Version" == "" ] ; then
		GenerateForVersion "VisualStudio$Conf_Version" "$@"
	else
		WindowsGenerator="VisualStudio2017"
		if [ -f "Repo.conf" ] ; then
		{
			OLDIFS="$IFS"
			IFS=$'\n'
			RepoConfig=`cat Stream.conf`
			for Line in $RepoConfig; do
				IFS=' '
				
				read -a LineCommands <<< "$Line"
				Key=${LineCommands[0]}
				Value=${LineCommands[1]}
				
				if [[ "$Key" == "WindowsGenerator" ]]; then
					WindowsGenerator=$Value
				fi
			done
			IFS="$OLDIFS"
		}
		fi
		GenerateForVersion "$WindowsGenerator" "$@"
	fi
else
	if [ "$Conf_Version" == "4" ] ; then
		GenerateForVersion Xcode "$@"
	elif [ ! "$Conf_Version" == "" ] ; then
		GenerateForVersion "Xcode$Conf_Version" "$@"
	else
		GenerateForVersion "Xcode5" "$@"
	fi
fi

if [[ "$MalterlibTool" != "true" ]]; then
	echo "Build system generation done"
fi
