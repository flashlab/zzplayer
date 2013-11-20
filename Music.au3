#region ;**** 参数创建于 ACNWrapper_GUI ****
#AutoIt3Wrapper_Icon=mu.ico
#AutoIt3Wrapper_UseUPX=n
#AutoIt3Wrapper_Res_FileVersion=2.0.0.0
#AutoIt3Wrapper_Run_Tidy=y
#Autoit3Wrapper_Run_Obfuscator=y
#Obfuscator_Parameters= /SO /OM
#Obfuscator_On
#endregion ;**** 参数创建于 ACNWrapper_GUI ****
;ver 0.0.0.4
#include 'MyConstants.au3'
#include 'desklrc.au3'
#include 'lyric.au3'
#include 'lrcPrase.au3'
#include "DoDragDrop.au3"
#include "GUICtrlMenuEx.au3"

Opt("GUIOnEventMode", 1)
Opt("TrayOnEventMode", 1)
Opt("GUIResizeMode", 802)
Opt("MouseCoordMode", 0)
Opt("TrayMenuMode", 1)
;~ Opt("TrayIconDebug", 1)
OnAutoItExitRegister("_OnAutoItExit")
HotKeySet('+!i', 'ID') ;hotkey for showing ID3 tags

$FilesDir = @ScriptDir & '\ICON'
Global $cover_put = @ScriptDir & "\ICON\music-default.jpg"
DirCreate($FilesDir)
FileInstall('music-default.jpg', $FilesDir & '\music-default.jpg')
FileInstall('test.png', $FilesDir & '\test.png')

_BASS_STARTUP("BASS.dll");打开BASS.DLL，开放可调用函数
_Bass_PluginLoad("bassflac.dll")
_Bass_PluginLoad("bass_ape.dll")
_Bass_PluginLoad("basswma.dll")
_Bass_PluginLoad('bass_aac.dll')
_BASS_Init(0, -1, 44100, 0, "");函数初始化
If @error Then
	MsgBox(0, "Error Code: " & @error, "无法使用音频播放功能，请检查设备是否正常！", 4)
;~ 	Exit
EndIf

Global $IDragSourceHelper = _ObjCoCreateInstance($CLSID_DragDropHelper, $IID_IDragSourceHelper, $IDragSourceHelper_vTable)
;~ Global Const $CDDS_SUBITEMPREPAINT = BitOR($CDDS_ITEM, $CDDS_SUBITEM, $CDDS_PREPAINT)
Global $Font1 = _WinAPI_CreateFont(14, 0, 0, 0, $FW_BOLD)
;~ Global $Font2 = _WinAPI_CreateFont(17, 0, 0, 0, $FW_NORMAL, False, False, False, $DEFAULT_CHARSET, $OUT_DEFAULT_PRECIS, _
;~ 		$CLIP_DEFAULT_PRECIS, $DEFAULT_QUALITY, 0, 'Arial')

;~ Global $skins = @ScriptDir & "\Mecca.msstyles"
;~ Global $Dll_ = DllOpen(@ScriptDir & "\USkin.dll")
;~ DllCall($Dll_, "int", "USkinInit", "str", "Null", "str", "NULL", "str", $skins)  ;loading skin dll.
;~ DllCall($Dll_, "int", "USkinLoadSkin", "str", $skins) ;  initialize skin
$ShellContextMenu = ObjCreate("ExplorerShellContextMenu.ShowContextMenu")
;~ tray begin
TraySetIcon(@ScriptDir & '\icon.dll', 14)
$play_control = TrayCreateMenu("播放控制")
$tray_play = TrayCreateItem("播放/暂停", $play_control)
TrayItemSetOnEvent(-1, "tray")
$tray_stop = TrayCreateItem("停止", $play_control)
TrayItemSetOnEvent(-1, "tray")
TrayCreateItem("")
$exit = TrayCreateItem("退出")
TrayItemSetOnEvent(-1, '_Exit')
TraySetOnEvent($TRAY_EVENT_PRIMARYUP, "SpecialEvent")
TraySetClick(8)
TraySetState()
Func SpecialEvent()
	GUISetState(@SW_SHOW, $hGUI)
EndFunc   ;==>SpecialEvent
;~ tray end

$hGUI = GUICreate("音乐管理器 v2.0", 781, 562, -1, -1, 0x94CE0000, 0x00000010)
$col_def = GUIGetBkColor($hGUI)
GUISetOnEvent($GUI_EVENT_CLOSE, "gui")
GUISetOnEvent($GUI_EVENT_RESTORE, "gui")
GUISetOnEvent($GUI_EVENT_RESIZED, "gui")
GUISetOnEvent($GUI_EVENT_MINIMIZE, "gui")
$hcontextmenu = GUICtrlCreateContextMenu()
$hColor = GUICtrlCreateMenu("界面颜色", $hcontextmenu)
$col_1 = GUICtrlCreateMenuItem("系统默认", $hColor)
GUICtrlSetOnEvent(-1, "guicolor")
$col_2 = GUICtrlCreateMenuItem("粉红", $hColor)
GUICtrlSetOnEvent(-1, "guicolor")
$col_3 = GUICtrlCreateMenuItem("鸭黄", $hColor)
GUICtrlSetOnEvent(-1, "guicolor")
$col_4 = GUICtrlCreateMenuItem("水绿", $hColor)
GUICtrlSetOnEvent(-1, "guicolor")
$col_5 = GUICtrlCreateMenuItem("纯白", $hColor)
GUICtrlSetOnEvent(-1, "guicolor")
$col_6 = GUICtrlCreateMenuItem("纯黑", $hColor)
GUICtrlSetOnEvent(-1, "guicolor")
$hListView = GUICtrlCreateListView("      文件名        |歌名          |歌手       |   专辑        |  位速  | 大小  | 时长 |文件夹", _
		8, 92, 764, _Iif($onlylist = 2, 437, 214), BitOR($LVS_EDITLABELS, $LVS_REPORT, $LVS_SHOWSELALWAYS))
_GUICtrlListView_SetExtendedListViewStyle($hListView, BitOR($LVS_EX_FULLROWSELECT, $LVS_EX_HEADERDRAGDROP, $LVS_EX_DOUBLEBUFFER))
GUICtrlSetResizing(-1, 102)
$hHeader = HWnd(_GUICtrlListView_GetHeader($hListView))
_WinAPI_SetFont($hHeader, $Font1, True)
_GUICtrlListView_SetColumnWidth($hListView, 0, 250)
_GUICtrlListView_SetUnicodeFormat($hListView, True)
_WinAPI_SetWindowTheme(GUICtrlGetHandle($hListView), 'Explorer')

_GUICtrlListView_SetImageList($hListView, _GUIImageList_GetSystemImageList(), 1)
$l_btn_header = GUICtrlCreateButton('载入LRC文件', 8, 321, _Iif($onlylist = 1, 764, 500), 25)
GUICtrlSetState(-1, $GUI_DISABLE)
GUICtrlSetResizing(-1, 582)
GUICtrlSetOnEvent(-1, "gui")
;~ $Lrc_List = _GUICtrlListView_Create($hGUI, "歌词", 8, 321, 500, 214, BitOR($LVS_EDITLABELS, $LVS_REPORT))

$Lrc_List = GUICtrlCreateListView('lyrics', 8, 346, _Iif($onlylist = 1, 764, 500), 190, BitOR($LVS_REPORT, $LVS_EDITLABELS, $LVS_NOCOLUMNHEADER))
_GUICtrlListView_SetExtendedListViewStyle(-1, BitOR($LVS_EX_FULLROWSELECT, $WS_EX_CLIENTEDGE, $LVS_EX_DOUBLEBUFFER))
GUICtrlSetResizing(-1, 582)
$hWndListView = GUICtrlGetHandle($hListView)
$lWndListView = GUICtrlGetHandle($Lrc_List)
_GUICtrlListView_SetColumnWidth(-1, 0, $LVSCW_AUTOSIZE_USEHEADER)
_GUICtrlListView_SetUnicodeFormat(-1, True)
_GUICtrlListView_JustifyColumn(-1, 0, $list_align)
;~ _WinAPI_SetFont($Lrc_List, $Font2, True)    ;;Conflict with _GUICtrlListView_SetUnicodeFormat
GUICtrlSetFont(-1, $list_size, $list_xing, $list_var, $list_name)
GUICtrlSetColor(-1, $lrc_text_back_color)
GUICtrlSetBkColor(-1, $list_bk_color)
_GUICtrlListView_SetItemCount(-1, 6)
For $i = 0 To 5
	GUICtrlCreateListViewItem($L[$i], $Lrc_List)
Next
GUICtrlCreateGroup("播放控制", 535, 8, 235, 80)
;~ GUICtrlSetColor(-1, 0xff0000)
$Sound_Flag = GUICtrlCreateButton("=", 545, 48, 30, 25, $BS_FLAT)
GUICtrlSetFont(-1, 14, 800, 0, "Webdings")
;~ GUICtrlSetBkColor(-1, 0xD4D0C8)              ;control will disappear
;~ GUICtrlSetColor(-1, 0x000000)
GUICtrlSetOnEvent(-1, "gui")
$Sound_Play = GUICtrlCreateButton("4", 575, 48, 30, 25, $BS_FLAT)
GUICtrlSetFont(-1, 14, 800, 0, "Webdings")
GUICtrlSetOnEvent(-1, "gui")
$Sound_Stop = GUICtrlCreateButton("<", 605, 48, 30, 25, $BS_FLAT)
GUICtrlSetFont(-1, 14, 800, 0, "Webdings")
GUICtrlSetOnEvent(-1, "gui")
GUICtrlSetState(-1, $GUI_DISABLE)
$Sound_Desk = GUICtrlCreateButton("显示", 640, 48, 40, 25, $BS_FLAT)
GUICtrlSetOnEvent(-1, "gui")
$current_time = GUICtrlCreateLabel('00:00:00', 687, 50, 65, 25)
GUICtrlSetFont(-1, 12, 400, 0, 'Arial')
GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)
$slider = GUICtrlCreateSlider(540, 20, 220, 21, $TBS_NOTICKS)
GUICtrlSetData(-1, 0)
GUICtrlSetLimit(-1, 100, 1)
GUICtrlSetTip(-1, "播放进度")

;~ $filter = _GUICtrlComboBox_Create($hGUI, "", 45, 69, 125, 21)
$filter = GUICtrlCreateCombo("", 45, 69, 125, 21)
GUICtrlSetData(-1, "<\.mp3(?# 仅mp3文件)>|<^[\w\s\']+\.[\w]{2,4}(?# 仅英文文件名)>|<林俊杰(?# 指定歌手)>|<.*?(?# 所有歌曲)>", "")
$artist = GUICtrlCreateInput("", 180, 69, 82, 19)
GUICtrlSetTip(-1, '歌手')
$title = GUICtrlCreateInput("", 281, 69, 146, 19)
GUICtrlSetTip(-1, '歌名')
;~ GUICtrlSetOnEvent($title, "gui")
$Search_Button = GUICtrlCreateButton("搜索", 430, 67, 49, 23)
_GUICtrlButton_SetImageList($Search_Button, _GetImageListHandle("icon.dll", 11), 0)
GUICtrlSetOnEvent(-1, "gui")
$SearchDummy = GUICtrlCreateDummy()
$context_button = GUICtrlCreateContextMenu($SearchDummy)
$sogou_srh = GUICtrlCreateMenuItem("搜狗音乐", $context_button)
GUICtrlSetOnEvent($sogou_srh, "gui")
$google_srh = GUICtrlCreateMenuItem("谷歌音乐", $context_button)
GUICtrlSetOnEvent($google_srh, "gui")
$baidu_srh = GUICtrlCreateMenuItem("百度音乐", $context_button)
GUICtrlSetOnEvent($baidu_srh, "gui")
$bar = GUICtrlCreateButton("q", 262, 69, 19, 18, $BS_FLAT)
GUICtrlSetFont(-1, 12, 600, 0, "Webdings")
GUICtrlSetOnEvent($bar, 'gui')
$Search_Label1 = GUICtrlCreateLabel("过滤", 12, 73, 30, 17)
_ToolBar()
$cover_group = GUICtrlCreateGroup("专辑封面", 535, 321, 220, 216)
;~ GUICtrlSetColor(-1, 0xff0000)
GUICtrlSetResizing(-1, 836)
$cover = GUICtrlCreatePic($cover_put, 553, 340, 182, 182) ;$WS_EX_CLIENTEDGE will cause dislocation while update pic control
GUICtrlSetResizing(-1, 836)
$context_cover = GUICtrlCreateContextMenu($cover)
$save_cover = GUICtrlCreateMenuItem("封面另存为", $context_cover)
GUICtrlSetOnEvent($save_cover, "gui")
GUICtrlCreateMenuItem('', $context_cover)
$download_cover = GUICtrlCreateMenuItem('下载封面', $context_cover)
GUICtrlSetOnEvent($download_cover, "gui")

Switch $onlylist
	Case 2
		GUICtrlSetState($Lrc_List, $GUI_HIDE)
		GUICtrlSetState($l_btn_header, $GUI_HIDE)
		GUICtrlSetState($cover, $GUI_HIDE)
		GUICtrlSetState($cover_group, $GUI_HIDE)
	Case 1
		GUICtrlSetState($cover, $GUI_HIDE)
		GUICtrlSetState($cover_group, $GUI_HIDE)
EndSwitch

$ListMenu = GUICtrlCreateDummy()
GUICtrlSetOnEvent(-1, "_ListMenu_Click")
$Tbar = GUICtrlCreateDummy()
GUICtrlSetOnEvent(-1, "_ToolBar_Click")
$TbarMenu = GUICtrlCreateDummy()
GUICtrlSendToDummy(-1, 2000)
GUICtrlSetOnEvent(-1, "_ToolBarMenu")
$LyrMenu = GUICtrlCreateDummy()
GUICtrlSetOnEvent(-1, "_LyrMenu_Click")
$FileChange = GUICtrlCreateDummy()
GUICtrlSetOnEvent(-1, "_FileChange")
_CoProcReciver("Reciver")
$load_Pro = _CoProc("_load_")
;=====================for obfuscated
;~ Reciver()
;~ _load_()
;~ _loadReciver()
;~ __CoProcReciverHandler($hWnd, $iMsg, $WParam, $LParam)
;~ __CoProcDummy()
;~ move_list($hWnd, $iMsg, $WParam, $LParam)
;=====================
$StatusBar = _GUICtrlStatusBar_Create($hGUI, -1, "", $SBARS_TOOLTIPS)
_GUICtrlStatusBar_SetMinHeight($StatusBar, 20)
_GUICtrlStatusBar_SetParts($StatusBar, $StatusBar_PartsWidth)
$hIcons[0] = _WinAPI_LoadShell32Icon(-14)
$hIcons[1] = _WinAPI_LoadShell32Icon(-28)
$hIcons[18] = _WinAPI_LoadShell32Icon(-55)
_GUICtrlStatusBar_SetIcon($StatusBar, 0, $hIcons[0])
_GUICtrlStatusBar_SetText($StatusBar, "欢迎使用！", 1)
_GUICtrlStatusBar_SetTipText($StatusBar, 0, "测试网络中。。。")
$L_process = GUICtrlCreateProgress(0, 0, -1, -1, $PBS_MARQUEE)
_GUICtrlStatusBar_EmbedControl($StatusBar, 3, GUICtrlGetHandle($L_process))

;~ ----------选择歌词----------------
$Lrc_Choose = GUICreate("选择歌词", 350, 210, 10, 100, -1, -1, $hGUI)
GUISetOnEvent($GUI_EVENT_CLOSE, "gui")
$sub_list = GUICtrlCreateListView('   1     |      2      |      3      |     4     | 5 | 6 ', 10, 10, 330, 170, Default, BitOR($LVS_EX_FULLROWSELECT, $LVS_EX_DOUBLEBUFFER))
_GUICtrlListView_SetUnicodeFormat($sub_list, True)
_WinAPI_SetWindowTheme(GUICtrlGetHandle($sub_list), 'Explorer')
$sub_OK = GUICtrlCreateButton('下载', 9, 185, 330, 20)
GUICtrlSetOnEvent(-1, "gui")
GUICtrlSetState(-1, $GUI_FOCUS + $GUI_DEFBUTTON)
GUISetState(@SW_HIDE, $Lrc_Choose)
GUISwitch($hGUI)
guicolor($GUI_color)
GUISetState(@SW_SHOW, $hGUI)

GUIRegisterMsg($WM_NOTIFY, "_WM_NOTIFY")
GUIRegisterMsg($WM_COMMAND, "MY_WM_COMMAND")
GUIRegisterMsg(0x233, "WM_DROPFILES") ;WM_DROPFILES
GUIRegisterMsg($WM_HSCROLL, "MY_WM_HSCROLL")
GUIRegisterMsg($WM_EXITSIZEMOVE, "WM_EXITSIZEMOVE")
GUIRegisterMsg($WM_SYSCOMMAND, "On_WM_SYSCOMMAND")
GUIRegisterMsg($WM_MOUSEWHEEL, "WM_MOUSEWHEEL")
;~ GUIRegisterMsg($WM_DI_GETDRAGIMAGE, "MY_GETDRAGIMAGE")

;~ GUIRegisterMsg($WM_GETMINMAXINFO, "WM_GETMINMAXINFO")  ;cause GDI+ working not perfect
;~ GUIRegisterMsg($WM_PAINT, "MY_PAINT")   ; TOO MUCH FLICKERING!!
;~ GUIRegisterMsg($WM_SIZE, "WM_SIZE")
;~ WinMove($hGUI,"",0,0)

_GUICtrlMenuEx_Startup(Default)

For $x = 7 To 22
	$hIcons[$x - 5] = _WinAPI_ShellExtractIcons("icon.dll", $x, 16, 16)
Next
$SubsubMenu1 = _GUICtrlMenu_CreateMenu()
_GUICtrlMenuEx_AddMenuItem($SubsubMenu1, "编辑ID3标签", $id3_item, $hIcons[10])
_GUICtrlMenuEx_AddMenuItem($SubsubMenu1, "删除ID3标签", $del_id3_item, $hIcons[9])
$SubsubMenu2 = _GUICtrlMenu_CreateMenu()
_GUICtrlMenuEx_AddMenuItem($SubsubMenu2, "读取内嵌歌词(ID3v2)", $copy_lyr_item, $hIcons[12])
_GUICtrlMenuEx_AddMenuItem($SubsubMenu2, "读取内嵌歌词(Lyricv3)", $copy_qq_item, $hIcons[11])
$SubsubMenu3 = _GUICtrlMenu_CreateMenu()
_GUICtrlMenuEx_AddMenuItem($SubsubMenu3, "+1秒", $yh1)
_GUICtrlMenuEx_AddMenuItem($SubsubMenu3, "+500毫秒", $yh2)
_GUICtrlMenuEx_AddMenuItem($SubsubMenu3, "-500毫秒", $tq1)
_GUICtrlMenuEx_AddMenuItem($SubsubMenu3, "-1秒", $tq2)

$SubMenu = _GUICtrlMenu_CreatePopup()
_GUICtrlMenuEx_AddMenuItem($SubMenu, "重命名", $rn_item)
_GUICtrlMenuEx_AddMenuItem($SubMenu, "复制", $copy_item, $hIcons[2])
_GUICtrlMenuEx_AddMenuItem($SubMenu, "重新载入", $reload_item, $hIcons[5])
_GUICtrlMenuEx_AddMenuItem($SubMenu, "编辑属性", $edit_item, $hIcons[4])
_GUICtrlMenuEx_AddMenuItem($SubMenu, "下载封面", $load_cover, $hIcons[3])
_GUICtrlMenuEx_AddMenuItem($SubMenu, "放入回收站", $rm_item, $hIcons[16])
_GUICtrlMenuEx_AddMenuBar($SubMenu)
_GUICtrlMenuEx_AddMenuItem($SubMenu, "ID3标签", 0, $hIcons[1], $SubsubMenu1)
_GUICtrlMenuEx_AddMenuItem($SubMenu, "内嵌歌词", 0, $hIcons[7], $SubsubMenu2)
If IsObj($ShellContextMenu) Then _GUICtrlMenuEx_AddMenuItem($SubMenu, "more... ", $shell_item, $hIcons[14])

$SubMenu2 = _GUICtrlMenu_CreatePopup()
_GUICtrlMenuEx_AddMenuItem($SubMenu2, "提前200毫秒", $tq, $hIcons[14])
_GUICtrlMenuEx_AddMenuItem($SubMenu2, "延后200毫秒", $yh, $hIcons[13])
_GUICtrlMenuEx_AddMenuItem($SubMenu2, "更多调整", 0, $hIcons[18], $SubsubMenu3)
_GUICtrlMenuEx_AddMenuBar($SubMenu2)
_GUICtrlMenuEx_AddMenuItem($SubMenu2, "修改文件头", $hd, $hIcons[15])
_GUICtrlMenuEx_AddMenuItem($SubMenu2, "删除选中行", $sc, $hIcons[16])
_GUICtrlMenuEx_AddMenuItem($SubMenu2, "插入新的一行", $cr, $hIcons[17])

While 1

	Sleep(200)
WEnd

Func gui()
	Switch @GUI_CtrlId
		Case $GUI_EVENT_CLOSE
			Switch @GUI_WinHandle
				Case $hGUI
					_exit()
				Case $Lrc_Choose
					$coverStartIndex = 0
					GUISetState(@SW_ENABLE, $hGUI)
					ContinueCase
				Case Else
					GUISetState(@SW_HIDE, @GUI_WinHandle)
			EndSwitch
		Case $GUI_EVENT_RESTORE, $GUI_EVENT_RESIZED
			If @GUI_WinHandle = $hGUI Then
				_loadpic()
				_GUICtrlStatusBar_EmbedControl($StatusBar, 3, GUICtrlGetHandle($L_process))
			EndIf
		Case $GUI_EVENT_MINIMIZE
			_ReduceMemory(@AutoItPID)
		Case $Sound_Desk
			If GUICtrlRead($Sound_Desk) = '显示' Then
				GUICtrlSetData($Sound_Desk, '隐藏')
				Show_desk()
			Else
				GUICtrlSetData($Sound_Desk, '显示')
				Hide_desk()
			EndIf
		Case $Sound_Play
			_Play()
		Case $Sound_Stop
			_StopPlay()
		Case $Sound_Flag
			If GUICtrlRead($Sound_Flag) = '`' Then
				GUICtrlSetData($Sound_Flag, '=')
				$s_flag = False
			Else
				GUICtrlSetData($Sound_Flag, '`')
				$s_flag = True
			EndIf
		Case $sub_OK
			GUICtrlSetState($sub_OK, $GUI_DISABLE)
			Dim $lrc_Format
			Local $Index = _GUICtrlListView_GetItemTextString($sub_list)
			Dim $pre_get = StringSplit($Index, '|', 2)
			If $pre_get[0] And UBound($pre_get) = 6 Then
				$load_flag = 0
				If $mode = 1 Then
					If _CoProcSend($load_Pro, _LrcDownLoad_qianqian($pre_get[0], $pre_get[1], $pre_get[2], $isCnc)) Then
						_ShowLoading()
					Else
						_ToolTip('错误', "Worker not Responding (" & @error & ")", 3, 3)
					EndIf
				ElseIf $mode = 2 Then
					If _CoProcSend($load_Pro, 'viewlyrics.com' & '|' & StringTrimLeft($pre_get[0], 21) & '|2' & '||||') Then
						_ShowLoading()
					Else
						_ToolTip('错误', "Worker not Responding (" & @error & ")", 3, 3)
					EndIf
				ElseIf $mode = 3 Then
					$host = 'newlyric.koowo.com'
					$url = '/newlyric.lrc?' & _encode(_UrlToHex(StringFormat('user=377471152,LYRIC_1.2.1.5,KwLyric(1).exe,' & _
							'wmp&requester=localhost&type=full&req=3&songname=%s&artist=%s&path=%s&FileName=&zipsig=', _
							$pre_get[2], $pre_get[1], $pre_get[0]), 1, 'ansi'))
					If _CoProcSend($load_Pro, $host & '|' & $url & '|2' & '||||') Then
						_ShowLoading()
					Else
						_ToolTip('错误', "Worker not Responding (" & @error & ")", 3, 3)
					EndIf
				ElseIf $mode = 4 Then
					If _CoProcSend($load_Pro, 'www.5ilrc.com|/downlrc.asp|0||POST|gm_down=%31&id_gc=' & _
						StringTrimLeft(StringTrimRight($pre_get[0], 4), 6)&'|http://www.5ilrc.com|Content-Type: application/x-www-form-urlencoded') Then
						_ShowLoading()
					Else
						_ToolTip('错误', "Worker not Responding (" & @error & ")", 3, 3)
					EndIf
				ElseIf $mode = 9 Then
					If _CoProcSend($load_Pro, 'music.qq.com|/miniportal/static/lyric/' & _
							StringRight($pre_get[0], 2) & '/' & $pre_get[0] & '.xml|0||||') Then
						_ShowLoading()
					Else
						_ToolTip('错误', "Worker not Responding (" & @error & ")", 3, 3)
					EndIf
				ElseIf $mode = 6 Then
					$load_flag = 1
					Local $currentSel
					$currentSel = Number(_GUICtrlListView_GetSelectedIndices($sub_list))
					If $douban2[$currentSel][0] = '<<' Then
						$coverStartIndex -= 30
						$cover_key_input = $douban2[$currentSel][1]
						GUICtrlSendToDummy($ListMenu, $load_cover)
					ElseIf $douban2[$currentSel][0] = '>>' Then
						$coverStartIndex += 30
						$cover_key_input = $douban2[$currentSel][1]
						GUICtrlSendToDummy($ListMenu, $load_cover)
					Else
						$mode = 7
						Local $cov = StringSplit($douban2[$currentSel][1], '|', 2)
						If $isBig Then $cov[1] = StringReplace($cov[1], 'spic', 'lpic')
						$send = $cov[0] & '|' & $cov[1] & '|2||||'
						If _CoProcSend($load_Pro, $send) Then
							_ShowLoading()
							$cover_put = @TempDir & '\cover.' & StringRegExpReplace($cov[1], '.*\.', '')
						Else
							_ToolTip('错误', "Worker not Responding (" & @error & ")", 3, 3)
						EndIf
					EndIf
				EndIf
			Else
				_ToolTip('错误', '请先选择一项', 3)
			EndIf
			GUICtrlSetState($sub_OK, $GUI_ENABLE)
		Case $l_btn_header
			$lrc_text = FileRead($root_folder & '\' & $bLVItems[$iSelected][7] & _
					StringRegExpReplace($bLVItems[$iSelected][0], '\.(\w+)$', '') & '.lrc')
			If @error Then Return
			$lrc_Format = _lrc_Prase($lrc_text)
			If UBound($lrc_Format, 0) = 2 Then
				Update_L()
			EndIf
		Case $save_cover
			Local $cover_name = StringRegExp($cover_put, '^.*\\(.*?)\.(\w+)$', 3, 1)
			If @error Or $cover_put = @ScriptDir & "\ICON\music-default.jpg" Then Return
			Local $Save_cover_Dir = FileSaveDialog('保存图片', $root_folder, _
					'图像文件(*.' & $cover_name[1] & ')|所有文件(*.*)', 16, $cover_name[0] & '.' & $cover_name[1], $hGUI)
			If Not @error Then
				FileCopy($cover_put, $Save_cover_Dir, 9)
				If Not @error Then _ToolTip('', '保存成功', 5, 1)
			EndIf
		Case $download_cover
			GUICtrlSendToDummy($ListMenu, $load_cover)
		Case $Search_Button
			Local $arPos, $x, $y
			Local $hMenu = GUICtrlGetHandle($context_button)
			$arPos = ControlGetPos($hGUI, "", $Search_Button)
			$x = $arPos[0]
			$y = $arPos[1] + $arPos[3]
			ClientToScreen($hGUI, $x, $y)
			DllCall("user32.dll", "int", "TrackPopupMenuEx", "hwnd", $hMenu, "int", 0, "int", $x, "int", $y, "hwnd", $hGUI, "ptr", 0)
		Case $sogou_srh, $baidu_srh
			Local $s_url
			If Not GUICtrlRead($title) Then Return
			Switch @GUI_CtrlId
				Case $sogou_srh
					$s_url = 'http://mp3.sogou.com/music.so?query='
				Case $baidu_srh
					$s_url = 'http://mp3.baidu.com/m?word='
			EndSwitch
			If GUICtrlRead($artist) Then
				Return ShellExecute($s_url & _UrlToHex(GUICtrlRead($title), 1, 'ansi') & '+' & _
						_UrlToHex(GUICtrlRead($artist), 1, 'ansi'))
			Else
				Return ShellExecute($s_url & _UrlToHex(GUICtrlRead($title), 1, 'ansi'))
			EndIf
		Case $google_srh
			If Not GUICtrlRead($title) Then Return
			Return ShellExecute('http://www.google.cn/music/search?q=' & _UrlToHex(GUICtrlRead($title), 1, 'unicode'))
		Case $head_OK
			DllStructSetData($l_head, "title", GUICtrlRead($h[0]))
			DllStructSetData($l_head, "artist", GUICtrlRead($h[1]))
			DllStructSetData($l_head, "album", GUICtrlRead($h[2]))
			DllStructSetData($l_head, "editor", GUICtrlRead($h[3]))
			GUIDelete($lGUI)
		Case $bar
			Local $tmp_input = GUICtrlRead($artist)
			GUICtrlSetData($artist, GUICtrlRead($title))
			GUICtrlSetData($title, $tmp_input)
			$reg_order = BitXOR(1, $reg_order)
	EndSwitch
EndFunc   ;==>gui

Func guicolor($id = 1)
	If IsDeclared("id") Then
		$id = Eval("col_" & $id)
	Else
		Local $id = @GUI_CtrlId
	EndIf
	Switch $id
		Case $col_1
			GUISetBkColor($col_def, $hGUI)
			GUICtrlSetBkColor($slider, $col_def)
			menuCheck(1)
		Case $col_6
			GUISetBkColor(0x000000, $hGUI)
			GUICtrlSetBkColor($slider, 0x000000)
			GUICtrlSetColor($current_time, 0xffffff)
			Return menuCheck(6)
		Case $col_4
			GUISetBkColor(0x33CCCC, $hGUI)
			GUICtrlSetBkColor($slider, 0x33CCCC)
			menuCheck(4)
		Case $col_2
			GUISetBkColor(0xf9906f, $hGUI)
			GUICtrlSetBkColor($slider, 0xf9906f)
			menuCheck(2)
		Case $col_5
			GUISetBkColor(0xffffff, $hGUI)
			GUICtrlSetBkColor($slider, 0xffffff)
			menuCheck(5)
		Case $col_3
			GUISetBkColor(0xfaff72, $hGUI)
			GUICtrlSetBkColor($slider, 0xfaff72)
			menuCheck(3)
	EndSwitch
	GUICtrlSetColor($current_time, 0x000000)
EndFunc   ;==>guicolor

Func tray()
	Switch @TRAY_ID
		Case $tray_play
			_Play()
		Case $tray_stop
			_StopPlay()
	EndSwitch
EndFunc   ;==>tray

Func Reciver($vParameter)
	Switch BinaryMid($vParameter, 1, 1)
		Case 0x21
			If BinaryMid($vParameter, 2) = 0x30 Then
				If _GUICtrlToolbar_GetButtonState($hToolbar, $idDat) Then
					_GUICtrlToolbar_EnableButton($hToolbar, $idDat, False)
					GUICtrlSetState($hGIF, $GUI_DISABLE)
					_GUICtrlStatusBar_SetIcon($StatusBar, 0, $hIcons[1])
					_GUICtrlStatusBar_SetTipText($StatusBar, 0, "网络不畅")
					AdlibRegister('_chk_net', 3000)
				EndIf
			Else
				AdlibUnRegister('_chk_net')
				_GUICtrlToolbar_EnableButton($hToolbar, $idDat, True)
				GUICtrlSetState($hGIF, $GUI_ENABLE)
				_GUICtrlStatusBar_SetIcon($StatusBar, 0, $hIcons[0])
				_GUICtrlStatusBar_SetTipText($StatusBar, 0, "网络通畅")
			EndIf
		Case 0x22
			_GUICtrlStatusBar_SetText($StatusBar, BinaryToString(BinaryMid($vParameter, 2)), 2)
		Case 0x23
			$vParameter = BinaryMid($vParameter, 2)
			Local $Ping = StringSplit(BinaryToString($vParameter), '|', 2)
			_Chek_net($NetState[0], Number($Ping[0]))
			_Chek_net($NetState[1], _Iif(($Ping[1] = -1) Or ($Ping[2] = -1), 0, (Number($Ping[1]) + Number($Ping[2])) / 2))
			_Chek_net($NetState[2], _Iif(($Ping[3] = -1) Or ($Ping[4] = -1), 0, (Number($Ping[3]) + Number($Ping[4])) / 2))
			_Chek_net($NetState[3], Number($Ping[5]))
			_Chek_net($NetState[4], Number($Ping[6]))
			_Chek_net($NetState[5], Number($Ping[7]))
			_ExitLoading()
		Case 0x24
			_ToolTip("抱歉", "可能由于网络问题，导致无法获取数据", 3, 1)
			Return _ExitLoading()
		Case 0x25
			BinaryToString(BinaryMid($vParameter, 2)) ;联网进程
		Case Else
			Switch $load_flag
				Case 0
					If $mode = 3 Then
						$lrc_text = _LrcDownLoad_kuwo($vParameter)
					ElseIf $mode = 2 Then
						If BinaryMid($vParameter, 1, 2) = '0xFFFE' Then
							$lrc_text = BinaryToString(BinaryMid($vParameter, 3), 2)
						ElseIf BinaryMid($vParameter, 1, 2) = '0xFEFF' Then
							$lrc_text = BinaryToString(BinaryMid($vParameter, 3), 3)
						ElseIf BinaryMid($vParameter, 1, 3) = '0xEFBBBF' Then
							$lrc_text = BinaryToString(BinaryMid($vParameter, 4), 4)
						Else
							$lrc_text = BinaryToString($vParameter, 1)
						EndIf
					ElseIf $mode = 9 Then
						Local $lrc_qq_temp = StringRegExp(BinaryToString($vParameter), '(?s)\[CDATA\[(.*?)\]\]', 3, 1)
						If @error Then Return
						$lrc_text = $lrc_qq_temp[0]
					Else
						$lrc_text = BinaryToString($vParameter)
					EndIf
					$lrc_Format = _lrc_Prase($lrc_text)
					If IsArray($lrc_Format) Then
						Update_L()
					Else
						_GUICtrlListView_BeginUpdate($Lrc_List)
						_GUICtrlListView_DeleteAllItems($Lrc_List)
						Dim $lrc_Show = ''
						_txt_Prase($lrc_text, $lrc_Format)
						If @error Then
							For $i = 0 To 5
								GUICtrlCreateListViewItem($L[$i], $Lrc_List)
							Next
							Dim $lrc_Format = ''
						Else
							For $i = 0 To UBound($lrc_Format) - 1
								GUICtrlCreateListViewItem($lrc_Format[$i], $Lrc_List)
							Next
							_GUICtrlListView_SetColumnWidth($Lrc_List, 0, $LVSCW_AUTOSIZE_USEHEADER)
						EndIf
						_GUICtrlListView_EndUpdate($Lrc_List)
					EndIf
					If _BASS_ChannelIsActive($MusicHandle) = 0 Then $current_song = ''
				Case 1
					Local $re
					If $mode <> 7 And $mode <> 2 Then $vParameter = BinaryToString($vParameter)
					Switch $mode
						Case 1
							$re = _LrcList_qianqian(0, 0, 0, $vParameter)
							If IsArray($re) Then
								_GUICtrlListView_AddArray($sub_list, $re)
								_GUICtrlListView_SetColumn($sub_list, 0, "ID", 0, 0)
								_GUICtrlListView_SetColumn($sub_list, 1, "歌手", 132, 2)
								_GUICtrlListView_SetColumn($sub_list, 2, "歌曲", 180, 2)
								_GUICtrlListView_HideColumn($sub_list, 3)
								_GUICtrlListView_HideColumn($sub_list, 4)
								_GUICtrlListView_HideColumn($sub_list, 5)
								GUISetState(@SW_SHOW, $Lrc_Choose)
							EndIf
							WinSetTitle($Lrc_Choose, '', '选择歌词 - 千千静听')
						Case 2
							$re = _LrcList_mini(0, 0, $vParameter)
							If IsArray($re) Then
								_GUICtrlListView_AddArray($sub_list, $re)
								_GUICtrlListView_SetColumn($sub_list, 0, "URL", 0, 0)
								_GUICtrlListView_SetColumn($sub_list, 1, "歌手", 70, 2)
								_GUICtrlListView_SetColumn($sub_list, 2, "歌曲", 91, 2)
								_GUICtrlListView_SetColumn($sub_list, 3, "专辑", 80, 2)
								_GUICtrlListView_SetColumn($sub_list, 4, "得分", 35, 2)
								_GUICtrlListView_SetColumn($sub_list, 5, "票数", 35, 2)
								GUISetState(@SW_SHOW, $Lrc_Choose)
							EndIf
							WinSetTitle($Lrc_Choose, '', '选择歌词 - MiniLyrics')
						Case 3
							$re = _LrcList_kuwo(0, 0, $vParameter)
							If IsArray($re) Then
								_GUICtrlListView_AddArray($sub_list, $re)
								_GUICtrlListView_SetColumn($sub_list, 0, "PATH", 0, 0)
								_GUICtrlListView_SetColumn($sub_list, 1, "歌手", 135, 2)
								_GUICtrlListView_SetColumn($sub_list, 2, "歌曲", 176, 2)
								_GUICtrlListView_HideColumn($sub_list, 3)
								_GUICtrlListView_HideColumn($sub_list, 4)
								_GUICtrlListView_HideColumn($sub_list, 5)
								GUISetState(@SW_SHOW, $Lrc_Choose)
							EndIf
							WinSetTitle($Lrc_Choose, '', '选择歌词 -  酷我音乐')
						Case 4
							$re = _LrcList_ilrc(0, 1, $vParameter)
							If IsArray($re) Then
								_GUICtrlListView_AddArray($sub_list, $re)
								_GUICtrlListView_SetColumn($sub_list, 0, "URL", 0, 0)
								_GUICtrlListView_SetColumn($sub_list, 1, "歌手", 80, 2)
								_GUICtrlListView_SetColumn($sub_list, 2, "歌曲", 136, 2)
								_GUICtrlListView_SetColumn($sub_list, 3, "专辑", 95, 2)
								_GUICtrlListView_HideColumn($sub_list, 4)
								_GUICtrlListView_HideColumn($sub_list, 5)
								GUISetState(@SW_SHOW, $Lrc_Choose)
							EndIf
							WinSetTitle($Lrc_Choose, '', '选择歌词 -  5ilrc')
						Case 5
							Return _LrcDownLoad_baidu(0, 0, $vParameter)
						Case 6
							$re = _get_cover($vParameter)
							If @error Then
								GUICtrlSetImage($cover, @ScriptDir & "\icon\music-default.jpg")
								_ToolTip('很遗憾', "没有找到相关专辑", 3)
								$coverStartIndex = 0
								Return _ExitLoading()
							EndIf
						Case 7
							$cover_Dir = $cover_put
							$f_jpg = FileOpen($cover_Dir, 26)
							FileWrite($f_jpg, $vParameter)
							FileClose($f_jpg)
							_loadpic()
							$mode = 6
						Case 8
							$Ping = StringSplit($vParameter, '|', 2)
							_Chek_net($NetState[0], Number($Ping[0]))
							_Chek_net($NetState[1], _Iif(($Ping[1] = -1) Or ($Ping[2] = -1), 0, (Number($Ping[1]) + Number($Ping[2])) / 2))
							_Chek_net($NetState[2], _Iif(($Ping[3] = -1) Or ($Ping[4] = -1), 0, (Number($Ping[3]) + Number($Ping[4])) / 2))
							_Chek_net($NetState[3], Number($Ping[5]))
							_Chek_net($NetState[4], Number($Ping[6]))
							_Chek_net($NetState[5], Number($Ping[7]))
						Case 9
							$re = _LrcList_qq(0, 0, $vParameter)
							If IsArray($re) Then
								_GUICtrlListView_AddArray($sub_list, $re)
								_GUICtrlListView_SetColumn($sub_list, 0, "ID", 0, 0)
								_GUICtrlListView_SetColumn($sub_list, 1, "歌手", 145, 2)
								_GUICtrlListView_SetColumn($sub_list, 2, "歌曲", 180, 2)
								_GUICtrlListView_HideColumn($sub_list, 3)
								_GUICtrlListView_HideColumn($sub_list, 4)
								_GUICtrlListView_HideColumn($sub_list, 5)
								GUISetState(@SW_SHOW, $Lrc_Choose)
							EndIf
							WinSetTitle($Lrc_Choose, '', '选择歌词 - QQ音乐')
					EndSwitch
					If IsArray($re) Then _GUICtrlListView_SetItemSelected($sub_list, 0)
			EndSwitch
			_ExitLoading()
	EndSwitch
EndFunc   ;==>Reciver

Func set()
	Switch @GUI_CtrlId
		Case $Fonts[0]
			Local $font_a = __ChooseFont($font_name, $font_size, '', $font_xing, BitAND($font_var, 2), BitAND($font_var, 4), BitAND($font_var, 8), $Setting)
			If @error Then Return
			$font_var = $font_a[1]
			$font_name = $font_a[2]
			$font_size = $font_a[3]
			$font_xing = $font_a[4]
			If $font_xing >= 700 Then $font_var += 1
			ChangeStyle($font_name, $font_size, $font_var, $font_color, $d_trans)
		Case $Fonts[1]
			Local $Ch = _ChooseColor(2, $font_color, 1)
			If $Ch = -1 Then Return
			GUICtrlSetBkColor($Fonts[1], $Ch)
			$font_color = $Ch
			ChangeStyle($font_name, $font_size, $font_var, $font_color, $d_trans)
		Case $Fonts[2]
			Local $Ch = _ChooseColor(2, $lrc_text_front_color, 1)
			If $Ch = -1 Then Return
			$lrc_text_front_color = $Ch
			GUICtrlSetBkColor($Fonts[2], $Ch)
		Case $Fonts[3]
			Local $Ch = _ChooseColor(2, $lrc_text_back_color, 1)
			If $Ch = -1 Then Return
			$lrc_text_back_color = $Ch
			GUICtrlSetBkColor($Fonts[3], $Ch)
;~ 			Local $tItem = DllStructCreate($tagLVITEM)
;~ 			DllStructSetData($tItem, "Mask", $LVIF_PARAM)
;~ 	        DllStructSetData($tItem, "Item", 3)
;~ 			Local $pItem = DllStructGetPtr($tItem)
;~ 			GUICtrlSendMsg($Lrc_List, $LVM_GETITEMW, 0, $pItem)
;~ 			GUICtrlSetColor(DllStructGetData($tItem, "Param"), 0xff0000)
			If UBound($lrc_Format, 0) <> 2 Then
				GUICtrlSetColor($Lrc_List, $Ch)
;~ 				_GUICtrlListView_RedrawItems($Lrc_List, 0, _GUICtrlListView_GetItemCount($Lrc_List) - 1)
			Else
				Update_L($Ch)
			EndIf

		Case $Fonts[4]
			Local $Ch = _ChooseColor(2, 0xEEEEEE, 1)
			If $Ch = -1 Then Return
			$list_bk_color = $Ch
			GUICtrlSetBkColor($Fonts[4], $Ch)
			GUICtrlSetBkColor($Lrc_List, $Ch)
		Case $Fonts[5]
			Local $font_b = __ChooseFont($list_name, $list_size, '', $list_xing, BitAND($list_var, 2), BitAND($list_var, 4), BitAND($list_var, 8), $Setting)
			If @error Then Return
			GUICtrlSetFont($Lrc_List, $font_b[3], $font_b[4], $font_b[1], $font_b[2])
			$list_var = $font_b[1]
			$list_name = $font_b[2]
			$list_size = $font_b[3]
			$list_xing = $font_b[4]
		Case $Button1
			Local $ini_dir = @ScriptDir & '\config.ini'
			IniWrite($ini_dir, "lyrics", "font_name", $font_name)
			IniWrite($ini_dir, "lyrics", "font_var", $font_var)
			IniWrite($ini_dir, "lyrics", "font_size", $font_size)
			IniWrite($ini_dir, "lyrics", "font_xing", $font_xing)
			IniWrite($ini_dir, "lyrics", "font_color", $font_color)
			IniWrite($ini_dir, "lyrics", "list_name", $list_name)
			IniWrite($ini_dir, "lyrics", "list_var", $list_var)
			IniWrite($ini_dir, "lyrics", "list_size", $list_size)
			IniWrite($ini_dir, "lyrics", "list_xing", $list_xing)
			IniWrite($ini_dir, "lyrics", "list_bk_color", $list_bk_color)
			IniWrite($ini_dir, "lyrics", "lrc_text_back_color", $lrc_text_back_color)
			IniWrite($ini_dir, "lyrics", "lrc_text_front_color", $lrc_text_front_color)
			IniWrite($ini_dir, "lyrics", "transparency", $d_trans)
			IniWrite($ini_dir, "lyrics", "desk_top", $desk_top)
			IniWrite($ini_dir, "lyrics", "desk_fade", BitAND(GUICtrlRead($Fade_set), $GUI_CHECKED))
			IniWrite($ini_dir, "lyrics", "onlylist", $onlylist)
			IniWrite($ini_dir, "lyrics", "align", $list_align)
			IniWrite($ini_dir, "server", "cnc", $isCnc)
			IniWrite($ini_dir, "server", "cover_size", $isBig)
			IniWrite($ini_dir, "server", "proxy", _Iif(BitAND(GUICtrlRead($ProxyCheck), $GUI_CHECKED), GUICtrlRead($ProxyIP) & ':' & GUICtrlRead($port_input), ""))
			IniWrite($ini_dir, "others", "save_only_txt", $save_only_txt)
			IniWrite($ini_dir, "others", "save_always_ask", $save_always_ask)
			IniWrite($ini_dir, "others", "copy_with_lrc", $copy_with_lrc)
			IniWrite($ini_dir, "others", "force_ti_format", $force_ti_format)
			IniWrite($ini_dir, "others", "only_file_without_lrc", $only_file_without_lrc)
			IniWrite($ini_dir, "others", "dir_depth", GUICtrlRead($SubSel_Deep))
			IniWrite($ini_dir, "others", "work_dir", $root_folder)
			IniWrite($ini_dir, "others", "color", $GUI_color)
		Case $Button2
			GUISetState(@SW_HIDE, @GUI_WinHandle)
		Case $Top_set
			Local $s = GUICtrlRead($Top_set)
			If $s <> 1 Then $s = 0
			WinSetOnTop($dGUI, "", $s)
			$desk_top = $s
		Case $Slider1
			$d_trans = 255 - GUICtrlRead($Slider1)
			ChangeStyle($font_name, $font_size, $font_var, $font_color, $d_trans)
		Case $Fade_set
			Local $s = GUICtrlRead($Fade_set)
			If $s = 1 Then
				$FadeOut = 25
			Else
				$FadeOut = $d_trans
			EndIf
		Case $layOut0
			Local $hListView_height = _WinAPI_GetWindowHeight(GUICtrlGetHandle($hListView))
			Local $cu_width = _WinAPI_GetWindowWidth(GUICtrlGetHandle($hListView))
			Local $lrc_height = _WinAPI_GetWindowHeight(GUICtrlGetHandle($Lrc_List))
			If $onlylist = 2 Then
				$hListView_height = $hListView_height - 33 - $lrc_height
				GUICtrlSetPos($hListView, 8, 92, $cu_width, $hListView_height)
				GUICtrlSetState($Lrc_List, $GUI_SHOW)
				GUICtrlSetState($l_btn_header, $GUI_SHOW)
			Else
				GUICtrlSetPos($hListView, 8, 92, $cu_width, $hListView_height)
			EndIf
			GUICtrlSetState($cover, $GUI_SHOW)
			GUICtrlSetState($cover_group, $GUI_SHOW)
			GUICtrlSetPos($l_btn_header, 8, $hListView_height + 107, $cu_width - 263, 25)
			GUICtrlSetPos($Lrc_List, 8, $hListView_height + 132, $cu_width - 263, $lrc_height)
			_GUICtrlListView_SetColumnWidth($Lrc_List, 0, $LVSCW_AUTOSIZE_USEHEADER)
			$onlylist = 0
		Case $layOut1
			Local $hListView_height = _WinAPI_GetWindowHeight(GUICtrlGetHandle($hListView))
			Local $cu_width = _WinAPI_GetWindowWidth(GUICtrlGetHandle($hListView))
			Local $lrc_height = _WinAPI_GetWindowHeight(GUICtrlGetHandle($Lrc_List))
			If $onlylist = 2 Then
				$hListView_height -= (33 + $lrc_height)
				GUICtrlSetPos($hListView, 8, 92, $cu_width, $hListView_height)
				GUICtrlSetState($Lrc_List, $GUI_SHOW)
				GUICtrlSetState($l_btn_header, $GUI_SHOW)
			Else
				GUICtrlSetPos($hListView, 8, 92, $cu_width, $hListView_height)
			EndIf
			GUICtrlSetState($cover, $GUI_HIDE)
			GUICtrlSetState($cover_group, $GUI_HIDE)
			GUICtrlSetPos($l_btn_header, 8, $hListView_height + 107, $cu_width, 25)
			GUICtrlSetPos($Lrc_List, 8, $hListView_height + 132, $cu_width, $lrc_height)
			_GUICtrlListView_SetColumnWidth($Lrc_List, 0, $LVSCW_AUTOSIZE_USEHEADER)
			$onlylist = 1
		Case $layOut2
			If $onlylist = 2 Then Return
			Local $hListView_height = _WinAPI_GetWindowHeight(GUICtrlGetHandle($hListView))
			Local $cu_width = _WinAPI_GetWindowWidth(GUICtrlGetHandle($hListView))
			Local $lrc_height = _WinAPI_GetWindowHeight(GUICtrlGetHandle($Lrc_List))
			GUICtrlSetState($l_btn_header, $GUI_HIDE)
			GUICtrlSetState($Lrc_List, $GUI_HIDE)
			If Not $onlylist Then
				GUICtrlSetState($cover, $GUI_HIDE)
				GUICtrlSetState($cover_group, $GUI_HIDE)
			EndIf
			GUICtrlSetPos($hListView, 8, 92, $cu_width, $hListView_height + $lrc_height + 33)
			$onlylist = 2
		Case $align_check
			If GUICtrlRead($align_check) = 1 Then
				_GUICtrlListView_JustifyColumn($Lrc_List, 0, 2)
				$list_align = 2
			Else
				_GUICtrlListView_JustifyColumn($Lrc_List, 0, 0)
				$list_align = 0
			EndIf
			_GUICtrlListView_RedrawItems($Lrc_List, 0, _GUICtrlListView_GetItemCount($Lrc_List) - 1)
		Case $big, $small
			$isBig = BitAND(GUICtrlRead($big), $GUI_CHECKED)
		Case $cnc, $ct
			$isCnc = BitAND(GUICtrlRead($cnc), $GUI_CHECKED)
		Case $ProxyCheck
			Local $ip
			If BitAND(GUICtrlRead($ProxyCheck), $GUI_CHECKED) = $GUI_CHECKED Then
				$ip = GUICtrlRead($ProxyIP) & ':' & GUICtrlRead($port_input)
				StringRegExp($ip, '^(\d{1,2}|1\d\d|2[0-4]\d|25[0-5])\.(\d{1,2}|1\d\d|2[0-4]\d|25[0-5])\.(\d{1,2}|1\d\d|2[0-4]\d|25[0-5])\.(\d{1,2}|1\d\d|2[0-4]\d|25[0-5])\:\d+$', 3, 1)
				If Not @error Then
					GUICtrlSetState($ProxyIP, $GUI_DISABLE)
					GUICtrlSetState($port_input, $GUI_DISABLE)
					If _CoProcSend($load_Pro, 'proxy|' & $ip) Then

					Else
						_ToolTip('错误', "Worker not Responding (" & @error & ")", 3, 3)
					EndIf
				Else
					GUICtrlSetState($ProxyCheck, $GUI_UNCHECKED)
					MsgBox(48, '提示', '格式或其他错误！', 2)
				EndIf
			Else
				GUICtrlSetState($ProxyIP, $GUI_ENABLE)
				GUICtrlSetState($port_input, $GUI_ENABLE)
				If _CoProcSend($load_Pro, 'proxy|') Then

				Else
					_ToolTip('错误', "Worker not Responding (" & @error & ")", 3, 3)
				EndIf
			EndIf
		Case $Save_Checkbox
			If $save_only_txt Then
				$save_only_txt = 0
			Else
				$save_only_txt = 1
			EndIf
		Case $Save_Auto
			If $save_always_ask Then
				$save_always_ask = 0
			Else
				$save_always_ask = 1
			EndIf
		Case $Copy_Checkbox
			If $copy_with_lrc Then
				$copy_with_lrc = 0
			Else
				$copy_with_lrc = 1
			EndIf
		Case $Reg_Checkbox
			If $force_ti_format Then
				$force_ti_format = 0
			Else
				$force_ti_format = 1
			EndIf
		Case $Lrc_Checkbox
			If $only_file_without_lrc Then
				$only_file_without_lrc = 0
			Else
				$only_file_without_lrc = 1
			EndIf
		Case $shell_bt
			If IsObj($ShellContextMenu) Then
				_GUICtrlMenuEx_DeleteMenu($SubMenu, 9)
				$ShellContextMenu = ""
				_NETFramework_Load(@ScriptDir & "\ExplorerShellContextMenu.dll", False)
				GUICtrlSetData($shell_bt, "安装右键增强")
			Else
				_NETFramework_Load(@ScriptDir & "\ExplorerShellContextMenu.dll", True)
				_GUICtrlMenuEx_AddMenuItem($SubMenu, "more... ", $shell_item, $hIcons[14])
				$ShellContextMenu = ObjCreate("ExplorerShellContextMenu.ShowContextMenu")
				GUICtrlSetData($shell_bt, "卸载右键增强")
			EndIf
	EndSwitch
EndFunc   ;==>set

Func _Play()
	Local $lrc_exist
	If $iSelected = -1 Then Return _ToolTip('错误', '请选择一首歌曲', 3)
	If _BASS_ChannelIsActive($MusicHandle) = 0 Then
		$MusicHandle = _BASS_StreamCreateFile(False, $root_folder & '\' & $bLVItems[$iSelected][7] & $bLVItems[$iSelected][0], 0, 0, 0)
		If @error Then Return _ToolTip('错误', '未选中或其他错误' & @LF & '错误代码：' & @error, 3)
		$length = _BASS_ChannelGetLength($MusicHandle, $BASS_POS_BYTE)
		_BASS_ChannelPlay($MusicHandle, 1)
		If (Not UBound($lrc_Format, 0) = 2) Or ($current_song And $current_song <> $bLVItems[$iSelected][0]) Then
			$current_song = $bLVItems[$iSelected][0]
			$lrc_exist = FileOpen($root_folder & '\' & $bLVItems[$iSelected][7] & StringRegExpReplace($bLVItems[$iSelected][0], '\.(\w+)$', '') & '.lrc')
			If $lrc_exist = -1 Then
				_ToolTip('提示', '未找到歌词文件，请先搜索', 3, 1)
				$move_timer = _Timer_SetTimer($hGUI, 50, 'move_list', $move_timer)
				_GUICtrlListView_BeginUpdate($Lrc_List)
				_GUICtrlListView_DeleteAllItems($Lrc_List)
				For $i = 0 To 5
					GUICtrlCreateListViewItem($L[$i], $Lrc_List)
				Next
				_GUICtrlListView_SetColumnWidth($Lrc_List, 0, $LVSCW_AUTOSIZE_USEHEADER)
				_GUICtrlListView_EndUpdate($Lrc_List)
				Dim $lrc_Show = ''
				Dim $lrc_Format = ''
			Else
				$lrc_text = FileRead($lrc_exist)
				FileClose($lrc_text)
				$lrc_Format = _lrc_Prase($lrc_text)
				If UBound($lrc_Format, 0) = 2 Then
					Update_L()
					$n = 0
				Else
					$move_timer = _Timer_SetTimer($hGUI, 50, 'move_list', $move_timer)
					_ToolTip('错误', '无法解析歌词文件！', 3, 3)
				EndIf
			EndIf
		ElseIf UBound($lrc_Format, 0) = 2 Then ; may unnecessary
			Dim $lrc_Show = $lrc_Format
			ReDim $lrc_Show[UBound($lrc_Format, 1) + 1][3]
			$lrc_Show[UBound($lrc_Format, 1)][0] = Round(_BASS_ChannelBytes2Seconds($MusicHandle, $length) * 1000, 0)
			$lrc_Show[UBound($lrc_Format, 1) - 1][2] = $lrc_Show[UBound($lrc_Format, 1)][0] - $lrc_Show[UBound($lrc_Format, 1) - 1][0]
			$move_timer = _Timer_SetTimer($hGUI, 50, 'move_list', $move_timer)
		EndIf
		If $bLVItems[$iSelected][1] And $bLVItems[$iSelected][2] Then
			Local $SongString = $bLVItems[$iSelected][1] & ' - ' & $bLVItems[$iSelected][2]
			WinSetTitle($hGUI, '', $SongString)
		Else
			Local $SongString = StringRegExpReplace($bLVItems[$iSelected][0], '\.(\w+)$', '')
			WinSetTitle($hGUI, '', '正在播放 ' & $SongString)
		EndIf
		$vol = _BASS_ChannelGetAttribute($MusicHandle, $BASS_ATTRIB_VOL)
		GUICtrlSetState($Sound_Stop, $GUI_ENABLE)
		GUICtrlSetData($Sound_Play, ';')
	ElseIf _BASS_ChannelIsActive($MusicHandle) = 1 Then
		_BASS_ChannelPause($MusicHandle)
		GUICtrlSetData($Sound_Play, '4')
	ElseIf _BASS_ChannelIsActive($MusicHandle) = 3 Then
		_BASS_ChannelPlay($MusicHandle, 0)
		GUICtrlSetData($Sound_Play, ';')
		GUICtrlSetState($Sound_Stop, $GUI_ENABLE)
		$move_timer = _Timer_SetTimer($hGUI, 50, 'move_list', $move_timer)
	EndIf
EndFunc   ;==>_Play

Func _StopPlay()
	_Stop()
	GUICtrlSetData($current_time, '00:00:00')
	WinSetTitle($hGUI, '', '音乐管理器 v2.0')
EndFunc   ;==>_StopPlay

Func _ToolBar()
	$hToolbar = _GUICtrlToolbar_Create($hGUI)
;~ 	跟$TBSTYLE_EX_DRAWDDARROWS冲突_GUICtrlToolbar_SetStyle($hToolbar, BitOR($BTNS_AUTOSIZE, $CCS_TOP))
;~ 	_GUICtrlToolbar_SetStyle($hToolbar, BitOR($BTNS_BUTTON, $BTNS_SHOWTEXT, $TBSTYLE_LIST))
	_GUICtrlToolbar_SetExtendedStyle($hToolbar, $TBSTYLE_EX_DRAWDDARROWS)
;~ 	工具栏提示，由于跟_GuiCtrlToolbar_SetUnicodeFormat冲突，暂时不考虑加入
	;$ToolTip = _GUIToolTip_Create($hToolBar)
	;_GUICtrlToolbar_SetToolTips($hToolBar,$ToolTip)

	$hToolBarImageList = _GUIImageList_Create(32, 32, 5, 3)

	$hToolBar_image[0] = _GUIImageList_AddIcon($hToolBarImageList, "icon.dll", 0, True)
	$hToolBar_image[1] = _GUIImageList_AddIcon($hToolBarImageList, "icon.dll", 1, True)
	$hToolBar_image[2] = _GUIImageList_AddIcon($hToolBarImageList, "icon.dll", 2, True)
	$hToolBar_image[3] = _GUIImageList_AddIcon($hToolBarImageList, "icon.dll", 3, True)
	$hToolBar_image[4] = _GUIImageList_AddIcon($hToolBarImageList, "icon.dll", 5, True)
	$hToolBar_image[5] = _GUIImageList_AddIcon($hToolBarImageList, "icon.dll", 4, True)
	$hToolBar_image[6] = _GUIImageList_AddIcon($hToolBarImageList, "icon.dll", 6, True)
	_GUICtrlToolbar_SetImageList($hToolbar, $hToolBarImageList)
	_GUICtrlToolbar_SetUnicodeFormat($hToolbar, True)

	$hToolBar_strings[0] = _GUICtrlToolbar_AddString($hToolbar, "添加")
	$hToolBar_strings[1] = _GUICtrlToolbar_AddString($hToolbar, "打开")
	$hToolBar_strings[2] = _GUICtrlToolbar_AddString($hToolbar, "关于")
	$hToolBar_strings[3] = _GUICtrlToolbar_AddString($hToolbar, "设置")
	$hToolBar_strings[4] = _GUICtrlToolbar_AddString($hToolbar, "导出")
	$hToolBar_strings[5] = _GUICtrlToolbar_AddString($hToolbar, "保存为lrc")
	$hToolBar_strings[6] = _GUICtrlToolbar_AddString($hToolbar, "千千静听")
	_GUICtrlToolbar_AddButton($hToolbar, $idAdd, $hToolBar_image[0], $hToolBar_strings[0])
	_GUICtrlToolbar_AddButton($hToolbar, $idOpen, $hToolBar_image[1], $hToolBar_strings[1])
	_GUICtrlToolbar_AddButton($hToolbar, $idAbt, $hToolBar_image[2], $hToolBar_strings[2])
;~ 	_GUICtrlToolbar_AddButtonSep($hToolbar)
	_GUICtrlToolbar_AddButton($hToolbar, $idSet, $hToolBar_image[3], $hToolBar_strings[3])
	_GUICtrlToolbar_AddButton($hToolbar, $idLst, $hToolBar_image[4], $hToolBar_strings[4])
	_GUICtrlToolbar_AddButton($hToolbar, $idSav, $hToolBar_image[5], $hToolBar_strings[5], $BTNS_DROPDOWN)
	_GUICtrlToolbar_AddButton($hToolbar, $idDat, $hToolBar_image[6], $hToolBar_strings[6], $BTNS_DROPDOWN)
EndFunc   ;==>_ToolBar

Func _Setting_Gui() ;----------设置---------------
	$Setting = GUICreate("设置", 375, 260, 466, 121, -1, -1, $hGUI)
	GUISetOnEvent($GUI_EVENT_CLOSE, "gui")
	$Button1 = GUICtrlCreateButton("保存配置", 220, 232, 77, 25)
	_GUICtrlButton_SetImageList(-1, _GetImageListHandle("icon.dll", 13), 0)
	GUICtrlSetOnEvent(-1, "set")
	$Button2 = GUICtrlCreateButton("关闭", 301, 232, 57, 25)
	GUICtrlSetOnEvent(-1, "set")
	$Setting_tab = GUICtrlCreateTab(5, 6, 365, 225)
	;;;;;;;;;;;;;;;;;;;;
	$tab_dlrc = GUICtrlCreateTabItem("界面外观")
	$Fonts[0] = GUICtrlCreateLabel("桌面歌词字体", 25, 40, 120, 24)
	GUICtrlSetFont(-1, 15, 400, 4)
	GUICtrlSetColor(-1, 0x0000BC)
	GUICtrlSetCursor(-1, 0)
	$Fonts[5] = GUICtrlCreateLabel("滚动歌词字体", 25, 86, 120, 24)
	GUICtrlSetFont(-1, 15, 400, 4)
	GUICtrlSetColor(-1, 0x0000BC)
	GUICtrlSetCursor(-1, 0)
	$Group4 = GUICtrlCreateGroup("布局", 20, 132, 155, 96)
	$layOut0 = GUICtrlCreateRadio("显示全部", 30, 150, 65, 20)
	GUICtrlSetOnEvent(-1, "set")
	$layOut1 = GUICtrlCreateRadio("隐藏封面", 100, 150, 65, 20)
	GUICtrlSetOnEvent(-1, "set")
	$layOut2 = GUICtrlCreateRadio("隐藏歌词和封面", 30, 174, 120, 20)
	GUICtrlSetOnEvent(-1, "set")
	GUICtrlSetState(Eval("layOut" & $onlylist), $GUI_CHECKED)
	GUICtrlCreateGroup("", -99, -99, 1, 1)
	$align_check = GUICtrlCreateCheckbox("歌词居中显示", 30, 203, 100, 15)
	If $list_align Then GUICtrlSetState(-1, 1)
	GUICtrlSetOnEvent(-1, "set")
	;$hide_bottom = GUICtrlCreateCheckbox("隐藏滚动歌词和封面", 40, 203, 150, 15)
	$Group3 = GUICtrlCreateGroup("显示设置", 192, 153, 161, 75)
	$Top_set = GUICtrlCreateCheckbox("置顶", 200, 203, 48, 15)
	GUICtrlSetOnEvent(-1, "set")
	If $desk_top Then GUICtrlSetState(-1, 1)
	$Fade_set = GUICtrlCreateCheckbox("淡入淡出", 260, 203, 70, 15)
	GUICtrlSetOnEvent(-1, "set")
	If Number(IniRead(@ScriptDir & '\config.ini', "lyrics", "desk_fade", "1")) Then GUICtrlSetState(-1, 1)
	$Slider1 = GUICtrlCreateSlider(243, 172, 97, 25, $TBS_NOTICKS)
	GUICtrlSetLimit(-1, 255, 0)
	GUICtrlSetData(-1, 255 - $d_trans)
	GUICtrlSetOnEvent(-1, "set")
	GUICtrlCreateLabel('透明度', 203, 175, 50, 15)
	GUICtrlCreateGroup("", -99, -99, 1, 1)
	$Group2 = GUICtrlCreateGroup("色彩方案", 192, 32, 161, 114)
	GUICtrlCreateLabel('桌面歌词' & @CRLF & @CRLF & '前景色' & @CRLF & @CRLF & '后景色' & @CRLF & @CRLF & '背景色', 201, 49, 55, 90)
	$Fonts[1] = GUICtrlCreateLabel('', 260, 48, 68, 15, $SS_SUNKEN)
	GUICtrlSetBkColor($Fonts[1], $font_color)
	GUICtrlSetCursor(-1, 0)
	$Fonts[2] = GUICtrlCreateLabel('', 260, 72, 68, 15, $SS_SUNKEN)
	GUICtrlSetBkColor($Fonts[2], $lrc_text_front_color)
	GUICtrlSetCursor(-1, 0)
	$Fonts[3] = GUICtrlCreateLabel('', 260, 98, 68, 15, $SS_SUNKEN)
	GUICtrlSetBkColor($Fonts[3], $lrc_text_back_color)
	GUICtrlSetCursor(-1, 0)
	$Fonts[4] = GUICtrlCreateLabel('', 260, 120, 68, 15, $SS_SUNKEN)
	GUICtrlSetBkColor($Fonts[4], $list_bk_color)
	GUICtrlSetCursor(-1, 0)
	GUICtrlCreateGroup("", -99, -99, 1, 1)
	For $i = 0 To 5
		GUICtrlSetOnEvent($Fonts[$i], "set")
	Next

	;;;;;;;;;;;;;;;;;;;;;;;;
	$tab_Server = GUICtrlCreateTabItem("服务器")
	GUICtrlCreateGroup("千千静听服务器", 18, 32, 182, 40)
	GUIStartGroup()
	$ct = GUICtrlCreateRadio("电信", 30, 47, 50, 20)
	GUICtrlSetOnEvent(-1, "set")
	$cnc = GUICtrlCreateRadio("网通", 120, 47, 50, 20)
	GUICtrlSetOnEvent(-1, "set")
	If $isCnc Then
		GUICtrlSetState($cnc, $GUI_CHECKED)
	Else
		GUICtrlSetState($ct, $GUI_CHECKED)
	EndIf
	GUICtrlCreateGroup("", -99, -99, 1, 1)
	GUICtrlCreateGroup('封面文件大小', 210, 32, 139, 40)
	GUIStartGroup()
	$big = GUICtrlCreateRadio("大", 216, 47, 30, 20)
	GUICtrlSetOnEvent(-1, "set")
	$small = GUICtrlCreateRadio("小", 300, 47, 30, 20)
	GUICtrlSetOnEvent(-1, "set")
	If $isBig Then
		GUICtrlSetState($big, $GUI_CHECKED)
	Else
		GUICtrlSetState($small, $GUI_CHECKED)
	EndIf
	GUICtrlCreateGroup("", -99, -99, 1, 1)
	GUICtrlCreateGroup("代理服务器", 18, 80, 331, 80)
	GUICtrlCreateLabel("端口:", 208, 102, 31, 17)
	GUICtrlCreateLabel("IP:", 30, 102, 17, 17)
	$ProxyIP = GUICtrlCreateInput("", 56, 100, 105, 17, 0x50030081)
	$port_input = GUICtrlCreateInput("", 248, 100, 49, 18)
	$ProxyCheck = GUICtrlCreateCheckbox(" 使用代理服务器", 30, 132, 105, 18)
	Local $proxy = IniRead(@ScriptDir & '\config.ini', "server", "proxy", "0")
	StringRegExp($proxy, '^(\d{1,2}|1\d\d|2[0-4]\d|25[0-5])\.(\d{1,2}|1\d\d|2[0-4]\d|25[0-5])\.(\d{1,2}|1\d\d|2[0-4]\d|25[0-5])\.(\d{1,2}|1\d\d|2[0-4]\d|25[0-5])\:\d+$', 3, 1)
	If Not @error Then
		GUICtrlSetData($ProxyIP, StringRegExpReplace($proxy, '\:\d+$', ''))
		GUICtrlSetData($port_input, StringRegExpReplace($proxy, '.*\:(\d+)$', '\1'))
		GUICtrlSetState($ProxyCheck, 1)
		GUICtrlSetState($ProxyIP, $GUI_DISABLE)
		GUICtrlSetState($port_input, $GUI_DISABLE)
	EndIf
	GUICtrlSetOnEvent($ProxyCheck, "set")
	GUICtrlCreateGroup("", -99, -99, 1, 1)
	GUICtrlCreateGroup("服务器状态", 18, 165, 331, 40)
	For $i = 0 To 5
		$NetState[$i] = GUICtrlCreateLabel('a', 30 + 28 * $i, 180, 23, 23)
		GUICtrlSetFont(-1, 14, 800, 0, "Webdings")
	Next
	$hGIF = GUICtrlCreateLabel("PING", 208, 185, 32, 17)
	GUICtrlSetFont(-1, 8, 400, 4)
	GUICtrlSetColor(-1, 0x0000BC)
	GUICtrlSetCursor(-1, 0)
	GUICtrlSetTip($hGIF, '点击测试服务器')
	GUICtrlSetOnEvent(-1, "_StatusBar_Click")
	GUICtrlCreateGroup("", -99, -99, 1, 1)
	;;;;;;;;;;;;;;;;;;;;;;;
	$tab_Save = GUICtrlCreateTabItem("其他设置")
	$Save_Checkbox = GUICtrlCreateCheckbox("只保存歌词文本", 24, 42, 120, 17)
	GUICtrlSetOnEvent(-1, "set")
	If $save_only_txt Then GUICtrlSetState(-1, 1)
	$Save_Auto = GUICtrlCreateCheckbox("总是询问保存路径", 24, 65, 120, 17)
	GUICtrlSetOnEvent(-1, "set")
	If $save_always_ask Then GUICtrlSetState(-1, 1)
	$Copy_Checkbox = GUICtrlCreateCheckbox('右键复制时包含同名lrc文件(如果存在)', 24, 88, 240, 17)
	GUICtrlSetOnEvent(-1, "set")
	If $copy_with_lrc Then GUICtrlSetState(-1, 1)
	$Reg_Checkbox = GUICtrlCreateCheckbox('强制Title Formating(忽略TAG)', 24, 111, 240, 17)
	GUICtrlSetOnEvent(-1, "set")
	If $force_ti_format Then GUICtrlSetState(-1, 1)
	$Lrc_Checkbox = GUICtrlCreateCheckbox('只载入无LRC的文件', 24, 134, 240, 17)
	GUICtrlSetOnEvent(-1, "set")
	If $only_file_without_lrc Then GUICtrlSetState(-1, 1)
	GUICtrlCreateLabel('层子文件夹,载入时', 57, 164, 130, 17)
	$SubSel_Deep = GUICtrlCreateInput($dir_depth, 24, 160, 30, 17)
	$SubSel_Deep_Up = GUICtrlCreateUpdown($SubSel_Deep)
	GUICtrlSetLimit($SubSel_Deep_Up, 9, 1)
	$shell_bt = GUICtrlCreateButton(_Iif(IsObj($ShellContextMenu), "卸载右键增强", "安装右键增强(需写入注册表)"), 24, 182, 185, 23)
	GUICtrlSetOnEvent(-1, "set")
	_GUICtrlButton_SetShield(GUICtrlGetHandle($shell_bt))
	GUICtrlCreateTabItem("")
	GUISetState(@SW_SHOW)
	GUISwitch($hGUI)
EndFunc   ;==>_Setting_Gui

Func _GetImageListHandle($sFile, $nIconID = 0, $fLarge = False)
	Local $iSize = 16
	If $fLarge Then $iSize = 32

	Local $hImage = _GUIImageList_Create($iSize, $iSize, 5, 3)
	If StringUpper(StringMid($sFile, StringLen($sFile) - 2)) = "BMP" Then
		_GUIImageList_AddBitmap($hImage, $sFile)
	Else
		_GUIImageList_AddIcon($hImage, $sFile, $nIconID, $fLarge)
	EndIf
	Return $hImage
EndFunc   ;==>_GetImageListHandle

Func _Search($flag)
	Dim $re
	If GUICtrlRead($title) Then
		_GUICtrlListView_DeleteAllItems(GUICtrlGetHandle($sub_list))
		$load_flag = 1
		_ShowLoading()
		Switch $flag
			Case 0
				$mode = 1
				_LrcList_qianqian(GUICtrlRead($artist), GUICtrlRead($title), $isCnc)
			Case 1
				$mode = 2
				_LrcList_mini(GUICtrlRead($artist), GUICtrlRead($title))
			Case 2
				$mode = 3
				_LrcList_kuwo(GUICtrlRead($artist), GUICtrlRead($title))
			Case 3
				$mode = 5
				_LrcDownLoad_baidu(GUICtrlRead($artist), GUICtrlRead($title))
			Case 4
				$mode = 4
				_LrcList_ilrc(GUICtrlRead($artist), GUICtrlRead($title))
			Case 5
				$mode = 9
				_LrcList_qq(GUICtrlRead($artist), GUICtrlRead($title))
		EndSwitch
		If @error Then _ExitLoading()
	Else
		_ToolTip('警告', '歌名不能为空', 3, 2)
	EndIf
EndFunc   ;==>_Search

Func _Save()
	If IsArray($lrc_Format) Then
		Local $temp_select = $iSelected
		If $iSelected < 0 Then
			$iSelected = 0
			$bLVItems[0][0] = GUICtrlRead($title)
		EndIf
		If $lyr_changed And $toolbar_subitem[1] = 0 Then
			$lrc_text = StringFormat('[ti:%s]' & @CRLF & '[ar:%s]' & @CRLF & '[al:%s]' & @CRLF & '[by:%s]' & @CRLF, _
					DllStructGetData($l_head, 1), DllStructGetData($l_head, 2), DllStructGetData($l_head, 3), DllStructGetData($l_head, 4))
			Switch UBound($lrc_Format, 0)
				Case 2
					Local $lrc_file_format[UBound($lrc_Format)][2]
					Local $i = 0, $j = 0, $temp
					For $i = 0 To UBound($lrc_Format) - 1
						$temp = $lrc_Format[$i][1]
						If Not IsDeclared($temp) Then
							Assign($temp, $j)
							$lrc_file_format[$j][1] = $temp
							$lrc_file_format[$j][0] = '[' & _TickToTime($lrc_Format[$i][0]) & ']'
							$j += 1
						Else
							$lrc_file_format[Eval($temp)][0] &= '[' & _TickToTime($lrc_Format[$i][0]) & ']'
						EndIf
					Next
					ReDim $lrc_file_format[$j][2]
					For $i = 0 To $j - 1
						$lrc_text &= $lrc_file_format[$i][0] & $lrc_file_format[$i][1] & @CRLF
					Next
				Case 1
					For $i = 0 To UBound($lrc_Format) - 1
						$lrc_text &= $lrc_Format[$i] & @CRLF
					Next
				Case Else
			EndSwitch
		EndIf
		If $save_only_txt Or UBound($lrc_Format, 0) = 1 Then
			$Save_txt_dir = FileSaveDialog('选择保存的文件夹', $root_folder & '\' & $bLVItems[$iSelected][7], _
					'文本文件(*.txt)|所有文件(*.*)', 16, GUICtrlRead($title) & '.txt', $hGUI)
			If Not @error Then
				FileWrite($Save_txt_dir, StringStripWS(StringRegExpReplace($lrc_text, '(?m)\[[^\]]+\]', ''), 3))
				_ToolTip('保存成功', '现在可以到工作目录查看', 5, 1)
			EndIf
		ElseIf $toolbar_subitem[1] = 1 Then
			$lrc_text = ''
			For $i = 1 To UBound($lrc_Format) - 1
				$lrc_text &= $i & @CRLF & '00:' & StringReplace(_TickToTime($lrc_Format[$i - 1][0]), '.', ',') & _
						'0 --> 00:' & StringReplace(_TickToTime($lrc_Format[$i][0] - 1), '.', ',') & '0' & @CRLF & _
						$lrc_Format[$i - 1][1] & @CRLF & @CRLF
			Next
			$lrc_text &= UBound($lrc_Format) & @CRLF & '00:' & StringReplace(_TickToTime($lrc_Format[UBound($lrc_Format) - 1][0]), '.', ',') & _
					'0 --> 00:00:00,000' & @CRLF & $lrc_Format[UBound($lrc_Format) - 1][1] & @CRLF & @CRLF
			$Dir = FileSaveDialog('选择保存的位置', '', '字幕文件(*.srt)|所有文件(*.*)', _
					16, StringRegExpReplace($bLVItems[$iSelected][0], '\.(\w+)$', '') & '.srt', $hGUI)
			If Not @error Then
				Local $lrc_file = FileOpen($Dir, 10)
				FileWrite($lrc_file, $lrc_text)
				FileClose($lrc_file)
				_ToolTip('保存成功', '已保存至 ' & $Dir, 2, 1)
			EndIf
		Else
			If $save_always_ask Or $temp_select < 0 Then
				$Dir = FileSaveDialog('选择保存的位置', '', '歌词文件(*.lrc)|所有文件(*.*)', _
						16, StringRegExpReplace($bLVItems[$iSelected][0], '\.(\w+)$', '') & '.lrc', $hGUI)
			Else
				$Dir = $root_folder & '\' & $bLVItems[$iSelected][7] & StringRegExpReplace($bLVItems[$iSelected][0], '\.(\w+)$', '') & '.lrc'
				If FileExists($Dir) Then
					Local $oo = MsgBox(259, '提示', '存在同名文件，是否覆盖？' & @CRLF & '点否选择其他文件夹', 10, $hGUI)
					If $oo = 7 Then
						$Dir = FileSaveDialog('选择其他文件夹', '', '歌词文件(*.lrc)|所有文件(*.*)', _
								16, StringRegExpReplace($bLVItems[$iSelected][0], '\.(\w+)$', '') & '.lrc', $hGUI)
					ElseIf $oo = 2 Then
						SetError(1)
					EndIf
				EndIf
			EndIf
			If Not @error Then
				Local $lrc_file = FileOpen($Dir, 10)
				FileWrite($lrc_file, $lrc_text)
				FileClose($lrc_file)
				_ToolTip('保存成功', '已保存至 ' & $Dir, 2, 1)
			EndIf
		EndIf
		If $temp_select <> $iSelected Then
			$iSelected = -1
			$bLVItems[0][0] = ''
		EndIf
	Else
		_ToolTip('提示', '没有歌词内容可以保存', 3, 1)
	EndIf
EndFunc   ;==>_Save

Func _FilterItem($keyword)
	Local $num = 0, $temp, $mm, $j = 1, $k = 1, $key
	If Not $keyword Then Return _FilterItem('<.*>')
	StringRegExp($keyword, '\<[^\>]*$', 3, 1)
	If $aLVItems[0] = 0 Or @error = 0 Then Return
	ReDim $bLVItems[$aLVItems[0]][8]
;~ 	MsgBox(0,$keyword,$old_keyword)
	If Not (StringLeft($keyword, 1) == '<') Then
		If $old_keyword And StringInStr($keyword, $old_keyword, 1) <> 1 Then
			For $i = 1 To $aLVItems[0]
				If StringLen($keyword) > StringLen($aLVItems[$i]) Then ContinueLoop
				For $k = 1 To StringLen($keyword)
					$key = _PinYin(StringMid($keyword, $k, 1))
					Do
						$mm = _PinYin(StringMid($aLVItems[$i], $j, 1))
						$j += 1
					Until @extended <> 1
					If $mm <> $key Then ExitLoop
				Next
				If $k = StringLen($keyword) + 1 Then
					$num += 1
					$temp = StringSplit($aLVItems[$i], '|', 2)
					For $j = 0 To 7
						$bLVItems[$num - 1][$j] = $temp[$j]
					Next
				EndIf
				$j = 1
			Next
		Else
			$key = _PinYin(StringRight($keyword, 1))
			For $i = 0 To $Data_Count - 1
				$j = StringLen($keyword)
				Do
					$mm = _PinYin(StringMid($bLVItems[$i][0], $j, 1))
					$j += 1
				Until @extended <> 1
				If $mm = $key Then
					$num += 1
;~ 					MsgBox(0,$num,$bLVItems[$i][0])
					If $num - 1 = $i Then ContinueLoop
					For $j = 0 To 7
						$bLVItems[$num - 1][$j] = $bLVItems[$i][$j]
					Next
				EndIf
			Next
		EndIf
		$old_keyword = $keyword
	Else
		$key = StringMid($keyword, 2, StringLen($keyword) - 2)
		For $i = 1 To $aLVItems[0]
			StringRegExp($aLVItems[$i], $key, 3, 1)
			If @error = 2 Then ExitLoop
			If @error = 1 Then ContinueLoop
			$num += 1
			$temp = StringSplit($aLVItems[$i], '|', 2)
			For $j = 0 To 7
				$bLVItems[$num - 1][$j] = $temp[$j]
			Next
		Next
		$old_keyword = ''
	EndIf
	If $num = 0 Then
		Dim $bLVItems[1][8] = [[0, 0, 0, 0, 0, 0, 0, 0]]
		$iSelected = -1
		$Data_Count = 0
		_GUICtrlStatusBar_SetText($StatusBar, '没有满足条件的文件！', 1)
		Return _GUICtrlListView_DeleteAllItems(GUICtrlGetHandle($hListView))
	EndIf
	ReDim $bLVItems[$num][8]
	$Data_Count = $num
	$temp_stat = "共有" & $Data_Count & "首歌曲！"
	_GUICtrlListView_DeleteAllItems(GUICtrlGetHandle($hListView))
	__GUICtrlListView_AddArray($hListView, $bLVItems)
	_GUICtrlStatusBar_SetText($StatusBar, $temp_stat, 1)
EndFunc   ;==>_FilterItem

Func _ToolBarMenu()
	Switch GUICtrlRead($TbarMenu)
		Case $qqjt
			_GUICtrlToolbar_SetButtonText($hToolbar, $idDat, '千千静听')
			$toolbar_subitem[0] = 0
		Case $kwyy
			_GUICtrlToolbar_SetButtonText($hToolbar, $idDat, '酷我音乐')
			$toolbar_subitem[0] = 2
		Case $mngc
			_GUICtrlToolbar_SetButtonText($hToolbar, $idDat, '迷你歌词')
			$toolbar_subitem[0] = 1
		Case $bdyy
			_GUICtrlToolbar_SetButtonText($hToolbar, $idDat, '百度')
			$toolbar_subitem[0] = 3
		Case $ilrc
			_GUICtrlToolbar_SetButtonText($hToolbar, $idDat, '吾爱歌词')
			$toolbar_subitem[0] = 4
		Case $qqyy
			_GUICtrlToolbar_SetButtonText($hToolbar, $idDat, 'QQ音乐')
			$toolbar_subitem[0] = 5
		Case $save_as_lrc
			_GUICtrlToolbar_SetButtonText($hToolbar, $idSav, '保存为lrc')
			$toolbar_subitem[1] = 0
		Case $save_as_srt
			_GUICtrlToolbar_SetButtonText($hToolbar, $idSav, '保存为srt')
			$toolbar_subitem[1] = 1
		Case Else

	EndSwitch
EndFunc   ;==>_ToolBarMenu
Func _ListMenu_Click()
	If $iSelected >= 0 Then $sel_dir = $root_folder & '\' & $bLVItems[$iSelected][7] & $bLVItems[$iSelected][0]
	Switch GUICtrlRead($ListMenu)
		Case $copy_item
			Local $Items = _GUICtrlListView_GetSelectedIndices($hListView, True)
			Local $Files = "", $L, $fi
			If $Items[0] Then
				If $copy_with_lrc Then
					For $i = 1 To $Items[0]
						$fi = $root_folder & '\' & $bLVItems[$Items[$i]][7] & $bLVItems[$Items[$i]][0]
						$L = $root_folder & '\' & $bLVItems[$Items[$i]][7] & StringRegExpReplace($bLVItems[$Items[$i]][0], '\.(\w+)$', '') & '.lrc'
						If FileExists($fi) Then
							$Files &= $fi & '|'
							If FileExists($L) Then $Files &= $L & '|'
						EndIf
					Next
				Else
					For $i = 1 To $Items[0]
						$fi = $root_folder & '\' & $bLVItems[$Items[$i]][7] & $bLVItems[$Items[$i]][0]
						If FileExists($fi) Then $Files &= $fi & '|'
					Next
				EndIf
				$Files = StringTrimRight($Files, 1)
				_ClipPutFile(_ANSI_FIX($Files))
				_ToolTip('提示', '文件已复制到剪切板', 3, 1)
			Else
				Return _ToolTip('提示', '文件不存在或未选中！', 3, 1)
			EndIf
		Case $reload_item
			Local $sel_index = _ArraySearch($aLVItems, $bLVItems[$iSelected][0], 1, 0, 0, 1)
			_SearchFile($root_folder, $sel_dir, $iSelected)
			$aLVItems[$sel_index] = StringFormat('%s|%s|%s|%s|%s|%s|%s|%s', $bLVItems[$iSelected][0], _
					$bLVItems[$iSelected][1], $bLVItems[$iSelected][2], $bLVItems[$iSelected][3], _
					$bLVItems[$iSelected][4], $bLVItems[$iSelected][5], $bLVItems[$iSelected][6], $bLVItems[$iSelected][7])
			For $i = 0 To 7
				_GUICtrlListView_SetItemText($hListView, $iSelected, $bLVItems[$iSelected][$i], $i)
			Next
			$temp_stat = "共有" & $Data_Count & "首歌曲！"
			_GUICtrlStatusBar_SetText($StatusBar, $temp_stat, 1)

		Case $copy_qq_item
			Local $TagsHandle = _BASS_StreamCreateFile(False, $sel_dir, 0, 0, 0)
			Local $pPtr = _BASS_ChannelGetTags($TagsHandle, 10)
			If @error = $BASS_ERROR_NOTAVAIL Then
				_BASS_StreamFree($TagsHandle)
				Return _ToolTip('提示', '没有内嵌歌词', 3, 1)
			ElseIf @error = $BASS_ERROR_HANDLE Then
				Return _ToolTip('错误', '打开文件失败', 3, 3)
			EndIf
			Local $iStrLen = _BASS_PtrStringLen($pPtr)
			Local $sStr = _BASS_PtrStringRead($pPtr, False, $iStrLen)
			Local $lyrics_qq = StringTrimLeft(StringTrimRight($sStr, 15), 30)
			_BASS_StreamFree($TagsHandle)
			$sStr = 0
			$pPtr = 0
			If Not $lyrics_qq Then Return _ToolTip('未知错误', '没有内嵌歌词', 3)
			$lrc_Format = _lrc_Prase($lyrics_qq)
			If UBound($lrc_Format, 0) = 2 Then
				Update_L()
			Else
				_ToolTip('提示', StringRegExpReplace($bLVItems[$iSelected][0], '\.(\w+)$', '') & ' 内嵌歌词已复制到剪切板', 3, 1)
			EndIf
			Return
		Case $edit_item
			$intReturn = DllCall("shell32.dll", "int", "SHObjectProperties", "hwnd", 0, "dword", _
					$SHOP_FILEPATH, "wstr", $sel_dir, "wstr", $sTab)
			If Not $intReturn[0] Then Return _ToolTip('错误', '打开错误', 3, 3)
			$prop_item = StringRegExpReplace($bLVItems[$iSelected][0], '\.(\w+)$', '')
			If Not WinWait('[CLASS:#32770;TITLE:' & $prop_item & ']', '', 5) Then Return
			ControlClick('[CLASS:#32770;TITLE:' & $prop_item & ']', "", "[CLASS:Button; TEXT:(&V) >>; INSTANCE:1; ID:315]")
			AdlibRegister('Check_Prop', 1000)
		Case $id3_item
			If Not IsHWnd($ID3_dial) Then _ID3_GUI()
			_Edit_ID3($sel_dir)
		Case $del_id3_item
			_ID3WriteTag($sel_dir, 1)
			_ToolTip('提示', '清除成功！', 3, 1)
		Case $copy_lyr_item
			_ID3ReadTag($sel_dir, 2, "SYLT")
			Local $id3_lyr = _ID3GetTagField("SYLT")
			If Not $id3_lyr Then Return _ToolTip('提示', '没有内嵌歌词', 3, 1)
			$lrc_Format = _lrc_Prase($id3_lyr, 1)
			If UBound($lrc_Format, 0) = 2 Then
				Update_L()
			Else
				MsgBox(0, '无法识别标签', $id3_lyr)
			EndIf
		Case $load_cover
			If Not $begin Then
				$begin = TimerInit()
			Else
				If TimerDiff($begin) - $lastClick <= 5000 Then
					$lastClick = TimerDiff($begin)
					Return MsgBox(64, '', '刷新太快', 3, $hGUI)
				EndIf
				$lastClick = TimerDiff($begin)
			EndIf
			If $coverStartIndex = 0 Then
				If $iSelected >= 0 Then
					$cover_key_input = InputBox('专辑', '专辑名正确吗？' & @LF & _
							'专辑未知可以尝试搜歌名或歌手名', $bLVItems[$iSelected][3], '', 300, 150, Default, Default, 30, $hGUI)
				Else
					$cover_key_input = InputBox('专辑', '请输入专辑名' & @LF & '专辑未知可以尝试搜歌名或歌手名', '', '', 300, 150, Default, Default, 30, $hGUI)
				EndIf
				If @error Or (Not $cover_key_input) Then Return $GUI_RUNDEFMSG
				$coverStartIndex = 1
			EndIf
			$load_flag = 1
			$mode = 6
			$send = 'api.douban.com|/music/subjects?q=' & _UrlToHex($cover_key_input, 1, 'unicode') & '&start-index=' & $coverStartIndex & '&max-results=30' & '|1||||'
			ClipPut($send)
			If _CoProcSend($load_Pro, $send) Then
				_ShowLoading()
			Else
				_ToolTip('错误', "Worker not Responding (" & @error & ")", 3, 3)
			EndIf
		Case $rn_item
			_GUICtrlListView_EditLabel($hListView, $iSelected)
		Case $shell_item
			Local $asCurInfo = GUIGetCursorInfo($hGUI)
			If @error Then Dim $asCurInfo[2] = [0, 0]
			ClientToScreen($hGUI, $asCurInfo[0], $asCurInfo[1])
			$ShellContextMenu.Show($sel_dir, $asCurInfo[0], $asCurInfo[1])
		Case $rm_item
			_ToolTip('提示', _Iif(FileRecycle($sel_dir), '文件已放入回收站', '删除未成功'), 3, 1)
			If Not FileExists($sel_dir) Then
				_GUICtrlListView_DeleteItem(GUICtrlGetHandle($hListView), $iSelected)
				$Data_Count -= 1
				If Not $Data_Count Then
					Dim $bLVItems[1][8] = [[0, 0, 0, 0, 0, 0, 0, 0]]
					Dim $aLVItems[2] = [0, -1]
				Else
					Local $sel_index = _ArraySearch($aLVItems, $bLVItems[$iSelected][0], 1, 0, 0, 1)
					_ArrayDelete($bLVItems, $iSelected)
					_ArrayDelete($aLVItems, $sel_index)
					$aLVItems[0] = $Data_Count
				EndIf
				$temp_stat = "共有" & $Data_Count & "首歌曲！"
				_GUICtrlStatusBar_SetText($StatusBar, $temp_stat, 1)
			EndIf
	EndSwitch

EndFunc   ;==>_ListMenu_Click
Func _ToolBar_Click()
	If Not $begin Then
		$begin = TimerInit()
	Else
		If TimerDiff($begin) - $lastClick <= 1000 Then
			_ToolTip("", "请不要频繁刷新！", 3, 1)
			$lastClick = TimerDiff($begin)
			Return
		EndIf
		$lastClick = TimerDiff($begin)
	EndIf
	Switch GUICtrlRead($Tbar)
		Case $idAdd
			If Not FileExists(@SystemDir & '\shmedia.dll') And @OSVersion = 'WIN_XP' Then
				If FileCopy(@ScriptDir & "\shmedia.dll", @SystemDir & "\") Then
					RunWait('regsvr32.exe /s shmedia.dll', '', 0)
				Else
					_ToolTip('注意', '缺少 shmedia.dll 文件，无法读取歌曲属性！' & @LF & '请将该文件置于程序路径下并重新加载目录', 3, 1)
				EndIf
			EndIf
			If Not $drop_DIR Then
				Local $tmp_root_folder = FileSelectFolder("选择文件夹", '', 2, $root_folder, $hGUI)
				If @error Then Return
				$root_folder = $tmp_root_folder
				If FileExists(@ScriptDir & '\config.ini') Then IniWrite(@ScriptDir & '\config.ini', "others", "work_dir", $root_folder)
			EndIf
			$drop_DIR = False
			_SearchFile($root_folder)
			$temp_stat = "共有" & $Data_Count & "首歌曲！"
			_GUICtrlStatusBar_SetText($StatusBar, $temp_stat, 1)
			If $Data_Count = 0 Then Return ProgressOff()
			__GUICtrlListView_AddArray($hListView, $bLVItems)
			Dim $aLVItems[$Data_Count + 1]
			$aLVItems[0] = $Data_Count
			For $i = 1 To $aLVItems[0]
				$aLVItems[$i] = _GUICtrlListView_GetItemTextString($hListView, $i - 1)
			Next
			$iSelected = -1
			ProgressOff()
		Case $idOpen
			Local $nselect[1]
			If Not $root_folder Then Return
			If $iSelected > -1 Then
				$nselect[0] = $bLVItems[$iSelected][0]
				_WinAPI_ShellOpenFolderAndSelectItems($root_folder & '\' & $bLVItems[$iSelected][7], $nselect)
			Else
				ShellExecute($root_folder)
			EndIf

		Case $idAbt
			MsgBox(0, '关于&帮助', $about, 20, $hGUI)
		Case $idSet
			If Not $Setting Then Return _Setting_Gui()
			GUISetState(@SW_SHOW, $Setting)
		Case $idSav
			_Save()
		Case $idLst
			If _GUICtrlListView_GetItemCount($hListView) <= 1 Then Return
			Local $List_Dir = FileSaveDialog('选择列表保存的位置', '', 'm3u播放列表(*.m3u;*m3u8)|所有文件(*.*)', 16, 'PlayList.m3u', $hGUI)
			If @error Then Return
			Local $List_data = '#EXTM3U' & @CRLF
			For $i = 0 To UBound($bLVItems) - 1
				$ti = StringSplit($bLVItems[$i][6], ':')
				If Not @error And $bLVItems[$i][1] And $bLVItems[$i][2] Then _
						$List_data &= StringFormat('#EXTINF:%s,%s - %s', Number($ti[1]) * 3600 + Number($ti[2]) * 60 + Number($ti[3]), _
						$bLVItems[$i][2], $bLVItems[$i][1]) & @CRLF
				$List_data &= $root_folder & '\' & $bLVItems[$i][7] & $bLVItems[$i][0] & @CRLF
			Next
			Local $m3u_file = FileOpen($List_Dir, 10)
			FileWrite($m3u_file, $List_data)
			FileClose($m3u_file)
		Case $idDat
			_Search($toolbar_subitem[0])
	EndSwitch
	Return
EndFunc   ;==>_ToolBar_Click
Func _StatusBar_Click()
	$load_flag = 1
	If _CoProcSend($load_Pro, 'ping|' & $isCnc) Then
		_ShowLoading()
	Else
		_ToolTip('错误', "Worker not Responding (" & @error & ")", 3, 3)
	EndIf
EndFunc   ;==>_StatusBar_Click

Func _LyrMenu_Click()
	If UBound($lrc_Format, 0) <> 2 Then Return
	Switch GUICtrlRead($LyrMenu)
		Case $tq
			_timeStamp(-200)
		Case $tq1
			_timeStamp(-1000)
		Case $tq2
			_timeStamp(-500)
		Case $yh
			_timeStamp(200)
		Case $yh1
			_timeStamp(500)
		Case $yh2
			_timeStamp(1000)
		Case $sc
			For $i = 1 To $lyr_select[0]
				_ArrayDelete($lrc_Format, $lyr_select[$i])
				If IsArray($lrc_Show) Then _ArrayDelete($lrc_Show, $lyr_select[$i])
				If $lyr_select[$i] < $n Then $n -= 1
			Next
			_GUICtrlListView_DeleteItemsSelected(GUICtrlGetHandle($Lrc_List))
		Case $hd
			If IsDllStruct($l_head) Then _Head_Change()
		Case $cr
			Local $num = UBound($lrc_Format)
			ReDim $lrc_Format[$num + 1][3]
			GUICtrlCreateListViewItem('...', $Lrc_List)
			If $lyr_select[1] = $num - 1 Then
				$lrc_Format[$num - 1][2] = 3000
				$lrc_Format[$num][0] = $lrc_Format[$num - 1][0] + 3000
				$lrc_Format[$num][1] = '...'
			Else
				For $i = $num - 1 To $lyr_select[1] Step -1
					$lrc_Format[$i + 1][0] = $lrc_Format[$i][0]
					$lrc_Format[$i + 1][1] = $lrc_Format[$i][1]
					$lrc_Format[$i + 1][2] = $lrc_Format[$i][2]
				Next
				If $lyr_select[1] = 0 Then
					$lrc_Format[0][0] = 0
					$lrc_Format[0][2] = $lrc_Format[1][0]
				Else
					$lrc_Format[$lyr_select[1]][0] = Round(($lrc_Format[$lyr_select[1] + 1][0] + $lrc_Format[$lyr_select[1] - 1][0]) / 2)
					$lrc_Format[$lyr_select[1]][2] = $lrc_Format[$lyr_select[1] + 1][0] - $lrc_Format[$lyr_select[1]][0]
					$lrc_Format[$lyr_select[1] - 1][2] = $lrc_Format[$lyr_select[1]][0] - $lrc_Format[$lyr_select[1] - 1][0]
				EndIf
				$lrc_Format[$lyr_select[1]][1] = '...'
				Dim $List_ID[$num - $lyr_select[1] + 1]
				For $j = 0 To $num - $lyr_select[1]
					$List_ID[$j] = _GUICtrlListView_GetItemParam($Lrc_List, $j + $lyr_select[1])
					GUICtrlSetData($List_ID[$j], $lrc_Format[$lyr_select[1] + $j][1])
				Next

			EndIf
			If IsArray($lrc_Show) Then
				Local $tail = $lrc_Show[$num][0]
				Dim $lrc_Show = $lrc_Format
				ReDim $lrc_Show[$num + 2][3]
				$lrc_Show[$num + 1][0] = $tail
				$lrc_Show[$num][2] = $lrc_Show[$num + 1][0] - $lrc_Show[$num][0]
			EndIf
			If $lyr_select[1] < $n Then $n += 1
;~ 			_GUICtrlListView_InsertItem($Lrc_List, "...", $lyr_select[1],99)   ;can't return handle for autoit
			_GUICtrlListView_EditLabel($Lrc_List, $lyr_select[1])
	EndSwitch
	$lyr_changed = True
EndFunc   ;==>_LyrMenu_Click
Func _FileChange()
	Switch GUICtrlRead($FileChange)
		Case 1
			If $pre_name Then
				_File_Rename($root_folder & '\' & $old_name, $pre_name)
				If @error Then
					_ToolTip('错误', '无法重命名！' & @LF & '错误代码 ' & @error, 3, 3)
					_GUICtrlListView_SetItemText($hListView, $Changed, StringRegExpReplace($old_name, '^.*\\', ''))
				Else
					$bLVItems[$Changed][0] = $pre_name
					$aLVItems[$Changed + 1] = StringReplace($aLVItems[$Changed + 1], StringRegExpReplace($old_name, '^.*\\', ''), $pre_name)
					_ToolTip('重命名成功', 'Success！', 3)
				EndIf
			EndIf
			$Changed = -1
		Case 2
			Local $FMTETCs[1] = [_CreateHDROP_FORMATETC()]
			Local $Items = _GUICtrlListView_GetSelectedIndices($hListView, True)
			Local $Files = "", $L, $fi
			If $copy_with_lrc Then
				For $i = 1 To $Items[0]
					$fi = $root_folder & '\' & $bLVItems[$Items[$i]][7] & $bLVItems[$Items[$i]][0]
					$L = $root_folder & '\' & $bLVItems[$Items[$i]][7] & StringRegExpReplace($bLVItems[$Items[$i]][0], '\.(\w+)$', '') & '.lrc'
					If FileExists($fi) Then
						$Files &= $fi & '|'
						If FileExists($L) Then $Files &= $L & '|'
					EndIf
				Next
			Else
				For $i = 1 To $Items[0]
					$fi = $root_folder & '\' & $bLVItems[$Items[$i]][7] & $bLVItems[$Items[$i]][0]
					If FileExists($fi) Then $Files &= $fi & '|'
				Next
			EndIf
			$Files = StringTrimRight($Files, 1)
			If $Items[0] >= 3 Then WinSetState($hGUI, '', @SW_MINIMIZE)
			Local $STGMDs[1] = [_CreateDROPFILES_STGMEDIUM($Files)]
			$objIDataSource = _CreateIDataObject($FMTETCs, $STGMDs)
			If Not _ObjGetObjPtr($objIDataSource) Then
				_ReleaseStgMedium($STGMDs[0])
				Return GUIRegisterMsg(0x233, "WM_DROPFILES")
			EndIf
			_SetBMP($IDragSourceHelper, $objIDataSource)
			Local $Effect
			Local $result = _DoDragDrop($objIDataSource, $objIDropSource, BitOR($DROPEFFECT_MOVE, $DROPEFFECT_COPY, $DROPEFFECT_LINK), $Effect)

			If $result = $DRAGDROP_S_DROP Then
				$Effect = _GetUnoptimizedEffect($objIDataSource, $Effect)
				Switch $Effect
					Case $DROPEFFECT_MOVE
						For $i = $Items[0] To 1 Step -1
							If Not FileExists($root_folder & '\' & $bLVItems[$Items[$i]][7] & $bLVItems[$Items[$i]][0]) Then
								_GUICtrlListView_DeleteItem(GUICtrlGetHandle($hListView), $Items[$i])
								$Data_Count -= 1
								If Not $Data_Count Then
									Dim $bLVItems[1][8] = [[0, 0, 0, 0, 0, 0, 0, 0]]
									Dim $aLVItems[2] = [0, -1]
								Else
									Local $sel_index = _ArraySearch($aLVItems, $bLVItems[$Items[$i]][0], 1, 0, 0, 1)
									_ArrayDelete($bLVItems, $Items[$i])
									_ArrayDelete($aLVItems, $sel_index)
									$aLVItems[0] = $Data_Count
								EndIf
							EndIf
						Next
						_ToolTip('提示', '文件移动成功', 3, 1)
					Case $DROPEFFECT_COPY
						_ToolTip('提示', '文件复制成功', 3, 1)
					Case $DROPEFFECT_LINK

					Case $DROPEFFECT_NONE
						Local $deletedAnything = False
						If @OSType = "WIN32_NT" Then
							For $i = $Items[0] To 1 Step -1
								If Not FileExists($root_folder & '\' & $bLVItems[$Items[$i]][7] & $bLVItems[$Items[$i]][0]) Then
									_GUICtrlListView_DeleteItem(GUICtrlGetHandle($hListView), $Items[$i])
									$Data_Count -= 1
									If Not $Data_Count Then
										Dim $bLVItems[1][8] = [[0, 0, 0, 0, 0, 0, 0, 0]]
										Dim $aLVItems[2] = [0, -1]
										$iSelected = -1
									Else
										Local $sel_index = _ArraySearch($aLVItems, $bLVItems[$Items[$i]][0], 1, 0, 0, 1)
										_ArrayDelete($bLVItems, $Items[$i])
										_ArrayDelete($aLVItems, $sel_index)
										$aLVItems[0] = $Data_Count
									EndIf
									$deletedAnything = True
								EndIf
							Next
							If $deletedAnything Then _ToolTip('tips', 'Workaround detect: Move', 3, 1)
						EndIf
						If $deletedAnything = False Then
						EndIf
				EndSwitch
				$temp_stat = "共有" & $Data_Count & "首歌曲！"
				_GUICtrlStatusBar_SetText($StatusBar, $temp_stat, 1)
			ElseIf $result = $DRAGDROP_S_CANCEL Then
;~ 				MsgBox(0, '', "DoDragDrop cancelled")
			Else
				_ToolTip('tips', 'Error on DoDragDrop', 3, 1)
			EndIf
			_ReleaseIDataObject($objIDataSource)
			Return GUISetStyle(-1, 0x00000010, $hGUI)
		Case 3
			Local $aRect = _GUICtrlListView_GetSubItemRect($IWndListView, 15, 1)
			Local $aPos = ControlGetPos($ID3_dial, '', $IWndListView)
			Local $text = FileRead($LyricsFile)
			$hEdit = _GUICtrlEdit_Create($ID3_dial, $text, $aPos[0] + $aRect[0], $aPos[1] + $aRect[1], _
					120, 20, BitOR($WS_CHILD, $WS_VISIBLE, $ES_AUTOHSCROLL, $ES_LEFT))
			_GUICtrlEdit_SetSel($hEdit, 0, -1)
			_WinAPI_SetFocus($hEdit)
			_WinAPI_BringWindowToTop($hEdit)
	EndSwitch
	Return
EndFunc   ;==>_FileChange
Func _Head_Change()
	$lGUI = GUICreate("", 172, 123, 346, 196, $WS_POPUP, BitOR($WS_EX_TOPMOST, $WS_EX_WINDOWEDGE), $hGUI)
	GUISetBkColor(0x969696)
	GUICtrlCreateLabel('输入歌曲信息', 48, 5, 75, 12, -1, $GUI_WS_EX_PARENTDRAG)
	GUICtrlCreateLabel('[ti:' & @LF & '[ar:' & @LF & '[al:' & @LF & '[by:', 15, 25, 21, 89, -1, $GUI_WS_EX_PARENTDRAG)
	$h[0] = GUICtrlCreateInput(DllStructGetData($l_head, 1), 42, 22, 64, 21)
	$h[1] = GUICtrlCreateInput(DllStructGetData($l_head, 2), 42, 46, 64, 21)
	$h[2] = GUICtrlCreateInput(DllStructGetData($l_head, 3), 42, 70, 64, 21)
	$h[3] = GUICtrlCreateInput(DllStructGetData($l_head, 4), 42, 94, 64, 21)
	GUICtrlCreateLabel(']' & @LF & @LF & ']' & @LF & @LF & ']' & @LF & @LF & ']', 115, 25, 8, 89, -1, $GUI_WS_EX_PARENTDRAG)
	$head_OK = GUICtrlCreateButton("确定", 132, 30, 25, 73, $BS_MULTILINE)
	GUICtrlSetOnEvent($head_OK, 'gui')
	GUISetState()
	GUISwitch($hGUI)
EndFunc   ;==>_Head_Change

Func _Chek_net($hWnd, $tn)
	Local $data, $color
	If Not $tn Then
		$data = 'r'
		$color = 0xff0000
	Else
		Switch $tn
			Case 0 To 30
				$data = 'a'
				$color = 0xff00
			Case 31 To 100
				$data = 'a'
				$color = 0xfff000
			Case 100 To 400
				$data = 'a'
				$color = 0xff9000
			Case Else
				$data = 'r'
				$color = 0xff0000
		EndSwitch
	EndIf
	GUICtrlSetData($hWnd, $data)
	GUICtrlSetColor($hWnd, $color)
EndFunc   ;==>_Chek_net

Func menuCheck($i)
	Local $j = 1
	Do
		If BitAND(GUICtrlRead(Eval('col_' & $j)), $GUI_CHECKED) == $GUI_CHECKED Then
			If $j <> $i Then GUICtrlSetState(Eval('col_' & $j), $GUI_UNCHECKED)
		Else
			If $j == $i Then GUICtrlSetState(Eval('col_' & $j), $GUI_CHECKED)
		EndIf
		$j += 1
	Until $j >= 7
	$GUI_color = $i
EndFunc   ;==>menuCheck

Func Check_Prop()
	If Not WinExists('[CLASS:#32770;TITLE:' & $prop_item & ']', '') Then
		Local $iSelected = _ArraySearch($bLVItems, $prop_item, 1, 0, 0, 1, 1)
		GUICtrlSendToDummy($ListMenu, $reload_item)
		AdlibUnRegister('Check_Prop')
	EndIf
EndFunc   ;==>Check_Prop

Func Update_L($col = 0)
	_GUICtrlListView_BeginUpdate($Lrc_List)
	_GUICtrlListView_DeleteAllItems($Lrc_List)
	For $i = 0 To UBound($lrc_Format, 1) - 1
		GUICtrlCreateListViewItem($lrc_Format[$i][1], $Lrc_List)
	Next
	_GUICtrlListView_SetColumnWidth($Lrc_List, 0, $LVSCW_AUTOSIZE_USEHEADER)
	If $col Then
		GUICtrlSetColor($Lrc_List, $col)
		_GUICtrlListView_RedrawItems($Lrc_List, 0, $i - 1)

	ElseIf _BASS_ChannelIsActive($MusicHandle) <> 0 Then
		Dim $lrc_Show = $lrc_Format
		ReDim $lrc_Show[UBound($lrc_Format, 1) + 1][3]
		$lrc_Show[UBound($lrc_Format, 1)][0] = Round(_BASS_ChannelBytes2Seconds($MusicHandle, $length) * 1000, 0)
		$lrc_Show[UBound($lrc_Format, 1) - 1][2] = $lrc_Show[UBound($lrc_Format, 1)][0] - $lrc_Show[UBound($lrc_Format, 1) - 1][0]
		$n = 2
		$move_timer = _Timer_SetTimer($hGUI, 50, 'move_list', $move_timer)
	EndIf
	_GUICtrlListView_EndUpdate($Lrc_List)
EndFunc   ;==>Update_L

Func t_format()
	If Not $force_ti_format And $bLVItems[$iSelected][1] And $bLVItems[$iSelected][2] Then
		GUICtrlSetData($title, $bLVItems[$iSelected][1])
		GUICtrlSetData($artist, $bLVItems[$iSelected][2])
	Else
		Local $title_regexp = StringRegExp($bLVItems[$iSelected][0], '([^-.\]]+)\h*[-－_]+\h*(.*?)\.\w+$', 3, 1)
		If Not @error Then
			GUICtrlSetData($artist, $title_regexp[BitXOR(1, $reg_order)])
			GUICtrlSetData($title, $title_regexp[BitXOR(0, $reg_order)])
		Else
			GUICtrlSetData($title, StringRegExpReplace($bLVItems[$iSelected][0], '\.(\w+)$', ''))
			GUICtrlSetData($artist, $bLVItems[$iSelected][2])
		EndIf
	EndIf
EndFunc

; #FUNCTION# =========================================================================================================
; Name...........: GUIGetBkColor
; Description ...: Retrieves the RGB value of the GUI background.
; Syntax.........: GUIGetBkColor($hHandle)
; Parameters ....: $hHandle - A valid GUI handle.
; Requirement(s).: v3.3.2.0 or higher
; Return values .: Success - Returns RGB value of the GUI background.
;                  Failure - Returns 0 & sets @error = 1
; Author ........: guinness & additional information from PsaltyDS
; Example........; Yes
;=====================================================================================================================
Func GUIGetBkColor($hHandle)
	Local $bGetBkColor, $hDC
	$hDC = _WinAPI_GetDC($hHandle)
	$bGetBkColor = _WinAPI_GetBkColor($hDC)
	_WinAPI_ReleaseDC($hHandle, $hDC)
	Return $bGetBkColor
EndFunc   ;==>GUIGetBkColor

Func _exit()
	If _CoProcSend($load_Pro, 'exit|') Then

	Else
		If Not ProcessClose($load_Pro) Then _ToolTip('错误', "无法停止进程，错误代码: " & @error, 3)
	EndIf
	GUISetState(@SW_HIDE, $hGUI)
	_WinAPI_DeleteObject($Font1)
	_GUICtrlMenuEx_DestroyMenu($SubMenu)
	_GUICtrlMenuEx_DestroyMenu($SubMenu2)
	For $i = 0 To UBound($hIcons) - 1
		_WinAPI_DestroyIcon($hIcons[$i])
	Next
	_GDIPlus_Shutdown()
;~ 	DllCall($Dll_, "int", "USkinRemoveSkin") ;这里是关闭皮肤
;~ 	DllCall($Dll_, "int", "USkinExit") ;这里是退出皮肤调用的DLL
;~ 	DllClose($Dll_) ;关闭DLL文件调用
	_ReleaseIDropSource($objIDropSource)
	_OLEUnInitialize() ;drag/drop dll release
	_IUnknown_Release($IDragSourceHelper)
	_BASS_PluginFree(0)
	_Bass_Free()
	$_Free = 1
	_ID3DeleteFiles()
;~ 	MsgBox(0, '', 'Exit')
;~	GUIDelete()
	Exit
EndFunc   ;==>_exit

Func _OnAutoItExit()
	If $_Free = 0 Then _exit()
EndFunc   ;==>_OnAutoItExit
Func ID()
	GUICtrlSendToDummy($ListMenu, $id3_item)
EndFunc   ;==>ID
Func _WM_NOTIFY($hWndGUI, $MsgID, $WParam, $LParam)
	#forceref $hWndGUI, $MsgID, $wParam
	Local $tNMHDR, $event, $hwndFrom, $code, $i_idNew, $dwFlags, $lResult, $idFrom, $i_idOld, $tInfo
	Local $tNMTOOLBAR, $tNMTBHOTITEM, $hMenu, $hSubmenu, $lMenu, $lMenuID, $aRet, $iMenuID, $wMenu, $wMenuID
	$tNMHDR = DllStructCreate($tagNMHDR, $LParam)
	$hwndFrom = DllStructGetData($tNMHDR, "hWndFrom")
	$idFrom = DllStructGetData($tNMHDR, "IDFrom")
	$code = DllStructGetData($tNMHDR, "Code")
	Switch $hwndFrom
		Case $hToolbar
			Switch $code
				Case $TBN_DROPDOWN
					$hMenu = _GUICtrlMenu_CreatePopup()
					Switch $iItem
						Case $idDat
							_GUICtrlMenu_AddMenuItem($hMenu, "千千静听", $qqjt)
							_GUICtrlMenu_AddMenuItem($hMenu, "酷我音乐", $kwyy)
							_GUICtrlMenu_AddMenuItem($hMenu, "迷你歌词", $mngc)
							_GUICtrlMenu_AddMenuItem($hMenu, "百度音乐", $bdyy)
							_GUICtrlMenu_AddMenuItem($hMenu, "吾爱歌词", $ilrc)
							_GUICtrlMenu_AddMenuItem($hMenu, "QQ音乐", $qqyy)
						Case $idSav
							_GUICtrlMenu_AddMenuItem($hMenu, "保存为lrc", $save_as_lrc)
							_GUICtrlMenu_AddMenuItem($hMenu, "保存为srt", $save_as_srt)
					EndSwitch

					$aRet = _GetToolbarButtonScreenPos($hGUI, $hToolbar, $iItem, 2)
					If Not IsArray($aRet) Then
						Dim $aRet[2] = [-1, -1]
					EndIf

					; send button dropdown menu item commandID to dummy control for use in GuiGetMsg() or GUICtrlSetOnEvent()
					; allows quick return from message handler : See warning for GUIRegisterMsg() in helpfile
					$iMenuID = _GUICtrlMenu_TrackPopupMenu($hMenu, $hToolbar, $aRet[0], $aRet[1], 1, 1, 2)
					_GUICtrlMenu_DestroyMenu($hMenu)
					If Not $iMenuID Then Return $TBDDRET_DEFAULT
					GUICtrlSendToDummy($TbarMenu, $iMenuID)
					;If $iMenuID Then Return $TBDDRET_TREATPRESSED
					Return $TBDDRET_DEFAULT
				Case $TBN_HOTITEMCHANGE
					$tNMTBHOTITEM = DllStructCreate($tagNMTBHOTITEM, $LParam)
					$i_idOld = DllStructGetData($tNMTBHOTITEM, "idOld")
					$i_idNew = DllStructGetData($tNMTBHOTITEM, "idNew")
					$iItem = $i_idNew
					$dwFlags = DllStructGetData($tNMTBHOTITEM, "dwFlags")
			EndSwitch
		Case $hWndListView
			Switch $code
				Case $LVN_COLUMNCLICK ; sorting
					Local $iFormat, $asc
					If $Changed <> -1 Or _GUICtrlListView_GetItemCount($hWndListView) <= 1 Then Return $GUI_RUNDEFMSG
					$tInfo = DllStructCreate($tagNMLISTVIEW, $LParam)
;~ 					Local $rr = _Timer_Init()
					For $x = 0 To _GUICtrlHeader_GetItemCount($hHeader) - 1
						$iFormat = _GUICtrlHeader_GetItemFormat($hHeader, $x)
						If BitAND($iFormat, $HDF_SORTDOWN) Then
							If $x == DllStructGetData($tInfo, "SubItem") Then
								_GUICtrlHeader_SetItemFormat($hHeader, $x, BitOR(BitXOR($iFormat, $HDF_SORTDOWN), $HDF_SORTUP))
								$asc = 1
							Else
								_GUICtrlHeader_SetItemFormat($hHeader, $x, BitXOR($iFormat, $HDF_SORTDOWN))
							EndIf
						ElseIf BitAND($iFormat, $HDF_SORTUP) Then
							If $x == DllStructGetData($tInfo, "SubItem") Then
								_GUICtrlHeader_SetItemFormat($hHeader, $x, BitOR(BitXOR($iFormat, $HDF_SORTUP), $HDF_SORTDOWN))
								$asc = -1
							Else
								_GUICtrlHeader_SetItemFormat($hHeader, $x, BitXOR($iFormat, $HDF_SORTUP))
							EndIf
						EndIf
					Next
					If Not $asc Then _GUICtrlHeader_SetItemFormat($hHeader, DllStructGetData($tInfo, "SubItem"), BitOR($iFormat, $HDF_SORTUP))
					Switch DllStructGetData($tInfo, "SubItem")
						Case 5
							__ArraySort($bLVItems, $asc, 0, 0, DllStructGetData($tInfo, "SubItem"), True)
						Case Else
							__ArraySort($bLVItems, $asc, 0, 0, DllStructGetData($tInfo, "SubItem"))
					EndSwitch
					_GUICtrlListView_DeleteAllItems($hWndListView)
;~ 					ToolTip(_Timer_Diff($rr))
					_GUICtrlListView_SetItemCount($hWndListView, UBound($bLVItems))
					__GUICtrlListView_AddArray($hListView, $bLVItems)
;~ 					MsgBox(0, _Timer_Diff($rr), 'DONE')
;~ 					_GUICtrlListView_SimpleSort($hWndListView, True, DllStructGetData($tInfo, "SubItem"))
					; No return value
				Case $NM_CLICK
					If Not $bLVItems[0][0] Then Return
					Local $tInfo = DllStructCreate($tagNMITEMACTIVATE, $LParam)
					Local $Index = DllStructGetData($tInfo, "Index")
					If $Index = -1 Then Return $GUI_RUNDEFMSG
					If $iSelected = $Index Then
						$fDblClk = DllStructGetData($tInfo, "SubItem")
					Else
						$iSelected = $Index
						Call("t_format")
						If BitAND(GUICtrlGetState($l_btn_header), $GUI_DISABLE) = $GUI_DISABLE Then
							If FileExists($root_folder & '\' & $bLVItems[$iSelected][7] & _
									StringRegExpReplace($bLVItems[$iSelected][0], '\.(\w+)$', '') & '.lrc') Then GUICtrlSetState($l_btn_header, $GUI_ENABLE)
						Else
							If Not FileExists($root_folder & '\' & $bLVItems[$iSelected][7] & _
									StringRegExpReplace($bLVItems[$iSelected][0], '\.(\w+)$', '') & '.lrc') Then GUICtrlSetState($l_btn_header, $GUI_DISABLE)
						EndIf
					EndIf
				Case $NM_RCLICK
					Local $tInfo = DllStructCreate($tagNMITEMACTIVATE, $LParam)
					Local $item_sel = DllStructGetData($tInfo, "Index")
					If $item_sel = -1 Then Return $GUI_RUNDEFMSG
					$iSelected = $item_sel
					Call("t_format")
					If StringRight($bLVItems[$iSelected][0], 3) <> 'mp3' Or _BASS_ChannelIsActive($MusicHandle) Then
						_GUICtrlMenu_SetItemDisabled($SubMenu, 7)
						_GUICtrlMenu_SetItemDisabled($SubMenu, 8)
					ElseIf _GUICtrlMenu_GetItemDisabled($SubMenu, 7) Then
						_GUICtrlMenu_SetItemEnabled($SubMenu, 7)
						_GUICtrlMenu_SetItemEnabled($SubMenu, 8)
					EndIf
					If _BASS_ChannelIsActive($MusicHandle) Then
						_GUICtrlMenu_SetItemDisabled($SubMenu, 0)
						_GUICtrlMenu_SetItemDisabled($SubMenu, 5)
					ElseIf _GUICtrlMenu_GetItemDisabled($SubMenu, 0) Then
						_GUICtrlMenu_SetItemEnabled($SubMenu, 0)
						_GUICtrlMenu_SetItemEnabled($SubMenu, 5)
					EndIf
					Return _GUICtrlMenu_TrackPopupMenu($SubMenu, $hGUI)
				Case $NM_DBLCLK
					$tInfo = DllStructCreate($tagNMITEMACTIVATE, $LParam)
					$Index = DllStructGetData($tInfo, "Index")
					If $Index = -1 Then Return $GUI_RUNDEFMSG
					_Stop()
					_Play()
				Case $LVN_BEGINDRAG
					Local $tInfo = DllStructCreate($tagNMLISTVIEW, $LParam)
					Local $Drag_Index = DllStructGetData($tInfo, "Item")
					$iSelected = $Drag_Index
					GUISetStyle(-1, 0x00000000, $hGUI)
					GUICtrlSendToDummy($FileChange, 2)
					Return False
				Case $LVN_BEGINLABELEDITW
					If Not $fDblClk Then
						$old_name = $bLVItems[$iSelected][7] & $bLVItems[$iSelected][0]
						$Changed = $iSelected
						$fDblClk = 1
						Return False
					EndIf
					Return True
				Case $LVN_ENDLABELEDITW
					Local $tInfo = DllStructCreate($tagNMLVDISPINFO, $LParam)
					Local $tBuffer = DllStructCreate("wchar Text[" & DllStructGetData($tInfo, "TextMax") & "]", _
							DllStructGetData($tInfo, "Text"))
					$pre_name = DllStructGetData($tBuffer, "Text")
					;$iSelected = -1
					GUICtrlSendToDummy($FileChange, 1)
					If StringLen($pre_name) Then Return True

;~ 		        Case $NM_CUSTOMDRAW    ;eat so much CPU!!

			EndSwitch
		Case $lWndListView
			Switch $code
;~ 				Case $LVN_COLUMNCLICK

				Case $NM_CLICK
;~ 					Local $tInfo = DllStructCreate($tagNMITEMACTIVATE, $LParam)
;~ 					Local $Index = DllStructGetData($tInfo, "Index")
;~ 					_GUICtrlListView_SetItemDropHilited($lWndListView, $Index, False)
					Return False
				Case $NM_RCLICK
					Dim $lyr_select = _GUICtrlListView_GetSelectedIndices($lWndListView, True)
					If UBound($lrc_Format, 0) < 1 Then Return $GUI_RUNDEFMSG
					If UBound($lrc_Format, 0) = 1 Then
						_GUICtrlMenu_SetItemDisabled($SubMenu2, 0)
						_GUICtrlMenu_SetItemDisabled($SubMenu2, 1)
						_GUICtrlMenu_SetItemDisabled($SubMenu2, 2)
						_GUICtrlMenu_SetItemDisabled($SubMenu2, 3)
					ElseIf _GUICtrlMenu_GetItemDisabled($SubMenu, 0) Then
						_GUICtrlMenu_SetItemEnabled($SubMenu2, 0)
						_GUICtrlMenu_SetItemEnabled($SubMenu2, 1)
						_GUICtrlMenu_SetItemEnabled($SubMenu2, 2)
						_GUICtrlMenu_SetItemEnabled($SubMenu2, 3)
					EndIf
					Return _GUICtrlMenu_TrackPopupMenu($SubMenu2, $hGUI)
				Case $NM_DBLCLK
					Local $tInfo = DllStructCreate($tagNMITEMACTIVATE, $LParam)
					Local $lrc_index = DllStructGetData($tInfo, "Index")
					If $n = 0 And $time_pos <> 0 Then
						GUICtrlSetColor(_GUICtrlListView_GetItemParam($Lrc_List, 0), $lrc_text_front_color)
						If UBound($lrc_Format) > 1 Then
							If $time_pos > $lrc_Format[1][0] Then
								$lrc_Format[0][0] = $lrc_Format[1][0]
							Else
								$lrc_Format[0][0] = $time_pos
							EndIf
						EndIf
					ElseIf $n >= 1 Then
						If $n - 1 <> $lrc_index Then GUICtrlSetColor(_GUICtrlListView_GetItemParam($Lrc_List, $n - 1), $lrc_text_back_color)
						GUICtrlSetColor(_GUICtrlListView_GetItemParam($Lrc_List, $lrc_index), $lrc_text_front_color)
						Local $lrc_deta = $time_pos - $lrc_Format[$lrc_index][0]
						For $i = 0 To UBound($lrc_Format) - 1
							$lrc_Format[$i][0] += $lrc_deta
							$lrc_Show[$i][0] += $lrc_deta
							If $lrc_Format[$i][0] < 0 Then
								$lrc_Format[$i][0] = 0
								$lrc_Show[$i][0] = 0
							EndIf
						Next
					EndIf
					; No return value
				Case $LVN_ENDLABELEDITW
					Local $tInfo = DllStructCreate($tagNMLVDISPINFO, $LParam)
					$Index = DllStructGetData($tInfo, "Item")
					Local $tBuffer = DllStructCreate("wchar Text[" & DllStructGetData($tInfo, "TextMax") & "]", _
							DllStructGetData($tInfo, "Text"))
					Local $sNewText = DllStructGetData($tBuffer, "Text")
;~ 					GUICtrlSendToDummy($FileChange, 3)
					If $sNewText Then
						If UBound($lrc_Format, 0) = 2 Then
							$lrc_Format[$Index][1] = $sNewText
							If IsArray($lrc_Show) Then $lrc_Show[$Index][1] = $sNewText
							$lyr_changed = True
							Return True
						ElseIf UBound($lrc_Format, 0) = 1 Then
							$lrc_Format[$Index][1] = $sNewText
							Return True
						EndIf
					EndIf
			EndSwitch
		Case $IWndListView
			Switch $code
				Case $LVN_COLUMNCLICK
					$tInfo = DllStructCreate($tagNMLISTVIEW, $LParam)
					GUICtrlSendToDummy($ID3_btn, Number(DllStructGetData($tInfo, "SubItem")))
				Case $LVN_BEGINLABELEDITW
					$tInfo = DllStructCreate($tagNMLVDISPINFO, $LParam)
					If DllStructGetData($tInfo, "Item") = 15 Then
						GUICtrlSendToDummy($FileChange, 3)
						Return True
					Else
						Return False
					EndIf
				Case $LVN_ENDLABELEDITW
					$tInfo = DllStructCreate($tagNMLVDISPINFO, $LParam)
					Local $tBuffer = DllStructCreate("wchar Text[" & DllStructGetData($tInfo, "TextMax") & "]", _
							DllStructGetData($tInfo, "Text"))
					If StringLen(DllStructGetData($tBuffer, "Text")) Then Return True

			EndSwitch
	EndSwitch
	Return $GUI_RUNDEFMSG
EndFunc   ;==>_WM_NOTIFY

Func MY_WM_HSCROLL($hWnd, $msg, $WParam, $LParam)
	Local $slide, $s_show, $time_pos
	Local $nScrollCode, $nPos, $hwndScrollBar, $hwnd_slider
	$nScrollCode = BitAND($WParam, 0x0000FFFF)
	$nPos = BitShift($WParam, 16)
	$hwndScrollBar = $LParam
	$hwnd_slider = GUICtrlGetHandle($slider)
;~ 	$hwnd_slider2 = GUICtrlGetHandle($Slider2)
	Switch $hwndScrollBar
		Case $hwnd_slider
			Switch $nScrollCode;,GUICtrlGetHandle($Slider1)
				Case $TB_LINEDOWN, $TB_PAGEDOWN, $TB_THUMBTRACK, $TB_PAGEUP, $TB_LINEUP
					If _BASS_ChannelIsActive($MusicHandle) = 0 Then GUICtrlSetData($slider, 0)
					_Timer_KillAllTimers($hGUI)
					$move_timer = -1
					$slide = GUICtrlRead($slider)
					$setpos = Int($slide / 100 * $length)
					$time_pos = Round(_BASS_ChannelBytes2Seconds($MusicHandle, $setpos) * 1000, 0)
					_TicksToTime($time_pos, $s_show)
					ToolTip(@CRLF & @CRLF & $s_show)

				Case $TB_THUMBPOSITION, $TB_ENDTRACK
					$move_timer = _Timer_SetTimer($hGUI, 50, 'move_list', $move_timer)
					_BASS_ChannelSetPosition($MusicHandle, $setpos, $BASS_POS_BYTE)
					ToolTip('')
					GUICtrlSetState($title, $GUI_FOCUS)
			EndSwitch
	EndSwitch
	Return $GUI_RUNDEFMSG
EndFunc   ;==>MY_WM_HSCROLL

;~ Func WM_SIZE($hWnd, $iMsg, $iwParam, $ilParam)
;~ 	_GUICtrlStatusBar_Resize($StatusBar)
;~ 	Return $GUI_RUNDEFMSG
;~ EndFunc   ;==>WM_SIZE

;~ Func MY_PAINT($hWnd)

;~   Return $GUI_RUNDEFMSG
;~ EndFunc

Func MY_WM_COMMAND($hWnd, $msg, $WParam, $LParam)
	Local $nNotifyCode = _HiWord($WParam)
	Local $nID = _LoWord($WParam)
	If Not IsHWnd($filter) Then $hWndFilter = GUICtrlGetHandle($filter)
	Switch $nID
		Case $idAdd, $idOpen, $idAbt, $idSet, $idSav, $idDat, $idLst
			Switch $nNotifyCode
				Case $BN_CLICKED
					GUICtrlSendToDummy($Tbar, $nID)
			EndSwitch
		Case $rn_item, $rm_item, $copy_item, $copy_qq_item, $edit_item, $reload_item, $id3_item, $del_id3_item, $copy_lyr_item, $load_cover, $shell_item
			GUICtrlSendToDummy($ListMenu, $nID)
		Case $tq, $tq1, $tq2, $yh, $yh1, $yh2, $sc, $cr, $hd
			GUICtrlSendToDummy($LyrMenu, $nID)
	EndSwitch
	Switch $LParam
		Case $hEdit
			Switch $nNotifyCode
				Case $EN_KILLFOCUS
					_GUICtrlEdit_Destroy($hEdit)
			EndSwitch
		Case $hWndFilter
			Switch $nNotifyCode
				Case $CBN_EDITCHANGE
					_FilterItem(GUICtrlRead($filter))
				Case $CBN_SELENDOK
					Local $hh
					_GUICtrlComboBox_GetLBText($hWndFilter, _GUICtrlComboBox_GetCurSel($hWndFilter), $hh)
					_FilterItem($hh)
			EndSwitch
	EndSwitch
	Return $GUI_RUNDEFMSG
EndFunc   ;==>MY_WM_COMMAND

Func On_WM_SYSCOMMAND($hWnd, $msg, $WParam, $LParam)
	Switch BitAND($WParam, 0xFFF0)
		Case $SC_SIZE ;$SC_MOVE,
			;Const $SPI_SETDRAGFULLWINDOWS = 37
			;Const $SPI_GETDRAGFULLWINDOWS = 38
			;Const SPIF_SENDWININICHANGE = 2
			Local $a = GUIGetCursorInfo($hGUI)
			If $a[1] < 0 Then
				GUICtrlSetResizing($hListView, 102)
				GUICtrlSetResizing($Lrc_List, 582)
				GUICtrlSetResizing($l_btn_header, 582)
			Else
				If $onlylist = 2 Then
					GUICtrlSetResizing($hListView, 102)
				Else
					GUICtrlSetResizing($hListView, 550)
				EndIf
				GUICtrlSetResizing($Lrc_List, 102)
				GUICtrlSetResizing($l_btn_header, 550)
			EndIf
			$tBool = DllStructCreate("int")
			DllCall("user32.dll", "int", "SystemParametersInfo", "int", 38, "int", 0, "ptr", DllStructGetPtr($tBool), "int", 0)
			$OldParam = DllStructGetData($tBool, 1)
			DllCall("user32.dll", "int", "SystemParametersInfo", "int", 37, "int", 0, "ptr", 0, "int", 2)
		Case $SC_MOVE
			$OldParam = -2
	EndSwitch
	Return $GUI_RUNDEFMSG
EndFunc   ;==>On_WM_SYSCOMMAND

Func WM_EXITSIZEMOVE($hWnd, $msg, $WParam, $LParam)
	If $hWnd <> $hGUI Then Return
	Local $high_temp = WinGetPos($hGUI)
	Switch $OldParam
		Case 0, 1
			_GUICtrlStatusBar_Resize($StatusBar)
			DllCall("user32.dll", "int", "SystemParametersInfo", "int", 37, "int", $OldParam, "ptr", 0, "int", 2)
			$OldParam = -1
			_GUICtrlListView_SetColumnWidth($Lrc_List, 0, $LVSCW_AUTOSIZE_USEHEADER)
			$StatusBar_PartsWidth[2] = $high_temp[2] - 263
			$StatusBar_PartsWidth[3] = $high_temp[2] - 45
			_GUICtrlStatusBar_SetParts($StatusBar, $StatusBar_PartsWidth)
		Case -2
			$OldParam = -1
	EndSwitch
	_GUICtrlStatusBar_EmbedControl($StatusBar, 3, GUICtrlGetHandle($L_process))
;~ 	ToolTip('')
	Return $GUI_RUNDEFMSG
EndFunc   ;==>WM_EXITSIZEMOVE

;~ Func WM_GETMINMAXINFO($hWnd, $msg, $WParam, $LParam)
;~ 	Local $minmaxinfo
;~ 	$minmaxinfo = DllStructCreate("int;int;int;int;int;int;int;int;int;int", $LParam)
;~ 	DllStructSetData($minmaxinfo, 7, 532) ; min X
;~ 	DllStructSetData($minmaxinfo, 8, 418) ; min Y
;~ 	DllStructSetData($minmaxinfo, 9, 795) ; max X
;~ 	DllStructSetData($minmaxinfo, 10, 600) ; max Y
;~ 	Return 0
;~ EndFunc   ;==>WM_GETMINMAXINFO

Func WM_MOUSEWHEEL($hWnd, $iMsg, $WParam, $LParam)
	#forceref $hWnd, $iMsg, $wParam, $lParam
	Local $iLen = _WinAPI_HiWord($WParam) / $WHEEL_DELTA
	Local $iKeys = _WinAPI_LoWord($WParam)
	Local $iX = _WinAPI_LoWord($LParam)
	Local $iY = _WinAPI_HiWord($LParam)
	If BitAND($iKeys, $MK_RBUTTON) = $MK_RBUTTON Then

	Else
		If _BASS_ChannelIsActive($MusicHandle) = 1 Then
			$vol += $iLen / 10
			If $vol > 1 Or $vol < 0 Then $vol = 1
			_BASS_ChannelSetAttribute($MusicHandle, $BASS_ATTRIB_VOL, $vol)
			ToolTip('音量: ' & Int($vol * 10))
		EndIf
	EndIf
	Return 0 ; If you return zero, then the message will not be sent to any more windows.
EndFunc   ;==>WM_MOUSEWHEEL

Func MY_GETDRAGIMAGE($hWnd, $msg, $WParam, $LParam)
	Local $SHDRAGIMAGE = DllStructCreate($tagSHDRAGIMAGE, $LParam)
;~ 	Local $deskDC = _WinAPI_GetDC(_WinAPI_GetDesktopWindow())
;~ 	Local $hBMP = _WinAPI_CreateCompatibleBitmap($deskDC,96,96)
;~ 	_WinAPI_ReleaseDC(_WinAPI_GetDesktopWindow(),$deskDC)
	Local $hBMP = _WinAPI_LoadImage(0, "C:\Windows\Feder.bmp", 0, 0, 0, $LR_LOADFROMFILE)
	DllStructSetData($SHDRAGIMAGE, "hbmpDragImage", $hBMP)
	DllStructSetData($SHDRAGIMAGE, "sizeDragImage", 128, 1)
	DllStructSetData($SHDRAGIMAGE, "sizeDragImage", 128, 2)
	DllStructSetData($SHDRAGIMAGE, "ptOffset", 45, 1)
	DllStructSetData($SHDRAGIMAGE, "ptOffset", 69, 2)
	DllStructSetData($SHDRAGIMAGE, "crColorKey", 0x00FF00FF)

	Return True
EndFunc   ;==>MY_GETDRAGIMAGE

Func ClientToScreen($hWnd, ByRef $x, ByRef $y)
	Local $stPoint = DllStructCreate("int;int")

	DllStructSetData($stPoint, 1, $x)
	DllStructSetData($stPoint, 2, $y)

	DllCall("user32.dll", "int", "ClientToScreen", "hwnd", $hWnd, "ptr", DllStructGetPtr($stPoint))

	$x = DllStructGetData($stPoint, 1)
	$y = DllStructGetData($stPoint, 2)
	; release Struct not really needed as it is a local
	$stPoint = 0
EndFunc   ;==>ClientToScreen

Func _GetToolbarButtonScreenPos($hWnd, $hTbar, $iCmdID, $iOffset = 0, $iIndex = 0, $hRbar = -1)
	; Author: rover 04/08/2008
	; this UDF integrates _WinAPI_ClientToScreen() from WinAPI.au3 include
	; _GUICtrlMenu_TrackPopupMenu() uses screen coordinates to place dropdown menu
	; need to convert button client coordinates to screen coordinates
	; $hRbar and $iIndex is for optional Rebar hwnd and band index
	; $iOffset sets menu Y position below button
	; Update: 06/27/2009 added offset for menu position below button, corrected left off-screen menu positioning.
	Local $aBorders, $aBandRect, $aRect, $tpoint, $pPoint, $aRet[2]

	Local $aRect = _GUICtrlToolbar_GetButtonRect($hTbar, $iCmdID); 'Options' button with dropdown menu
	If Not IsArray($aRect) Then Return SetError(@error, 0, "")

	$tpoint = DllStructCreate("int X;int Y")
	DllStructSetData($tpoint, "X", $aRect[0])
	DllStructSetData($tpoint, "Y", $aRect[3])
	$pPoint = DllStructGetPtr($tpoint)

	DllCall("User32.dll", "int", "ClientToScreen", "hwnd", $hWnd, "ptr", $pPoint)
	If @error Then Return SetError(@error, 0, "")

	; X screen coordinate of dropdown button left corner
	$aRet[0] = DllStructGetData($tpoint, "X")
	; limit X coordinate to 0 if button partially off-screen
	If $aRet[0] < 0 Then $aRet[0] = 0
	; Y screen coordinate of dropdown button left corner
	$aRet[1] = DllStructGetData($tpoint, "Y") + Number($iOffset)

	If $hRbar <> -1 And IsHWnd($hRbar) And IsNumber($iIndex) Then
		$aBorders = _GUICtrlRebar_GetBandBorders($hRbar, $iIndex)
		If Not IsArray($aBorders) Then Return SetError(@error, 0, "")
		$aBandRect = _GUICtrlRebar_GetBandRect($hRbar, $iIndex)
		If Not IsArray($aBandRect) Then Return SetError(@error, 0, "")
		; X screen coordinate of dropdown button left corner
		; subtract 2 pixel border of bounding rectangle for band in rebar control
		If $aRet[0] <> 0 Then $aRet[0] += ($aBorders[0] - $aBandRect[0])
	EndIf

	Return $aRet; return X,Y screen coordinates of toolbar dropdown button lower left corner
EndFunc   ;==>_GetToolbarButtonScreenPos

Func RGB2BGR($iColor)
	Return BitAND(BitShift(String(Binary($iColor)), 8), 0xFFFFFF)
EndFunc   ;==>RGB2BGR

Func _WindowGetHovered()
	Local $h_Struct = DllStructCreate($tagPoint)
	DllStructSetData($h_Struct, "x", MouseGetPos(0))
	DllStructSetData($h_Struct, "y", MouseGetPos(1))
	Local $h_wnd = _WinAPI_WindowFromPoint($h_Struct)
	Local $rer = _WinAPI_GetParent($h_wnd)
	Return $rer
EndFunc   ;==>_WindowGetHovered

Func _WinAPI_ShellExtractIcons($Icon, $Index, $Width, $Height)
	Local $Ret = DllCall('shell32.dll', 'int', 'SHExtractIconsW', 'wstr', $Icon, 'int', $Index, 'int', $Width, 'int', $Height, 'ptr*', 0, 'ptr*', 0, 'int', 1, 'int', 0)
	If @error Or $Ret[0] = 0 Or $Ret[5] = Ptr(0) Then Return SetError(1, 0, 0)
	Return $Ret[5]
EndFunc   ;==>_WinAPI_ShellExtractIcons

Func WM_DROPFILES($hWnd, $uMsg, $WParam, $LParam)
	Local $tDrop, $aRet, $iCount, $iSize, $chg = False
	$aRet = DllCall("shell32.dll", "int", "DragQueryFileW", "ptr", $WParam, "uint", 0xFFFFFFFF, "ptr", 0, "uint", 0)
	$iCount = $aRet[0]

	For $i = 0 To $iCount - 1
		$iSize = DllCall("shell32.dll", "uint", "DragQueryFileW", "ptr", $WParam, "uint", $i, "ptr", 0, "uint", 0)
		$tDrop = DllStructCreate("wchar[" & $iSize[0] + 1 & "]")
		$aRet = DllCall("shell32.dll", "uint", "DragQueryFileW", "ptr", $WParam, "uint", $i, "ptr", DllStructGetPtr($tDrop), "uint", $iSize[0] + 1)
		Local $IsFile = StringRegExp(DllStructGetData($tDrop, 1), '\.(\w+)$', 3, 1)
		If Not IsArray($IsFile) Then
			$drop_DIR = True
			$root_folder = DllStructGetData($tDrop, 1)
			GUICtrlSendToDummy($Tbar, $idAdd)
			ExitLoop
		ElseIf $IsFile[0] = 'lrc' And $iCount = 1 Then
			$lrc_text = FileRead(DllStructGetData($tDrop, 1))
			$lrc_Format = _lrc_Prase($lrc_text)
			If UBound($lrc_Format, 0) = 2 Then
				Update_L()
			EndIf
			ExitLoop
		ElseIf $IsFile[0] = 'krc' And $iCount = 1 Then
			Local $res = '', $time_stamp, $krc, $src
			$krc = FileOpen(DllStructGetData($tDrop, 1), 16)
			FileRead($krc, 4)
			$src = FileRead($krc)
			If Not IsDeclared('krcXOR') Then Global $krcXOR[16] = [64, 71, 97, 119, 94, 50, 116, 71, 81, 54, 49, 45, 206, 210, 110, 105]
			Local $bin = BinaryLen($src)
			For $i = 0 To BinaryLen($src) - 1
				Local $m = Mod($i, 16)
				$res &= Hex(BitXOR(BinaryMid($src, $i + 1, 1), $krcXOR[$m]), 2)
			Next
			Local $Decompressed = _ZLIB_Uncompress(Binary('0x' & $res))
			$lrc_text = BinaryToString($Decompressed, 4)
			$lrc_text = StringRegExpReplace($lrc_text, '<[^\>]*>', '')
			$lrc_text = StringRegExpReplace($lrc_text, '(\[\d+).*?(\])', '\1\2')
			$time_stamp = StringRegExp($lrc_text, '\[(\d+)\]', 3, 1)
			If Not @error Then
				For $i = 0 To UBound($time_stamp) - 1
					$lrc_text = StringReplace($lrc_text, $time_stamp[$i], _TickToTime($time_stamp[$i]), 1)
				Next
			EndIf
			$lrc_Format = _lrc_Prase($lrc_text)
			If UBound($lrc_Format, 0) = 2 Then
				Update_L()
			EndIf
			ExitLoop
		ElseIf StringInStr('jpg|png', $IsFile[0]) And $iCount = 1 Then
			$cover_put = DllStructGetData($tDrop, 1)
			_loadpic()
			ExitLoop
		ElseIf StringInStr('mp3|wma|ape|flac|m4a|wav|aac|ogg', $IsFile[0]) Then
			Local $rfolder = StringRegExpReplace(DllStructGetData($tDrop, 1), '\\[^\\]+$', '')
			If Not (StringInStr($rfolder, $root_folder, 1) And $root_folder) Then
				$Data_Count = 0
				$root_folder = $rfolder
				_SearchFile($root_folder, DllStructGetData($tDrop, 1))
				_GUICtrlListView_DeleteAllItems(GUICtrlGetHandle($hListView))
				__GUICtrlListView_AddArray($hListView, $bLVItems)
				$temp_stat = "共有" & $Data_Count & "首歌曲！"
				_GUICtrlStatusBar_SetText($StatusBar, $temp_stat, 1)
				Dim $aLVItems[2] = [1, _GUICtrlListView_GetItemTextString($hListView, 0)]
				$iSelected = -1
			Else
				$sel_index = _ArraySearch($aLVItems, StringRegExpReplace(DllStructGetData($tDrop, 1), '^.*\\', ''), 1, 0, 0, 1)
				If $sel_index <> -1 Then
					_ToolTip('提示', DllStructGetData($tDrop, 1) & ' 已经存在于列表中', 3, 1)
					ContinueLoop
				EndIf
				Local $temp_count = $Data_Count
				_SearchFile($root_folder, DllStructGetData($tDrop, 1))
				If $temp_count <> $Data_Count Then
					Local $new_count = $aLVItems[0] + 1
					ReDim $aLVItems[$new_count + 1]
					$aLVItems[$new_count] = ''
					$aLVItems[0] = $new_count
					$aLVItems[$new_count] = StringFormat('%s|%s|%s|%s|%s|%s|%s|%s', $bLVItems[$Data_Count - 1][0], _
							$bLVItems[$Data_Count - 1][1], $bLVItems[$Data_Count - 1][2], $bLVItems[$Data_Count - 1][3], _
							$bLVItems[$Data_Count - 1][4], $bLVItems[$Data_Count - 1][5], $bLVItems[$Data_Count - 1][6], $bLVItems[$Data_Count - 1][7])
					Dim $appendIt[1][8]
					For $k = 0 To 7
						$appendIt[0][$k] = $bLVItems[$Data_Count - 1][$k]
						$aLVItems[$new_count] &= $bLVItems[$Data_Count - 1][$k] & "|"
					Next
					$aLVItems[$new_count] = StringTrimRight($aLVItems[$new_count], 1)
					__GUICtrlListView_AddArray($hListView, $appendIt)
					$temp_stat = "共有" & $Data_Count & "首歌曲！"
					_GUICtrlStatusBar_SetText($StatusBar, $temp_stat, 1)

				EndIf
			EndIf
		Else
			ContinueLoop
		EndIf
	Next
	DllCall("shell32.dll", "int", "DragFinish", "ptr", $WParam)
	Return
EndFunc   ;==>WM_DROPFILES
