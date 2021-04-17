#! /bin/bash

yum -y install net-tools

cp /vagrant/log/rsyslog.conf /etc/rsyslog.conf
cp /vagrant/log/auditd.conf /etc/audit/auditd.conf

service auditd restart
systemctl restart rsyslog
