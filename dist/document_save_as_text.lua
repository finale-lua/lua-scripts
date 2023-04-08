package.preload["library.note_entry"] = package.preload["library.note_entry"] or function()

    local note_entry = {}

    function note_entry.get_music_region(entry)
        local exp_region = finale.FCMusicRegion()
        exp_region:SetCurrentSelection()
        exp_region.StartStaff = entry.Staff
        exp_region.EndStaff = entry.Staff
        exp_region.StartMeasure = entry.Measure
        exp_region.EndMeasure = entry.Measure
        exp_region.StartMeasurePos = entry.MeasurePos
        exp_region.EndMeasurePos = entry.MeasurePos
        return exp_region
    end


    local use_or_get_passed_in_entry_metrics = function(entry, entry_metrics)
        if entry_metrics then
            return entry_metrics, false
        end
        entry_metrics = finale.FCEntryMetrics()
        if entry_metrics:Load(entry) then
            return entry_metrics, true
        end
        return nil, false
    end

    function note_entry.get_evpu_notehead_height(entry)
        local highest_note = entry:CalcHighestNote(nil)
        local lowest_note = entry:CalcLowestNote(nil)
        local evpu_height = (2 + highest_note:CalcStaffPosition() - lowest_note:CalcStaffPosition()) * 12
        return evpu_height
    end

    function note_entry.get_top_note_position(entry, entry_metrics)
        local retval = -math.huge
        local loaded_here = false
        entry_metrics, loaded_here = use_or_get_passed_in_entry_metrics(entry, entry_metrics)
        if nil == entry_metrics then
            return retval
        end
        if not entry:CalcStemUp() then
            retval = entry_metrics.TopPosition
        else
            local cell_metrics = finale.FCCell(entry.Measure, entry.Staff):CreateCellMetrics()
            if nil ~= cell_metrics then
                local evpu_height = note_entry.get_evpu_notehead_height(entry)
                local scaled_height = math.floor(((cell_metrics.StaffScaling * evpu_height) / 10000) + 0.5)
                retval = entry_metrics.BottomPosition + scaled_height
                cell_metrics:FreeMetrics()
            end
        end
        if loaded_here then
            entry_metrics:FreeMetrics()
        end
        return retval
    end

    function note_entry.get_bottom_note_position(entry, entry_metrics)
        local retval = math.huge
        local loaded_here = false
        entry_metrics, loaded_here = use_or_get_passed_in_entry_metrics(entry, entry_metrics)
        if nil == entry_metrics then
            return retval
        end
        if entry:CalcStemUp() then
            retval = entry_metrics.BottomPosition
        else
            local cell_metrics = finale.FCCell(entry.Measure, entry.Staff):CreateCellMetrics()
            if nil ~= cell_metrics then
                local evpu_height = note_entry.get_evpu_notehead_height(entry)
                local scaled_height = math.floor(((cell_metrics.StaffScaling * evpu_height) / 10000) + 0.5)
                retval = entry_metrics.TopPosition - scaled_height
                cell_metrics:FreeMetrics()
            end
        end
        if loaded_here then
            entry_metrics:FreeMetrics()
        end
        return retval
    end

    function note_entry.calc_widths(entry)
        local left_width = 0
        local right_width = 0
        for note in each(entry) do
            local note_width = note:CalcNoteheadWidth()
            if note_width > 0 then
                if note:CalcRightsidePlacement() then
                    if note_width > right_width then
                        right_width = note_width
                    end
                else
                    if note_width > left_width then
                        left_width = note_width
                    end
                end
            end
        end
        return left_width, right_width
    end




    function note_entry.calc_left_of_all_noteheads(entry)
        if entry:CalcStemUp() then
            return 0
        end
        local left, right = note_entry.calc_widths(entry)
        return -left
    end

    function note_entry.calc_left_of_primary_notehead(entry)
        return 0
    end

    function note_entry.calc_center_of_all_noteheads(entry)
        local left, right = note_entry.calc_widths(entry)
        local width_centered = (left + right) / 2
        if not entry:CalcStemUp() then
            width_centered = width_centered - left
        end
        return width_centered
    end

    function note_entry.calc_center_of_primary_notehead(entry)
        local left, right = note_entry.calc_widths(entry)
        if entry:CalcStemUp() then
            return left / 2
        end
        return right / 2
    end

    function note_entry.calc_stem_offset(entry)
        if not entry:CalcStemUp() then
            return 0
        end
        local left, right = note_entry.calc_widths(entry)
        return left
    end

    function note_entry.calc_right_of_all_noteheads(entry)
        local left, right = note_entry.calc_widths(entry)
        if entry:CalcStemUp() then
            return left + right
        end
        return right
    end

    function note_entry.calc_note_at_index(entry, note_index)
        local x = 0
        for note in each(entry) do
            if x == note_index then
                return note
            end
            x = x + 1
        end
        return nil
    end

    function note_entry.stem_sign(entry)
        if entry:CalcStemUp() then
            return 1
        end
        return -1
    end

    function note_entry.duplicate_note(note)
        local new_note = note.Entry:AddNewNote()
        if nil ~= new_note then
            new_note.Displacement = note.Displacement
            new_note.RaiseLower = note.RaiseLower
            new_note.Tie = note.Tie
            new_note.TieBackwards = note.TieBackwards
        end
        return new_note
    end

    function note_entry.delete_note(note)
        local entry = note.Entry
        if nil == entry then
            return false
        end

        finale.FCAccidentalMod():EraseAt(note)
        finale.FCCrossStaffMod():EraseAt(note)
        finale.FCDotMod():EraseAt(note)
        finale.FCNoteheadMod():EraseAt(note)
        finale.FCPercussionNoteMod():EraseAt(note)
        finale.FCTablatureNoteMod():EraseAt(note)
        if finale.FCTieMod then
            finale.FCTieMod(finale.TIEMODTYPE_TIESTART):EraseAt(note)
            finale.FCTieMod(finale.TIEMODTYPE_TIEEND):EraseAt(note)
        end
        return entry:DeleteNote(note)
    end

    function note_entry.make_rest(entry)
        local articulations = entry:CreateArticulations()
        for articulation in each(articulations) do
            articulation:DeleteData()
        end
        if entry:IsNote() then
            while entry.Count > 0 do
                note_entry.delete_note(entry:GetItemAt(0))
            end
        end
        entry:MakeRest()
        return true
    end

    function note_entry.calc_pitch_string(note)
        local pitch_string = finale.FCString()
        local cell = finale.FCCell(note.Entry.Measure, note.Entry.Staff)
        local key_signature = cell:GetKeySignature()
        note:GetString(pitch_string, key_signature, false, false)
        return pitch_string
    end

    function note_entry.calc_spans_number_of_octaves(entry)
        local top_note = entry:CalcHighestNote(nil)
        local bottom_note = entry:CalcLowestNote(nil)
        local displacement_diff = top_note.Displacement - bottom_note.Displacement
        local num_octaves = math.ceil(displacement_diff / 7)
        return num_octaves
    end

    function note_entry.add_augmentation_dot(entry)

        entry.Duration = bit32.bor(entry.Duration, bit32.rshift(entry.Duration, 1))
    end

    function note_entry.get_next_same_v(entry)
        local next_entry = entry:Next()
        if entry.Voice2 then
            if (nil ~= next_entry) and next_entry.Voice2 then
                return next_entry
            end
            return nil
        end
        if entry.Voice2Launch then
            while (nil ~= next_entry) and next_entry.Voice2 do
                next_entry = next_entry:Next()
            end
        end
        return next_entry
    end

    function note_entry.hide_stem(entry)
        local stem = finale.FCCustomStemMod()
        stem:SetNoteEntry(entry)
        stem:UseUpStemData(entry:CalcStemUp())
        if stem:LoadFirst() then
            stem.ShapeID = 0
            stem:Save()
        else
            stem.ShapeID = 0
            stem:SaveNew()
        end
    end

    function note_entry.rest_offset(entry, offset)
        if entry:IsNote() then
            return false
        end
        if offset == 0 then
            entry:SetFloatingRest(true)
        else
            local rest_prop = "OtherRestPosition"
            if entry.Duration >= finale.BREVE then
                rest_prop = "DoubleWholeRestPosition"
            elseif entry.Duration >= finale.WHOLE_NOTE then
                rest_prop = "WholeRestPosition"
            elseif entry.Duration >= finale.HALF_NOTE then
                rest_prop = "HalfRestPosition"
            end
            entry:MakeMovableRest()
            local rest = entry:GetItemAt(0)
            local curr_staffpos = rest:CalcStaffPosition()
            local staff_spec = finale.FCCurrentStaffSpec()
            staff_spec:LoadForEntry(entry)
            local total_offset = staff_spec[rest_prop] + offset - curr_staffpos
            entry:SetRestDisplacement(entry:GetRestDisplacement() + total_offset)
        end
        return true
    end
    return note_entry
end
package.preload["library.expression"] = package.preload["library.expression"] or function()

    local expression = {}
    local library = require("library.general_library")
    local note_entry = require("library.note_entry")
    local enigma_string = require("library.enigma_string")

    function expression.get_music_region(exp_assign)
        if not exp_assign:IsSingleStaffAssigned() then
            return nil
        end
        local exp_region = finale.FCMusicRegion()
        exp_region:SetCurrentSelection()
        exp_region.StartStaff = exp_assign.Staff
        exp_region.EndStaff = exp_assign.Staff
        exp_region.StartMeasure = exp_assign.Measure
        exp_region.EndMeasure = exp_assign.Measure
        exp_region.StartMeasurePos = exp_assign.MeasurePos
        exp_region.EndMeasurePos = exp_assign.MeasurePos
        return exp_region
    end

    function expression.get_associated_entry(exp_assign)
        local exp_region = expression.get_music_region(exp_assign)
        if nil == exp_region then
            return nil
        end
        for entry in eachentry(exp_region) do
            if (0 == exp_assign.LayerAssignment) or (entry.LayerNumber == exp_assign.LayerAssignment) then
                if not entry:GetGraceNote() then
                    return entry
                end
            end
        end
        return nil
    end

    function expression.calc_handle_offset_for_smart_shape(exp_assign)
        local manual_horizontal = exp_assign.HorizontalPos
        local def_horizontal = 0
        local alignment_offset = 0
        local exp_def = exp_assign:CreateTextExpressionDef()
        if nil ~= exp_def then
            def_horizontal = exp_def.HorizontalOffset
        end
        local exp_entry = expression.get_associated_entry(exp_assign)
        local ent_position = exp_entry and exp_entry.ManualPosition or 0
        if (nil ~= exp_entry) and (nil ~= exp_def) then
            if finale.ALIGNHORIZ_LEFTOFALLNOTEHEAD == exp_def.HorizontalAlignmentPoint then
                alignment_offset = note_entry.calc_left_of_all_noteheads(exp_entry)
            elseif finale.ALIGNHORIZ_LEFTOFPRIMARYNOTEHEAD == exp_def.HorizontalAlignmentPoint then
                alignment_offset = note_entry.calc_left_of_primary_notehead(exp_entry)
            elseif finale.ALIGNHORIZ_STEM == exp_def.HorizontalAlignmentPoint then
                alignment_offset = note_entry.calc_stem_offset(exp_entry)
            elseif finale.ALIGNHORIZ_CENTERPRIMARYNOTEHEAD == exp_def.HorizontalAlignmentPoint then
                alignment_offset = note_entry.calc_center_of_primary_notehead(exp_entry)
            elseif finale.ALIGNHORIZ_CENTERALLNOTEHEADS == exp_def.HorizontalAlignmentPoint then
                alignment_offset = note_entry.calc_center_of_all_noteheads(exp_entry)
            elseif finale.ALIGNHORIZ_RIGHTALLNOTEHEADS == exp_def.HorizontalAlignmentPoint then
                alignment_offset = note_entry.calc_right_of_all_noteheads(exp_entry)
            end
        end
        return (manual_horizontal + def_horizontal + ent_position + alignment_offset)
    end

    function expression.calc_text_width(expression_def, expand_tags)
        expand_tags = expand_tags or false
        local fcstring = expression_def:CreateTextString()
        if expand_tags then
            enigma_string.expand_value_tag(fcstring, expression_def:GetPlaybackTempoValue())
        end
        local retval = enigma_string.calc_text_advance_width(fcstring)
        return retval
    end

    function expression.is_for_current_part(exp_assign, current_part)
        current_part = current_part or library.get_current_part()
        if current_part:IsScore() and exp_assign.ScoreAssignment then
            return true
        elseif current_part:IsPart() and exp_assign.PartAssignment then
            return true
        end
        return false
    end

    function expression.is_dynamic(exp)
        if not exp:IsShape() and exp.Visible and exp.StaffGroupID == 0 then
            local cat_id = exp:CreateTextExpressionDef().CategoryID
            if cat_id == finale.DEFAULTCATID_DYNAMICS then
                return true
            end
            local cd = finale.FCCategoryDef()
            cd:Load(cat_id)
            if cd.Type == finale.DEFAULTCATID_DYNAMICS then
                return true
            end
            local exp_name = cd:CreateName().LuaString
            if string.find(exp_name, "Dynamic") or string.find(exp_name, "dynamic") then
                return true
            end
        end
        return false
    end

    function expression.resync_expressions_for_category(category_id)
        for expression_def in loadall(finale.FCTextExpressionDefs()) do
            if expression_def.CategoryID == category_id then
                expression.resync_to_category(expression_def)
            end
        end
    end

    function expression.resync_to_category(expression_def)
        local cat = finale.FCCategoryDef()
        cat:Load(expression_def.CategoryID)

        if expression_def.UseCategoryFont then
            local str = expression_def:CreateTextString()
            if str then
                str:ReplaceCategoryFonts(cat, finale.CATEGORYMODE_TEXT, false)
                str:ReplaceCategoryFonts(cat, finale.CATEGORYMODE_MUSIC, false)
                str:ReplaceCategoryFonts(cat, finale.CATEGORYMODE_NUMBER, false)
                expression_def:SaveTextString(str)
            end
        end
        if expression_def.UseCategoryPos then
            local pos_props = {
                "HorizontalJustification",
                "HorizontalAlignmentPoint",
                "HorizontalOffset",
                "VerticalAlignmentPoint",
                "VerticalBaselineOffset",
                "VerticalEntryOffset"
            }
            for _, prop in pairs(pos_props) do
                expression_def[prop] = cat[prop]
            end
            expression_def:Save()
        end
    end
    return expression
end
package.preload["library.enigma_string"] = package.preload["library.enigma_string"] or function()

    local enigma_string = {}
    local starts_with_font_command = function(string)
        local text_cmds = {"^font", "^Font", "^fontMus", "^fontTxt", "^fontNum", "^size", "^nfx"}
        for i, text_cmd in ipairs(text_cmds) do
            if string:StartsWith(text_cmd) then
                return true
            end
        end
        return false
    end


    function enigma_string.trim_first_enigma_font_tags(string)
        local font_info = finale.FCFontInfo()
        local found_tag = false
        while true do
            if not starts_with_font_command(string) then
                break
            end
            local end_of_tag = string:FindFirst(")")
            if end_of_tag < 0 then
                break
            end
            local font_tag = finale.FCString()
            if string:SplitAt(end_of_tag, font_tag, nil, true) then
                font_info:ParseEnigmaCommand(font_tag)
            end
            string:DeleteCharactersAt(0, end_of_tag + 1)
            found_tag = true
        end
        if found_tag then
            return font_info
        end
        return nil
    end

    function enigma_string.change_first_string_font(string, font_info)
        local final_text = font_info:CreateEnigmaString(nil)
        local current_font_info = enigma_string.trim_first_enigma_font_tags(string)
        if (current_font_info == nil) or not font_info:IsIdenticalTo(current_font_info) then
            final_text:AppendString(string)
            string:SetString(final_text)
            return true
        end
        return false
    end

    function enigma_string.change_first_text_block_font(text_block, font_info)
        local new_text = text_block:CreateRawTextString()
        if enigma_string.change_first_string_font(new_text, font_info) then
            text_block:SaveRawTextString(new_text)
            return true
        end
        return false
    end



    function enigma_string.change_string_font(string, font_info)
        local final_text = font_info:CreateEnigmaString(nil)
        string:TrimEnigmaFontTags()
        final_text:AppendString(string)
        string:SetString(final_text)
    end

    function enigma_string.change_text_block_font(text_block, font_info)
        local new_text = text_block:CreateRawTextString()
        enigma_string.change_string_font(new_text, font_info)
        text_block:SaveRawTextString(new_text)
    end

    function enigma_string.remove_inserts(fcstring, replace_with_generic)


        local text_cmds = {
            "^arranger", "^composer", "^copyright", "^date", "^description", "^fdate", "^filename", "^lyricist", "^page",
            "^partname", "^perftime", "^subtitle", "^time", "^title", "^totpages",
        }
        local lua_string = fcstring.LuaString
        for i, text_cmd in ipairs(text_cmds) do
            local starts_at = string.find(lua_string, text_cmd, 1, true)
            while nil ~= starts_at do
                local replace_with = ""
                if replace_with_generic then
                    replace_with = string.sub(text_cmd, 2)
                end
                local after_text_at = starts_at + string.len(text_cmd)
                local next_at = string.find(lua_string, ")", after_text_at, true)
                if nil ~= next_at then
                    next_at = next_at + 1
                else
                    next_at = starts_at
                end
                lua_string = string.sub(lua_string, 1, starts_at - 1) .. replace_with .. string.sub(lua_string, next_at)
                starts_at = string.find(lua_string, text_cmd, 1, true)
            end
        end
        fcstring.LuaString = lua_string
    end

    function enigma_string.expand_value_tag(fcstring, value_num)
        value_num = math.floor(value_num + 0.5)
        fcstring.LuaString = fcstring.LuaString:gsub("%^value%(%)", tostring(value_num))
    end

    function enigma_string.calc_text_advance_width(inp_string)
        local accumulated_string = ""
        local accumulated_width = 0
        local enigma_strings = inp_string:CreateEnigmaStrings(true)
        for str in each(enigma_strings) do
            accumulated_string = accumulated_string .. str.LuaString
            if string.sub(str.LuaString, 1, 1) ~= "^" then
                local fcstring = finale.FCString()
                local text_met = finale.FCTextMetrics()
                fcstring.LuaString = accumulated_string
                local font_info = fcstring:CreateLastFontInfo()
                fcstring.LuaString = str.LuaString
                fcstring:TrimEnigmaTags()
                text_met:LoadString(fcstring, font_info, 100)
                accumulated_width = accumulated_width + text_met:GetAdvanceWidthEVPUs()
            end
        end
        return accumulated_width
    end
    return enigma_string
end
package.preload["mixin.FCMControl"] = package.preload["mixin.FCMControl"] or function()



    local mixin = require("library.mixin")
    local mixin_helper = require("library.mixin_helper")
    local meta = {}
    local public = {}
    local private = setmetatable({}, {__mode = "k"})

    local parent = setmetatable({}, {__mode = "kv"})
    local temp_str = finale.FCString()

    function meta:Init()
        if private[self] then
            return
        end
        private[self] = {}
    end

    function public:GetParent()
        return parent[self]
    end

    function public:RegisterParent(window)
        mixin_helper.assert_argument_type(2, window, "FCMCustomWindow", "FCMCustomLuaWindow")
        if parent[self] then
            error("This method is for internal use only.", 2)
        end
        parent[self] = window
    end












    for method, valid_types in pairs({
        Enable = {"boolean", "nil"},
        Visible = {"boolean", "nil"},
        Left = {"number"},
        Top = {"number"},
        Height = {"number"},
        Width = {"number"},
    }) do
        public["Get" .. method] = function(self)
            if mixin.FCMControl.UseStoredState(self) then
                return private[self][method]
            end
            return self["Get" .. method .. "_"](self)
        end
        public["Set" .. method] = function(self, value)
            mixin_helper.assert_argument_type(2, value, table.unpack(valid_types))
            if mixin.FCMControl.UseStoredState(self) then
                private[self][method] = value
            else

                if (method == "Enable" or method == "Visible") and finenv.UI():IsOnMac() and finenv.MajorVersion == 0 and finenv.MinorVersion < 63 then
                    self:GetText_(temp_str)
                    self:SetText_(temp_str)
                end
                self["Set" .. method .. "_"](self, value)
            end
        end
    end

    function public:GetText(str)
        mixin_helper.assert_argument_type(2, str, "nil", "FCString")
        local do_return = false
        if not str then
            str = temp_str
            do_return = true
        end
        if mixin.FCMControl.UseStoredState(self) then
            str.LuaString = private[self].Text
        else
            self:GetText_(str)
        end
        if do_return then
            return str.LuaString
        end
    end

    function public:SetText(str)
        mixin_helper.assert_argument_type(2, str, "string", "number", "FCString")
        str = mixin_helper.to_fcstring(str, temp_str)
        if mixin.FCMControl.UseStoredState(self) then
            private[self].Text = str.LuaString
        else
            self:SetText_(str)
        end
    end

    function public:UseStoredState()
        local parent = self:GetParent()
        return mixin_helper.is_instance_of(parent, "FCMCustomLuaWindow") and parent:GetRestoreControlState() and not parent:WindowExists() and parent:HasBeenShown()
    end

    function public:StoreState()
        self:GetText_(temp_str)
        private[self].Text = temp_str.LuaString
        private[self].Enable = self:GetEnable_()
        private[self].Visible = self:GetVisible_()
        private[self].Left = self:GetLeft_()
        private[self].Top = self:GetTop_()
        private[self].Height = self:GetHeight_()
        private[self].Width = self:GetWidth_()
    end

    function public:RestoreState()
        self:SetEnable_(private[self].Enable)
        self:SetVisible_(private[self].Visible)
        self:SetLeft_(private[self].Left)
        self:SetTop_(private[self].Top)
        self:SetHeight_(private[self].Height)
        self:SetWidth_(private[self].Width)

        temp_str.LuaString = private[self].Text
        self:SetText_(temp_str)
    end


    public.AddHandleCommand, public.RemoveHandleCommand = mixin_helper.create_standard_control_event("HandleCommand")
    return {meta, public}
end
package.preload["mixin.FCMCtrlButton"] = package.preload["mixin.FCMCtrlButton"] or function()



    local mixin_helper = require("library.mixin_helper")
    local meta = {}
    local public = {}
    mixin_helper.disable_methods(public, "AddHandleCheckChange", "RemoveHandleCheckChange")
    return {meta, public}
end
package.preload["mixin.FCMCtrlCheckbox"] = package.preload["mixin.FCMCtrlCheckbox"] or function()



    local mixin = require("library.mixin")
    local mixin_helper = require("library.mixin_helper")
    local meta = {}
    local public = {}
    local trigger_check_change
    local each_last_check_change

    function public:SetCheck(checked)
        mixin_helper.assert_argument_type(2, checked, "number")
        self:SetCheck_(checked)
        trigger_check_change(self)
    end



    public.AddHandleCheckChange, public.RemoveHandleCheckChange, trigger_check_change, each_last_check_change =
        mixin_helper.create_custom_control_change_event(


            {name = "last_check", get = "GetCheck_", initial = 0})
    return {meta, public}
end
package.preload["mixin.FCMCtrlDataList"] = package.preload["mixin.FCMCtrlDataList"] or function()



    local mixin = require("library.mixin")
    local mixin_helper = require("library.mixin_helper")
    local meta = {}
    local public = {}
    local temp_str = finale.FCString()

    function public:AddColumn(title, columnwidth)
        mixin_helper.assert_argument_type(2, title, "string", "number", "FCString")
        mixin_helper.assert_argument_type(3, columnwidth, "number")
        self:AddColumn_(mixin_helper.to_fcstring(title, temp_str), columnwidth)
    end

    function public:SetColumnTitle(columnindex, title)
        mixin_helper.assert_argument_type(2, columnindex, "number")
        mixin_helper.assert_argument_type(3, title, "string", "number", "FCString")
        self:SetColumnTitle_(columnindex, mixin_helper.to_fcstring(title, temp_str))
    end


    public.AddHandleCheck, public.RemoveHandleCheck = mixin_helper.create_standard_control_event("HandleDataListCheck")


    public.AddHandleSelect, public.RemoveHandleSelect = mixin_helper.create_standard_control_event("HandleDataListSelect")
    return {meta, public}
end
package.preload["mixin.FCMCtrlEdit"] = package.preload["mixin.FCMCtrlEdit"] or function()



    local mixin = require("library.mixin")
    local mixin_helper = require("library.mixin_helper")
    local utils = require("library.utils")
    local meta = {}
    local public = {}
    local trigger_change
    local each_last_change
    local temp_str = mixin.FCMString()

    function public:SetText(str)
        mixin_helper.assert_argument_type(2, str, "string", "number", "FCString")
        mixin.FCMControl.SetText(self, str)
        trigger_change(self)
    end




    for method, valid_types in pairs({
        Integer = {"number"},
        Float = {"number"},
    }) do
        public["Get" .. method] = function(self)

            mixin.FCMControl.GetText(self, temp_str)
            return temp_str["Get" .. method](temp_str, 0)
        end
        public["Set" .. method] = function(self, value)
            mixin_helper.assert_argument_type(2, value, table.unpack(valid_types))
            temp_str["Set" .. method](temp_str, value)
            mixin.FCMControl.SetText(self, temp_str)
            trigger_change(self)
        end
    end












    for method, valid_types in pairs({
        Measurement = {"number"},
        MeasurementEfix = {"number"},
        MeasurementInteger = {"number"},
        Measurement10000th = {"number"},
    }) do
        public["Get" .. method] = function(self, measurementunit)
            mixin_helper.assert_argument_type(2, measurementunit, "number")
            mixin.FCMControl.GetText(self, temp_str)
            return temp_str["Get" .. method](temp_str, measurementunit)
        end
        public["GetRange" .. method] = function(self, measurementunit, minimum, maximum)
            mixin_helper.assert_argument_type(2, measurementunit, "number")
            mixin_helper.assert_argument_type(3, minimum, "number")
            mixin_helper.assert_argument_type(4, maximum, "number")
            mixin.FCMControl.GetText(self, temp_str)
            return temp_str["GetRange" .. method](temp_str, measurementunit, minimum, maximum)
        end
        public["Set" .. method] = function(self, value, measurementunit)
            mixin_helper.assert_argument_type(2, value, table.unpack(valid_types))
            mixin_helper.assert_argument_type(3, measurementunit, "number")
            temp_str["Set" .. method](temp_str, value, measurementunit)
            mixin.FCMControl.SetText(self, temp_str)
            trigger_change(self)
        end
    end

    function public:GetRangeInteger(minimum, maximum)
        mixin_helper.assert_argument_type(2, minimum, "number")
        mixin_helper.assert_argument_type(3, maximum, "number")
        return utils.clamp(mixin.FCMCtrlEdit.GetInteger(self), math.ceil(minimum), math.floor(maximum))
    end



    public.AddHandleChange, public.RemoveHandleChange, trigger_change, each_last_change = mixin_helper.create_custom_control_change_event(
        {
            name = "last_value",
            get = mixin.FCMControl.GetText,
            initial = ""
        }
    )
    return {meta, public}
end
package.preload["mixin.FCMCtrlListBox"] = package.preload["mixin.FCMCtrlListBox"] or function()



    local mixin = require("library.mixin")
    local mixin_helper = require("library.mixin_helper")
    local library = require("library.general_library")
    local utils = require("library.utils")
    local meta = {}
    local public = {}
    local private = setmetatable({}, {__mode = "k"})
    local trigger_selection_change
    local each_last_selection_change
    local temp_str = finale.FCString()

    function meta:Init()
        if private[self] then
            return
        end
        private[self] = {
            Items = {},
        }
    end

    function public:StoreState()
        mixin.FCMControl.StoreState(self)
        private[self].SelectedItem = self:GetSelectedItem_()
    end

    function public:RestoreState()
        mixin.FCMControl.RestoreState(self)
        self:Clear_()
        for _, str in ipairs(private[self].Items) do
            temp_str.LuaString = str
            self:AddString_(temp_str)
        end
        self:SetSelectedItem_(private[self].SelectedItem)
    end

    function public:Clear()
        if not mixin.FCMControl.UseStoredState(self) then
            self:Clear_()
        end
        private[self].Items = {}
        for v in each_last_selection_change(self) do
            if v.last_item >= 0 then
                v.is_deleted = true
            end
        end
        trigger_selection_change(self)
    end

    function public:GetCount()
        if mixin.FCMControl.UseStoredState(self) then
            return #private[self].Items
        end
        return self:GetCount_()
    end

    function public:GetSelectedItem()
        if mixin.FCMControl.UseStoredState(self) then
            return private[self].SelectedItem
        end
        return self:GetSelectedItem_()
    end

    function public:SetSelectedItem(index)
        mixin_helper.assert_argument_type(2, index, "number")
        if mixin.FCMControl.UseStoredState(self) then
            private[self].SelectedItem = index
        else
            self:SetSelectedItem_(index)
        end
        trigger_selection_change(self)
    end

    function public:SetSelectedLast()
        local return_value
        if mixin.FCMControl.UseStoredState(self) then
            local count = mixin.FCMCtrlListBox.GetCount(self)
            mixin.FCMCtrlListBox.SetSelectedItem(self, count - 1)
            return_value = count > 0 and true or false
        else
            return_value = self:SetSelectedLast_()
        end
        trigger_selection_change(self)
        return return_value
    end

    function public:HasSelection()
        return mixin.FCMCtrlListBox.GetSelectedItem(self) >= 0
    end

    function public:ItemExists(index)
        mixin_helper.assert_argument_type(2, index, "number")
        return private[self].Items[index + 1] and true or false
    end

    function public:AddString(str)
        mixin_helper.assert_argument_type(2, str, "string", "number", "FCString")
        str = mixin_helper.to_fcstring(str, temp_str)
        if not mixin.FCMControl.UseStoredState(self) then
            self:AddString_(str)
        end

        table.insert(private[self].Items, str.LuaString)
    end

    function public:AddStrings(...)
        for i = 1, select("#", ...) do
            local v = select(i, ...)
            mixin_helper.assert_argument_type(i + 1, v, "string", "number", "FCString", "FCStrings")
            if type(v) == "userdata" and v:ClassName() == "FCStrings" then
                for str in each(v) do
                    mixin.FCMCtrlListBox.AddString(self, str)
                end
            else
                mixin.FCMCtrlListBox.AddString(self, v)
            end
        end
    end

    function public:GetStrings(strs)
        mixin_helper.assert_argument_type(2, strs, "nil", "FCStrings")
        if strs then
            mixin.FCMStrings.CopyFromStringTable(strs, private[self].Items)
        else
            return utils.copy_table(private[self].Items)
        end
    end

    function public:SetStrings(...)
        for i = 1, select("#", ...) do
            mixin_helper.assert_argument_type(i + 1, select(i, ...), "FCStrings", "FCString", "string", "number")
        end
        local strs = select(1, ...)
        if select("#", ...) ~= 1 or not mixin_helper.is_instance_of(strs, "FCStrings") then
            strs = mixin.FCMStrings()
            strs:AddCopies(...)
        end
        if not mixin.FCMControl.UseStoredState(self) then
            self:SetStrings_(strs)
        end

        private[self].Items = mixin.FCMStrings.CreateStringTable(strs)
        for v in each_last_selection_change(self) do
            if v.last_item >= 0 then
                v.is_deleted = true
            end
        end
        trigger_selection_change(self)
    end

    function public:GetItemText(index, str)
        mixin_helper.assert_argument_type(2, index, "number")
        mixin_helper.assert_argument_type(3, str, "nil", "FCString")
        if not mixin.FCMCtrlListBox.ItemExists(self, index) then
            error("No item at index " .. tostring(index), 2)
        end
        if str then
            str.LuaString = private[self].Items[index + 1]
        else
            return private[self].Items[index + 1]
        end
    end

    function public:SetItemText(index, str)
        mixin_helper.assert_argument_type(2, index, "number")
        mixin_helper.assert_argument_type(3, str, "string", "number", "FCString")
        if not private[self].Items[index + 1] then
            error("No item at index " .. tostring(index), 2)
        end
        str = mixin_helper.to_fcstring(str, temp_str)

        if private[self].Items[index + 1] == str then
            return
        end
        private[self].Items[index + 1] = str.LuaString
        if not mixin.FCMControl.UseStoredState(self) then

            if self.SetItemText_ and self:GetParent():WindowExists_() then
                self:SetItemText_(index, str)

            else
                local curr_item = mixin.FCMCtrlListBox.GetSelectedItem(self)
                self:SetStrings_(mixin.FCMStrings():CopyFromStringTable(private[self].Items))
                self:SetSelectedItem_(curr_item)
            end
        end
    end

    function public:GetSelectedString(str)
        mixin_helper.assert_argument_type(2, str, "nil", "FCString")
        local index = mixin.FCMCtrlListBox.GetSelectedItem(self)
        if str then
            str.LuaString = index ~= -1 and private[self].Items[index + 1] or ""
        else
            return index ~= -1 and private[self].Items[index + 1] or nil
        end
    end

    function public:SetSelectedString(str)
        mixin_helper.assert_argument_type(2, str, "string", "number", "FCString")
        str = type(str) == "userdata" and str.LuaString or tostring(str)
        for k, v in ipairs(private[self].Items) do
            if str == v then
                mixin.FCMCtrlListBox.SetSelectedItem(self, k - 1)
                return
            end
        end
    end

    function public:InsertItem(index, str)
        mixin_helper.assert_argument_type(2, index, "number")
        mixin_helper.assert_argument_type(3, str, "string", "number", "FCString")
        if index < 0 then
            index = 0
        elseif index >= mixin.FCMCtrlListBox.GetCount(self) then
            mixin.FCMCtrlListBox.AddString(self, str)
            return
        end
        table.insert(private[self].Items, index + 1, type(str) == "userdata" and str.LuaString or tostring(str))
        local current_selection = mixin.FCMCtrlListBox.GetSelectedItem(self)
        if not mixin.FCMControl.UseStoredState(self) then
            self:SetStrings_(mixin.FCMStrings():CopyFromStringTable(private[self].Items))
        end
        local new_selection = current_selection + (index <= current_selection and 1 or 0)
        mixin.FCMCtrlListBox.SetSelectedItem(self, new_selection)
        for v in each_last_selection_change(self) do
            if v.last_item >= index then
                v.last_item = v.last_item + 1
            end
        end
    end

    function public:DeleteItem(index)
        mixin_helper.assert_argument_type(2, index, "number")
        if index < 0 or index >= mixin.FCMCtrlListBox.GetCount(self) then
            return
        end
        table.remove(private[self].Items, index + 1)

        local current_selection = mixin.FCMCtrlListBox.GetSelectedItem(self)
        if not mixin.FCMControl.UseStoredState(self) then
            self:SetStrings_(mixin.FCMStrings():CopyFromStringTable(private[self].Items))
        end
        local new_selection
        if index < current_selection then
            new_selection = current_selection - 1
        elseif index == current_selection then
            new_selection = -1
        else
            new_selection = current_selection
        end
        mixin.FCMCtrlListBox.SetSelectedItem(self, new_selection)
        for v in each_last_selection_change(self) do
            if v.last_item == index then
                v.is_deleted = true
            elseif v.last_item > index then
                v.last_item = v.last_item - 1
            end
        end

        if index == current_selection then
            trigger_selection_change(self)
        end
    end



    public.AddHandleSelectionChange, public.RemoveHandleSelectionChange, trigger_selection_change, each_last_selection_change = mixin_helper.create_custom_control_change_event(
        {
            name = "last_item",
            get = function(ctrl)
                return mixin.FCMCtrlListBox.GetSelectedItem(ctrl)
            end,
            initial = -1,
        }, {
            name = "last_item_text",
            get = function(ctrl)
                return mixin.FCMCtrlListBox.GetSelectedString(ctrl) or ""
            end,
            initial = "",
        }, {
            name = "is_deleted",
            get = function()
                return false
            end,
            initial = false,
        }
    )
    return {meta, public}
end
package.preload["mixin.FCMCtrlPopup"] = package.preload["mixin.FCMCtrlPopup"] or function()



    local mixin = require("library.mixin")
    local mixin_helper = require("library.mixin_helper")
    local library = require("library.general_library")
    local utils = require("library.utils")
    local meta = {}
    local public = {}
    local private = setmetatable({}, {__mode = "k"})
    local trigger_selection_change
    local each_last_selection_change
    local temp_str = finale.FCString()

    function meta:Init()
        if private[self] then
            return
        end
        private[self] = {
            Items = {},
        }
    end

    function public:StoreState()
        mixin.FCMControl.StoreState(self)
        private[self].SelectedItem = self:GetSelectedItem_()
    end

    function public:RestoreState()
        mixin.FCMControl.RestoreState(self)
        self:Clear_()
        for _, str in ipairs(private[self].Items) do
            temp_str.LuaString = str
            self:AddString_(temp_str)
        end
        self:SetSelectedItem_(private[self].SelectedItem)
    end

    function public:Clear()
        if not mixin.FCMControl.UseStoredState(self) then
            self:Clear_()
        end
        private[self].Items = {}
        for v in each_last_selection_change(self) do
            if v.last_item >= 0 then
                v.is_deleted = true
            end
        end

        trigger_selection_change(self)
    end

    function public:GetCount()
        if mixin.FCMControl.UseStoredState(self) then
            return #private[self].Items
        end
        return self:GetCount_()
    end

    function public:GetSelectedItem()
        if mixin.FCMControl.UseStoredState(self) then
            return private[self].SelectedItem
        end
        return self:GetSelectedItem_()
    end

    function public:SetSelectedItem(index)
        mixin_helper.assert_argument_type(2, index, "number")
        if mixin.FCMControl.UseStoredState(self) then
            private[self].SelectedItem = index
        else
            self:SetSelectedItem_(index)
        end
        trigger_selection_change(self)
    end

    function public:SetSelectedLast()
        mixin.FCMCtrlPopup.SetSelectedItem(self, mixin.FCMCtrlPopup.GetCount(self) - 1)
    end

    function public:HasSelection()
        return mixin.FCMCtrlPopup.GetSelectedItem(self) >= 0
    end

    function public:ItemExists(index)
        mixin_helper.assert_argument_type(2, index, "number")
        return private[self].Items[index + 1] and true or false
    end

    function public:AddString(str)
        mixin_helper.assert_argument_type(2, str, "string", "number", "FCString")
        str = mixin_helper.to_fcstring(str, temp_str)
        if not mixin.FCMControl.UseStoredState(self) then
            self:AddString_(str)
        end

        table.insert(private[self].Items, str.LuaString)
    end

    function public:AddStrings(...)
        for i = 1, select("#", ...) do
            local v = select(i, ...)
            mixin_helper.assert_argument_type(i + 1, v, "string", "number", "FCString", "FCStrings")
            if type(v) == "userdata" and v:ClassName() == "FCStrings" then
                for str in each(v) do
                    mixin.FCMCtrlPopup.AddString(self, str)
                end
            else
                mixin.FCMCtrlPopup.AddString(self, v)
            end
        end
    end

    function public:GetStrings(strs)
        mixin_helper.assert_argument_type(2, strs, "nil", "FCStrings")
        if strs then
            mixin.FCMStrings.CopyFromStringTable(strs, private[self].Items)
        else
            return utils.copy_table(private[self].Items)
        end
    end

    function public:SetStrings(...)
        for i = 1, select("#", ...) do
            mixin_helper.assert_argument_type(i + 1, select(i, ...), "FCStrings", "FCString", "string", "number")
        end
        local strs = select(1, ...)
        if select("#", ...) ~= 1 or not mixin_helper.is_instance_of(strs, "FCStrings") then
            strs = mixin.FCMStrings()
            strs:AddCopies(...)
        end
        if not mixin.FCMControl.UseStoredState(self) then
            self:SetStrings_(strs)
        end

        private[self].Items = mixin.FCMStrings.CreateStringTable(strs)
        for v in each_last_selection_change(self) do
            if v.last_item >= 0 then
                v.is_deleted = true
            end
        end
        trigger_selection_change(self)
    end

    function public:GetItemText(index, str)
        mixin_helper.assert_argument_type(2, index, "number")
        mixin_helper.assert_argument_type(3, str, "nil", "FCString")
        if not mixin.FCMCtrlPopup.ItemExists(self, index) then
            error("No item at index " .. tostring(index), 2)
        end
        if str then
            str.LuaString = private[self].Items[index + 1]
        else
            return private[self].Items[index + 1]
        end
    end

    function public:SetItemText(index, str)
        mixin_helper.assert_argument_type(2, index, "number")
        mixin_helper.assert_argument_type(3, str, "string", "number", "FCString")
        if not mixin.FCMCtrlPopup.ItemExists(self, index) then
            error("No item at index " .. tostring(index), 2)
        end
        str = type(str) == "userdata" and str.LuaString or tostring(str)

        if private[self].Items[index + 1] == str then
            return
        end
        private[self].Items[index + 1] = str
        if not mixin.FCMControl.UseStoredState(self) then
            local curr_item = self:GetSelectedItem_()
            self:SetStrings_(mixin.FCMStrings():CopyFromStringTable(private[self].Items))
            self:SetSelectedItem_(curr_item)
        end
    end

    function public:GetSelectedString(str)
        mixin_helper.assert_argument_type(2, str, "nil", "FCString")
        local index = mixin.FCMCtrlPopup.GetSelectedItem(self)
        if str then
            str.LuaString = index ~= -1 and private[self].Items[index + 1] or ""
        else
            return index ~= -1 and private[self].Items[index + 1] or nil
        end
    end

    function public:SetSelectedString(str)
        mixin_helper.assert_argument_type(2, str, "string", "number", "FCString")
        str = type(str) == "userdata" and str.LuaString or tostring(str)
        for k, v in ipairs(private[self].Items) do
            if str == v then
                mixin.FCMCtrlPopup.SetSelectedItem(self, k - 1)
                return
            end
        end
    end

    function public:InsertString(index, str)
        mixin_helper.assert_argument_type(2, index, "number")
        mixin_helper.assert_argument_type(3, str, "string", "number", "FCString")
        if index < 0 then
            index = 0
        elseif index >= mixin.FCMCtrlPopup.GetCount(self) then
            mixin.FCMCtrlPopup.AddString(self, str)
            return
        end
        table.insert(private[self].Items, index + 1, type(str) == "userdata" and str.LuaString or tostring(str))
        local current_selection = mixin.FCMCtrlPopup.GetSelectedItem(self)
        if not mixin.FCMControl.UseStoredState(self) then
            self:SetStrings_(mixin.FCMStrings():CopyFromStringTable(private[self].Items))
        end
        local new_selection = current_selection + (index <= current_selection and 1 or 0)
        mixin.FCMCtrlPopup.SetSelectedItem(self, new_selection)
        for v in each_last_selection_change(self) do
            if v.last_item >= index then
                v.last_item = v.last_item + 1
            end
        end
    end

    function public:DeleteItem(index)
        mixin_helper.assert_argument_type(2, index, "number")
        if index < 0 or index >= mixin.FCMCtrlPopup.GetCount(self) then
            return
        end
        table.remove(private[self].Items, index + 1)
        local current_selection = mixin.FCMCtrlPopup.GetSelectedItem(self)
        if not mixin.FCMControl.UseStoredState(self) then
            self:SetStrings_(mixin.FCMStrings():CopyFromStringTable(private[self].Items))
        end
        local new_selection
        if index < current_selection then
            new_selection = current_selection - 1
        elseif index == current_selection then
            new_selection = -1
        else
            new_selection = current_selection
        end
        mixin.FCMCtrlPopup.SetSelectedItem(self, new_selection)
        for v in each_last_selection_change(self) do
            if v.last_item == index then
                v.is_deleted = true
            elseif v.last_item > index then
                v.last_item = v.last_item - 1
            end
        end

        if index == current_selection then
            trigger_selection_change(self)
        end
    end



    public.AddHandleSelectionChange, public.RemoveHandleSelectionChange, trigger_selection_change, each_last_selection_change = mixin_helper.create_custom_control_change_event(
        {
            name = "last_item",
            get = function(ctrl)
                return mixin.FCMCtrlPopup.GetSelectedItem(ctrl)
            end,
            initial = -1,
        }, {
            name = "last_item_text",
            get = function(ctrl)
                return mixin.FCMCtrlPopup.GetSelectedString(ctrl) or ""
            end,
            initial = "",
        }, {
            name = "is_deleted",
            get = function()
                return false
            end,
            initial = false,
        }
    )
    return {meta, public}
end
package.preload["mixin.FCMCtrlSlider"] = package.preload["mixin.FCMCtrlSlider"] or function()



    local mixin = require("library.mixin")
    local mixin_helper = require("library.mixin_helper")
    local meta = {}
    local public = {}
    local windows = setmetatable({}, {__mode = "k"})
    local trigger_thumb_position_change
    local each_last_thumb_position_change
    local using_timer_fix = false
    local function bootstrap_command()

        trigger_thumb_position_change(true)
    end
    local function bootstrap_timer(timerid, window)

        trigger_thumb_position_change(true, true)
    end
    local bootstrap_timer_first

    bootstrap_timer_first = function(timerid, window)
        window:RemoveHandleCommand(bootstrap_command)
        window:RemoveHandleTimer(timerid, bootstrap_timer_first)
        window:AddHandleTimer(timerid, bootstrap_timer)
        bootstrap_timer(timerid, window)
    end

    function public:RegisterParent(window)
        mixin.FCMControl.RegisterParent(self, window)
        if finenv.MajorVersion == 0 and finenv.MinorVersion < 64 and not windows[window] and mixin_helper.is_instance_of(window, "FCMCustomLuaWindow") then

            window:AddHandleCommand(bootstrap_command)
            if window.SetTimer_ then

                window:AddHandleTimer(window:SetNextTimer(1000), bootstrap_timer_first)
            end
            windows[window] = true
        end
    end

    function public:SetThumbPosition(position)
        mixin_helper.assert_argument_type(2, position, "number")
        self:SetThumbPosition_(position)
        trigger_thumb_position_change(self)
    end

    function public:SetMinValue(minvalue)
        mixin_helper.assert_argument_type(2, minvalue, "number")
        self:SetMinValue_(minvalue)
        trigger_thumb_position_change(self)
    end

    function public:SetMaxValue(maxvalue)
        mixin_helper.assert_argument_type(2, maxvalue, "number")
        self:SetMaxValue_(maxvalue)
        trigger_thumb_position_change(self)
    end



    public.AddHandleThumbPositionChange, public.RemoveHandleThumbPositionChange, trigger_thumb_position_change, each_last_thumb_position_change = mixin_helper.create_custom_control_change_event(
        {
            name = "last_position",
            get = "GetThumbPosition_",
            initial = -1,
        }
    )
    return {meta, public}
end
package.preload["mixin.FCMCtrlStatic"] = package.preload["mixin.FCMCtrlStatic"] or function()



    local mixin = require("library.mixin")
    local mixin_helper = require("library.mixin_helper")
    local utils = require("library.utils")
    local meta = {}
    local public = {}
    local private = setmetatable({}, {__mode = "k"})
    local temp_str = finale.FCString()

    function meta:Init()
        if private[self] then
            return
        end
        private[self] = {}
    end

    function public:SetTextColor(red, green, blue)
        mixin_helper.assert_argument_type(2, red, "number")
        mixin_helper.assert_argument_type(3, green, "number")
        mixin_helper.assert_argument_type(4, blue, "number")
        private[self].TextColor = {red, green, blue}
        if not mixin.FCMControl.UseStoredState(self) then
            self:SetTextColor_(red, green, blue)


            mixin.FCMControl.SetText(self, mixin.FCMControl.GetText(self))
        end
    end

    function public:RestoreState()
        mixin.FCMControl.RestoreState(self)

        if private[self].TextColor then
            mixin.FCMCtrlStatic.SetTextColor(self, private[self].TextColor[1], private[self].TextColor[2], private[self].TextColor[3])
        end
    end
    return {meta, public}
end
package.preload["mixin.FCMCtrlSwitcher"] = package.preload["mixin.FCMCtrlSwitcher"] or function()



    local mixin = require("library.mixin")
    local mixin_helper = require("library.mixin_helper")
    local meta = {}
    local public = {}
    local private = setmetatable({}, {__mode = "k"})
    local trigger_page_change
    local each_last_page_change
    local temp_str = finale.FCString()

    function meta:Init()
        if private[self] then
            return
        end
        private[self] = {
            Index = {},
            TitleIndex = {},
        }
    end

    function public:AddPage(title)
        mixin_helper.assert_argument_type(2, title, "string", "number", "FCString")
        title = mixin_helper.to_fcstring(title, temp_str)
        self:AddPage_(title)
        table.insert(private[self].Index, title.LuaString)
        private[self].TitleIndex[title.LuaString] = #private[self].Index - 1
    end

    function public:AddPages(...)
        for i = 1, select("#", ...) do
            local v = select(i, ...)
            mixin_helper.assert_argument_type(i + 1, v, "string", "number", "FCString")
            mixin.FCMCtrlSwitcher.AddPage(self, v)
        end
    end

    function public:AttachControl(control, pageindex)
        mixin_helper.assert_argument_type(2, control, "FCControl", "FCMControl")
        mixin_helper.assert_argument_type(3, pageindex, "number")
        mixin_helper.boolean_to_error(self, "AttachControl", control, pageindex)
    end

    function public:AttachControlByTitle(control, title)
        mixin_helper.assert_argument_type(2, control, "FCControl", "FCMControl")
        mixin_helper.assert_argument_type(3, title, "string", "number", "FCString")
        title = type(title) == "userdata" and title.LuaString or tostring(title)
        local index = private[self].TitleIndex[title] or -1
        mixin_helper.force_assert(index ~= -1, "No page titled '" .. title .. "'")
        mixin.FCMCtrlSwitcher.AttachControl(self, control, index)
    end

    function public:SetSelectedPage(index)
        mixin_helper.assert_argument_type(2, index, "number")
        self:SetSelectedPage_(index)
        trigger_page_change(self)
    end

    function public:SetSelectedPageByTitle(title)
        mixin_helper.assert_argument_type(2, title, "string", "number", "FCString")
        title = type(title) == "userdata" and title.LuaString or tostring(title)
        local index = private[self].TitleIndex[title] or -1
        mixin_helper.force_assert(index ~= -1, "No page titled '" .. title .. "'", 2)
        mixin.FCMCtrlSwitcher.SetSelectedPage(self, index)
    end

    function public:GetSelectedPageTitle(title)
        mixin_helper.assert_argument_type(2, title, "nil", "FCString")
        local index = self:GetSelectedPage_()
        if index == -1 then
            if title then
                title.LuaString = ""
            else
                return nil
            end
        else
            return mixin.FCMCtrlSwitcher.GetPageTitle(self, index, title)
        end
    end

    function public:GetPageTitle(index, str)
        mixin_helper.assert_argument_type(2, index, "number")
        mixin_helper.assert_argument_type(3, str, "nil", "FCString")
        local text = private[self].Index[index + 1]
        mixin_helper.force_assert(text, "No page at index " .. tostring(index))
        if str then
            str.LuaString = text
        else
            return text
        end
    end



    public.AddHandlePageChange, public.RemoveHandlePageChange, trigger_page_change, each_last_page_change = mixin_helper.create_custom_control_change_event(
        {
            name = "last_page",
            get = "GetSelectedPage_",
            initial = -1
        },
        {
            name = "last_page_title",

            get = function(ctrl)
                return mixin.FCMCtrlSwitcher.GetSelectedPageTitle(ctrl)
            end,
            initial = "",
        }
    )
    return {meta, public}
end
package.preload["mixin.FCMCtrlTree"] = package.preload["mixin.FCMCtrlTree"] or function()



    local mixin = require("library.mixin")
    local mixin_helper = require("library.mixin_helper")
    local meta = {}
    local props = {}
    local temp_str = finale.FCString()

    function public:AddNode(parentnode, iscontainer, text)
        mixin_helper.assert_argument_type(2, parentnode, "nil", "FCTreeNode")
        mixin_helper.assert_argument_type(3, iscontainer, "boolean")
        mixin_helper.assert_argument_type(4, text, "string", "number", "FCString")
        return self:AddNode_(parentnode, iscontainer, mixin_helper.to_fcstring(text, temp_str))
    end
    return {meta, public}
end
package.preload["mixin.FCMCtrlUpDown"] = package.preload["mixin.FCMCtrlUpDown"] or function()



    local mixin = require("library.mixin")
    local mixin_helper = require("library.mixin_helper")
    local private = setmetatable({}, {__mode = "k"})
    local props = {}

    function props:Init()
        private[self] = private[self] or {}
    end

    function props:GetConnectedEdit()
        return private[self].ConnectedEdit
    end

    function props:ConnectIntegerEdit(control, minvalue, maxvalue)
        mixin_helper.assert_argument_type(2, control, "FCMCtrlEdit")
        mixin_helper.assert_argument_type(3, minvalue, "number")
        mixin_helper.assert_argument_type(4, maxvalue, "number")
        local ret = self:ConnectIntegerEdit_(control, minvalue, maxvalue)
        if ret then
            private[self].ConnectedEdit = control
        end
        return ret
    end

    function props:ConnectMeasurementEdit(control, minvalue, maxvalue)
        mixin_helper.assert_argument_type(2, control, "FCMCtrlEdit")
        mixin_helper.assert_argument_type(3, minvalue, "number")
        mixin_helper.assert_argument_type(4, maxvalue, "number")
        local ret = self:ConnectMeasurementEdit_(control, minvalue, maxvalue)
        if ret then
            private[self].ConnectedEdit = control
        end
        return ret
    end


    props.AddHandlePress, props.RemoveHandlePress = mixin_helper.create_standard_control_event("HandleUpDownPressed")
    return props
end
package.preload["mixin.FCMCustomLuaWindow"] = package.preload["mixin.FCMCustomLuaWindow"] or function()



    local mixin = require("library.mixin")
    local mixin_helper = require("library.mixin_helper")
    local utils = require("library.utils")
    local measurement = require("library.measurement")
    local private = setmetatable({}, {__mode = "k"})
    local props = {}
    local trigger_measurement_unit_change
    local each_last_measurement_unit_change

    local window_events = {"HandleCancelButtonPressed", "HandleOkButtonPressed", "InitWindow", "CloseWindow"}
    local control_events = {"HandleCommand", "HandleDataListCheck", "HandleDataListSelect", "HandleUpDownPressed"}
    local function flush_custom_queue(self)
        local queue = private[self].HandleCustomQueue
        private[self].HandleCustomQueue = {}
        for _, callback in ipairs(queue) do
            callback()
        end
    end
    local function restore_position(self)
        if private[self].HasBeenShown and private[self].EnableAutoRestorePosition and self.StorePosition then
            self:StorePosition(false)
            self:SetRestorePositionOnlyData_(private[self].StoredX, private[self].StoredY)
            self:RestorePosition()
        end
    end

    local function dispatch_event_handlers(self, event, context, ...)
        local handlers = private[self][event]
        if handlers.Registered then
            handlers.Registered(context, ...)
        end
        for _, handler in ipairs(handlers.Added) do
            handler(context, ...)
        end
    end
    local function create_handle_methods(event)

        props["Register" .. event] = function(self, callback)
            mixin_helper.assert_argument_type(2, callback, "function")
            private[self][event].Registered = callback
        end
        props["Add" .. event] = function(self, callback)
            mixin_helper.assert_argument_type(2, callback, "function")
            table.insert(private[self][event].Added, callback)
        end
        props["Remove" .. event] = function(self, callback)
            mixin_helper.assert_argument_type(2, callback, "function")
            utils.table_remove_first(private[self][event].Added, callback)
        end
    end

    function props:Init()
        private[self] = private[self] or {
            HandleTimer = {},
            HandleCustomQueue = {},
            HasBeenShown = false,
            EnableDebugClose = false,
            RestoreControlState = true,
            EnableAutoRestorePosition = true,
            StoredX = nil,
            StoredY = nil,
            MeasurementUnit = measurement.get_real_default_unit(),
            UseParentMeasurementUnit = true,
        }

        for _, event in ipairs(control_events) do
            private[self][event] = {Added = {}}
            if self["Register" .. event .. "_"] then

                local is_running = false
                self["Register" .. event .. "_"](self, function(control, ...)
                    if is_running then
                        return
                    end
                    is_running = true

                    flush_custom_queue(self)

                    local real_control = self:FindControl(control:GetControlID())
                    if not real_control then
                        error("Control with ID #" .. tostring(control:GetControlID()) .. " not found in '" .. event .. "'")
                    end
                    dispatch_event_handlers(self, event, real_control, ...)

                    while #private[self].HandleCustomQueue > 0 do
                        flush_custom_queue(self)
                    end
                    is_running = false
                end)
            end
        end

        for _, event in ipairs(window_events) do
            private[self][event] = {Added = {}}
            if not self["Register" .. event .. "_"] then
                goto continue
            end
            if event == "InitWindow" then
                self["Register" .. event .. "_"](self, function(...)
                    if private[self].HasBeenShown and private[self].RestoreControlState then
                        for control in each(self) do
                            control:RestoreState()
                        end
                    end
                    dispatch_event_handlers(self, event, self, ...)
                end)
            elseif event == "CloseWindow" then
                self["Register" .. event .. "_"](self, function(...)
                    if private[self].EnableDebugClose and finenv.RetainLuaState ~= nil then
                        if finenv.DebugEnabled and (self:QueryLastCommandModifierKeys(finale.CMDMODKEY_ALT) or self:QueryLastCommandModifierKeys(finale.CMDMODKEY_SHIFT)) then
                            finenv.RetainLuaState = false
                        end
                    end

                    local success, error_msg = pcall(dispatch_event_handlers, self, event, self, ...)
                    if self.StorePosition then
                        self:StorePosition(false)
                        private[self].StoredX = self.StoredX
                        private[self].StoredY = self.StoredY
                    end
                    if private[self].RestoreControlState then
                        for control in each(self) do
                            control:StoreState()
                        end
                    end
                    private[self].HasBeenShown = true
                    if not success then
                        error(error_msg, 0)
                    end
                end)
            else
                self["Register" .. event .. "_"](self, function(...)
                    dispatch_event_handlers(self, event, self, ...)
                end)
            end
            :: continue ::
        end

        if self.RegisterHandleTimer_ then
            self:RegisterHandleTimer_(function(timerid)

                if private[self].HandleTimer.Registered then

                    private[self].HandleTimer.Registered(self, timerid)
                end

                if private[self].HandleTimer[timerid] then
                    for _, callback in ipairs(private[self].HandleTimer[timerid]) do

                        callback(self, timerid)
                    end
                end
            end)
        end
    end












    for _, event in ipairs(control_events) do
        create_handle_methods(event)
    end
















    for _, event in ipairs(window_events) do
        create_handle_methods(event)
    end

    function props:QueueHandleCustom(callback)
        mixin_helper.assert_argument_type(2, callback, "function")
        table.insert(private[self].HandleCustomQueue, callback)
    end
    if finenv.MajorVersion > 0 or finenv.MinorVersion >= 56 then

        function props:RegisterHandleControlEvent(control, callback)
            mixin_helper.assert_argument_type(2, control, "FCControl", "FCMControl")
            mixin_helper.assert_argument_type(3, callback, "function")
            if not self:RegisterHandleControlEvent_(control, function(ctrl)
                callback(self:FindControl(ctrl:GetControlID()))
            end) then
                error("'FCMCustomLuaWindow.RegisterHandleControlEvent' has encountered an error.", 2)
            end
        end
    end
    if finenv.MajorVersion > 0 or finenv.MinorVersion >= 56 then


        function props:RegisterHandleTimer(callback)
            mixin_helper.assert_argument_type(2, callback, "function")
            private[self].HandleTimer.Registered = callback
        end

        function props:AddHandleTimer(timerid, callback)
            mixin_helper.assert_argument_type(2, timerid, "number")
            mixin_helper.assert_argument_type(3, callback, "function")
            private[self].HandleTimer[timerid] = private[self].HandleTimer[timerid] or {}
            table.insert(private[self].HandleTimer[timerid], callback)
        end

        function props:RemoveHandleTimer(timerid, callback)
            mixin_helper.assert_argument_type(2, timerid, "number")
            mixin_helper.assert_argument_type(3, callback, "function")
            if not private[self].HandleTimer[timerid] then
                return
            end
            utils.table_remove_first(private[self].HandleTimer[timerid], callback)
        end

        function props:SetTimer(timerid, msinterval)
            mixin_helper.assert_argument_type(2, timerid, "number")
            mixin_helper.assert_argument_type(3, msinterval, "number")
            self:SetTimer_(timerid, msinterval)
            private[self].HandleTimer[timerid] = private[self].HandleTimer[timerid] or {}
        end

        function props:GetNextTimerID()
            while private[self].HandleTimer[private[self].NextTimerID] do
                private[self].NextTimerID = private[self].NextTimerID + 1
            end
            return private[self].NextTimerID
        end

        function props:SetNextTimer(msinterval)
            mixin_helper.assert_argument_type(2, msinterval, "number")
            local timerid = mixin.FCMCustomLuaWindow.GetNextTimerID(self)
            mixin.FCMCustomLuaWindow.SetTimer(self, timerid, msinterval)
            return timerid
        end
    end
    if finenv.MajorVersion > 0 or finenv.MinorVersion >= 60 then

        function props:SetEnableAutoRestorePosition(enabled)
            mixin_helper.assert_argument_type(2, enabled, "boolean")
            private[self].EnableAutoRestorePosition = enabled
        end

        function props:GetEnableAutoRestorePosition()
            return private[self].EnableAutoRestorePosition
        end

        function props:SetRestorePositionData(x, y, width, height)
            mixin_helper.assert_argument_type(2, x, "number")
            mixin_helper.assert_argument_type(3, y, "number")
            mixin_helper.assert_argument_type(4, width, "number")
            mixin_helper.assert_argument_type(5, height, "number")
            self:SetRestorePositionOnlyData_(x, y, width, height)
            if private[self].HasBeenShown and not self:WindowExists() then
                private[self].StoredX = x
                private[self].StoredY = y
            end
        end

        function props:SetRestorePositionOnlyData(x, y)
            mixin_helper.assert_argument_type(2, x, "number")
            mixin_helper.assert_argument_type(3, y, "number")
            self:SetRestorePositionOnlyData_(x, y)
            if private[self].HasBeenShown and not self:WindowExists() then
                private[self].StoredX = x
                private[self].StoredY = y
            end
        end
    end

    function props:SetEnableDebugClose(enabled)
        mixin_helper.assert_argument_type(2, enabled, "boolean")
        private[self].EnableDebugClose = enabled and true or false
    end

    function props:GetEnableDebugClose()
        return private[self].EnableDebugClose
    end

    function props:SetRestoreControlState(enabled)
        mixin_helper.assert_argument_type(2, enabled, "boolean")
        private[self].RestoreControlState = enabled and true or false
    end

    function props:GetRestoreControlState()
        return private[self].RestoreControlState
    end

    function props:HasBeenShown()
        return private[self].HasBeenShown
    end

    function props:ExecuteModal(parent)
        if mixin_helper.is_instance_of(parent, "FCMCustomLuaWindow") and private[self].UseParentMeasurementUnit then
            self:SetMeasurementUnit(parent:GetMeasurementUnit())
        end
        restore_position(self)
        return mixin.FCMCustomWindow.ExecuteModal(self, parent)
    end

    function props:ShowModeless()
        finenv.RegisterModelessDialog(self)
        restore_position(self)
        return self:ShowModeless_()
    end

    function props:RunModeless(selection_not_required, default_action_override)
        local modifier_keys_on_invoke = finenv.QueryInvokedModifierKeys and (finenv.QueryInvokedModifierKeys(finale.CMDMODKEY_ALT) or finenv.QueryInvokedModifierKeys(finale.CMDMODKEY_SHIFT))
        local default_action = default_action_override == nil and private[self].HandleOkButtonPressed.Registered or default_action_override
        if modifier_keys_on_invoke and self:HasBeenShown() and default_action then
            default_action(self)
            return
        end
        if finenv.IsRGPLua then

            if self.OkButtonCanClose then
                self.OkButtonCanClose = modifier_keys_on_invoke
            end
            if self:ShowModeless() then
                finenv.RetainLuaState = true
            end
        else
            if not selection_not_required and finenv.Region():IsEmpty() then
                finenv.UI():AlertInfo("Please select a music region before running this script.", "Selection Required")
                return
            end
            self:ExecuteModal(nil)
        end
    end

    function props:GetMeasurementUnit()
        return private[self].MeasurementUnit
    end

    function props:SetMeasurementUnit(unit)
        mixin_helper.assert_argument_type(2, unit, "number")
        if unit == private[self].MeasurementUnit then
            return
        end
        if unit == finale.MEASUREMENTUNIT_DEFAULT then
            unit = measurement.get_real_default_unit()
        end
        mixin_helper.force_assert(measurement.is_valid_unit(unit), "Measurement unit is not valid.")
        private[self].MeasurementUnit = unit

        for ctrl in each(self) do
            local func = ctrl.UpdateMeasurementUnit
            if func then
                func(ctrl)
            end
        end
        trigger_measurement_unit_change(self)
    end

    function props:GetMeasurementUnitName()
        return measurement.get_unit_name(private[self].MeasurementUnit)
    end

    function props:GetUseParentMeasurementUnit(enabled)
        return private[self].UseParentMeasurementUnit
    end

    function props:SetUseParentMeasurementUnit(enabled)
        mixin_helper.assert_argument_type(2, enabled, "boolean")
        private[self].UseParentMeasurementUnit = enabled and true or false
    end



    props.AddHandleMeasurementUnitChange, props.RemoveHandleMeasurementUnitChange, trigger_measurement_unit_change, each_last_measurement_unit_change = mixin_helper.create_custom_window_change_event(
        {
            name = "last_unit",
            get = function(window)
                return mixin.FCMCustomLuaWindow.GetMeasurementUnit(window)
            end,
            initial = measurement.get_real_default_unit(),
        }
    )

    function props:CreateMeasurementEdit(x, y, control_name)
        mixin_helper.assert_argument_type(2, x, "number")
        mixin_helper.assert_argument_type(3, y, "number")
        mixin_helper.assert_argument_type(4, control_name, "string", "nil")
        local edit = mixin.FCMCustomWindow.CreateEdit(self, x, y, control_name)
        return mixin.subclass(edit, "FCXCtrlMeasurementEdit")
    end

    function props:CreateMeasurementUnitPopup(x, y, control_name)
        mixin_helper.assert_argument_type(2, x, "number")
        mixin_helper.assert_argument_type(3, y, "number")
        mixin_helper.assert_argument_type(4, control_name, "string", "nil")
        local popup = mixin.FCMCustomWindow.CreatePopup(self, x, y, control_name)
        return mixin.subclass(popup, "FCXCtrlMeasurementUnitPopup")
    end

    function props:CreatePageSizePopup(x, y, control_name)
        mixin_helper.assert_argument_type(2, x, "number")
        mixin_helper.assert_argument_type(3, y, "number")
        mixin_helper.assert_argument_type(4, control_name, "string", "nil")
        local popup = mixin.FCMCustomWindow.CreatePopup(self, x, y, control_name)
        return mixin.subclass(popup, "FCXCtrlPageSizePopup")
    end
    return props
end
package.preload["mixin.FCMCustomWindow"] = package.preload["mixin.FCMCustomWindow"] or function()



    local mixin = require("library.mixin")
    local mixin_helper = require("library.mixin_helper")
    local meta = {}
    local public = {}
    local private = setmetatable({}, {__mode = "k"})
    local function create_control(self, func, num_args, ...)
        local control = self["Create" .. func .. "_"](self, ...)
        private[self].Controls[control:GetControlID()] = control
        control:RegisterParent(self)
        local control_name = select(num_args + 1, ...)
        if control_name then
            control_name = type(control_name) == "userdata" and control_name.LuaString or control_name
            if private[self].NamedControls[control_name] then
                error("A control is already registered with the name '" .. control_name .. "'", 2)
            end
            private[self].NamedControls[control_name] = control
        end
        return control
    end

    function meta:Init()
        if private[self] then
            return
        end
        private[self] = {
            Controls = {},
            NamedControls = {},
        }
    end


















    for num_args, ctrl_types in pairs({
        [0] = {"CancelButton", "OpenButton",},
        [2] = {"Button", "Checkbox", "CloseButton", "DataList", "Edit",
            "ListBox", "Popup", "Slider", "Static", "Switcher", "Tree", "UpDown",
        },
        [3] = {"HorizontalLine", "VerticalLine",},
    }) do
        for _, control_type in pairs(ctrl_types) do
            if not finale.FCCustomWindow.__class["Create" .. control_type] then
                goto continue
            end
            public["Create" .. control_type] = function(self, ...)
                for i = 1, num_args do
                    mixin_helper.assert_argument_type(i + 1, select(i, ...), "number")
                end
                mixin_helper.assert_argument_type(num_args + 2, select(num_args + 1, ...), "string", "nil", "FCString")
                return create_control(self, control_type, num_args, ...)
            end
            :: continue ::
        end
    end

    function public:FindControl(control_id)
        mixin_helper.assert_argument_type(2, control_id, "number")
        return private[self].Controls[control_id]
    end

    function public:GetControl(control_name)
        mixin_helper.assert_argument_type(2, control_name, "string", "FCString")
        return private[self].NamedControls[control_name]
    end

    function public:Each(class_filter)
        local i = -1
        local v
        local iterator = function()
            repeat
                i = i + 1
                v = mixin.FCMCustomWindow.GetItemAt(self, i)
            until not v or not class_filter or mixin_helper.is_instance_of(v, class_filter)
            return v
        end
        return iterator
    end

    function public:GetItemAt(index)
        local item = self:GetItemAt_(index)
        return item and private[self].Controls[item:GetControlID()] or item
    end

    function public:GetParent()
        return private[self].Parent
    end

    function public:ExecuteModal(parent)
        private[self].Parent = parent
        local ret = self:ExecuteModal_(parent)
        private[self].Parent = nil
        return ret
    end
    return {meta, public}
end
package.preload["mixin.FCMNoteEntry"] = package.preload["mixin.FCMNoteEntry"] or function()



    local mixin = require("library.mixin")
    local mixin_helper = require("library.mixin_helper")
    local meta = {}
    local public = {}
    local private = setmetatable({}, {__mode = "k"})

    function meta:Init()
        if private[self] then
            return
        end
        private[self] = {}
    end

    function public:RegisterParent(parent)
        mixin_helper.assert_argument_type(2, parent, "FCNoteEntryCell")
        if not private[self].Parent then
            private[self].Parent = parent
        end
    end

    function public:GetParent()
        return private[self].Parent
    end
    return {meta, public}
end
package.preload["mixin.FCMNoteEntryCell"] = package.preload["mixin.FCMNoteEntryCell"] or function()



    local mixin = require("library.mixin")
    local mixin_helper = require("library.mixin_helper")
    local meta = {}
    local public = {}

    function public:GetItemAt(index)
        mixin_helper.assert_argument_type(2, index, "number")
        local item = self:GetItemAt_(index)
        if item then
            item:RegisterParent(self)
        end
        return item
    end
    return {meta, public}
end
package.preload["mixin.FCMPage"] = package.preload["mixin.FCMPage"] or function()



    local mixin = require("library.mixin")
    local mixin_helper = require("library.mixin_helper")
    local page_size = require("library.page_size")
    local props = {}

    function props:GetSize()
        return page_size.get_page_size(self)
    end

    function props:SetSize(size)
        mixin_helper.assert_argument_type(2, size, "string")
        mixin_helper.assert(page_size.is_size(size), "'" .. size .. "' is not a valid page size.")
        page_size.set_page_size(self, size)
    end

    function props:IsBlank()
        return self:GetFirstSystem() == -1
    end
    return props
end
package.preload["mixin.FCMString"] = package.preload["mixin.FCMString"] or function()



    local mixin = require("library.mixin")
    local mixin_helper = require("library.mixin_helper")
    local utils = require("library.utils")
    local measurement = require("library.measurement")
    local meta = {}
    local public = {}

    local unit_overrides = {
        {unit = finale.MEASUREMENTUNIT_EVPUS, overrides = {"EVPUS", "evpus", "e"}},
        {unit = finale.MEASUREMENTUNIT_INCHES, overrides = {"inches", "in", "i", "”"}},
        {unit = finale.MEASUREMENTUNIT_CENTIMETERS, overrides = {"centimeters", "cm", "c"}},

        {unit = finale.MEASUREMENTUNIT_POINTS, overrides = {"points", "pts", "pt"}},
        {unit = finale.MEASUREMENTUNIT_PICAS, overrides = {"picas", "p"}},
        {unit = finale.MEASUREMENTUNIT_SPACES, overrides = {"spaces", "sp", "s"}},
        {unit = finale.MEASUREMENTUNIT_MILLIMETERS, overrides = {"millimeters", "mm", "m"}},
    }
    function split_string_start(str, pattern)
        return string.match(str, "^(" .. pattern .. ")(.*)")
    end
    local function split_number(str, allow_negative)
        return split_string_start(str, (allow_negative and "%-?" or "") .. "%d+%.?%d*")
    end
    local function calculate_picas(whole, fractional)
        fractional = fractional or 0
        return tonumber(whole) * 48 + tonumber(fractional) * 4
    end

    function public:GetMeasurement(measurementunit)
        mixin_helper.assert_argument_type(2, measurementunit, "number")

        local value = string.gsub(self.LuaString, "%" .. mixin.UI():GetDecimalSeparator(), '.')
        local start_number, remainder = split_number(value, true)
        if not start_number then
            return 0
        end
        if remainder then

            remainder = utils.ltrim(remainder)
            if remainder == "" then
                goto continue
            end
            for _, unit in ipairs(unit_overrides) do
                for _, override in ipairs(unit.overrides) do
                    local a, b = split_string_start(remainder, override)
                    if a then
                        measurementunit = unit.unit
                        if measurementunit == finale.MEASUREMENTUNIT_PICAS then
                            return calculate_picas(start_number, split_number(utils.ltrim(b)))
                        end
                        goto continue
                    end
                end
            end
            :: continue ::
        end
        if measurementunit == finale.MEASUREMENTUNIT_DEFAULT then
            measurementunit = measurement.get_real_default_unit()
        end
        start_number = tonumber(start_number)
        if measurementunit == finale.MEASUREMENTUNIT_EVPUS then
            return start_number
        elseif measurementunit == finale.MEASUREMENTUNIT_INCHES then
            return start_number * 288
        elseif measurementunit == finale.MEASUREMENTUNIT_CENTIMETERS then
            return start_number * 288 / 2.54
        elseif measurementunit == finale.MEASUREMENTUNIT_POINTS then
            return start_number * 4
        elseif measurementunit == finale.MEASUREMENTUNIT_PICAS then
            return start_number * 48
        elseif measurementunit == finale.MEASUREMENTUNIT_SPACES then
            return start_number * 24
        elseif measurementunit == finale.MEASUREMENTUNIT_MILLIMETERS then
            return start_number * 288 / 25.4
        end

        return 0
    end

    function public:GetRangeMeasurement(measurementunit, minimum, maximum)
        mixin_helper.assert_argument_type(2, measurementunit, "number")
        mixin_helper.assert_argument_type(3, minimum, "number")
        mixin_helper.assert_argument_type(4, maximum, "number")
        return utils.clamp(mixin.FCMString.GetMeasurement(measurementunit), minimum, maximum)
    end

    function public:SetMeasurement(value, measurementunit)
        mixin_helper.assert_argument_type(2, value, "number")
        mixin_helper.assert_argument_type(3, measurementunit, "number")
        if measurementunit == finale.MEASUREMENTUNIT_PICAS then
            local whole = math.floor(value / 48)
            local fractional = value - whole * 48
            fractional = fractional < 0 and fractional * -1 or fractional
            self.LuaString = whole .. "p" .. utils.round(fractional / 4, 4)
            return
        end

        if measurementunit == finale.MEASUREMENTUNIT_INCHES then
            value = value / 288
        elseif measurementunit == finale.MEASUREMENTUNIT_CENTIMETERS then
            value = value / 288 * 2.54
        elseif measurementunit == finale.MEASUREMENTUNIT_POINTS then
            value = value / 4
        elseif measurementunit == finale.MEASUREMENTUNIT_SPACES then
            value = value / 24
        elseif measurementunit == finale.MEASUREMENTUNIT_MILLIMETERS then
            value = value / 288 * 25.4
        end
        self.LuaString = tostring(utils.round(value, 5))
    end

    function public:GetMeasurementInteger(measurementunit)
        mixin_helper.assert_argument_type(2, measurementunit, "number")
        return utils.round(mixin.FCMString.GetMeasurement(self, measurementunit))
    end

    function public:GetRangeMeasurementInteger(measurementunit, minimum, maximum)
        mixin_helper.assert_argument_type(2, measurementunit, "number")
        mixin_helper.assert_argument_type(3, minimum, "number")
        mixin_helper.assert_argument_type(4, maximum, "number")
        return utils.clamp(mixin.FCMString.GetMeasurementInteger(measurementunit), math.ceil(minimum), math.floor(maximum))
    end

    function public:SetMeasurementInteger(value, measurementunit)
        mixin_helper.assert_argument_type(2, value, "number")
        mixin_helper.assert_argument_type(3, measurementunit, "number")
        mixin.FCMString.SetMeasurement(self, utils.round(value), measurementunit)
    end

    function public:GetMeasurementEfix(measurementunit)
        mixin_helper.assert_argument_type(2, measurementunit, "number")
        return utils.round(mixin.FCMString.GetMeasurement(self, measurementunit) * 64)
    end

    function public:GetRangeMeasurementEfix(measurementunit, minimum, maximum)
        mixin_helper.assert_argument_type(2, measurementunit, "number")
        mixin_helper.assert_argument_type(3, minimum, "number")
        mixin_helper.assert_argument_type(4, maximum, "number")
        return utils.clamp(mixin.FCMString.GetMeasurementEfix(measurementunit), math.ceil(minimum), math.floor(maximum))
    end

    function public:SetMeasurementEfix(value, measurementunit)
        mixin_helper.assert_argument_type(2, value, "number")
        mixin_helper.assert_argument_type(3, measurementunit, "number")
        mixin.FCMString.SetMeasurement(self, utils.round(value) / 64, measurementunit)
    end

    function public:GetMeasurement10000th(measurementunit)
        mixin_helper.assert_argument_type(2, measurementunit, "number")
        return utils.round(mixin.FCMString.GetMeasurement(self, measurementunit) * 10000)
    end

    function public:GetRangeMeasurement10000th(measurementunit, minimum, maximum)
        mixin_helper.assert_argument_type(2, measurementunit, "number")
        mixin_helper.assert_argument_type(3, minimum, "number")
        mixin_helper.assert_argument_type(4, maximum, "number")
        return utils.clamp(mixin.FCMString.GetMeasurement10000th(self, measurementunit), math.ceil(minimum), math.floor(maximum))
    end

    function public:SetMeasurement10000th(value, measurementunit)
        mixin_helper.assert_argument_type(2, value, "number")
        mixin_helper.assert_argument_type(3, measurementunit, "number")
        mixin.FCMString.SetMeasurement(self, utils.round(value) / 10000, measurementunit)
    end
    return {meta, public}
end
package.preload["mixin.FCMStrings"] = package.preload["mixin.FCMStrings"] or function()



    local mixin = require("library.mixin")
    local mixin_helper = require("library.mixin_helper")
    local library = require("library.general_library")
    local meta = {}
    local public = {}
    local temp_str = finale.FCString()

    function public:AddCopy(str)
        mixin_helper.assert_argument_type(2, str, "string", "number", "FCString")
        mixin_helper.boolean_to_error(self, "AddCopy", mixin_helper.to_fcstring(str, temp_str))
    end

    function public:AddCopies(...)
        for i = 1, select("#", ...) do
            local v = select(i, ...)
            mixin_helper.assert_argument_type(i + 1, v, "FCStrings", "FCString", "string", "number")
            if mixin_helper.is_instance_of(v, "FCStrings") then
                for str in each(v) do
                    self:AddCopy_(str)
                end
            else
                mixin.FCStrings.AddCopy(self, v)
            end
        end
    end

    function public:Find(str)
        mixin_helper.assert_argument_type(2, str, "string", "number", "FCString")
        return self:Find_(mixin_helper.to_fcstring(str, temp_str))
    end

    function public:FindNocase(str)
        mixin_helper.assert_argument_type(2, str, "string", "number", "FCString")
        return self:FindNocase_(mixin_helper.to_fcstring(str, temp_str))
    end

    function public:LoadFolderFiles(folderstring)
        mixin_helper.assert_argument_type(2, folderstring, "string", "FCString")
        mixin_helper.boolean_to_error(self, "LoadFolderFiles", mixin_helper.to_fcstring(folderstring, temp_str))
    end

    function public:LoadSubfolders(folderstring)
        mixin_helper.assert_argument_type(2, folderstring, "string", "FCString")
        mixin_helper.boolean_to_error(self, "LoadSubfolders", mixin_helper.to_fcstring(folderstring, temp_str))
    end

    function public:LoadSymbolFonts()
        mixin_helper.boolean_to_error(self, "LoadSymbolFonts")
    end

    function public:LoadSystemFontNames()
        mixin_helper.boolean_to_error(self, "LoadSystemFontNames")
    end

    if finenv.MajorVersion > 0 or finenv.MinorVersion >= 59 then
        function public:InsertStringAt(str, index)
            mixin_helper.assert_argument_type(2, str, "string", "number", "FCString")
            mixin_helper.assert_argument_type(3, index, "number")
            self:InsertStringAt_(mixin_helper.to_fcstring(str, temp_str), index)
        end
    end

    function public:CopyFromStringTable(strings)
        mixin_helper.assert_argument_type(2, strings, "table")
        local suffix = self.MixinClass and "_" or ""
        if finenv.MajorVersion == 0 and finenv.MinorVersion < 64 then
            self:ClearAll()
            for _, v in pairs(strings) do
                temp_str.LuaString = tostring(v)
                self["AddCopy" .. suffix](self, temp_str)
            end
        else
            self["CopyFromStringTable" .. suffix](self, strings)
        end
    end

    function public:CreateStringTable()
        local t = {}
        for str in each(self) do
            table.insert(t, str.LuaString)
        end
        return t
    end
    return {meta, public}
end
package.preload["mixin.FCMTextExpressionDef"] = package.preload["mixin.FCMTextExpressionDef"] or function()




    local mixin = require("library.mixin")
    local mixin_helper = require("library.mixin_helper")
    local meta = {}
    local public = {}
    local private = setmetatable({}, {__mode = "k"})
    local temp_str = finale.FCString()

    function public:SaveNewTextBlock(str)
        mixin_helper.assert_argument_type(2, str, "string", "FCString")
        str = mixin_helper.to_fcstring(str, temp_str)
        mixin_helper.boolean_to_error(self, "SaveNewTextBlock", str)
    end

    function public:AssignToCategory(cat_def)
        mixin_helper.assert_argument_type(2, cat_def, "FCCategoryDef")
        mixin_helper.boolean_to_error(self, "AssignToCategory", cat_def)
    end

    function public:SetUseCategoryPos(enable)
        mixin_helper.assert_argument_type(2, enable, "boolean")
        mixin_helper.boolean_to_error(self, "SetUseCategoryPos", enable)
    end

    function public:SetUseCategoryFont(enable)
        mixin_helper.assert_argument_type(2, enable, "boolean")
        mixin_helper.boolean_to_error(self, "SetUseCategoryFont", enable)
    end

    function public:MakeRehearsalMark(str, measure)
        local do_return = false
        if type(measure) == "nil" then
            measure = str
            str = temp_str
            do_return = true
        else
            mixin_helper.assert_argument_type(2, str, "FCString")
        end
        mixin_helper.assert_argument_type(do_return and 2 or 3, measure, "number")
        mixin_helper.boolean_to_error(self, "MakeRehearsalMark", str, measure)
        if do_return then
            return str.LuaString
        end
    end

    function public:SaveTextString(str)
        mixin_helper.assert_argument_type(2, str, "string", "FCString")
        str = mixin_helper.to_fcstring(str, temp_str)
        mixin_helper.boolean_to_error(self, "SaveTextString", str)
    end

    function public:DeleteTextBlock()
        mixin_helper.boolean_to_error(self, "DeleteTextBlock")
    end

    function public:SetDescription(str)
        mixin_helper.assert_argument_type(2, str, "string", "FCString")
        str = mixin_helper.to_fcstring(str, temp_str)
        self:SetDescription_(str)
    end

    function public:GetDescription(str)
        mixin_helper.assert_argument_type(2, str, "nil", "FCString")
        local do_return = not str
        str = str or temp_str
        self:GetDescription_(str)
        if do_return then
            return str.LuaString
        end
    end

    function public:DeepSaveAs(item_num)
        mixin_helper.assert_argument_type(2, item_num, "number")
        mixin_helper.boolean_to_error(self, "DeepSaveAs", item_num)
    end

    function public:DeepDeleteData()
        mixin_helper.boolean_to_error(self, "DeepDeleteData")
    end
    return {meta, public}
end
package.preload["mixin.FCMTreeNode"] = package.preload["mixin.FCMTreeNode"] or function()



    local mixin = require("library.mixin")
    local mixin_helper = require("library.mixin_helper")
    local meta = {}
    local public = {}
    local temp_str = finale.FCString()

    function public:GetText(str)
        mixin_helper.assert_argument_type(2, str, "nil", "FCString")
        local do_return = false
        if not str then
            str = temp_str
            do_return = true
        end
        self:GetText_(str)
        if do_return then
            return str.LuaString
        end
    end

    function public:SetText(str)
        mixin_helper.assert_argument_type(2, str, "string", "number", "FCString")
        self:SetText_(mixin_helper.to_fcstring(str, temp_str))
    end
    return {meta, public}
end
package.preload["mixin.FCMUI"] = package.preload["mixin.FCMUI"] or function()



    local mixin = require("library.mixin")
    local mixin_helper = require("library.mixin_helper")
    local meta = {}
    local public = {}
    local temp_str = finale.FCString()

    function public:GetDecimalSeparator(str)
        mixin_helper.assert_argument_type(2, str, "nil", "FCString")
        local do_return = false
        if not str then
            str = temp_str
            do_return = true
        end
        self:GetDecimalSeparator_(str)
        if do_return then
            return str.LuaString
        end
    end
    return {meta, public}
end
package.preload["mixin.FCXCtrlMeasurementEdit"] = package.preload["mixin.FCXCtrlMeasurementEdit"] or function()



    local mixin = require("library.mixin")
    local mixin_helper = require("library.mixin_helper")
    local utils = require("library.utils")
    local private = setmetatable({}, {__mode = "k"})
    local props = {MixinParent = "FCMCtrlEdit"}
    local trigger_change
    local each_last_change

    local function convert_type(value, from, to)

        if from ~= "Measurement" then
            value = utils.round(value)
        end
        if from == to then
            return value
        end
        if from == "MeasurementEfix" then
            value = value / 64
        elseif from == "Measurement10000th" then
            value = value / 10000
        end
        if to == "MeasurementEfix" then
            value = value * 64
        elseif to == "Measurement10000th" then
            value = value * 10000
        end
        if to == "Measurement" then
            return value
        end
        return utils.round(value)
    end

    function props:Init()
        local parent = self:GetParent()
        mixin_helper.assert(function() return mixin_helper.is_instance_of(parent, "FCXCustomLuaWindow") end, "FCXCtrlMeasurementEdit must have a parent window that is an instance of FCXCustomLuaWindow")
        private[self] = private[self] or {
            Type = "MeasurementInteger",
            LastMeasurementUnit = parent:GetMeasurementUnit(),
            LastText = mixin.FCMCtrlEdit.GetText(self),
            Value = mixin.FCMCtrlEdit.GetMeasurementInteger(self, parent:GetMeasurementUnit()),
        }
    end



    for method, valid_types in pairs({
        Text = {"string", "number", "FCString"},
        Integer = {"number"},
        Float = {"number"},
    }) do
        props["Set" .. method] = function(self, value)
            mixin_helper.assert_argument_type(2, value, table.unpack(valid_types))
            mixin.FCMCtrlEdit["Set" .. method](self, value)
            trigger_change(self)
        end
    end

    function props:GetType()
        return private[self].Type
    end




















    for method, valid_types in pairs({
        Measurement = {"number"},
        MeasurementInteger = {"number"},
        MeasurementEfix = {"number"},
        Measurement10000th = {"number"},
    }) do
        props["Get" .. method] = function(self)
            local text = mixin.FCMCtrlEdit.GetText(self)
            if (text ~= private[self].LastText) then
                private[self].Value = mixin.FCMCtrlEdit["Get" .. private[self].Type](self, private[self].LastMeasurementUnit)
                private[self].LastText = text
            end
            return convert_type(private[self].Value, private[self].Type, method)
        end
        props["GetRange" .. method] = function(self, minimum, maximum)
            mixin_helper.assert_argument_type(2, minimum, "number")
            mixin_helper.assert_argument_type(3, maximum, "number")
            minimum = method ~= "Measurement" and math.ceil(minimum) or minimum
            maximum = method ~= "Measurement" and math.floor(maximum) or maximum
            return utils.clamp(mixin.FCXCtrlMeasurementEdit["Get" .. method](self), minimum, maximum)
        end
        props["Set" .. method] = function (self, value)
            mixin_helper.assert_argument_type(2, value, table.unpack(valid_types))
            private[self].Value = convert_type(value, method, private[self].Type)
            mixin.FCMCtrlEdit["Set" .. private[self].Type](self, private[self].Value, private[self].LastMeasurementUnit)
            private[self].LastText = mixin.FCMCtrlEdit.GetText(self)
            trigger_change(self)
        end
        props["IsType" .. method] = function(self)
            return private[self].Type == method
        end
        props["SetType" .. method] = function(self)
            private[self].Value = convert_type(private[self].Value, private[self].Type, method)
            for v in each_last_change(self) do
                v.last_value = convert_type(v.last_value, private[self].Type, method)
            end
            private[self].Type = method
        end
    end

    function props:UpdateMeasurementUnit()
        local new_unit = self:GetParent():GetMeasurementUnit()
        if private[self].LastMeasurementUnit ~= new_unit then
            local value = mixin.FCXCtrlMeasurementEdit["Get" .. private[self].Type](self)
            private[self].LastMeasurementUnit = new_unit
            mixin.FCXCtrlMeasurementEdit["Set" .. private[self].Type](self, value)
        end
    end



    props.AddHandleChange, props.RemoveHandleChange, trigger_change, each_last_change = mixin_helper.create_custom_control_change_event(
        {
            name = "last_value",
            get = function(self)
                return mixin.FCXCtrlMeasurementEdit["Get" .. private[self].Type](self)
            end,
            initial = 0,
        }
    )
    return props
end
package.preload["mixin.FCXCtrlMeasurementUnitPopup"] = package.preload["mixin.FCXCtrlMeasurementUnitPopup"] or function()



    local mixin = require("library.mixin")
    local mixin_helper = require("library.mixin_helper")
    local measurement = require("library.measurement")
    local props = {MixinParent = "FCMCtrlPopup"}
    local unit_order = {
        finale.MEASUREMENTUNIT_EVPUS, finale.MEASUREMENTUNIT_INCHES, finale.MEASUREMENTUNIT_CENTIMETERS,
        finale.MEASUREMENTUNIT_POINTS, finale.MEASUREMENTUNIT_PICAS, finale.MEASUREMENTUNIT_SPACES,
    }
    local flipped_unit_order = {}
    for k, v in ipairs(unit_order) do
        flipped_unit_order[v] = k
    end

    mixin_helper.disable_methods(
        props, "Clear", "AddString", "AddStrings", "SetStrings", "GetSelectedItem", "SetSelectedItem", "SetSelectedLast",
        "ItemExists", "InsertString", "DeleteItem", "GetItemText", "SetItemText", "AddHandleSelectionChange",
        "RemoveHandleSelectionChange")

    function props:Init()
        mixin_helper.assert(function() return mixin_helper.is_instance_of(self:GetParent(), "FCXCustomLuaWindow") end, "FCXCtrlMeasurementUnitPopup must have a parent window that is an instance of FCXCustomLuaWindow")
        for _, v in ipairs(unit_order) do
            mixin.FCMCtrlPopup.AddString(self, measurement.get_unit_name(v))
        end
        self:UpdateMeasurementUnit()
        mixin.FCMCtrlPopup.AddHandleSelectionChange(self, function(control)
            control:GetParent():SetMeasurementUnit(unit_order[mixin.FCMCtrlPopup.GetSelectedItem(control) + 1])
        end)
    end

    function props:UpdateMeasurementUnit()
        local unit = self:GetParent():GetMeasurementUnit()
        if unit == unit_order[mixin.FCMCtrlPopup.GetSelectedItem(self) + 1] then
            return
        end
        mixin.FCMCtrlPopup.SetSelectedItem(self, flipped_unit_order[unit] - 1)
    end
    return props
end
package.preload["library.page_size"] = package.preload["library.page_size"] or function()



    local page_size = {}
    local utils = require("library.utils")

    local sizes = {}

    sizes.A3 = {width = 3366, height = 4761}
    sizes.A4 = {width = 2381, height = 3368}
    sizes.A5 = {width = 1678, height = 2380}
    sizes.B4 = {width = 2920, height = 4127}
    sizes.B5 = {width = 1994, height = 2834}
    sizes.Concert = {width = 2592, height = 3456}
    sizes.Executive = {width = 2160, height = 2880}
    sizes.Folio = {width = 2448, height = 3744}
    sizes.Hymn = {width = 1656, height = 2376}
    sizes.Legal = {width = 2448, height = 4032}
    sizes.Letter = {width = 2448, height = 3168}
    sizes.Octavo = {width = 1944, height = 3024}
    sizes.Quarto = {width = 2448, height = 3110}
    sizes.Statement = {width = 1584, height = 2448}
    sizes.Tabloid = {width = 3168, height = 4896}


    function page_size.get_dimensions(size)
        return utils.copy_table(sizes[size])
    end

    function page_size.is_size(size)
        return sizes[size] and true or false
    end

    function page_size.get_size(width, height)

        if height < width then
            local temp = height
            height = width
            width = temp
        end
        for size, dimensions in pairs(sizes) do
            if dimensions.width == width and dimensions.height == height then
                return size
            end
        end
        return nil
    end

    function page_size.get_page_size(page)
        return page_size.get_size(page.Width, page.Height)
    end

    function page_size.set_page_size(page, size)
        if not sizes[size] then
            return
        end
        if page:IsPortrait() then
            page:SetWidth(sizes[size].width)
            page:SetHeight(sizes[size].height)
        else
            page:SetWidth(sizes[size].height)
            page:SetHeight(sizes[size].width)
        end
    end

    local sizes_index
    function page_size.pairs()
        if not sizes_index then
            sizes_index = {}
            for size in pairs(sizes) do
                table.insert(sizes_index, size)
            end
            table.sort(sizes_index)
        end
        local i = 0
        local iterator = function()
            i = i + 1
            if sizes_index[i] == nil then
                return nil
            else
                return sizes_index[i], sizes[sizes_index[i]]
            end
        end
        return iterator
    end
    return page_size
end
package.preload["mixin.FCXCtrlPageSizePopup"] = package.preload["mixin.FCXCtrlPageSizePopup"] or function()



    local mixin = require("library.mixin")
    local mixin_helper = require("library.mixin_helper")
    local measurement = require("library.measurement")
    local page_size = require("library.page_size")
    local private = setmetatable({}, {__mode = "k"})
    local props = {MixinParent = "FCMCtrlPopup"}
    local trigger_page_size_change
    local each_last_page_size_change
    local temp_str = finale.FCString()

    mixin_helper.disable_methods(props, "Clear", "AddString", "AddStrings", "SetStrings", "GetSelectedItem", "SetSelectedItem", "SetSelectedLast",
        "ItemExists", "InsertString", "DeleteItem", "GetItemText", "SetItemText", "AddHandleSelectionChange", "RemoveHandleSelectionChange")
    local function repopulate(control)
        local unit = mixin_helper.is_instance_of(control:GetParent(), "FCXCustomLuaWindow") and control:GetParent():GetMeasurementUnit() or measurement.get_real_default_unit()
        if private[control].LastUnit == unit then
            return
        end
        local suffix = measurement.get_unit_abbreviation(unit)
        local selection = mixin.FCMCtrlPopup.GetSelectedItem(control)

        mixin.FCMCtrlPopup.Clear(control)
        for size, dimensions in page_size.pairs() do
            local str = size .. " ("
            temp_str:SetMeasurement(dimensions.width, unit)
            str = str .. temp_str.LuaString .. suffix .. " x "
            temp_str:SetMeasurement(dimensions.height, unit)
            str = str .. temp_str.LuaString .. suffix .. ")"
            mixin.FCMCtrlPopup.AddString(control, str)
        end
        mixin.FCMCtrlPopup.SetSelectedItem(control, selection)
        private[control].LastUnit = unit
    end

    function props:Init()
        private[self] = private[self] or {}
        repopulate(self)
    end

    function props:GetSelectedPageSize()
        local str = mixin.FCMCtrlPopup.GetSelectedString(self)
        if not str then
            return nil
        end
        return str:match("(.+) %(")
    end

    function props:SetSelectedPageSize(size)
        mixin_helper.assert_argument_type(2, size, "string", "FCString")
        size = type(size) == "userdata" and size.LuaString or tostring(size)
        mixin_helper.assert(page_size.is_size(size), "'" .. size .. "' is not a valid page size.")
        local index = 0
        for s in page_size.pairs() do
            if size == s then
                if index ~= self:GetSelectedItem_() then
                    mixin.FCMCtrlPopup.SetSelectedItem(self, index)
                    trigger_page_size_change(self)
                end
                return
            end
            index = index + 1
        end
    end

    function props:UpdateMeasurementUnit()
        repopulate(self)
    end



    props.AddHandlePageSizeChange, props.RemoveHandlePageSizeChange, trigger_page_size_change, each_last_page_size_change = mixin_helper.create_custom_control_change_event(
        {
            name = "last_page_size",
            get = function(ctrl)
                return mixin.FCXCtrlPageSizePopup.GetSelectedPageSize(ctrl)
            end,
            initial = false,
        }
    )
    return props
end
package.preload["mixin.FCXCtrlStatic"] = package.preload["mixin.FCXCtrlStatic"] or function()



    local mixin = require("library.mixin")
    local mixin_helper = require("library.mixin_helper")
    local measurement = require("library.measurement")
    local utils = require("library.utils")
    local private = setmetatable({}, {__mode = "k"})
    local props = {MixinParent = "FCMCtrlStatic"}
    local temp_str = finale.FCString()
    local function get_suffix(unit, suffix_type)
        if suffix_type == 1 then
            return measurement.get_unit_suffix(unit)
        elseif suffix_type == 2 then
            return measurement.get_unit_abbreviation(unit)
        elseif suffix_type == 3 then
            return " " .. string.lower(measurement.get_unit_name(unit))
        end
    end

    function props:Init()
        mixin_helper.assert(function() return mixin_helper.is_instance_of(self:GetParent(), "FCXCustomLuaWindow") end, "FCXCtrlStatic must have a parent window that is an instance of FCXCustomLuaWindow")
        private[self] = private[self] or {
            ShowMeasurementSuffix = true,
            MeasurementSuffixType = 2,
        }
    end

    function props:SetText(str)
        mixin_helper.assert_argument_type(2, str, "string", "number", "FCString")
        mixin.FCMCtrlStatic.SetText(self, str)
        private[self].Measurement = nil
        private[self].MeasurementType = nil
    end

    function props:SetMeasurement(value)
        mixin_helper.assert_argument_type(2, value, "number")
        local unit = self:GetParent():GetMeasurementUnit()
        temp_str:SetMeasurement(value, unit)
        temp_str:AppendLuaString(private[self].ShowMeasurementSuffix and get_suffix(unit, private[self].MeasurementSuffixType) or "")
        mixin.FCMCtrlStatic.SetText(self, temp_str)
        private[self].Measurement = value
        private[self].MeasurementType = "Measurement"
    end

    function props:SetMeasurementInteger(value)
        mixin_helper.assert_argument_type(2, value, "number")
        value = utils.round(value)
        local unit = self:GetParent():GetMeasurementUnit()
        temp_str:SetMeasurement(value, unit)
        temp_str:AppendLuaString(private[self].ShowMeasurementSuffix and get_suffix(unit, private[self].MeasurementSuffixType) or "")
        mixin.FCMCtrlStatic.SetText(self, temp_str)
        private[self].Measurement = value
        private[self].MeasurementType = "MeasurementInteger"
    end

    function props:SetMeasurementEfix(value)
        mixin_helper.assert_argument_type(2, value, "number")
        local evpu = value / 64
        local unit = self:GetParent():GetMeasurementUnit()
        temp_str:SetMeasurement(evpu, unit)
        temp_str:AppendLuaString(private[self].ShowMeasurementSuffix and get_suffix(unit, private[self].MeasurementSuffixType) or "")
        mixin.FCMCtrlStatic.SetText(self, temp_str)
        private[self].Measurement = value
        private[self].MeasurementType = "MeasurementEfix"
    end

    function props:SetShowMeasurementSuffix(enabled)
        mixin_helper.assert_argument_type(2, enabled, "boolean")
        private[self].ShowMeasurementSuffix = enabled and true or false
        mixin.FCXCtrlStatic.UpdateMeasurementUnit(self)
    end

    function props:SetMeasurementSuffixShort()
        private[self].MeasurementSuffixType = 1
        mixin.FCXCtrlStatic.UpdateMeasurementUnit(self)
    end

    function props:SetMeasurementSuffixAbbreviated()
        private[self].MeasurementSuffixType = 2
        mixin.FCXCtrlStatic.UpdateMeasurementUnit(self)
    end

    function props:SetMeasurementSuffixFull()
        private[self].MeasurementSuffixType = 3
        mixin.FCXCtrlStatic.UpdateMeasurementUnit(self)
    end

    function props:UpdateMeasurementUnit()
        if private[self].Measurement then
            mixin.FCXCtrlStatic["Set" .. private[self].MeasurementType](self, private[self].Measurement)
        end
    end
    return props
end
package.preload["mixin.FCXCtrlUpDown"] = package.preload["mixin.FCXCtrlUpDown"] or function()



    local mixin = require("library.mixin")
    local mixin_helper = require("library.mixin_helper")
    local private = setmetatable({}, {__mode = "k"})
    local props = {MixinParent = "FCMCtrlUpDown"}
    local temp_str = finale.FCString()

    local function enum_edit_type(edit, edit_type)
        if edit_type == "Integer" then
            return 1
        else
            if edit:IsTypeMeasurement() then
                return 2
            elseif edit:IsTypeMeasurementInteger() then
                return 3
            elseif edit:IsTypeMeasurementEfix() then
                return 4
            end
        end
    end
    local default_measurement_steps = {
        [finale.MEASUREMENTUNIT_EVPUS] = {value = 1, is_evpus = true},
        [finale.MEASUREMENTUNIT_INCHES] = {value = 0.03125, is_evpus = false},
        [finale.MEASUREMENTUNIT_CENTIMETERS] = {value = 0.01, is_evpus = false},
        [finale.MEASUREMENTUNIT_POINTS] = {value = 0.25, is_evpus = false},
        [finale.MEASUREMENTUNIT_PICAS] = {value = 1, is_evpus = true},
        [finale.MEASUREMENTUNIT_SPACES] = {value = 0.125, is_evpus = false},
    }
    local default_efix_steps = {
        [finale.MEASUREMENTUNIT_EVPUS] = {value = 0.015625, is_evpus = true},
        [finale.MEASUREMENTUNIT_INCHES] = {value = 0.03125, is_evpus = false},
        [finale.MEASUREMENTUNIT_CENTIMETERS] = {value = 0.001, is_evpus = false},
        [finale.MEASUREMENTUNIT_POINTS] = {value = 0.03125, is_evpus = false},
        [finale.MEASUREMENTUNIT_PICAS] = {value = 0.015625, is_evpus = true},
        [finale.MEASUREMENTUNIT_SPACES] = {value = 0.03125, is_evpus = false},
    }

    function props:Init()
        mixin_helper.assert(function() return mixin_helper.is_instance_of(self:GetParent(), "FCXCustomLuaWindow") end, "FCXCtrlUpDown must have a parent window that is an instance of FCXCustomLuaWindow")
        private[self] = private[self] or {IntegerStepSize = 1, MeasurementSteps = {}, AlignWhenMoving = true}
        self:AddHandlePress(
            function(self, delta)
                if not private[self].ConnectedEdit then
                    return
                end
                local edit = private[self].ConnectedEdit
                local edit_type = enum_edit_type(edit, private[self].ConnectedEditType)
                local unit = self:GetParent():GetMeasurementUnit()
                local separator = mixin.UI():GetDecimalSeparator()
                local step_def
                if edit_type == 1 then
                    step_def = {value = private[self].IntegerStepSize}
                else
                    step_def = private[self].MeasurementSteps[unit] or (edit_type == 4 and default_efix_steps[unit]) or
                                   default_measurement_steps[unit]
                end

                local value
                if edit_type == 1 then
                    value = edit:GetText():match("^%-*[0-9%.%,%" .. separator .. "-]+")
                    value = value and tonumber(value) or 0
                else
                    if step_def.is_evpus then
                        value = edit:GetMeasurement()
                    else

                        temp_str:SetMeasurement(edit:GetMeasurement(), unit)
                        value = temp_str.LuaString:gsub("%" .. separator, ".")
                        value = tonumber(value)
                    end
                end

                if private[self].AlignWhenMoving then

                    local num_steps = tonumber(tostring(value / step_def.value))
                    if num_steps ~= math.floor(num_steps) then
                        if delta > 0 then
                            value = math.ceil(num_steps) * step_def.value
                            delta = delta - 1
                        elseif delta < 0 then
                            value = math.floor(num_steps) * step_def.value
                            delta = delta + 1
                        end
                    end
                end

                local new_value = value + delta * step_def.value

                if edit_type == 1 then
                    self:SetValue(new_value)
                else
                    if step_def.is_evpus then
                        self:SetValue(edit_type == 4 and new_value * 64 or new_value)
                    else

                        temp_str.LuaString = tostring(new_value)
                        local new_evpus = temp_str:GetMeasurement(unit)
                        if new_evpus < private[self].Minimum or new_evpus > private[self].Maximum then
                            self:SetValue(edit_type == 4 and new_evpus * 64 or new_evpus)
                        else
                            edit:SetText(temp_str.LuaString:gsub("%.", separator))
                        end
                    end
                end
            end)
    end

    function props:GetConnectedEdit()
        return private[self].ConnectedEdit
    end

    function props:ConnectIntegerEdit(control, minimum, maximum)
        mixin_helper.assert_argument_type(2, control, "FCMCtrlEdit")
        mixin_helper.assert_argument_type(3, minimum, "number")
        mixin_helper.assert_argument_type(4, maximum, "number")
        mixin_helper.assert(function() return not mixin_helper.is_instance_of(control, "FCXCtrlMeasurementEdit") end, "A measurement edit cannot be connected as an integer edit.")
        private[self].ConnectedEdit = control
        private[self].ConnectedEditType = "Integer"
        private[self].Minimum = minimum
        private[self].Maximum = maximum
    end

    function props:ConnectMeasurementEdit(control, minimum, maximum)
        mixin_helper.assert_argument_type(2, control, "FCXCtrlMeasurementEdit")
        mixin_helper.assert_argument_type(3, minimum, "number")
        mixin_helper.assert_argument_type(4, maximum, "number")
        private[self].ConnectedEdit = control
        private[self].ConnectedEditType = "Measurement"
        private[self].Minimum = minimum
        private[self].Maximum = maximum
    end

    function props:SetIntegerStepSize(value)
        mixin_helper.assert_argument_type(2, value, "number")
        private[self].IntegerStepSize = value
    end

    function props:SetEVPUsStepSize(value)
        mixin_helper.assert_argument_type(2, value, "number")
        private[self].MeasurementSteps[finale.MEASUREMENTUNIT_EVPUS] = {value = value, is_evpus = true}
    end

    function props:SetInchesStepSize(value, is_evpus)
        mixin_helper.assert_argument_type(2, value, "number")
        mixin_helper.assert_argument_type(3, is_evpus, "boolean", "nil")
        private[self].MeasurementSteps[finale.MEASUREMENTUNIT_INCHES] = {
            value = value,
            is_evpus = is_evpus and true or false,
        }
    end

    function props:SetCentimetersStepSize(value, is_evpus)
        mixin_helper.assert_argument_type(2, value, "number")
        mixin_helper.assert_argument_type(3, is_evpus, "boolean", "nil")
        private[self].MeasurementSteps[finale.MEASUREMENTUNIT_CENTIMETERS] = {
            value = value,
            is_evpus = is_evpus and true or false,
        }
    end

    function props:SetPointsStepSize(value, is_evpus)
        mixin_helper.assert_argument_type(2, value, "number")
        mixin_helper.assert_argument_type(3, is_evpus, "boolean", "nil")
        private[self].MeasurementSteps[finale.MEASUREMENTUNIT_POINTS] = {
            value = value,
            is_evpus = is_evpus and true or false,
        }
    end

    function props:SetPicasStepSize(value, is_evpus)
        mixin_helper.assert_argument_type(2, value, "number", "string")
        if not is_evpus then
            temp_str:SetText(tostring(value))
            value = temp_str:GetMeasurement(finale.MEASUREMENTUNIT_PICAS)
        end
        private[self].MeasurementSteps[finale.MEASUREMENTUNIT_PICAS] = {value = value, is_evpus = true}
    end

    function props:SetSpacesStepSize(value, is_evpus)
        mixin_helper.assert_argument_type(2, value, "number")
        mixin_helper.assert_argument_type(3, is_evpus, "boolean", "nil")
        private[self].MeasurementSteps[finale.MEASUREMENTUNIT_SPACES] = {
            value = value,
            is_evpus = is_evpus and true or false,
        }
    end

    function props:SetAlignWhenMoving(on)
        mixin_helper.assert_argument_type(2, on, "boolean")
        private[self].AlignWhenMoving = on
    end

    function props:GetValue()
        if not private[self].ConnectedEdit then
            return
        end
        local edit = private[self].ConnectedEdit
        if private[self].ConnectedEditType == "Measurement" then
            return edit["Get" .. edit:GetType()](edit, private[self].Minimum, private[self].Maximum)
        else
            return edit:GetRangeInteger(private[self].Minimum, private[self].Maximum)
        end
    end

    function props:SetValue(value)
        mixin_helper.assert_argument_type(2, value, "number")
        mixin_helper.assert(private[self].ConnectedEdit, "Unable to set value: no connected edit.")

        value = value < private[self].Minimum and private[self].Minimum or value
        value = value > private[self].Maximum and private[self].Maximum or value
        local edit = private[self].ConnectedEdit
        if private[self].ConnectedEditType == "Measurement" then
            edit["Set" .. edit:GetType()](edit, value)
        else
            edit:SetInteger(value)
        end
    end

    function props:GetMinimum()
        return private[self].Minimum
    end

    function props:GetMaximum()
        return private[self].Maximum
    end

    function props:SetRange(minimum, maximum)
        mixin_helper.assert_argument_type(2, minimum, "number")
        mixin_helper.assert_argument_type(3, maximum, "number")
        private[self].Minimum = minimum
        private[self].Maximum = maximum
    end
    return props
end
package.preload["library.measurement"] = package.preload["library.measurement"] or function()

    local measurement = {}
    local unit_names = {
        [finale.MEASUREMENTUNIT_EVPUS] = "EVPUs",
        [finale.MEASUREMENTUNIT_INCHES] = "Inches",
        [finale.MEASUREMENTUNIT_CENTIMETERS] = "Centimeters",
        [finale.MEASUREMENTUNIT_POINTS] = "Points",
        [finale.MEASUREMENTUNIT_PICAS] = "Picas",
        [finale.MEASUREMENTUNIT_SPACES] = "Spaces",
    }
    local unit_suffixes = {
        [finale.MEASUREMENTUNIT_EVPUS] = "e",
        [finale.MEASUREMENTUNIT_INCHES] = "i",
        [finale.MEASUREMENTUNIT_CENTIMETERS] = "c",
        [finale.MEASUREMENTUNIT_POINTS] = "pt",
        [finale.MEASUREMENTUNIT_PICAS] = "p",
        [finale.MEASUREMENTUNIT_SPACES] = "s",
    }
    local unit_abbreviations = {
        [finale.MEASUREMENTUNIT_EVPUS] = "ev",
        [finale.MEASUREMENTUNIT_INCHES] = "in",
        [finale.MEASUREMENTUNIT_CENTIMETERS] = "cm",
        [finale.MEASUREMENTUNIT_POINTS] = "pt",
        [finale.MEASUREMENTUNIT_PICAS] = "pc",
        [finale.MEASUREMENTUNIT_SPACES] = "sp",
    }

    function measurement.convert_to_EVPUs(text)
        local str = finale.FCString()
        str.LuaString = text
        return str:GetMeasurement(finale.MEASUREMENTUNIT_DEFAULT)
    end

    function measurement.get_unit_name(unit)
        if unit == finale.MEASUREMENTUNIT_DEFAULT then
            unit = measurement.get_real_default_unit()
        end
        return unit_names[unit]
    end

    function measurement.get_unit_suffix(unit)
        if unit == finale.MEASUREMENTUNIT_DEFAULT then
            unit = measurement.get_real_default_unit()
        end
        return unit_suffixes[unit]
    end

    function measurement.get_unit_abbreviation(unit)
        if unit == finale.MEASUREMENTUNIT_DEFAULT then
            unit = measurement.get_real_default_unit()
        end
        return unit_abbreviations[unit]
    end

    function measurement.is_valid_unit(unit)
        return unit_names[unit] and true or false
    end

    function measurement.get_real_default_unit()
        local str = finale.FCString()
        finenv.UI():GetDecimalSeparator(str)
        local separator = str.LuaString
        str:SetMeasurement(72, finale.MEASUREMENTUNIT_DEFAULT)
        if str.LuaString == "72" then
            return finale.MEASUREMENTUNIT_EVPUS
        elseif str.LuaString == "0" .. separator .. "25" then
            return finale.MEASUREMENTUNIT_INCHES
        elseif str.LuaString == "0" .. separator .. "635" then
            return finale.MEASUREMENTUNIT_CENTIMETERS
        elseif str.LuaString == "18" then
            return finale.MEASUREMENTUNIT_POINTS
        elseif str.LuaString == "1p6" then
            return finale.MEASUREMENTUNIT_PICAS
        elseif str.LuaString == "3" then
            return finale.MEASUREMENTUNIT_SPACES
        end
    end
    return measurement
end
package.preload["mixin.FCXCustomLuaWindow"] = package.preload["mixin.FCXCustomLuaWindow"] or function()



    local mixin = require("library.mixin")
    local utils = require("library.utils")
    local mixin_helper = require("library.mixin_helper")
    local measurement = require("library.measurement")
    local props = {MixinParent = "FCMCustomLuaWindow"}
    local trigger_measurement_unit_change
    local each_last_measurement_unit_change

    function props:Init()
        self:SetEnableDebugClose(true)
    end

    function props:CreateStatic(x, y, control_name)
        mixin_helper.assert_argument_type(2, x, "number")
        mixin_helper.assert_argument_type(3, y, "number")
        mixin_helper.assert_argument_type(4, control_name, "string", "nil")
        local popup = mixin.FCMCustomWindow.CreateStatic(self, x, y, control_name)
        return mixin.subclass(popup, "FCXCtrlStatic")
    end

    function props:CreateUpDown(x, y, control_name)
        mixin_helper.assert_argument_type(2, x, "number")
        mixin_helper.assert_argument_type(3, y, "number")
        mixin_helper.assert_argument_type(4, control_name, "string", "nil")
        local updown = mixin.FCMCustomWindow.CreateUpDown(self, x, y, control_name)
        return mixin.subclass(updown, "FCXCtrlUpDown")
    end
    return props
end
package.preload["library.utils"] = package.preload["library.utils"] or function()

    local utils = {}




    function utils.copy_table(t)
        if type(t) == "table" then
            local new = {}
            for k, v in pairs(t) do
                new[utils.copy_table(k)] = utils.copy_table(v)
            end
            setmetatable(new, utils.copy_table(getmetatable(t)))
            return new
        else
            return t
        end
    end

    function utils.table_remove_first(t, value)
        for k = 1, #t do
            if t[k] == value then
                table.remove(t, k)
                return
            end
        end
    end

    function utils.iterate_keys(t)
        local a, b, c = pairs(t)
        return function()
            c = a(b, c)
            return c
        end
    end

    function utils.round(value, places)
        places = places or 0
        local multiplier = 10^places
        return math.floor(value * multiplier + 0.5) / multiplier
    end

    function utils.calc_roman_numeral(num)
        local thousands = {'M','MM','MMM'}
        local hundreds = {'C','CC','CCC','CD','D','DC','DCC','DCCC','CM'}
        local tens = {'X','XX','XXX','XL','L','LX','LXX','LXXX','XC'}	
        local ones = {'I','II','III','IV','V','VI','VII','VIII','IX'}
        local roman_numeral = ''
        if math.floor(num/1000)>0 then roman_numeral = roman_numeral..thousands[math.floor(num/1000)] end
        if math.floor((num%1000)/100)>0 then roman_numeral=roman_numeral..hundreds[math.floor((num%1000)/100)] end
        if math.floor((num%100)/10)>0 then roman_numeral=roman_numeral..tens[math.floor((num%100)/10)] end
        if num%10>0 then roman_numeral = roman_numeral..ones[num%10] end
        return roman_numeral
    end

    function utils.calc_ordinal(num)
        local units = num % 10
        local tens = num % 100
        if units == 1 and tens ~= 11 then
            return num .. "st"
        elseif units == 2 and tens ~= 12 then
            return num .. "nd"
        elseif units == 3 and tens ~= 13 then
            return num .. "rd"
        end
        return num .. "th"
    end

    function utils.calc_alphabet(num)
        local letter = ((num - 1) % 26) + 1
        local n = math.floor((num - 1) / 26)
        return string.char(64 + letter) .. (n > 0 and n or "")
    end

    function utils.clamp(num, minimum, maximum)
        return math.min(math.max(num, minimum), maximum)
    end

    function utils.ltrim(str)
        return string.match(str, "^%s*(.*)")
    end

    function utils.rtrim(str)
        return string.match(str, "(.-)%s*$")
    end

    function utils.trim(str)
        return utils.ltrim(utils.rtrim(str))
    end

    local pcall_wrapper
    local rethrow_placeholder = "tryfunczzz"
    local pcall_line = debug.getinfo(1, "l").currentline + 2
    function utils.call_and_rethrow(levels, tryfunczzz, ...)
        return pcall_wrapper(levels, pcall(function(...) return 1, tryfunczzz(...) end, ...))

    end

    local source = debug.getinfo(1, "S").source
    local source_is_file = source:sub(1, 1) == "@"
    if source_is_file then
        source = source:sub(2)
    end

    pcall_wrapper = function(levels, success, result, ...)
        if not success then
            local file
            local line
            local msg
            file, line, msg = result:match("([a-zA-Z]-:?[^:]+):([0-9]+): (.+)")
            msg = msg or result
            local file_is_truncated = file and file:sub(1, 3) == "..."
            file = file_is_truncated and file:sub(4) or file



            if file
                and line
                and source_is_file
                and (file_is_truncated and source:sub(-1 * file:len()) == file or file == source)
                and tonumber(line) == pcall_line
            then
                local d = debug.getinfo(levels, "n")

                msg = msg:gsub("'" .. rethrow_placeholder .. "'", "'" .. (d.name or "") .. "'")

                if d.namewhat == "method" then
                    local arg = msg:match("^bad argument #(%d+)")
                    if arg then
                        msg = msg:gsub("#" .. arg, "#" .. tostring(tonumber(arg) - 1), 1)
                    end
                end
                error(msg, levels + 1)


            else
                error(result, 0)
            end
        end
        return ...
    end

    function utils.rethrow_placeholder()
        return "'" .. rethrow_placeholder .. "'"
    end
    return utils
end
package.preload["library.client"] = package.preload["library.client"] or function()

    local client = {}
    local function to_human_string(feature)
        return string.gsub(feature, "_", " ")
    end
    local function requires_later_plugin_version(feature)
        if feature then
            return "This script uses " .. to_human_string(feature) .. "which is only available in a later version of RGP Lua. Please update RGP Lua instead to use this script."
        end
        return "This script requires a later version of RGP Lua. Please update RGP Lua instead to use this script."
    end
    local function requires_rgp_lua(feature)
        if feature then
            return "This script uses " .. to_human_string(feature) .. " which is not available on JW Lua. Please use RGP Lua instead to use this script."
        end
        return "This script requires RGP Lua, the successor of JW Lua. Please use RGP Lua instead to use this script."
    end
    local function requires_plugin_version(version, feature)
        if tonumber(version) <= 0.54 then
            if feature then
                return "This script uses " .. to_human_string(feature) .. " which requires RGP Lua or JW Lua version " .. version ..
                           " or later. Please update your plugin to use this script."
            end
            return "This script requires RGP Lua or JW Lua version " .. version .. " or later. Please update your plugin to use this script."
        end
        if feature then
            return "This script uses " .. to_human_string(feature) .. " which requires RGP Lua version " .. version .. " or later. Please update your plugin to use this script."
        end
        return "This script requires RGP Lua version " .. version .. " or later. Please update your plugin to use this script."
    end
    local function requires_finale_version(version, feature)
        return "This script uses " .. to_human_string(feature) .. ", which is only available on Finale " .. version .. " or later"
    end

    function client.get_raw_finale_version(major, minor, build)
        local retval = bit32.bor(bit32.lshift(math.floor(major), 24), bit32.lshift(math.floor(minor), 20))
        if build then
            retval = bit32.bor(retval, math.floor(build))
        end
        return retval
    end

    function client.get_lua_plugin_version()
        local num_string = tostring(finenv.MajorVersion) .. "." .. tostring(finenv.MinorVersion)
        return tonumber(num_string)
    end
    local features = {
        clef_change = {
            test = client.get_lua_plugin_version() >= 0.60,
            error = requires_plugin_version("0.58", "a clef change"),
        },
        ["FCKeySignature::CalcTotalChromaticSteps"] = {
            test = finenv.IsRGPLua and finale.FCKeySignature.__class.CalcTotalChromaticSteps,
            error = requires_later_plugin_version("a custom key signature"),
        },
        ["FCCategory::SaveWithNewType"] = {
            test = client.get_lua_plugin_version() >= 0.58,
            error = requires_plugin_version("0.58"),
        },
        ["finenv.QueryInvokedModifierKeys"] = {
            test = finenv.IsRGPLua and finenv.QueryInvokedModifierKeys,
            error = requires_later_plugin_version(),
        },
        ["FCCustomLuaWindow::ShowModeless"] = {
            test = finenv.IsRGPLua,
            error = requires_rgp_lua("a modeless dialog")
        },
        ["finenv.RetainLuaState"] = {
            test = finenv.IsRGPLua and finenv.RetainLuaState ~= nil,
            error = requires_later_plugin_version(),
        },
        smufl = {
            test = finenv.RawFinaleVersion >= client.get_raw_finale_version(27, 1),
            error = requires_finale_version("27.1", "a SMUFL font"),
        },
    }

    function client.supports(feature)
        if features[feature].test == nil then
            error("a test does not exist for feature " .. feature, 2)
        end
        return features[feature].test
    end

    function client.assert_supports(feature)
        local error_level = finenv.DebugEnabled and 2 or 0
        if not client.supports(feature) then
            if features[feature].error then
                error(features[feature].error, error_level)
            end

            error("Your Finale version does not support " .. to_human_string(feature), error_level)
        end
        return true
    end
    return client
end
package.preload["library.general_library"] = package.preload["library.general_library"] or function()

    local library = {}
    local client = require("library.client")

    function library.group_overlaps_region(staff_group, region)
        if region:IsFullDocumentSpan() then
            return true
        end
        local staff_exists = false
        local sys_staves = finale.FCSystemStaves()
        sys_staves:LoadAllForRegion(region)
        for sys_staff in each(sys_staves) do
            if staff_group:ContainsStaff(sys_staff:GetStaff()) then
                staff_exists = true
                break
            end
        end
        if not staff_exists then
            return false
        end
        if (staff_group.StartMeasure > region.EndMeasure) or (staff_group.EndMeasure < region.StartMeasure) then
            return false
        end
        return true
    end

    function library.group_is_contained_in_region(staff_group, region)
        if not region:IsStaffIncluded(staff_group.StartStaff) then
            return false
        end
        if not region:IsStaffIncluded(staff_group.EndStaff) then
            return false
        end
        return true
    end

    function library.staff_group_is_multistaff_instrument(staff_group)
        local multistaff_instruments = finale.FCMultiStaffInstruments()
        multistaff_instruments:LoadAll()
        for inst in each(multistaff_instruments) do
            if inst:ContainsStaff(staff_group.StartStaff) and (inst.GroupID == staff_group:GetItemID()) then
                return true
            end
        end
        return false
    end

    function library.get_selected_region_or_whole_doc()
        local sel_region = finenv.Region()
        if sel_region:IsEmpty() then
            sel_region:SetFullDocument()
        end
        return sel_region
    end

    function library.get_first_cell_on_or_after_page(page_num)
        local curr_page_num = page_num
        local curr_page = finale.FCPage()
        local got1 = false

        while curr_page:Load(curr_page_num) do
            if curr_page:GetFirstSystem() > 0 then
                got1 = true
                break
            end
            curr_page_num = curr_page_num + 1
        end
        if got1 then
            local staff_sys = finale.FCStaffSystem()
            staff_sys:Load(curr_page:GetFirstSystem())
            return finale.FCCell(staff_sys.FirstMeasure, staff_sys.TopStaff)
        end

        local end_region = finale.FCMusicRegion()
        end_region:SetFullDocument()
        return finale.FCCell(end_region.EndMeasure, end_region.EndStaff)
    end

    function library.get_top_left_visible_cell()
        if not finenv.UI():IsPageView() then
            local all_region = finale.FCMusicRegion()
            all_region:SetFullDocument()
            return finale.FCCell(finenv.UI():GetCurrentMeasure(), all_region.StartStaff)
        end
        return library.get_first_cell_on_or_after_page(finenv.UI():GetCurrentPage())
    end

    function library.get_top_left_selected_or_visible_cell()
        local sel_region = finenv.Region()
        if not sel_region:IsEmpty() then
            return finale.FCCell(sel_region.StartMeasure, sel_region.StartStaff)
        end
        return library.get_top_left_visible_cell()
    end

    function library.is_default_measure_number_visible_on_cell(meas_num_region, cell, staff_system, current_is_part)
        local staff = finale.FCCurrentStaffSpec()
        if not staff:LoadForCell(cell, 0) then
            return false
        end
        if meas_num_region:GetShowOnTopStaff() and (cell.Staff == staff_system.TopStaff) then
            return true
        end
        if meas_num_region:GetShowOnBottomStaff() and (cell.Staff == staff_system:CalcBottomStaff()) then
            return true
        end
        if staff.ShowMeasureNumbers then
            return not meas_num_region:GetExcludeOtherStaves(current_is_part)
        end
        return false
    end

    function library.calc_parts_boolean_for_measure_number_region(meas_num_region, for_part)
        if meas_num_region.UseScoreInfoForParts then
            return false
        end
        if nil == for_part then
            return finenv.UI():IsPartView()
        end
        return for_part
    end

    function library.is_default_number_visible_and_left_aligned(meas_num_region, cell, system, current_is_part, is_for_multimeasure_rest)
        current_is_part = library.calc_parts_boolean_for_measure_number_region(meas_num_region, current_is_part)
        if is_for_multimeasure_rest and meas_num_region:GetShowOnMultiMeasureRests(current_is_part) then
            if (finale.MNALIGN_LEFT ~= meas_num_region:GetMultiMeasureAlignment(current_is_part)) then
                return false
            end
        elseif (cell.Measure == system.FirstMeasure) then
            if not meas_num_region:GetShowOnSystemStart() then
                return false
            end
            if (finale.MNALIGN_LEFT ~= meas_num_region:GetStartAlignment(current_is_part)) then
                return false
            end
        else
            if not meas_num_region:GetShowMultiples(current_is_part) then
                return false
            end
            if (finale.MNALIGN_LEFT ~= meas_num_region:GetMultipleAlignment(current_is_part)) then
                return false
            end
        end
        return library.is_default_measure_number_visible_on_cell(meas_num_region, cell, system, current_is_part)
    end

    function library.update_layout(from_page, unfreeze_measures)
        from_page = from_page or 1
        unfreeze_measures = unfreeze_measures or false
        local page = finale.FCPage()
        if page:Load(from_page) then
            page:UpdateLayout(unfreeze_measures)
        end
    end

    function library.get_current_part()
        local part = finale.FCPart(finale.PARTID_CURRENT)
        part:Load(part.ID)
        return part
    end

    function library.get_score()
        local part = finale.FCPart(finale.PARTID_SCORE)
        part:Load(part.ID)
        return part
    end

    function library.get_page_format_prefs()
        local current_part = library.get_current_part()
        local page_format_prefs = finale.FCPageFormatPrefs()
        local success = false
        if current_part:IsScore() then
            success = page_format_prefs:LoadScore()
        else
            success = page_format_prefs:LoadParts()
        end
        return page_format_prefs, success
    end
    local calc_smufl_directory = function(for_user)
        local is_on_windows = finenv.UI():IsOnWindows()
        local do_getenv = function(win_var, mac_var)
            if finenv.UI():IsOnWindows() then
                return win_var and os.getenv(win_var) or ""
            else
                return mac_var and os.getenv(mac_var) or ""
            end
        end
        local smufl_directory = for_user and do_getenv("LOCALAPPDATA", "HOME") or do_getenv("COMMONPROGRAMFILES")
        if not is_on_windows then
            smufl_directory = smufl_directory .. "/Library/Application Support"
        end
        smufl_directory = smufl_directory .. "/SMuFL/Fonts/"
        return smufl_directory
    end

    function library.get_smufl_font_list()
        local font_names = {}
        local add_to_table = function(for_user)
            local smufl_directory = calc_smufl_directory(for_user)
            local get_dirs = function()
                if finenv.UI():IsOnWindows() then
                    return io.popen("dir \"" .. smufl_directory .. "\" /b /ad")
                else
                    return io.popen("ls \"" .. smufl_directory .. "\"")
                end
            end
            local is_font_available = function(dir)
                local fc_dir = finale.FCString()
                fc_dir.LuaString = dir
                return finenv.UI():IsFontAvailable(fc_dir)
            end
            for dir in get_dirs():lines() do
                if not dir:find("%.") then
                    dir = dir:gsub(" Bold", "")
                    dir = dir:gsub(" Italic", "")
                    local fc_dir = finale.FCString()
                    fc_dir.LuaString = dir
                    if font_names[dir] or is_font_available(dir) then
                        font_names[dir] = for_user and "user" or "system"
                    end
                end
            end
        end
        add_to_table(true)
        add_to_table(false)
        return font_names
    end

    function library.get_smufl_metadata_file(font_info)
        if not font_info then
            font_info = finale.FCFontInfo()
            font_info:LoadFontPrefs(finale.FONTPREF_MUSIC)
        end
        local try_prefix = function(prefix, font_info)
            local file_path = prefix .. font_info.Name .. "/" .. font_info.Name .. ".json"
            return io.open(file_path, "r")
        end
        local user_file = try_prefix(calc_smufl_directory(true), font_info)
        if user_file then
            return user_file
        end
        return try_prefix(calc_smufl_directory(false), font_info)
    end

    function library.is_font_smufl_font(font_info)
        if not font_info then
            font_info = finale.FCFontInfo()
            font_info:LoadFontPrefs(finale.FONTPREF_MUSIC)
        end
        if client.supports("smufl") then
            if nil ~= font_info.IsSMuFLFont then
                return font_info.IsSMuFLFont
            end
        end
        local smufl_metadata_file = library.get_smufl_metadata_file(font_info)
        if nil ~= smufl_metadata_file then
            io.close(smufl_metadata_file)
            return true
        end
        return false
    end

    function library.simple_input(title, text)
        local return_value = finale.FCString()
        return_value.LuaString = ""
        local str = finale.FCString()
        local min_width = 160

        function format_ctrl(ctrl, h, w, st)
            ctrl:SetHeight(h)
            ctrl:SetWidth(w)
            str.LuaString = st
            ctrl:SetText(str)
        end

        title_width = string.len(title) * 6 + 54
        if title_width > min_width then
            min_width = title_width
        end
        text_width = string.len(text) * 6
        if text_width > min_width then
            min_width = text_width
        end

        str.LuaString = title
        local dialog = finale.FCCustomLuaWindow()
        dialog:SetTitle(str)
        local descr = dialog:CreateStatic(0, 0)
        format_ctrl(descr, 16, min_width, text)
        local input = dialog:CreateEdit(0, 20)
        format_ctrl(input, 20, min_width, "")
        dialog:CreateOkButton()
        dialog:CreateCancelButton()

        function callback(ctrl)
        end

        dialog:RegisterHandleCommand(callback)

        if dialog:ExecuteModal(nil) == finale.EXECMODAL_OK then
            return_value.LuaString = input:GetText(return_value)

            return return_value.LuaString

        end
    end

    function library.is_finale_object(object)

        return object and type(object) == "userdata" and object.ClassName and object.GetClassID and true or false
    end

    function library.get_parent_class(classname)
        local class = finale[classname]
        if type(class) ~= "table" then return nil end
        if not finenv.IsRGPLua then
            local classt = class.__class
            if classt and classname ~= "__FCBase" then
                local classtp = classt.__parent
                if classtp and type(classtp) == "table" then
                    for k, v in pairs(finale) do
                        if type(v) == "table" then
                            if v.__class and v.__class == classtp then
                                return tostring(k)
                            end
                        end
                    end
                end
            end
        else
            for k, _ in pairs(class.__parent) do
                return tostring(k)
            end
        end
        return nil
    end

    function library.get_class_name(object)
        local class_name = object:ClassName(object)
        if class_name == "__FCCollection" and object.ExecuteModal then
            return object.RegisterHandleCommand and "FCCustomLuaWindow" or "FCCustomWindow"
        elseif class_name == "FCControl" then
            if object.GetCheck then
                return "FCCtrlCheckbox"
            elseif object.GetThumbPosition then
                return "FCCtrlSlider"
            elseif object.AddPage then
                return "FCCtrlSwitcher"
            else
                return "FCCtrlButton"
            end
        elseif class_name == "FCCtrlButton" and object.GetThumbPosition then
            return "FCCtrlSlider"
        end
        return class_name
    end

    function library.system_indent_set_to_prefs(system, page_format_prefs)
        page_format_prefs = page_format_prefs or library.get_page_format_prefs()
        local first_meas = finale.FCMeasure()
        local is_first_system = (system.FirstMeasure == 1)
        if (not is_first_system) and first_meas:Load(system.FirstMeasure) then
            if first_meas.ShowFullNames then
                is_first_system = true
            end
        end
        if is_first_system and page_format_prefs.UseFirstSystemMargins then
            system.LeftMargin = page_format_prefs.FirstSystemLeft
        else
            system.LeftMargin = page_format_prefs.SystemLeft
        end
        return system:Save()
    end

    function library.calc_script_name(include_extension)
        local fc_string = finale.FCString()
        if finenv.RunningLuaFilePath then

            fc_string.LuaString = finenv.RunningLuaFilePath()
        else


            fc_string:SetRunningLuaFilePath()
        end
        local filename_string = finale.FCString()
        fc_string:SplitToPathAndFile(nil, filename_string)
        local retval = filename_string.LuaString
        if not include_extension then
            retval = retval:match("(.+)%..+")
            if not retval or retval == "" then
                retval = filename_string.LuaString
            end
        end
        return retval
    end

    function library.get_default_music_font_name()
        local fontinfo = finale.FCFontInfo()
        local default_music_font_name = finale.FCString()
        if fontinfo:LoadFontPrefs(finale.FONTPREF_MUSIC) then
            fontinfo:GetNameString(default_music_font_name)
            return default_music_font_name.LuaString
        end
    end
    return library
end
package.preload["library.mixin_helper"] = package.preload["library.mixin_helper"] or function()




    local utils = require("library.utils")
    local mixin = require("library.mixin")
    local library = require("library.general_library")
    local mixin_helper = {}
    local debug_enabled = finenv.DebugEnabled

    function mixin_helper.is_instance_of(object, ...)
        if not library.is_finale_object(object) then
            return false
        end



        local class_names = {[0] = {}, [1] = {}, [2] = {}}
        for i = 1, select("#", ...) do
            local class_name = select(i, ...)

            local class_type = (mixin.is_fcx_class_name(class_name) and 2) or (mixin.is_fcm_class_name(class_name) and 1) or (mixin.is_fc_class_name(class_name) and 0) or false
            if class_type then

                class_names[class_type][class_type == 1 and mixin.fcm_to_fc_class_name(class_name) or class_name] = true
            end
        end
        local object_type = (mixin.is_fcx_class_name(object.MixinClass) and 2) or (mixin.is_fcm_class_name(object.MixinClass) and 1) or 0
        local parent = object_type == 0 and library.get_class_name(object) or object.MixinClass

        if object_type == 2 then
            repeat
                if class_names[2][parent] then
                    return true
                end

                parent = object.MixinParent
            until mixin.is_fcm_class_name(parent)
        end

        if object_type > 0 then
            parent = mixin.fcm_to_fc_class_name(parent)
        end

        repeat
            if (object_type < 2 and class_names[0][parent])
                or (object_type > 0 and class_names[1][parent])
            then
                return true
            end
            parent = library.get_parent_class(parent)
        until not parent

        return false
    end
    local function assert_argument_type(levels, argument_number, value, ...)
        local value_type = type(value)
        for i = 1, select("#", ...) do
            if value_type == select(i, ...) then
                return
            end
        end
        if mixin_helper.is_instance_of(value, ...) then
            return
        end

        if library.is_finale_object(value) then
            value_type = value.MixinClass or value.ClassName
        end
        error("bad argument #" .. tostring(argument_number) .. " to 'tryfunczzz' (" .. table.concat(table.pack(...), " or ") .. " expected, got " .. value_type .. ")", levels)
    end

    function mixin_helper.assert_argument_type(argument_number, value, ...)
        if debug_enabled then
            assert_argument_type(4, argument_number, value, ...)
        end
    end

    function mixin_helper.force_assert_argument_type(argument_number, value, ...)
        assert_argument_type(4, argument_number, value, ...)
    end
    local function assert_func(condition, message, level)
        if type(condition) == 'function' then
            condition = condition()
        end
        if not condition then
            error(message, level)
        end
    end

    function mixin_helper.assert(condition, message, no_level)
        if debug_enabled then
            assert_func(condition, message, no_level and 0 or 4)
        end
    end

    function mixin_helper.force_assert(condition, message, no_level)
        assert_func(condition, message, no_level and 0 or 4)
    end
    local disabled_method = function()
        error("Attempt to call disabled method 'tryfunczzz'", 2)
    end

    function mixin_helper.disable_methods(props, ...)
        for i = 1, select("#", ...) do
            props[select(i, ...)] = disabled_method
        end
    end

    function mixin_helper.create_standard_control_event(name)
        local callbacks = setmetatable({}, {__mode = "k"})
        local windows = setmetatable({}, {__mode = "k"})
        local dispatcher = function(control, ...)
            if not callbacks[control] then
                return
            end
            for _, cb in ipairs(callbacks[control]) do
                cb(control, ...)
            end
        end
        local function init_window(window)
            if windows[window] then
                return
            end
            window["Add" .. name](window, dispatcher)
            windows[window] = true
        end
        local function add_func(control, callback)
            mixin_helper.assert_argument_type(3, callback, "function")
            local window = control:GetParent()
            mixin_helper.assert(window, "Cannot add handler to control with no parent window.")
            mixin_helper.assert(
                (window.MixinBase or window.MixinClass) == "FCMCustomLuaWindow",
                "Handlers can only be added if parent window is an instance of FCMCustomLuaWindow")
            init_window(window)
            callbacks[control] = callbacks[control] or {}
            table.insert(callbacks[control], callback)
        end
        local function remove_func(control, callback)
            mixin_helper.assert_argument_type(3, callback, "function")
            utils.table_remove_first(callbacks[control], callback)
        end
        return add_func, remove_func
    end

    local function unpack_arguments(values, ...)
        local args = {}
        for i = 1, select("#", ...) do
            table.insert(args, values[select(i, ...).name])
        end
        return table.unpack(args)
    end
    local function get_event_value(target, func)
        if type(func) == "string" then
            return target[func](target)
        else
            return func(target)
        end
    end
    local function create_change_event(...)
        local callbacks = setmetatable({}, {__mode = "k"})
        local params = {...}
        local event = {}
        function event.dispatcher(target)
            if not callbacks[target] then
                return
            end

            local current = {}
            for _, p in ipairs(params) do
                current[p.name] = get_event_value(target, p.get)
            end
            for _, cb in ipairs(callbacks[target].order) do

                local called = false
                for k, v in pairs(current) do
                    if current[k] ~= callbacks[target].history[cb][k] then
                        cb(target, unpack_arguments(callbacks[target].history[cb], table.unpack(params)))
                        called = true
                        goto continue
                    end
                end
                ::continue::

                for _, p in ipairs(params) do
                    current[p.name] = get_event_value(target, p.get)
                end


                if called then
                    callbacks[target].history[cb] = utils.copy_table(current)
                end
            end
        end
        function event.add(target, callback, initial)
            callbacks[target] = callbacks[target] or {order = {}, history = {}}
            local history = {}
            for _, p in ipairs(params) do
                if initial then
                    if type(p.initial) == "function" then
                        history[p.name] = p.initial(target)
                    else
                        history[p.name] = p.initial
                    end
                else
                    history[p.name] = get_event_value(target, p.get)
                end
            end
            callbacks[target].history[callback] = history
            table.insert(callbacks[target].order, callback)
        end
        function event.remove(target, callback)
            if not callbacks[target] then
                return
            end
            callbacks[target].history[callback] = nil
            table.insert(callbacks[target].order, callback)
        end
        function event.callback_exists(target, callback)
            return callbacks[target] and callbacks[target].history[callback] and true or false
        end
        function event.has_callbacks(target)
            return callbacks[target] and #callbacks[target].order > 0 or false
        end

        function event.history_iterator(control)
            local cb = callbacks[control]
            if not cb or #cb.order == 0 then
                return function()
                    return nil
                end
            end
            local i = 0
            local iterator = function()
                i = i + 1
                if not cb.order[i] then
                    return nil
                end
                return cb.history[cb.order[i]]
            end
            return iterator
        end
        function event.target_iterator()
            return utils.iterate_keys(callbacks)
        end
        return event
    end

    function mixin_helper.create_custom_control_change_event(...)
        local event = create_change_event(...)
        local windows = setmetatable({}, {__mode = "k"})
        local queued = setmetatable({}, {__mode = "k"})
        local function init_window(window)
            if windows[window] then
                return
            end
            window:AddInitWindow(
                function()

                    for control in event.target_iterator() do
                        event.dispatcher(control)
                    end
                end)
            window:AddHandleCommand(event.dispatcher)
        end
        local function add_func(self, callback)
            mixin_helper.assert_argument_type(2, callback, "function")
            local window = self:GetParent()
            mixin_helper.assert(window, "Cannot add handler to self with no parent window.")
            mixin_helper.assert(
                (window.MixinBase or window.MixinClass) == "FCMCustomLuaWindow",
                "Handlers can only be added if parent window is an instance of FCMCustomLuaWindow")
            mixin_helper.force_assert(
                not event.callback_exists(self, callback), "The callback has already been added as a handler.")
            init_window(window)
            event.add(self, callback, not window:WindowExists_())
        end
        local function remove_func(self, callback)
            mixin_helper.assert_argument_type(2, callback, "function")
            event.remove(self, callback)
        end
        local function trigger_helper(control)
            if not event.has_callbacks(control) or queued[control] then
                return
            end
            local window = control:GetParent()
            if window:WindowExists_() then
                window:QueueHandleCustom(
                    function()
                        queued[control] = nil
                        event.dispatcher(control)
                    end)
                queued[control] = true
            end
        end



        local function trigger_func(control, immediate)
            if type(control) == "boolean" and control then
                for ctrl in event.target_iterator() do
                    if immediate then
                        event.dispatcher(ctrl)
                    else
                        trigger_helper(ctrl)
                    end
                end
            else
                if immediate then
                    event.dispatcher(control)
                else
                    trigger_helper(control)
                end
            end
        end
        return add_func, remove_func, trigger_func, event.history_iterator
    end

    function mixin_helper.create_custom_window_change_event(...)
        local event = create_change_event(...)
        local queued = setmetatable({}, {__mode = "k"})
        local function add_func(self, callback)
            mixin_helper.assert_argument_type(1, self, "FCMCustomLuaWindow")
            mixin_helper.assert_argument_type(2, callback, "function")
            mixin_helper.force_assert(
                not event.callback_exists(self, callback), "The callback has already been added as a handler.")
            event.add(self, callback)
        end
        local function remove_func(self, callback)
            mixin_helper.assert_argument_type(2, callback, "function")
            event.remove(self, callback)
        end
        local function trigger_helper(window)
            if not event.has_callbacks(window) or queued[window] or not window:WindowExists_() then
                return
            end
            window:QueueHandleCustom(
                function()
                    queued[window] = nil
                    event.dispatcher(window)
                end)
            queued[window] = true
        end
        local function trigger_func(window, immediate)
            if type(window) == "boolean" and window then
                for win in event.target_iterator() do
                    if immediate then
                        event.dispatcher(window)
                    else
                        trigger_helper(window)
                    end
                end
            else
                if immediate then
                    event.dispatcher(window)
                else
                    trigger_helper(window)
                end
            end
        end
        return add_func, remove_func, trigger_func, event.history_iterator
    end

    function mixin_helper.to_fcstring(value, fcstr)
        if mixin_helper.is_instance_of(value, "FCString") then
            return value
        end
        fcstr = fcstr or finale.FCString()
        fcstr.LuaString = tostring(value)
        return fcstr
    end

    function mixin_helper.boolean_to_error(object, method, ...)
        if not object[method .. "_"](object, ...) then
            error("'" .. object.MixinClass .. "." .. method .. "' has encountered an error.", 3)
        end
    end
    return mixin_helper
end
package.preload["mixin.__FCMUserWindow"] = package.preload["mixin.__FCMUserWindow"] or function()



    local mixin = require("library.mixin")
    local mixin_helper = require("library.mixin_helper")
    local meta = {}
    local public = {}
    local temp_str = finale.FCString()

    function public:GetTitle(title)
        mixin_helper.assert_argument_type(2, title, "nil", "FCString")
        local do_return = false
        if not title then
            title = temp_str
            do_return = true
        end
        self:GetTitle_(title)
        if do_return then
            return title.LuaString
        end
    end

    function public:SetTitle(title)
        mixin_helper.assert_argument_type(2, title, "string", "number", "FCString")
        self:SetTitle_(mixin_helper.to_fcstring(title, temp_str))
    end
    return {meta, public}
end
package.preload["library.mixin"] = package.preload["library.mixin"] or function()





    local utils = require("library.utils")
    local library = require("library.general_library")


    local mixin_public = {}

    local mixin_private = {}

    local mixin_classes = {}

    local mixin_props = setmetatable({}, {__mode = "k"})


    local reserved_props = {
        MixinReady = function(class) return true end,
        MixinClass = function(class) return class end,
        MixinParent = function(class) return mixin_classes[class].meta.Parent end,
        MixinBase = function(class) return mixin_classes[class].meta.Base end,
        Init = function(class) return mixin_classes[class].meta.Init end,
    }


    local mixin = setmetatable({}, {
        __newindex = function(t, k, v) end,
        __index = function(t, k)
            if mixin_public[k] then return mixin_public[k] end

            mixin_private.load_mixin_class(k)
            if not mixin_classes[k] then return nil end


            mixin_public[k] = setmetatable({}, {
                __newindex = function(tt, kk, vv) end,
                __index = function(tt, kk)
                    local val = reserved_props[kk] and utils.copy_table(reserved_props[kk](k)) or utils.copy_table(mixin_classes[k].public[kk])
                    if type(val) == "function" then
                        val = mixin_private.create_fluid_proxy(val, kk)
                    end
                    return val
                end,
                __call = function(_, ...)
                    if mixin_private.is_fcm_class_name(k) then
                        return mixin_private.create_fcm(k, ...)
                    else
                        return mixin_private.create_fcx(k, ...)
                    end
                end
            })

            return mixin_public[k]
        end
    })


    function mixin_private.is_fc_class_name(class_name)
        return type(class_name) == "string" and not mixin_private.is_fcm_class_name(class_name) and not mixin_private.is_fcx_class_name(class_name) and (class_name:match("^FC%u") or class_name:match("^__FC%u")) and true or false
    end

    function mixin_private.is_fcm_class_name(class_name)
        return type(class_name) == "string" and (class_name:match("^FCM%u") or class_name:match("^__FCM%u")) and true or false
    end

    function mixin_private.is_fcx_class_name(class_name)
        return type(class_name) == "string" and class_name:match("^FCX%u") and true or false
    end

    function mixin_private.fcm_to_fc_class_name(class_name)
        return string.gsub(class_name, "FCM", "FC", 1)
    end

    function mixin_private.fc_to_fcm_class_name(class_name)
        return string.gsub(class_name, "FC", "FCM", 1)
    end

    function mixin_private.assert_valid_property_name(name, error_level, suffix)
        if type(name) ~= "string" then
            return
        end

        suffix = suffix or ""

        if name:sub(-1) == "_" then
            error("Mixin methods and properties cannot end in an underscore" .. suffix, error_level)
        elseif name:sub(1, 5):lower() == "mixin" then
            error("Mixin methods and properties beginning with 'Mixin' are reserved" .. suffix, error_level)
        elseif reserved_props[name] then
            error("'" .. name .. "' is a reserved name and cannot be used for propertiea or methods" .. suffix, error_level)
        end
    end


    function mixin_private.try_load_module(name)
        local success, result = pcall(function(c) return require(c) end, name)


        if not success and not result:match("module '[^']-' not found") then
            error(result, 0)
        end

        return success, result
    end


    function mixin_private.load_mixin_class(class_name)
        if mixin_classes[class_name] then return end

        local is_fcm = mixin_private.is_fcm_class_name(class_name)
        local is_fcx = mixin_private.is_fcx_class_name(class_name)


        local success, result = mixin_private.try_load_module("personal_mixin." .. class_name)

        if not success then
            success, result = mixin_private.try_load_module("mixin." .. class_name)
        end

        if not success then

            if is_fcm and finale[mixin_private.fcm_to_fc_class_name(class_name)] then
                result = {{}, {}}
            else
                return
            end
        end


        if type(result) ~= "table" then
            error("Mixin '" .. class_name .. "' is not a table.", 0)
        end

        local class = {}
        if #result > 1 then
            class.meta = result[1]
            class.public = result[2]
        else

            class.public = result
            class.meta = {}
            class.meta.Parent = class.public.MixinParent
            class.meta.Init = class.public.Init
            class.public.MixinParent = nil
            class.public.Init = nil
        end


        for k, _ in pairs(class.public) do
            mixin_private.assert_valid_property_name(k, 0, " (" .. class_name .. "." .. k .. ")")
        end


        if class.meta.Init and type(class.meta.Init) ~= "function" then
            error("Mixin meta-method 'Init' must be a function (" .. class_name .. ")", 0)
        end


        if is_fcm then

            class.meta.Parent = library.get_parent_class(mixin_private.fcm_to_fc_class_name(class_name))

            if class.meta.Parent then

                class.meta.Parent = mixin_private.fc_to_fcm_class_name(class.meta.Parent)

                mixin_private.load_mixin_class(class.meta.Parent)


                class.init = mixin_classes[class.meta.Parent].init and utils.copy_table(mixin_classes[class.meta.Parent].init) or {}

                if class.meta.Init then
                    table.insert(class.init, class.meta.Init)
                end



                for k, v in pairs(mixin_classes[class.meta.Parent].public) do
                    if type(class.public[k]) == "nil" then
                        class.public[k] = utils.copy_table(v)
                    end
                end
            end


        else

            if not class.meta.Parent then
                error("Mixin '" .. class_name .. "' does not have a parent class defined.", 0)
            end

            mixin_private.load_mixin_class(class.meta.Parent)


            if not mixin_classes[class.meta.Parent] then
                error("Unable to load mixin '" .. class.meta.Parent .. "' as parent of '" .. class_name .. "'", 0)
            end


            class.meta.Base = mixin_private.is_fcm_class_name(class.meta.Parent) and class.meta.Parent or mixin_classes[class.meta.Parent].meta.Base
        end


        class.meta.Class = class_name

        mixin_classes[class_name] = class
    end



    local function proxy(t, ...)
        local n = select("#", ...)

        if n == 0 then
            return t
        end


        for i = 1, n do
            mixin_private.enable_mixin(select(i, ...))
        end
        return ...
    end


    function mixin_private.create_fluid_proxy(func, func_name)
        return function(t, ...)
            return proxy(t, utils.call_and_rethrow(2, func, t, ...))
        end
    end


    function mixin_private.enable_mixin(object, fcm_class_name)
        if mixin_props[object] or not library.is_finale_object(object) then
            return object
        end

        mixin_private.apply_mixin_foundation(object)
        fcm_class_name = fcm_class_name or mixin_private.fc_to_fcm_class_name(library.get_class_name(object))

        mixin_private.load_mixin_class(fcm_class_name)
        mixin_props[object] = {MixinClass = fcm_class_name}

        for _, v in pairs(mixin_classes[fcm_class_name].init) do
            v(object)
        end

        return object
    end



    function mixin_private.apply_mixin_foundation(object)
        if not object or not library.is_finale_object(object) or object.MixinReady then return end


        local meta = getmetatable(object)


        local original_index = meta.__index
        local original_newindex = meta.__newindex

        local fcm_class_name = mixin_private.fc_to_fcm_class_name(library.get_class_name(object))

        meta.__index = function(t, k)


            if k == "MixinReady" then return true end


            if not mixin_props[t] then return original_index(t, k) end

            local prop


            if type(k) == "string" and k:sub(-1) == "_" then

                prop = original_index(t, k:sub(1, -2))


            elseif type(mixin_props[t][k]) ~= "nil" then
                prop = mixin_props[t][k]


            elseif type(mixin_classes[fcm_class_name].public[k]) ~= "nil" then
                prop = mixin_classes[fcm_class_name].public[k]


                if type(prop) == "table" then
                    mixin_props[t][k] = utils.copy_table(prop)
                    prop = mixin[t][k]
                end


            elseif reserved_props[k] then
                prop = reserved_props[k](mixin_props[t].MixinClass)


            else
                prop = original_index(t, k)
            end

            if type(prop) == "function" then
                return mixin_private.create_fluid_proxy(prop, k)
            else
                return prop
            end
        end



        meta.__newindex = function(t, k, v)

            if not mixin_props[t] then return utils.call_and_rethrow(2, original_newindex, t, k, v) end

            mixin_private.assert_valid_property_name(k, 3)

            local type_v_original = type(original_index(t, k))


            if type_v_original == "nil" then
                local type_v_mixin = type(mixin_props[t][k])
                local type_v = type(v)



                if type_v_mixin ~= "nil" then
                    if type_v == "function" and type_v_mixin ~= "function" then
                        error("A mixin method cannot be overridden with a property.", 2)
                    elseif type_v_mixin == "function" and type_v ~= "function" then
                        error("A mixin property cannot be overridden with a method.", 2)
                    end
                end

                mixin_props[t][k] = v


            elseif type_v_original == "function" then
                if type(v) ~= "function" then
                    error("A mixin method cannot be overridden with a property.", 2)
                end

                mixin_props[t][k] = v


            else
                utils.call_and_rethrow(2, original_newindex, t, k, v)
            end
        end
    end


    function mixin_private.subclass(object, class_name)
        if not library.is_finale_object(object) then
            error("Object is not a finale object.", 2)
        end

        if not utils.call_and_rethrow(2, mixin_private.subclass_helper, object, class_name) then
            error(class_name .. " is not a subclass of " .. object.MixinClass, 2)
        end

        return object
    end



    function mixin_private.subclass_helper(object, class_name, suppress_errors)
        if not object.MixinClass then
            if suppress_errors then
                return false
            end

            error("Object is not mixin-enabled.", 2)
        end

        if not mixin_private.is_fcx_class_name(class_name) then
            if suppress_errors then
                return false
            end

            error("Mixins can only be subclassed with an FCX class.", 2)
        end

        if object.MixinClass == class_name then return true end

        mixin_private.load_mixin_class(class_name)

        if not mixin_classes[class_name] then
            if suppress_errors then
                return false
            end

            error("Mixin '" .. class_name .. "' not found.", 2)
        end


        if mixin_private.is_fcm_class_name(mixin_classes[class_name].meta.Parent) and mixin_classes[class_name].meta.Parent ~= object.MixinClass then
            return false
        end


        if mixin_classes[class_name].meta.Parent ~= object.MixinClass then
            if not utils.call_and_rethrow(2, mixin_private.subclass_helper, object, mixin_classes[class_name].meta.Parent) then
                return false
            end
        end


        local props = mixin_props[object]
        props.MixinClass = class_name

        for k, v in pairs(mixin_classes[class_name].public) do
            props[k] = utils.copy_table(v)
        end


        if mixin_classes[class_name].meta.Init then
            utils.call_and_rethrow(2, mixin_classes[class_name].meta.Init, object)
        end

        return true
    end


    function mixin_private.create_fcm(class_name, ...)
        mixin_private.load_mixin_class(class_name)
        if not mixin_classes[class_name] then return nil end

        return mixin_private.enable_mixin(utils.call_and_rethrow(2, finale[mixin_private.fcm_to_fc_class_name(class_name)], ...))
    end


    function mixin_private.create_fcx(class_name, ...)
        mixin_private.load_mixin_class(class_name)
        if not mixin_classes[class_name] then return nil end

        local object = mixin_private.create_fcm(mixin_classes[class_name].meta.Base, ...)

        if not object then return nil end

        if not utils.call_and_rethrow(2, mixin_private.subclass_helper, object, class_name, false) then
            return nil
        end

        return object
    end


    mixin_public.is_fc_class_name = mixin_private.is_fc_class_name


    mixin_public.is_fcm_class_name = mixin_private.is_fcm_class_name


    mixin_public.is_fcx_class_name = mixin_private.is_fcx_class_name


    mixin_public.fc_to_fcm_class_name = mixin_private.fc_to_fcm_class_name


    mixin_public.fcm_to_fc_class_name = mixin_private.fcm_to_fc_class_name


    mixin_public.subclass = mixin_private.subclass


    function mixin_public.UI()
        return mixin_private.enable_mixin(finenv.UI(), "FCMUI")
    end


    function mixin_public.eachentry(region, layer)
        local measure = region.StartMeasure
        local slotno = region:GetStartSlot()
        local i = 0
        local layertouse = 0
        if layer ~= nil then layertouse = layer end
        local c = mixin.FCMNoteEntryCell(measure, region:CalcStaffNumber(slotno))
        c:SetLoadLayerMode(layertouse)
        c:Load()
        return function ()
            while true do
                i = i + 1;
                local returnvalue = c:GetItemAt(i - 1)
                if returnvalue ~= nil then
                    if (region:IsEntryPosWithin(returnvalue)) then return returnvalue end
                else
                    measure = measure + 1
                    if measure > region.EndMeasure then
                        measure = region.StartMeasure
                        slotno = slotno + 1
                        if (slotno > region:GetEndSlot()) then return nil end
                        c = mixin.FCMNoteEntryCell(measure, region:CalcStaffNumber(slotno))
                        c:SetLoadLayerMode(layertouse)
                        c:Load()
                        i = 0
                    else
                        c = mixin.FCMNoteEntryCell(measure, region:CalcStaffNumber(slotno))
                        c:SetLoadLayerMode(layertouse)
                        c:Load()
                        i = 0
                    end
                end
            end
        end
    end

    return mixin
end
function plugindef()
    finaleplugin.RequireSelection = false
    finaleplugin.NoStore = true
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0.1"
    finaleplugin.Date = "January 28, 2023"
    finaleplugin.CategoryTags = "Document"
    finaleplugin.MinJWLuaVersion = 0.63
    finaleplugin.Notes = [[
        This script encodes the current document to a utf-8 text file. The primary purpose is to find changes
        between one version of a document and another. One could then write each version out to a text file and
        use a comparison tool like kdiff3 to find differences. The text files could also be used to track changes with a tool like Git.
        The specifics of the shorthand for how the music is represented may not be that important.
        The idea is to identify the measures and staves that are different and then look at the score to see the differences.
        The following are encoded in such a way that if they are different, a comparison tool will flag them.
        - notes and rhythms
        - articulations
        - expressions (both text and shape)
        - ties
        - smart shapes
        - lyric assignments
        Chord symbols are currently not encoded, due to the lack of a simple way to generate a string for them. This is a needed
        future enhancement.
        The goal of this script is to assist in finding *substantive* differences that would affect how a player would play the piece.
        The script encodes the items above but not small engraving differences such as placement coordinates. One hopes, for example,
        that if there were a printed score that were out of date, this tool would flag the minimum number of changes that needed to
        be hand-corrected in the older score.
    ]]
    return "Save Document As Text File...", "", "Write current document to text file."
end
local library = require("library.general_library")
local text_extension = ".txt"
local note_entry = require('library.note_entry')
local expression = require('library.expression')
local enigma_string = require('library.enigma_string')
local mixin = require('library.mixin')
local fcstr = function(str)
    return mixin.FCMString():SetLuaString(str)
end
function do_save_as_dialog(document)
    local path_name = finale.FCString()
    local file_name = finale.FCString()
    local file_path = finale.FCString()
    document:GetPath(file_path)
    file_path:SplitToPathAndFile(path_name, file_name)
    local full_file_name = file_name.LuaString
    local extension = mixin.FCMString()
                            :SetLuaString(file_name.LuaString)
                            :ExtractFileExtension()
    if extension.Length > 0 then
        file_name:TruncateAt(file_name:FindLast("."..extension.LuaString))
    end
    file_name:AppendLuaString(text_extension)
    local save_dialog = mixin.FCMFileSaveAsDialog(finenv.UI())
            :SetWindowTitle(fcstr("Save "..full_file_name.." As"))
            :AddFilter(fcstr("*"..text_extension), fcstr("Text File"))
            :SetInitFolder(path_name)
            :SetFileName(file_name)
    save_dialog:AssureFileExtension(text_extension)
    if not save_dialog:Execute() then
        return nil
    end
    local selected_file_name = finale.FCString()
    save_dialog:GetFileName(selected_file_name)
    return selected_file_name.LuaString
end
local smart_shape_codes = {
    [finale.SMARTSHAPE_SLURDOWN] = "SD",
    [finale.SMARTSHAPE_SLURUP] = "SU",
    [finale.SMARTSHAPE_DIMINUENDO] = "DM",
    [finale.SMARTSHAPE_CRESCENDO] = "CR",
    [finale.SMARTSHAPE_OCTAVEDOWN ] = "8B",
    [finale.SMARTSHAPE_OCTAVEUP] = "8V",
    [finale.SMARTSHAPE_DASHLINEUP] = "DU",
    [finale.SMARTSHAPE_DASHLINEDOWN] = "DD",
    [finale.SMARTSHAPE_DASHCURVEDOWN] = "DCD",
    [finale.SMARTSHAPE_DASHCURVEUP] = "DCU",
    [finale.SMARTSHAPE_DASHLINE ] = "DL",
    [finale.SMARTSHAPE_SOLIDLINE] = "SL",
    [finale.SMARTSHAPE_SOLIDLINEDOWN] = "SLD",
    [finale.SMARTSHAPE_SOLIDLINEUP] = "SLU",
    [finale.SMARTSHAPE_TRILL] = "TR",
    [finale.SMARTSHAPE_SLURAUTO] = "SS",
    [finale.SMARTSHAPE_DASHCURVEAUTO] = "DC",
    [finale.SMARTSHAPE_TRILLEXT] = "TE",
    [finale.SMARTSHAPE_SOLIDLINEDOWN2] = "SLD2",
    [finale.SMARTSHAPE_SOLIDLINEUP2] = "SLU2",
    [finale.SMARTSHAPE_TWOOCTAVEDOWN] = "15B",
    [finale.SMARTSHAPE_TWOOCTAVEUP] = "15V",
    [finale.SMARTSHAPE_DASHLINEDOWN2] = "DLD2",
    [finale.SMARTSHAPE_DASHLINEUP2] = "DLU2",
    [finale.SMARTSHAPE_GLISSANDO] = "GL",
    [finale.SMARTSHAPE_TABSLIDE] = "TS",
    [finale.SMARTSHAPE_BEND_HAT] = "BH",
    [finale.SMARTSHAPE_BEND_CURVE] = "BC",
    [finale.SMARTSHAPE_CUSTOM] = "CU",
    [finale.SMARTSHAPE_SOLIDLINEUPLEFT] = "SLUL",
    [finale.SMARTSHAPE_SOLIDLINEDOWNLEFT] = "SLDL",
    [finale.SMARTSHAPE_DASHLINEUPLEFT ] = "DLUL",
    [finale.SMARTSHAPE_DASHLINEDOWNLEFT ] = "DLDL",
    [finale.SMARTSHAPE_SOLIDLINEUPDOWN ] = "SLUD",
    [finale.SMARTSHAPE_SOLIDLINEDOWNUP] = "SLDU",
    [finale.SMARTSHAPE_DASHLINEUPDOWN] = "DLUD",
    [finale.SMARTSHAPE_DASHLINEDOWNUP] = "DLDU",
    [finale.SMARTSHAPE_HYPHEN] = "HY",
    [finale.SMARTSHAPE_WORD_EXT] = "WE",
    [finale.SMARTSHAPE_DASHEDSLURDOWN] = "DSD",
    [finale.SMARTSHAPE_DASHEDSLURUP] = "DSU",
    [finale.SMARTSHAPE_DASHEDSLURAUTO] = "DS"
}
function get_smartshape_string(smart_shape, beg_mark, end_mark)
    local desc = smart_shape_codes[smart_shape.ShapeType]
    if not desc then
        desc = "S"..tostring(smart_shape.ShapeType)
    end
    if smart_shape.ShapeType == finale.SMARTSHAPE_CUSTOM then
        desc = desc .. tostring(smart_shape.LineID)
    end
    if end_mark then
        desc = "<-" .. desc
    end
    if beg_mark then
        desc = desc .. "->"
    end
    return desc
end
local known_chars = {
    [0xe4a0] = ">",
    [0xe4a2] = ".",
}
function get_char_string(char)
    if known_chars[char] then
        return known_chars[char]
    end
    if char < 32 then
        return " "
    end
    return utf8.char(char)
end
function entry_string(entry)
    local retval = ""

    local articulations = entry:CreateArticulations()
    for articulation in each(articulations) do
        local articulation_def = articulation:CreateArticulationDef()
        if articulation_def.MainSymbolIsShape then
            retval = retval .. " sa" .. tostring(articulation_def.MainSymbolShapeID)
        else
            retval = retval .. " " .. get_char_string(articulation_def.MainSymbolChar)
        end
    end
    local smart_shape_marks = finale.FCSmartShapeEntryMarks(entry)
    local already_processed = {}
    if smart_shape_marks:LoadAll() then
        for mark in each(smart_shape_marks) do
            if not already_processed[mark.ShapeNumber] then
                already_processed[mark.ShapeNumber] = true
                local beg_mark = mark:CalcLeftMark()
                local end_mark = mark:CalcRightMark()
                if beg_mark or end_mark then
                    local smart_shape = mark:CreateSmartShape()
                    if not smart_shape:CalcLyricBased() then
                        retval = retval .. " " .. get_smartshape_string(smart_shape, beg_mark, end_mark)
                    end
                end
            end
        end
    end
    if entry:IsRest() then
        retval = retval .. " RR"
    else
        for note_index = 0,entry.Count-1 do
            local note = entry:GetItemAt(note_index)
            retval = retval .. " "
            if note.TieBackwards then
                retval = retval .. "<-"
            end
            retval = retval .. note_entry.calc_pitch_string(note).LuaString
            if note.Tie then
                retval = retval .. "->"
            end
        end
    end
    for _, syllables in ipairs({finale.FCVerseSyllables(entry), finale.FCChorusSyllables(entry), finale.FCSectionSyllables(entry)}) do
        if syllables:LoadAll() then
            for syllable in each(syllables) do
                local syllable_text = finale.FCString()
                if syllable:GetText(syllable_text) then
                    syllable_text:TrimEnigmaTags()
                    retval = retval .. " " .. syllable_text.LuaString
                end
            end
        end
    end
    return retval
end
local get_edupos_table = function(measure_table, staff_number, edupos)
    if not measure_table[staff_number] then
        measure_table[staff_number] = {}
    end
    local staff_table = measure_table[staff_number]
    if not staff_table[edupos] then
        staff_table[edupos] = {}
    end
    return staff_table[edupos]
end
function create_measure_table(measure_region, measure)
    local measure_table = {}

    local expression_assignments = measure:CreateExpressions()
    for expression_assignment in each(expression_assignments) do
        local staff_num = expression_assignment:CalcStaffInPageView()
        if staff_num > 0 then
            if expression.is_for_current_part(expression_assignment) and expression_assignment.Visible then
                local edupos_table = get_edupos_table(measure_table, staff_num, expression_assignment.MeasurePos)
                if not edupos_table.expressions then
                    edupos_table.expressions = {}
                end
                if expression_assignment.Shape then
                    local shapeexp_def = expression_assignment:CreateShapeExpressionDef()
                    table.insert(edupos_table.expressions, " Shape "..tostring(shapeexp_def.ID))
                else
                    local textexp_def = expression_assignment:CreateTextExpressionDef()
                    local exp_text = textexp_def:CreateTextString()
                    enigma_string.expand_value_tag(exp_text, textexp_def:GetPlaybackTempoValue())
                    exp_text:TrimEnigmaTags()
                    table.insert(edupos_table.expressions, " " .. exp_text.LuaString)
                end
            end
        end
    end
    local smart_shape_marks = finale.FCSmartShapeMeasureMarks()
    local already_processed = {}
    if smart_shape_marks:LoadAllForRegion(measure_region) then
        for mark in each(smart_shape_marks) do
            local smart_shape = mark:CreateSmartShape()
            if smart_shape and not already_processed[smart_shape.ShapeNumber] and not smart_shape.EntryBased and not smart_shape:CalcLyricBased() then
                already_processed[mark.ShapeNumber] = true
                local lterm = smart_shape:GetTerminateSegmentLeft()
                local rterm = smart_shape:GetTerminateSegmentRight()
                local beg_mark = lterm.Measure == measure.ItemNo
                local end_mark = lterm.Measure == measure.ItemNo
                if beg_mark or end_mark then
                    if beg_mark then
                        local edupos_table = get_edupos_table(measure_table, lterm.Staff, lterm.MeasurePos)
                        if not edupos_table.smartshapes then
                            edupos_table.smartshapes = {}
                        end
                        local left_and_right = end_mark and rterm.Staff == lterm.Staff and rterm.Measure == lterm.Measure and rterm.MeasurePos == lterm.MeasurePos
                        local desc = get_smartshape_string(smart_shape, true, left_and_right)
                        if desc then
                            table.insert(edupos_table.smartshapes, " " .. desc)
                        end
                        if left_and_right then
                            end_mark = false
                        end
                    end
                    if end_mark then

                        local edupos_table = get_edupos_table(measure_table, rterm.Staff, rterm.MeasurePos)
                        if not edupos_table.smartshapes then
                            edupos_table.smartshapes = {}
                        end
                        local desc = get_smartshape_string(smart_shape, false, true)
                        if desc then
                            table.insert(edupos_table.smartshapes, " " .. desc)
                        end
                    end
                end
            end
        end
    end
    for entry in eachentry(measure_region) do
        local edupos_table = get_edupos_table(measure_table, entry.Staff, entry.MeasurePos)
        if not edupos_table.entries then
            edupos_table.entries = {}
        end
        table.insert(edupos_table.entries, entry_string(entry))
    end
    return measure_table
end
function write_measure(file, measure, measure_number_regions)
    local display_text = finale.FCString()
    local region_number = measure_number_regions:CalcStringFromNumber(measure.ItemNo, display_text)
    if region_number < 0 then
        display_text.LuaString = "#"..tostring(measure.ItemNo)
    end
    file:write("\n")
    file:write("Measure ", measure.ItemNo, " [", display_text.LuaString, "]\n")
    local measure_region = finale.FCMusicRegion()
    measure_region:SetFullDocument()
    measure_region.StartMeasure = measure.ItemNo
    measure_region.EndMeasure = measure.ItemNo
    local measure_table = create_measure_table(measure_region, measure)
    for slot = 1, measure_region.EndSlot do
        local staff_number = measure_region:CalcStaffNumber(slot)
        local staff_table = measure_table[staff_number]
        if staff_table then
            local staff = finale.FCCurrentStaffSpec()
            local staff_name = ""
            if staff:LoadForCell(finale.FCCell(measure.ItemNo, staff_number), 0) then
                staff_name = staff:CreateDisplayFullNameString().LuaString
            end
            if staff_name == "" then
                staff_name = "Staff " .. staff_number
            end
            file:write("  ", staff_name, ":")
            for edupos, edupos_table in pairsbykeys(staff_table) do
                file:write(" ["..tostring(edupos).."]")

                if edupos_table.smartshapes then
                    for _, ss_string in ipairs(edupos_table.smartshapes) do
                        file:write(ss_string)
                    end
                end
                if edupos_table.expressions then
                    for _, exp_string in ipairs(edupos_table.expressions) do
                        file:write(exp_string)
                    end
                end
                if edupos_table.entries then
                    for _, entry_string in ipairs(edupos_table.entries) do
                        file:write(entry_string)
                    end
                end
            end
            file:write("\n")
        end
    end
end
function document_save_as_text()
    local documents = finale.FCDocuments()
    documents:LoadAll()
    local document = documents:FindCurrent()
    local file_to_write = do_save_as_dialog(document)
    if not file_to_write then
        return
    end
    local file = io.open(file_to_write, "w")
    if not file then
        finenv.UI():AlertError("Unable to open " .. file_to_write .. ". Please check folder permissions.", "")
        return
    end
    local score_part = nil
    if not library.get_current_part():IsScore() then
        score_part = library.get_score()
        score_part:SwitchTo()
    end


    local document_path = finale.FCString()
    document:GetPath(document_path)
    file:write("Script document_save_as_text.lua version ", finaleplugin.Version, "\n")
    file:write(document_path.LuaString, "\n")
    file:write("Saving as ", file_to_write, "\n")
    local measure_number_regions = finale.FCMeasureNumberRegions()
    measure_number_regions:LoadAll()
    for measure in loadall(finale.FCMeasures()) do
        write_measure(file, measure, measure_number_regions)
    end
    file:close()
    if score_part then
        score_part:SwitchBack()
    end
end
document_save_as_text()
