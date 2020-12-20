local enabled = false

RegisterKeyMapping("+enable_test", "dope_perico Test", "keyboard", "k")

RegisterCommand(
  "+enable_test",
  function()
    Citizen.CreateThread(function()
      enabled = not enabled
      EnableIsland(enabled)
    end)
  end,
  false
)

RegisterCommand(
  "-enable_test",
  function()
    -- empty for chat
  end,
  false
)
