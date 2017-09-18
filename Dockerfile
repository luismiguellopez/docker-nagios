FROM debian:latest
MAINTAINER Luis M López <luismiguel.lopez@avanttic.com>
ENV NAGIOS_HOME			/usr/local/nagios
ENV NAGIOS_USER			nagios
ENV NAGIOS_GROUP		nagios
ENV NAGIOS_CMDUSER		nagios
ENV NAGIOS_CMDGROUP		nagios
ENV NAGIOS_FQDN			nagios-docker.avanttic.com
ENV NAGIOSADMIN_USER		nagiosadmin
ENV NAGIOSADMIN_PASS		nagios
ENV APACHE_RUN_USER		nagios
ENV APACHE_RUN_GROUP		nagios
ENV NAGIOS_TIMEZONE		Europe/Madrid
ENV DEBIAN_FRONTEND		noninteractive
ENV NG_NAGIOS_CONFIG_FILE	${NAGIOS_HOME}/etc/nagios.cfg
ENV NG_CGI_DIR			${NAGIOS_HOME}/sbin
ENV NG_WWW_DIR			${NAGIOS_HOME}/share/nagiosgraph
ENV NG_CGI_URL			/cgi-bin
ENV NAGIOS_BRANCH		nagios-4.3.4
ENV NAGIOS_PLUGINS_BRANCH	release-2.2.1
ENV NRPE_BRANCH			nrpe-3.1.1
ENV OPENSSL_BRANCH		OpenSSL_1_0_2-stable
ENV LD_LIBRARY_PATH             /opt/instantclient_12_2:/usr/local/ssl/lib

RUN	sed -i 's/main/main non-free/' /etc/apt/sources.list	&& \
	echo postfix postfix/main_mailer_type string "'Internet Site'" | debconf-set-selections && \
	echo postfix postfix/mynetworks string "127.0.0.0/8" | debconf-set-selections && \
	echo postfix postfix/mailname string ${NAGIOS_FQDN} | debconf-set-selections && \
	apt-get update && apt-get install -y				\
		iputils-ping						\
		netcat							\
		dnsutils						\
		build-essential						\
		automake						\
		autoconf						\
		gettext							\
		m4							\
		gperf							\
		snmp							\
		snmpd							\
		snmp-mibs-downloader					\
		php-cli							\
		php-gd							\
		libgd2-xpm-dev						\
		apache2							\
		apache2-utils						\
		libapache2-mod-php					\
		runit							\
		unzip							\
		bc							\
		postfix							\
		rsyslog							\
		bsd-mailx						\
		libnet-snmp-perl					\
		git							\
		libssl-dev						\
		libcgi-pm-perl						\
		librrds-perl						\
		libgd-gd2-perl						\
		libnagios-object-perl					\
		fping							\
		libfreeradius-dev				\
		libnet-snmp-perl					\
		libnet-xmpp-perl					\
		parallel						\
		libcache-memcached-perl					\
		libdbd-mysql-perl					\
		libdbi-perl						\
		libnet-tftp-perl					\
		libredis-perl						\
		libswitch-perl						\
		libwww-perl							\
		libjson-perl					&&	\
		apt-get clean

RUN	( egrep -i "^${NAGIOS_GROUP}"    /etc/group || groupadd $NAGIOS_GROUP    )				&&	\
	( egrep -i "^${NAGIOS_CMDGROUP}" /etc/group || groupadd $NAGIOS_CMDGROUP )
RUN	( id -u $NAGIOS_USER    || useradd --system -d $NAGIOS_HOME -g $NAGIOS_GROUP    $NAGIOS_USER    )	&&	\
	( id -u $NAGIOS_CMDUSER || useradd --system -d $NAGIOS_HOME -g $NAGIOS_CMDGROUP $NAGIOS_CMDUSER )

## Nagios 4.3.1 has leftover debug code which spams syslog every 15 seconds
## Its fixed in 4.3.2 and the patch can be removed then
#NAGIOS CORE	
RUN	cd /tmp							&&	\
	git clone https://github.com/NagiosEnterprises/nagioscore.git -b $NAGIOS_BRANCH &&	\
	cd nagioscore						&&	\
	./configure							\
		--prefix=${NAGIOS_HOME}					\
		--exec-prefix=${NAGIOS_HOME}				\
		--enable-event-broker					\
		--with-command-user=${NAGIOS_CMDUSER}			\
		--with-command-group=${NAGIOS_CMDGROUP}			\
		--with-nagios-user=${NAGIOS_USER}			\
		--with-nagios-group=${NAGIOS_GROUP}		&&	\
	make all						&&	\
	make install						&&	\
	make install-config					&&	\
	make install-commandmode				&&	\
	make install-webconf					&&	\
	make clean
#NAGIOS PLUGINS
RUN	cd /tmp							&&	\
	git clone https://github.com/nagios-plugins/nagios-plugins.git -b $NAGIOS_PLUGINS_BRANCH		&&	\
	cd nagios-plugins					&&	\
	./tools/setup						&&	\
	./configure							\
		--prefix=${NAGIOS_HOME}				&&	\
	make							&&	\
	make install						&&	\
	make clean	&&	\
	mkdir -p /usr/lib/nagios/plugins	&&	\
	ln -sf ${NAGIOS_HOME}/libexec/utils.pm /usr/lib/nagios/plugins

RUN     cd /tmp							&& \
	git clone https://github.com/openssl/openssl.git -b $OPENSSL_BRANCH && \
	cd openssl						&& \
	./config shared						&& \
	make && make install 					&& \
	cd .. && rm -rf openssl
	
RUN	cd /tmp							&&	\
	git clone https://github.com/NagiosEnterprises/nrpe.git	-b $NRPE_BRANCH	&&	\
	cd nrpe							&&	\
	./configure							\
		--with-ssl=/usr/local/ssl				\
		--with-ssl-lib=/usr/local/ssl/lib		&&	\
	make check_nrpe						&&	\
	cp src/check_nrpe ${NAGIOS_HOME}/libexec/		&&	\
	cd .. && rm -rf nrpe

RUN	cd /tmp											&&	\
	git clone https://git.code.sf.net/p/nagiosgraph/git nagiosgraph				&&	\
	cd nagiosgraph										&&	\
	./install.pl --install										\
		--prefix ${NAGIOS_HOME}/../nagiosgraph								\
		--nagios-user ${NAGIOS_USER}								\
		--www-user ${NAGIOS_USER}								\
		--nagios-perfdata-file ${NAGIOS_HOME}/var/perfdata.log					\
		--nagios-cgi-url /cgi-bin							&&	\
	cp share/nagiosgraph.ssi ${NAGIOS_HOME}/share/ssi/common-header.ssi

#RUN cd /opt &&		\
#	git clone https://github.com/willixix/naglio-plugins.git	WL-Nagios-Plugins	&&	\
#	git clone https://github.com/JasonRivers/nagios-plugins.git	JR-Nagios-Plugins	&&	\
#	git clone https://github.com/justintime/nagios-plugins.git      JE-Nagios-Plugins       &&      \
#	chmod +x /opt/WL-Nagios-Plugins/check*                                                  &&      \
#	chmod +x /opt/JE-Nagios-Plugins/check_mem/check_mem.pl                                  &&      \
#	cp /opt/JE-Nagios-Plugins/check_mem/check_mem.pl ${NAGIOS_HOME}/libexec/                   &&      \
#	cp ${NAGIOS_HOME}/libexec/utils.sh /opt/JR-Nagios-Plugins/

RUN	sed -i.bak 's/.*\=www\-data//g' /etc/apache2/envvars

RUN	export DOC_ROOT="DocumentRoot $(echo $NAGIOS_HOME/share)"					&&	\
	sed -i "s,DocumentRoot.*,$DOC_ROOT," /etc/apache2/sites-enabled/000-default.conf		&&	\
	sed -i "s,</VirtualHost>,<IfDefine ENABLE_USR_LIB_CGI_BIN>\nScriptAlias /cgi-bin/ /opt/nagios/sbin/\n</IfDefine>\n</VirtualHost>," /etc/apache2/sites-enabled/000-default.conf	&&	\
	ln -s /etc/apache2/mods-available/cgi.load /etc/apache2/mods-enabled/cgi.load

RUN	mkdir -p -m 0755 /usr/share/snmp/mibs							&&	\
	mkdir -p         ${NAGIOS_HOME}/etc/conf.d						&&	\
	mkdir -p         ${NAGIOS_HOME}/etc/monitor						&&	\
	mkdir -p -m 700  ${NAGIOS_HOME}/.ssh							&&	\
	chown ${NAGIOS_USER}:${NAGIOS_GROUP} ${NAGIOS_HOME}/.ssh				&&	\
	touch /usr/share/snmp/mibs/.foo								&&	\
	ln -s /usr/share/snmp/mibs ${NAGIOS_HOME}/libexec/mibs					&&	\
	ln -s ${NAGIOS_HOME}/bin/nagios /usr/local/bin/nagios					&&	\
	download-mibs && echo "mibs +ALL" > /etc/snmp/snmp.conf

RUN	sed -i 's,/bin/mail,/usr/bin/mail,' ${NAGIOS_HOME}/etc/objects/commands.cfg		&&	\
	sed -i 's,/usr/usr,/usr,'           ${NAGIOS_HOME}/etc/objects/commands.cfg

RUN	cp /etc/services /var/spool/postfix/etc/	&&\
	echo "smtp_address_preference = ipv4" >> /etc/postfix/main.cf

RUN	rm -rf /etc/rsyslog.d /etc/rsyslog.conf
RUN	rm -rf /etc/sv/getty-5

ADD nagios/nagios.cfg ${NAGIOS_HOME}/etc/nagios.cfg
ADD nagios/cgi.cfg ${NAGIOS_HOME}/etc/cgi.cfg
ADD nagios/templates.cfg ${NAGIOS_HOME}/etc/objects/templates.cfg
ADD nagios/commands.cfg ${NAGIOS_HOME}/etc/objects/commands.cfg
ADD nagios/localhost.cfg ${NAGIOS_HOME}/etc/objects/localhost.cfg

COPY files/check_oracle_health-3.1.0.1.tar.gz /tmp
COPY scripts/install_oracle_client.sh /tmp
COPY scripts/install_check_oracle_perl.sh /tmp

RUN /tmp/install_oracle_client.sh && rm /tmp/install_oracle_client.sh
RUN /tmp/install_check_oracle_perl.sh && /tmp/install_check_oracle_perl.sh
ADD rsyslog/rsyslog.conf /etc/rsyslog.conf
RUN echo "use_timezone=${NAGIOS_TIMEZONE}" >> ${NAGIOS_HOME}/etc/nagios.cfg

# Copy example config in-case the user has started with empty var or etc
RUN mkdir -p /orig/var && mkdir -p /orig/etc				&&	\
	cp -Rp ${NAGIOS_HOME}/var/* /orig/var/					&&	\
	cp -Rp ${NAGIOS_HOME}/etc/* /orig/etc/

RUN a2enmod session					&&\
    a2enmod session_cookie				&&\
    a2enmod session_crypto				&&\
    a2enmod auth_form					&&\
    a2enmod request

ADD nagios.init /etc/sv/nagios/run
ADD apache.init /etc/sv/apache/run
ADD postfix.init /etc/sv/postfix/run
ADD rsyslog.init /etc/sv/rsyslog/run
ADD start.sh /usr/local/bin/start_nagios
RUN chmod +x /usr/local/bin/start_nagios

# enable all runit services
RUN ln -s /etc/sv/* /etc/service

ENV APACHE_LOCK_DIR /var/run
ENV APACHE_LOG_DIR /var/log/apache2

#Set ServerName and timezone for Apache
RUN echo "ServerName ${NAGIOS_FQDN}" > /etc/apache2/conf-available/servername.conf	&& \
    echo "PassEnv TZ" > /etc/apache2/conf-available/timezone.conf			&& \
    ln -s /etc/apache2/conf-available/servername.conf /etc/apache2/conf-enabled/servername.conf	&& \
    ln -s /etc/apache2/conf-available/timezone.conf /etc/apache2/conf-enabled/timezone.conf
EXPOSE 80
VOLUME "${NAGIOS_HOME}/var" "${NAGIOS_HOME}/etc" "${NAGIOS_HOME}/libexec" "/var/log/apache2" "/usr/share/snmp/mibs" "/opt/Custom-Nagios-Plugins"
CMD [ "/usr/local/bin/start_nagios" ]
