# OTUS_logging
rsyslog+auditd

### Настроен центральный сервер для сбора логов:
 - В вагранте подняты 2 машины web и log. На web поднят nginx. На log настроен центральный лог сервер через rsyslog.  
 - Настроен аудит следящий за изменением конфигов нжинкса. Все критичные логи с web собираются локально и удаленно. Все логи с nginx уходят на удаленный сервер (локально только критичные) логи аудита должны также уходить на удаленную систему


### Выполнение:
Подняты 2 виртуальные машины:
```
1. Web (ip 10.0.1.4)
2. Log (ip 10.0.1.5)
```

### Настраиваем Web: 
1. Устанавливаем Nginx `dnf install nginx`
2. Добавляем правила для `auditd` в конфиг файл:
```
vim /etc/audit/rules.d/audit.rules

## Audit of nginx configuration files changes
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
Пробуем изменять порт Nginx и смотрим логи: 



### Настраиваем Log:





