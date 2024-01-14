function plugindef()
    finaleplugin.RequireDocument = false
    finaleplugin.MinJWLuaVersion = 0.71
    return "0--auto resize width test"
end

local mixin = require('library.mixin')

function create_dialog()
    --local dlg = finale.FCCustomLuaWindow()
    local dlg = mixin.FCXCustomLuaWindow()
    dlg:SetTitle(finale.FCString("Test Auto Resize Width"))

    local y = 0

    local ctrl_static = dlg:CreateStatic(0, y)
    ctrl_static:SetAutoResizeWidth(true)
    ctrl_static:SetWidth(20)
    ctrl_static:SetText(finale.FCString("This is long option text."))
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
    --ctrl_edit:SetMeasurement(1, finale.MEASUREMENTUNIT_DEFAULT)
    y = y + 30

    local ctrl_button = dlg:CreateButton(0, 70)
    ctrl_button:SetAutoResizeWidth(true)
    ctrl_button:SetWidth(0)
    ctrl_button:SetText(finale.FCString("Short."))
    y = y + 30

    local ctrl_popup = dlg:CreatePopup(0, y)
    ctrl_popup:SetAutoResizeWidth(true)
    ctrl_popup:SetWidth(0)
    for counter = 1, 3 do
        if counter == 3 then
            ctrl_popup:AddString(finale.FCString("This is long option text " .. counter .. "."))
        else
            ctrl_popup:AddString(finale.FCString("Short " .. counter .. "."))
        end
    end
    ctrl_popup:SetSelectedItem(2)
    y = y + 20

    local ctrl_cbobox = dlg:CreateComboBox(0, y)
    ctrl_cbobox:SetAutoResizeWidth(true)
    ctrl_cbobox:SetWidth(40)
    for counter = 1, 3 do
        if counter == 3 then
            ctrl_cbobox:AddString(finale.FCString("This is long option text " .. counter .. "."))
        else
            ctrl_cbobox:AddString(finale.FCString("Short " .. counter .. "."))
        end
    end
    ctrl_cbobox:SetSelectedItem(2)
    y = y + 20

        --[[
    local ctrl_radiobuttons = dlg:CreateRadioButtonGroup(0, y, 3)
    local counter = 1
    for rbtn in each(ctrl_radiobuttons) do
        rbtn:SetWidth(20)
        rbtn:SetAutoResizeWidth(true)
        --rbtn:SetText(finale.FCString("This is long option text " .. counter .. "."))
        rbtn:SetText(finale.FCString("Short " .. counter .. "."))
        counter = counter + 1
    end
]]

    dlg:RegisterInitWindow(function()
        --ctrl_edit:SetMeasurement(1, finale.MEASUREMENTUNIT_DEFAULT)
    end)

    dlg:CreateOkButton()

    return dlg
end

global_dialog = global_dialog or create_dialog()
global_dialog:RunModeless()
