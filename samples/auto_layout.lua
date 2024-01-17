function plugindef()
    finaleplugin.RequireDocument = false
    finaleplugin.MinJWLuaVersion = 0.71
    return "0--auto resize width test"
end

local mixin = require('library.mixin')

local function win_mac(winval, macval)
    if finenv.UI():IsOnWindows() then return winval end
    return macval
end

function create_dialog()
    --local dlg = finale.FCCustomLuaWindow()
    local dlg = mixin.FCXCustomLuaWindow()
    dlg:SetTitle(finale.FCString("Test Autolayout"))

    local y = 0

    local ctrl_label = dlg:CreateStatic(0, y)
    ctrl_label:DoAutoResizeWidth(true)
    ctrl_label:SetWidth(0)
    ctrl_label:SetText(finale.FCString("Label:"))
    local ctrl_edit = dlg:CreateEdit(0, y - win_mac(2, 3))
    ctrl_edit:SetText(finale.FCString("Editable"))
    ctrl_edit:AssureNoHorizontalOverlap(ctrl_label, 2)
    y = y + 20

    local ctrl_checkbox = dlg:CreateCheckbox(0, y)
    ctrl_checkbox:DoAutoResizeWidth(true)
    ctrl_checkbox:SetWidth(0)
    ctrl_checkbox:SetText(finale.FCString("Short."))
    y = y + 20

    local ctrl_edit2 = dlg:CreateEdit(0, y)
    ctrl_edit2:DoAutoResizeWidth(true)
    ctrl_edit2:SetWidth(0)
    ctrl_edit2:SetText(finale.FCString("Short."))
    --ctrl_edit2:SetMeasurement(1, finale.MEASUREMENTUNIT_DEFAULT)
    y = y + 30

    local ctrl_button = dlg:CreateButton(0, 70)
    ctrl_button:DoAutoResizeWidth(true)
    ctrl_button:SetWidth(0)
    ctrl_button:SetText(finale.FCString("Short."))
    y = y + 30

    local popup_label = dlg:CreateStatic(0, y)
    popup_label:DoAutoResizeWidth(true)
    popup_label:SetWidth(0)
    popup_label:SetText(finale.FCString("Popup:"))
    local ctrl_popup = dlg:CreatePopup(0, y - win_mac(2, 2))
    ctrl_popup:DoAutoResizeWidth(true)
    ctrl_popup:SetWidth(0)
    ctrl_popup:AssureNoHorizontalOverlap(popup_label, 2)
    --ctrl_popup:HorizontallyAlignWith(ctrl_edit)
    for k, v in pairs(finale.FCControl.__propget) do
        print (tostring(k), tostring(v), tostring(ctrl_popup[k]))
    end
    for counter = 1, 3 do
        if counter == 3 then
            ctrl_popup:AddString(finale.FCString("This is long option text " .. counter .. "."))
        else
            ctrl_popup:AddString(finale.FCString("Short " .. counter .. "."))
        end
    end
    ctrl_popup:SetSelectedItem(1)
    y = y + 22

    local cbobox_label = dlg:CreateStatic(0, y)
    cbobox_label:DoAutoResizeWidth(true)
    cbobox_label:SetWidth(0)
    cbobox_label:SetText(finale.FCString("ComboBox:"))
    local ctrl_cbobox = dlg:CreateComboBox(0, y - win_mac(2, 4))
    ctrl_cbobox:DoAutoResizeWidth(true)
    ctrl_cbobox:SetWidth(40)
    ctrl_cbobox:AssureNoHorizontalOverlap(cbobox_label, 2)
    ctrl_cbobox:HorizontallyAlignWith(ctrl_popup)
    for k, v in pairs(finale.FCControl.__propget) do
        print (tostring(k), tostring(v), tostring(ctrl_cbobox[k]))
    end
    for counter = 1, 3 do
        if counter == 3 then
            ctrl_cbobox:AddString(finale.FCString("This is long option text " .. counter .. "."))
        else
            ctrl_cbobox:AddString(finale.FCString("Short " .. counter .. "."))
        end
    end
    ctrl_cbobox:SetSelectedItem(2)
    y = y + 30

    local ctrl_radiobuttons = dlg:CreateRadioButtonGroup(0, y, 3)
    local counter = 1
    for rbtn in each(ctrl_radiobuttons) do
        rbtn:SetWidth(0)
        rbtn:DoAutoResizeWidth(true)
        if counter == 2 then
            rbtn:SetText(finale.FCString("This is long option text " .. counter .. "."))
        else
            rbtn:SetText(finale.FCString("Short " .. counter .. "."))
        end
        counter = counter + 1
    end

    dlg:RegisterInitWindow(function()
        --ctrl_edit:SetMeasurement(1, finale.MEASUREMENTUNIT_DEFAULT)
    end)

    dlg:CreateOkButton()
    dlg:CreateCancelButton()

    return dlg
end

global_dialog = global_dialog or create_dialog()
global_dialog:RunModeless()
--global_dialog:ExecuteModal(nil)
