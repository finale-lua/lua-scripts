function plugindef()
	finaleplugin.RequireSelection = true
	finaleplugin.Version = "v1.1"
	finaleplugin.Date = "2022/05/30"
    finaleplugin.AdditionalMenuOptions = [[
		Barline Set Double
		Barline Set Final
		Barline Set None
		Barline Set Dashed
     ]]
    finaleplugin.AdditionalUndoText = [[
		Barline Set Double
		Barline Set Final
		Barline Set None
		Barline Set Dashed
	]]
    finaleplugin.AdditionalPrefixes = [[
		new_barline = finale.BARLINE_DOUBLE
		new_barline = finale.BARLINE_FINAL
		new_barline = finale.BARLINE_NONE
		new_barline = finale.BARLINE_DASHED		
	]]
	finaleplugin.Notes = [[
		Change all selected barlines to the normal "single" barline. 
		Uncder RGPLua (0.62 and above) an additional four menu items are created 
		offering the choice of four other basic barline styles.
	]]
	finaleplugin.MinJWLuaVersion = 0.62
	return "Barline Set Normal", "Barline Set Normal", "Set barlines to one of five styles"
end

-- default to "SINGLE" barline for "normal" operation
new_barline = new_barline or finale.BARLINE_NORMAL

-- ===================
function change_barline()
	local region = finenv.Region()
	region.StartMeasurePos = 0
	region:SetEndMeasurePosRight()
	region:SetFullMeasureStack() -- just to be sure!
	
	local measures = finale.FCMeasures()
	measures:LoadRegion(region)
	for m in each(measures) do
		m.Barline = new_barline
	end
	measures:SaveAll()
end
-- ===================
change_barline()
