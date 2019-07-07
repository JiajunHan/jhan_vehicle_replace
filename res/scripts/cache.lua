-- A package acts as the central place for data storage

local cache = {}

-- Table for vehicles in the format of
-- { vehicleName = string, duration = { yearTo = int, yearFrom = int }, fileName = string }
cache.trams = {}
cache.buses = {}
cache.trucks = {}

cache.typeToVehicleTable = {
  bus = cache.buses,
  tram = cache.trams,
  truck = cache.trucks
}

-- Stores last used index
cache.typeToLastIndex = {
  bus = 0,
  tram = 0,
  truck = 0
}

cache.typeToToolName = {
  bus = "Replace all buses",
  tram = "Replace all trams",
  truck = "Replace all trucks"
}

cache.paramsKey = "vehicleNameIndex"

return cache
