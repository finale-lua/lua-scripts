--  Author: Edward Koltun
--  Date: March 3, 2022
--[[
$module FCMStrings

## Summary of Modifications
- Setters that accept `FCString` also accept a Lua `string`.
- Methods that returned a boolean to indicate success/failure now throw an error instead.
- Added polyfill for `CopyFromStringTable`.
- Added `CreateStringTable` method.
]] --
local mixin = require("library.mixin")
local mixin_helper = require("library.mixin_helper")

local class = {Methods = {}}
local methods = class.Methods

local temp_str = finale.FCString()

--[[
% AddCopy

**[Breaking Change] [Fluid] [Override]**

Override Changes:
- Accepts Lua `string` and `number` in addition to `FCString`.
- Throws an error instead of returning a boolean for success/failure.

@ self (FCMStrings)
@ str (FCString | string | number)
]]
function methods:AddCopy(str)
    mixin_helper.assert_argument_type(2, str, "string", "number", "FCString")

    mixin_helper.boolean_to_error(self, "AddCopy", mixin_helper.to_fcstring(str, temp_str))
end

--[[
% AddCopies

Same as `AddCopy`, but accepts multiple arguments so that multiple values can be added at a time.

@ self (FCMStrings)
@ ... (FCStrings | FCString | string | number) `number`s will be cast to `string`
]]
function methods:AddCopies(...)
    for i = 1, select("#", ...) do
        local v = select(i, ...)
        mixin_helper.assert_argument_type(i + 1, v, "FCStrings", "FCString", "string", "number")
        if mixin_helper.is_instance_of(v, "FCStrings") then
            for str in each(v) do
                self:AddCopy__(str)
            end
        else
            mixin.FCStrings.AddCopy(self, v)
        end
    end
end

--[[
% Find

**[Override]**

Override Changes:
- Accepts Lua `string` and `number` in addition to `FCString`.

@ self (FCMStrings)
@ str (FCString | string | number)
: (FCMString | nil)
]]
function methods:Find(str)
    mixin_helper.assert_argument_type(2, str, "string", "number", "FCString")

    return self:Find_(mixin_helper.to_fcstring(str, temp_str))
end

--[[
% FindNocase

**[Override]**

Override Changes:
- Accepts Lua `string` and `number` in addition to `FCString`.

@ self (FCMStrings)
@ str (FCString | string | number)
: (FCMString | nil)
]]
function methods:FindNocase(str)
    mixin_helper.assert_argument_type(2, str, "string", "number", "FCString")

    return self:FindNocase__(mixin_helper.to_fcstring(str, temp_str))
end

--[[
% LoadFolderFiles

**[Breaking Change] [Fluid] [Override]**

Override Changes:
- Accepts Lua `string` in addition to `FCString`.
- Throws an error instead of returning a boolean for success/failure.

@ self (FCMStrings)
@ folderstring (FCString | string)
]]
function methods:LoadFolderFiles(folderstring)
    mixin_helper.assert_argument_type(2, folderstring, "string", "FCString")

    mixin_helper.boolean_to_error(self, "LoadFolderFiles", mixin_helper.to_fcstring(folderstring, temp_str))
end

--[[
% LoadSubfolders

**[Breaking Change] [Fluid] [Override]**

Override Changes:
- Accepts Lua `string` in addition to `FCString`.
- Throws an error instead of returning a boolean for success/failure.

@ self (FCMStrings)
@ folderstring (FCString | string)
]]
function methods:LoadSubfolders(folderstring)
    mixin_helper.assert_argument_type(2, folderstring, "string", "FCString")

    mixin_helper.boolean_to_error(self, "LoadSubfolders", mixin_helper.to_fcstring(folderstring, temp_str))
end

--[[
% LoadSymbolFonts

**[Breaking Change] [Fluid] [Override]**

Override Changes:
- Throws an error instead of returning a boolean for success/failure.

@ self (FCMStrings)
]]
function methods:LoadSymbolFonts()
    mixin_helper.boolean_to_error(self, "LoadSymbolFonts")
end

--[[
% LoadSystemFontNames

**[Breaking Change] [Fluid] [Override]**

Override Changes:
- Throws an error instead of returning a boolean for success/failure.

@ self (FCMStrings)
]]
function methods:LoadSystemFontNames()
    mixin_helper.boolean_to_error(self, "LoadSystemFontNames")
end

--[[
% InsertStringAt

**[>= v0.59] [Fluid] [Override]**

Override Changes:
- Accepts Lua `string` and `number` in addition to `FCString`.

@ self (FCMStrings)
@ str (FCString | string | number)
@ index (number)
]]
if finenv.MajorVersion > 0 or finenv.MinorVersion >= 59 then
    function methods:InsertStringAt(str, index)
        mixin_helper.assert_argument_type(2, str, "string", "number", "FCString")
        mixin_helper.assert_argument_type(3, index, "number")

        self:InsertStringAt__(mixin_helper.to_fcstring(str, temp_str), index)
    end
end

--[[
% CopyFromStringTable

**[Fluid] [Polyfill]**

Polyfills `FCStrings.CopyFromStringTable` for earlier RGP/JWLua versions.

*Note: This method can also be called statically with a non-mixin `FCStrings` object.*

@ self (FCMStrings | FCStrings)
@ strings (table)
]]
function methods:CopyFromStringTable(strings)
    mixin_helper.assert_argument_type(2, strings, "table")

    local suffix = self.MixinClass and "__" or ""

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

--[[
% CreateStringTable

Creates a table of Lua `string`s from the `FCString`s in this collection.

*Note: This method can also be called statically with a non-mixin `FCStrings` object.*

@ self (FCMStrings | FCStrings)
: (table)
]]
function methods:CreateStringTable()
    local t = {}
    for str in each(self) do
        table.insert(t, str.LuaString)
    end
    return t
end

return class
