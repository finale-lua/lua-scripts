function plugindef()
    finaleplugin.RequireDocument = false
    finaleplugin.MinJWLuaVersion = 0.74
    -- A true value of NoStore causes all changes to be rolled back and prevents FCDocument instances from being saved.
    finaleplugin.NoStore = false
    -- A true value of HandlesUndo does not prevent the automatic Undo logic in FCDocument/FCLuaIterator from saving changes,
    -- but it prevents other changes that are not protected by an explicit call to StartNewUndoBlock.
    finaleplugin.HandlesUndo = false
    finaleplugin.Notes = [[
        This script demonstrates how to process all open documents or batch process a list of files with an iterator.
        The SwitchTo/SwitchBack functions automatically manage the Undo blocks per document, based on the NoStore
        and HandlesUndo settings. For versions of RGP Lua before 0.74, the Undo handling is not as consistent, and neither
        FCLuaIterator nor FCDocument know about the NoStore or HandlesUndo settings.
    ]]
    return "0--process_all_documents.lua"
end

local shift_amount = 144
local use_iterator = false
local use_files = false
local files = (function()
    local retval = finale.FCStrings()
    local homepath = finale.FCString()
    homepath:SetUserPath()
    homepath:AssureEndingPathDelimiter()
    for _, filename in ipairs({ "Desktop/1.musx", "Desktop/2.musx" }) do
        local result = finale.FCString(homepath.LuaString .. filename)
        retval:AddCopy(result)
    end
    return retval
end)()

local function file_name()
    local fpath = finale.FCString()
    fpath.LuaString = finenv.RunningLuaFilePath()
    local fname = finale.FCString()
    fpath:SplitToPathAndFile(nil, fname)
    return fname.LuaString
end

local function process_document_with_name(doc, filepath)
    local region = finale.FCMusicRegion()
    region:SetFullDocument()
    for entry in eachentrysaved(region) do
        entry.ManualPosition = entry.ManualPosition + shift_amount
    end
    if not finaleplugin.NoStore then
        region:Redraw() -- do not call Redraw when using NoStore, or you can get confusing visible artifacts.
    end
    local filename = finale.FCString()
    filepath:SplitToPathAndFile(nil, filename)
    print("processed " .. filename.LuaString .. " [" .. doc.ID .. "]")
end

local function process_document(doc)
    local filepath = finale.FCString()
    doc:GetPath(filepath)
    process_document_with_name(doc, filepath)
end

local function move_expression_baseline()
    local baselines = finale.FCBaselines()
    baselines:LoadAllForPiece(finale.BASELINEMODE_EXPRESSIONABOVE)
    local baseline = baselines:AssureSavedStaffForPiece(finale.BASELINEMODE_EXPRESSIONABOVE, 1)
    if baseline then
        baseline.VerticalOffset = baseline.VerticalOffset + 24
        baseline:Save()
    end
end

-- this change is suppressed if either NoStore or HandlesUndo is true
-- otherwise, it creates a separate undo entry
move_expression_baseline()

if use_iterator then
    local iterator = finale.FCLuaIterator()
    if use_files then
        iterator:ForEachFileSaved(files, process_document_with_name)
    else
        iterator:ForEachDocument(process_document)
    end
else
    local docs = finale.FCDocuments()
    local count = docs:LoadAll()
    print("got " .. count .. " documents")
    for doc in each(docs) do
        doc:SwitchTo(finale.FCString(file_name() .. " " .. doc.ID), true) -- true: save current changes (unless NoStore is true)
        process_document(doc)
        doc:SwitchBack(true) -- true: changes successful (will be saved unless NoStore is true)
    end
end

-- this change is suppressed if either NoStore or HandlesUndo is true
-- otherwise, it creates a separate undo entry
move_expression_baseline()
