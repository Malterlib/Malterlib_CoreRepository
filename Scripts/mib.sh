#!/bin/bash
# Copyright © 2015-2018 Nonna Holding AB
# Distributed under the MIT license, see license text in LICENSE.Malterlib

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

set -e

source "$DIR/Detect.sh"
ExtraOptions=""

export MalterlibProtectedEnvironment="MToolIsMalterlib;@MalterlibProtectedEnvironment"

while true; do

	export MToolIsMalterlib="true"

	set +e
	"$MalterlibExecutable" "$@" $ExtraOptions
	MToolExit=$?
	set -e

	export MToolIsMalterlib="false"

	if [[ $MToolExit == 3 ]]; then
		ExtraOptions=
		echo mib tool potentially updated, running command again
		UpdateMTool
		continue
	elif [[ $MToolExit == 4 ]]; then
		echo mib tool potentially updated, running command again
		ExtraOptions="--reconcile-no-options"
		UpdateMTool
		continue
	fi

	exit $MToolExit
done
