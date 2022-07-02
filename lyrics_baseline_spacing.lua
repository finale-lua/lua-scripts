function plugindef()
    finaleplugin.RequireSelection = false
    finaleplugin.Author = "Jacob Winkler" 
    finaleplugin.Copyright = "©2022 Jacob Winkler"
    finaleplugin.AuthorEmail = "jacob.winkler@mac.com"
    finaleplugin.Version = "1.0"
    finaleplugin.Date = "2022-07-02"
    finaleplugin.Notes = [[
The default beheavior of this script makes all lyrics types (verse, section, chorus) use the same settings.
This is easily toggled off, but to make the types indendent by default, add the following code to the
'Optional prefix' field in the RGP Lua setup interface:

all_lyrics = false
    ]]
    return "Lyrics - Space Baselines", "Lyrics - Space Baselines", "Lyrics - Space Baselines"
end

all_lyrics = all_lyrics or true

function lyrics_spacing(title)
    local independent_lyrics = false
    local baseline_verse = finale.FCBaseline()
    baseline_verse:LoadDefaultForLyricNumber(finale.BASELINEMODE_LYRICSVERSE,1)
    local verse1_start = -baseline_verse.VerticalOffset
    baseline_verse:LoadDefaultForLyricNumber(finale.BASELINEMODE_LYRICSVERSE,2)
    local verse_gap =  -baseline_verse.VerticalOffset - verse1_start
    --
    local baseline_chorus = finale.FCBaseline()
    baseline_chorus:LoadDefaultForLyricNumber(finale.BASELINEMODE_LYRICSCHORUS,1)
    local chorus1_start = -baseline_chorus.VerticalOffset
    baseline_chorus:LoadDefaultForLyricNumber(finale.BASELINEMODE_LYRICSCHORUS,2)
    local chorus_gap =  -baseline_chorus.VerticalOffset - chorus1_start
    --
    local baseline_section = finale.FCBaseline()
    baseline_section:LoadDefaultForLyricNumber(finale.BASELINEMODE_LYRICSSECTION,1)
    local section1_start = -baseline_section.VerticalOffset
    baseline_section:LoadDefaultForLyricNumber(finale.BASELINEMODE_LYRICSSECTION,2)
    local section_gap = -baseline_section.VerticalOffset - section1_start
    --
    local row_h = 20
    local col_w = 60
    local col_gap = 10
    local str = finale.FCString()
    str.LuaString = title
    local dialog = finale.FCCustomLuaWindow()
    dialog:SetTitle(str)

    local row = {}
    for i = 1, 100 do
        row[i] = (i -1) * row_h
    end
--
    local col = {}
    for i = 1, 20 do
        col[i] = (i - 1) * col_w
    end
--

    function add_ctrl(dialog, ctrl_type, text, x, y, h, w, min, max)
        str.LuaString = text
        local ctrl = ""
        if ctrl_type == "button" then
            ctrl = dialog:CreateButton(x, y)
        elseif ctrl_type == "checkbox" then
            ctrl = dialog:CreateCheckbox(x, y)
        elseif ctrl_type == "datalist" then
            ctrl = dialog:CreateDataList(x, y)
        elseif ctrl_type == "edit" then
            ctrl = dialog:CreateEdit(x, y - 2)
        elseif ctrl_type == "horizontalline" then
            ctrl = dialog:CreateHorizontalLine(x, y, w)
        elseif ctrl_type == "listbox" then
            ctrl = dialog:CreateListBox(x, y)
        elseif ctrl_type == "popup" then
            ctrl = dialog:CreatePopup(x, y)
        elseif ctrl_type == "slider" then
            ctrl = dialog:CreateSlider(x, y)
            ctrl:SetMaxValue(max)
            ctrl:SetMinValue(min)
        elseif ctrl_type == "static" then
            ctrl = dialog:CreateStatic(x, y)
        elseif ctrl_type == "switcher" then
            ctrl = dialog:CreateSwitcher(x, y)
        elseif ctrl_type == "tree" then
            ctrl = dialog:CreateTree(x, y)
        elseif ctrl_type == "updown" then
            ctrl = dialog:CreateUpDown(x, y)
        elseif ctrl_type == "verticalline" then
            ctrl = dialog:CreateVerticalLine(x, y, h)
        end
        if ctrl_type == "edit" then
            ctrl:SetHeight(h-2)
            ctrl:SetWidth(w - col_gap)
        elseif ctrl_type == "horizontalline" then
            ctrl:SetHeight(h + h/2)
            ctrl:SetWidth(w)
        elseif ctrl_type == "popup" then
            ctrl:SetHeight(h)
            ctrl:SetWidth(w - col_gap)
        else
            ctrl:SetHeight(h)
            ctrl:SetWidth(w)
        end
        ctrl:SetText(str)
        return ctrl
    end



--    local control = add_ctrl(dialog, "static", "TESTING!", col[1], row[2], row_h, col_w, 0, 0)
    local verse_static = add_ctrl(dialog, "static", "All Lyrics", col[3], row[1], row_h, col_w, 0, 0)
    local chorus_static = add_ctrl(dialog, "static", "", col[4], row[1], row_h, col_w, 0, 0)
    local section_static = add_ctrl(dialog, "static", "", col[5], row[1], row_h, col_w, 0, 0)
    --
    local lyric1_static = add_ctrl(dialog, "static", "Lyric 1 baseline:", col[1] + 31, row[2], row_h, col_w * 2, 0, 0)
    local verse1_edit = add_ctrl(dialog, "edit", verse1_start, col[3], row[2], row_h, col_w, 0, 0)  
    local chorus1_edit = add_ctrl(dialog, "edit", chorus1_start, col[4], row[2], row_h, col_w, 0, 0)  
    local section1_edit = add_ctrl(dialog, "edit", section1_start, col[5], row[2], row_h, col_w, 0, 0)
    --
    local gap_static = add_ctrl(dialog, "static", "Gap:", col[2] + 29, row[3], row_h, col_w, 0, 0)
    local verse_gap_edit = add_ctrl(dialog, "edit", verse_gap, col[3], row[3], row_h, col_w, 0, 0)  
    local chorus_gap_edit = add_ctrl(dialog, "edit", chorus_gap, col[4], row[3], row_h, col_w, 0, 0)  
    local section_gap_edit = add_ctrl(dialog, "edit", section_gap, col[5], row[3], row_h, col_w, 0, 0)  
    --
        local all_lyrics_static = add_ctrl(dialog, "static", "Edit all:", col[2] + 14, row[4], row_h, col_w, 0, 0)
    local all_lyrics_check = add_ctrl(dialog, "checkbox", "", col[3], row[4], row_h, col_w * 2, 0, 0) 
    if all_lyrics == true then
        all_lyrics_check:SetCheck(1)
    else
        all_lyrics_check:SetCheck(0)
    end

    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    --
    function apply()
        if all_lyrics == true then
            verse1_edit:GetText(str)
            chorus1_edit:SetText(str)
            section1_edit:SetText(str)
            --
            verse_gap_edit:GetText(str)
            chorus_gap_edit:SetText(str)
            section_gap_edit:SetText(str)
        end

        verse1_edit:GetText(str)
        verse1_start = tonumber(str.LuaString)
        chorus1_edit:GetText(str)
        chorus1_start = tonumber(str.LuaString)
        section1_edit:GetText(str)
        section1_start = tonumber(str.LuaString)
--
        verse_gap_edit:GetText(str)
        verse_gap = tonumber(str.LuaString)
        chorus_gap_edit:GetText(str)
        chorus_gap = tonumber(str.LuaString)
        section_gap_edit:GetText(str)
        section_gap = tonumber(str.LuaString)
        --
        for i = 1, 100, 1 do
            baseline_verse:LoadDefaultForLyricNumber(finale.BASELINEMODE_LYRICSVERSE,i)
            baseline_verse.VerticalOffset = -verse1_start - (verse_gap * (i - 1))
            baseline_verse:Save()
            --
            baseline_chorus:LoadDefaultForLyricNumber(finale.BASELINEMODE_LYRICSCHORUS,i)
            baseline_chorus.VerticalOffset = -chorus1_start - (chorus_gap * (i - 1))
            baseline_chorus:Save()
            --
            baseline_section:LoadDefaultForLyricNumber(finale.BASELINEMODE_LYRICSSECTION,i)
            baseline_section.VerticalOffset = -section1_start - (section_gap * (i - 1))
            baseline_section:Save()
        end
    end

    function callback(ctrl)
        if ctrl:GetControlID() == all_lyrics_check:GetControlID()  then

            if all_lyrics_check:GetCheck() == 1 then
                all_lyrics = true
            else
                all_lyrics = false
            end
            update()
        end
    end -- callback
    --
    dialog:RegisterHandleCommand(callback)
    --
    function update()
        if all_lyrics == false then
            independent_lyrics = true
            str.LuaString = "Verse"
            verse_static:SetText(str)
            str.LuaString = "Chorus"
            chorus_static:SetText(str)
            str.LuaString = "Section"
            section_static:SetText(str)
        else
            independent_lyrics = false
            str.LuaString = "All Lyrics"
            verse_static:SetText(str)
            str.LuaString = ""
            chorus_static:SetText(str)
            section_static:SetText(str)
        end
        chorus1_edit:SetEnable(independent_lyrics)
        section1_edit:SetEnable(independent_lyrics)
        chorus_gap_edit:SetEnable(independent_lyrics)
        section_gap_edit:SetEnable(independent_lyrics)
        --
--        chorus1_edit:SetVisible(independent_lyrics)
--        section1_edit:SetVisible(independent_lyrics)
--        chorus_gap_edit:SetVisible(independent_lyrics)
--        section_gap_edit:SetVisible(independent_lyrics)
    end

    update()
    if dialog:ExecuteModal(nil) == finale.EXECMODAL_OK then
        apply()
    end
end -- function

lyrics_spacing("Lyrics - Space Baselines")