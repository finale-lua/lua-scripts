function plugindef()
    finaleplugin.RequireDocument = false
    finaleplugin.MinJWLuaVersion = 0.71
    return "0--auto resize width test"
end

local mixin = require('library.mixin')

--local dlg = finale.FCCustomLuaWindow()
local dlg = mixin.FCMCustomWindow()
dlg:SetTitle(finale.FCString("Test Auto Resize Width"))

local y = 0

local ctrl_static = dlg:CreateStatic(0, y)
ctrl_static:SetAutoResizeWidth(true)
ctrl_static:SetWidth(0)
ctrl_static:SetText(finale.FCString("Short."))
y = y + 20

local ctrl_checkbox = dlg:CreateCheckbox(0, y)
ctrl_checkbox:SetAutoResizeWidth(true)
ctrl_checkbox:SetWidth(0)
ctrl_checkbox:SetText(finale.FCString("Short."))
y = y + 20

local ctrl_edit = dlg:CreateEdit(0, y)
ctrl_edit:SetAutoResizeWidth(true)
ctrl_edit:SetWidth(0)
ctrl_edit:SetText(finale.FCString("Short."))
y = y + 30

local ctrl_button = dlg:CreateButton(0, 70)
ctrl_button:SetAutoResizeWidth(true)
ctrl_button:SetWidth(0)
ctrl_button:SetText(finale.FCString("Short."))
y = y + 30

local ctrl_popup = dlg:CreatePopup(0, y)
ctrl_popup:SetAutoResizeWidth(true)
ctrl_popup:SetWidth(100)
for counter = 1, 3 do
    ctrl_popup:AddString(finale.FCString("This is long option text " .. counter .."."))
end
--ctrl_popup:SetText(finale.FCString("This is long option text 1\nThis is long option text 2\nThis is long option text 3\n"))
y = y + 20

local ctrl_radiobuttons = dlg:CreateRadioButtonGroup(0, y, 3)
local counter = 1
for rbtn in each(ctrl_radiobuttons) do
    rbtn:SetWidth(0)
    rbtn:SetAutoResizeWidth(true)
    rbtn:SetText(finale.FCString("This is long option text " .. counter .."."))
    counter = counter + 1
end

dlg:CreateOkButton()
dlg:ExecuteModal(nil)
