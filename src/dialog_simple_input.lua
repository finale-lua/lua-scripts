function plugindef()
  -- This function and the 'finaleplugin' namespace
  -- are both reserved for the plug-in definition.
  finaleplugin.Author = "Jacob Winkler"
  finaleplugin.Copyright = "2022"
  finaleplugin.Version = ".1"
  finaleplugin.Date = "1/30/2022"
  return "Simple Input Dialog", "Simple Input Dialog", "Opens a dialog box for user input"
end

function simple_input(title, text)
  local return_value = finale.FCString()
  return_value.LuaString = ""
  local str = finale.FCString()
  local min_width = 160
  --
  function format_ctrl(ctrl, h, w, st)
      ctrl:SetHeight(h)
      ctrl:SetWidth(w)
      str.LuaString = st
      ctrl:SetText(str)
  end -- function format_ctrl
  --
  title_width = string.len(title) * 6 + 54
  if title_width > min_width then min_width = title_width end
  text_width = string.len(text) * 6
  if text_width > min_width then min_width = text_width end
  --
  str.LuaString = title
  local dialog = finale.FCCustomLuaWindow()
  dialog:SetTitle(str)
  local descr = dialog:CreateStatic(0, 0)
  format_ctrl(descr, 16, min_width, text)
  local input = dialog:CreateEdit(0, 20)
  format_ctrl(input, 20, min_width, "") -- edit "" for defualt value
  dialog:CreateOkButton()
  dialog:CreateCancelButton()
  --
  function callback(ctrl)
  end -- callback
  --
  dialog:RegisterHandleCommand(callback)
  --
  if dialog:ExecuteModal(nil) == 1 then
    return_value.LuaString = input:GetText(return_value)
    --print(return_value.LuaString)
    return return_value.LuaString
  -- OK button was pressed
  end
end -- function simple_input


