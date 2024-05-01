function plugindef()
    finaleplugin.MinJWLuaVersion = 0.74
    finaleplugin.NoStore = false -- With RGP Lua 0.74 and higher, setting this to true causes all changes to rollback.
    finaleplugin.HandlesUndo = true -- A true value here does not suppress the automatic Undo logic in FCDocument.
    finaleplugin.Notes = [[
        This script demonstrates how to process all open documents. The SwitchTo/SwitchBack functions automatically
        manage the Undo blocks per document, based on the NoStore setting.
    ]]
    return "0--process_all_documents.lua"
end

local shift_amount = 144

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
    doc:SwitchTo(finale.FCString(file_name() .. " " .. doc.ID), false)
    local region = finale.FCMusicRegion()
    region:SetFullDocument()
    for entry in eachentrysaved(region) do
        entry.ManualPosition = entry.ManualPosition + shift_amount
    end
    if not finaleplugin.NoStore then
        region:Redraw() -- do not call Redraw when using NoStore, or you can get confusing visible artifacts.
    end
    doc:SwitchBack(true) -- true: changes successful (will be saved unless NoStore is true)
end
