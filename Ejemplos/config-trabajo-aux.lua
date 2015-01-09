
--
--  check_status()
--  --------------------------------------------------------------------
-- 
-- Obtiene el estado actual del mailbox y devuelve tres valores: 
--   número de mensajes existentes
--   número de mensajes recientes no leidos. 
--   número de mensajes no vistos
--                 
cuentaTrabajo.INBOX:check_status()
cuentaArchivo.INBOX:check_status()
            
-----------------
--  Funciones  --
-----------------
--
-- parseRules para filtrar los mensajes usando una tabla de reglas

-- @param res         la tabla con los mensajes a filtrar
-- @param ruleTable   la tabla de reglas con las que hacer el matching de los mensajes
--
ruleMove = function ( res, ruleTable )
local subresults = {}
  for _,entry in pairs(ruleTable) do
    -- no uso match_field porque se baja el mensaje entero y es lento
    subresults = res:contain_field(entry["header"], entry["p"])
    if subresults:move_messages( entry["moveto"] ) == false then
      print("No puedo mover los menssajes !")
    end
  end
end

-- @param res         la tabla con los mensajes a filtrar
-- @param ruleTable   la tabla de reglas con las que hacer el matching de los mensajes
--
ruleDelete = function ( res, ruleTable )
local subresults = {}
  for _,entry in pairs(ruleTable) do
    -- no uso match_field porque se baja el mensaje entero y es lento
    subresults = res:contain_field(entry["header"], entry["p"])
    if subresults:delete_messages() == false then
      print("No puedo borrar los mensajes !")
    end
  end
end

-- @param res         la tabla con los mensajes a filtrar
-- @param ruleTable   la tabla de reglas con las que hacer el matching de los mensajes
--
ruleFlag = function ( res, ruleTable )
local subresults = {}
  for _,entry in pairs(ruleTable) do
    -- no uso match_field porque se baja el mensaje entero y es lento
    subresults = res:contain_field(entry["header"], entry["p"])
    subresults:add_flags({ 'Exec', '\\Seen' })
    subresults:unmark_seen()
  end
end

-----------------------
--  Filtros:         --
-----------------------
--

pre_filtersMoveTrabajo = {

  -- Ejemplo donde bloqueo IP's (ej. ficticias) que típicamente mandan spam
  { header = "Received" , p = "85.11.111.58", moveto = acc1['Trash'] },
  { header = "Received" , p = "176.16.16.16", moveto = acc1['Trash'] },
  
}

pre_filtersDeleteTrabajo = {

  -- Varias fuentes que borro directamente (algún día me daré de bajo :-)
  { header = "From", p = "tal-sitio.com" },
  { header = "From", p = "new.muypesados.es" },
  { header = "From", p = "promocion@tld.org" },

}

filtersMoveTrabajo = {

  -- Newsletters, las archivo...
  { header = "From", p = "bounce@emisor-newsleteers.com", moveto = cuentaArchivo['Archivo'] },

  -- Mailing lists, me interesan pero no en el Inbox, las archivo
  { header = "From", p = "noreply@servicios.talytal.com", moveto = cuentaArchivo['Archivo_TalTal'] },

  -- Departamentos
  { header = "Subject", p = "_Equipos_Ventas", moveto = cuentaArchivo['Ventas'] },
  { header = "Subject", p = "_Reuniones", moveto = cuentaArchivo['Reuniones'] },
  { header = "To", p = "mailinglist@empresa.com", moveto = cuentaArchivo['Archivo'] },


}

post_filtersMoveTrabajo = {

  -- Añadir aquí cualquier otra regla que me interese... 
  { header = "Subject" , p = "[SPAM?] ", moveto = cuentaArchivo['Junk'] },

}

---------------------------
--  Ejecución principal  --
---------------------------
--

-- Leo todo el correo Trabajo
   allmsgsTrabajo  = cuentaTrabajo.INBOX:select_all()

-- Aplico las reglas al correo del Trabajo
   ruleMove(allmsgsTrabajo, pre_filtersMoveTrabajo)
   ruleDelete(allmsgsTrabajo, pre_filtersDeleteTrabajo)
   ruleMove(allmsgsTrabajo, filtersMoveTrabajo)
   ruleMove(allmsgsTrabajo, post_filtersMoveTrabajo)
	
-------------------------
--  Mensajes complejos --
--  
--  Operadores:
--    +  OR
--    *  AND
--    -  NOT
-------------------------

msgs = cuentaTrabajo.INBOX:is_unseen() *
  cuentaTrabajo.INBOX:contain_from('Nombre_Persona') *
  cuentaTrabajo.INBOX:contain_subject('Invitaciones:')
msgs:move_messages(cuentaArchivo['Archivo'])

msgs = cuentaTrabajo.INBOX:contain_to('mi_usuario') *
  cuentaTrabajo.INBOX:contain_from('mi_jefe') +
  cuentaTrabajo.INBOX:contain_from('mi_superjefe')
msgs:add_flags({ 'Exec', '\\Seen' })
msgs:unmark_seen()

