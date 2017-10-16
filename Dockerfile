FROM debian:jessie-slim

ARG DOWNLOAD_URL_BASE
ARG INSTALL_FILE=ColdFusion_exp_2016_WWEJ_linux64.zip
ARG INSTALL_FILE_SHASUM=c6c9a96f7fc45bfbf689235e2159ff90e44e14baee86bc67e493352fb037fa51

ENV CF_DIR=/opt/coldfusion/cfusion \
    COLDFUSION_HOST=localhost \
    COLDFUSION_PORT=8116

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
        apache2 \
        wget \
        ca-certificates \
        unzip \
    && wget $DOWNLOAD_URL_BASE/$INSTALL_FILE \
    && echo "$INSTALL_FILE_SHASUM *$INSTALL_FILE" | sha256sum -c \
    && useradd coldfusion \
    && unzip -q /ColdFusion_exp_2016_WWEJ_linux64.zip \
    && chown -R coldfusion:coldfusion ColdFusion \
    && mv ColdFusion ${CF_DIR%/cfusion} \
    && rm /ColdFusion_exp_2016_WWEJ_linux64.zip \
    && $CF_DIR/../jre/bin/java -jar $CF_DIR/runtime/lib/wsconfig.jar \
           -ws Apache -dir /etc/apache2 -norestart \
    && mv /etc/apache2/apache2.conf.1 /etc/apache2/apache2.conf \
    && rm /etc/apache2/mod_jk.conf \
    && DEBIAN_FRONTEND=noninteractive apt-get remove --purge --auto-remove -y \
        wget \
        ca-certificates \
        unzip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /srv/www

COPY apache/coldfusion.conf /etc/apache2/sites-available/
COPY apache/jk.conf apache/jk.load /etc/apache2/mods-available/
RUN a2enmod -q jk \
    && a2ensite -q coldfusion

COPY run-coldfusion.sh run-apache.sh /
RUN chmod a+x /run-coldfusion.sh /run-apache.sh

VOLUME /srv/www
