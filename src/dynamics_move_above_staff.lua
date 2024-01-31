function plugindef()
   -- This function and the 'finaleplugin' namespace
   -- are both reserved for the plug-in definition.
   finaleplugin.RequireScore = false
   finaleplugin.RequireSelection = true
   finaleplugin.Author = "Jacob Winkler"
   finaleplugin.Copyright = "2021"
   finaleplugin.Version = "1.0.1"
   return "Dynamics Above Staff", "Dynamics Above Staff", "Moves dynamics above staff"
end

 
function dyn_above()
    local region = finenv.Region()
    local start_msr = region.StartMeasure
    local end_msr = region.EndMeasure
    local start_staff = region.StartStaff
    local end_staff = region.EndStaff
    local measures = finale.FCMeasures()
    measures:LoadRegion(region)
    local sysstaves = finale.FCSystemStaves()
    sysstaves:LoadAllForRegion(region)
    local staffsystems = finale.FCStaffSystems()
    staffsystems:LoadAll()
    local staffsys = finale.FCStaffSystem()
    local start_staffsys = staffsystems:FindMeasureNumber(start_msr)
    local end_staffsys = staffsystems:FindMeasureNumber(end_msr)
    print("Start Staffsys is",start_staffsys.ItemNo,", End is",end_staffsys.ItemNo)
    local baseline = finale.FCBaseline()
    baseline.Mode = finale.BASELINEMODE_EXPRESSIONABOVE
    baseline:LoadDefaultForMode(finale.BASELINEMODE_EXPRESSIONABOVE)
    local baseline_off = baseline.VerticalOffset
    print("Above Staff Baseline is", baseline_off)
    local e_vert_target = 0
    local h_vert_target = 0
    local vocal_dynamic_offset = 36 -- Distance above reference line to place dynamics, in absence of other entries

    local function metrics(sys_region)
        print("metrics function called")
        local highest = 0
        local hairpins
        measures:LoadRegion(sys_region)
        local cellmetrics, staff_scale
        for msr in each(measures) do
            print("Analyzing measure", msr.ItemNo)
            local cell = finale.FCCell(msr.ItemNo, sys_region.StartStaff)
            cellmetrics = cell:CreateCellMetrics()
            --**** May need to account for cellmetrics:GetStaffScaling()...
            staff_scale = cellmetrics:GetStaffScaling() / 10000
            if cellmetrics.ReferenceLinePos + vocal_dynamic_offset > highest then
                highest = cellmetrics.ReferenceLinePos + vocal_dynamic_offset
            end
        end -- for msr..
        for entry in eachentry(sys_region) do
            local e_metrics = finale.FCEntryMetrics()
            e_metrics:Load(entry)
            local e_highest = e_metrics:GetTopPosition() / staff_scale
            if e_highest + vocal_dynamic_offset > highest then 
                highest = e_highest + vocal_dynamic_offset
            end
        end
        hairpins = highest - cellmetrics.ReferenceLinePos +12

        return highest, hairpins
    end -- function metrics

    local function expr_move(staff_region, e_vert_target)   -- luacheck: ignore e_vert_target
        local expressions = finale.FCExpressions()
        expressions:LoadAllForRegion(staff_region)
        for e in each(expressions) do
            local dynamic = false
            local sed = e:CreateTextExpressionDef()
            local cat_ID = sed:GetCategoryID()
            local cd = finale.FCCategoryDef()
            if cd:Load(cat_ID) then
                local cat_name = cd:CreateName()
                --print(cat_name.LuaString)
                if cat_name.LuaString == "Dynamics" then
                    dynamic = true
                end
            end
            if dynamic == true then
                print("VerticalPos",e.VerticalPos)
                local e_metric = finale.FCPoint(0, 0)
                print("Vertical Target is",e_vert_target)
                e:CalcMetricPos(e_metric)
                print("Expression Y is",e_metric.Y)
                e:SetVerticalPos(e.VerticalPos + (e_vert_target - e_metric.Y))
                e:Save()
            end -- if dynamic == true
        end -- for e...
    end -- func expr_move


    local function hairpin_move(staff_region, h_vert_target)   -- luacheck: ignore h_vert_target
        local ssmm = finale.FCSmartShapeMeasureMarks()
        ssmm:LoadAllForRegion(staff_region, true)
        for mark in each(ssmm) do
            local smart_shape = mark:CreateSmartShape()
            if smart_shape:IsHairpin() then
                print("found hairpin")
                local left_seg = smart_shape:GetTerminateSegmentLeft()
                local right_seg = smart_shape:GetTerminateSegmentRight()
                left_seg:SetEndpointOffsetY(h_vert_target)
                right_seg:SetEndpointOffsetY(h_vert_target)

                smart_shape:Save()            
            end
        end
    end -- func hairpin_move

    local function analyze_staves()
        for i = start_staffsys.ItemNo, end_staffsys.ItemNo, 1 do
            print("Analyzing staffsys",i)
            staffsys:Load(i)
            local sys_region_start, sys_region_end
            if start_msr > staffsys.FirstMeasure then
                sys_region_start = start_msr
            else
                sys_region_start = staffsys.FirstMeasure
            end
            if end_msr < (staffsys.NextSysMeasure - 1) then
                sys_region_end = end_msr
            else
                sys_region_end = staffsys.NextSysMeasure - 1
            end
            print("Start Measure",sys_region_start, "End", sys_region_end)
            local sys_region = finenv.Region()
            sys_region:SetStartMeasure(sys_region_start)
            sys_region:SetEndMeasure(sys_region_end)
            for j = start_staff, end_staff, 1 do
                sys_region:SetStartStaff(j)
                sys_region:SetEndStaff(j)
                e_vert_target, h_vert_target = metrics(sys_region)
                print("vert_target for staff",j,"is",e_vert_target)
                expr_move(sys_region, e_vert_target)
                hairpin_move(sys_region, h_vert_target)
            end -- for j = start_staff...
        end -- for i...
    end -- function 

    analyze_staves()

end -- function

dyn_above()
