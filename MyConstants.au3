#Include <GDIPlus.au3>
#Include <array.au3>
#include "ID3.au3"
#include <WinAPIEx.au3>
#include <APIConstants.au3>
#include <editconstants.au3>
#include <StaticConstants.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <ButtonConstants.au3>
#include <ComboConstants.au3>
#include <EditConstants.au3>
#include <FontConstants.au3>
#include <ListViewConstants.au3>
#include <GuiListView.au3>
#include <GuiImageList.au3>
#include <GUIEdit.au3>
#include <GuiStatusBar.au3>
#include <GuiToolbar.au3>
#include <GuiToolTip.au3>
#include <GuiStatusBar.au3>
#include <GUIComboBox.au3>
#include <GuiButton.au3>
#include <GuiMenu.au3>
#include <Timers.au3>
#include "BassConstants.au3"
#include "Bass.au3"
#include "ShellContextMenu.au3"

Global $hGUI, $hReBar, $hToolbar, $Tbar, $TbarMenu, $LyrMenu, $ListMenu, $SubMenu, $SubMenu2, $Lrc_Choose, $Setting, $hGIF, $dGUI, $ID3_lst, $ID3_dial, $ID3_btn, $hIcons[19]
Global Enum $idAdd = 1000, $idOpen, $idAbt, $idSet, $idSav, $idDat, $idLst
Global $iItem, $iSelected = -1, $old_name, $pre_name='', $lyr_select[1] = [0], $fDblClk = 0, $Changed = -1, $_Free = 0, $show_lyric = True, $drop_DIR = False, $shell_item=True
Global Enum $qqjt = 2000, $kwyy, $mngc, $bdyy, $ilrc, $qqyy, $tq, $tq1, $tq2, $yh, $yh1, $yh2, $sc, $cr,$hd,$save_as_lrc,$save_as_srt
Global Enum $copy_item = 3000, $rn_item, $copy_qq_item, $rm_item, $edit_item, $reload_item, $id3_item, $del_id3_item, $copy_lyr_item, $load_cover
Global $hToolBar_image[7], $hToolBar_strings[7], $Fonts[6], $Top_set, $layOut1, $layOut2, $layOut0, $Fade_set, $FadeOut=25, $Slider1,$cnc, $Ping
Global $StatusBar, $StatusBar_PartsWidth[5] = [24, 190, 533, 750, -1], $NetState[6], $L_process, $OldParam=-1
Global $Sound_Play, $Sound_Stop, $Sound_Flag, $s_flag=False, $MusicHandle, $Data_Count=0, $mode = -1
Global $IWndListView, $hWndListView, $lWndListView, $hListView, $Lrc_List, $hHeader, $l_btn_header, $tab_Save, $Save_Checkbox, $Save_Auto, $Reg_Checkbox, $Lrc_Checkbox, $SubSel_Deep, _
$Copy_Checkbox, $Search_Button, $ProxyCheck, $ProxyIP, $port_input, $cover, $save_cover, $shell_bt, $align_check, $download_cover, $filter,$bar,$reg_order=1,$old_keyword=''
Global $sub_list, $sub_OK, $Label5, $Button1, $Button2, $n=0, $move_timer=-1, $col_def
Global $col_1, $col_2, $col_3, $col_4, $col_5, $col_6
Global $setpos, $time_pos=0, $length, $vol=1, $lrc_text, $lrc_Format, $lrc_Show, $lyr_changed = False, $root_folder, $cover_Dir, $load_flag = 1, $load_Pro, _
		$pre_get[1] = [-1], $aLVItems[1] = [0], $bLVItems[2][1] = [[0],[0]], $toolbar_subitem[2]=[0,0], $l_head, $file_list,$deep
Global $font_name = "Arial", $font_var = 0, $font_size = 16, $font_xing = 400, $font_color = 0xFF0000, $list_bk_color,$lrc_text_back_color=0xFFFFFF, $lrc_text_front_color=0xEE0000
Global $list_name, $list_var, $list_size, $list_xing
Global $lGUI,$h[4],$head_OK,$sTab
Global $play_control, $tray_play, $tray_stop
Global $ct, $cnc, $big, $small
Global Const $TBDDRET_DEFAULT = 0
Global Const $TBDDRET_NODEFAULT = 1
Global Const $TBDDRET_TREATPRESSED = 2
Global Const $TB_LINEUP = 0
Global Const $TB_LINEDOWN = 1
Global Const $TB_PAGEUP = 2
Global Const $TB_PAGEDOWN = 3
Global Const $TB_THUMBPOSITION = 4
Global Const $TB_THUMBTRACK = 5
Global Const $TB_ENDTRACK = 8
Global Const $TBS_NOTICKS = 0x0010
Global Const $PBS_MARQUEE = 0x00000008
;~ Global Const $WM_EXITSIZEMOVE = 0x232
Global Const $WHEEL_DELTA = 120
Global Const $MK_LBUTTON = 0x1
Global Const $MK_RBUTTON = 0x2
Global Const $MK_SHIFT = 0x4
Global Const $MK_CONTROL = 0x8
Global Const $MK_MBUTTON = 0x10
Global Const $MK_XBUTTON1 = 0x20
Global Const $MK_XBUTTON2 = 0x40
Global Const $L[6] = ['简短说明', '这里显示同步歌词', '双击定位时间戳', '点击两次修改内容', '接受jpg/lrc/krc/mp3/wma/ogg/wav/acc/m4a/flac/ape文件', 'enjoy yourself!']
Global Const $key[27]=['吖','八','擦','耷','俄','发','噶','哈','丌','丌','卡','拉','马','拿','哦','趴','七','然','撒','他','挖','挖','挖','西','丫','匝','匝']
Global Const $ID3_v2_kword[8]=['标题','艺术家','专辑','流派','轨道','年份','备注','长度']
Global Const $ID3_v2_kword_Ex[11]=['异步歌词','商业性息链接','空位填充','自定义链接','编码器','艺术家(表演者)链接','唯一编号', _
                                  '作曲家','乐队/乐团/伴奏','发布人','封面']
Global Const $LBS_NOSEL = 0x00004000
Global Const $PBM_SETMARQUEE = 0X400 + 10
;~ Global Const $IMAGE_BITMAP = 0
Global Const $STM_SETIMAGE = 0x0172
Global $about = '此工具仅供学习使用，请勿作商业用途' & _
		@LF & '杀毒软件可能会报毒，请自行斟酌' & @LF & 'bug较多，重要文件请备份或慎用' & @LF & '进度条滚动时请尽量减少操作' & @LF & _
		'有更多建议请联系zhengjuefei25@gmail.com'
Global Const $_tagCHOOSEFONT = "dword Size;hwnd hWndOwner;handle hDC;ptr LogFont;int PointSize;dword Flags;dword rgbColors;lparam CustData;" & _
		"ptr fnHook;ptr TemplateName;handle hInstance;ptr szStyle;word FontType;int nSizeMin;int nSizeMax"

;~ ====================================
Global $AlbumArtFile, $LyricsFile, $tr,  _
	   $current_time, $current_song, $coverStartIndex=0, $douban2, $cover_key_input, $slider
Global $Proc, $hLabel, $loading_count = 0
Global $sFile = @ScriptDir & '\ICON\test.png'
Global $iW, $iH, $hBmp
Global $ti,$ar,$al,$by
Global $d_trans
Global $FileDir, $temp_stat="欢迎使用！", $prop_item, $hEdit
;~ ====================================
Global $begin, $lastClick=0, $Stop_l=False
;~ ====================================
Global Const $list_baidu="/x?op=12&count=1&title=%s$$%s$$$$"
Global Const $list_qq='/fcgi-bin/qm_getLyricId.fcg?name=%s&singer=%s&from=qqplayer'
Global $oMyError = ObjEvent("AutoIt.Error","MyErrFunc")

Switch @OSLang
	Case "0804", "0404", "", "0c04", "1004", "1404" ;Chinese
		Switch @OSVersion
			Case 'WIN_XP'
				$sTab = '摘要'
			Case Else
				$sTab = '详细信息'
		EndSwitch
	Case "1009", "0409", "0809", "0c09", "1409", "1809", "1c09", "2009", "2409", "2809", "2c09", "3009", "3409" ; English
		$sTab = "Details"
;~     Case Else
EndSwitch
_GDIPlus_Startup()

Global $font_name=IniRead(@ScriptDir&'\config.ini', "lyrics", "font_name", "Arial")
Global $font_var=Number(IniRead(@ScriptDir&'\config.ini', "lyrics", "font_var", "0"))
Global $font_size=Number(IniRead(@ScriptDir&'\config.ini', "lyrics", "font_size", "16"))
Global $font_xing=Number(IniRead(@ScriptDir&'\config.ini', "lyrics", "font_xing", "400"))
Global $font_color=IniRead(@ScriptDir&'\config.ini', "lyrics", "font_color", "0xFFFFFF")
Global $list_name=IniRead(@ScriptDir&'\config.ini', "lyrics", "list_name", "Arial")
Global $list_var=Number(IniRead(@ScriptDir&'\config.ini', "lyrics", "list_var", "0"))
Global $list_size=Number(IniRead(@ScriptDir&'\config.ini', "lyrics", "list_size", "9"))
Global $list_xing=Number(IniRead(@ScriptDir&'\config.ini', "lyrics", "list_xing", "400"))
Global $list_bk_color=IniRead(@ScriptDir&'\config.ini', "lyrics", "list_bk_color", "0x324469")
Global $lrc_text_back_color=IniRead(@ScriptDir&'\config.ini', "lyrics", "lrc_text_back_color", "0xFFFFFF")
Global $lrc_text_front_color=IniRead(@ScriptDir&'\config.ini', "lyrics", "lrc_text_front_color", "0xEE0000")
Global $d_trans=Number(IniRead(@ScriptDir&'\config.ini', "lyrics", "transparency", "255"))
Global $onlylist=Number(IniRead(@ScriptDir&'\config.ini', "lyrics", "onlylist", "0"))
Global $desk_top=Number(IniRead(@ScriptDir&'\config.ini', "lyrics", "desk_top", "1"))
Global $list_align=Number(IniRead(@ScriptDir&'\config.ini', "lyrics", "align", "2"))
If Number(IniRead(@ScriptDir&'\config.ini', "lyrics", "desk_fade", "1")) Then
	$FadeOut = 25
Else
	$FadeOut = $d_trans
EndIf
Global $isCnc=Number(IniRead(@ScriptDir&'\config.ini', "server", "cnc", "0"))
Global $isBig=Number(IniRead(@ScriptDir&'\config.ini', "server", "cover_size", "1"))
Global $save_only_txt=Number(IniRead(@ScriptDir&'\config.ini', "others", "save_only_txt", "0"))
Global $save_always_ask=Number(IniRead(@ScriptDir&'\config.ini', "others", "save_always_ask", "0"))
Global $copy_with_lrc=Number(IniRead(@ScriptDir&'\config.ini', "others", "copy_with_lrc", "1"))
Global $force_ti_format=Number(IniRead(@ScriptDir&'\config.ini', "others", "force_ti_format", "0"))
Global $dir_depth=Number(IniRead(@ScriptDir&'\config.ini', "others", "dir_depth", "1"))
Global $only_file_without_lrc=Number(IniRead(@ScriptDir&'\config.ini', "others", "only_file_without_lrc", "0"))
Global $root_folder=IniRead(@ScriptDir&'\config.ini', "others", "work_dir", "")
Global $GUI_color=Number(IniRead(@ScriptDir&'\config.ini', "others", "color", "1"))

Global $__RegAsmPath


Func MyErrFunc()
	If Not $hGUI Then Return
	TrayTip("COM ERROR !!", "" & @CRLF & @CRLF & _
			"err.description is: " & @TAB & $oMyError.description & @CRLF & _
			"err.windescription:" & @TAB & $oMyError.windescription & @CRLF & _
			"err.number is: " & @TAB & Hex($oMyError.number, 8) & @CRLF & _
			"err.lastdllerror is: " & @TAB & $oMyError.lastdllerror & @CRLF & _
			"err.scriptline is: " & @TAB & $oMyError.scriptline & @CRLF & _
			"err.source is: " & @TAB & $oMyError.source & @CRLF & _
			"err.helpfile is: " & @TAB & $oMyError.helpfile & @CRLF & _
			"err.helpcontext is: " & @TAB & $oMyError.helpcontext, 3, 3 _
			)
	Local $err = $oMyError.number
	If $err = 0 Then $err = -1
	$g_eventerror = $err
EndFunc   ;==>MyErrFunc

Func _ReduceMemory($i_PID = -1)
	If $i_PID <> -1 Then
		Local $ai_Handle = DllCall("kernel32.dll", 'int', 'OpenProcess', 'int', 0x1f0fff, 'int', False, 'int', $i_PID)
		Local $ai_Return = DllCall("psapi.dll", 'int', 'EmptyWorkingSet', 'long', $ai_Handle[0])
		DllCall('kernel32.dll', 'int', 'CloseHandle', 'int', $ai_Handle[0])
	Else
		Local $ai_Return = DllCall("psapi.dll", 'int', 'EmptyWorkingSet', 'long', -1)
	EndIf

	Return $ai_Return[0]
EndFunc   ;==>_ReduceMemory
