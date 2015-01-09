#
# "imapfilter" by Luispa, Jan 2015
# 
# Un contenedor muy sencillo que solo va a dedicarse a 
# hacer limpieza de correos con el programa imapfilter
#
# Enlaces sobre este proyecto: 
#
# Sitio en GitHub         : https://github.com/LuisPalacios/base-imapfilter
# Automatización con FIG  : https://github.com/LuisPalacios/servicio-correo
# Apunte técnico          : http://www.luispa.com/?p=961
# 
# -----------------------------------------------------

#
# Desde donde parto...
#
FROM debian:jessie

# Autor de este Dockerfile
#
MAINTAINER Luis Palacios <luis@luispa.com>

# Pido que el frontend de Debian no sea interactivo
ENV DEBIAN_FRONTEND noninteractive

# Actualizo el sistema operativo e instalo mi propia base de 
# paquetes que siempre pongo en todos los containers. 
#
RUN apt-get update && \
    apt-get -y install 	locales \
    					net-tools \
                       	vim \
                       	supervisor \
                       	wget \
                       	curl \
                        rsyslog

# Preparo locales y Timezone
#
RUN locale-gen es_ES.UTF-8
RUN locale-gen en_US.UTF-8
RUN dpkg-reconfigure locales
RUN echo "Europe/Madrid" > /etc/timezone; dpkg-reconfigure -f noninteractive tzdata

# HOME
ENV HOME /root

# ------- ------- ------- ------- ------- ------- -------
# Instalo imapfilter desde los fuentes
# ------- ------- ------- ------- ------- ------- -------
#
# Instalo las librerías de desarrollo necesarias
RUN apt-get update && \
	apt-get -y install	make			\
						git				\
						liblua5.2-dev	\
    					libssl-dev		\
    					libpcre3-dev

# Descargo y compilo los fuentes
# Imapfilter queda instalado en /usr/local/bin
WORKDIR /root
RUN git clone https://github.com/lefcha/imapfilter.git
RUN cd /root/imapfilter && make INCDIRS=-I/usr/include/lua5.2 LIBLUA=-llua5.2 && make install

# Nota: Este contenedor ejecutará un script cada vez que arranque
# donde se espera encontrar los ficheros de configuración en /root/.imapfilter
# Ver do.sh en https://github.com/LuisPalacios/base-imapfilter

# Script "confcat"
# Durante el desarrollo de mis contenedores suelo usarlo mucho, así que siempre lo 
# dejo instalado. Es como "cat" pero elimina líneas de comentarios
RUN echo "grep -vh '^[[:space:]]*#' \"\$@\" | grep -v '^//' | grep -v '^;' | grep -v '^\$' | grep -v '^\!' | grep -v '^--'" > /usr/bin/confcat
RUN chmod 755 /usr/bin/confcat

# Directorio de trabajo
#
WORKDIR /root

#-----------------------------------------------------------------------------------

# Ejecutar siempre al arrancar el contenedor este script
#
ADD do.sh /do.sh
RUN chmod +x /do.sh
ENTRYPOINT ["/do.sh"]

#
# Si no se especifica nada se ejecutará lo siguiente: 
#
CMD ["/usr/bin/supervisord", "-n -c /etc/supervisor/supervisord.conf"]
