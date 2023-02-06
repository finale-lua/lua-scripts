--  Author: Edward Koltun
--  Date: March 3, 2022
--[[
$module FCMStrings

Summary of modifications:
- Methods that accept `FCString` now also accept Lua `string` and `number` (except for folder loading methods which do not accept `number`).
- Setters that accept `FCStrings` now also accept multiple arguments of `FCString`, Lua `string`, or `number`.
]] --
local mixin = require("library.mixin")
local mixin_helper = require("library.mixin_helper")
local library = require("library.general_library")

local props = {}

local temp_str = finale.FCString()

--[[
% AddCopy

**[Override]**
Accepts Lua `string` and `number` in addition to `FCString`.

@ self (FCMStrings)
@ str (FCString|string|number)
: (boolean) True on success.
]]
function props:AddCopy(str)
    mixin_helper.assert_argument_type(2, str, "string", "number", "FCString")

    if type(str) ~= "userdata" then
        temp_str.LuaString = tostring(str)
        str = temp_str
    end

    return self:AddCopy_(str)
end

--[[
% AddCopies

**[Override]**
Same as `AddCopy`, but accepts multiple arguments so that multiple strings can be added at a time.

@ self (FCMStrings)
@ ... (FCStrings|FCString|string|number) `number`s will be cast to `string`
: (boolean) `true` if successful
]]
function props:AddCopies(...)
    for i = 1, select("#", ...) do
        local v = select(i, ...)
        mixin_helper.assert_argument_type(i + 1, v, "FCStrings", "FCString", "string", "number")
        if type(v) == "userdata" and v:ClassName() == "FCStrings" then
            for str in each(v) do
                v:AddCopy_(str)
            end
        else
            mixin.FCStrings.AddCopy(self, v)
        end
    end

    return true
end

--[[
% CopyFrom

**[Override]**
Accepts multiple arguments.

@ self (FCMStrings)
@ ... (FCStrings|FCString|string|number) `number`s will be cast to `string`
: (boolean) `true` if successful
]]
function props:CopyFrom(...)
    local num_args = select("#", ...)
    local first = select(1, ...)
    mixin_helper.assert_argument_type(2, first, "FCStrings", "FCString", "string", "number")

    if library.is_finale_object(first) and first:ClassName() == "FCStrings" then
        self:CopyFrom_(first)
    else
        self:ClearAll_()
        mixin.FCMStrings.AddCopy(self, first)
    end

    for i = 2, num_args do
        local v = select(i, ...)
        mixin_helper.assert_argument_type(i + 1, v, "FCStrings", "FCString", "string", "number")

        if type(v) == "userdata" then
            if v:ClassName() == "FCString" then
                self:AddCopy_(v)
            elseif v:ClassName() == "FCStrings" then
                for str in each(v) do
                    v:AddCopy_(str)
                end
            end
        else
            temp_str.LuaString = tostring(v)
            self:AddCopy_(temp_str)
        end
    end

    return true
end

--[[
% Find

**[Override]**
Accepts Lua `string` and `number` in addition to `FCString`.

@ self (FCMStrings)
@ str (FCString|string|number)
: (FCMString|nil)
]]
function props:Find(str)
    mixin_helper.assert_argument_type(2, str, "string", "number", "FCString")

    if type(str) ~= "userdata" then
        temp_str.LuaString = tostring(str)
        str = temp_str
    end

    return self:Find_(str)
end

--[[
% FindNocase

**[Override]**
Accepts Lua `string` and `number` in addition to `FCString`.

@ self (FCMStrings)
@ str (FCString|string|number)
: (FCMString|nil)
]]
function props:FindNocase(str)
    mixin_helper.assert_argument_type(2, str, "string", "number", "FCString")

    if type(str) ~= "userdata" then
        temp_str.LuaString = tostring(str)
        str = temp_str
    end

    return self:FindNocase_(str)
end

--[[
% LoadFolderFiles

**[Override]**
Accepts Lua `string` in addition to `FCString`.

@ self (FCMStrings)
@ folderstring (FCString|string)
: (boolean) True on success.
]]
function props:LoadFolderFiles(folderstring)
    mixin_helper.assert_argument_type(2, folderstring, "string", "FCString")

    if type(folderstring) ~= "userdata" then
        temp_str.LuaString = tostring(folderstring)
        folderstring = temp_str
    end

    return self:LoadFolderFiles_(folderstring)
end

--[[
% LoadSubfolders

**[Override]**
Accepts Lua `string` in addition to `FCString`.

@ self (FCMStrings)
@ folderstring (FCString|string)
: (boolean) True on success.
]]
function props:LoadSubfolders(folderstring)
    mixin_helper.assert_argument_type(2, folderstring, "string", "FCString")

    if type(folderstring) ~= "userdata" then
        temp_str.LuaString = tostring(folderstring)
        folderstring = temp_str
    end

    return self:LoadSubfolders_(folderstring)
end

--[[
% InsertStringAt

**[>= v0.59] [Fluid] [Override]**
Accepts Lua `string` and `number` in addition to `FCString`.

@ self (FCMStrings)
@ str (FCString|string|number)
@ index (number)
]]
if finenv.MajorVersion > 0 or finenv.MinorVersion >= 59 then
    function props:InsertStringAt(str, index)
        mixin_helper.assert_argument_type(2, str, "string", "number", "FCString")
        mixin_helper.assert_argument_type(3, index, "number")

        if type(str) ~= "userdata" then
            temp_str.LuaString = tostring(str)
            str = temp_str
        end

        self:InsertStringAt_(str, index)
    end
end

return props
