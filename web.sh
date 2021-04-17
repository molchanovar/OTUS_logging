#! /bin/bash

yum -y install vim 
yum -y install epel-release 
yum -y install net-tools
dnf -y install nginx
yum -y install audispd-plugins

cp /vagrant/web/nginx.conf /etc/nginx/nginx.conf
cp /vagrant/web/rsyslog.conf /etc/rsyslog.conf
cp /vagrant/web/auditd.conf /etc/audit/auditd.conf
cp /vagrant/web/audit.rules /etc/audit/rules.d/audit.rules
cp /vagrant/web/audisp-remote.conf /etc/audit/audisp-remote.conf
cp /vagrant/web/au-remote.conf /etc/audit/plugins.d/au-remote.conf

service auditd restart
systemctl restart rsyslog
systemctl restart nginx
