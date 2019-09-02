FROM php:5.6-fpm

MAINTAINER suliang20<suliang20@163.com>

# 更换(debian 8)软件源
# RUN mv /etc/apt/sources.list /etc/apt/sources.list.bak
# ADD data/resources/debian8.sources    /etc/apt/sources.list

# extions

# Install Core extension
#
# bcmath bz2 calendar ctype curl dba dom enchant exif fileinfo filter ftp gd gettext gmp hash iconv
# imap interbase intl json ldap mbstring mcrypt mssql mysql mysqli oci8 odbc opcache pcntl
# pdo pdo_dblib pdo_firebird pdo_mysql pdo_oci pdo_odbc pdo_pgsql pdo_sqlite pgsql phar posix
# pspell readline recode reflection session shmop simplexml snmp soap sockets spl standard
# sybase_ct sysvmsg sysvsem sysvshm tidy tokenizer wddx xml xmlreader xmlrpc xmlwriter xsl zip
#
# Must install dependencies for your extensions manually, if need.
RUN apt-get update && apt-get install -y \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libmcrypt-dev \
        libpng12-dev \

        libbz2-dev \
        libenchant-dev \
        libgmp-dev \
        libxml2-dev libtidy-dev libxslt1-dev \
        libzip-dev \
        libpq-dev \
        libpspell-dev \
        librecode-dev \
        firebird-dev \
        freetds-dev \
        libldap2-dev \
        libc-client-dev libkrb5-dev \
        firebird-dev \
        libicu-dev \

    && rm -r /var/lib/apt/lists/* \
    && docker-php-ext-install -j$(nproc) iconv mcrypt \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd \

    && docker-php-ext-install -j$(nproc) bz2 \
    && docker-php-ext-install -j$(nproc) enchant \
    && docker-php-ext-install -j$(nproc) gmp \
    && docker-php-ext-install -j$(nproc) soap wddx xmlrpc tidy xsl \
    && docker-php-ext-install -j$(nproc) zip \
    && docker-php-ext-install -j$(nproc) pgsql pdo_pgsql \
    && docker-php-ext-install -j$(nproc) pspell \
    && docker-php-ext-install -j$(nproc) recode \
    && docker-php-ext-install -j$(nproc) pdo_firebird \
    && docker-php-ext-install -j$(nproc) pdo_dblib \
    && docker-php-ext-install -j$(nproc) ldap \
    && docker-php-ext-install -j$(nproc) imap \
    && docker-php-ext-install -j$(nproc) interbase \
    && docker-php-ext-install -j$(nproc) intl \

    # no dependency extension
    && docker-php-ext-install gettext mysqli opcache pdo_mysql sockets bcmatch calendar exif dba pcntl \
    shmop sysvmsg sysvsem sysvshm

# Install PECL extensions
RUN apt-get install -y \

    # for memcache
    libmemcache-dev \

    # for memcached
    libmemcached-dev \

    libmagickwand-dev \

    && pecl install memcache && docker-php-ext-enable memcache \
    && pecl install memcached && docker-php-ext-enable memcached \
    && pecl install gearman && docker-php-ext-enable gearman \


    && pecl install xdebug && docker-php-ext-enable xdebug \
    && pecl install redis && docker-php-ext-enable redis \
    && pecl install xhprof && docker-php-ext-enable xhprof \
    && pecl install imagick-3.4.3 && docker-php-ext-enable imagick \

    && docker-php-source delete \
    && apt-get clean; rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/* \
    && echo 'PHP 5.6 installed.'

# Other extensions
RUN curl -fsSL 'https://xcache.lighttpd.net/pub/Releases/3.2.0/xcache-3.2.0.tar.gz' -o xcache.tar.gz \
     && mkdir -p xcache \
     && tar -xf xcache.tar.gz -C xcache --strip-components=1 \
     && rm xcache.tar.gz \
     && ( \
         cd xcache \
         && phpize \
         && ./configure --enable-xcache \
         && make -j$(nproc) \
         && make install \
     ) \
     && rm -r xcache \
     && docker-php-ext-enable xcache

# 增加 odbc, pdo_odbc 扩展
RUN set -ex; \
     docker-php-source extract; \
     { \
          echo '# https://github.com/docker-library/php/issues/103#issuecomment-271413933'; \
          echo 'AC_DEFUN([PHP_ALWAYS_SHARED],[])dnl'; \
          echo; \
          cat /usr/src/php/ext/odbc/config.m4; \
     } > temp.m4; \
     mv temp.m4 /usr/src/php/ext/odbc/config.m4; \
     apt-get update; \
     apt-get install -y --no-install-recommends unixodbc-dev; \
     rm -rf /var/lib/apt/lists/*; \
     docker-php-ext-configure odbc --with-unixODBC=shared,/usr; \
     docker-php-ext-configure pdo_odbc --with-pdo-odbc=unixODBC,/usr; \
     docker-php-ext-install odbc pdo_odbc; \
     docker-php-source delete

    # open pid file
RUN sed -i '/^;pid\s*=\s*/s/\;//g' /usr/local/etc/php-fpm.d/www.conf \

    # add php-fpm to service
    && cp services/php/5.6/php-fpm /etc/init.d/php-fpm && chmod +x /etc/init.d/php-fpm
    # && chkconfig --add php-fpm

# ADD data/packages/php-tools/composer.phar /usr/local/bin/composer
# RUN chmod 755 /usr/local/bin/composer

WORKDIR "/var/www"

################################################################################
# Volumes
################################################################################

VOLUME ["/var/www"]

# extends from parent
# EXPOSE 9000
# CMD ["php-fpm"]