function plugindef()


   finaleplugin.RequireSelection = true
   finaleplugin.Author = "Robert Patterson"
   finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
   finaleplugin.Version = "1.0"
   finaleplugin.Date = "June 10, 2020"
   finaleplugin.CategoryTags = "Measure"
   return "Force Full Names", "Force Full Names", "Force first selected measure to show full staff names."
end
function measure_force_full_names()

    local systems = finale.FCStaffSystems()
    systems:LoadAll()
    local measure_number = finenv.Region().StartMeasure
    local system = systems:FindMeasureNumber(measure_number)
    if measure_number ~= system.FirstMeasure then
        if finale.OKRETURN ~= finenv.UI():AlertOkCancel("The first measure you selected is not at the beginning of a system. Do you wish to process the first measure of this system?", nil) then
            return;
        end
        measure_number = system.FirstMeasure
    end
    local measure = finale.FCMeasure()
    if not measure:Load(measure_number) then
        finenv.UI():AlertInfo("Unable to find measure " .. measure_number)
        return
    end
    measure.ShowFullNames = true;
    measure.SystemBreak = true;
    measure:Save()
end
measure_force_full_names()