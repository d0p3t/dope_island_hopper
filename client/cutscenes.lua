function LoadCutscene(cut, flag1, flag2)
  if (not flag1) then
    RequestCutscene(cut, 8)
  else
    RequestCutsceneEx(cut, flag1, flag2)
  end
  while (not HasThisCutsceneLoaded(cut)) do Wait(0) end
  return
end

local function BeginCutsceneWithPlayer()
  local plyrId = PlayerPedId()
  local playerClone = ClonePed_2(plyrId, 0.0, false, true, 1)

  SetBlockingOfNonTemporaryEvents(playerClone, true)
  SetEntityVisible(playerClone, false, false)
  SetEntityInvincible(playerClone, true)
  SetEntityCollision(playerClone, false, false)
  FreezeEntityPosition(playerClone, true)
  SetPedHelmet(playerClone, false)
  RemovePedHelmet(playerClone, true)

  SetCutsceneEntityStreamingFlags('MP_1', 0, 1)
  RegisterEntityForCutscene(plyrId, 'MP_1', 0, GetEntityModel(plyrId), 64)

  Wait(10)
  StartCutscene(0)
  Wait(10)
  ClonePedToTarget(playerClone, plyrId)
  Wait(10)
  DeleteEntity(playerClone)
  Wait(50)
  DoScreenFadeIn(250)

  return playerClone
end

local function Finish(timer)
  local tripped = false

  repeat
    Wait(0)
    if (timer and (GetCutsceneTime() > timer))then
      DoScreenFadeOut(250)
      tripped = true
    end

    if (GetCutsceneTotalDuration() - GetCutsceneTime() <= 250) then
      DoScreenFadeOut(250)
      tripped = true
    end
  until not IsCutscenePlaying()
  if (not tripped) then
    DoScreenFadeOut(100)
    Wait(150)
  end
  return
end

local landAnim = {1, 2, 4}
local timings = {
  [1] = 9100,
  [2] = 17500,
  [4] = 25400
}

function BeginLeaving(isIsland)
  if (isIsland) then
    RequestCollisionAtCoord(-2392.838, -2427.619, 43.1663)

    LoadCutscene('hs4_nimb_isd_lsa', 8, 24)
    BeginCutsceneWithPlayer()
    Finish()
    RemoveCutscene()
  else
    RequestCollisionAtCoord(-1652.79, -3117.5, 13.98)

    LoadCutscene('hs4_lsa_take_nimb2')
    BeginCutsceneWithPlayer()

    Finish()
    RemoveCutscene()

    if (Config.Cutscenes.long) then
      LoadCutscene('hs4_nimb_lsa_isd', 128, 24)
      BeginCutsceneWithPlayer()
      Finish(165000)

      LoadCutscene('hs4_nimb_lsa_isd', 256, 24)
      BeginCutsceneWithPlayer()
      Finish(170000)

      LoadCutscene('hs4_nimb_lsa_isd', 512, 24)
      BeginCutsceneWithPlayer()
      Finish(175200)
      RemoveCutscene()
    end
  end
end

function BeginLanding(isIsland)
  if (isIsland) then
    RequestCollisionAtCoord(-1652.79, -3117.5, 13.98)
    local flag = landAnim[ math.random( #landAnim ) ]
    LoadCutscene('hs4_lsa_land_nimb', flag, 24)
    BeginCutsceneWithPlayer()
    Finish(timings[flag])
    RemoveCutscene()
  else
    LoadCutscene('hs4_nimb_lsa_isd_repeat')

    RequestCollisionAtCoord(-2392.838, -2427.619, 43.1663)
    BeginCutsceneWithPlayer()

    Finish()
    RemoveCutscene()
  end
end