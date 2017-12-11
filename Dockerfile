FROM debian:jessie-slim

ENV CF_DIR=/opt/coldfusion/cfusion \
    COLDFUSION_HOST=localhost \
    COLDFUSION_PORT=8116 \
    COLDFUSION_MIN_MEM=256m \
    COLDFUSION_MAX_MEM=1024m \
    COLDFUSION_ADDITIONAL_JVM_ARGS=

# Install Apache and pre-requisites
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
        apache2 \
        curl \
        wget \
        ca-certificates \
        unzip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /srv/www

# Install ColdFusion
ARG DOWNLOAD_URL_BASE
ARG INSTALL_FILE=ColdFusion_2016_WWEJ_linux64.bin
ARG INSTALL_FILE_SHASUM=cf60aa13a7a21325f2c27db2c0e4e8f3279e5c4fdf8a49744af29eb53e8b4ce4
COPY install-coldfusion.sh coldfusion-installer.properties /
RUN chmod a+x /install-coldfusion.sh \
    && /install-coldfusion.sh

# Configure ColdFusion
COPY run-coldfusion.sh configure-coldfusion.sh /
RUN chmod a+x /run-coldfusion.sh /configure-coldfusion.sh \
    && su -c /configure-coldfusion.sh coldfusion

# Patch ColdFusion
ARG PATCH_FILE=
ARG PATCH_FILE_SHASUM=
COPY patch-coldfusion.sh /
RUN /bin/bash /patch-coldfusion.sh

# Configure Apache
RUN $CF_DIR/../jre/bin/java -jar $CF_DIR/runtime/lib/wsconfig.jar \
        -ws Apache -dir /etc/apache2 -norestart \
    && mv /etc/apache2/apache2.conf.1 /etc/apache2/apache2.conf \
    && rm /etc/apache2/mod_jk.conf
COPY apache/coldfusion.conf /etc/apache2/sites-available/
COPY apache/jk.conf apache/jk.load /etc/apache2/mods-available/
COPY run-apache.sh /
RUN chmod a+x /run-apache.sh \
    && a2enmod -q jk \
    && a2ensite -q coldfusion

VOLUME /srv/www
