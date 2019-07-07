local log = require "log"
local cache = require "cache"

local function populateVehicles(fileName, data)
  local md = data.metadata

  if not md.transportVehicle then
    return data
  end

  local carrier = md.transportVehicle.carrier

  -- Only care about tram, bus and trucks
  if carrier ~= "TRAM" and carrier ~= "ROAD" then
    return data
  end

  local capType = md.transportVehicle.capacities[1].type
  local targetTable

  if carrier == "TRAM" then
    targetTable = cache.trams
    log.openFile("trams", "w")
  elseif carrier == "ROAD" and capType == "PASSENGERS" then
    targetTable = cache.buses
    log.openFile("buses", "w")
  elseif carrier == "ROAD" then
    targetTable = cache.trucks
    log.openFile("trucks", "w")
  else
    assert(false, "something wrong :(")
  end

  targetTable[md.description.name] = {
    file = fileName,
    duration = md.availability
  }
  log.table(targetTable)
  log.str("-----call stack-------")
  local info
  local i = 1

  repeat
    local info = debug.getinfo(i, "S")
    log.table(info)
    i = i + 1
  until info == nil

  return data
end

local function logAllModel(fileName, data)
  log.table(data)
  return data
end

function data()
  return {
    info = {
      minorVersion = 0,
      severityAdd = "NONE",
      severityRemove = "NONE",
      name = "Vehicle replace",
      description = "Replace all vehicles at once.",
      tags = {"Asset Mod"},
      authors = {
        {
          name = "jhan",
          role = "CREATOR"
        }
      },
      tags = {"Script Mod"}
    },
    runFn = function(settings)
      addModifier("loadModel", populateVehicles)
    end
  }
end
