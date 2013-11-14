;~ Opt("GUIOnEventMode", 1)

;~ _GDIPlus_Startup()
$hImage1 = _GDIPlus_ImageLoadFromFile($sFile)
$iW = _GDIPlus_ImageGetWidth($hImage1)
$iH = _GDIPlus_ImageGetHeight($hImage1)
$dGUI = GUICreate("", $iW/2, $iH, -1, -1, $WS_POPUP, BitOr($WS_EX_LAYERED, $WS_EX_TOPMOST, $WS_EX_TOOLWINDOW))
GUIRegisterMsg($WM_NCHITTEST, "WM_NCHITTEST")
WinSetOnTop($dGUI, "", _Iif($desk_top, 1, 0))
GUISetState(@SW_HIDE, $dGUI)
$hBmp = _ImageDrawText($hImage1, "Desk Lyrics", 230, 18, $font_color,16)
SetBitmap($dGUI, $hBmp, 0)
_WinAPI_DeleteObject($hBmp)

Func _ID3_GUI()
    $ID3_dial = GUICreate("编辑ID3", 320, 408, 466, 121, -1, 0x180, $hGUI)
    GUISetOnEvent($GUI_EVENT_CLOSE, 'ID3_Exit')
    $ID3_btn = GUICtrlCreateDummy()
    GUICtrlSetOnEvent(-1, 'ID3_Func')
    $ID3_lst=GUICtrlCreateListView('',8, 10, 304, 388, 0x5003020D, BitOR($LVS_EX_FULLROWSELECT, $LVS_EX_DOUBLEBUFFER,$WS_EX_CLIENTEDGE))
    GUICtrlSetColor(-1, 0x0080C0)
    GUICtrlSetBkColor(-1,$GUI_BKCOLOR_LV_ALTERNATE) ;设置列表背景颜色
	$IWndListView = GUICtrlGetHandle($ID3_lst)
    _GUICtrlListView_SetUnicodeFormat(-1, True)
    _GUICtrlListView_EnableGroupView($ID3_lst)
    _GUICtrlListView_InsertGroup($ID3_lst, -1, 1, "ID3V2/ACC")
    _GUICtrlListView_InsertGroup($ID3_lst, -1, 2, "ID3V1")
    _GUICtrlListView_InsertGroup($ID3_lst, -1, 3, "ID3V2 More")
;~ 	Local $Iimage = _GUIImageList_Create(16, 16, 5, 3)
;~ 	_GUIImageList_AddIcon($Iimage, "icon.dll", 13)
;~ 	_GUIImageList_AddIcon($Iimage, "icon.dll", 14)
;~ 	_GUICtrlListView_SetImageList($ID3_lst, $Iimage, 1)
    _GUICtrlListView_InsertColumn($ID3_lst, 0, "选择封面", 320, 0, 0)
    _GUICtrlListView_InsertColumn($ID3_lst, 1, "缓存数据", 50)
    _GUICtrlListView_InsertColumn($ID3_lst, 1, "写入标签", 50, 0, 1)
    _GUICtrlListView_SetColumnOrder($ID3_lst, "1|0|2")
    Local $item
    For $ii = 0 To 7
    $item = GUICtrlCreateListViewItem('|'&$ID3_v2_kword[$ii],$ID3_lst)
    _GUICtrlListView_SetItemGroupID($ID3_lst,$ii,1)
    GUICtrlSetBkColor ($item, 0xEEEEEE)
    Next
    For $ii = 0 To 6
    $item = GUICtrlCreateListViewItem('|'&$ID3_v2_kword[$ii],$ID3_lst)
    _GUICtrlListView_SetItemGroupID($ID3_lst,8+$ii,2)
    GUICtrlSetBkColor ($item, 0xEEEEEE)
    Next
    For $ii = 0 To 10
    $item = GUICtrlCreateListViewItem('|'&$ID3_v2_kword_Ex[$ii],$ID3_lst)
    _GUICtrlListView_SetItemGroupID($ID3_lst,15+$ii,3)
    GUICtrlSetBkColor ($item, 0xEEEEEE)
    Next
    ;~ GUISetState()
EndFunc

Func _Edit_ID3($Filename)
	$FileDir=$Filename
	_GUICtrlStatusBar_SetText($StatusBar , "Reading Tags...",1)
;~ 	_GDIPlus_BitmapDispose($cBitmap)   ;!!!
	WinSetTitle($ID3_dial, '', '编辑ID3 - '&StringRegExpReplace($Filename,'.*\\',''))

	_ID3ReadTag($Filename)

	_GUICtrlListView_SetItemText($ID3_lst,0,_ID3GetTagField("TIT2"))
	_GUICtrlListView_SetItemText($ID3_lst,1,_ID3GetTagField("TPE1"))
	_GUICtrlListView_SetItemText($ID3_lst,2,_ID3GetTagField("TALB"))
	_GUICtrlListView_SetItemText($ID3_lst,3,_ID3GetTagField("TCON"))
	_GUICtrlListView_SetItemText($ID3_lst,4,_ID3GetTagField("TRCK"))
	_GUICtrlListView_SetItemText($ID3_lst,5,_ID3GetTagField("TYER"))
	_GUICtrlListView_SetItemText($ID3_lst,6,_ID3GetTagField("COMM"))
;~
	_GUICtrlListView_SetItemText($ID3_lst,8,_ID3GetTagField("Title"))
	_GUICtrlListView_SetItemText($ID3_lst,9,_ID3GetTagField("Artist"))
	_GUICtrlListView_SetItemText($ID3_lst,10,_ID3GetTagField("Album"))
	_GUICtrlListView_SetItemText($ID3_lst,11,_ID3GetTagField("Genre"))
	_GUICtrlListView_SetItemText($ID3_lst,12,_ID3GetTagField("Track"))
	_GUICtrlListView_SetItemText($ID3_lst,13,_ID3GetTagField("Year"))
	_GUICtrlListView_SetItemText($ID3_lst,14,_ID3GetTagField("Comment"))
	;If Not($AlbumArtFile == $DefaultPicName) Then
		;If FileExists($AlbumArtFile) Then FileDelete($AlbumArtFile)
	;EndIf
    _GUICtrlListView_SetItemText($ID3_lst,7,_ID3GetTagField("TLEN"))
	_GUICtrlListView_SetItemText($ID3_lst,24,_ID3GetTagField("TPUB"))
	_GUICtrlListView_SetItemText($ID3_lst,16,_ID3GetTagField("WCOM"))
	_GUICtrlListView_SetItemText($ID3_lst,17,_ID3GetTagField("ZPAD"))
	_GUICtrlListView_SetItemText($ID3_lst,18,_ID3GetTagField("WXXX"))
	_GUICtrlListView_SetItemText($ID3_lst,19,_ID3GetTagField("TSSE"))
	_GUICtrlListView_SetItemText($ID3_lst,20,_ID3GetTagField("WOAR"))
	_GUICtrlListView_SetItemText($ID3_lst,21,_ID3GetTagField("UFID"))
	_GUICtrlListView_SetItemText($ID3_lst,22,_ID3GetTagField("TCOM"))
	_GUICtrlListView_SetItemText($ID3_lst,23,_ID3GetTagField("TPE2"))
    $LyricsFile = _ID3GetTagField("USLT")
	_GUICtrlListView_SetItemText($ID3_lst,15, FileRead($LyricsFile))
	$AlbumArtFile = _ID3GetTagField("APIC")
	If $AlbumArtFile Then
	    $cover_put = $AlbumArtFile
		_loadpic()
		_GUICtrlListView_SetItemText($ID3_lst,25, '有')
	Else
		_GUICtrlListView_SetItemText($ID3_lst,25, '无')
	EndIf
	_GUICtrlStatusBar_SetText($StatusBar , "Success Reading Tags!",1)
	GUISetState(@SW_SHOW,$ID3_dial)
EndFunc

Func _ID3_ResetAll()
    For $i = 0 To 24
	    _GUICtrlListView_SetItemText($ID3_lst,$i,'')
    Next
EndFunc

Func ID3_Func()
	Switch GUICtrlRead($ID3_btn)
		Case 2
			_ArrayDisplay($ID3BufferArray,"ID3v2 Tag Array",-1,0,";","")
		Case 1
			_GUICtrlStatusBar_SetText($StatusBar , "Writing Tags...",1)
			If StringRight(WinGetTitle($ID3_dial),3)=='mp3' Then
			    _ID3SetTagField("TIT2",_GUICtrlListView_GetItemText($ID3_lst,0))
			    _ID3SetTagField("TPE1",_GUICtrlListView_GetItemText($ID3_lst,1))
				_ID3SetTagField("TALB",_GUICtrlListView_GetItemText($ID3_lst,2))
				_ID3SetTagField("TCON",_GUICtrlListView_GetItemText($ID3_lst,3))
				_ID3SetTagField("TRCK",_GUICtrlListView_GetItemText($ID3_lst,4))
				_ID3SetTagField("TYER",_GUICtrlListView_GetItemText($ID3_lst,5))
			    _ID3SetTagField("COMM",_GUICtrlListView_GetItemText($ID3_lst,6))
				_ID3SetTagField("TLEN",_GUICtrlListView_GetItemText($ID3_lst,7))
			    ;_ID3SetTagField("WOAR",GUICtrlRead ($WOAR_input))
;~ 			    _ID3RemoveField("WOAR")
			    _ID3SetTagField("Title",_GUICtrlListView_GetItemText($ID3_lst,8))
			    _ID3SetTagField("Artist",_GUICtrlListView_GetItemText($ID3_lst,9))
			    _ID3SetTagField("Album",_GUICtrlListView_GetItemText($ID3_lst,10))
			    _ID3SetTagField("Genre",_GUICtrlListView_GetItemText($ID3_lst,11))
			    _ID3SetTagField("Track",_GUICtrlListView_GetItemText($ID3_lst,12))
			    _ID3SetTagField("Year",_GUICtrlListView_GetItemText($ID3_lst,13))
			    _ID3SetTagField("Comment",_GUICtrlListView_GetItemText($ID3_lst,14))
			    If $cover_put<>$AlbumArtFile Then _ID3SetTagField("APIC",$cover_put)
			    _ID3WriteTag($FileDir)    ;文件名
			Else
				Local $foo=Run(@ScriptDir & "\AACTagReader.exe", @ScriptDir, @SW_HIDE, $STDOUT_CHILD)
				StdinWrite($foo, StringToBinary(" -writetags "& StringMid(WinGetTitle($ID3_dial),13)&' '& _
				   StringFormat('name=%s artist=%s album=%s genre=%s track=%s composer=%s year=%s', _
				   _GUICtrlListView_GetItemText($ID3_lst,0),_GUICtrlListView_GetItemText($ID3_lst,1), _
				   _GUICtrlListView_GetItemText($ID3_lst,2),_GUICtrlListView_GetItemText($ID3_lst,3), _
				   _GUICtrlListView_GetItemText($ID3_lst,4),_GUICtrlListView_GetItemText($ID3_lst,22), _
				   _GUICtrlListView_GetItemText($ID3_lst,5)),4))
				StdinWrite($foo)
				If $cover_put<>@TempDir & '\cover.jpg' Then Run(@ScriptDir & "\AACTagReader.exe -writeimage "&$sel_dir&' '&$cover_put, @ScriptDir, @SW_HIDE, $STDOUT_CHILD)
			EndIf
				_ToolTip('Complete','写入成功！',3)
			_GUICtrlStatusBar_SetText($StatusBar , "Success Writing Tags!",1)
		Case 0
			$PIC_Filename = FileOpenDialog("Select JPG File", @ScriptDir, "图像 (*.jpg;*.png)", 1,'',$ID3_dial)
			IF Not @error Then
				$cover_put = $PIC_Filename
				_loadpic()
			EndIf
	EndSwitch
EndFunc
Func ID3_Exit()
;~ 	GUISwitch($hGUI)
	If StringInStr(_GUICtrlStatusBar_GetText($StatusBar ,1),'Reading Tags') Then _GUICtrlStatusBar_SetText($StatusBar , $temp_stat,1)
	$temp_stat = ''
	GUISetState(@SW_HIDE, $ID3_dial)
	_ID3_ResetAll()
EndFunc

Func _loadpic()
	Switch StringRight($cover_put,3)
		Case "png"
            Local $hImage = _GDIPlus_ImageLoadFromFile($cover_put)
            Local $hGraphic = _GDIPlus_GraphicsCreateFromHWND(GUICtrlGetHandle($cover))
            _GDIPLus_GraphicsDrawImageRect($hGraphic, $hImage, 0, 0, 182, 182)
		    _GDIPlus_GraphicsDispose($hGraphic)
            _GDIPlus_ImageDispose($hImage)
		Case Else
           GUICtrlSetImage($cover, $cover_put)
	EndSwitch
EndFunc
Func Show_desk()
   GUISetState(@SW_SHOW, $dGUI)
   For $i = 0 To $d_trans Step $FadeOut
    SetBitmap($dGUI, $hBmp, $i)
	$tr=$i
	Sleep(50)
   Next
   _WinAPI_DeleteObject($hBmp)
EndFunc

Func Hide_desk()
   For $i = $d_trans To 0 Step (-1)*$FadeOut
    SetBitmap($dGUI, $hBmp, $i)
	$tr=$i
	Sleep(50)
   Next
   _WinAPI_DeleteObject($hBmp)
   GUISetState(@SW_HIDE, $dGUI)
EndFunc

Func move_list($hWnd, $Msg, $iIDTimer, $dwTime)
;~ 	If Not _BASS_ChannelIsActive($MusicHandle) Then Return
	Local $tm_show
	Local $pos = _BASS_ChannelGetPosition($MusicHandle, $BASS_POS_BYTE)
	If @error Then Return GUICtrlSetData($slider, 0)
	$time_pos = Round(_BASS_ChannelBytes2Seconds($MusicHandle, $pos) * 1000, 0)
	_TicksToTime($time_pos, $tm_show)
	If GUICtrlRead($current_time)<>$tm_show Then
	    GUICtrlSetData($current_time, $tm_show)
		GUICtrlSetData($slider, Int($time_pos / Round(_BASS_ChannelBytes2Seconds($MusicHandle, $length) * 1000, 0) * 100))
	EndIf
	If ($pos>=$length And $length > 0) Or _BASS_ChannelIsActive($MusicHandle) = 0 Then
		_Stop()
		$hBmp = _ImageDrawText($hImage1, "Desk Lyrics", 230, 18, $font_color,16)
		SetBitmap($dGUI, $hBmp, 0)
		_WinAPI_DeleteObject($hBmp)
		If $s_flag Then
			If $iSelected<UBound($bLVItems)-1 Then
				$iSelected+=1
			Else
				$iSelected=0
			EndIf
			_GUICtrlListView_ClickItem($hListView, $iSelected, "left", False, 1)
			_Play()
		EndIf
	ElseIf UBound($lrc_Show,0)=2 Then

		If  $n = 0 And $time_pos>=$lrc_Show[0][0] Then
			GUICtrlSetColor(_GUICtrlListView_GetItemParam($Lrc_List, 0), $lrc_text_front_color)
			_GUICtrlListView_EnsureVisible($Lrc_List, 0)
			$hBmp = _ImageDrawText($hImage1, $lrc_Show[0][1], 0,0, $font_color, $font_size, $font_var, $font_name)
;~ 			      ConsoleWrite($tr&@CRLF)
			SetBitmap($dGUI, $hBmp, $tr)
			_WinAPI_DeleteObject($hBmp)
			$n=1
		ElseIf $n = 1 And $time_pos>=$lrc_Show[1][0] Then
			GUICtrlSetColor(_GUICtrlListView_GetItemParam($Lrc_List, 0), $lrc_text_back_color)
			GUICtrlSetColor(_GUICtrlListView_GetItemParam($Lrc_List, 1), $lrc_text_front_color)
            _GUICtrlListView_EnsureVisible($Lrc_List, 1)
			$hBmp = _ImageDrawText($hImage1, $lrc_Show[1][1], 0,0, $font_color, $font_size, $font_var, $font_name)
			SetBitmap($dGUI, $hBmp, $tr)
			_WinAPI_DeleteObject($hBmp)
			$n=2
		ElseIf $n>=UBound($lrc_Show, 1)-1 Then
			Return
		ElseIf $n>=2 Then
			Switch $time_pos
				Case 1 To $lrc_Show[$n-1][0]
			        GUICtrlSetColor(_GUICtrlListView_GetItemParam($Lrc_List, $n-1), $lrc_text_back_color)
			        Do
			        	$n-=1
			        	If $n=0 Then ExitLoop
					Until $time_pos>=$lrc_Show[$n][0]
					GUICtrlSetColor(_GUICtrlListView_GetItemParam($Lrc_List, $n), $lrc_text_front_color)
   	    	        $hBmp = _ImageDrawText($hImage1, $lrc_Show[$n][1], 0,0, $font_color, $font_size, $font_var, $font_name)
			        SetBitmap($dGUI, $hBmp, $tr)
                    _WinAPI_DeleteObject($hBmp)
			        $n+=1
				Case $lrc_Show[$n][0] To $lrc_Show[$n+1][0]-1
					GUICtrlSetColor(_GUICtrlListView_GetItemParam($Lrc_List, $n-1), $lrc_text_back_color)
					GUICtrlSetColor(_GUICtrlListView_GetItemParam($Lrc_List, $n), $lrc_text_front_color)
   	    	        $hBmp = _ImageDrawText($hImage1, $lrc_Show[$n][1], 0,0, $font_color, $font_size, $font_var, $font_name)
			        SetBitmap($dGUI, $hBmp, $tr)
                    _WinAPI_DeleteObject($hBmp)
					$n+=1
				Case $lrc_Show[$n+1][0] To $lrc_Show[UBound($lrc_Show, 1)-1][0]
			        GUICtrlSetColor(_GUICtrlListView_GetItemParam($Lrc_List, $n-1), $lrc_text_back_color)
			        Do
			        	$n+=1
			        	If $n=UBound($lrc_Show, 1)-1 Then ExitLoop
					Until $time_pos<=$lrc_Show[$n][0]
;~ 					_GUICtrlListView_Scroll($Lrc_List, 0, 162)
					GUICtrlSetColor(_GUICtrlListView_GetItemParam($Lrc_List, $n), $lrc_text_front_color)
   	    	        $hBmp = _ImageDrawText($hImage1, $lrc_Show[$n][1], 0,0, $font_color, $font_size, $font_var, $font_name)
			        SetBitmap($dGUI, $hBmp, $tr)
                    _WinAPI_DeleteObject($hBmp)
			        $n+=1
				Case Else
					Return
			EndSwitch
			Local $ny=_GUICtrlListView_GetItemPositionY($Lrc_List, $n-1)
			If $ny>170 Or $ny<0 Then
                _GUICtrlListView_EnsureVisible($Lrc_List, UBound($lrc_Show)-2, True)
                _GUICtrlListView_EnsureVisible($Lrc_List, $n-1, True)
            EndIf
		EndIf
	EndIf
EndFunc

Func ChangeStyle($na,$s,$v, $c, $t=255)
	$d_trans = $t
	$tr = $t
	If $n=0 Then
		$hBmp = _ImageDrawText($hImage1, 'Desk Lyrics',  230, 18, $font_color,16)
	Else
	    $hBmp = _ImageDrawText($hImage1, $lrc_Show[$n-1][1], 0, 0, $font_color, $font_size, $font_var, $font_name)
	EndIf
	SetBitmap($dGUI, $hBmp, $tr)
	_WinAPI_DeleteObject($hBmp)
EndFunc

Func _Stop()
;~ 	AdlibUnRegister('move_list')
    _Timer_KillAllTimers($hGUI)
	$move_timer=-1
	$time_pos=0
	If $n>=1 Then
	    GUICtrlSetColor(_GUICtrlListView_GetItemParam($Lrc_List, $n-1), $lrc_text_back_color)
	    $n=0
	EndIf
	_BASS_ChannelStop($MusicHandle)
	_BASS_StreamFree($MusicHandle)
	GUICtrlSetData($slider, 0)
	GUICtrlSetData($Sound_Play, '4')
	GUICtrlSetState($Sound_Stop, $GUI_DISABLE)
	Return
EndFunc

Func _ExitLoading()
 	_SendMessage(GUICtrlGetHandle($L_process), $PBM_SETMARQUEE, False, 100)
;~ 	GUISetState(@SW_ENABLE, $hGUI)
;~ 	GUICtrlSetState($sub_OK,$GUI_ENABLE)
;~ 	_GUICtrlToolbar_EnableButton($hToolbar, $idDat, True)
;~ 	GUICtrlSetState($hGIF, $GUI_ENABLE)
 	_GUICtrlStatusBar_SetText($StatusBar , $temp_stat,1)
EndFunc
Func _ShowLoading()
 	_GUICtrlStatusBar_SetText($StatusBar , "加载中... 按Esc键退出",1)
;~ 	GUISetState(@SW_DISABLE, $hGUI)
;~     GUICtrlSetState($sub_OK,$GUI_DISABLE)
;~ 	_GUICtrlToolbar_EnableButton($hToolbar, $idDat, False)
;~ 	GUICtrlSetState($hGIF, $GUI_DISABLE)
    _SendMessage(GUICtrlGetHandle($L_process), $PBM_SETMARQUEE, True, 100)
EndFunc
Func WM_NCHITTEST($hWnd, $iMsg, $iwParam, $ilParam)
    If ($hWnd = $dGUI) Or ($hWnd = $lGUI) And ($iMsg = $WM_NCHITTEST) Then Return $HTCAPTION
EndFunc

Func _ImageDrawText($hImage, $sText, $iX = 0, $iY = 0, $iRGB = 0x3f3e3c, $iSize = 9, $iStyle = 0, $sFont = "Arial")
    Local $w, $h, $hGraphic1, $hBitmap, $hGraphic2, $hBrush, $hFormat, $hFamily, $hFont, $tLayout, $aInfo
    $w = _GDIPlus_ImageGetWidth($hImage)
    $h = _GDIPlus_ImageGetHeight($hImage)

    ;Create a new bitmap, this way the original opened png is left unchanged
    $hGraphic1 = _GDIPlus_GraphicsCreateFromHWND(_WinAPI_GetDesktopWindow())
    $hBitmap = _GDIPlus_BitmapCreateFromGraphics($w, $h, $hGraphic1)
    $hGraphic2 = _GDIPlus_ImageGetGraphicsContext($hBitmap)

    ; Draw the original opened png into my newly created bitmap
    _GDIPlus_GraphicsDrawImageRect($hGraphic2, $hImage, 0, 0, $w, $h)

    ;Create the font
    $hBrush = _GDIPlus_BrushCreateSolid ("0xFF" & Hex($iRGB, 6))
    $hFormat = _GDIPlus_StringFormatCreate()
    $hFamily = _GDIPlus_FontFamilyCreate ($sFont)
    $hFont = _GDIPlus_FontCreate ($hFamily, $iSize, $iStyle,2)
    $tLayout = _GDIPlus_RectFCreate ($iX, $iY, 0, 0)
    $aInfo = _GDIPlus_GraphicsMeasureString ($hGraphic2, $sText, $hFont, $tLayout, $hFormat)
    $tLayout = _GDIPlus_RectFCreate (Floor($w / 2 - (DllStructGetData($aInfo[0], "Width") / 2)), Floor($h / 2 - (DllStructGetData($aInfo[0], "Height") / 2)), 0, 0)
	$aInfo = _GDIPlus_GraphicsMeasureString ($hGraphic2, $sText, $hFont, $tLayout, $hFormat)   ;重新定义位置
    ;Draw the font onto the new bitmap
    _GDIPlus_GraphicsDrawStringEx ($hGraphic2, $sText, $hFont, $aInfo[0], $hFormat, $hBrush)

    ;Cleanup the no longer needed resources
    _GDIPlus_FontDispose ($hFont)
    _GDIPlus_FontFamilyDispose ($hFamily)
    _GDIPlus_StringFormatDispose ($hFormat)
    _GDIPlus_BrushDispose ($hBrush)
    _GDIPlus_GraphicsDispose ($hGraphic2)
    _GDIPlus_GraphicsDispose ($hGraphic1)

    ;Return the new bitmap
    Return $hBitmap
EndFunc

Func SetBitmap($dGUI, $hImage, $iOpacity)
    Local Const $AC_SRC_ALPHA = 1
    Local Const $ULW_ALPHA = 2
    Local $hScrDC, $hMemDC, $hBitmap, $hOld, $pSize, $tSize, $pSource, $tSource, $pBlend, $tBlend

    $hScrDC = _WinAPI_GetDC(0)
    $hMemDC = _WinAPI_CreateCompatibleDC($hScrDC)
    $hBitmap = _GDIPlus_BitmapCreateHBITMAPFromBitmap($hImage)
    $hOld = _WinAPI_SelectObject($hMemDC, $hBitmap)

    $tSize = DllStructCreate($tagSIZE)
    $pSize = DllStructGetPtr($tSize)
    DllStructSetData($tSize, "X", _GDIPlus_ImageGetWidth($hImage))
    DllStructSetData($tSize, "Y", _GDIPlus_ImageGetHeight($hImage))
    $tSource = DllStructCreate($tagPOINT)
    $pSource = DllStructGetPtr($tSource)
    $tBlend = DllStructCreate($tagBLENDFUNCTION)
    $pBlend = DllStructGetPtr($tBlend)
    DllStructSetData($tBlend, "Alpha", $iOpacity)
    DllStructSetData($tBlend, "Format", $AC_SRC_ALPHA)

    _WinAPI_UpdateLayeredWindow($dGUI, $hScrDC, 0, $pSize, $hMemDC, $pSource, 0, $pBlend, $ULW_ALPHA)
    _WinAPI_ReleaseDC(0, $hScrDC)
    _WinAPI_SelectObject($hMemDC, $hOld)
    _WinAPI_DeleteObject($hBitmap)
    _WinAPI_DeleteDC($hMemDC)
EndFunc ;==>SetBitmap
