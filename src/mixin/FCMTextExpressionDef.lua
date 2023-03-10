--  Author: Edward Koltun and Carl Vine
--  Date: 2023/02/07
--  Version: 0.06
--[[
$module FCMTextExpressionDef

## Summary of Modifications
- Setters that accept `FCString` also accept a Lua string.
- `FCString` parameter in getters is optional and if omitted, the result will be returned as a Lua `string`.
- Methods that returned a boolean to indicate success/failure now throw an error instead.
]] --

local mixin = require("library.mixin")
local mixin_helper = require("library.mixin_helper")

local meta = {}
local public = {}
local private = setmetatable({}, {__mode = "k"})

local temp_str = finale.FCString()


--[[
% SaveNewTextBlock

**[Breaking Change] [Fluid] [Override]**

Override Changes:
- Throws an error instead of returning a boolean for success/failure.
- Accepts Lua `string` in addition to `FCString`.

@ self (FCMTextExpressionDef)
@ str (string | FCString) The initializing string
]]

function public:SaveNewTextBlock(str)
    mixin_helper.assert_argument_type(2, str, "string", "FCString")

    str = mixin_helper.to_fcstring(str, temp_str)
    mixin_helper.boolean_to_error(self, "SaveNewTextBlock", str)
end

--[[
% AssignToCategory

**[Breaking Change] [Fluid] [Override]**

Override Changes:
- Throws an error instead of returning a boolean for success/failure.

@ self (FCMTextExpressionDef)
@ cat_def (FCCategoryDef) the parent Category Definition
]]

function public:AssignToCategory(cat_def)
    mixin_helper.assert_argument_type(2, cat_def, "FCCategoryDef")

    mixin_helper.boolean_to_error(self, "AssignToCategory", cat_def)
end

--[[
% SetUseCategoryPos

**[Breaking Change] [Fluid] [Override]**

Override Changes:
- Throws an error instead of returning a boolean for success/failure.

@ self (FCMTextExpressionDef)
@ enable (boolean)
]]

function public:SetUseCategoryPos(enable)
    mixin_helper.assert_argument_type(2, enable, "boolean")

    mixin_helper.boolean_to_error(self, "SetUseCategoryPos", enable)
end

--[[
% SetUseCategoryFont

**[Breaking Change] [Fluid] [Override]**

Override Changes:
- Throws an error instead of returning a boolean for success/failure.

@ self (FCMTextExpressionDef)
@ enable (boolean)
]]

function public:SetUseCategoryFont(enable)
    mixin_helper.assert_argument_type(2, enable, "boolean")

    mixin_helper.boolean_to_error(self, "SetUseCategoryFont", enable)
end

--[[
% MakeRehearsalMark

**[Breaking Change] [Fluid] [Override]**

Override Changes:
- Throws an error instead of returning a boolean for success/failure.
- Passing an `FCString` is optional. If omitted, the result is returned as a Lua `string`. If passed, nothing is returned and the method is fluid.

@ self (FCMTextExpressionDef)
@ [str] (FCString)
@ measure (integer)
: (string) If `FCString` is omitted.
]]

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

--[[
% SaveTextString

**[Breaking Change] [Fluid] [Override]**

Override Changes:
- Throws an error instead of returning a boolean for success/failure.
- Accepts Lua `string` in addition to `FCString`.

@ self (FCMTextExpressionDef)
@ str (string | FCString) The initializing string
]]

function public:SaveTextString(str)
    mixin_helper.assert_argument_type(2, str, "string", "FCString")

    str = mixin_helper.to_fcstring(str, temp_str)
    mixin_helper.boolean_to_error(self, "SaveTextString", str)
end


--[[
% DeleteTextBlock

**[Breaking Change] [Fluid] [Override]**

Override Changes:
- Throws an error instead of returning a boolean for success/failure.

@ self (FCMTextExpressionDef)
]]

function public:DeleteTextBlock()
    mixin_helper.boolean_to_error(self, "DeleteTextBlock")
end


--[[
% SetDescription

**[Breaking Change] [Fluid] [Override]**

Override Changes:
- Accepts Lua `string` in addition to `FCString`.

@ self (FCMTextExpressionDef)
@ str (string | FCString) The initializing string
]]

function public:SetDescription(str)
    mixin_helper.assert_argument_type(2, str, "string", "FCString")

    str = mixin_helper.to_fcstring(str, temp_str)
    self:SetDescription_(str)
end

--[[
% GetDescription

**[Breaking Change] [Fluid] [Override]**

Override Changes:
- Passing an `FCString` is optional. If omitted, the result is returned as a Lua `string`. If passed, nothing is returned and the method is fluid.

@ self (FCMTextExpressionDef)
@ [str] (FCString)
: (string) If `FCString` is omitted.
]]

function public:GetDescription(str)
    mixin_helper.assert_argument_type(2, str, "nil", "FCString")

    local do_return = not str
    str = str or temp_str
    self:GetDescription_(str)

    if do_return then
        return str.LuaString
    end
end

--[[
% DeepSaveAs

**[Breaking Change] [Fluid] [Override]**

Override Changes:
- Throws an error instead of returning a boolean for success/failure.

@ self (FCMTextExpressionDef)
@ item_num (integer)
]]

function public:DeepSaveAs(item_num)
    mixin_helper.assert_argument_type(2, item_num, "number")

    mixin_helper.boolean_to_error(self, "DeepSaveAs", item_num)
end

--[[
% DeepDeleteData

**[Breaking Change] [Fluid] [Override]**

Override Changes:
- Throws an error instead of returning a boolean for success/failure.

@ self (FCMTextExpressionDef)
]]

function public:DeepDeleteData()
    mixin_helper.boolean_to_error(self, "DeepDeleteData")
end


return {meta, public}
