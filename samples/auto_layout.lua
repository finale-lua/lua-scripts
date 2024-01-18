function plugindef()
    finaleplugin.RequireDocument = false
    finaleplugin.MinJWLuaVersion = 0.71
    return "0--auto resize width test"
end

local utils = require('library.utils')
local mixin = require('library.mixin')
local localization = require('library.localization')

--
-- This table was auto-generated with localization_developer.create_localized_base_table_string(en)
-- Then it was edited to include only the strings that need to be localized.
--
localization_en =
{
    ["Action Button"] = "Action Button",
    ["Choices"] = "Choices",
    ["First Option"] = "First Option",
    ["Fourth Option"] = "Fourth Option",
    ["Left Checkbox Option 1"] = "Left Checkbox Option 1",
    ["Left Checkbox Option 2"] = "Left Checkbox Option 2",
    ["Menu"] = "Menu",
    ["Right Three-State Option"] = "Right Three-State Option",
    ["Second Option"] = "Second Option",
    ["Short "] = "Short ",
    ["Test Autolayout"] = "Test Autolayout",
    ["Third Option"] = "Third Option",
    ["This is long menu text "] = "This is long menu text ",
    ["This is long text choice "] = "This is long text choice ",
    ["This is longer option text "] = "This is longer option text ",
}

--
-- The rest of the localization tables were created one-at-a-time with the auto_layout_localizing_script.lua
--
-- This table was auto-generated with localization_developer.translate_localized_table_string(localization_en, "en", "es")
--
localization_es = {
    ["Action Button"] = "Botón de Acción",
    ["Choices"] = "Opciones",
    ["First Option"] = "Primera Opción",
    ["Fourth Option"] = "Cuarta Opción",
    ["Left Checkbox Option 1"] = "Opción de Casilla de Verificación Izquierda 1",
    ["Left Checkbox Option 2"] = "Opción de Casilla de Verificación Izquierda 2",
    ["Menu"] = "Menú",
    ["Right Three-State Option"] = "Opción de Tres Estados a la Derecha",
    ["Second Option"] = "Segunda Opción",
    ["Short "] = "Corto ",
    ["Test Autolayout"] = "Prueba de Autodiseño",
    ["Third Option"] = "Tercera Opción",
    ["This is long menu text "] = "Este es un texto de menú largo ",
    ["This is long text choice "] = "Esta es una elección de texto largo ",
    ["This is longer option text "] = "Este es un texto de opción más largo ",
}

--
-- This table was auto-generated with localization_developer.translate_localized_table_string(localization_en, "en", "es")
--
localization_jp = {
    ["Action Button"] = "アクションボタン",
    ["Choices"] = "選択肢",
    ["First Option"] = "最初のオプション",
    ["Fourth Option"] = "第四のオプション",
    ["Left Checkbox Option 1"] = "左チェックボックスオプション1",
    ["Left Checkbox Option 2"] = "左チェックボックスオプション2",
    ["Menu"] = "メニュー",
    ["Right Three-State Option"] = "右三状態オプション",
    ["Second Option"] = "第二のオプション",
    ["Short "] = "短い ",
    ["Test Autolayout"] = "テスト自動レイアウト",
    ["Third Option"] = "第三のオプション",
    ["This is long menu text "] = "これは長いメニューテキストです ",
    ["This is long text choice "] = "これは長いテキスト選択です ",
    ["This is longer option text "] = "これはより長いオプションテキストです ",
}

--
-- This table was auto-generated with localization_developer.translate_localized_table_string(localization_en, "en", "de")
--
localization_de = {
    ["Action Button"] = "Aktionsknopf",
    ["Choices"] = "Auswahlmöglichkeiten",
    ["First Option"] = "Erste Option",
    ["Fourth Option"] = "Vierte Option",
    ["Left Checkbox Option 1"] = "Linke Checkbox Option 1",
    ["Left Checkbox Option 2"] = "Linke Checkbox Option 2",
    ["Menu"] = "Menü",
    ["Right Three-State Option"] = "Rechte Dreizustandsoption",
    ["Second Option"] = "Zweite Option",
    ["Short "] = "Kurz ",
    ["Test Autolayout"] = "Test Autolayout",
    ["Third Option"] = "Dritte Option",
    ["This is long menu text "] = "Dies ist ein langer Menütext ",
    ["This is long text choice "] = "Dies ist eine lange Textauswahl ",
    ["This is longer option text "] = "Dies ist ein längerer Optionstext ",
}

localization_fr = {
    ["Action Button"] = "Bouton d'action",
    ["Choices"] = "Choix",
    ["First Option"] = "Première Option",
    ["Fourth Option"] = "Quatrième Option",
    ["Left Checkbox Option 1"] = "Option de case à cocher gauche 1",
    ["Left Checkbox Option 2"] = "Option de case à cocher gauche 2",
    ["Menu"] = "Menu",
    ["Right Three-State Option"] = "Option à trois états à droite",
    ["Second Option"] = "Deuxième Option",
    ["Short "] = "Court ",
    ["Test Autolayout"] = "Test Autolayout",
    ["Third Option"] = "Troisième Option",
    ["This is long menu text "] = "Ceci est un long texte de menu ",
    ["This is long text choice "] = "Ceci est un long choix de texte ",
    ["This is longer option text "] = "Ceci est un texte d'option plus long ",
}

localization_zh = {
    ["Action Button"] = "操作按钮",
    ["Choices"] = "选择：",
    ["First Option"] = "第一选项：",
    ["Fourth Option"] = "第四选项：",
    ["Left Checkbox Option 1"] = "左侧复选框选项1",
    ["Left Checkbox Option 2"] = "左侧复选框选项2",
    ["Menu"] = "菜单：",
    ["Right Three-State Option"] = "右侧三态选项",
    ["Second Option"] = "第二选项：",
    ["Short "] = "短 ",
    ["Test Autolayout"] = "测试自动布局",
    ["Third Option"] = "第三选项：",
    ["This is long menu text "] = "这是长菜单文本 ",
    ["This is long text choice "] = "这是长文本选择 ",
    ["This is longer option text "] = "这是更长的选项文本 ",
}

localization_ar = {
    ["Action Button"] = "زر العمل",
    ["Choices"] = "الخيارات",
    ["First Option"] = "الخيار الأول",
    ["Fourth Option"] = "الخيار الرابع",
    ["Left Checkbox Option 1"] = "خيار المربع الأول على اليسار",
    ["Left Checkbox Option 2"] = "خيار المربع الثاني على اليسار",
    ["Menu"] = "القائمة",
    ["Right Three-State Option"] = "خيار الحالة الثلاثية اليمين",
    ["Second Option"] = "الخيار الثاني",
    ["Short "] = "قصير ",
    ["Test Autolayout"] = "اختبار التخطيط التلقائي",
    ["Third Option"] = "الخيار الثالث",
    ["This is long menu text "] = "هذا نص قائمة طويل ",
    ["This is long text choice "] = "هذا خيار نص طويل ",
    ["This is longer option text "] = "هذا نص خيار أطول ",
}

localization_fa = {
    ["Action Button"] = "دکمه عملیات",
    ["Choices"] = "گزینه ها",
    ["First Option"] = "گزینه اول",
    ["Fourth Option"] = "گزینه چهارم",
    ["Left Checkbox Option 1"] = "گزینه چک باکس سمت چپ 1",
    ["Left Checkbox Option 2"] = "گزینه چک باکس سمت چپ 2",
    ["Menu"] = "منو",
    ["Right Three-State Option"] = "گزینه سه حالته سمت راست",
    ["Second Option"] = "گزینه دوم",
    ["Short "] = "کوتاه ",
    ["Test Autolayout"] = "تست خودکار طرح بندی",
    ["Third Option"] = "گزینه سوم",
    ["This is long menu text "] = "این متن منوی طولانی است ",
    ["This is long text choice "] = "این یک انتخاب متن طولانی است ",
    ["This is longer option text "] = "این متن گزینه طولانی تر است ",
}

localization.set_language("fa")

function create_dialog()
    local dlg = mixin.FCXCustomLuaWindow()
    dlg:SetTitle(localization.localize("Test Autolayout"))

    local y = 0
    local line_no = 0
    local y_increment = 22
    local label_edit_separ = 3
    local center_padding = 20

    -- left side
    dlg:CreateStatic(0, line_no * y_increment, "option1-label")
        :DoAutoResizeWidth(true)
        :SetWidth(0)
        :SetText(localization.localize("First Option"))
    dlg:CreateEdit(0, line_no * y_increment - utils.win_mac(2, 3), "option1")
        :SetInteger(1)
        :AssureNoHorizontalOverlap(dlg:GetControl("option1-label"), label_edit_separ)
    line_no = line_no + 1

    dlg:CreateCheckbox(0, line_no * y_increment, "left-checkbox1")
        :DoAutoResizeWidth(true)
        :SetWidth(0)
        :SetText(localization.localize("Left Checkbox Option 1"))
    line_no = line_no + 1

    dlg:CreateStatic(0, line_no * y_increment, "option2-label")
        :DoAutoResizeWidth(true)
        :SetWidth(0)
        :SetText(localization.localize("Second Option"))
    dlg:CreateEdit(0, line_no * y_increment - utils.win_mac(2, 3), "option2")
        :SetInteger(2)
        :AssureNoHorizontalOverlap(dlg:GetControl("option2-label"), label_edit_separ)
        :HorizontallyAlignLeftWith(dlg:GetControl("option1"))
    line_no = line_no + 1

    dlg:CreateCheckbox(0, line_no * y_increment, "left-checkbox2")
        :DoAutoResizeWidth(true)
        :SetWidth(0)
        :SetText(localization.localize("Left Checkbox Option 2"))
    line_no = line_no + 1

    -- center vertical line
    local vertical_line= dlg:CreateVerticalLine(0, 0 - utils.win_mac(2, 3), line_no * y_increment)
        :AssureNoHorizontalOverlap(dlg:GetControl("option1"), center_padding)
        :AssureNoHorizontalOverlap(dlg:GetControl("left-checkbox1"), center_padding)
        :AssureNoHorizontalOverlap(dlg:GetControl("option2"), center_padding)
        :AssureNoHorizontalOverlap(dlg:GetControl("left-checkbox2"), center_padding)
    line_no = 0

    -- right side
    dlg:CreateStatic(0, line_no * y_increment, "option3-label")
        :DoAutoResizeWidth(true)
        :SetWidth(0)
        :SetText(localization.localize("Third Option"))
        :AssureNoHorizontalOverlap(vertical_line, center_padding)
    dlg:CreateEdit(0, line_no * y_increment - utils.win_mac(2, 3), "option3")
        :SetInteger(3)
        :AssureNoHorizontalOverlap(dlg:GetControl("option3-label"), label_edit_separ)
    line_no = line_no + 1

    dlg:CreateCheckbox(0, line_no * y_increment, "right-checkbox1")
        :DoAutoResizeWidth(true)
        :SetWidth(0)
        :SetText(localization.localize("Right Three-State Option"))
        :SetThreeStatesMode(true)
        :AssureNoHorizontalOverlap(vertical_line, center_padding)
    line_no = line_no + 1

    dlg:CreateStatic(0, line_no * y_increment, "option4-label")
        :DoAutoResizeWidth(true)
        :SetWidth(0)
        :SetText(localization.localize("Fourth Option"))
        :AssureNoHorizontalOverlap(vertical_line, center_padding)
    dlg:CreateEdit(0, line_no * y_increment - utils.win_mac(2, 3), "option4")
        :SetInteger(4)
        :AssureNoHorizontalOverlap(dlg:GetControl("option4-label"), label_edit_separ)
        :HorizontallyAlignLeftWith(dlg:GetControl("option3"))
    line_no = line_no + 1

    dlg:CreateButton(0, line_no * y_increment)
        :DoAutoResizeWidth(true)
        :SetWidth(0)
        :SetText(localization.localize("Action Button"))
        :AssureNoHorizontalOverlap(vertical_line, center_padding)
        :HorizontallyAlignRightWith(dlg:GetControl("option4"))
    line_no = line_no + 1

    -- horizontal line here
    dlg:CreateHorizontalLine(0, line_no * y_increment + utils.win_mac(7, 5), 20)
        :StretchToAlignWithRight()
    line_no = line_no + 1

    -- bottom side
    local start_line_no = line_no
    dlg:CreateStatic(0, line_no * y_increment, "popup_label")
        :DoAutoResizeWidth(true)
        :SetWidth(0)
        :SetText(localization.localize("Menu"))
    local ctrl_popup = dlg:CreatePopup(0, line_no * y_increment - utils.win_mac(2, 2), "popup")
        :DoAutoResizeWidth(true)
        :SetWidth(0)
        :AssureNoHorizontalOverlap(dlg:GetControl("popup_label"), label_edit_separ)
    for counter = 1, 3 do
        if counter == 3 then
            ctrl_popup:AddString(finale.FCString(localization.localize("This is long menu text ") .. counter))
        else
            ctrl_popup:AddString(finale.FCString(localization.localize("Short ") .. counter))
        end
    end
    ctrl_popup:SetSelectedItem(0)
    line_no = line_no + 1

    dlg:CreateStatic(0, line_no * y_increment, "cbobox_label")
        :DoAutoResizeWidth(true)
        :SetWidth(0)
        :SetText(localization.localize("Choices"))
    local ctrl_cbobox = dlg:CreateComboBox(0, line_no * y_increment - utils.win_mac(2, 3), "cbobox")
        :DoAutoResizeWidth(true)
        :SetWidth(40)
        :AssureNoHorizontalOverlap(dlg:GetControl("cbobox_label"), label_edit_separ)
        :HorizontallyAlignLeftWith(ctrl_popup)
    for counter = 1, 3 do
        if counter == 3 then
            ctrl_cbobox:AddString(finale.FCString(localization.localize("This is long text choice ") .. counter))
        else
            ctrl_cbobox:AddString(finale.FCString(localization.localize("Short ") .. counter))
        end
    end
    ctrl_cbobox:SetSelectedItem(0)
    line_no = line_no + 1

    line_no = start_line_no
    local ctrl_radiobuttons = dlg:CreateRadioButtonGroup(0, line_no * y_increment, 3)
    local counter = 1
    for rbtn in each(ctrl_radiobuttons) do
        rbtn:SetWidth(0)
            :DoAutoResizeWidth(true)
            :AssureNoHorizontalOverlap(ctrl_popup, 10)
            :AssureNoHorizontalOverlap(ctrl_cbobox, 10)
        if counter == 2 then
            rbtn:SetText(finale.FCString(localization.localize("This is longer option text ") .. counter))
        else
            rbtn:SetText(finale.FCString(localization.localize("Short ") .. counter))
        end
        counter = counter + 1
    end
    line_no = line_no + 2

    dlg:CreateCloseButton(0, line_no * y_increment + 5)
        :HorizontallyAlignRightWithFurthest()
        :DoAutoResizeWidth()

    return dlg
end

global_dialog = global_dialog or create_dialog()
global_dialog:RunModeless()
--global_dialog:ExecuteModal(nil)
