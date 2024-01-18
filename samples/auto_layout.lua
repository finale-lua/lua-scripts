function plugindef()
    finaleplugin.RequireDocument = false
    finaleplugin.MinJWLuaVersion = 0.71
    return "0--auto resize width test"
end

local utils = require('library.utils')
local mixin = require('library.mixin')

function create_dialog()
    local dlg = mixin.FCXCustomLuaWindow()
    dlg:SetTitle(finale.FCString("Test Autolayout"))

    local y = 0
    local line_no = 0
    local y_increment = 22
    local label_edit_separ = 3
    local center_padding = 20

    -- left side
    dlg:CreateStatic(0, line_no * y_increment, "option1-label")
        :DoAutoResizeWidth(true)
        :SetWidth(0)
        :SetText("First Option:")
    dlg:CreateEdit(0, line_no * y_increment - utils.win_mac(2, 3), "option1")
        :SetInteger(1)
        :AssureNoHorizontalOverlap(dlg:GetControl("option1-label"), label_edit_separ)
    line_no = line_no + 1

    dlg:CreateCheckbox(0, line_no * y_increment, "left-checkbox1")
        :DoAutoResizeWidth(true)
        :SetWidth(0)
        :SetText("Left Checkbox Option 1")
    line_no = line_no + 1

    dlg:CreateStatic(0, line_no * y_increment, "option2-label")
        :DoAutoResizeWidth(true)
        :SetWidth(0)
        :SetText("Second Option:")
    dlg:CreateEdit(0, line_no * y_increment - utils.win_mac(2, 3), "option2")
        :SetInteger(2)
        :AssureNoHorizontalOverlap(dlg:GetControl("option2-label"), label_edit_separ)
        :HorizontallyAlignLeftWith(dlg:GetControl("option1"))
    line_no = line_no + 1

    dlg:CreateCheckbox(0, line_no * y_increment, "left-checkbox2")
        :DoAutoResizeWidth(true)
        :SetWidth(0)
        :SetText("Left Checkbox Option 2")
    line_no = line_no + 1

    -- center vertical line
    local vertical_line= dlg:CreateVerticalLine(0, 0 - utils.win_mac(2, 3), line_no * y_increment)
        :AssureNoHorizontalOverlap(dlg:GetControl("option1"), center_padding)
        :AssureNoHorizontalOverlap(dlg:GetControl("left-checkbox1"), center_padding)
        :AssureNoHorizontalOverlap(dlg:GetControl("option2"), center_padding)
        :AssureNoHorizontalOverlap(dlg:GetControl("left-checkbox2"), center_padding)
    line_no = 0

    -- right side
    dlg:CreateStatic(0, line_no * y_increment, "option3-label")
        :DoAutoResizeWidth(true)
        :SetWidth(0)
        :SetText("Third Option:")
        :AssureNoHorizontalOverlap(vertical_line, center_padding)
    dlg:CreateEdit(0, line_no * y_increment - utils.win_mac(2, 3), "option3")
        :SetInteger(3)
        :AssureNoHorizontalOverlap(dlg:GetControl("option3-label"), label_edit_separ)
    line_no = line_no + 1

    dlg:CreateCheckbox(0, line_no * y_increment, "right-checkbox1")
        :DoAutoResizeWidth(true)
        :SetWidth(0)
        :SetText("Right Checkbox Option 1")
        :SetThreeStatesMode(true)
        :AssureNoHorizontalOverlap(vertical_line, center_padding)
    line_no = line_no + 1

    dlg:CreateStatic(0, line_no * y_increment, "option4-label")
        :DoAutoResizeWidth(true)
        :SetWidth(0)
        :SetText("Fourth Option:")
        :AssureNoHorizontalOverlap(vertical_line, center_padding)
    dlg:CreateEdit(0, line_no * y_increment - utils.win_mac(2, 3), "option4")
        :SetInteger(4)
        :AssureNoHorizontalOverlap(dlg:GetControl("option4-label"), label_edit_separ)
        :HorizontallyAlignLeftWith(dlg:GetControl("option3"))
    line_no = line_no + 1

    dlg:CreateButton(0, line_no * y_increment)
        :DoAutoResizeWidth(true)
        :SetWidth(0)
        :SetText("Action Button")
        :AssureNoHorizontalOverlap(vertical_line, center_padding)
        :HorizontallyAlignRightWith(dlg:GetControl("option4"))
    line_no = line_no + 1

    -- horizontal line here
    dlg:CreateHorizontalLine(0, line_no * y_increment + utils.win_mac(7, 5), 20)
        :StretchToAlignWithRight()
    line_no = line_no + 1

    -- bottom side
    local start_line_no = line_no
    dlg:CreateStatic(0, line_no * y_increment, "popup_label")
        :DoAutoResizeWidth(true)
        :SetWidth(0)
        :SetText("Menu:")
    local ctrl_popup = dlg:CreatePopup(0, line_no * y_increment - utils.win_mac(2, 2), "popup")
        :DoAutoResizeWidth(true)
        :SetWidth(0)
        :AssureNoHorizontalOverlap(dlg:GetControl("popup_label"), label_edit_separ)
    for counter = 1, 3 do
        if counter == 3 then
            ctrl_popup:AddString(finale.FCString("This is long menu text " .. counter))
        else
            ctrl_popup:AddString(finale.FCString("Short " .. counter))
        end
    end
    ctrl_popup:SetSelectedItem(0)
    line_no = line_no + 1

    dlg:CreateStatic(0, line_no * y_increment, "cbobox_label")
        :DoAutoResizeWidth(true)
        :SetWidth(0)
        :SetText("Choices:")
    local ctrl_cbobox = dlg:CreateComboBox(0, line_no * y_increment - utils.win_mac(2, 3), "cbobox")
        :DoAutoResizeWidth(true)
        :SetWidth(40)
        :AssureNoHorizontalOverlap(dlg:GetControl("cbobox_label"), label_edit_separ)
        :HorizontallyAlignLeftWith(ctrl_popup)
    for counter = 1, 3 do
        if counter == 3 then
            ctrl_cbobox:AddString(finale.FCString("This is long text choice " .. counter))
        else
            ctrl_cbobox:AddString(finale.FCString("Short " .. counter))
        end
    end
    ctrl_cbobox:SetSelectedItem(0)
    line_no = line_no + 1

    line_no = start_line_no
    local ctrl_radiobuttons = dlg:CreateRadioButtonGroup(0, line_no * y_increment, 3)
    local counter = 1
    for rbtn in each(ctrl_radiobuttons) do
        rbtn:SetWidth(0)
            :DoAutoResizeWidth(true)
            :AssureNoHorizontalOverlap(ctrl_popup, 10)
            :AssureNoHorizontalOverlap(ctrl_cbobox, 10)
        if counter == 2 then
            rbtn:SetText(finale.FCString("This is longer option text " .. counter))
        else
            rbtn:SetText(finale.FCString("Short " .. counter))
        end
        counter = counter + 1
    end
    line_no = line_no + 2

    dlg:CreateCloseButton(0, line_no * y_increment + 5)
        :HorizontallyAlignRightWithFurthest()
        :DoAutoResizeWidth()

    return dlg
end

global_dialog = global_dialog or create_dialog()
global_dialog:RunModeless()
--global_dialog:ExecuteModal(nil)
