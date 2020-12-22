local IsOnIsland = false
local IsInSideTeleportLocation = false
local ClosestTeleportLocation = nil
local IsTeleporting = false
local PedCoordinates = vector3(0.0, 0.0, 0.0)

local IslandBounds = {
  x1 = 6093.88,
  y1 = -5966.44,
  x2 = 3283.17,
  y2 = -4199.8
}

local Blips = {}

local function GetFromCoordinate(location)
  local coordinate = location.LosSantosCoordinate
  local heading = location.LosSantosHeading
  if IsOnIsland then
    coordinate = location.IslandCoordinate
    heading = location.IslandHeading
  end

  return coordinate, heading
end

local function GetToCoordinate(location)
  local coordinate = location.IslandCoordinate
  local heading = location.IslandHeading

  if IsOnIsland then
    coordinate = location.LosSantosCoordinate
    heading = location.LosSantosHeading
  end

  return coordinate, heading
end

local function CreateNewBlips()
  for _, blip in pairs(Blips) do
    RemoveBlip(blip)
  end

  Blips = {}

  for _, location in pairs(Config.TeleportLocations) do
    local blip = nil
    local blipName = Config.Blip.LosSantosName
    if not IsOnIsland then
      blip = AddBlipForCoord(location.LosSantosCoordinate.x, location.LosSantosCoordinate.y, location.LosSantosCoordinate.z)
    else
      blip = AddBlipForCoord(location.IslandCoordinate.x, location.IslandCoordinate.y, location.IslandCoordinate.z)
      blipName = Config.Blip.IslandName
    end

    if blip then
      SetBlipAsShortRange(blip, Config.Blip.MinimapOnly)
      SetBlipSprite(blip, Config.Blip.Sprite)
      SetBlipColour(blip, Config.Blip.Color)
      SetBlipScale(blip, Config.Blip.Size)
      SetBlipDisplayIndicatorOnBlip(blip, false)
      BeginTextCommandSetBlipName("STRING")
      AddTextComponentSubstringPlayerName(blipName)
      EndTextCommandSetBlipName(blip)
    end
    table.insert(Blips, blip)
  end
end

local function DisplayTeleportHelpText()
  local key = Config.Control

  if not key or not IsInSideTeleportLocation then
    return
  end

  local destination = "Cayo Perico"
  if IsOnIsland then
    destination = "Los Santos"
  end

  BeginTextCommandDisplayHelp("DOPE_PERICO_HELP")
  AddTextComponentSubstringPlayerName(key.Name)
  AddTextComponentSubstringPlayerName(destination)
  EndTextCommandDisplayHelp(0, false, false, -1)
end

local function ShowMarker()
  local marker = Config.Marker
  local startCoordinate = GetFromCoordinate(ClosestTeleportLocation)
  local endCoordinate = GetToCoordinate(ClosestTeleportLocation)

  -- Some config issue
  if not marker or not startCoordinate or not endCoordinate then
    return
  end

  -- Draw marker
  DrawMarker(
    marker.Type,
    startCoordinate.x,
    startCoordinate.y,
    startCoordinate.z,
    0.0,
    0.0,
    0.0,
    0.0,
    0.0,
    0.0,
    marker.Size,
    marker.Size,
    marker.Size,
    marker.Color.Red,
    marker.Color.Green,
    marker.Color.Blue,
    marker.Color.Alpha,
    false,
    true,
    2,
    nil,
    nil,
    nil,
    false
  )
end

local function GetClosestLocation()
  local closestLocation = Config.TeleportLocations[1]
  local closestLocationCoords = GetFromCoordinate(closestLocation)

  for index, location in pairs(Config.TeleportLocations) do
    local startCoordinate = GetFromCoordinate(location)

    local distance = #(PedCoordinates - startCoordinate)
    local currentClosestDistance = #(PedCoordinates - closestLocationCoords)

    if distance < currentClosestDistance then
      closestLocation = location
      closestLocationCoords = startCoordinate
    end
  end

  ClosestTeleportLocation = closestLocation

  local dist = #(PedCoordinates - closestLocationCoords)
  if #(PedCoordinates - closestLocationCoords) < Config.DrawDistance then
    IsInSideTeleportLocation = true
  end
end

local function IsPointInsideRectangle(x, y, x1, y1, x2, y2)
  return (x1 < x and x < x2) and (y1 < y and y < y2)
end

-- Refresh client's ped coordinates only once 500ms
Citizen.CreateThread(
  function()
    if IsScreenFadedOut() then
      DoScreenFadeIn(500)
    end
    while true do
      PedCoordinates = GetEntityCoords(PlayerPedId(), true)
      Wait(500)
    end
  end
)

Citizen.CreateThread(
  function()
    local waitTime = 500
    AddTextEntry("DOPE_PERICO_HELP", "Press ~a~ to teleport to ~a~")
    CreateNewBlips()
    while true do
      Wait(waitTime)

      if not IsInSideTeleportLocation then
        GetClosestLocation()
      else
        local closestLocationCoords = GetFromCoordinate(ClosestTeleportLocation)

        local distance = #(PedCoordinates - closestLocationCoords)
        if distance > 20.0 then
          IsInSideTeleportLocation = false
          waitTime = 500
        else
          waitTime = 0

          if distance < (Config.Marker.Size * Config.ActivationDistanceScaler) then
            DisplayTeleportHelpText()
          end
          ShowMarker()
        end
      end
    end
  end
)

RegisterKeyMapping("+dope_perico", "Teleport to/from Cayo Perico Island", "keyboard", Config.Control.Key)

RegisterCommand(
  "+dope_perico",
  function()
    if not IsInSideTeleportLocation then
      return
    end

    local endCoordinate, endHeading = GetToCoordinate(ClosestTeleportLocation)

    if not IsTeleporting then
      Citizen.CreateThread(
        function()
          if not IsPlayerTeleportActive() then
            IsTeleporting = true

            local ped = PlayerPedId()
            FreezeEntityPosition(ped, true)
            if IsScreenFadedIn() then
              DoScreenFadeOut(500)
              while not IsScreenFadedOut() do
                Wait(50)
              end
            end

            if (Config.Cutscenes.enabled) then BeginLeaving(IsOnIsland) end

            EnableIsland(not IsOnIsland)
                      
            if (Config.Cutscenes.enabled) then BeginLanding(IsOnIsland) end

            StartPlayerTeleport(PlayerId(), endCoordinate.x, endCoordinate.y, endCoordinate.z, endHeading, true, true, false)

            local start = GetGameTimer()
            while IsPlayerTeleportActive() do
              if GetGameTimer() - start > 20000 then
                print("^1Could not teleport. Report this to server administrator(s).^7")
                if IsScreenFadedOut() then
                  DoScreenFadeIn(0)
                end
                return
              end
              Wait(500)
            end

            SetGameplayCamRelativePitch(0.0, 1.0)
            SetGameplayCamRelativeHeading(0.0)

            if IsScreenFadedOut() then
              DoScreenFadeIn(1000)
              while not IsScreenFadedIn() do
                Wait(50)
              end
            end

            IsTeleporting = false
            IsOnIsland = not IsOnIsland

            CreateNewBlips()
            ToggleIslandPathNodes(IsOnIsland)
            FreezeEntityPosition(ped, false)
          end
        end
      )
    end
  end,
  false
)

RegisterCommand(
  "-dope_perico",
  function()
    -- empty to prevent chat message
  end,
  false
)
