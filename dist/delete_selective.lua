function plugindef()finaleplugin.RequireSelection=true;finaleplugin.Author="Carl Vine"finaleplugin.AuthorURL="http://carlvine.com/lua"finaleplugin.Copyright="CC0 https://creativecommons.org/publicdomain/zero/1.0/"finaleplugin.Version="0.51"finaleplugin.Date="2022/06/24"finaleplugin.AdditionalMenuOptions=[[
        Delete dynamics
        Delete expressions (not dynamics)
        Delete expressions (measure-attached)
        Delete articulations
        Delete hairpins
        Delete slurs
        Delete custom lines
        Delete glissandos
        Delete smart shapes (beat aligned)
        Delete all smart shapes
     ]]finaleplugin.AdditionalUndoText=[[
        Delete dynamics
        Delete expressions (not dynamics)
        Delete expressions (measure-attached)
        Delete articulations
        Delete hairpins
        Delete slurs
        Delete custom lines
        Delete glissandos
        Delete smart shapes (beat aligned)
        Delete all smart shapes
	]]finaleplugin.AdditionalDescriptions=[[
        Delete dynamics from the selected region
        Delete expressions (not dynamics) from the selected region
        Delete measure-assigned expressions from the selected region
        Delete articulations from the selected region
        Delete hairpins from the selected region
        Delete slurs from the selected region
        Delete custom lines from the selected region
        Delete glissandos from the selected region
        Delete smart shapes (beat aligned) from the selected region
        Delete all smart shapes from the selected region
    ]]finaleplugin.AdditionalPrefixes=[[
        delete_type = "expression_dynamic"
        delete_type = "expression_not_dynamic"
        delete_type = "measure_attached"
        delete_type = "articulation"
        delete_type = "shape_hairpin"
        delete_type = "shape_slur"
        delete_type = "shape_custom"
        delete_type = "shape_glissando"
        delete_type = "shape_beat_aligned"
        delete_type = "shape_all"
	]]finaleplugin.Notes=[[
        Deletes nominated items from the selected region, 
        defaulting to a primary menu item: "Delete all expressions".  
        Under RGPLua (0.62+) nine additional menu items are created 
        to independently delete other items of these types: 
        dynamics / expressions (not dynamics) / expressions (measure-attached) / articulations / 
        hairpins / slurs / custom lines / glissandos / smart shapes (beat aligned) / all smart shapes 
    ]]return"Delete all expressions","Delete all expressions","Delete all expressions from the selected region"end;delete_type=delete_type or"expression_all"function delete_selected()if string.find(delete_type,"shape")then local a=finale.FCSmartShapeMeasureMarks()a:LoadAllForRegion(finenv.Region(),true)for b in each(a)do local c=b:CreateSmartShape()if delete_type=="shape_hairpin"and c:IsHairpin()or delete_type=="shape_slur"and c:IsSlur()or delete_type=="shape_custom"and c:IsCustomLine()or delete_type=="shape_glissando"and c:IsGlissando()or delete_type=="shape_beat_aligned"and not c:IsEntryBased()or delete_type=="shape_all"then c:DeleteData()end end elseif string.find(delete_type,"express")then local d=finale.FCExpressions()d:LoadAllForRegion(finenv.Region())for e in eachbackwards(d)do local f=e:CreateTextExpressionDef().CategoryID;if not e:IsShape()and e.StaffGroupID==0 and(delete_type=="expression_all"or delete_type=="expression_not_dynamic"and f~=finale.DEFAULTCATID_DYNAMICS or delete_type=="expression_dynamic"and f==finale.DEFAULTCATID_DYNAMICS)then e:DeleteData()end end elseif delete_type=="measure_attached"then local g=finale.FCMeasures()g:LoadRegion(finenv.Region())local h=finale.FCExpression()for i in each(g)do for e in eachbackwards(i:CreateExpressions())do if e.StaffGroupID>0 then e:DeleteData()end end;if not h:Load(i.ItemNo,0)then i.ExpressionFlag=false;i:Save()end end elseif delete_type=="articulation"then for j in eachentrysaved(finenv.Region())do if j:GetArticulationFlag()then for k in eachbackwards(j:CreateArticulations())do k:DeleteData()end;j:SetArticulationFlag(false)end end end end;delete_selected()