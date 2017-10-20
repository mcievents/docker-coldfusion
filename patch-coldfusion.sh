#!/bin/bash
set -e

if [ ! -z "$PATCH_FILE" ]; then
    mkdir -p "$CF_DIR/hf-updates"
    cd "$CF_DIR/hf-updates"
    wget "$DOWNLOAD_URL_BASE/$PATCH_FILE"
    echo "$PATCH_FILE_SHASUM *$PATCH_FILE" | sha256sum -c
    cat > silent-update.properties <<EOF
INSTALLER_UI=SILENT
USER_INSTALL_DIR=${CF_DIR%/cfusion}
DOC_ROOT=$CF_DIR/wwwroot
EOF
    $CF_DIR/../jre/bin/java -jar "$PATCH_FILE" -i silent -f silent-update.properties
    rm "$PATCH_FILE" silent-update.properties
fi
