function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "http://carlvine.com/lua/"
    finaleplugin.Copyright = "https://creativecommons.org/licenses/by/4.0/"
    finaleplugin.Version = "v0.54"
    finaleplugin.Date = "2022/10/23"
    finaleplugin.MinJWLuaVersion = 0.62
	finaleplugin.AdditionalMenuOptions = [[
        Noteheads Change to Diamond
        Noteheads Change to Diamond (Guitar)
        Noteheads Change to Square
        Noteheads Change to Triangle
        Noteheads Change to Slash
        Noteheads Change to Wedge
        Noteheads Change to Hidden
        Noteheads Change to Number
        Noteheads Revert to Default
     ]]
     finaleplugin.AdditionalUndoText = [[
        Noteheads Change to Diamond
        Noteheads Change to Diamond (Guitar)
        Noteheads Change to Square
        Noteheads Change to Triangle
        Noteheads Change to Slash
        Noteheads Change to Wedge
        Noteheads Change to Hidden
        Noteheads Change to Number
        Noteheads Revert to Default
	]]
     finaleplugin.AdditionalDescriptions = [[
        Change all noteheads in the selection to Diamonds
        Change all noteheads in the selection to Diamonds (Guitar - short notes filled)
        Change all noteheads in the selection to Squares
        Change all noteheads in the selection to Triangles
        Change all noteheads in the selection to Slashes
        Change all noteheads in the selection to Wedges
        Change all noteheads in the selection to Hidden
        Change all noteheads in the selection to specific number (glyph)
        Return all noteheads in the selection to Default
    ]]
    finaleplugin.AdditionalPrefixes = [[
        new_shape = "diamond"
        new_shape = "guitar_diamond"
        new_shape = "square"
        new_shape = "triangle"
        new_shape = "slash"
        new_shape = "wedge"
        new_shape = "hidden"
        new_shape = "number"
        new_shape = "default"
	]]
    finaleplugin.ScriptGroupName = "Noteheads Change"
    finaleplugin.ScriptGroupDescription = "Change all noteheads in the selection to one of eight chosen shapes"
        finaleplugin.Notes = [[
        Change all noteheads in the current selection to one of eight chosen shapes (SMuFL compliant):
        
        ```
        X
        Diamond -- ("hollow" diamonds for all durations)
        Diamond (Guitar) -- ("filled" diamonds for quarter note or shorter)
        Square
        Triangle
        Slash
        Wedge
        Hidden
        Number -- a specific character number (glyph)
        Default -- revert to normal (default) noteheads

        ```
        
        ]]
    return "Noteheads Change to X", "Noteheads Change to X", "Change all noteheads in the selection to X-Noteheads (SMuFL compliant)"
end

new_shape = new_shape or "x"
local notehead = require("library.notehead")

function user_chooses_glyph()
    local x, y = 200, 10
    local y_diff = finenv.UI():IsOnMac() and 3 or 0 -- extra y-offset for Mac text box
    local dlg = finale.FCCustomWindow()
    local str = finale.FCString()
    str.LuaString = plugindef()
    dlg:SetTitle(str)

    str.LuaString = "Enter required character (glyph) number:"
    _ = dlg:CreateStatic(0, y)
    _:SetText(str)
    _:SetWidth(x)
    str.LuaString = "(as simple integer, or hex value like \"0xe0e1\")"
    _ = dlg:CreateStatic(0, y + 20)
    _:SetText(str)
    _:SetWidth(x + 100)
    local answer = dlg:CreateEdit(x, y - y_diff)
    str.LuaString = "0x0100"
    answer:SetText(str)
    dlg:CreateOkButton()
    dlg:CreateCancelButton()
    local ok = dlg:ExecuteModal(nil)
    answer:GetText(str)
    return ok, tonumber(str.LuaString)
end

function change_notehead()
    local mod_down = finenv.QueryInvokedModifierKeys and (finenv.QueryInvokedModifierKeys(finale.CMDMODKEY_ALT) or finenv.QueryInvokedModifierKeys(finale.CMDMODKEY_SHIFT))
    if mod_down then new_shape = "default" end

    if new_shape == "number" then
        local ok
        ok, new_shape = user_chooses_glyph() -- get user's numeric choice in var. new_shape
        if ok ~= finale.EXECMODAL_OK then
            return -- user cancelled
        end
    end

    for entry in eachentrysaved(finenv.Region()) do
        if entry:IsNote() then
            for note in each(entry) do
                notehead.change_shape(note, new_shape)
            end
        end
    end
end

change_notehead()
