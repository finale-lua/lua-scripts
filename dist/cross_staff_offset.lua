function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "http://carlvine.com"
    finaleplugin.Version = "v1.21"
    finaleplugin.Date = "2022/05/23"   
    finaleplugin.Notes = [[
        When creating cross-staff notes using the option-downarrow shortcut, the stems of 'crossed' notes
        are reversed (on the wrong side of the notehead) and so appear too far to the right (if shifting downwards)
        by the width of one notehead (typically 24EVPU). This script lets you set a horizontal offset for all cross-staff
        notes in the currently selected region, with a different offset for non-crossed notes. For crossing to the
        staff below use (-24,0) or (-12,12). For crossing to the staff above use (24,0) or (12,-12). Also specify
        which layer number (1-4) or "all layers" (0). (This also offers a simple way to reset the horizontal offset
        of all notes in the selection to zero).

        If you invoke the plugin with Option key (macOS) or Shift key pressed, the script uses the last settings
        from the dialog.
    ]]
    return "CrossStaff Offset", "CrossStaff Offset", "Offset horizontal position of cross-staff note entries"
end
 
function user_selects_offset()
    local current_vert, vertical_step = 10, 25
    local mac_offset = finenv.UI():IsOnMac() and 3 or 0 -- extra y-offset for Mac text box
    local edit_box_horiz = 120
    
    local dialog = finale.FCCustomWindow()
    local str = finale.FCString()
    str.LuaString = plugindef()
    dialog:SetTitle(str)

    local answer = {}
    local texts = { -- words, default value
        { "Cross-staff offset:", cross_offset and cross_offset or 0 }, --> answer[1] cross_offset
        { "Non-crossed offset:", non_cross_offset and non_cross_offset or 0 }, --> answer[2] non_cross_offset
        { "Layer 1-4 (0 = all):", layer_number and layer_number or 0 } --> answer[3] layer_number
    }
        
    for i,v in ipairs(texts) do
        str.LuaString = v[1]
        local static = dialog:CreateStatic(0, current_vert)
        static:SetText(str)
        static:SetWidth(200)
        answer[i] = dialog:CreateEdit(edit_box_horiz, current_vert - mac_offset)
        answer[i]:SetInteger(v[2])
        answer[i]:SetWidth(75)
        if i < 3 then
            str.LuaString = "EVPUs"
            dialog:CreateStatic(edit_box_horiz + 80, current_vert):SetText(str)
        end
        current_vert = current_vert + vertical_step
    end

    local static = dialog:CreateStatic(0, current_vert + 8)
    str.LuaString = "cross to staff below = [ -24 | 0 ] or [ -12, 12 ]"
    static:SetText(str)
    static:SetWidth(240)
    static = dialog:CreateStatic(0, current_vert + vertical_step)
    str.LuaString = "cross to staff above = [ 24 | 0 ] or [ 12, -12 ]"
    static:SetText(str)
    static:SetWidth(240)

    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    return dialog:ExecuteModal(nil), -- == 1 if Ok button pressed, else 0
        answer[1]:GetInteger(), answer[2]:GetInteger(), answer[3]:GetInteger()
end

function is_out_of_range(horiz_offset)
    max_value = 999 -- some unrealistic horizontal offset (EVPUs)
    return ( horiz_offset > max_value or horiz_offset < max_value * -1 )
end

function cross_staff_offset()
    local modifier_keys_pressed = finenv.QueryInvokedModifierKeys and
                                        (finenv.QueryInvokedModifierKeys(finale.CMDMODKEY_ALT) or finenv.QueryInvokedModifierKeys(finale.CMDMODKEY_SHIFT))
    if not modifier_keys_pressed or dialog_result ~= finale.EXECMODAL_OK then
        -- use global result values so that RetainLuaState remembers them
        dialog_result, cross_offset, non_cross_offset, layer_number = user_selects_offset()
        if dialog_result ~= finale.EXECMODAL_OK then -- user cancelled
            return
        end
        if nil ~= finenv.RetainLuaState then
            finenv.RetainLuaState = true
        end
    end

    local error = ""  -- TEST FOR ERRORS (note that all user responses are perforce already integers)
    if layer_number < 0 or layer_number > 4  then 
        error = "The layer number must\nbe between 0 and 4\n(not " .. layer_number .. ")"
    elseif is_out_of_range(cross_offset) or is_out_of_range(non_cross_offset) then
        error = "Choose realistic offset\nvalues (say from -999 to 999)\n(not " .. cross_offset .. " / " .. non_cross_offset .. ")"
    end
    if (error ~= "") then  -- error dialog and exit
        finenv.UI():AlertNeutral("script: "..plugindef(), error)
        dialog_result = finale.EXECMODAL_CANCEL -- force dialog box to open next time
    else
        -- change entry offsets
        for entry in eachentrysaved(finenv.Region(), layer_number) do -- only access notes in the chosen layer (0 = all layers)
            if entry:IsNote() then
                entry.ManualPosition = entry.CrossStaff and cross_offset or non_cross_offset
            end
        end
    end
end

cross_staff_offset()
