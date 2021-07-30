function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Jacob Winkler" -- With help & advice from CJ Garcia, Nick Mazuk, and Jan Angermüller. Thanks guys!
    finaleplugin.Copyright = "©2019 Jacob Winkler"
    finaleplugin.AuthorEmail = "jacob.winkler@mac.com"
    finaleplugin.Version = "1.0"
    finaleplugin.Date = "11/02/2019"
    return "Cluster - Determinate", "Cluster - Determinate", "Creates a determinate cluster."
end

local region = finenv.Region()      
-- Setup arrays

local layer1note = {}
local layer2note = {}
--local staff = 0
local measure = {}
--
-- Stem variables
local stemDir = false
--
local horz_off = -20

-- FUNCTION 1: Delete and Hide Notes
local function ProcessNotes(music_region)
    local stem_dir = {}
    -- First build up a table of the initial stem direction information
    for entry in eachentrysaved(region) do
        entry.FreezeStem = false
        table.insert(stem_dir, entry:CalcStemUp())
        --entry.FreezeStem = true
    end -- end for entry
    --
    CopyLayer(1, 2)
    CopyLayer(1, 3)
    --
    local i = 1 -- To iterate stem direction table for Layer 1
    local j = 1 -- To iterate stem direction table for Layer 2
    local stemDir = stem_dir[i]
    --
  for noteentry in eachentrysaved(music_region) do
    --local highestnote = entry:CalcHighestNote(nil)
    --local lowestnote = entry:CalcLowestNote(nil)
    local span = noteentry:CalcDisplacementRange(nil)
    local stemDir = stem_dir[i]
        if noteentry.LayerNumber == 1 then
            stemDir = stem_dir[i]
            if noteentry:IsNote() then  
                if span > 2 then
                    DeleteBottomNotes(noteentry)
                else
                    DeleteMiddleNotes(noteentry)
                    noteentry.FreezeStem = true
                    noteentry.StemUp = stemDir
                end
            elseif noteentry:IsRest() then
                noteentry:SetRestDisplacement(6)
            end
            if stemDir == false and span > 2 then 
                HideStems(noteentry, stemDir)
            end -- end "if stemDir == false" for layer 1
            --noteentry.FreezeStem = true
            --noteentry.StemUp = stemDir
            i = i + 1
        elseif noteentry.LayerNumber == 2 then
            stemDir = stem_dir[j]
            if noteentry:IsNote() and span > 2 then            
                DeleteTopNotes(noteentry)
            else
                noteentry:MakeRest()
                noteentry.Visible = false
                noteentry:SetRestDisplacement(4)                
            end
            if stemDir == true then
                HideStems(noteentry, stemDir)
            end -- end "if stemDir == true" for layer 2
            --noteentry.FreezeStem = true
            --noteentry.StemUp = stemDir
            j = j + 1
        elseif noteentry.LayerNumber == 3 then
            if noteentry:IsNote() then
                for note in each(noteentry) do
                    note.AccidentalFreeze = true
                    note.Accidental = false
                end
                noteentry.FreezeStem = true
                noteentry.StemUp = true
                HideStems(noteentry, true)
                DeleteTopBottomNotes(noteentry)
            elseif noteentry:IsRest() then
                noteentry:SetRestDisplacement(2)
            end
            noteentry.Visible = false
        end  -- end "if layernumber == x"
        noteentry.CheckAccidentals = true
        if noteentry:IsNote() then
            n = 1
            for note in each(noteentry) do
                note.NoteID = n
                n = n +1
            end -- end "for note..."
        end -- end "if IsNote..."
    end -- end for noteentry in eachentrysaved...
end -- EndFunc


-- Function 2: Hide Stems (from JW's Harp Gliss script, modified)
function HideStems(entry, stemDir)
    local stem = finale.FCCustomStemMod()
    stem:SetNoteEntry(entry)
    if stemDir then -- Reverse "stemDir"
        stemDir = false
    else
        stemDir =true
    end
    stem:UseUpStemData(stemDir)
    if stem:LoadFirst() then
        stem.ShapeID = 0   
        stem:Save()
    else
        stem.ShapeID = 0
        stem:SaveNew()
    end
    entry:SetBeamBeat(true) -- Since flags get hidden, use this instead of trying tro change beam width
end

-- Function 3 - Copy Layer "src" to Layer "dest"
function CopyLayer(src, dest) -- source and destination layer numbers, 1 based
    local region = finenv.Region()
    local start=region.StartMeasure
    local stop=region.EndMeasure
    local sysstaves = finale.FCSystemStaves()
    sysstaves:LoadAllForRegion(region)
    -- Set variables for 0-based layers
    src = src - 1
    dest = dest - 1
    for sysstaff in each(sysstaves) do
        staffNum = sysstaff.Staff
        local noteentrylayerSrc = finale.FCNoteEntryLayer(src,staffNum,start,stop)
        noteentrylayerSrc:Load()     
        local noteentrylayerDest = noteentrylayerSrc:CreateCloneEntries(dest,staffNum,start)
        noteentrylayerDest:Save()
        noteentrylayerDest:CloneTuplets(noteentrylayerSrc)
        noteentrylayerDest:Save()
    end -- end "for sysstaff"
end -- end CopyLayer()

-- Function 4 - Delete the bottom notes, leaving only the top
function DeleteBottomNotes(entry)
    while entry.Count > 1 do
        local lowestnote = entry:CalcLowestNote(nil)
        entry:DeleteNote(lowestnote)
    end -- end while
end -- end func

-- Function 5 - Delete the top notes, leaving only the bottom
function DeleteTopNotes(entry)
    while entry.Count > 1 do
        local highestnote = entry:CalcHighestNote(nil)
        entry:DeleteNote(highestnote)
    end -- end while
end -- end func

-- Function 6 - Delete the Top and Bottom Notes
function DeleteTopBottomNotes(entry)
--    for entry in eachentrysaved(region) do
        local highestnote = entry:CalcHighestNote(nil)
        entry:DeleteNote(highestnote)
        local lowestnote = entry:CalcLowestNote(nil)
        entry:DeleteNote(lowestnote)
 --   end -- "for entry..."
end -- end Delete...Notes

-- Function 6.1 - Delete the middle notes
function DeleteMiddleNotes(entry)
    while entry.Count > 2 do
        local n = 1
        for note in each(entry) do
            note.NoteID = n
            n = n +1
        end -- end "for note..."
        for note in each(entry) do
            if note.NoteID == 2 then
                entry:DeleteNote(note)
            end
        end -- end for note...
    end -- end while
end -- end "Delete middle notes"


-- Function 7: Create the custom line to use (or choose it if it already exists)
local function create_cluster_line()
    --Check to see if the right line exists. If it does, get the line ID
    local lineExists = false
    local myLine = 0
    local myLineWidth = 64 * 24 * .5 -- 64 EFIXes * 24EVPUs * .5 = 1/2 space
    local customsmartlinedefs = finale.FCCustomSmartLineDefs()
    customsmartlinedefs:LoadAll()
    for csld in each(customsmartlinedefs) do
        if csld.LineStyle == finale.CUSTOMLINE_SOLID and csld.LineWidth == myLineWidth then -- 1st if: Solid line, 740
            if csld.StartArrowheadStyle == finale.CLENDPOINT_NONE and  csld.EndArrowheadStyle == finale.CLENDPOINT_NONE then -- 2nd if (arrowhead styles)
                if csld.Horizontal == false then
                    myLine = csld.ItemNo
                    lineExists = true
                end -- end 3rd if
            end -- end 2nd if
        end -- end 1st if
    end -- end "for" loop looking at custom smart lines
        -- if the line does not exist, create it and get the line ID
    if lineExists == false then
        local csld = finale.FCCustomSmartLineDef()
        csld.Horizontal = false
        csld.LineStyle = finale.CUSTOMLINE_SOLID
        csld.StartArrowheadStyle = finale.CLENDPOINT_NONE
        csld.EndArrowheadStyle = finale.CLENDPOINT_NONE
        csld.LineWidth = myLineWidth
        csld:SaveNew()
        myLine = csld.ItemNo
    end
    return myLine
end

-- Function 7.1: Create the short-span custom line to use (or choose it if it already exists)
local function create_short_cluster_line()
    --Check to see if the right line exists. If it does, get the line ID
    local lineExists = false
    local myLine = 0
    local myLineWidth = 64 * 24 * .333 -- 64 EFIXes * 24EVPUs * .333 = 1/3 space
    local customsmartlinedefs = finale.FCCustomSmartLineDefs()
    customsmartlinedefs:LoadAll()
    for csld in each(customsmartlinedefs) do
        if csld.LineStyle == finale.CUSTOMLINE_SOLID and csld.LineWidth == myLineWidth then -- 1st if: Solid line, 740
            if csld.StartArrowheadStyle == finale.CLENDPOINT_NONE and  csld.EndArrowheadStyle == finale.CLENDPOINT_NONE then -- 2nd if (arrowhead styles)
                if csld.Horizontal == false then
                    myLine = csld.ItemNo
                    lineExists = true
                end -- end 3rd if
            end -- end 2nd if
        end -- end 1st if
    end -- end "for" loop looking at custom smart lines
        -- if the line does not exist, create it and get the line ID
    if lineExists == false then
        local csld = finale.FCCustomSmartLineDef()
        csld.Horizontal = false
        csld.LineStyle = finale.CUSTOMLINE_SOLID
        csld.StartArrowheadStyle = finale.CLENDPOINT_NONE
        csld.EndArrowheadStyle = finale.CLENDPOINT_NONE
        csld.LineWidth = myLineWidth
        csld:SaveNew()
        myLine = csld.ItemNo
    end
    return myLine
end

-- Function 8: Attach the cluster line to the score
function add_cluster_line(leftnote, rightnote, lineID)
    if leftnote:IsNote() and leftnote.Count == 1 and rightnote:IsNote() then
        local smartshape = finale.FCSmartShape()
        local layer1highest = leftnote:CalcHighestNote(nil)
        local noteWidth = layer1highest:CalcNoteheadWidth()
        local layer1noteY = layer1highest:CalcStaffPosition()
        --
        local layer2highest = rightnote:CalcHighestNote(nil)
        local layer2noteY = layer2highest:CalcStaffPosition()
        --
        local topPad = 0
        local bottomPad = 0
        if leftnote.Duration >= 2048 and leftnote.Duration < 4096 then -- for half notes...
            topPad = 9
            bottomPad = topPad
        elseif leftnote.Duration >= 4096 then -- for whole notes and greater...
            topPad = 10
            bottomPad = 11.5
        end -- end if
        layer1noteY = (layer1noteY * 12) - topPad 
        layer2noteY = (layer2noteY * 12) + bottomPad 
        --
        smartshape.ShapeType = finale.SMARTSHAPE_CUSTOM
        smartshape.EntryBased = false
        smartshape.MakeHorizontal = false
        smartshape.BeatAttached= true
        smartshape.PresetShape = true
        smartshape.Visible = true
        smartshape.LineID = lineID
        --
        local leftseg = smartshape:GetTerminateSegmentLeft()
        leftseg:SetMeasure(leftnote.Measure)
        leftseg:SetStaff(leftnote.Staff)
        leftseg:SetMeasurePos(leftnote.MeasurePos)
        leftseg:SetEndpointOffsetX(noteWidth/2)
        leftseg:SetEndpointOffsetY(layer1noteY)
        --
        local rightseg = smartshape:GetTerminateSegmentRight()
        rightseg:SetMeasure(rightnote.Measure)
        rightseg:SetStaff(rightnote.Staff)
        rightseg:SetMeasurePos(rightnote.MeasurePos)
        rightseg:SetEndpointOffsetX(noteWidth/2)
        rightseg:SetEndpointOffsetY(layer2noteY)
        --
        smartshape:SaveNewEverything(NULL,NULL)
    end -- end "if leftnote..."
end -- end function

-- Function 8.1: Attach the short cluster line to the score
function add_short_cluster_line(entry, short_lineID)
    if entry:IsNote() and entry.Count > 1 then
        local smartshape = finale.FCSmartShape()
        local leftnote = entry:CalcHighestNote(nil)
        local leftnoteY = leftnote:CalcStaffPosition() * 12 + 12
        --
        local rightnote = entry:CalcLowestNote(nil)
        local rightnoteY = rightnote:CalcStaffPosition() * 12 - 12
        --
        smartshape.ShapeType = finale.SMARTSHAPE_CUSTOM
        smartshape.EntryBased = false
        smartshape.MakeHorizontal = false
        smartshape.PresetShape = true
        smartshape.Visible = true
        smartshape.BeatAttached= true
        smartshape.LineID = short_lineID
        --
        local leftseg = smartshape:GetTerminateSegmentLeft()
        leftseg:SetMeasure(entry.Measure)
        leftseg:SetStaff(entry.Staff)
        leftseg:SetMeasurePos(entry.MeasurePos)
        leftseg:SetEndpointOffsetX(horz_off)
        leftseg:SetEndpointOffsetY(leftnoteY)
        --
        local rightseg = smartshape:GetTerminateSegmentRight()
        rightseg:SetMeasure(entry.Measure)
        rightseg:SetStaff(entry.Staff)
        rightseg:SetMeasurePos(entry.MeasurePos)
        rightseg:SetEndpointOffsetX(horz_off)
        rightseg:SetEndpointOffsetY(rightnoteY)
        --
        smartshape:SaveNewEverything(NULL,NULL)
--[[
        -- move accidentals...
        for note in each(entry) do
            if note.Accidental == true then
                local accidental = finale.FCAccidentalMod()
                accidental:SetNoteEntry(entry)
                accidental:SetHorizontalPos(horz_off)
                accidental:SaveAt(note)
            end -- end "if entry.Accidental..."
         end -- end "for note..."
    --]]--
    end -- end "if entry:IsNote..."
end -- end function


-- Do the functions...

local lineID = create_cluster_line()
local short_lineID = create_short_cluster_line()

for addstaff = region:GetStartStaff(), region:GetEndStaff() do
    local count = 0
        --
    for k,v in pairs(layer1note) do
        layer1note [k] = nil
    end
    for k,v in pairs(layer2note) do
        layer2note [k] = nil
    end
    for k,v in pairs(measure) do
        measure[k] = nil
    end
    --
    region:SetStartStaff(addstaff)
    region:SetEndStaff(addstaff)
    local measures = finale.FCMeasures()
    measures:LoadRegion(region)
    ProcessNotes(region) -- Call Function 1
--
    for entry in eachentrysaved(region) do
        if entry.LayerNumber == 1 then
            table.insert(layer1note, entry)
            table.insert(measure, entry.Measure)
            staff = entry.Staff
            count = count + 1
        elseif entry.LayerNumber == 2 then
            table.insert(layer2note, entry)
        end -- end if
    end -- end for
    --
    for i = 1, count do
            add_short_cluster_line(layer1note[i], short_lineID)
            add_cluster_line(layer1note[i], layer2note[i], lineID)
    end -- end for
end

-- separate move accidentals function for short clusters that encompass a 3rd
for noteentry in eachentrysaved(finenv.Region()) do
    if noteentry:IsNote() and noteentry.Count > 1 then
        for note in each(noteentry) do
            if note.Accidental == true then
                local am = finale.FCAccidentalMod()
                am:SetNoteEntry(noteentry)
                am:SetUseCustomVerticalPos(true)
                am:SetHorizontalPos(horz_off*1.5)
                am:SaveAt(note)
            end
        end
    end
end


