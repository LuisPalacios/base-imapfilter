#!/bin/bash
#
# Punto de entrada para el servicio imapfilter
#
# Activar el debug de este script:
# set -eux

##################################################################
#
# main
#
##################################################################

# Averiguar si necesito configurar por primera vez
#
CONFIG_DONE="/.config_imapfilter_done"
NECESITA_PRIMER_CONFIG="si"
if [ -f ${CONFIG_DONE} ] ; then
    NECESITA_PRIMER_CONFIG="no"
fi

##################################################################
#
# PREPARAR EL CONTAINER POR PRIMERA VEZ
#
##################################################################

# Necesito configurar por primera vez?
#
if [ ${NECESITA_PRIMER_CONFIG} = "si" ] ; then
	
	############
	#
	# Permisos
	#
	############
	if [ -f "/root/.imapfilter/certificates" ]; then
		chmod go-rwx /root/.imapfilter/certificates
		chown root:root /root/.imapfilter/certificates
	fi
	if [ -f "/root/.imapfilter/config.lua" ]; then
		chmod go-rwx /root/.imapfilter/config.lua
		chown root:root /root/.imapfilter/config.lua
	fi



	############
	#
	# Programación
	#
	############
	#
	# Utilizo cron para programar que cada 'n' minutos se ejecute imapfilter, 
	# En mi ejemplo lo hago cada 3 minutos, algo agresivo, lo normal sería 
	# hacerlo cada 5 o 10 minutos.
	#
	#cat > /root/instala-en-cron.txt <<-EOF_CRON_INSTALA
	#
	#MAILTO=""
	#5,10,15,20,25,30,35,40,45,50,55,0 * * * * [ \`pidof imapfilter\` ] || imapfilter > /dev/null 2>&1
	#
	#EOF_CRON_INSTALA
	#crontab /root/instala-en-cron.txt



	############
	#
	# Supervisor
	# 
	############

	cat > /etc/supervisor/conf.d/supervisord.conf <<-EOF_SUPERVISOR
	
	[unix_http_server]
	file=/var/run/supervisor.sock 					; path to your socket file
	
	[inet_http_server]
	port = 0.0.0.0:9001								; allow to connect from web browser to supervisord
	
	[supervisord]
	logfile=/var/log/supervisor/supervisord.log 	; supervisord log file
	logfile_maxbytes=50MB 							; maximum size of logfile before rotation
	logfile_backups=10 								; number of backed up logfiles
	loglevel=error 									; info, debug, warn, trace
	pidfile=/var/run/supervisord.pid 				; pidfile location
	minfds=1024 									; number of startup file descriptors
	minprocs=200 									; number of process descriptors
	user=root 										; default user
	childlogdir=/var/log/supervisor/ 				; where child log files will live
	
	nodaemon=false 									; run supervisord as a daemon when debugging
	;nodaemon=true 									; run supervisord interactively (production)
 	
	[rpcinterface:supervisor]
	supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface
	
	[supervisorctl]
	serverurl=unix:///var/run/supervisor.sock		; use a unix:// URL for a unix socket 
	
	#[program:cron]
	#process_name = cron
	#command=/usr/sbin/cron -f
	#startsecs = 0
	#autorestart = true
	
	[program:imapfilter]
	process_name = imapfilter
	command=/usr/local/bin/imapfilter
	startsecs = 0
	autorestart = true
	
	#
	# DESCOMENTAR PARA DEBUG o SI QUIERES SSHD
	#
	#[program:sshd]
	#process_name = sshd
	#command=/usr/sbin/sshd -D
	#startsecs = 0
	#autorestart = true
	
	EOF_SUPERVISOR

	############
	#
	# rsyslogd 
	#
	############
	
	## Servidor:Puerto por el que escucha el agregador de Logs (fluentd)
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
		## Añado rsyslogd a supervisord.conf
		##
		cat >> /etc/supervisor/conf.d/supervisord.conf <<-EOF_SUPERVISOR_RSYSLOGD
	
		[program:rsyslog]
		process_name = rsyslogd
		command=/usr/sbin/rsyslogd -n
		startsecs = 0
		autorestart = true
	
		EOF_SUPERVISOR_RSYSLOGD

	fi


    #
    # Creo el fichero de control para que el resto de 
    # ejecuciones no realice la primera configuración
    > ${CONFIG_DONE}
	echo "Termino la primera configuración del contenedor"
	
fi

##################################################################
#
# EJECUCIÓN DEL COMANDO SOLICITADO
#
##################################################################
#
exec "$@"
