#!/usr/bin/env bash
set -e

RESET=$(echo -e "\033[0m")
BOLD=$(echo -e "\033[1m")
YELLOW=$(echo -e "\033[33m")
BLUE_BG=$(echo -e "\033[44m")

function header()
{
	local title="$1"
	echo "${BLUE_BG}${YELLOW}${BOLD}${title}${RESET}"
	echo "------------------------------------------"
}

function header2()
{
	local title="$1"
	echo "### ${BOLD}${title}${RESET}"
	echo
}

function run()
{
	echo "+ $*"
	"$@"
}

function cleanup()
{
	set +e
	local pids=$(jobs -p)
	if [[ "$pids" != "" ]]; then
		kill $pids 2>/dev/null
	fi
	if [[ $(type -t _cleanup) == function ]]; then
		_cleanup
	fi
}

trap cleanup EXIT
