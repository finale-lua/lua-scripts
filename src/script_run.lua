function plugindef()
  -- This function and the 'finaleplugin' namespace
  -- are both reserved for the plug-in definition.
  finaleplugin.Author = "Jacob Winkler"
  finaleplugin.Copyright = "2022"
  finaleplugin.Version = ".1"
  finaleplugin.Date = "1/30/2022"
  return "Run Script", "Run Script", "Opens and executes a Lua script"
end

function run_script()
  local script_name = open_script()
  -- Will eventually add additional logic for previously opened scripts...
  dofile(script_name)
end

function open_script()
  local ui = finenv.UI()
  local run = finale.FCFileOpenDialog(ui)
  local str = finale.FCString()
  --
  run:Execute()
  run:GetFileName(str)
  return str.LuaString
end

run_script()

