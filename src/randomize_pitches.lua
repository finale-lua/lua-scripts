function plugindef()
    finaleplugin.Author = "Michael McClennan"
    finaleplugin.Version = 1.0
    finaleplugin.Copyright = "2022/01/03"
    finaleplugin.HandlesUndo = true
end

local str = finale.FCString()
dialog = finale.FCCustomLuaWindow()
str.LuaString="Randomize Pitches 0.1"
dialog:SetTitle(str)
dialog:CreateOkButton()
dialog:CreateCancelButton()

editInterval_range = dialog:CreateEdit(85,0)
str.LuaString="3"
editInterval_range:SetText(str)
editInterval_range:SetWidth(30)
staticInterval_range = dialog:CreateStatic(0,2)
str.LuaString="Interval Range:"
staticInterval_range:SetText(str)
buttonApply = dialog:CreateButton(125,0)
str.LuaString="Apply"
buttonApply:SetText(str)

local function randomize_pitches(interval_range)
    finenv.StartNewUndoBlock("Randomize Pitches")
    for entry in eachentrysaved(finenv.Region()) do
        low_interval_range = interval_range * -1 
        if entry:IsNote() then
            for note in each(entry) do
                local midi = note:CalcMIDIKey()
                random_num = math.random(low_interval_range, interval_range)
                note:SetMIDIKey(midi +random_num)
            end
        end
    end
    finenv.EndUndoBlock(true)
end

if finenv.IsRGPLua then
    local Lua_version_text = dialog:CreateStatic(0, 15)
    str.LuaString = "(RGP Lua)"
    Lua_version_text:SetText(str)

    dialog:RegisterHandleControlEvent (
        buttonApply,
        function(control)
            local interval_range = editInterval_range:GetInteger()
            randomize_pitches(interval_range)
            local ui = finenv.UI()
            ui:RedrawDocument() 
        end
    )

    finenv.RegisterModelessDialog(dialog) 
    dialog:ShowModeless()

else
    local Lua_version_text = dialog:CreateStatic(0, 15)
    str.LuaString = "(JW Lua)"
    Lua_version_text:SetText(str)

    local function command_handler(thecontrol)

        if thecontrol:GetControlID(1) == buttonApply:GetControlID() then
            local interval_range = editInterval_range:GetInteger()
            randomize_pitches(interval_range)
            local ui = finenv.UI()
            ui:RedrawDocument() 
        end
    end

    dialog:RegisterHandleCommand(command_handler)

    if (dialog:ExecuteModal(nil) == 1) then
        -- Ok button was pressed
    end
end
