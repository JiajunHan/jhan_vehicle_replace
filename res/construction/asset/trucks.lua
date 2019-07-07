local cache = require "cache"
local utils = require "vehicle_replace_utils"
local log = require "log"

function data()
  log.openFile("trucks.con", "w")
  vehicleToDurationPairs = {}

  for k, v in pairs(cache.trucks) do
    -- table.insert(values, k)
    table.insert(vehicleToDurationPairs, {vehicleName = k, duration = v.duration})
  end

  local vehicleInfo = utils.processVehicleToDurationPairs(vehicleToDurationPairs, "vehicleNameIndex", "Replace Trucks")
  return {
    type = "ASSET_DEFAULT",
    description = {
      name = "trucks",
      description = "des"
    },
    autoRemoveable = true,
    categories = {"tools"},
    skipCollision = false,
    order = 1,
    params = vehicleInfo.params,
    updateFn = function(input)
      -- fake result that is required to return by this function.
      local result = {}

      result.models = {
        {id = "asset/rock_1.mdl", transf = {1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1}}
      }

      result.terrainAlignmentLists = {
        {
          type = "EQUAL",
          faces = {}
        }
      }
      -- end fake result

      -- If "No action" is selected or there is no selection change, do nothing.
      if input.vehicleNameIndex == 0 or input.vehicleNameIndex == cache.truckPreviousIndex then
        return result
      end

      -- Find selected vehicle.
      local selectedVehicle
      local currentYear = game.interface.getGameTime().date.year
      for i, v in ipairs(vehicleInfo.durationVehiclesPairList) do
        local duration = v.duration
        if currentYear >= duration.yearFrom and (duration.yearTo == 0 or currentYear < duration.yearTo) then
          local selectedName = v.vehicleNames[input.vehicleNameIndex + 1]
          selectedVehicle = cache.trucks[selectedName]
        end
      end

      cache.truckPreviousIndex = input.vehicleNameIndex

      if not selectedVehicle then
        return result
      end

      local modelFilePath = string.gsub(selectedVehicle.file, "res/models/model/(.*)", "%1")

      local vehicles =
        game.interface.getVehicles(
        {
          carrier = "ROAD"
        }
      )

      if #vehicles == 0 then
        return result
      end

      for i, id in ipairs(vehicles) do
        local oldVehicle = game.interface.getEntity(id).vehicles[1]

        if string.find(oldVehicle.fileName, "truck") then
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
      return result
    end
  }
end
