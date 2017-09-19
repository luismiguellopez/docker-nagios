#!/bin/bash
echo -n "Installing DBD::Oracle..."
printf "yes \n get DBD::Oracle \n exit \n"|cpan >/dev/null 2>&1
if [ $? != 0 ];then
  echo "KO"
  exit 1
fi
echo "OK"
cd ~/.cpan/build/DBD-Oracle*
perl Makefile.PL && make && make install 
cd /tmp
tar xvfz check_oracle_health-3.1.0.1.tar.gz
cd check_oracle*
./configure --libexecdir ${NAGIOS_HOME}/libexec && make && make install >/dev/null 2>&1
exit $?
