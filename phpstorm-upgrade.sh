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


OPTIONS=$@
DOWNLOAD_PAGE_URL='https://www.jetbrains.com/phpstorm/download/download_thanks.jsp?os=linux'
DOWNLOAD_LINK_REGEX='<a href=\"([^"]+)">HTTP</a>'
DOWNLOAD_URL_REGEX='http://download.jetbrains.com/webide/PhpStorm-[^"]+'
VERSION_REGEX='\d+\.\d+\.\d+'
FILENAME_REGEX='PhpStorm-\d+\.\d+\.\d+\.tar\.gz'
CURL_DOWNLOAD_PARAMS='-LOs'
DOWNLOAD_TMP_DIR='/tmp'
BINARY_DIR="$HOME/bin"
PHPSTORM_DIR="$HOME/.local/share/phpstorm"

for i in $@; do
	case ${i} in
		--debug|-d) DEBUG='true';;
	esac
done

check_dependencies() {
	local commands='curl tar grep egrep'
	local error=0
	for i in ${commands}; do
		command -v ${i} >/dev/null 2>&1
		if [ $? -eq 0 ]; then
			[ ! -z ${DEBUG} ] && echo "Check $i ... OK"
		else
			echo "Error. $i command not available"
			error=1
		fi
	done
	return ${error}
}

_help() {
	cat <<EOL
Usage: $0 [OPTION...]

Options:
  -h, --help                 Show this help message
  -d, --debug                Run program in debug mode

EOL
	exit 1;
}
while getopts 'hd-:' param; do
	case ${param} in
		h )  _help;;
		d )  DEBUG=1;;
		- )  VALUE="${OPTARG#*=}"
			case $OPTARG in
				debug )	DEBUG=1;;
				help  ) _help;;
				''    ) break;;
				*     ) echo "Error. Illegal option --$OPTARG"; exit 2;;
			esac ;;
		* ) echo "Error. Illegal option $OPTARG"; exit 2;;
	esac
done
shift $((OPTIND-1))

exit 0

check_dependencies	|| exit 1;

if [ ! -x ${DOWNLOAD_TMP_DIR} ]; then
	echo 'TEMP DIR not found'; exit 1
fi

if [ ! -x ${PHPSTORM_DIR} ]; then
	echo 'Error. TEMP DIR not found. Trying to create'
	command mkdir -p ${PHPSTORM_DIR}
	if [ $? -eq 0 ] && [ -x ${PHPSTORM_DIR} ]; then
		echo 'Success';
	else
		echo 'Error. PHPSTORM_DIR creation failure'; exit 1
	fi
fi

DOWNLOAD_LINK=$(command curl -s "$DOWNLOAD_PAGE_URL" | command egrep -o "$DOWNLOAD_LINK_REGEX" | command egrep -o "$DOWNLOAD_URL_REGEX")

if [ ! -z ${DOWNLOAD_LINK} ]; then
	echo "DOWNLOAD_LINK: $DOWNLOAD_LINK"
else
	echo 'Error. DOWNLOAD_LINK parsing failure'; exit 1
fi

PHPSTORM_VERSION=$(echo ${DOWNLOAD_LINK} | command grep -Po ${VERSION_REGEX})

if [ ! -z ${PHPSTORM_VERSION} ]; then
	echo "Latest version: $PHPSTORM_VERSION"
else
	echo 'Error. Version parsing failure'; exit 1
fi

PHPSTORM_FILENAME=$(echo ${DOWNLOAD_LINK} | command grep -Po ${FILENAME_REGEX})

if [ ! -z ${PHPSTORM_FILENAME} ]; then
	echo "File name: $PHPSTORM_FILENAME"
else
	echo 'Error. PHPSTORM_FILENAME parsing failure'; exit 1
fi

if [ -e "$DOWNLOAD_TMP_DIR/$PHPSTORM_FILENAME" ]; then
	echo "Found downloaded file in $DOWNLOAD_TMP_DIR"
else
	cd ${DOWNLOAD_TMP_DIR}

	command curl ${CURL_DOWNLOAD_PARAMS} ${DOWNLOAD_LINK}

	if [ $? -eq 0 ]; then
		echo 'File successfully downloaded'
	else
		echo 'File download failure'; exit 1
	fi
fi

var=$(tar -tf ${PHPSTORM_FILENAME} | grep '/bin/phpstorm.sh')

if [ -z ${var} ]; then
	echo 'Error. Not found executable in archive'; exit 1
fi

var=$(tar -tf ${PHPSTORM_FILENAME} | head -n 1);
dir=$(dirname ${var});
PHPSTORM_BUILD=${dir%/*}
unset var dir

if [ ! -z ${PHPSTORM_BUILD} ]; then
	echo "Found build: $PHPSTORM_BUILD"
else
	echo 'Error. Not found bulild in archive'; exit 1
fi

# Check previous version
if [ -d "$PHPSTORM_DIR/$PHPSTORM_BUILD" ]; then
	echo 'Installed latest version. Exit'; exit 0
fi

cd ${PHPSTORM_DIR}

# Remove previous backups
for dir in *.bkp; do
	[ ! -z ${DEBUG} ] && echo "Found old backup: $dir"
	rm -rf ${dir}
	if [ $? -eq 0 ]; then
		[ ! -z ${DEBUG} ] && echo 'Removed'
	else
		echo "Error. Could not delete the dir: $dir"; exit 1
	fi
done

# Backup previous versions
for dir in *[!.bkp]; do
	[ ! -z ${DEBUG} ] && echo "Backup old installation: $dir"
	mv ${dir} ${dir}.bkp
	if [ $? -eq 0 ]; then
		[ ! -z ${DEBUG} ] && echo 'Done'
	else
		echo "Error. Could not backup the dir: $dir"; exit 1
	fi
done

tar xf "$DOWNLOAD_TMP_DIR/$PHPSTORM_FILENAME"

if [ $? -eq 0 ] && [ -d "$PHPSTORM_DIR/$PHPSTORM_BUILD" ]; then
	echo 'Archive succesfully unpacked'
else
	echo 'Unpack failure'; exit 1
fi

if [ -h "$BINARY_DIR/phpstorm" ] || [ -e "$BINARY_DIR/phpstorm" ]; then
	rm -f "$BINARY_DIR/phpstorm"
	if [ $? -eq 0 ]; then
		echo 'Found old link. Removed'
	else
		echo "Error. Could not delete the file: $BINARY_DIR/phpstorm"
		exit 1
	fi
fi

ln -s "$PHPSTORM_DIR/$PHPSTORM_BUILD/bin/phpstorm.sh" "$BINARY_DIR/phpstorm"

if [ $? -eq 0 ]; then
	echo 'New link succesfully created'
else
	echo "Error. Could not create the link: $BINARY_DIR/phpstorm"
	exit 1
fi

echo "Successfully installed new version: $PHPSTORM_VERSION"

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
			PHPSTORM_BUILD			\
			OPTIONS
	echo 'Cleanup ... OK'
else
	echo "Error. Could not delete the file: $DOWNLOAD_TMP_DIR/$PHPSTORM_FILENAME";
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
			PHPSTORM_BUILD			\
			OPTIONS
	exit 1
fi
