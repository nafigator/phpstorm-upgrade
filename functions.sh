#!/usr/bin/env bash
#
# functions.sh
#
# Copyright © 2015 Yancharuk Alexander <alex at itvault dot info>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the BSD 3-Clause License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# BSD 3-Clause License for more details.
#
# You should have received a copy of the BSD 3-Clause License along with this
# program.
# If not, see <https://tldrlegal.com/license/bsd-3-clause-license-(revised)>.

# Function for error messages
error() {
	printf "[$(date --rfc-3339=seconds)]: \033[0;31mERROR:\033[0m $@\n" >&2
}

# Function for informational messages
inform() {
	printf "[$(date --rfc-3339=seconds)]: \033[0;32mINFO:\033[0m $@\n"
}

# Function for warning messages
warn() {
	printf "[$(date --rfc-3339=seconds)]: \033[0;33mWARNING:\033[0m $@\n" >&2
}

# Function for debug messages
debug() {
	[ ! -z ${DEBUG} ] && printf "[$(date --rfc-3339=seconds)]: \033[0;32mDEBUG:\033[0m $@\n"
}

check_dependencies() {
	local commands='curl tar grep egrep'
	local result=0
	for i in ${commands}; do
		command -v ${i} >/dev/null 2>&1
		if [ $? -eq 0 ]; then
			debug "Check $i ... OK"
		else
			warn "$i command not available"
			result=1
		fi
	done
	return ${result}
}

usage_help() {
	cat <<EOL
Usage: $0 [OPTIONS...]

Options:
  -v, --version              Show script version
  -h, --help                 Show this help message
  -d, --debug                Run program in debug mode

EOL
}

print_version() {
	cat <<EOL
phpstorm-upgrade.sh ${VERSION} by Yancharuk Alexander

EOL
}

parse_options() {
	local result=0

	while getopts :vhd-: param; do
		case ${param} in
			v ) debug "Found option -$param"; print_version;;
			h ) debug "Found option -$param"; usage_help;;
			d ) DEBUG=1; debug "Found option -$param";;
			- ) local value="${OPTARG#*=}"
				debug "Found long $value"
				case $OPTARG in
					version ) debug "Found option --$OPTARG"; print_version; result=1;;
					help ) debug "Found option --$OPTARG"; usage_help; result=1;;
					debug ) DEBUG=1; debug "Found option --$OPTARG";;
					'' ) warn "Found -- option"; result=2;;
					* ) debug "Found option --$OPTARG"; warn "Illegal option --$OPTARG"; result=2;;
				esac;;
			* ) debug "Found option -$param"; warn "Illegal option -$param"; result=2;;
		esac
	done
	shift $((OPTIND-1))

	return ${result}
}
