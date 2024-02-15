function plugindef()
    finaleplugin.RequireDocument = false
    return "0--slider_control.lua"
end

if finenv.IsRGPLua and not finenv.ConsoleIsAvailable then
    require('mobdebug').start()
end

local dialog = finale.FCCustomLuaWindow()
local str = finale.FCString()
local static = dialog:CreateStatic(0, 0)
static:SetWidth(150)

local slider = dialog:CreateSlider(0, 30)
slider:SetMinValue(0)
slider:SetMaxValue(10)
slider:SetThumbPosition(2)

str.LuaString = "Thumb position: " .. slider:GetThumbPosition()
static:SetText(str)

dialog:CreateOkButton()
dialog:CreateCancelButton()

dialog:RegisterHandleControlEvent(slider, function(ctrl)
    local thumb_pos = ctrl:GetThumbPosition()
    str.LuaString = "Thumb position: " .. tostring(thumb_pos)
    print(str.LuaString)
    static:SetText(str)
end)

dialog:RegisterMouseTrackingStarted(function(ctrl)
    local thumb_pos = ctrl:GetThumbPosition()
    print("Slider tracking started: " .. thumb_pos)
end)

dialog:RegisterMouseTrackingStopped(function(ctrl)
    local thumb_pos = ctrl:GetThumbPosition()
    print("Slider tracking stopped: " .. thumb_pos)
end)

local result = dialog:ExecuteModal(nil)
print("ExecuteModal returned: " .. result)

finenv.UI():AlertInfo("Thumb position: " .. tostring(slider:GetThumbPosition()), "")
