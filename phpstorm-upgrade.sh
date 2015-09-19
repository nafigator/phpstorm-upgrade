#!/usr/bin/env bash

DOWNLOAD_PAGE_URL='https://www.jetbrains.com/phpstorm/download/download_thanks.jsp?os=linux'
DOWNLOAD_LINK_REGEX='<a href=\"([^"]+)">HTTP</a>'
DOWNLOAD_URL_REGEX='http://download.jetbrains.com/webide/PhpStorm-[^"]+'
VERSION_REGEX='\d+\.\d+\.\d+'
FILENAME_REGEX='PhpStorm-\d+\.\d+\.\d+\.tar\.gz'
CURL_DOWNLOAD_PARAMS='-LOs'
TMP_DIR='/tmp'
PHPSTORM_DIR="$HOME/.local/share/phpstorm"
BINARY_DIR="$HOME/bin"


if [ ! -x ${TMP_DIR} ]; then
	echo 'TEMP DIR not found'; return 1
fi

if [ ! -x ${PHPSTORM_DIR} ]; then
	echo 'Error. TEMP DIR not found. Trying to create'
	command mkdir -p ${PHPSTORM_DIR}
	if [ $? -eq 0 ] && [ -x ${PHPSTORM_DIR} ]; then
		echo 'Success';
	else
		echo 'Error. PHPSTORM_DIR creation failure'; return 1
	fi
fi

DOWNLOAD_LINK=$(curl -s "$DOWNLOAD_PAGE_URL" | command egrep -o "$DOWNLOAD_LINK_REGEX" | command egrep -o "$DOWNLOAD_URL_REGEX")

if [ ! -z ${DOWNLOAD_LINK} ]; then
	echo "DOWNLOAD_LINK: $DOWNLOAD_LINK"
else
	echo 'Error. DOWNLOAD_LINK parsing failure'; return 1
fi

VERSION=$(echo ${DOWNLOAD_LINK} | command grep -Po ${VERSION_REGEX})

if [ ! -z ${VERSION} ]; then
	echo "Latest version: $VERSION"
else
	echo 'Error. Version parsing failure'; return 1
fi

FILENAME=$(echo ${DOWNLOAD_LINK} | command grep -Po ${FILENAME_REGEX})

if [ ! -z ${FILENAME} ]; then
	echo "File name: $FILENAME"
else
	echo 'Error. FILENAME parsing failure'; return 1
fi

# Check previous version
#if [ -d "$PHPSTORM_DIR/$FILENAME" ]; then
#	echo 'Installed latest version. Exit'; exit 0
#fi

if [ -e "$TMP_DIR/$FILENAME" ]; then
	echo "Found downloaded file in $TMP_DIR"
else
	cd ${TMP_DIR}

	curl ${CURL_DOWNLOAD_PARAMS} ${DOWNLOAD_LINK}

	if [ $? -eq 0 ]; then
		echo 'File successfully downloaded'
	else
		echo 'File download failure'; return 1
	fi
fi

var=$(tar -tf ${FILENAME} | grep '/bin/phpstorm.sh')

if [ -z ${var} ]; then
	echo 'Error. Not found executable in archive'; return 1
fi

var=$(tar -tf ${FILENAME} | head -n 1);
dir=$(dirname ${var});
PHPSTORM_BUILD=${dir%/*}
unset var dir

if [ ! -z ${PHPSTORM_BUILD} ]; then
	echo "Found build: $PHPSTORM_BUILD"
else
	echo 'Error. Not found bulild in archive'; return 1
fi

# Check previous version
if [ -d "$PHPSTORM_DIR/$PHPSTORM_BUILD" ]; then
	echo 'Installed latest version. Exit'; return 0
fi

cd ${PHPSTORM_DIR}
tar xf "$TMP_DIR/$FILENAME"

if [ $? -eq 0 ] && [ -d "$PHPSTORM_DIR/$PHPSTORM_BUILD" ]; then
	echo 'Archive succesfully unpacked'
else
	echo 'Unpack failure'; return 1
fi

if [ -h "$BINARY_DIR/phpstorm" ] || [ -e "$BINARY_DIR/phpstorm" ]; then
	rm -f "$BINARY_DIR/phpstorm"
	if [ $? -eq 0 ]; then
		echo 'Found old link. Removed'
	else
		echo "Error. Could not delete the file: $BINARY_DIR/phpstorm"
		return 1
	fi
fi

ln -s "$PHPSTORM_DIR/$PHPSTORM_BUILD/bin/phpstorm.sh" "$BINARY_DIR/phpstorm"

if [ $? -eq 0 ]; then
	echo 'Link succesfully created'
else
	echo "Error. Could not create the link: $BINARY_DIR/phpstorm"
	return 1
fi

rm -f "$TMP_DIR/$FILENAME"

if [ $? -eq 0 ]; then
	echo 'Cleanup ... OK'
else
	echo "Error. Could not delete the file: $TMP_DIR/$FILENAME"; return 1
fi

echo "Successfully installed new version: $VERSION"
