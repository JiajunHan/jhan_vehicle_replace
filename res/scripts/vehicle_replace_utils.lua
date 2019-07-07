require "tableutil"
local cache = require "cache"

local utils = {}

local function insertToAlterTable(vehicleName, year, isAdd, alterYearTable)
  if not alterYearTable[year] then
    alterYearTable[year] = {}
  end
  table.insert(alterYearTable[year], {vehicleName = vehicleName, isAdd = isAdd})
end

-- Remove first occurance of a item from a list, error if not found.
function utils.removeListItem(list, item)
  local targetIndex
  for i, v in ipairs(list) do
    if v == item then
      targetIndex = i
      break
    end
  end

  assert(targetIndex, "Value not found in list")
  table.remove(list, targetIndex)
end

function utils.getKeys(input)
  local result = {}
  for k, _ in pairs(input) do
    table.insert(result, k)
  end
  return result
end

-- Input would types ("bus", "tram", "trucks")
-- Result would be
-- {params = {'needed by construction definition'},
--   durationVehiclesPairList = {{duration = {yearFrom, yearTo}, vehicleNames = {string ...}} ...}}.
function utils.processVehicleToDurationPairs(type)
  -- Build vehicle to duration pair list
  local vehicleToDurationPairs = {}
  local currentVehicleTable = cache.typeToVehicleTable[type]

  for k, v in pairs(currentVehicleTable) do
    table.insert(vehicleToDurationPairs, {vehicleName = k, duration = v.duration})
  end

  -- Build a year to vehicle add / remove table.
  local alterYearToVehicleChanges = {}
  for _, pair in ipairs(vehicleToDurationPairs) do
    insertToAlterTable(pair.vehicleName, pair.duration.yearFrom, true, alterYearToVehicleChanges)
    insertToAlterTable(pair.vehicleName, pair.duration.yearTo, false, alterYearToVehicleChanges)
  end

  local keys = utils.getKeys(alterYearToVehicleChanges)
  table.sort(keys)

  assert(keys[1] == 0, "Ending year should represented as 0")
  assert(keys[2] == 1850, "Starting year should be 1850")

  -- Move first element 0 from beginning to end.
  table.remove(keys, 1)
  table.insert(keys, 0)

  local yearFrom
  local params = {}
  local values = {"No actions"}
  local durationVehiclesPairList = {}
  for i, yearTo in ipairs(keys) do
    if yearFrom then
      table.insert(
        params,
        {
          key = cache.paramsKey,
          name = cache.typeToToolName[type],
          values = table.copy(values),
          yearFrom = yearFrom,
          yearTo = yearTo
        }
      )

      table.insert(
        durationVehiclesPairList,
        {
          duration = {
            yearFrom = yearFrom,
            yearTo = yearTo
          },
          vehicleNames = table.copy(values)
        }
      )
    end

    for _, v in ipairs(alterYearToVehicleChanges[yearTo]) do
      if v.isAdd then
        table.insert(values, v.vehicleName)
      else
        utils.removeListItem(values, v.vehicleName)
      end
    end
    yearFrom = yearTo
  end

  local result = {
    params = params,
    durationVehiclesPairList = durationVehiclesPairList
  }

  return result
end

-- Generate update function for vehicles. The input type will only be "bus", "tram" and "truck"
function utils.replaceVehicleFunctionFactory(type, vehicleInfo)
  assert(type == "bus" or type == "tram" or type == "truck")
  -- Generate a fake result to be returned later
  local result = {
    models = {
      {id = "asset/rock_1.mdl", transf = {1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1}}
    },
    terrainAlignmentLists = {
      {
        type = "EQUAL",
        faces = {}
      }
    }
  }

  return function(input)
    -- If "No action" is selected or there is no selection change, do nothing.
    local vehicleNameIndex = input[cache.paramsKey]
    if vehicleNameIndex == 0 or vehicleNameIndex == cache.typeToLastIndex[type] then
      return result
    end

    -- Find selected vehicle.
    local selectedVehicle
    local currentVehicleTable = cache.typeToVehicleTable[type]
    local currentYear = game.interface.getGameTime().date.year
    for i, v in ipairs(vehicleInfo.durationVehiclesPairList) do
      local duration = v.duration
      if currentYear >= duration.yearFrom and (duration.yearTo == 0 or currentYear < duration.yearTo) then
        local selectedName = v.vehicleNames[vehicleNameIndex + 1]
        selectedVehicle = currentVehicleTable[selectedName]
      end
    end

    if not selectedVehicle then
      return result
    end

    local modelFilePath = string.gsub(selectedVehicle.file, "res/models/model/(.*)", "%1")

    local vehicles =
      game.interface.getVehicles(
      {
        carrier = (type == "tram" and "TRAM") or "ROAD"
      }
    )

    if #vehicles == 0 then
      return result
    end

    for i, id in ipairs(vehicles) do
      local oldVehicle = game.interface.getEntity(id).vehicles[1]

      -- Types happen to match the path of fileNames.
      if string.find(oldVehicle.fileName, type) then
        local newVehicles = {
          color = oldVehicle.color,
          logo = oldVehicle.logo,
          fileName = modelFilePath,
          -- Some vehicle has different load index with others, like DMG Cannstatt.
          -- Can't preserve exising config.
          loadConfig = {-1}
        }
        game.interface.replaceVehicle(id, {newVehicles})
      end
    end

    cache.typeToLastIndex[type] = vehicleNameIndex
    return result
  end
end

-- Create a function for a construction definition. Input types are "bus", "tram" or "truck"
function utils.constructionFunctionFatory(type)
  return function()
    local vehicleInfo = utils.processVehicleToDurationPairs(type)
    return {
      type = "ASSET_DEFAULT",
      description = {
        name = cache.typeToToolName[type],
        description = ""
      },
      autoRemoveable = true,
      categories = {"tools"},
      skipCollision = false,
      order = 1,
      params = vehicleInfo.params,
      updateFn = utils.replaceVehicleFunctionFactory(type, vehicleInfo)
    }
  end
end

return utils
