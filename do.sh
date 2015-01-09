#!/bin/bash
#
# Punto de entrada para el servicio "imapfilter" by Luispa, Jan 2015
#
# Enlaces sobre este proyecto: 
#
# Sitio en GitHub         : https://github.com/LuisPalacios/base-imapfilter
# Automatización con FIG  : https://github.com/LuisPalacios/servicio-correo
# Apunte técnico          : http://www.luispa.com/?p=961
# 
# Activar el debug de este script:
# set -eux


##################################################################
#
# VARIABLE "IMAPFILTER_INSTANCIAS"
#
##################################################################

## Instancias de imapfilter. El número de instancias viene definido
#  por el número de items separados por comas. 
#
#  Si no se define esta variable entonces se asume que solo 
#  ejecutará una única instancia y el nombre del fichero que
#  debe existir tiene que tener el nombre siguiente: 
#
#  /root/.imapfilter/config-cuenta.lua
#
: ${IMAPFILTER_INSTANCIAS:="cuenta"}

#  El nombre de los items identifica el nombre de los ficheros de
#  configuración. Ejemplo, para una variable con dos items:
#
#  IMAPFILTER_INSTANCIAS="cuentaPersonal, cuentaTrabajo"
#
#  Los ficheros de configuración que se utilizarán serán:
#
#  /root/.imapfilter/config-cuentaPersonal.lua
#  /root/.imapfilter/config-cuentaTrabajo.lua
#
# El comando siguiente traspasa al array INSTANCIA[] el contenido
# de la variable IMAPFILTER_INSTANCIAS
#
# Ejemplos de uso:
#   ${#INSTANCIA[@]} - Número de instancias
#   ${INSTANCIA[n]}  - Contenido en la posición 'n' dentro del array
#
# Recibo los items en "INSTANCIA"
INSTANCIA=(${IMAPFILTER_INSTANCIAS//,/ })
echo "IMAPFILTER_INSTANCIAS=\"${IMAPFILTER_INSTANCIAS}\""
echo "Número de instancias a ejecutar: ${#INSTANCIA[@]}"


##################################################################
#
# PREPARAR EL CONTENEDOR
#
##################################################################
	
############
# Permisos
############
if [ -f "/root/.imapfilter/certificates" ]; then
	chmod go-rwx /root/.imapfilter/certificates
	chown root:root /root/.imapfilter/certificates
fi
chmod go-rwx /root/.imapfilter/config*.lua
chown root:root /root/.imapfilter/config*.lua


#########################
# Programación (obsoleto)
#########################
#
# Lo utilicé al principio aunque ahora ya no uso esta técnica, es
# otra alternativa, en vez de dejar imapfilter en un loop infinito
# se puede ejecutar in-and-out, es decir, se ejecuta y termina 
# cuando nos interesa invocarlo. 
#
# Si tu fichero config*.lua trabaja en ese modo dejo aquí estas 
# líneas a modo de ejemplo, cómo configurar cron en el contenedor: 
#
## cat > /root/instala-en-cron.txt <<-EOF_CRON_INSTALA
## 
## MAILTO=""
## 5,10,15,20,25,30,35,40,45,50,55,0 * * * * [ \`pidof imapfilter\` ] || imapfilter > /dev/null 2>&1
##
## EOF_CRON_INSTALA
## crontab /root/instala-en-cron.txt


#############
# Supervisord
#############
cat > /etc/supervisor/conf.d/supervisord.conf <<-EOF_SUPERVISOR

[unix_http_server]
file=/var/run/supervisor.sock 					; Path al fichero socket

[inet_http_server]
port = 0.0.0.0:9001								; Permitir la conexión desde el browser

[supervisord]
logfile=/var/log/supervisor/supervisord.log 	; Fichero de log
logfile_maxbytes=10MB 							; Tamaño máximo del log antes de rotarlo
logfile_backups=2 								; Número de logfiles que se guardan
loglevel=error 									; info, debug, warn, trace
pidfile=/var/run/supervisord.pid 				; localización del pidfile
minfds=1024 									; número de startup file descriptors
minprocs=200 									; número de process descriptors
user=root 										; usuario por defecto
childlogdir=/var/log/supervisor/ 				; dónde vivirán los logs de los childs

nodaemon=false 									; Ejecutar supervisord como un daemon (util para debugging)
;nodaemon=true 									; Ejecutar supervisord interactivo (producción)
	
[rpcinterface:supervisor]
supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface

[supervisorctl]
serverurl=unix:///var/run/supervisor.sock		; Usar URL unix:// para un socket unix

EOF_SUPERVISOR


######################################
# Añadir instancias a supervisord.conf
######################################

HAY_INSTANCIA=0
echo "============"
for i in "${!INSTANCIA[@]}"
do
	theFile="config-${INSTANCIA[i]}.lua"
	if [ -f /root/.imapfilter/${theFile} ]; then 
		cat >> /etc/supervisor/conf.d/supervisord.conf <<-EOF_INSTANCIA_SUPERVISORD
		
		[program:imapfilter_${INSTANCIA[i]}]
		process_name = imapfilter
		command=/bin/bash -c "sleep 5 && /usr/local/bin/imapfilter -c /root/.imapfilter/config-${INSTANCIA[i]}.lua"    
		startsecs = 0
		autorestart = true
		
		EOF_INSTANCIA_SUPERVISORD
		echo "${theFile} - El fichero existe, imapfilter queda programado y se ejecutará"
		HAY_INSTANCIA=1
	else 
		echo "${theFile} - El fichero NO EXISTE... AVISO !!! no se programará el arranque de imapfilter para esta instancia."
	fi
done
echo "============"

## Si no hay ningún fichero de configuración... para que "ejecutarme" ???
#
#
if [ "${HAY_INSTANCIA}" = "0" ]; then
	echo >&2 "error: No existe ningún fichero de configuración, debe crear al menos uno para que pueda funcionar". 
	exit 1
fi


############
# rsyslogd 
############

# En el caso de desear que RSYSLOGD arranque y además envíe logs a un 
# agregador, entonces hay que configurar la variable FLUENTD_LINK
#
# Ejemplo: -e FLUENTD_LINK="tuagregador.tld.org:24224"
#  
if [ ! -z "${FLUENTD_LINK}" ]; then
	
	# Averiguo Host y Puerto del agregador
	fluentdHost=${FLUENTD_LINK%%:*}
	fluentdPort=${FLUENTD_LINK##*:}

	#
	echo "Configuro rsyslog.conf"
	cat > /etc/rsyslog.conf <<-EOF_RSYSLOG
	
	\$LocalHostName chatarrero
	\$ModLoad imuxsock # provides support for local system logging
	#\$ModLoad imklog   # provides kernel logging support
	#\$ModLoad immark  # provides --MARK-- message capability
	
	# provides UDP syslog reception
	#\$ModLoad imudp
	#\$UDPServerRun 514
	
	# provides TCP syslog reception
	#\$ModLoad imtcp
	#\$InputTCPServerRun 514
	
	# Activar para debug interactivo
	#
	#\$DebugFile /var/log/rsyslogdebug.log
	#\$DebugLevel 2
	
	\$ActionFileDefaultTemplate RSYSLOG_TraditionalFileFormat
	
	\$FileOwner root
	\$FileGroup adm
	\$FileCreateMode 0640
	\$DirCreateMode 0755
	\$Umask 0022
	
	#\$WorkDirectory /var/spool/rsyslog
	#\$IncludeConfig /etc/rsyslog.d/*.conf
	
	# Dirección del Host:Puerto agregador de Log's con Fluentd
	#
	*.* @@${fluentdHost}:${fluentdPort}
	
	# Activar para debug interactivo
	#
	# *.* /var/log/syslog			
	
	EOF_RSYSLOG
		

	##
	# Añado rsyslogd a supervisord.conf
	##
	cat >> /etc/supervisor/conf.d/supervisord.conf <<-EOF_SUPERVISOR_RSYSLOGD
	
	[program:rsyslog]
	process_name = rsyslogd
	command=/usr/sbin/rsyslogd -n
	startsecs = 1
	autorestart = true
	
	EOF_SUPERVISOR_RSYSLOGD

fi


##################################################################
#
# EJECUCIÓN DEL COMANDO SOLICITADO
#
##################################################################
#
exec "$@"
