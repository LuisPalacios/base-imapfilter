
--
--  check_status()
--  --------------------------------------------------------------------
-- 
-- Obtiene el estado actual del mailbox y devuelve tres valores: 
--   número de mensajes existentes
--   número de mensajes recientes no leidos. 
--   número de mensajes no vistos
--                 
cuentaPersonal.INBOX:check_status()
cuentaCuarentena.INBOX:check_status()
                  
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

pre_filtersMovePersonal = {

  -- Emisores y/o temas que se son SPAM y que automáticamente quiero cargarme... 
  --
  { header = "From", p = "<un emisor que no te gusta>", moveto = cuentaCuarentena['INBOX'] },
  { header = "Subject", p = "<un tema que no quieres>", moveto = cuentaCuarentena['INBOX']  },
}

pre_filtersDeletePersonal = {

  -- Aquí pongo todos los mails que quiero cargarme directamente.. 
  --
  { header = "From", p = "<un emisor que quiero ignorar durante una temporada...>" },

}

---------------------------
--  Ejecución principal  --
---------------------------
--

-- Leo todo el correo Personal
	allmsgsPersonal  = cuentaPersonal.INBOX:select_all()

-- Aplico las reglas al correo Personal
	ruleDelete(allmsgsPersonal, pre_filtersDeletePersonal)
	ruleMove(allmsgsPersonal, pre_filtersMovePersonal)
	

