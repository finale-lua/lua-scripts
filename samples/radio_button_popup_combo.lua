function plugindef()
    finaleplugin.RequireDocument = false
    finaleplugin.MinJWLuaVersion = 0.74
    finaleplugin.Notes = [[
        This script illustrates how to set up a radio button group where each radio button item has an
        associated popup menu. It uses the auto-layout features of v0.74 to align the controls.

        Note that since the vertical spacing of the popups is wider than the default vertical spacing of
        the radio buttons, the radio button spacing is expanded. For this to work, the top value of the
        topmost popup should be >= the top value of the topmost radio button. In this example, the
        `radio_top` and `popup_spacing` variables ensure this.
    ]]
    return "0-radio_button_popup_combo.lua"
end

local dialog = finale.FCCustomLuaWindow()
dialog:SetTitle(finale.FCString("Radio Group Test"))
local static = dialog:CreateStatic(0, 0)
static:SetText(finale.FCString("Select Radio Button"))
static:SetWidth(150)
local my_list = { "Here", "are", "some", "radio", "button", "texts" }
local radio_top = 20
local popup_spacing = 23
local radio = dialog:CreateRadioButtonGroup(0, radio_top, #my_list) -- topmost radion button is at radio_top
local popups = {}
for index, value in ipairs(my_list) do
    local rad = radio:GetItemAt(index - 1)
    rad:SetText(finale.FCString(value))
    rad:DoAutoResizeWidth(0) -- radio buttons are set to have a width that exactly matches their text (the 0 parameter does this)
    local popup = dialog:CreatePopup(0, radio_top + popup_spacing*(index - 1)) -- popup buttons are spaced out starting with radio_top
    popups[index] = popup
    for i = 1, 3 do
        popup:AddString(finale.FCString(value .. " option " .. i))
    end
    popup:AssureNoHorizontalOverlap(rad, 5) -- popups are at least 5 pixels from the radio button text
    popup:VerticallyAlignWith(rad, -1) -- popups are offet -1 from the top of the radio buttons
    popup:DoAutoResizeWidth() -- popup buttons are set to have a width *at least* as wide as the text (omitting the parameter does this)
    if index > 1 then
        popup:HorizontallyAlignLeftWith(popups[1])
    end
end
dialog:CreateOkButton()
dialog:CreateCancelButton()
dialog:ExecuteModal()
