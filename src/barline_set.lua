function plugindef()
	finaleplugin.RequireSelection = true
	finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
	finaleplugin.Author = "Carl Vine"
	finaleplugin.AuthorURL = "http://carlvine.com/?cv=lua"
	finaleplugin.Version = "v1.2"
	finaleplugin.Date = "2022/06/18"
	finaleplugin.MinJWLuaVersion = 0.62
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
	finaleplugin.ScriptGroupName = "Barline set"
	finaleplugin.ScriptGroupDescription = "Set all selected barlines to one of five styles"
	finaleplugin.Notes = [[
		Creates five menu items to change all selected barlines
		to one of these barline styles:
		
		```
		Barline Set Normal
		Barline Set Double
		Barline Set Final
		Barline Set None 
		Barline Set Dashed
		```
	]]
	return "Barline Set Normal", "Barline Set Normal", "Set all selected barlines to one of five styles"
end

-- default to "SINGLE" barline for "normal" operation
new_barline = new_barline or finale.BARLINE_NORMAL

function change_barline()
	local region = finenv.Region()
	region.StartMeasurePos = 0
	region:SetEndMeasurePosRight()
	
	local measures = finale.FCMeasures()
	measures:LoadRegion(region)
	for measure in each(measures) do
		measure.Barline = new_barline
	end
	measures:SaveAll()
end

change_barline()
