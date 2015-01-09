# Introducción

Contenedor base para hacer limpieza de correos con el programa imapfilter. Está automatizado en el Registry Hub de Docker [luispa/base-imapfilter](https://registry.hub.docker.com/u/luispa/base-imapfilter/).

Enlaces relacionados con este proyecto: 

* Automatizado desde GitHub : [base-imapfilter](https://github.com/LuisPalacios/base-imapfilter)
* Automatización con FIG    : [servicio-correo](https://github.com/LuisPalacios/servicio-correo))
* Apunte técnico            : [Asistente de filtrado de correo en Linux](http://www.luispa.com/?p=961)


## Ficheros

* **Dockerfile**: Para crear la base de servicio.
* **do.sh**: Para arrancar el contenedor creado con esta imagen.
* **config-__.lua**: Ejemplos de ficheros de configuración

## Instalación de la imagen

Para usar la imagen desde el registry de docker hub

    totobo ~ $ docker pull luispa/base-imapfilter


## Clonar el repositorio

Si quieres clonar el repositorio este es el comando poder trabajar con él directamente

    ~ $ clone https://github.com/LuisPalacios/docker-imapfilter.git

Luego puedes crear la imagen localmente con el siguiente comando

    $ docker build -t luispa/base-imapfilter ./


# Configuración


## Volúmenes

Es importante que prepares un volumen persistente donde imapfilter espera encontrar su(s) fichero(s) de configuración. En mi caso es el siguiente: 

    - /Apps/data/correo/imapfilter/:/root/.imapfilter/
    
Dentro de este directorio tendremos el fichero con los certificados SSL/TLS de tus servidores y además el(los) fichero(s) de configuraicón

	- certificates
	- config*.lua


## Variables

### FLUENTD_LINK

Es opcional, si quieres activar el envío de logs a un agregador, usa la siguiente variable: 

    FLUENTD_LINK:    "servidor-agregador.tld.org:24224"
    
Si quieres ver un ejemplo sobre cómo instalarte tu propio agregador de Logs, échale un vistazo a este proyecto: [servicio-log](https://github.com/LuisPalacios/servicio-log). 


### IMAPFILTER_INSTANCIAS

Este contenedor va a crear una instancia de imapfilter por cada cuenta de correo. La razón reside en que en mi caso tengo varias cuentas y empleo la técnica de loop infinito con imap-idle para que el servidor notifique los cambios a imapfilter. Dado que imapfilter no soporta imap-idle multicuenta entonces es necesario tener varias instancias.

Esa es la razón por la que empleo la siguiente variable:

	IMAPFILTER_INSTANCIAS="cuenta1, cuenta2, ..."

Esta variable define el nombre de cada una de las cuentas que deseas filtrar. El número de instancias viene definido por el número de items separados por comas. Si tu caso es más sencillo y solo tienes una única cuenta entonces lo mejor es "NO" definir la variable

Si no se define esta variable entonces se asume que solo ejecutará una única instancia, de hecho se establece que la variable IMAPFILTER_INSTANCIAS es igual a "cuenta" y por lo tanto el nombre del fichero de configuración que espera encontrar es:

	/root/.imapfilter/config-cuenta.lua

El nombre de los items identifica el nombre de los ficheros de configuración, así para una variable con dos items:

	IMAPFILTER_INSTANCIAS="cuentaPersonal, cuentaTrabajo"
	
Los ficheros de configuración que se utilizarán serán:

	/root/.imapfilter/config-cuentaPersonal.lua
	/root/.imapfilter/config-cuentaTrabajo.lua

Para más información ver el script do.sh.
    

### Ejecutar con certificados

En el caso de que tu(s) servidor(es) de correo utilicen SSL/TLS entonces tendrás que aceptar manualmente sus certificados. Ocurre la primera vez que se ejecuta imapfilter, creandose el fichero /root/.imapfilter/certificates. No he automatizado la aceptación de los mismos y por lo tanto, si deseas aceptar los certificados entonces tendrás que ejecutar este contenedor en dos pasos: 

#### Paso 1: Arranque manual y aceptación de certificados: 


    $ docker run --rm -t -i -e IMAPFILTER_INSTANCIAS="personal, trabajo" -v /Apps/data/correo/imapfilter/:/root/.imapfilter/ luispa/base-imapfilter /bin/bash
	
	:
	root@48dd8f3b633a:~/.imapfilter# imapfilter -c /root/.imapfilter/config-personal.lua
	Server certificate subject: /C=ES/ST=Madrid/L=Mi querido pueblo/O=Org/OU=Clave SSL IMAP/CN=localhost/emailAddress=postmaster@tld.org
	Server certificate issuer: /C=ES/ST=Madrid/L=Mi querido pueblo/O=Org/OU=Clave SSL IMAP/CN=localhost/emailAddress=postmaster@tld.org
	Server key fingerprint: 08:C2:E3:93:17:D4:05:22:E9:C4:4C:BB:55:EE:BB:18
	(R)eject, accept (t)emporarily or accept (p)ermanently? p
	:
	:
	root@48dd8f3b633a:~/.imapfilter# imapfilter -c /root/.imapfilter/config-trabajo.lua
	Server certificate subject: /C=ES/ST=Almeria/L=Garrucha/O=Org/OU=Clave SSL IMAP/CN=localhost/emailAddress=postmaster@tld.org
	Server certificate issuer: /C=ES/ST=Almeria/L=Garrucha/O=Org/OU=Clave SSL IMAP/CN=localhost/emailAddress=postmaster@tld.org
	Server certificate issuer: /C=ES/ST=Madrid/L=Mi querido pueblo/O=Org/OU=Clave SSL IMAP/CN=localhost/	Server key fingerprint: 12:32:43:53:67:D4:35:22:E9:C4:4C:BB:55:EE:BB:18
	(R)eject, accept (t)emporarily or accept (p)ermanently? p
	:

#### Paso 2: Arranques sucesivos

Una vez que tenemos ya "probado" que imapfilter funciona, el segundo y futuros arranques son normales, de modo que el filtrado de los correos se produce de manera desatendida. 

	docker run --rm -t -i -e IMAPFILTER_INSTANCIAS="personal, trabajo" -v /Apps/data/correo/imapfilter/:/root/.imapfilter/ luispa/base-imapfilter



### Ejecutar ignorando certificados

Otra opción es que ignores los certificados. Basta con poner la línea siguiente en tu fichero config*.lua para que se ingnoren los certificados del servidor IMAP. Ojo que es peligroso porque podrían suplantarlo, así que solo te recomiendo usarlo en caso de que controles perfectamente a tu servidor.

	options.certificates = false

