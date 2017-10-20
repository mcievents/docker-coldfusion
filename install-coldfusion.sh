#!/bin/bash
# For some reason the ColdFusion installer exits with an error status even
# when it's successful.
#set -e

useradd coldfusion
wget "$DOWNLOAD_URL_BASE/$INSTALL_FILE"
echo "$INSTALL_FILE_SHASUM *$INSTALL_FILE" | sha256sum -c
chmod a+x "$INSTALL_FILE"
./"$INSTALL_FILE" -f /coldfusion-installer.properties

# Clean up.
rm $CF_DIR/../ColdFusionAPIManager*.bin
rm "$INSTALL_FILE" /coldfusion-installer.properties /install-coldfusion.sh
