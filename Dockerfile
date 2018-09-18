FROM wonderfall/nginx-php:7.2

ARG VERSION=3.6.0
ARG GPG_matthieu="814E 346F A01A 20DB B04B  6807 B5DB D592 5590 A237"

ENV UID=991 GID=991 \
    UPLOAD_MAX_SIZE=10M \
    MEMORY_LIMIT=256M \
    OPCACHE_MEM_SIZE=128M

RUN BUILD_DEPS=" \
    git \
    tar \
    build-base \
    autoconf \
    geoip-dev \
    libressl \
    ca-certificates \
    gnupg" \
 && apk -U upgrade && apk add \
    ${BUILD_DEPS} \
    geoip \
    tzdata \
 && pecl install geoip-1.1.1 \
 && echo 'extension=geoip.so' >> /php/conf.d/geoip.ini \
 && mkdir /matomo && cd /tmp \
 && MATOMO_TARBALL="piwik-${VERSION}.tar.gz" \
 && wget -q https://builds.matomo.org/${MATOMO_TARBALL} \
 && wget -q https://builds.matomo.org/${MATOMO_TARBALL}.asc \
 && wget -q https://builds.matomo.org/signature.asc \
 && echo "Verifying authenticity of ${MATOMO_TARBALL}..." \
 && gpg --import signature.asc \
 && FINGERPRINT="$(LANG=C gpg --verify ${MATOMO_TARBALL}.asc ${MATOMO_TARBALL} 2>&1 \
  | sed -n "s#Primary key fingerprint: \(.*\)#\1#p")" \
 && if [ -z "${FINGERPRINT}" ]; then echo "Warning! Invalid GPG signature!" && exit 1; fi \
 && if [ "${FINGERPRINT}" != "${GPG_matthieu}" ]; then echo "Warning! Wrong GPG fingerprint!" && exit 1; fi \
 && echo "All seems good, now unpacking ${MATOMO_TARBALL}..." \
 && tar xzf ${MATOMO_TARBALL} --strip 1 -C /matomo \
 && wget -q https://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz -P /usr/share/GeoIP/ \
 && gzip -d /usr/share/GeoIP/GeoLiteCity.dat.gz \
 && mv /usr/share/GeoIP/GeoLiteCity.dat /usr/share/GeoIP/GeoIPCity.dat \
 && apk del ${BUILD_DEPS} php7-dev php7-pear \
 && rm -rf /var/cache/apk/* /tmp/* /root/.gnupg

COPY rootfs /

RUN chmod +x /usr/local/bin/run.sh /etc/s6.d/*/* /etc/s6.d/.s6-svscan/*

VOLUME /config

EXPOSE 8888

LABEL description "Open web analytics platform" \
      matomo "Matomo v${VERSION}" \
      maintainer="Wonderfall <wonderfall@targaryen.house>"

CMD ["run.sh"]
