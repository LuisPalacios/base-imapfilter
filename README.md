# Introducción

Contenedor base para hacer limpieza de correos con el programa imapfilter. Está automatizado en el Registry Hub de Docker [luispa/base-imapfilter](https://registry.hub.docker.com/u/luispa/base-imapfilter/) conectado con el proyecto GitHub [base-imapfilter](https://github.com/LuisPalacios/base-imapfilter). 


## Ficheros

* **Dockerfile**: Para crear la base de servicio.
* **do.sh**: Para arrancar el contenedor creado con esta imagen.
* **config.lua**: Ejemplo de fichero de configuración para imapfilter

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

Es importante que prepares un volumen persistente apuntando al fichero config.lua donde tenemos la configuración para imapfilter. En mi caso he dejado dicho fichero en la siguiente ubicación.

    - /Apps/data/correo/imapfilter/:/root/.imapfilter/
    
Dentro de este directorio deberemos terminar teneiendo el fichoer de certificados y el fichero de configuraicón

	- certificates
	- config.lua
    

# Instalación con certificados

En el caso de que tu(s) servidor(es) de correo utilicen SSL/TLS entonces es necesario que "aceptes" sus certificados. Esto ocurre la primera vez que se ejecuta imapfilter, creandose el fichero /root/.imapfilter/certificates. Dado que cada instalación va a ser diferente no he automatizado la aceptación de los mismos y por lo tanto la creación de este contenedor tiene dos pasos. 

El primer paso consiste en arrancar el contenedor manualmente con /bin/bash, ejecutar imapfilter y aceptar los certificados

    docker run --rm -t -i -v /Apps/data/correo/imapfilter/:/root/.imapfilter/ luispa/base-imapfilter /bin/bash
    ...
	:
	$ imapfilter
	:
	root@48dd8f3b633a:~/.imapfilter# imapfilter
	Server certificate subject: /C=ES/ST=Madrid/L=Mi querido pueblo/O=Org/OU=Clave SSL IMAP/CN=localhost/emailAddress=postmaster@tld.org
	Server certificate issuer: /C=ES/ST=Madrid/L=Mi querido pueblo/O=Org/OU=Clave SSL IMAP/CN=localhost/emailAddress=postmaster@tld.org
	Server key fingerprint: 08:C2:E3:93:17:D4:05:22:E9:C4:4C:BB:55:EE:BB:18
	(R)eject, accept (t)emporarily or accept (p)ermanently? p
	:


Una vez que tenemos ya "probado" que imapfilter funciona, el segundo y futuros arranques son normales, de modo que el filtrado de los correos se produce de manera desatendida. 

	docker run -v /Apps/data/correo/imapfilter/:/root/.imapfilter/ luispa/base-imapfilter

Nota: Ten en cuenta que el contenedor hace uso del cron para ejecutar imapfilter cada cierto tiempo. En el fichero do.sh verás cómo lo programo en mi caso y podrás adaptarlo a tu gusto. 


# Instalación ignorando certificados

Otra opción es que ignores los certificados. Basta con poner la línea siguiente en tu fichero config.lua para que se ingnoren los certificados del servidor IMAP. Ojo que es peligroso porque podrían suplantarlo.

	options.certificates = false

# Ejemplo config.lua



