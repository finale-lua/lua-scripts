local a,b,c,d=(function(e)local f={[{}]=true}local g;local h={}local require;local i={}g=function(j,k)if not h[j]then h[j]=k end end;require=function(j)local l=i[j]if l then if l==f then return nil end else if not h[j]then if not e then local m=type(j)=='string'and'\"'..j..'\"'or tostring(j)error('Tried to require '..m..', but no such module has been registered')else return e(j)end end;i[j]=f;l=h[j](require,i,g,h)i[j]=l end;return l end;return require,i,g,h end)(require)c("__root",function(require,n,c,d)function plugindef()finaleplugin.Author="Nick Mazuk"finaleplugin.Copyright="CC0 https://creativecommons.org/publicdomain/zero/1.0/"finaleplugin.Version="1.0.0"finaleplugin.Date="June 4, 2022"finaleplugin.CategoryTags="Meter"finaleplugin.MinJWLuaVersion=0.62;finaleplugin.AuthorURL="https://nickmazuk.com"finaleplugin.RequireSelection=true;finaleplugin.Notes=[[
        Changes the meter in a selected range.
        
        If a single measure is selected,
        the meter will be set for all measures until the next
        meter change, or until the next measure with Time Signature
        set to "Always Show", or for the remaining measures in the score.
        You can override stopping at "Always Show" measures with a configuration
        file script_settings/meter_change.config.txt that contains the following
        line:

        ```
        stop_at_always_show = false
        ```

        You can limit the meter change to one bar by holding down Shift or Option
        keys when invoking the script. Then the meter is changed only
        for the single measure you selected.

        If multiple measures are selected, the meter will be set
        exactly for the selected measures. 
    ]]finaleplugin.AdditionalMenuOptions=[[
        Meter - 1/2
        Meter - 2/2
        Meter - 3/2
        Meter - 4/2
        Meter - 5/2
        Meter - 6/2
        Meter - 1/4
        Meter - 2/4
        Meter - 3/4
        Meter - 5/4
        Meter - 6/4
        Meter - 7/4
        Meter - 3/8
        Meter - 5/8 (2+3)
        Meter - 5/8 (3+2)
        Meter - 6/8
        Meter - 7/8 (2+2+3)
        Meter - 7/8 (3+2+2)
        Meter - 9/8
        Meter - 12/8
        Meter - 15/8
    ]]finaleplugin.AdditionalPrefixes=[[
        numerator = 1 denominator = 2
        numerator = 2 denominator = 2
        numerator = 3 denominator = 2
        numerator = 4 denominator = 2
        numerator = 5 denominator = 2
        numerator = 6 denominator = 2
        numerator = 1 denominator = 4
        numerator = 2 denominator = 4
        numerator = 3 denominator = 4
        numerator = 5 denominator = 4
        numerator = 6 denominator = 4
        numerator = 7 denominator = 4
        numerator = 3 denominator = 8
        numerator = 5 denominator = 8 composite = {2, 3}
        numerator = 5 denominator = 8 composite = {3, 2}
        numerator = 6 denominator = 8
        numerator = 7 denominator = 8 composite = {2, 2, 3}
        numerator = 7 denominator = 8 composite = {3, 2, 2}
        numerator = 9 denominator = 8
        numerator = 12 denominator = 8
        numerator = 15 denominator = 8
    ]]return"Meter - 4/4","Meter - 4/4","Sets the meter as indicated in a selected range."end;local o=require("library.configuration")config={stop_at_always_show=true}o.get_parameters("meter_change.config.txt",config)numerator=numerator or 4;denominator=denominator or 4;composite=composite or nil;if denominator==8 and not composite then numerator=numerator/3 end;num_composite=0;if composite then for p,q in pairs(composite)do num_composite=num_composite+1 end end;local r={}r[2]=2048;r[4]=1024;r[8]=composite and 512 or 1536;local s=finenv.QueryInvokedModifierKeys(finale.CMDMODKEY_ALT)or finenv.QueryInvokedModifierKeys(finale.CMDMODKEY_SHIFT)function apply_new_time(t,u,v)local w=t:GetTimeSignature()if composite then local x=finale.FCCompositeTimeSigTop()x:AddGroup(num_composite)for p,q in ipairs(composite)do x:SetGroupElementBeats(0,p-1,q)end;w:SaveNewCompositeTop(x)t.UseTimeSigForDisplay=true;local y=t:GetTimeSignatureForDisplay()y:RemoveCompositeTop(u)y:RemoveCompositeBottom(v)else if t.UseTimeSigForDisplay then local y=t:GetTimeSignatureForDisplay()y:RemoveCompositeTop(u)y:RemoveCompositeBottom(v)t.UseTimeSigForDisplay=false end;w:RemoveCompositeTop(u)end;w:RemoveCompositeBottom(v)end;function set_time(u,v)local z=finale.FCMeasures()z:LoadRegion(finenv.Region())if z.Count>1 or s then for A in each(z)do apply_new_time(A,u,v)A:Save()end else local B=z:GetItemAt(0)local C=B:GetTimeSignature()for A in loadall(finale.FCMeasures())do if A.ItemNo>B.ItemNo then if config.stop_at_always_show and A.ShowTimeSignature==finale.SHOWSTATE_SHOW then break end;if not C:IsIdentical(A:GetTimeSignature())then break end;apply_new_time(A,u,v)A:Save()end end;apply_new_time(B,u,v)B:Save()end end;set_time(numerator,r[denominator])end)c("library.configuration",function(require,n,c,d)local D={}function D.finale_version(E,F,G)local H=bit32.bor(bit32.lshift(math.floor(E),24),bit32.lshift(math.floor(F),20))if G then H=bit32.bor(H,math.floor(G))end;return H end;function D.group_overlaps_region(I,J)if J:IsFullDocumentSpan()then return true end;local K=false;local L=finale.FCSystemStaves()L:LoadAllForRegion(J)for M in each(L)do if I:ContainsStaff(M:GetStaff())then K=true;break end end;if not K then return false end;if I.StartMeasure>J.EndMeasure or I.EndMeasure<J.StartMeasure then return false end;return true end;function D.group_is_contained_in_region(I,J)if not J:IsStaffIncluded(I.StartStaff)then return false end;if not J:IsStaffIncluded(I.EndStaff)then return false end;return true end;function D.staff_group_is_multistaff_instrument(I)local N=finale.FCMultiStaffInstruments()N:LoadAll()for O in each(N)do if O:ContainsStaff(I.StartStaff)and O.GroupID==I:GetItemID()then return true end end;return false end;function D.get_selected_region_or_whole_doc()local P=finenv.Region()if P:IsEmpty()then P:SetFullDocument()end;return P end;function D.get_first_cell_on_or_after_page(Q)local R=Q;local S=finale.FCPage()local T=false;while S:Load(R)do if S:GetFirstSystem()>0 then T=true;break end;R=R+1 end;if T then local U=finale.FCStaffSystem()U:Load(S:GetFirstSystem())return finale.FCCell(U.FirstMeasure,U.TopStaff)end;local V=finale.FCMusicRegion()V:SetFullDocument()return finale.FCCell(V.EndMeasure,V.EndStaff)end;function D.get_top_left_visible_cell()if not finenv.UI():IsPageView()then local W=finale.FCMusicRegion()W:SetFullDocument()return finale.FCCell(finenv.UI():GetCurrentMeasure(),W.StartStaff)end;return D.get_first_cell_on_or_after_page(finenv.UI():GetCurrentPage())end;function D.get_top_left_selected_or_visible_cell()local P=finenv.Region()if not P:IsEmpty()then return finale.FCCell(P.StartMeasure,P.StartStaff)end;return D.get_top_left_visible_cell()end;function D.is_default_measure_number_visible_on_cell(X,Y,Z,_)local a0=finale.FCCurrentStaffSpec()if not a0:LoadForCell(Y,0)then return false end;if X:GetShowOnTopStaff()and Y.Staff==Z.TopStaff then return true end;if X:GetShowOnBottomStaff()and Y.Staff==Z:CalcBottomStaff()then return true end;if a0.ShowMeasureNumbers then return not X:GetExcludeOtherStaves(_)end;return false end;function D.is_default_number_visible_and_left_aligned(X,Y,a1,_,a2)if X.UseScoreInfoForParts then _=false end;if a2 and X:GetShowOnMultiMeasureRests(_)then if finale.MNALIGN_LEFT~=X:GetMultiMeasureAlignment(_)then return false end elseif Y.Measure==a1.FirstMeasure then if not X:GetShowOnSystemStart()then return false end;if finale.MNALIGN_LEFT~=X:GetStartAlignment(_)then return false end else if not X:GetShowMultiples(_)then return false end;if finale.MNALIGN_LEFT~=X:GetMultipleAlignment(_)then return false end end;return D.is_default_measure_number_visible_on_cell(X,Y,a1,_)end;function D.update_layout(a3,a4)a3=a3 or 1;a4=a4 or false;local a5=finale.FCPage()if a5:Load(a3)then a5:UpdateLayout(a4)end end;function D.get_current_part()local a6=finale.FCParts()a6:LoadAll()return a6:GetCurrent()end;function D.get_page_format_prefs()local a7=D.get_current_part()local a8=finale.FCPageFormatPrefs()local a9=false;if a7:IsScore()then a9=a8:LoadScore()else a9=a8:LoadParts()end;return a8,a9 end;function D.get_smufl_metadata_file(aa)if not aa then aa=finale.FCFontInfo()aa:LoadFontPrefs(finale.FONTPREF_MUSIC)end;local ab=function(ac,aa)local ad=ac.."/SMuFL/Fonts/"..aa.Name.."/"..aa.Name..".json"return io.open(ad,"r")end;local ae=""if finenv.UI():IsOnWindows()then ae=os.getenv("LOCALAPPDATA")else ae=os.getenv("HOME").."/Library/Application Support"end;local af=ab(ae,aa)if nil~=af then return af end;local ag="/Library/Application Support"if finenv.UI():IsOnWindows()then ag=os.getenv("COMMONPROGRAMFILES")end;return ab(ag,aa)end;function D.is_font_smufl_font(aa)if not aa then aa=finale.FCFontInfo()aa:LoadFontPrefs(finale.FONTPREF_MUSIC)end;if finenv.RawFinaleVersion>=D.finale_version(27,1)then if nil~=aa.IsSMuFLFont then return aa.IsSMuFLFont end end;local ah=D.get_smufl_metadata_file(aa)if nil~=ah then io.close(ah)return true end;return false end;function D.simple_input(ai,aj)local ak=finale.FCString()ak.LuaString=""local al=finale.FCString()local am=160;function format_ctrl(an,ao,ap,aq)an:SetHeight(ao)an:SetWidth(ap)al.LuaString=aq;an:SetText(al)end;title_width=string.len(ai)*6+54;if title_width>am then am=title_width end;text_width=string.len(aj)*6;if text_width>am then am=text_width end;al.LuaString=ai;local ar=finale.FCCustomLuaWindow()ar:SetTitle(al)local as=ar:CreateStatic(0,0)format_ctrl(as,16,am,aj)local at=ar:CreateEdit(0,20)format_ctrl(at,20,am,"")ar:CreateOkButton()ar:CreateCancelButton()function callback(an)end;ar:RegisterHandleCommand(callback)if ar:ExecuteModal(nil)==finale.EXECMODAL_OK then ak.LuaString=at:GetText(ak)return ak.LuaString end end;function D.is_finale_object(au)return au and type(au)=="userdata"and au.ClassName and au.GetClassID and true or false end;function D.system_indent_set_to_prefs(a1,a8)a8=a8 or D.get_page_format_prefs()local av=finale.FCMeasure()local aw=a1.FirstMeasure==1;if not aw and av:Load(a1.FirstMeasure)then if av.ShowFullNames then aw=true end end;if aw and a8.UseFirstSystemMargins then a1.LeftMargin=a8.FirstSystemLeft else a1.LeftMargin=a8.SystemLeft end;return a1:Save()end;return D end)return a("__root")