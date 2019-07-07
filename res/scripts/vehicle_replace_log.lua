local log = {}
local pretty = require "pl.pretty"
local file
local currentFileName

function log.openFile(fileName, mode)
  if currentFileName == fileName then
    return
  end

  currentFileName = fileName

  file =
    io.open(
    "/home/hanjiajun/.steam/steam/steamapps/common/Transport Fever/mods/jhan_vehicle_replace_1/log/" ..
      fileName .. ".log",
    mode
  )
  assert(file ~= nil, "file is not init successfully")
  file:write("file opened for " .. fileName .. "\n")
end

function log.str(str)
  assert(file ~= nil, "file is not open before write")
  if str == nil then
    file:write("nil" .. "\n")
  else
    file:write(str .. "\n")
  end
end

function log.table(table, desc)
  desc = desc or ""
  log.str("-------" .. desc .. "-------------\n")
  file:write(pretty.write(table))
  file:write("\n")
  log.str("--------------------------\n")
end

return log
