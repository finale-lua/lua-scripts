function plugindef()
    finaleplugin.RequireDocument = false
    finaleplugin.MinJWLuaVersion = 0.68
    finaleplugin.Notes = [[
        This script illustrates how to set up a modeless dialog box.
    ]]
    return "0--modeless_dialog.lua"
end

if not finenv.ConsoleIsAvailable then
    require('mobdebug').start()
end

local mixin = require("library.mixin")

local strings = {"Option 1", "Option 2", "Option 3"}
local strings2 = {"Long Suboption 1", "Long Suboption 2"}

local function create_dialog()
    local dlg = mixin.FCXCustomLuaWindow()
    dlg:SetTitle(finale.FCString("RGP Lua Modeless Test"))

    local do_something = dlg:CreateButton(0, 0, "do")
    do_something:SetText(finale.FCString("Do Something"))
    do_something:SetWidth(150)

    local radio_button_values = {} -- key: button group, value: last seen selected item

    local button_group1 = dlg:CreateRadioButtonGroup(0, 30, 3, "radio1")
    local strs = finale.FCStrings()
    strs:CopyFromStringTable(strings)
    button_group1:SetText(strs)
    radio_button_values[button_group1.GroupID] = button_group1:GetSelectedItem()


    local button_group2 = dlg:CreateRadioButtonGroup(0, 100, 2, "radio2")
    strs:CopyFromStringTable(strings2)
    button_group2:SetText(strs)
    button_group2:SetWidth(150)
    radio_button_values[button_group2.GroupID] = button_group2:GetSelectedItem()

    dlg:RegisterInitWindow(function()
            button_group1:MoveAllRelative(20, 10)
        end)

    dlg:RegisterHandleActivate(function(activated)
            if activated then
                print("Activated")
            else
                print("Deactivated")
            end
        end)

    dlg:RegisterHandleCommand(function(control)
            if control:ClassName() == "FCCtrlRadioButton" then
                local button_group = control.RadioButtonGroup
                if button_group:GetSelectedItem() == radio_button_values[button_group.GroupID] then
                    control:SetCheck(false)
                end
                radio_button_values[button_group.GroupID] = button_group:GetSelectedItem()
                local str = finale.FCString()
                control:GetText(str)
                print(str.LuaString..":", button_group:GetSelectedItem(), button_group:GetSelectedButton() and button_group:GetSelectedButton():GetControlID() or -1)
            end
        end)

    dlg:RegisterHandleControlEvent(do_something,
        function(_control)
            local fpath = finale.FCString()
            fpath:SetRunningLuaFolderPath()
            local fname = finale.FCString()
            fname:SetRunningLuaFilePath()
            dlg:CreateChildUI():AlertInfo(fname.LuaString, fpath.LuaString)
            --[[
            local grp1 = global_dialog:GetControl("radio1")
            print("radio group 1 selected item: " .. grp1:GetSelectedItem())
            local grp2 = global_dialog:GetControl("radio2")
            print("radio group 2 selected item: " .. grp2:GetSelectedItem())
            ]]
            --[[
            finenv.StartNewUndoBlock("Playback Region", false)
            finenv.Region():Playback()
            finenv.EndUndoBlock(false)
            ]]
            -- the following commented blocks are all other options for what the "Do Something" button could do.
            --[[
            local mresult = finale.FCListenToMidiResult()
            finenv.UI():DisplayListenToMidiDialog(mresult)
            dlg:CreateChildUI():DisplayListenToMidiDialog(mresult)
            ]]
            --[[
            local radio_button = button_group1:GetSelectedButton()
            if radio_button then
                local str = finale.FCString()
                radio_button:GetText(str)
                finenv.UI():AlertInfo(str.LuaString, "")
            else
                finenv.UI():AlertInfo("nothing selected", "")
            end
            ]]
            --[[
            local function fcstr(s)
                local str = finale.FCString()
                str.LuaString = s
                return str
            end
            local function file_name()
                local fpath = finale.FCString()
                fpath.LuaString = finenv.RunningLuaFilePath()
                local fname = finale.FCString()
                fpath:SplitToPathAndFile(nil, fname)
                return fname.LuaString
            end
            local docs = finale.FCDocuments()
            docs:LoadAll()
            for doc in each(docs) do
                doc:SwitchTo(fcstr(file_name().." "..doc.ID), false)
                local region = finale.FCMusicRegion()
                region:SetFullDocument()
                for entry in eachentrysaved(region) do
                    entry.ManualPosition = entry.ManualPosition + 144
                end
                region:Redraw()
                doc:SwitchBack(true)
            end
            ]]
        end
    )

    dlg:RegisterOSMenuCommandExecuted(function(menucmd, cmdtype)
            local cmdstr
            if finenv.UI():IsOnMac() then
                cmdstr = string.char(
                            bit32.extract(menucmd, 24, 8),
                            bit32.extract(menucmd, 16, 8),
                            bit32.extract(menucmd, 8, 8),
                            bit32.extract(menucmd, 0, 8)
                        )
            else
                cmdstr = string.format(string.format("0x%x", menucmd))
            end
            print(cmdstr, cmdtype)
        end)

    dlg:CreateOkButton()
    dlg:CreateCancelButton()
    return dlg
end

global_dialog = global_dialog or create_dialog()
global_dialog:RunModeless()
