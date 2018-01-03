#!/bin/bash

curl -sL ${SOURCES_ZIP} > /tmp/sources.zip \
 && unzip -q /tmp/sources.zip -d /tmp/unzipped \
 && mkdir -p /tmp/sources \
 && shopt -s dotglob \
 && rm -rf /tmp/sources/* \
 && mv /tmp/unzipped/*/* /tmp/sources/ \
 && shopt -u dotglob \
 && rsync --delete --force -aq /tmp/sources /opt
