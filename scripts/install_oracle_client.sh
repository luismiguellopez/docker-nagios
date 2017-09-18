apt-get install libaio1
cd /tmp
curl -O http://172.17.0.1:8080/instantclient-basic-linux.x64-12.2.0.1.0.zip
curl -O http://172.17.0.1:8080/instantclient-odbc-linux.x64-12.2.0.1.0.zip
curl -O http://172.17.0.1:8080/instantclient-sdk-linux.x64-12.2.0.1.0.zip
curl -O http://172.17.0.1:8080/instantclient-sqlplus-linux.x64-12.2.0.1.0.zip

cd /opt
unzip /tmp/instantclient-basic-linux.x64-12.2.0.1.0.zip
unzip /tmp/instantclient-odbc-linux.x64-12.2.0.1.0.zip
unzip /tmp/instantclient-sdk-linux.x64-12.2.0.1.0.zip
unzip /tmp/instantclient-sqlplus-linux.x64-12.2.0.1.0.zip
printf "export ORACLE_HOME=/opt/instantclient_12_2\nexport PATH=\$ORACLE_HOME:\$PATH\nexport LD_LIBRARY_PATH=\$ORACLE_HOME:\$LD_LIBRARY_PATH">/etc/profile.d/oracle.sh
chmod +x /etc/profile.d/oracle.sh
echo "/opt/instant_client_12_2" > /etc/ld.so.conf.d/oracle.conf
ldconfig
rm /tmp/instantclient*
