local a,b,c,d=(function(e)local f={[{}]=true}local g;local h={}local require;local i={}g=function(j,k)if not h[j]then h[j]=k end end;require=function(j)local l=i[j]if l then if l==f then return nil end else if not h[j]then if not e then local m=type(j)=='string'and'\"'..j..'\"'or tostring(j)error('Tried to require '..m..', but no such module has been registered')else return e(j)end end;i[j]=f;l=h[j](require,i,g,h)i[j]=l end;return l end;return require,i,g,h end)(require)c("__root",function(require,n,c,d)function plugindef()finaleplugin.RequireSelection=true;finaleplugin.Author="Robert Patterson"finaleplugin.Version="1.0"finaleplugin.Copyright="CC0 https://creativecommons.org/publicdomain/zero/1.0/"finaleplugin.Date="May 15, 2022"finaleplugin.CategoryTags="Baseline"finaleplugin.AuthorURL="http://robertgpatterson.com"finaleplugin.MinJWLuaVersion=0.62;finaleplugin.Notes=[[
        This script nudges system baselines up or down by a single staff-space (24 evpus). It introduces 10
        menu options to nudge each baseline type up or down. It also introduces 5 menu options to reset
        the baselines to their staff-level values.

        The possible prefix inputs to the script are

        ```
        direction -- 1 for up, -1 for down, 0 for reset
        baseline_types -- a table containing a list of the baseline types to process
        nudge_evpus -- a positive number indicating the size of the nudge
        ```

        You can also change the size of the nudge by creating a configuration file called `baseline_move.config.txt` and
        adding a single line with the size of the nudge in evpus.

        ```
        nudge_evpus = 36 -- or whatever size you wish
        ```

        A value in a prefix overrides any setting in a configuration file.
    ]]finaleplugin.AdditionalMenuOptions=[[
        Move Lyric Baselines Up
        Reset Lyric Baselines
        Move Expression Baseline Above Down
        Move Expression Baseline Above Up
        Reset Expression Baseline Above
        Move Expression Baseline Below Down
        Move Expression Baseline Below Up
        Reset Expression Baseline Below
        Move Chord Baseline Down
        Move Chord Baseline Up
        Reset Chord Baseline
        Move Fretboard Baseline Down
        Move Fretboard Baseline Up
        Reset Fretboard Baseline
    ]]finaleplugin.AdditionalDescriptions=[[
        Moves all lyrics baselines up one space in the selected systems
        Resets all selected lyrics baselines to default
        Moves the selected expression above baseline down one space
        Moves the selected expression above baseline up one space
        Resets the selected expression above baselines
        Moves the selected expression below baseline down one space
        Moves the selected expression below baseline up one space
        Resets the selected expression below baselines
        Moves the selected chord baseline down one space
        Moves the selected chord baseline up one space
        Resets the selected chord baselines
        Moves the selected fretboard baseline down one space
        Moves the selected fretboard baseline up one space
        Resets the selected fretboard baselines
    ]]finaleplugin.AdditionalPrefixes=[[
        direction = 1 -- no baseline_types table, which picks up the default (lyrics)
        direction = 0 -- no baseline_types table, which picks up the default (lyrics)
        direction = -1 baseline_types = {finale.BASELINEMODE_EXPRESSIONABOVE}
        direction = 1 baseline_types = {finale.BASELINEMODE_EXPRESSIONABOVE}
        direction = 0 baseline_types = {finale.BASELINEMODE_EXPRESSIONABOVE}
        direction = -1 baseline_types = {finale.BASELINEMODE_EXPRESSIONBELOW}
        direction = 1 baseline_types = {finale.BASELINEMODE_EXPRESSIONBELOW}
        direction = 0 baseline_types = {finale.BASELINEMODE_EXPRESSIONBELOW}
        direction = -1 baseline_types = {finale.BASELINEMODE_CHORD}
        direction = 1 baseline_types = {finale.BASELINEMODE_CHORD}
        direction = 0 baseline_types = {finale.BASELINEMODE_CHORD}
        direction = -1 baseline_types = {finale.BASELINEMODE_FRETBOARD}
        direction = 1 baseline_types = {finale.BASELINEMODE_FRETBOARD}
        direction = 0 baseline_types = {finale.BASELINEMODE_FRETBOARD}
    ]]return"Move Lyric Baselines Down","Move Lyrics Baselines Down","Moves all lyrics baselines down one space in the selected systems"end;local o=require("library.configuration")local p={nudge_evpus=24}if nil~=o then o.get_parameters("baseline_move.config.txt",p)end;local q={[finale.BASELINEMODE_LYRICSVERSE]=function()return finale.FCVerseLyricsText()end,[finale.BASELINEMODE_LYRICSCHORUS]=function()return finale.FCChorusLyricsText()end,[finale.BASELINEMODE_LYRICSSECTION]=function()return finale.FCSectionLyricsText()end}local r=function(s)local t=q[s]if t then local u={}local v=t()for w=1,32767,1 do if v:Load(w)then local x=finale.FCString()v:GetText(x)if not x:IsEmpty()then u[{s,w}]=1 end end end;return u end;return nil end;function baseline_move()local y=finenv.Region()local z=finale.FCStaffSystems()z:LoadAll()local A=y:GetStartMeasure()local B=y:GetEndMeasure()local C=z:FindMeasureNumber(A)local D=z:FindMeasureNumber(B)local E=C:GetItemNo()local F=D:GetItemNo()local G=y:GetStartSlot()local H=y:GetEndSlot()for I,s in pairs(baseline_types)do local u=r(s)for w=E,F,1 do local J=finale.FCBaselines()if direction~=0 then J:LoadAllForSystem(s,w)for K=G,H do if u then for L,I in pairs(u)do local I,M=table.unpack(L)bl=J:AssureSavedLyricNumber(s,w,y:CalcStaffNumber(K),M)bl.VerticalOffset=bl.VerticalOffset+direction*nudge_evpus;bl:Save()end else bl=J:AssureSavedStaff(s,w,y:CalcStaffNumber(K))bl.VerticalOffset=bl.VerticalOffset+direction*nudge_evpus;bl:Save()end end else for K=G,H do J:LoadAllForSystemStaff(s,w,y:CalcStaffNumber(K))for N in eachbackwards(J)do N:DeleteData()end end end end end end;baseline_types=baseline_types or{finale.BASELINEMODE_LYRICSVERSE,finale.BASELINEMODE_LYRICSCHORUS,finale.BASELINEMODE_LYRICSSECTION}direction=direction or-1;nudge_evpus=nudge_evpus or p.nudge_evpus;baseline_move()end)c("library.configuration",function(require,n,c,d)local O={}function O.finale_version(P,Q,R)local S=bit32.bor(bit32.lshift(math.floor(P),24),bit32.lshift(math.floor(Q),20))if R then S=bit32.bor(S,math.floor(R))end;return S end;function O.group_overlaps_region(T,y)if y:IsFullDocumentSpan()then return true end;local U=false;local V=finale.FCSystemStaves()V:LoadAllForRegion(y)for W in each(V)do if T:ContainsStaff(W:GetStaff())then U=true;break end end;if not U then return false end;if T.StartMeasure>y.EndMeasure or T.EndMeasure<y.StartMeasure then return false end;return true end;function O.group_is_contained_in_region(T,y)if not y:IsStaffIncluded(T.StartStaff)then return false end;if not y:IsStaffIncluded(T.EndStaff)then return false end;return true end;function O.staff_group_is_multistaff_instrument(T)local X=finale.FCMultiStaffInstruments()X:LoadAll()for Y in each(X)do if Y:ContainsStaff(T.StartStaff)and Y.GroupID==T:GetItemID()then return true end end;return false end;function O.get_selected_region_or_whole_doc()local Z=finenv.Region()if Z:IsEmpty()then Z:SetFullDocument()end;return Z end;function O.get_first_cell_on_or_after_page(_)local a0=_;local a1=finale.FCPage()local a2=false;while a1:Load(a0)do if a1:GetFirstSystem()>0 then a2=true;break end;a0=a0+1 end;if a2 then local a3=finale.FCStaffSystem()a3:Load(a1:GetFirstSystem())return finale.FCCell(a3.FirstMeasure,a3.TopStaff)end;local a4=finale.FCMusicRegion()a4:SetFullDocument()return finale.FCCell(a4.EndMeasure,a4.EndStaff)end;function O.get_top_left_visible_cell()if not finenv.UI():IsPageView()then local a5=finale.FCMusicRegion()a5:SetFullDocument()return finale.FCCell(finenv.UI():GetCurrentMeasure(),a5.StartStaff)end;return O.get_first_cell_on_or_after_page(finenv.UI():GetCurrentPage())end;function O.get_top_left_selected_or_visible_cell()local Z=finenv.Region()if not Z:IsEmpty()then return finale.FCCell(Z.StartMeasure,Z.StartStaff)end;return O.get_top_left_visible_cell()end;function O.is_default_measure_number_visible_on_cell(a6,a7,a8,a9)local aa=finale.FCCurrentStaffSpec()if not aa:LoadForCell(a7,0)then return false end;if a6:GetShowOnTopStaff()and a7.Staff==a8.TopStaff then return true end;if a6:GetShowOnBottomStaff()and a7.Staff==a8:CalcBottomStaff()then return true end;if aa.ShowMeasureNumbers then return not a6:GetExcludeOtherStaves(a9)end;return false end;function O.is_default_number_visible_and_left_aligned(a6,a7,C,a9,ab)if a6.UseScoreInfoForParts then a9=false end;if ab and a6:GetShowOnMultiMeasureRests(a9)then if finale.MNALIGN_LEFT~=a6:GetMultiMeasureAlignment(a9)then return false end elseif a7.Measure==C.FirstMeasure then if not a6:GetShowOnSystemStart()then return false end;if finale.MNALIGN_LEFT~=a6:GetStartAlignment(a9)then return false end else if not a6:GetShowMultiples(a9)then return false end;if finale.MNALIGN_LEFT~=a6:GetMultipleAlignment(a9)then return false end end;return O.is_default_measure_number_visible_on_cell(a6,a7,C,a9)end;function O.update_layout(ac,ad)ac=ac or 1;ad=ad or false;local ae=finale.FCPage()if ae:Load(ac)then ae:UpdateLayout(ad)end end;function O.get_current_part()local af=finale.FCParts()af:LoadAll()return af:GetCurrent()end;function O.get_page_format_prefs()local ag=O.get_current_part()local ah=finale.FCPageFormatPrefs()local ai=false;if ag:IsScore()then ai=ah:LoadScore()else ai=ah:LoadParts()end;return ah,ai end;function O.get_smufl_metadata_file(aj)if not aj then aj=finale.FCFontInfo()aj:LoadFontPrefs(finale.FONTPREF_MUSIC)end;local ak=function(al,aj)local am=al.."/SMuFL/Fonts/"..aj.Name.."/"..aj.Name..".json"return io.open(am,"r")end;local an=""if finenv.UI():IsOnWindows()then an=os.getenv("LOCALAPPDATA")else an=os.getenv("HOME").."/Library/Application Support"end;local ao=ak(an,aj)if nil~=ao then return ao end;local ap="/Library/Application Support"if finenv.UI():IsOnWindows()then ap=os.getenv("COMMONPROGRAMFILES")end;return ak(ap,aj)end;function O.is_font_smufl_font(aj)if not aj then aj=finale.FCFontInfo()aj:LoadFontPrefs(finale.FONTPREF_MUSIC)end;if finenv.RawFinaleVersion>=O.finale_version(27,1)then if nil~=aj.IsSMuFLFont then return aj.IsSMuFLFont end end;local aq=O.get_smufl_metadata_file(aj)if nil~=aq then io.close(aq)return true end;return false end;function O.simple_input(ar,as)local at=finale.FCString()at.LuaString=""local x=finale.FCString()local au=160;function format_ctrl(av,aw,ax,ay)av:SetHeight(aw)av:SetWidth(ax)x.LuaString=ay;av:SetText(x)end;title_width=string.len(ar)*6+54;if title_width>au then au=title_width end;text_width=string.len(as)*6;if text_width>au then au=text_width end;x.LuaString=ar;local az=finale.FCCustomLuaWindow()az:SetTitle(x)local aA=az:CreateStatic(0,0)format_ctrl(aA,16,au,as)local aB=az:CreateEdit(0,20)format_ctrl(aB,20,au,"")az:CreateOkButton()az:CreateCancelButton()function callback(av)end;az:RegisterHandleCommand(callback)if az:ExecuteModal(nil)==finale.EXECMODAL_OK then at.LuaString=aB:GetText(at)return at.LuaString end end;function O.is_finale_object(aC)return aC and type(aC)=="userdata"and aC.ClassName and aC.GetClassID and true or false end;function O.system_indent_set_to_prefs(C,ah)ah=ah or O.get_page_format_prefs()local aD=finale.FCMeasure()local aE=C.FirstMeasure==1;if not aE and aD:Load(C.FirstMeasure)then if aD.ShowFullNames then aE=true end end;if aE and ah.UseFirstSystemMargins then C.LeftMargin=ah.FirstSystemLeft else C.LeftMargin=ah.SystemLeft end;return C:Save()end;return O end)return a("__root")