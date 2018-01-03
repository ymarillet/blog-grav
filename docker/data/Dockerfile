FROM alpine:latest
MAINTAINER ymarillet <yohann.marillet@gmail.com>

RUN apk update \
    && apk add bash curl unzip rsync

VOLUME /opt/sources

ADD start.sh /opt/start.sh
RUN chmod 755 /opt/start.sh

CMD ["/opt/start.sh"]
