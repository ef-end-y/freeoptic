ARG HTTPD_VERSION=2.4

FROM httpd:${HTTPD_VERSION}

RUN apt-get update && apt-get install -y \
  iputils-ping \
  default-mysql-client \
  libdbd-mysql-perl \
  libjson-perl \
  libgraph-perl \
  && rm -rf /var/lib/apt/lists/* \
  && apt-get clean

WORKDIR /usr/local/freeoptic
COPY . .

RUN set -e \
  && chown www-data:www-data -R /usr/local/freeoptic \
  && find /usr/local/freeoptic -type d -exec chmod 500 {} + \
  && find /usr/local/freeoptic -type f -exec chmod 400 {} + \
  && chmod 700 /usr/local/freeoptic/logs \
  && chmod 500 /usr/local/freeoptic/cgi-bin/* \
  && rm -fR /usr/local/apache2/cgi-bin \
  && rm -fR /usr/local/apache2/htdocs \
  && ln -s /usr/local/freeoptic/cgi-bin/ /usr/local/apache2/cgi-bin \
  && ln -s /usr/local/freeoptic/htdocs/ /usr/local/apache2/htdocs \
  && cd /usr/local/freeoptic/ \
  && perl install.pl -x

EXPOSE 80  

CMD ["httpd-foreground", "-c", "LoadModule cgid_module modules/mod_cgid.so"]