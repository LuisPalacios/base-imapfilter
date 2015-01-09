
------------------------
--  Opciones globales --
------------------------

-- Numero de segundos a esperar ante no respuestas
options.timeout = 60
-- Crear la carpeta destino si al ir a escribir un mensaje no existe
options.create = true
-- Normalmente los mensajes que se marcaron como a borrar se borrarán 
-- al cerrar el buzon. Al poner 'expunge' a true se borran de forma inmediata
options.expunge = true
-- Cerrar la carpeta en uso al terminar las operaciones, implica que se
-- eliminen, en ese momento, los mensajes marcados como a borrar.
options.close = true
-- Implica que las carpetas creadas automáticamente sean suscritas (visibles).
options.subscribe = true
-- Activo la opción de usar STARTTLS por el puerto 443. Nota: En mi servidor
-- IMAP he desactivado el uso de SSL por estar desaconsejado.
options.starttls = true
-- Ignorar los certificados. NOTA: Opción MUY peligrosa si no sabes lo que 
-- estás haciendo. Cuando se conecta con un servidor SSL/TLS y esta opción 
-- está en "false" entonces "no" se muestra su certificado y se pide confirmación
-- al usuario antes de aceptarlo. Cuando está en 'true' (valor por defecto) sí 
-- se pide confirmación. Solo puedo recomendar ponerlo en 'false' si se 
-- tiene un control absoluto sobre el servidor, en caso contrario dejarlo en 'true'
options.certificates = false
-- Opciones para recuperar al máximo de errores del servidor
options.reenter = false
options.recover = errors

----------------
--  Cuentas   --
----------------
--
--  Crear una entrada para cada cuenta de correo sobre la que quiero actuar.
--  En este caso voy a leer desde mail.midominio.com, y en este ejemplo la
--  mayoría de los mails los borraré o los mandaré a cuarentena, para que 
--  sea analizado por otro contenedor "chatarrero" con spamassassin/amavis/clamav

cuentaPersonal = IMAP {
     server = 'mail.midominio.com',
     username = 'usuario@midominio.com',
     password = 'micontraseña',
}

cuentaCuarentena = IMAP {
     server = 'mail.midominio.com',
     username = 'spam-cuarentena@midominio.com',
     password = 'micontraseña',
}


---------------------
--  Loop infinito  --
---------------------
--
--  Cada 10 minutos se relee el fichero config-CUENTA-aux.lua o cada
--  vez que se modifica, por ejemplo para cambiar las rules. 
--
--  Con este loop garantizo que si el administrador quiere 
--  cambiar una rule lo pueda hacer. Si estoy siendo ejecutado
--  en un contenedor de Docker y el fichero config-CUENTA-aux.lua está
--  en un directorio persistente entonces consigo que se pueda
--  modificar y este script se de cuenta.
--

_, timestamp = pipe_from('stat -c %Y /root/.imapfilter/config-personal-aux.lua')
while (true) do

    dofile('/root/.imapfilter/config-personal-aux.lua')

    if not cuentaPersonal.INBOX:enter_idle() then
       posix.sleep(300)
    else
       print('salgo de enter_idle()')    
    end
end
