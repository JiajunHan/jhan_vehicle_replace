local cache = require "vehicle_replace_cache"

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
  elseif carrier == "ROAD" and capType == "PASSENGERS" then
    targetTable = cache.buses
  elseif carrier == "ROAD" then
    targetTable = cache.trucks
  else
    assert(false, "something wrong :(")
  end

  targetTable[md.description.name] = {
    file = fileName,
    duration = md.availability
  }

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
