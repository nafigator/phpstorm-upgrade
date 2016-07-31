#!/usr/bin/env bash
#
# phpstorm-upgrade.sh
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

readonly DOWNLOAD_PAGE_URL='https://www.jetbrains.com/phpstorm/download/download-thanks.jsp?os=linux'
readonly DOWNLOAD_LINK_REGEX='<a href=\"([^"]+)">HTTP</a>'
readonly DOWNLOAD_URL_REGEX='http://download.jetbrains.com/webide/PhpStorm-[^"]+'
readonly VERSION_REGEX='\d+\.\d+(\.\d+)?'
readonly FILENAME_REGEX='PhpStorm-\d+\.\d+(\.\d+)?\.tar\.gz'
readonly CURL_DOWNLOAD_PARAMS='-LO --progress-bar'
readonly DOWNLOAD_TMP_DIR='/tmp'
readonly BINARY_DIR="$HOME/bin"
readonly PHPSTORM_DIR="$HOME/.local/share/phpstorm"
readonly VERSION='0.0.4'

. ./functions.sh

parse_options "$@" || exit $?
check_dependencies  || exit $?

if [ ! -x ${DOWNLOAD_TMP_DIR} ]; then
	error "$DOWNLOAD_TMP_DIR not found"; exit 1
fi

if [ ! -x ${PHPSTORM_DIR} ]; then
	debug "$PHPSTORM_DIR not found. Trying to create"
	command mkdir -p ${PHPSTORM_DIR}
	if [ $? -eq 0 ] && [ -x ${PHPSTORM_DIR} ]; then
		debug 'Success';
	else
		error "$PHPSTORM_DIR creation failure"; exit 1
	fi
fi

DOWNLOAD_LINK=$(command curl -s "$DOWNLOAD_PAGE_URL" | command egrep -o "$DOWNLOAD_LINK_REGEX" | command egrep -o "$DOWNLOAD_URL_REGEX")

if [ ! -z ${DOWNLOAD_LINK} ]; then
	debug "DOWNLOAD_LINK: $DOWNLOAD_LINK"
else
	error "DOWNLOAD_LINK parsing failure"; exit 1
fi

PHPSTORM_VERSION=$(echo ${DOWNLOAD_LINK} | command grep -Po ${VERSION_REGEX})

if [ ! -z ${PHPSTORM_VERSION} ]; then
	debug "Latest version: $PHPSTORM_VERSION"
else
	error "Version parsing failure"; exit 1
fi

PHPSTORM_FILENAME=$(echo ${DOWNLOAD_LINK} | command grep -Po ${FILENAME_REGEX})

if [ ! -z ${PHPSTORM_FILENAME} ]; then
	debug "File name: $PHPSTORM_FILENAME"
else
	error "PHPSTORM_FILENAME parsing failure"; exit 1
fi

if [ -e "$DOWNLOAD_TMP_DIR/$PHPSTORM_FILENAME" ]; then
	debug "Found downloaded file in $DOWNLOAD_TMP_DIR"
else
	cd ${DOWNLOAD_TMP_DIR}

	debug "Downloading the archive from server:"
	command curl ${CURL_DOWNLOAD_PARAMS} ${DOWNLOAD_LINK}

	if [ $? -eq 0 ]; then
		debug 'File successfully downloaded'
	else
		error 'File download failure'; exit 1
	fi
fi

var=$(tar -tf ${PHPSTORM_FILENAME} | grep '/bin/phpstorm.sh')

if [ -z ${var} ]; then
	error "Not found executable in archive"; exit 1
fi

var=$(tar -tf ${PHPSTORM_FILENAME} | head -n 1);
dir=$(dirname ${var});
PHPSTORM_BUILD=${dir%/*}
unset var dir

if [ ! -z ${PHPSTORM_BUILD} ]; then
	debug "Found build: $PHPSTORM_BUILD"
else
	error "Not found build in archive"; exit 1
fi

# Check previous version
if [ -d "$PHPSTORM_DIR/$PHPSTORM_BUILD" ]; then
	debug 'Installed latest version. Exit'; exit 0
fi

cd ${PHPSTORM_DIR}

# Remove previous backups
for dir in *.bkp; do
	debug "Found old backup: $dir"
	rm -rf ${dir}
	if [ $? -eq 0 ]; then
		debug 'Removed'
	else
		error "Could not delete the dir: $dir"; exit 1
	fi
done

# Backup previous versions
for dir in *[!.bkp]; do
	debug "Backup old installation: $dir"
	mv ${dir} ${dir}.bkp
	if [ $? -eq 0 ]; then
		debug 'Done'
	else
		error "Could not backup the dir: $dir"; exit 1
	fi
done

tar xf "$DOWNLOAD_TMP_DIR/$PHPSTORM_FILENAME"

if [ $? -eq 0 ] && [ -d "$PHPSTORM_DIR/$PHPSTORM_BUILD" ]; then
	debug 'Archive successfully unpacked'
else
	error 'Unpack failure'; exit 1
fi

if [ -h "$BINARY_DIR/phpstorm" ] || [ -e "$BINARY_DIR/phpstorm" ]; then
	rm -f "$BINARY_DIR/phpstorm"
	if [ $? -eq 0 ]; then
		debug 'Found old link. Removed'
	else
		error "Could not delete the file: $BINARY_DIR/phpstorm"
		exit 1
	fi
fi

ln -s "$PHPSTORM_DIR/$PHPSTORM_BUILD/bin/phpstorm.sh" "$BINARY_DIR/phpstorm"

if [ $? -eq 0 ]; then
	debug 'New link successfully created'
else
	error "Error. Could not create the link: $BINARY_DIR/phpstorm"
	exit 1
fi

inform "Successfully installed new version: $PHPSTORM_VERSION"

rm -f "$DOWNLOAD_TMP_DIR/$PHPSTORM_FILENAME"

if [ $? -eq 0 ]; then
	[ -z ${DEBUG} ] &&				\
		unset DOWNLOAD_PAGE_URL		\
			DOWNLOAD_LINK_REGEX 	\
			DOWNLOAD_URL_REGEX 		\
			VERSION_REGEX			\
			FILENAME_REGEX			\
			CURL_DOWNLOAD_PARAMS	\
			DOWNLOAD_TMP_DIR		\
			PHPSTORM_DIR			\
			BINARY_DIR				\
			PHPSTORM_VERSION		\
			PHPSTORM_FILENAME		\
			DOWNLOAD_LINK			\
			PHPSTORM_BUILD
	debug 'Cleanup ... OK'
else
	error "Could not delete the file: $DOWNLOAD_TMP_DIR/$PHPSTORM_FILENAME";
	[ -z ${DEBUG} ] &&				\
		unset DOWNLOAD_PAGE_URL		\
			DOWNLOAD_LINK_REGEX 	\
			DOWNLOAD_URL_REGEX 		\
			VERSION_REGEX			\
			FILENAME_REGEX			\
			CURL_DOWNLOAD_PARAMS	\
			DOWNLOAD_TMP_DIR		\
			PHPSTORM_DIR			\
			BINARY_DIR				\
			PHPSTORM_VERSION		\
			PHPSTORM_FILENAME		\
			DOWNLOAD_LINK			\
			PHPSTORM_BUILD
	exit 1
fi
