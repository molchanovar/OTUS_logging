# OTUS_logging
rsyslog+auditd

### Настроен центральный сервер для сбора логов:
 - В вагранте подняты 2 машины web и log. На web поднят nginx. На log настроен центральный лог сервер через rsyslog.  
 - Настроен аудит следящий за изменением конфигов нжинкса. Все критичные логи с web собираются локально и удаленно. Все логи с nginx уходят на удаленный сервер (локально только критичные) логи аудита должны также уходить на удаленную систему


### Выполнение:
Подняты 2 виртуальные машины:
```
1. Web (ip 10.0.1.4) # клиент
2. Log (ip 10.0.1.5) # сервер 
```

### Настраиваем Web: 
1. Устанавливаем Nginx `dnf install nginx`
2. Добавляем правила для `auditd` в конфиг файл:
```
vim /etc/audit/rules.d/audit.rules

## Nginx conf change Audit
-w /etc/nginx/nginx.conf -p wa -k nginx_conf
-w /etc/nginx/default.d/ -p wa -k nginx_conf
```
Рестартуем сервис (рестарт через systemctl не работает) и проверяем правила: 
```
[root@web vagrant]# service auditd restart
Stopping logging:                                          [  OK  ]
Redirecting start to /bin/systemctl start auditd.service

[root@web vagrant]# auditctl -l
-w /etc/nginx/nginx.conf -p wa -k nginx_conf
-w /etc/nginx/default.d -p wa -k nginx_conf
```
Пробуем поменять порт Nginx и смотрим логи: 
```
[root@web vagrant]# vim /etc/nginx/nginx.conf
...
server {
        listen       8080 default_server;
        listen       [::]:8080 default_server;
...

[root@web vagrant]# systemctl restart nginx
```

Проверяем что логи пишутся локально `ausearch -k nginx_conf`: 
```
time->Wed Apr 14 19:50:37 2021
type=PROCTITLE msg=audit(1618429837.670:1184): proctitle=76696D002F6574632F6E67696E782F6E67696E782E636F6E66
type=PATH msg=audit(1618429837.670:1184): item=0 name=(null) inode=8457463 dev=08:01 mode=0100644 ouid=0 ogid=0 rdev=00:00 obj=system_u:object_r:httpd_config_t:s0 nametype=NORMAL cap_fp=0 cap_fi=0 cap_fe=0 cap_fver=0 cap_frootid=0
type=SYSCALL msg=audit(1618429837.670:1184): arch=c000003e syscall=91 success=yes exit=0 a0=5 a1=81a4 a2=7fff358a73a0 a3=24 items=1 ppid=4113 pid=34318 auid=1000 uid=0 gid=0 euid=0 suid=0 fsuid=0 egid=0 sgid=0 fsgid=0 tty=pts0 ses=6 comm="vim" exe="/usr/bin/vim" subj=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023 key="nginx_conf"
----
time->Wed Apr 14 19:50:37 2021
type=PROCTITLE msg=audit(1618429837.670:1185): proctitle=76696D002F6574632F6E67696E782F6E67696E782E636F6E66
type=PATH msg=audit(1618429837.670:1185): item=0 name="/etc/nginx/nginx.conf" inode=8457463 dev=08:01 mode=0100644 ouid=0 ogid=0 rdev=00:00 obj=system_u:object_r:httpd_config_t:s0 nametype=NORMAL cap_fp=0 cap_fi=0 cap_fe=0 cap_fver=0 cap_frootid=0
type=CWD msg=audit(1618429837.670:1185): cwd="/home/vagrant"
type=SYSCALL msg=audit(1618429837.670:1185): arch=c000003e syscall=188 success=yes exit=0 a0=564e44c14430 a1=7f12a44d61ef a2=564e44e30fc0 a3=1c items=1 ppid=4113 pid=34318 auid=1000 uid=0 gid=0 euid=0 suid=0 fsuid=0 egid=0 sgid=0 fsgid=0 tty=pts0 ses=6 comm="vim" exe="/usr/bin/vim" subj=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023 key="nginx_conf"
```

3. Настраиваем отправку логов аудита на удаленный сервер: 
Устанавливаем пакет `audispd-plugins` и идем в конфиги: 
```
[root@web vagrant]# vim /etc/audit/audisp-remote.conf
...
remote_server = 10.0.1.5
port = 60
...

vim /etc/audit/plugins.d/au-remote.conf 
...
active = yes
...

vim /etc/audit/auditd.conf
...
# Not record logs on local filesystem:
log_format = NOLOG
...
```

Рестартуем сервис auditd 
```
service auditd restart
```
4. Отправка критичных логов на Log сервер + сохрание на локальной машине:
Идем в конфиг файл rsyslog `/etc/rsyslog.conf` и добавляем правила:
```
...
#### RULES ####
...
*.crit action(type="omfwd" target="10.0.1.5" port="514" protocol="tcp"
              action.resumeRetryCount="100"
              queue.type="linkedList" queue.size="10000")
...
#  *.* @10.0.1.5:514           # использовал на этапе тестов, отправляет все логи 
```

5. Правим конфиг Nginx для отправки логов на Log сервер + оставляем crit логи на Web: 
```
vim /etc/nginx/nginx.conf

...
error_log /var/log/nginx/error.log crit;
error_log syslog:server=10.0.1.5:514,tag=nginx_error;
...
access_log syslog:server=10.0.1.5:514,tag=nginx_access;

```



### Настраиваем Log:

1. Разрешаем прием логов в `/etc/rsyslog.conf`:
```
# Provides TCP syslog reception
module(load="imtcp") # needs to be done just once
input(type="imtcp" port="514")

# Provides UDP syslog reception
module(load="imudp") # needs to be done just once
input(type="imudp" port="514")
```

2. Добавляем в конфиг разделение логов `nginx_access` и `nginx_error` по директориям: 
```
vim /etc/rsyslog.conf

if ($hostname == 'web') and ($programname == 'nginx_access') then {
    action(type="omfile" file="/var/log/rsyslog/web/nginx_access.log")
    stop
}

if ($hostname == 'web') and ($programname == 'nginx_error') then {
    action(type="omfile" file="/var/log/rsyslog/web/nginx_error.log")
    stop
}
```

