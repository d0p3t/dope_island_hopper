local function VerifyConfig()
  local invalid = false

  if not Config then
    print("^1Could not find shared/config.lua!^7")
    invalid = true
  end

  if Config.Debug == nil or not Config.Marker or not Config.DrawDistance or not Config.ActivationDistanceScaler then
    print("^1Missing default values Debug, Marker, DrawDistance or ActivationDistanceScaler.^7")
    invalid = true
  end

  -- Check Config.Control
  if not Config.Control.Key or not Config.Control.Name then
    print("^1Invalid Control setting.^7")
    invalid = true
  end

  -- Check Config.TeleportLocations
  if not Config.TeleportLocations then
    print("^1Could not find TeleportLocations.^7")
    invalid = true
  else
    for index, location in ipairs(Config.TeleportLocations) do
      if not location.LosSantosCoordinate or not location.IslandCoordinate then
        print("^1Could not find Markers, LosSantosCoordinate or IslandCoordinate in teleport location " .. index .. ".^7")
        invalid = true
        break
      end

      if type(location.LosSantosCoordinate) ~= "vector3" or type(location.IslandCoordinate) ~= "vector3" then
        print("^1Invalid type for LosSantosCoordinate or IslandCoordinate in teleport location " .. index .. ". Type must be vector3^7")
        invalid = true
        break
      end

      if not location.LosSantosHeading or not location.IslandHeading then
        print("^1Could not find location headings.^7")
        invalid = true
      end
    end
  end

  if invalid then
    local resource = GetCurrentResourceName()
    print("^1You have one or more errors in your configuration file. Please check Config.lua.^7")
    print("^3Can't fix this issue yourself? Check the forum topic of" .. resource .. " on the Cfx.re forum.^7")
    print("^1Stopping " .. resource .. " ...^7")
    StopResource(GetCurrentResourceName())
  end
end

Citizen.CreateThread(
  function()
    VerifyConfig()
  end
)
