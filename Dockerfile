FROM lsiobase/alpine.armhf:3.5
MAINTAINER saarg

# set version label
ARG BUILD_DATE
ARG VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"

# install runtime dependencies required for Oscam
RUN \
 apk add --no-cache \
	libcrypto1.0 \
	libssl1.0 \
	libusb \
	pcsc-lite \
	pcsc-lite-libs && \

# install runtime dependencies from edge
 apk add --no-cache --repository http://dl-3.alpinelinux.org/alpine/edge/community/ \
	ccid && \

# install build time dependencies
 apk add --no-cache --virtual=build-dependencies \
	curl \
	gcc \
	g++ \
	libusb-dev \
	linux-headers \
	make \
	libressl-dev \
	pcsc-lite-dev \
	subversion \
	tar && \

# compile oscam from source
 svn checkout http://www.streamboard.tv/svn/oscam/trunk /tmp/oscam-svn && \
 cd /tmp/oscam-svn && \
 ./config.sh \
	--enable all --disable \
		CARDREADER_DB2COM \
		CARDREADER_INTERNAL \
		CARDREADER_STINGER \
		CARDREADER_STAPI \
		CARDREADER_STAPI5 \
		IPV6SUPPORT \
		LCDSUPPORT \
		LEDSUPPORT \
		READ_SDT_CHARSETS && \
 make \
	OSCAM_BIN=/usr/bin/oscam \
	NO_PLUS_TARGET=1 \
	CONF_DIR=/config \
	DEFAULT_PCSC_FLAGS="-I/usr/include/PCSC" \
	pcsc-libusb && \

# fix broken permissions from pcscd install.
 chown root:root \
	/usr/sbin/pcscd && \
 chmod 755 \
	/usr/sbin/pcscd && \

# fix group for card readers and add abc to dialout group
 groupmod -g 24 audio && \
 groupmod -g 18 dialout && \
 usermod -a -G 18 abc && \

# cleanup
 apk del --purge \
	build-dependencies && \
 rm -rf \
	/tmp/*

# copy local files
COPY root/ /

# Ports and volumes
EXPOSE 8888 10000
VOLUME /config
