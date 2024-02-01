function plugindef()
    finaleplugin.RequireDocument = true -- Load Text Metrics crashes Finale (and doesn't work) if no document is open
    finaleplugin.MinJWLuaVersion = 0.71
    return "0--text_editor_control.lua"
end

if finenv.IsRGPLua then
    require('mobdebug').start()
end

print(_VERSION)
print(finenv.LuaBridgeVersion)

local init_with_rtf = true

local function win_mac(winval, macval)
    if finenv.UI():IsOnMac() then return macval end
    return winval
end

local function calc_tab_width(font, numchars) -- assumes fixed_width font
    local text_met = finale.FCTextMetrics()
    text_met:LoadString(finale.FCString("a"), font, 100)
    local adv_points = text_met:GetAdvanceWidthEVPUs() / 4 -- GetAdvanceWidthPoints is broken on Windows
    return numchars * adv_points
end

local initial_wordwrap = true

local dlg = finale.FCCustomLuaWindow()
dlg:SetTitle(finale.FCString("Test Edit Text"))
local edit_text = dlg:CreateTextEditor(10, 10) -- CreateTextEditor
edit_text:SetWidth(400)
edit_text:SetHeight(180)
edit_text:SetUseRichText(true)
local edit_font = finale.FCFontInfo()
edit_font.Name = win_mac("Consolas", "Monaco")
edit_font.Size = win_mac(9, 11)
edit_text:SetFont(edit_font)
print(edit_text:GetControlID())
local tabstop_width = calc_tab_width(edit_font, 4)
edit_text:SetTabstopWidth(tabstop_width)
edit_text:SetAutomaticEditing(true)
dlg:RegisterHandleControlEvent(edit_text, function(_control)
--        local finale.FCString = control:CreateEnigmaString()
--        print("Got Enigma String: "..finale.FCString.LuaString)
    end)
edit_text:SetWordWrap(initial_wordwrap)
--edit_text:SetText(finale.FCString("This is a test."))
local non_bmp_text = [[𝒜𝓈 𝒸𝒽
𝒶𝓇𝓂𝒾
𝓃𝑔 𝓈
𝓊𝓃𝓈𝑒
𝓉𝓈 𝒾𝓃 𝓉𝒽𝑒 𝓋𝒶𝓈𝓉 𝒾𝓃𝓉𝓸 𝓉𝒽𝑒 𝓊𝓃𝓀𝓃𝑜𝓌𝓃
𝒾𝓈 𝒶 𝒷𝑒𝒶𝓊𝓉𝒾𝒻𝓊𝓁 𝓂𝒶𝑔𝒾𝒸 𝑜𝒻 𝒸𝒽𝒶𝓇𝒶𝒸𝓉𝑒𝓇𝓈.]]
local long_line_text = "This is a test. Now is the time for a very long string to come to the aid and comfort of their friends and enemies to create a very, very long string." -- luacheck: ignore
local rtf_text = [[{\rtf1\ansi
This is some {\b bold} text.
This is some {\i italic} text.
This is some {\ul underline} text.
This is some {\strike strikethrough} text.
This is some {\colortbl ;\red0\green128\blue0;\red0\green0\blue255;}{\cf1\fs36 green text.}
This is some {\highlight1\cf2 highlighted text.}
This is some {\ulwave underlined with wave} text.
This is some {\uldb double underline} text.
This is some {\ulth thick underline} text.
This is some {\super superscript} text.
This is some {\sub subscript} text.
}
]]
local findtext -- forward declaration
local enabler = dlg:CreateCheckbox(10, 200)
enabler:SetText(finale.FCString("Enable"))
enabler:SetWidth(60)
enabler:SetCheck(1)
dlg:RegisterHandleControlEvent(enabler, function(control)
        edit_text:SetEnable(control:GetCheck() ~= 0)
        findtext:SetEnable(control:GetCheck() ~= 0)
        edit_text:SetKeyboardFocus()
    end)
local visifier = dlg:CreateButton(90, 200)
visifier:SetText(finale.FCString("Visible"))
dlg:RegisterHandleControlEvent(visifier, function(_control)
        edit_text:SetVisible(not edit_text:GetVisible())
        enabler:SetVisible(not enabler:GetVisible())
        edit_text:SetKeyboardFocus()
    end)
local readonly = dlg:CreateButton(170, 200)
readonly:SetText(finale.FCString("Readonly"))
dlg:RegisterHandleControlEvent(readonly, function(_control)
        edit_text:SetReadOnly(not edit_text:GetReadOnly())
        edit_text:SetKeyboardFocus()
    end)
local sizer = dlg:CreateButton(250, 200)
sizer:SetText(finale.FCString("Size"))
local size_incrementer
dlg:RegisterHandleControlEvent(sizer, function(_control)
        if not size_incrementer then size_incrementer = 10 end
        size_incrementer = size_incrementer * 1.25
        edit_text:SetFontSizeForSelection(size_incrementer)
    end)
local copier = dlg:CreateButton(330, 200)
copier:SetText(finale.FCString("Copy"))
dlg:RegisterHandleControlEvent(copier, function(_control)
        edit_text:TextToClipboard()
    end)
local replacer = dlg:CreateButton(10, 225)
replacer:SetText(finale.FCString("Replace"))
dlg:RegisterHandleControlEvent(replacer, function(_control)
        if not edit_text:ReplaceSelectedText(finale.FCString("*** replaced\ntext ***")) then
            print("ReplaceSelectedText failed because no selected text.")
        end
        edit_text:SetKeyboardFocus()
    end)
local restorer = dlg:CreateButton(90, 225)
restorer:SetText(finale.FCString("Restore"))
dlg:RegisterHandleControlEvent(restorer, function(_control)
--        local vers1 = finale.FCVerseLyricsText()
--        if not vers1:Load(1) then print("lyrics load failed") end
--        local versstr = vers1:CreateString()
--        print("Lyrics: "..versstr.LuaString)
--        --local versstr = finale.FCString("^font(Verdana)^size(11)^nfx(128)This is a test.")
--        edit_text:SetEnigmaString(versstr, vers1.BlockType)
        edit_text:SetText(finale.FCString(non_bmp_text))
        edit_text:SetKeyboardFocus()
    end)
local inserter = dlg:CreateButton(170, 225)
inserter:SetText(finale.FCString("Insert"))
dlg:RegisterHandleControlEvent(inserter, function(_control)
        edit_text:InsertTextAtCursor(finale.FCString("*** inserted text ***"))
        edit_text:SetKeyboardFocus()
    end)
local selectall = dlg:CreateButton(250, 225)
selectall:SetText(finale.FCString("SelAll"))
dlg:RegisterHandleControlEvent(selectall, function(_control)
        local range = finale.FCRange()
        edit_text:GetTotalTextRange(range)
        edit_text:SetSelection(range)
        edit_text:SetKeyboardFocus()
    end)
local tabber = dlg:CreateButton(10, 250)
tabber:SetText(finale.FCString("Tabs"))
dlg:RegisterHandleControlEvent(tabber, function(_control)
        tabstop_width = tabstop_width - 12
        if tabstop_width < 12 then
            tabstop_width = 12
        end
        edit_text:SetTabstopWidth(tabstop_width)
        edit_text:SetKeyboardFocus()
    end)
local wrapper = dlg:CreateCheckbox(90, 250)
wrapper:SetText(finale.FCString("Wrap"))
wrapper:SetWidth(70)
wrapper:SetCheck(initial_wordwrap and 1 or 0)
dlg:RegisterHandleControlEvent(wrapper, function(control)
        edit_text:SetWordWrap(control:GetCheck() ~= 0)
        control:SetCheck(edit_text:GetWordWrap() and 1 or 0) -- on Windows, this prevent the checkbox from changing
        edit_text:SetKeyboardFocus()
    end)
local bolder = dlg:CreateCheckbox(170, 250)
bolder:SetText(finale.FCString("Bold"))
bolder:SetWidth(70)
dlg:RegisterHandleControlEvent(bolder, function(control)
        edit_text:SetFontBoldForSelection(control:GetCheck() ~= 0)
    end)
local italicer = dlg:CreateCheckbox(250, 250)
italicer:SetText(finale.FCString("Italic"))
italicer:SetWidth(70)
dlg:RegisterHandleControlEvent(italicer, function(control)
        edit_text:SetFontItalicForSelection(control:GetCheck() ~= 0)
    end)
local locinfo = dlg:CreateButton(330, 250)
locinfo:SetText(finale.FCString("Loc."))
locinfo:SetWidth(70)
dlg:RegisterHandleControlEvent(locinfo, function(_control)
        local selrange = finale.FCRange()
        edit_text:GetSelection(selrange)
        local posrange = finale.FCRange()
        edit_text:GetLineRangeForPosition(selrange.Start, posrange)
        local line = edit_text:GetLineForPosition(selrange.Start)
        local total_lines = edit_text:GetNumberOfLines()
        local range = finale.FCRange()
        edit_text:GetLineRangeForLine(line, range)
        print("sel: (start: "..selrange.Start..", length: "..selrange.Length..")")
        print("line: "..line.. " (out of "..total_lines..").")
        print("posrange: (start: "..posrange.Start..", length: "..posrange.Length..")")
        print("linrange: (start: "..range.Start..", length: "..range.Length..")")
    end)        
local finder = dlg:CreateButton(10, 275)
finder:SetText(finale.FCString("Find"))
findtext = dlg:CreateEdit(90, 274)
findtext:SetWidth(70)
local wordonly = dlg:CreateCheckbox(170, 275)
wordonly:SetText(finale.FCString("RegEx"))
wordonly:SetWidth(70)
local igncase = dlg:CreateCheckbox(250, 275)
igncase:SetText(finale.FCString("Ign Case"))
igncase:SetWidth(70)
dlg:RegisterHandleControlEvent(finder, function(_control)
        local str = finale.FCString()
        findtext:GetText(str)
        local options = 0
        if wordonly:GetCheck() ~= 0 then
            options = options | finale.STRFINDOPT_REGEX
        end
        if igncase:GetCheck() ~= 0 then
            options = options | finale.STRFINDOPT_IGNORECASE
        end
        options = options | finale.STRFINDOPT_WHOLEWORDS
        local search_range = finale.FCRange()
        if not edit_text:GetSelection(search_range) or search_range:GetLength() <= 0 then
            search_range = nil
        end
        local ranges = edit_text:CreateRangesForString(str, options, search_range)
        if not ranges then
            finenv.UI():AlertInfo("not found.", "")
            return
        end
        for range in eachbackwards(ranges) do
            edit_text:ReplaceTextInRange(finale.FCString("GOTCHA"), range)
        end
        edit_text:SetKeyboardFocus()
    end)
local dumper = dlg:CreateButton(330, 275)
dumper:SetText(finale.FCString("DumpText"))
dumper:SetWidth(70)
dlg:RegisterHandleControlEvent(dumper, function(_control)
        local range = finale.FCRange()
        edit_text:GetSelection(range)
        if range.Length == 0 then
            edit_text:GetTotalTextRange(range)
        end
        local raw_string = finale.FCString()
        edit_text:GetTextInRange(raw_string, range)
        print("Got Raw String: " .. raw_string.LuaString)
        local utf16_string = finale.FCString()
        local i = range.Start
        while (i < range.End) do
            local next_char = edit_text:CreateCharacterAtIndex(i)
            if not next_char then
                print("GetCharacterAtIndex failed")
                break
            end
            utf16_string:AppendString(next_char)
            i = i + next_char.Length
        end
        if utf16_string.Length > 0 then
            print("Got Utf16 String: " .. utf16_string.LuaString)
        end
        local fcstr = edit_text:CreateEnigmaString(range)
        print("Got Enigma String: "..fcstr.LuaString)
    end)
local colorizer = dlg:CreateButton(10, 300)
colorizer:SetText(finale.FCString("Sel2Red"))
colorizer:SetWidth(90)
dlg:RegisterHandleControlEvent(colorizer, function(_control)
        local range = finale.FCRange()
        edit_text:GetSelection(range)
        edit_text:SetTextColorInRange(247, 0, 0, range)
    end)
local find2color = dlg:CreateButton(110, 300)
find2color:SetText(finale.FCString("Find2Green"))
find2color:SetWidth(90)
dlg:RegisterHandleControlEvent(find2color, function(_control)
        local str = finale.FCString()
        findtext:GetText(str)
        local options = 0
        if wordonly:GetCheck() ~= 0 then
            options = options | finale.STRFINDOPT_WHOLEWORDS
        end
        if igncase:GetCheck() ~= 0 then
            options = options | finale.STRFINDOPT_IGNORECASE
        end
        local ranges = edit_text:CreateRangesForString(str, options)
        if not ranges then
            finenv.UI():AlertInfo("not found.", "")
            return
        end
        for range in each(ranges) do
            edit_text:SetTextColorInRange(0, 233, 0, range)
        end
    end)
local colorreporter = dlg:CreateButton(210, 300)
colorreporter:SetText(finale.FCString("Color Starts"))
colorreporter:SetWidth(90)
dlg:RegisterHandleControlEvent(colorreporter, function(_control)
        local ranges = edit_text:CreateTextColorChanges()
        if not ranges then
            print("No colors returned.")
            return
        end
        for range in each(ranges) do
            local rgb = edit_text:GetTextColorAtIndex(range.Start)
            local org_length = range.Length
            if range.Length > 15 then range.Length = 15 end
            local fcs = finale.FCString()
            edit_text:GetTextInRange(fcs, range)
            print("Range "..range.Start.."-"..(range.Start+org_length), "("..rgb[1]..", "..rgb[2].. ", "..rgb[3]..")", fcs.LuaString)
        end
    end)
local colorreverter = dlg:CreateButton(310, 300)
colorreverter:SetText(finale.FCString("Default"))
dlg:RegisterHandleControlEvent(colorreverter, function(_control)
        edit_text:SetFont(finale.FCFontInfo("Arial", 12))
        --local range = finale.FCRange()
        --edit_text:GetTotalTextRange(range)
        --edit_text:ResetTextColorInRange(range)
--------
--        local vers1 = finale.FCVerseLyricsText()
--        local enigma_str = edit_text:CreateEnigmaString()
--        edit_text:TextEditor(enigma_str, vers1.BlockType)
    end)
local curr_sel = dlg:CreateStatic(10, 325)
curr_sel:SetWidth(200)
dlg:RegisterTextSelectionChanged(function(control)
        local fstr = finale.FCString()
        control:GetSelectedText(fstr) -- if no selection, fstr is unchanged and empty
        --print("Selected Text: "..fstr.LuaString)
        curr_sel:SetText(fstr)
    end)
dlg:CreateOkButton()
dlg:RegisterInitWindow(function()
        if init_with_rtf then
            edit_text:SetFont(finale.FCFontInfo("Arial", 12))
            print(rtf_text)
            edit_text:SetRTFString(finale.FCString(rtf_text))
            print(edit_text:CreateRTFString().LuaString)
            local enigma_version = edit_text:CreateEnigmaString()
            print(enigma_version.LuaString)
            --edit_text:SetEnigmaString(enigma_version)
        else
            local expdef = finale.FCTextExpressionDef()
            if not expdef:Load(3) then
                local expstr = expdef:CreateTextString()
                print("Exp "..expdef.ItemNo..": "..expstr.LuaString)
                edit_text:SetEnigmaString(expstr)
                local fcstr = edit_text:CreateEnigmaString()
                print("Got Enigma String: "..fcstr.LuaString)
            else
                local vers1 = finale.FCVerseLyricsText()
                if not vers1:Load(1) then print("lyrics load failed") end
                local versstr = vers1:CreateString()
                if #versstr.LuaString <= 0 then
                    versstr.LuaString = "test"
                end
                print("Lyrics: "..versstr.LuaString)
                --local versstr = finale.FCString("^font(Verdana)^size(11)^nfx(128)This is a test.")
                edit_text:SetEnigmaString(versstr, vers1.BlockType)
                local fcstr = edit_text:CreateEnigmaString()
                print("Got Enigma String: "..fcstr.LuaString)
                --edit_text:SetText(finale.FCString(""))
                edit_text:SetEnigmaString(finale.FCString, vers1.BlockType)
            end
        end
        edit_text:ResetUndoState()
    end)
dlg:ExecuteModal(nil)
