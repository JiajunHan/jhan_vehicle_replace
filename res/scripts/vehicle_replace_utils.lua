require "tableutil"
local log = require "log"

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

-- Input would  {{vehicleName = string, duration = {yearFrom = int, yearTo = int}} ...}
-- Result would be
-- {params = {'needed by construction definition'},
--   durationVehiclesPairList = {{duration = {yearFrom, yearTo}, vehicleNames = {string ...}} ...}}.
function utils.processVehicleToDurationPairs(vehicleToDurationPairs, paramsKeyName, paramsName)
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
          key = paramsKeyName,
          name = paramsName,
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

  -- log.table(result, "params and durationVehiclesPairList")

  return result
end

return utils
