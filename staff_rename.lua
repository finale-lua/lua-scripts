function plugindef()
    -- This function and the 'finaleplugin' namespace
    -- are both reserved for the plug-in definition.
    finaleplugin.Author = "Jacob Winkler"
    finaleplugin.Copyright = "2022"
    finaleplugin.Version = "1.1"
    finaleplugin.Date = "3/18/2022"
    finaleplugin.Notes = [[
USING THE 'STAFF RENAME' SCRIPT

This script creates a dialog containing the full and abbreviated names of all selected instruments, including multi-staff instruments such as organ or piano. This allows for quick renaming of staves, with far less mouse clicking than trying to rename them from the Score Manager.

If there is no selection, all staves will be loaded.

There are buttons for each instrument that will copy the full name into the abbreviated name field.

There is a popup at the bottom of the list that will automatically set all transposing instruments to show either the instrument and then the transposition (e.g. "Clarinet in Bb"), or the transposition and then the instrument (e.g. "Bb Clarinet").

Speaking of the Bb Clarinet... Accidentals are displayed with square brackets, so the dialog will show "B[b] Clarinet". This is then converted into symbols using the appropriate Enigma tags. All other font info is retained.

Note that this script is not currently able to address Finale's auto-numbering. When this feature is added to future versions of RGP Lua I will update the script to allow for some quick processing of these as well, such as being able to switch numbering systems for all instruments at once, or hard-coding the player number into the full/abbreviated names and removing auto-numbering.
]]
    return "Rename Staves", "Rename Staves", "Renames selected staves"
end



function staff_rename()
    local multi_inst = finale.FCMultiStaffInstruments()
    multi_inst:LoadAll()
    local multi_inst_grp = {}
    local multi_fullnames = {}
    local multi_full_fonts = {}
    local multi_abbnames = {}
    local multi_abb_fonts = {}
    local multi_added = {}
    local omit_staves = {}
    local multi_staff = {}
    local multi_staves = {}
    local fullnames = {}
    local abbnames = {}
    local full_fonts = {}
    local abb_fonts = {}
    local staves = {}
    --  tables for dialog controls
    local static_staff = {}
    local edit_fullname = {}
    local edit_abbname = {}
    local copy_button = {}
    -- Transposing instruments (Finale 27)
    local form0_names = {"Clarinet in B[b]", "Clarinet in A", "Clarinet in E[b]","Horn in F", "Trumpet in B[b]", "Trumpet in C", "Horn in E[b]", "Piccolo Trumpet in A", "Trumpet in D", "Cornet in E[b]", "Pennywhistle in D", "Pennywhistle in G", "Tin Whistle in B[b]", "Melody Sax in C"}
    local form1_names = {"B[b] Clarinet", "A Clarinet", "E[b] Clarinet", "F Horn", "B[b] Trumpet", "C Trumpet", "E[b] Horn", "A Piccolo Trumpet", "D Trumpet", "E[b] Cornet", "D Pennywhistle", "G Pennywhistle", "B[b] Tin Whistle", "C Melody Sax"}

    function enigma_to_accidental(str)
        str.LuaString = string.gsub(str.LuaString, "%^flat%(%)", "[b]")
        str.LuaString = string.gsub(str.LuaString, "%^natural%(%)", "[n]")
        str.LuaString = string.gsub(str.LuaString, "%^sharp%(%)", "[#]")
        str:TrimEnigmaTags()
        return str
    end

    function accidental_to_enigma(s)
        s.LuaString = string.gsub(s.LuaString, "%[b%]", "^flat()")
        s.LuaString = string.gsub(s.LuaString, "%[n%]", "^natural()")
        s.LuaString = string.gsub(s.LuaString, "%[%#%]", "^sharp()")
        return s
    end

    for inst in each(multi_inst) do
        table.insert(multi_inst_grp, inst.GroupID)
        local grp = finale.FCGroup()
        grp:Load(0, inst.GroupID)
        local str = grp:CreateFullNameString()
        local font = str:CreateLastFontInfo()
        enigma_to_accidental(str)

        table.insert(multi_fullnames, str.LuaString)
        local font_enigma = finale.FCString()
        font_enigma = font:CreateEnigmaString(NULL)
        table.insert(multi_full_fonts, font_enigma.LuaString)
        --
        str = grp:CreateAbbreviatedNameString()
        font = str:CreateLastFontInfo()
        font_enigma = font:CreateEnigmaString(NULL)
        enigma_to_accidental(str)
        table.insert(multi_abbnames, str.LuaString)
        table.insert(multi_abb_fonts, font_enigma.LuaString)
        table.insert(multi_added, false)
        table.insert(omit_staves, inst:GetFirstStaff())
        table.insert(omit_staves, inst:GetSecondStaff())
        if inst:GetThirdStaff() ~= 0 then
            table.insert(omit_staves, inst:GetThirdStaff())
        end
        table.insert(multi_staff, inst:GetFirstStaff())
        table.insert(multi_staff, inst:GetSecondStaff())
        table.insert(multi_staff, inst:GetThirdStaff())
        table.insert(multi_staves, multi_staff)
        multi_staff = {}
    end

    local sysstaves = finale.FCSystemStaves()
    local region = finale.FCMusicRegion()
    region = finenv.Region()
    if region:IsEmpty() then
        region:SetFullDocument()
    end
    sysstaves:LoadAllForRegion(region)

    for sysstaff in each(sysstaves) do
        -- Process multi-staff instruments
        for i,j in pairs(multi_staves) do

            for k,l in pairs(multi_staves[i]) do
                if multi_staves[i][k] == sysstaff.Staff and multi_staves[i][k] ~= 0 then
                    if multi_added[i] == false then
                        table.insert(fullnames, multi_fullnames[i])
                        table.insert(abbnames, multi_abbnames[i])
                        table.insert(full_fonts, multi_full_fonts[i])
                        table.insert(abb_fonts, multi_abb_fonts[i])
                        table.insert(staves, sysstaff.Staff)
                        multi_added[i] = true
                        goto done
                    elseif multi_added == true then
                        goto done
                    end
                end
            end
        end
        for i, j in pairs(omit_staves) do
            if omit_staves[i] == sysstaff.Staff then
                goto done
            end
        end

        -- Process single-staff instruments
        local staff = finale.FCStaff()
        staff:Load(sysstaff.Staff)
        local str = staff:CreateFullNameString()
        local font = str:CreateLastFontInfo()
        enigma_to_accidental(str)
        table.insert(fullnames, str.LuaString)
        local font_enigma = finale.FCString()
        font_enigma = font:CreateEnigmaString(NULL)
        table.insert(full_fonts, font_enigma.LuaString)
        str = staff:CreateAbbreviatedNameString()
        font = str:CreateLastFontInfo()
        enigma_to_accidental(str)
        table.insert(abbnames, str.LuaString)
        font_enigma = font:CreateEnigmaString(NULL)
        table.insert(abb_fonts, font_enigma.LuaString)
        table.insert(staves, sysstaff.Staff)
        ::done::
    end

    function dialog(title)
        local row_h = 20
        local row_count = 1
        local col_w = 140
        local col_gap = 20
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
        for i = 1, 11 do
            col[i] = (i - 1) * col_w
            col[i] = col[i] + 40
        end
--

        function add_ctrl(dialog, ctrl_type, text, x, y, h, w, min, max)
            str.LuaString = text
            local ctrl = ""
            if ctrl_type == "button" then
                ctrl = dialog:CreateButton(x, y)
            elseif ctrl_type == "popup" then
                ctrl = dialog:CreatePopup(x, y)
            elseif ctrl_type == "checkbox" then
                ctrl = dialog:CreateCheckbox(x, y)
            elseif ctrl_type == "edit" then
                ctrl = dialog:CreateEdit(x, y - 2)
            elseif ctrl_type == "horizontalline" then
                ctrl = dialog:CreateHorizontalLine(x, y, w)
            elseif ctrl_type == "static" then
                ctrl = dialog:CreateStatic(x, y)
            elseif ctrl_type == "verticalline" then
                ctrl = dialog:CreateVerticalLine(x, y, h)
            end
            if ctrl_type == "edit" then
                ctrl:SetHeight(h-2)
                ctrl:SetWidth(w - col_gap)
            elseif ctrl_type == "horizontalline" then
                ctrl:SetY(y + h/2)
                ctrl:SetWidth(w)
            else
                ctrl:SetHeight(h)
                ctrl:SetWidth(w)
            end
            ctrl:SetText(str)
            return ctrl
        end

        local staff_num_static = add_ctrl(dialog, "static", "Staff", 0, row[1], row_h, col_w, 0, 0)
        local staff_name_full_static = add_ctrl(dialog, "static", "Full Name", col[1], row[1], row_h, col_w, 0, 0)
        local staff_name_abb_static = add_ctrl(dialog, "static", "Abbr. Name", col[2], row[1], row_h, col_w, 0, 0)
        local copy_all = add_ctrl(dialog, "button", "→", col[2] - col_gap + 2, row[1], row_h-4, 16, 0, 0)
        --local h_line = add_ctrl(dialog, "horizontalline", 0, row[1], 1, col_w * 3, 0, 0)
        --
        for i, j in pairs(staves) do
            static_staff[i] = add_ctrl(dialog, "static", staves[i], 10, row[i + 1], row_h, col_w, 0, 0)
            edit_fullname[i] = add_ctrl(dialog, "edit", fullnames[i], col[1], row[i + 1], row_h, col_w, 0, 0)
            edit_abbname[i] = add_ctrl(dialog, "edit", abbnames[i], col[2], row[i + 1], row_h, col_w, 0, 0)
            copy_button[i] = add_ctrl(dialog, "button", "→", col[2] - col_gap + 2, row[i + 1], row_h-4, 16, 0, 0)
            row_count = row_count + 1
        end
        --
        local form_select = add_ctrl(dialog, "popup", "", col[1], row[row_count + 1] + row_h/2, row_h, col_w - col_gap, 0, 0)
        local forms = {"Inst. in Tr.","Tr. Inst."}
        for i,j in pairs(forms) do
            str.LuaString = forms[i]
            form_select:AddString(str)
        end   
        --
        dialog:CreateOkButton()
        dialog:CreateCancelButton()
        --
        function callback(ctrl)
            if ctrl:GetControlID() == form_select:GetControlID() then
                local form = form_select:GetSelectedItem()
                local search = {}
                local replace = {}
                if form == 0 then
                    search = form1_names
                    replace = form0_names
                elseif form == 1 then
                    search = form0_names
                    replace = form1_names
                end

                for a,b in pairs(search) do
                    search[a] = string.gsub(search[a], "%[", "%%[")
                    search[a] = string.gsub(search[a], "%]", "%%]")
                    replace[a] = string.gsub(replace[a], "%%", "")
                end

                for i,j in pairs(fullnames) do
                    edit_fullname[i]:GetText(str)
                    for k,l in pairs(search) do
                        str.LuaString = string.gsub(str.LuaString, search[k], replace[k])
                    end                    
                    edit_fullname[i]:SetText(str)
                    --
                    edit_abbname[i]:GetText(str)
                    for k,l in pairs(search) do
                        str.LuaString = string.gsub(str.LuaString, search[k], replace[k])
                    end                    
                    edit_abbname[i]:SetText(str)
                end
            end

            for i, j in pairs(copy_button) do
                if ctrl:GetControlID() == copy_button[i]:GetControlID() then
                    edit_fullname[i]:GetText(str)
                    edit_abbname[i]:SetText(str)
                end
            end

            if ctrl:GetControlID() == copy_all:GetControlID() then
                for i,j in pairs(edit_fullname) do
                    edit_fullname[i]:GetText(str)
                    edit_abbname[i]:SetText(str)
                end
            end
        end -- callback
        --
        dialog:RegisterHandleCommand(callback)
        --
        if dialog:ExecuteModal(nil) == finale.EXECMODAL_OK then
            local str = finale.FCString()
            for i, j in pairs(staves) do
                for k, l in pairs(multi_staves) do 
                    for m, n in pairs(multi_staves[k]) do
                        if staves[i] == multi_staves[k][m] then
                            local grp = finale.FCGroup()
                            grp:Load(0, multi_inst_grp[k])
                            edit_fullname[i]:GetText(str)
                            accidental_to_enigma(str)
                            str.LuaString = full_fonts[i]..str.LuaString
                            grp:SaveNewFullNameBlock(str)
                            edit_abbname[i]:GetText(str)
                            accidental_to_enigma(str)
                            str.LuaString = abb_fonts[i]..str.LuaString
                            grp:SaveNewAbbreviatedNameBlock(str)
                            grp:Save()
                        end
                    end
                end
                for k, l in pairs(omit_staves) do
                    if staves[i] == omit_staves[k] then
                        goto done2
                    end
                end
                local staff = finale.FCStaff()
                staff:Load(staves[i])
                edit_fullname[i]:GetText(str)
                accidental_to_enigma(str)
                str.LuaString = full_fonts[i]..str.LuaString
                staff:SaveNewFullNameString(str)
                edit_abbname[i]:GetText(str)
                accidental_to_enigma(str)

                str.LuaString = abb_fonts[i]..str.LuaString
                staff:SaveNewAbbreviatedNameString(str)
                staff:Save()
                ::done2::
            end
        end

    end -- function

    dialog("Rename Staves")

end -- rename_staves()

staff_rename()