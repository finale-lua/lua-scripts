function plugindef()
    finaleplugin.RequireDocument = false
    finaleplugin.MinJWLuaVersion = 0.71
    return "0--auto resize width test"
end

local utils = require('library.utils')
local mixin = require('library.mixin')
local localization = require('library.localization')

--
-- For scripts in the `src` directory, each localization should be separately stored in the
-- `localization` subdirectory. See the comments in `library/localization.lua` for more details.
-- The localization tables are included here in this sample to keep the sample self-contained.
--

--
-- This table was auto-generated with `utilities/localization_tool.lua`
-- Then it was edited to include only the strings that need to be localized.
--
localization.Base = -- this is en_GB due to spelling of "Localisation"
{
    action_button = "Action Button",
    choices = "Choices",
    close = "Close",
    first_option = "First Option",
    fourth_option = "Fourth Option",
    left_checkbox1 = "Left Checkbox Option 1",
    left_checkbox2 = "Left Checkbox Option 2",
    menu = "Menu",
    right_three_state = "Right Three-State Option",
    second_option = "Second Option",
    short = "Short %d",
    test_autolayout = "Test Autolayout With Localisation",
    third_option = "Third Option",
    long_menu_text = "This is long menu text %d",
    long_text_choice = "This is long text choice %d",
    longer_option_text = "This is longer option text %d",
}

localization.en_US =
{
    test_autolayout = "Test Autolayout With Localization"
}

--
-- The rest of the localization tables were created one-at-a-time with the `utilities/localization_tool.lua` script.
--
localization.es = {
    action_button = "Botón de Acción",
    choices = "Opciones",
    close = "Cerrar",
    first_option = "Primera Opción",
    fourth_option = "Cuarta Opción",
    left_checkbox1 = "Opción de Casilla de Verificación Izquierda 1",
    left_checkbox2 = "Opción de Casilla de Verificación Izquierda 2",
    menu = "Menú",
    right_three_state = "Opción de Tres Estados a la Derecha",
    second_option = "Segunda Opción",
    short = "Corto %d",
    test_autolayout = "Prueba de Autodiseño con Localización",
    third_option = "Tercera Opción",
    long_menu_text = "Este es un texto de menú largo %d",
    long_text_choice = "Esta es una elección de texto largo %d",
    longer_option_text = "Este es un texto de opción más largo %d",
}

--
-- This table was auto-generated with `utilities/localization_tool.lua`
--
localization.ja = {
    action_button = "アクションボタン",
    choices = "選択肢",
    close = "閉じる",
    first_option = "最初のオプション",
    fourth_option = "第四のオプション",
    left_checkbox1 = "左チェックボックスオプション1",
    left_checkbox2 = "左チェックボックスオプション2",
    menu = "メニュー",
    right_three_state = "右三状態オプション",
    second_option = "第二のオプション",
    short = "短い %d",
    test_autolayout = "ローカリゼーションでのオートレイアウトのテスト",
    third_option = "第三のオプション",
    long_menu_text = "これは第%d長いメニューテキストです",
    long_text_choice = "これは第%d長いテキストの選択です",
    longer_option_text = "これは第%dより長いオプションテキストです ",
}

--
-- This table was auto-generated with `utilities/localization_tool.lua`
--
localization.de = {
    action_button = "Aktionsknopf",
    choices = "Auswahlmöglichkeiten",
    close = "Schließen",
    first_option = "Erste Option",
    fourth_option = "Vierte Option",
    left_checkbox1 = "Linke Checkbox Option 1",
    left_checkbox2 = "Linke Checkbox Option 2",
    menu = "Menü",
    right_three_state = "Rechte Dreizustandsoption",
    second_option = "Zweite Option",
    short = "Kurz %d",
    test_autolayout = "Test von Autolayout mit Lokalisierung",
    third_option = "Dritte Option",
    long_menu_text = "Dies ist ein langer Menütext %d",
    long_text_choice = "Dies ist eine lange Textauswahl %d",
    longer_option_text = "Dies ist ein längerer Optionstext %d",
}

localization.fr = {
    action_button = "Bouton d'action",
    choices = "Choix",
    close = "Close",
    first_option = "Première Option",
    fourth_option = "Quatrième Option",
    left_checkbox1 = "Option de case à cocher gauche 1",
    left_checkbox2 = "Option de case à cocher gauche 2",
    menu = "Menu",
    right_three_state = "Option à trois états à droite",
    second_option = "Deuxième Option",
    short = "Court %d",
    test_autolayout = "Test de AutoLayout avec Localisation",
    third_option = "Troisième Option",
    long_menu_text = "Ceci est un long texte de menu %d",
    long_text_choice = "Ceci est un long choix de texte %d",
    longer_option_text = "Ceci est un texte d'option plus long %d",
}

localization.zh = {
    action_button = "操作按钮",
    choices = "选择：",
    close = "关闭",
    first_option = "第一选项：",
    fourth_option = "第四选项：",
    left_checkbox1 = "左侧复选框选项1",
    left_checkbox2 = "左侧复选框选项2",
    menu = "菜单：",
    right_three_state = "右侧三态选项",
    second_option = "第二选项：",
    short = "短 %d",
    test_autolayout = "自动布局与本地化测试",
    third_option = "第三选项：",
    long_menu_text = "这是长菜单文本 %d",
    long_text_choice = "这是长文本选择 %d",
    longer_option_text = "这是更长的选项文本 %d",
}

localization.ar = {
    action_button = "زر العمل",
    choices = "الخيارات",
    close = "إغلاق",
    first_option = "الخيار الأول",
    fourth_option = "الخيار الرابع",
    left_checkbox1 = "خيار المربع الأول على اليسار",
    left_checkbox2 = "خيار المربع الثاني على اليسار",
    menu = "القائمة",
    right_three_state = "خيار الحالة الثلاثية اليمين",
    second_option = "الخيار الثاني",
    short = "قصير %d",
    test_autolayout = "اختبار التخطيط التلقائي مع التعريب",
    third_option = "الخيار الثالث",
    long_menu_text = "هذا نص قائمة طويل %d",
    long_text_choice = "هذا خيار نص طويل %d",
    longer_option_text = "هذا نص خيار أطول %d",
}

localization.fa = {
    action_button = "دکمه عملیات",
    choices = "گزینه ها",
    close = "بستن",
    first_option = "گزینه اول",
    fourth_option = "گزینه چهارم",
    left_checkbox1 = "گزینه چک باکس سمت چپ 1",
    left_checkbox2 = "گزینه چک باکس سمت چپ 2",
    menu = "منو",
    right_three_state = "گزینه سه حالته سمت راست",
    second_option = "گزینه دوم",
    short = "کوتاه %d",
    test_autolayout = "تست آتولایوت با بومی سازی",
    third_option = "گزینه سوم",
    long_menu_text = "این متن منوی طولانی است %d",
    long_text_choice = "این یک انتخاب متن طولانی است %d",
    longer_option_text = "این متن گزینه طولانی تر است %d",
}

localization.set_locale("es")

function create_dialog()
    local dlg = mixin.FCXCustomLuaWindow()
    dlg:SetTitleLocalized("test_autolayout")

    local line_no = 0
    local y_increment = 22
    local label_edit_separ = 3
    local center_padding = 20

    -- left side
    dlg:CreateStatic(0, line_no * y_increment, "option1-label")
        :DoAutoResizeWidth(0)
        :SetTextLocalized("first_option")
    dlg:CreateEdit(0, line_no * y_increment - utils.win_mac(2, 3), "option1")
        :SetInteger(1)
        :AssureNoHorizontalOverlap(dlg:GetControl("option1-label"), label_edit_separ)
    line_no = line_no + 1

    dlg:CreateCheckbox(0, line_no * y_increment, "left-checkbox1")
        :DoAutoResizeWidth(0)
        :SetTextLocalized("left_checkbox1")
    line_no = line_no + 1

    dlg:CreateStatic(0, line_no * y_increment, "option2-label")
        :DoAutoResizeWidth(0)
        :SetTextLocalized("second_option")
    dlg:CreateEdit(10, line_no * y_increment - utils.win_mac(2, 3), "option2")
        :SetInteger(2)
        :AssureNoHorizontalOverlap(dlg:GetControl("option2-label"), label_edit_separ)
        :HorizontallyAlignLeftWith(dlg:GetControl("option1"))
    line_no = line_no + 1

    dlg:CreateCheckbox(0, line_no * y_increment, "left-checkbox2")
        :DoAutoResizeWidth(0)
        :SetTextLocalized("left_checkbox2")
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
        :DoAutoResizeWidth(0)
        :SetTextLocalized("third_option")
        :AssureNoHorizontalOverlap(vertical_line, center_padding)
    dlg:CreateEdit(0, line_no * y_increment - utils.win_mac(2, 3), "option3")
        :SetInteger(3)
        :AssureNoHorizontalOverlap(dlg:GetControl("option3-label"), label_edit_separ)
    line_no = line_no + 1

    dlg:CreateCheckbox(0, line_no * y_increment, "right-checkbox1")
        :DoAutoResizeWidth(0)
        :SetTextLocalized("right_three_state")
        :SetThreeStatesMode(true)
        :AssureNoHorizontalOverlap(vertical_line, center_padding)
    line_no = line_no + 1

    dlg:CreateStatic(0, line_no * y_increment, "option4-label")
        :DoAutoResizeWidth(0)
        :SetTextLocalized("fourth_option")
        :AssureNoHorizontalOverlap(vertical_line, center_padding)
    dlg:CreateEdit(0, line_no * y_increment - utils.win_mac(2, 3), "option4")
        :SetInteger(4)
        :AssureNoHorizontalOverlap(dlg:GetControl("option4-label"), label_edit_separ)
        :HorizontallyAlignLeftWith(dlg:GetControl("option3"))
    line_no = line_no + 1

    dlg:CreateButton(0, line_no * y_increment)
        :DoAutoResizeWidth()
        :SetTextLocalized("action_button")
        :AssureNoHorizontalOverlap(vertical_line, center_padding)
        :HorizontallyAlignRightWith(dlg:GetControl("option4"))
--        :HorizontallyAlignRightWithFurthest()
    line_no = line_no + 1

    -- horizontal line here
    dlg:CreateHorizontalLine(0, line_no * y_increment + utils.win_mac(7, 5), 20)
        :StretchToAlignWithRight()
    line_no = line_no + 1

    -- bottom side
    local start_line_no = line_no
    dlg:CreateStatic(0, line_no * y_increment, "popup_label")
        :DoAutoResizeWidth(0)
        :SetTextLocalized("menu")
    local ctrl_popup = dlg:CreatePopup(0, line_no * y_increment - utils.win_mac(2, 2), "popup")
        :DoAutoResizeWidth(0)
        :AssureNoHorizontalOverlap(dlg:GetControl("popup_label"), label_edit_separ)
    for counter = 1, 3 do
        local format_string
        if counter == 3 then
            format_string = localization.localize("long_menu_text")
        else
            format_string = localization.localize("short")
        end
        ctrl_popup:AddString(string.format(format_string, counter))
    end
    ctrl_popup:SetSelectedItem(0)
    line_no = line_no + 1

    dlg:CreateStatic(0, line_no * y_increment, "cbobox_label")
        :DoAutoResizeWidth(0)
        :SetTextLocalized("choices")
    local ctrl_cbobox = dlg:CreateComboBox(0, line_no * y_increment - utils.win_mac(2, 3), "cbobox")
        :DoAutoResizeWidth(40)
        :AssureNoHorizontalOverlap(dlg:GetControl("cbobox_label"), label_edit_separ)
        :HorizontallyAlignLeftWith(ctrl_popup)
    for counter = 1, 3 do
        local format_string
        if counter == 3 then
            format_string = localization.localize("long_text_choice")
        else
            format_string = localization.localize("short")
        end
        ctrl_cbobox:AddString(string.format(format_string, counter))
    end
    ctrl_cbobox:SetSelectedItem(0)
    line_no = line_no + 1 -- luacheck: ignore

    line_no = start_line_no
    local ctrl_radiobuttons = dlg:CreateRadioButtonGroup(0, line_no * y_increment, 3)
    local counter = 1
    for rbtn in each(ctrl_radiobuttons) do
        rbtn:DoAutoResizeWidth(0)
            :AssureNoHorizontalOverlap(ctrl_popup, 10)
            :AssureNoHorizontalOverlap(ctrl_cbobox, 10)
        local format_string
        if counter == 2 then
            format_string = localization.localize("longer_option_text")
        else
            format_string = localization.localize("short")
        end
        rbtn:SetText(string.format(format_string, counter))
        counter = counter + 1
    end
    line_no = line_no + 2

    dlg:CreateCloseButton(0, line_no * y_increment + 5)
        :SetTextLocalized("close")
        :DoAutoResizeWidth()
        :HorizontallyAlignRightWithFurthest()

    return dlg
end

global_dialog = global_dialog or create_dialog()
global_dialog:RunModeless()
--global_dialog:ExecuteModal(nil)
