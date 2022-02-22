--[[
$module FCMStrings
]]

local mixin = require("library.mixin")

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
    mixin.assert_argument(str, {"string", "number", "FCString"}, 2)

    if type(str) ~= "userdata" then
        temp_str.LuaString = tostring(str)
        str = temp_str
    end

    return self:AddCopy_(str)
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
    mixin.assert_argument(str, {"string", "number", "FCString"}, 2)

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
    mixin.assert_argument(str, {"string", "number", "FCString"}, 2)

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
    mixin.assert_argument(folderstring, {"string", "FCString"}, 2)

    if type(str) ~= "userdata" then
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
    mixin.assert_argument(folderstring, {"string", "FCString"}, 2)

    if type(str) ~= "userdata" then
        temp_str.LuaString = tostring(folderstring)
        folderstring = temp_str
    end

    return self:LoadSubfolders_(folderstring)
end

--[[
% InsertStringAt

**[Fluid] [Override]**
Accepts Lua `string` and `number` in addition to `FCString`.

@ self (FCMStrings)
@ str (FCString|string|number)
@ index (number)
]]
if finenv.MajorVersion > 0 or finenv.MinorVersion >= 59 then
    function props:InsertStringAt(str, index)
        mixin.assert_argument(str, {"string", "number", "FCString"}, 2)
        mixin.assert_argument(index, "number", 3)

        if type(str) ~= "userdata" then
            temp_str.LuaString = tostring(str)
            str = temp_str
        end

        self:InsertStringAt_(str, index)
    end
end


return props