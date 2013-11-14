
HotKeySet("{Esc}", "_StopLoading")
Func _lrc_Prase($src_Lrc, $flag=0)
    Local $k=0, $l
	$l_head=DllStructCreate('wchar title[30];wchar artist[30];wchar album[30];wchar editor[30]')
;~ 	ClipPut($src_Lrc)
    If Not $flag Then
		$src_Lrc=StringRegExpReplace($src_Lrc, '[^\v\h](\h*[^\]])(?=\[)', '\1'&@CRLF)
        $src_Lrc=StringRegExpReplace(StringStripWS($src_Lrc, 3),'(?<=\r\n)\s*\r\n','')
        StringRegExpReplace($src_Lrc,'(?m)\[\d{1,2}\:\d{2}(?:\.\d{1,3})?\]','')
	ElseIf $flag=1 Then
		StringRegExpReplace($src_Lrc,'(?m)\[\d+\]','')
	EndIf
	If Not @extended Then Return SetError(-1)
    Local $lrc[@extended][3]
    If StringInStr($src_Lrc,@CRLF) Then
        $l = StringSplit($src_Lrc,@CRLF,1)
	ElseIf StringInStr($src_Lrc,@LF) Then
		$l = StringSplit($src_Lrc,@LF,1)
	Else
		Return $src_Lrc
	EndIf
;~ 	_ArrayDisplay($l)
;~ 	_ArrayDisplay($lrc)
	If $flag=1 And UBound($l)-1<>UBound($lrc) Then Return
	If Not $flag Then
    	For $i = 1 To $l[0]
    		$temp = StringReplace(StringStripWS($l[$i],1),'[','')
    		$my = StringSplit($temp,']')
			If $my[0]=1 Then ContinueLoop
    ;~ 		_ArrayDisplay($my)
     		For $j = 1 To $my[0]-1
				StringRegExp($my[$j],'^\d{1,2}\:\d{2}(\.\d{1,3})?$',3,1)
				If Not @error Then
    				$time = _TimeConv($my[$j])
    				$lrc[$k][0]=$time
					If Not $my[$my[0]] Then $my[$my[0]]='... ...'
    				$lrc[$k][1]=$my[$my[0]]
    				$k+=1
                ElseIf StringLeft($my[$j],3)='ti:' Then
       				DllStructSetData($l_head,"title",StringTrimLeft($my[$j],3))
    			ElseIf StringLeft($my[$j],3)='ar:' Then
    				DllStructSetData($l_head,"artist",StringTrimLeft($my[$j],3))
    			ElseIf StringLeft($my[$j],3)='al:' Then
    				DllStructSetData($l_head,"album",StringTrimLeft($my[$j],3))
    			ElseIf StringLeft($my[$j],3)='by:' Then
    				DllStructSetData($l_head,"editor",StringTrimLeft($my[$j],3))
                Else
                    ContinueLoop
    			EndIf
       		Next

        Next
	ElseIf $flag=1 Then
		For $i = 1 To $l[0]
			$my=StringSplit(StringTrimLeft($l[$i],1),']',2)
			$lrc[$k][0]=Number($my[0])
			If Not $my[1] Then $my[1]='... ...'
			$lrc[$k][1]=$my[1]
			$k+=1
		Next
	EndIf
    	_ArraySort($lrc, 0, 0, 0, 0)
		If $k>=2 Then
		    For $i=0 To $k-2
		    	$lrc[$i][2]=$lrc[$i+1][0]-$lrc[$i][0]
		    Next
			$lrc[$k-1][2]=0
		EndIf
    ;~ 	_ArrayDisplay($lrc,$ti&$ar)
        Return $lrc
EndFunc ;===>_lrc()

Func _txt_Prase($src_Txt, ByRef $aArray)
	$src_Txt=StringRegExpReplace(StringStripWS($src_Txt, 3),'(?<=\r\n)\s*\r\n','')
	If StringInStr($src_Txt, @CRLF) Then
		$aArray = StringSplit(StringStripCR($src_Txt), @CRLF, 2)
	Else
		If Not StringLen($src_Txt) Then Return SetError(1)
		Dim $aArray[1] = [$src_Txt]
	EndIf
	Return SetError(0)
EndFunc

Func _TimeConv($t)
	Local $tt=StringSplit($t,':')
	If $tt[0]<>2 Then Return 0
	Switch  StringLen($tt[2]) - StringInStr($tt[2],'.')
		Case 2
	        Return Int($tt[1])*60*1000+Int(StringMid($tt[2],1,2))*1000+Int(StringMid($tt[2],4,2))*10
		Case 3
			Return Int($tt[1])*60*1000+Int(StringMid($tt[2],1,2))*1000+Int(StringMid($tt[2],4,3))
		Case 1
			Return Int($tt[1])*60*1000+Int(StringMid($tt[2],1,2))*1000+Int(StringMid($tt[2],4,1))*100
		Case StringLen($tt[2])
			Return Int($tt[1])*60*1000+Int(StringMid($tt[2],1,2))*1000
		Case Else
			Return 0
	EndSwitch
EndFunc

Func _TickToTime($t)
	Local $Min,$Sec,$mSec
	If Not $t Then Return '00:00.00'
	$Min=Int($t/60000)
	$t=Mod($t,60000)
	$Sec=Int($t/1000)
	$mSec=Int(Mod($t,1000)/10)
	Return StringFormat("%02i:%02i.%02i", $Min, $Sec, $mSec)
EndFunc

Func _TicksToTime($iTicks, ByRef $iFormat)
	Local $iHours, $iMins, $iSecs
	If Number($iTicks) > 0 Then
		$iTicks = Int($iTicks / 1000)
		$iHours = Int($iTicks / 3600)
		$iTicks = Mod($iTicks, 3600)
		$iMins = Int($iTicks / 60)
		$iSecs = Mod($iTicks, 60)
		$iFormat = StringFormat("%02i:%02i:%02i", $iHours, $iMins, $iSecs)
		; If $iHours = 0 then $iHours = 24
		Return SetError(0)
	ElseIf Number($iTicks) = 0 Then
        $iFormat = '00:00:00'
		Return SetError(0)
	Else
		Return SetError(1)
	EndIf
EndFunc   ;==>_TicksToTime

Func _get_cover($xml)
	Local $i, $ii=0, $current, $douA, $douB, $douC, $douD, $douE, $douF, $douG, $douH
	Local $keyWord, $totalResults, $startIndex, $douban
	$xml = StringRegExpReplace($xml,'\v','')
	$keyWord = StringRegExp($xml,'<title>搜索\s(.*?)\s的结果<\/title>',3,1)
	$totalResults = StringRegExp($xml,'<opensearch:totalResults>(\d+)<\/opensearch:totalResults>',3,1)
	$startIndex = StringRegExp($xml,'<opensearch:startIndex>(\d+)<\/opensearch:startIndex>',3,1)
	If $totalResults = 0 Then Return SetError(1)
	$douA=StringRegExp($xml,'<entry>(.*?)<\/entry>',3,1)
	If @error Then Return SetError(1)
	$current=UBound($douA)
	If Number($startIndex[0])>1 Then
	    Dim $douban[$current+1][6]
		Dim $douban2[$current+1][2]
		$douban[0][0]='[...上一页...]'
		$douban2[0][0]='<<'
		$douban2[0][1]=$keyWord[0]
		$ii=1
	Else
	    Dim $douban[$current][6]
	    Dim $douban2[$current][2]
	EndIf
	For $i = 0 To $current-1
	    $j = $i+$ii
		$douB=StringRegExp($douA[$i],'<id>(.*?)<\/id>',3,1)
		$douban2[$j][0]=$douB[0]
		$douC=StringRegExp($douA[$i],'<title>(.*?)<\/title>',3,1)
		$douban[$j][0]=$douC[0]
		$douD=StringRegExp($douA[$i],'(?i)http://([^/]+)(/spic/\w+\.\w+)',3,1)
		If @error Then
    		$douban2[$j][1]='img3.douban.com|/pics/music-default-medium.gif'
		Else
			$douban2[$j][1]=$douD[0]&'|'&$douD[1]
		EndIf
		$douE=StringRegExp($douA[$i],'<db:attribute name="pubdate">(.*?)<\/db:attribute>',3.1)
		If @error Then
    		$douban[$j][2]=''
		Else
		    $douban[$j][2]=$douE[0]
		EndIf
		$douF=StringRegExp($douA[$i],'<db:attribute name="singer">(.*?)<\/db:attribute>',3.1)
		If @error Then
     		$douban[$j][1]=''
		ElseIf UBound($douF)>1 Then
			$douban[$j][1]=_ArrayToString($douF, '/')
		Else
		    $douban[$j][1]=$douF[0]
		EndIf
		$douG=StringRegExp($douA[$i],'<db:attribute name="publisher">(.*?)<\/db:attribute>',3.1)
		If @error Then
    		$douban[$j][3]=''
		Else
		    $douban[$j][3]=$douG[0]
		EndIf
		$douH=StringRegExp($douA[$i],'<gd:rating average=\"([\d\.]+)\".*?numRaters=\"(\d+)\"/>',3.1)
		If @error Then
    		$douban[$j][4]=''
			$douban[$j][5]=''
		Else
		    $douban[$j][4]=$douH[0]
			$douban[$j][5]=$douH[1]
		EndIf
	Next
;~ 	MsgBox(0,$startIndex[0],$current&'  '&$totalResults[0])
	If Number($startIndex[0])+29<Number($totalResults[0]) And $current=30 Then
    	ReDim $douban[$current+$ii+1][6]
		$douban[$current+$ii][0]='[...下一页...]'
		ReDim $douban2[$current+$ii+1][2]
		$douban2[$current+$ii][0]='>>'
		$douban2[$current+$ii][1]=$keyWord[0]
	EndIf
	_GUICtrlListView_DeleteAllItems(GUICtrlGetHandle($sub_list))
	_GUICtrlListView_AddArray($sub_list, $douban)
	_GUICtrlListView_SetColumn($sub_list, 0, "标题", 212, 0)
	_GUICtrlListView_SetColumn($sub_list, 1, "歌手", 92, 2)
	_GUICtrlListView_SetColumn($sub_list, 2, "时间", 52, 2)
	_GUICtrlListView_SetColumn($sub_list, 3, "发布人", 50, 2)
	_GUICtrlListView_SetColumn($sub_list, 4, "得分", 38, 2)
	_GUICtrlListView_SetColumn($sub_list, 5, "票数", 38, 2)
    WinSetTitle($Lrc_Choose, '', '选择专辑(共 '& $totalResults[0] &' 条结果) - 豆瓣音乐')
	GUISetState(@SW_SHOW, $Lrc_Choose)
	GUISetState(@SW_DISABLE, $hGUI)
EndFunc

Func _StopLoading()
	If $Data_Count Then $Stop_l=True
	If _GUICtrlStatusBar_GetText($StatusBar, 1) = "加载中... 按Esc键退出" Then
	    If ProcessClose($load_Pro) Then
	    	$load_Pro = 0
	    	$load_Pro = _CoProc("_load_")
	    	Return _ExitLoading()
	    Else
	    	Return _ToolTip('错误', "无法停止进程，错误代码: " & @error, 3)
	    EndIf
	EndIf
EndFunc

Func _GetExtProperty($sPath, $iProp)
	Local $iExist, $sFile, $sDir, $oShellApp, $oDir, $oFile, $tem, $tt, $at, $al, $aProperty='', $sProperty=''
;~ 	$iExist = FileExists($sPath)
;~ 	If $iExist = 0 Then
;~ 		Return SetError(1)
;~ 	EndIf
    $sDir = FileGetShortName(StringRegExpReplace($sPath, "(^.*\\)(.*)", "\1"), 1)
    $sFile = StringRegExpReplace($sPath, "^.*\\", "")
	$oShellApp = ObjCreate("shell.application")
	$oDir = $oShellApp.NameSpace($sDir)
	$oFile = $oDir.Parsename($sFile)
	If $iProp = -1 Then
		For $i = 0 To 34
			$aProperty &= $oDir.GetDetailsOf($oFile, $i)&@LF
		Next
		Return StringTrimRight($aProperty,1)
	Else
		$arr = StringSplit($iProp, '|')
		For $i = 1 To $arr[0]
			$sProperty &= $oDir.GetDetailsOf($oFile, Number($arr[$i]))&@LF
		Next
		Return StringTrimRight($sProperty,1)
	EndIf
EndFunc   ;==>_GetExtProperty

;返回值：= 1 成功
;        = 0 失败，并返回 @Error 为以下值：
;                         @Error = 1--原始文件不存在
;                         @Error = 2--未指定新文件名
;                         @Error = 3--新文件名含有非法字符
;                         @Error = 4--新文件名已存在同名文件
;                         @Error = 5--未知错误(如不能更改的系统目录、正在使用的目录等)

Func _File_Rename($File_Old_Name, $File_New_Name)
        If Not FileExists($File_Old_Name) Then Return SetError(1, 0, 0)
        If $File_New_Name = '' Then Return SetError(2, 0, 0)
        If StringRight($File_Old_Name, 1) = '\' Then $File_Old_Name = StringTrimRight($File_Old_Name, 1)
        If StringInStr($File_New_Name, '\') Then $File_New_Name = StringRegExpReplace($File_New_Name, '.+\\', '')
        If StringRegExp($File_New_Name, '(\/|\:|\*|\?|\"|\<|\>|\|)') Then Return SetError(3, 0, 0)
        Local $fPath = ''
        If StringRegExp($File_Old_Name, '\\') Then $fPath = StringRegExpReplace($File_Old_Name, '(.+\\).+', '\1')
        If FileExists($fPath & $File_New_Name) Then Return SetError(4, 0, 0)
;~ 		MsgBox(0,$File_Old_Name,$fPath & $File_New_Name)
;~         RunWait(@ComSpec & ' /c Rename "' & $File_Old_Name & '" ' & $File_New_Name, @ScriptDir, @SW_HIDE)
        FileMove($File_Old_Name,$fPath & $File_New_Name,1)
        If FileExists($fPath & $File_New_Name) Then Return 1
        If Not FileExists($fPath & $File_New_Name) Then Return SetError(5, 0, 0)
EndFunc   ;==>_File_Rename
Func _SearchFile($fo, $single='',$index=-1)
	Local $sFile, $filetype, $info, $item, $sub_folder,$temp,$tFormat
	If Not $single Then
		ProgressOn("加载中", "等待读取", "0 %")
		If $SubSel_Deep Then
		    $deep=GUICtrlRead($SubSel_Deep)
		Else
		    $deep=$dir_depth
		EndIf
		$Data_Count = 0
        _filelist($fo)
	    If Not $file_list Then
			_ToolTip('提示','目录下没有文件',3)
		    Return SetError(1)
		EndIf
		$sFile=StringSplit($file_list,@CRLF,1)
		$file_list=''
		_GUICtrlListView_DeleteAllItems(GUICtrlGetHandle($hListView))
		Dim $bLVItems[$sFile[0]-1][8]
	Else
		If Not FileExists($single) Then Return SetError(1)
		Dim $sFile[2]=[2,$single]
		If UBound($bLVItems,2)=8 Then
			If $index=-1 Then ReDim $bLVItems[$Data_Count+1][8]
		Else
		    _GUICtrlListView_DeleteAllItems(GUICtrlGetHandle($hListView))
		    Dim $bLVItems[1][8]
		EndIf
	EndIf
	If @OSVersion = 'WIN_7' Then
	    $Ext_Index = '21|20|14|28|1|27'
	Else
		$Ext_Index = '10|16|17|22|1|21'
	EndIf
	If Not $single Then _GUICtrlStatusBar_SetText($StatusBar, "读取中，按Esc键中断", 1)
	For $i = 1 To $sFile[0]-1
		If $Stop_l Then ExitLoop
		$filetype = StringRegExp($sFile[$i],'\.(\w+)$',3,1)
		If Not IsArray($filetype) Then Dim $filetype[1]=['']

		If $only_file_without_lrc Then
		    If FileExists(StringRegExpReplace($sFile[$i],'\.\w+$','.lrc')) Then ContinueLoop
		EndIf
		If Not $single Then ProgressSet( Round($i/$sFile[0],2)*100, '第'&$i & "个文件",'正在读取')
		Local $sub_folder = StringMid(StringRegExpReplace($sFile[$i],'[^\\]+$',''),StringLen($fo)+2)
		Switch StringLower($filetype[0])
			Case 'wma','mp3','m4a'
				Dim $info = StringSplit(_GetExtProperty($sFile[$i], $Ext_Index)&@LF&$sub_folder, @LF)
				$info[0] = StringRegExpReplace($sFile[$i],'^.*\\','')
			Case 'flac','wav','aac'
				$size = _GetExtProperty($sFile[$i], '1')
				Local $stream = _BASS_StreamCreateFile(False, $sFile[$i],0,0,0)
				Local $len=_BASS_ChannelBytes2Seconds($stream, _BASS_ChannelGetLength($stream, $BASS_POS_BYTE))
				_TicksToTime(Round($len*1000,0), $tFormat)
				Local $bitrate=Round(_BASS_StreamGetFilePosition($stream, $Bass_FILEPOS_END)/$len/125, 0)
				Dim $info[8] = [StringRegExpReplace($sFile[$i],'^.*\\',''), '', '', '',$bitrate&'kbps',$size,$tFormat,$sub_folder]
		    Case 'ogg','ape'
			    $size = _GetExtProperty($sFile[$i], '1')
				Local $stream = _BASS_StreamCreateFile(False, $sFile[$i],0,0,0)
				If $filetype[0]='ogg' Then
				    Local $ptr = _BASS_ChannelGetTags($stream, 2)
				Else
					Local $ptr = _BASS_ChannelGetTags($stream, 6)
				EndIf
                If Not @error Then
				    $temp = _GetID3StructFromOGGComment($ptr)
				Else
					$temp=DllStructCreate($ogg_tag)
				EndIf
				Local $len=_BASS_ChannelBytes2Seconds($stream, _BASS_ChannelGetLength($stream, $BASS_POS_BYTE))
				If Not @error Then
				    _TicksToTime(Round($len*1000,0), $tFormat)
				    Local $bitrate=Round(_BASS_StreamGetFilePosition($stream, $Bass_FILEPOS_END)/$len/125, 0)
				Else
					$bitrate=-1
					$tFormat='00:00:00'
				EndIf
				Dim $info[8] = [StringRegExpReplace($sFile[$i],'^.*\\',''), _
				DllStructGetData($temp, "title"),DllStructGetData($temp, "artist"),DllStructGetData($temp, "album"),$bitrate&'kbps',$size,$tFormat,$sub_folder]
				_BASS_StreamFree($stream)

			Case Else
				ContinueLoop
		EndSwitch
		If $index=-1 Then
		    For $j = 0 To 7
		    	$bLVItems[$Data_Count][$j]=StringStripWS($info[$j],3)
		    Next
		    $Data_Count += 1
		Else
		    For $j = 0 To 7
		    	$bLVItems[$index][$j]=StringStripWS($info[$j],3)
		    Next
		EndIf
	Next
	ProgressSet(100 , "完成", "加载完成")
	If Not $Data_Count Then
		Dim $bLVItems[1][8] = [[0, 0, 0, 0, 0, 0, 0, 0]]
	Else
	    ReDim $bLVItems[$Data_Count][8]
	EndIf
	$Stop_l=False
EndFunc

Func _filelist($searchdir,$d=1)
        $search = FileFindFirstFile($searchdir & "\*.*")
        If $search = -1 Then Return
        While 1
                $file = FileFindNextFile($search)
                If @error Then
					FileClose($search)
					Return
;~                 ElseIf StringInStr(FileGetAttrib($searchdir & "\" & $file), "D") Then
				ElseIf @extended=1 Then
                    If $d<$deep Then
						_filelist($searchdir & "\" & $file,$d+1)
					EndIf
				Else
					$file_list &= $searchdir & "\" & $file & @CRLF
                EndIf
        WEnd
EndFunc   ;==>_filelist

Func _ANSI_FIX($UN_FIX_TEXT);修复汉字计算字符数引起的字符截断问题,用于ClipPutFile  作者：ACN论坛 lainline
    Local $temp= $UN_FIX_TEXT
    Local $cnTEXTnumber = BinaryLen (StringToBinary($temp,4))-StringLen($temp)
    If $cnTEXTnumber>0 Then
    For $i=1 To $cnTEXTnumber
    $temp &= "|"
    Next
    EndIf
    Return $temp
EndFunc

Func _PinYin($str)
	For $i = 1 To StringLen($str)
	Switch Dec(StringTrimLeft(StringToBinary($str),2))
		Case 33095 To 62289
			Return Chr(97+_C($str,0,26))
		Case 65 To 122
			Return $str
		Case Else
		    Return SetExtended(1,$str)
	EndSwitch
Next
EndFunc
Func _C($s,$f,$e)
	Local $mid=Int(($e-$f)/2)+$f
	If $mid=$f Then Return $f
	If StringCompare($s,$key[$mid])>0 Then
		Return _C($s,$mid,$e)
	ElseIf StringCompare($s,$key[$mid])<0 Then
		Return _C($s,$f,$mid)
	ElseIf Not StringCompare($s,$key[$mid]) Then
		Return $mid
	EndIf
EndFunc

Func __ArraySort(ByRef $avArray, $iDescending = 0, $iStart = 0, $iEnd = 0, $iSubItem = 0, $forceNUM=False)
	If Not IsArray($avArray) Then Return SetError(1, 0, 0)

	Local $iUBound = UBound($avArray) - 1

	; Bounds checking
	If $iEnd < 1 Or $iEnd > $iUBound Then $iEnd = $iUBound
	If $iStart < 0 Then $iStart = 0
	If $iStart > $iEnd Then Return SetError(2, 0, 0)

	; Sort
	Switch UBound($avArray, 0)
		Case 1
			__ArrayQuickSort1D($avArray, $iStart, $iEnd)
			If $iDescending Then _ArrayReverse($avArray, $iStart, $iEnd)
		Case 2
			Local $iSubMax = UBound($avArray, 2) - 1
			If $iSubItem > $iSubMax Then Return SetError(3, 0, 0)

			If Not $iDescending Then $iDescending = 1

			_ArrayQuickSort2D($avArray, $iDescending, $iStart, $iEnd, $iSubItem, $iSubMax, $forceNUM)
		Case Else
			Return SetError(4, 0, 0)
	EndSwitch

	Return 1
EndFunc   ;==>_ArraySort

Func _ArrayQuickSort2D(ByRef $avArray, ByRef $iStep, ByRef $iStart, ByRef $iEnd, ByRef $iSubItem, ByRef $iSubMax, $forceNUM)
	If $iEnd <= $iStart Then Return

	; QuickSort
	Local $vTmp, $L = $iStart, $R = $iEnd, $vPivot = $avArray[Int(($iStart + $iEnd) / 2)][$iSubItem], $fNum = IsNumber($vPivot)
	Do
		If Not $forceNUM Then
		    If $fNum Then
		    	; While $avArray[$L][$iSubItem] < $vPivot
		    	While ($iStep * ($avArray[$L][$iSubItem] - $vPivot) < 0 And IsNumber($avArray[$L][$iSubItem])) Or (Not IsNumber($avArray[$L][$iSubItem]) And $iStep * StringCompare($avArray[$L][$iSubItem], $vPivot) < 0)
		    		$L += 1
		    	WEnd
		    	; While $avArray[$R][$iSubItem] > $vPivot
		    	While ($iStep * ($avArray[$R][$iSubItem] - $vPivot) > 0 And IsNumber($avArray[$R][$iSubItem])) Or (Not IsNumber($avArray[$R][$iSubItem]) And $iStep * StringCompare($avArray[$R][$iSubItem], $vPivot) > 0)
		    		$R -= 1
		    	WEnd
		    Else
		    	While ($iStep * StringCompare($avArray[$L][$iSubItem], $vPivot) < 0)
		    		$L += 1
		    	WEnd
		    	While ($iStep * StringCompare($avArray[$R][$iSubItem], $vPivot) > 0)
		    		$R -= 1
		    	WEnd
		    EndIf
		Else
			$vPivot=Number($vPivot)
            While ($iStep * (Number($avArray[$L][$iSubItem]) - $vPivot)) < 0
				$L += 1
			WEnd
			While ($iStep * (Number($avArray[$R][$iSubItem]) - $vPivot)) > 0
				$R -= 1
			WEnd
	    EndIf

		; Swap
		If $L <= $R Then
			For $i = 0 To $iSubMax
				$vTmp = $avArray[$L][$i]
				$avArray[$L][$i] = $avArray[$R][$i]
				$avArray[$R][$i] = $vTmp
			Next
			$L += 1
			$R -= 1
		EndIf
	Until $L > $R

	_ArrayQuickSort2D($avArray, $iStep, $iStart, $R, $iSubItem, $iSubMax,$forceNUM)
	_ArrayQuickSort2D($avArray, $iStep, $L, $iEnd, $iSubItem, $iSubMax,$forceNUM)
EndFunc   ;==>__ArrayQuickSort2D

Func __ChooseFont($sFontName = "Courier New", $iPointSize = 10, $iColorRef = 0, $iFontWeight = 0, $iItalic = False, $iUnderline = False, $iStrikethru = False, $hWndOwner = 0)
	Local $italic = 0, $underline = 0, $strikeout = 0

	Local $lngDC = __MISC_GetDC(0)
	Local $lfHeight = Round(($iPointSize * __MISC_GetDeviceCaps($lngDC, $LOGPIXELSX)) / 72, 0)
	__MISC_ReleaseDC(0, $lngDC)

	Local $tChooseFont = DllStructCreate($_tagCHOOSEFONT)
	Local $tLogFont = DllStructCreate($tagLOGFONT)

	DllStructSetData($tChooseFont, "Size", DllStructGetSize($tChooseFont))
	DllStructSetData($tChooseFont, "hWndOwner", $hWndOwner)
	DllStructSetData($tChooseFont, "LogFont", DllStructGetPtr($tLogFont))
	DllStructSetData($tChooseFont, "PointSize", $iPointSize)
	DllStructSetData($tChooseFont, "Flags", BitOR($CF_SCREENFONTS, $CF_INITTOLOGFONTSTRUCT,$CF_NOSCRIPTSEL,0x10000,0x1000000,0x2000))
	DllStructSetData($tChooseFont, "rgbColors", $iColorRef)
	DllStructSetData($tChooseFont, "FontType", 0)
    DllStructSetData($tChooseFont, "nSizeMin", 8)
	DllStructSetData($tChooseFont, "nSizeMax", 20)

	DllStructSetData($tLogFont, "Height", $lfHeight)
	DllStructSetData($tLogFont, "Weight", $iFontWeight)
	DllStructSetData($tLogFont, "Italic", $iItalic)
	DllStructSetData($tLogFont, "Underline", $iUnderline)
	DllStructSetData($tLogFont, "Strikeout", $iStrikethru)
	DllStructSetData($tLogFont, "FaceName", $sFontName)

	Local $aResult = DllCall("comdlg32.dll", "bool", "ChooseFontW", "ptr", DllStructGetPtr($tChooseFont))
	If @error Then Return SetError(@error, @extended, -1)
	If $aResult[0] = 0 Then Return SetError(-3, -3, -1) ; user selected cancel or struct settings incorrect

	Local $fontname = DllStructGetData($tLogFont, "FaceName")
	If StringLen($fontname) = 0 And StringLen($sFontName) > 0 Then $fontname = $sFontName

	If DllStructGetData($tLogFont, "Italic") Then $italic = 2
	If DllStructGetData($tLogFont, "Underline") Then $underline = 4
	If DllStructGetData($tLogFont, "Strikeout") Then $strikeout = 8

	Local $attributes = BitOR($italic, $underline, $strikeout)
	Local $size = DllStructGetData($tChooseFont, "PointSize") / 10
	Local $colorref = DllStructGetData($tChooseFont, "rgbColors")
	Local $weight = DllStructGetData($tLogFont, "Weight")

	Local $color_picked = Hex(String($colorref), 6)

	Return StringSplit($attributes & "," & $fontname & "," & $size & "," & $weight & "," & $colorref & "," & '0x' & $color_picked & "," & '0x' & StringMid($color_picked, 5, 2) & StringMid($color_picked, 3, 2) & StringMid($color_picked, 1, 2), ",")
EndFunc   ;==>_ChooseFont

Func _ToolTip($t,$n_msg,$ti,$f=0)
	Local $h_pos=WinGetPos($hGUI)
	ToolTip($n_msg,Int($h_pos[2]/2)+$h_pos[0],$h_pos[1]+35,$t,$f,6)
	AdlibRegister("_del_tooltip",$ti*1000)
EndFunc

Func _timeStamp($t)
	If IsArray($lrc_Show) Then
		For $i = 0 To UBound($lrc_Format) - 1
			$lrc_Format[$i][0] += $t
			$lrc_Show[$i][0] += $t
			If $lrc_Format[$i][0] < 0 Then
				$lrc_Format[$i][0] = 0
				$lrc_Show[$i][0] = 0
			EndIf
		Next
	Else
		For $i = 0 To UBound($lrc_Format) - 1
			$lrc_Format[$i][0] += $t
			If $lrc_Format[$i][0] < 0 Then
				$lrc_Format[$i][0] = 0
			EndIf
		Next
	EndIf
EndFunc

Func _del_tooltip()
	ToolTip('')
	AdlibUnRegister("_del_tooltip")
EndFunc

; Prog@ndy
Func _GUIImageList_GetSystemImageList($bLargeIcons = False)
    Local $dwFlags, $hIml, $FileInfo = DllStructCreate($tagSHFILEINFO)


    $dwFlags = BitOR($SHGFI_USEFILEATTRIBUTES, $SHGFI_SYSICONINDEX)
    If Not ($bLargeIcons) Then
        $dwFlags = BitOR($dwFlags, $SHGFI_SMALLICON)
    EndIf

;~    '// Load the image list - use an arbitrary file extension for the
;~    '// call to SHGetFileInfo (we don't want to touch the disk, so use
;~    '// FILE_ATTRIBUTE_NORMAL && SHGFI_USEFILEATTRIBUTES).
    $hIml = _WinAPI_SHGetFileInfo(".mp3", $FILE_ATTRIBUTE_NORMAL, _
            DllStructGetPtr($FileInfo), DllStructGetSize($FileInfo), $dwFlags)

    Return $hIml
EndFunc   ;==>_GUIImageList_GetSystemImageList

; Prog@ndy
Func _WinAPI_SHGetFileInfo($pszPath, $dwFileAttributes, $psfi, $cbFileInfo, $uFlags)
    Local $return = DllCall("shell32.dll", "DWORD*", "SHGetFileInfo", "str", $pszPath, "DWORD", $dwFileAttributes, "ptr", $psfi, "UINT", $cbFileInfo, "UINT", $uFlags)
    If @error Then Return SetError(@error, 0, 0)
    Return $return[0]
EndFunc   ;==>_WinAPI_SHGetFileInfo

; Prog@ndy
Func _GUIImageList_GetFileIconIndex($sFileSpec, $bLargeIcons = False, $bForceLoadFromDisk = False)
    Local $dwFlags, $FileInfo = DllStructCreate($tagSHFILEINFO)

    $dwFlags = $SHGFI_SYSICONINDEX
    If $bLargeIcons Then
        $dwFlags = BitOR($dwFlags, $SHGFI_LARGEICON)
    Else
        $dwFlags = BitOR($dwFlags, $SHGFI_SMALLICON)
    EndIf
;~ ' We choose whether to access the disk or not. If you don't
;~ ' hit the disk, you may get the wrong icon if the icon is
;~ ' not cached. But the speed is very good!
    If Not $bForceLoadFromDisk Then
        $dwFlags = BitOR($dwFlags, $SHGFI_USEFILEATTRIBUTES)
    EndIf

;~ ' sFileSpec can be any file. You can specify a
;~ ' file that does not exist and still get the
;~ ' icon, for example sFileSpec = "C:\PANTS.DOC"
    Local $lR = _WinAPI_SHGetFileInfo( _
            $sFileSpec, $FILE_ATTRIBUTE_NORMAL, DllStructGetPtr($FileInfo), DllStructGetSize($FileInfo), _
            $dwFlags _
            )

    If ($lR = 0) Then
        Return SetError(1, 0, -1)
    Else
        Return DllStructGetData($FileInfo, "iIcon")
    EndIf
EndFunc   ;==>_GUIImageList_GetFileIconIndex

Func __GUICtrlListView_AddArray($hWnd, ByRef $aItems)
	If $Debug_LV Then __UDF_ValidateClassName($hWnd, $__LISTVIEWCONSTANT_ClassName)

	Local $tItem = DllStructCreate($tagLVITEM)
	Local $tBuffer
	$tBuffer = DllStructCreate("wchar Text[4096]")

	DllStructSetData($tItem, "Mask", BitOR($LVIF_TEXT, $LVIF_IMAGE))
	DllStructSetData($tItem, "Text", DllStructGetPtr($tBuffer))
	DllStructSetData($tItem, "TextMax", 4096)
	Local $iLastItem = _GUICtrlListView_GetItemCount($hWnd)
	_GUICtrlListView_BeginUpdate($hWnd)
	Local $pItem = DllStructGetPtr($tItem)
	For $iI = 0 To UBound($aItems) - 1
		DllStructSetData($tItem, "Item", $iI + $iLastItem)
		DllStructSetData($tItem, "SubItem", 0)
		DllStructSetData($tItem, "Image", _GUIImageList_GetFileIconIndex($aItems[$iI][0]))
		DllStructSetData($tBuffer, "Text", $aItems[$iI][0])
		GUICtrlSendMsg($hWnd, $LVM_INSERTITEMW, 0, $pItem)
		For $iJ = 1 To UBound($aItems, 2) - 1
			DllStructSetData($tItem, "SubItem", $iJ)
			DllStructSetData($tBuffer, "Text", $aItems[$iI][$iJ])
			GUICtrlSendMsg($hWnd, $LVM_SETITEMW, 0, $pItem)
		Next
	Next
	_GUICtrlListView_EndUpdate($hWnd)
EndFunc   ;==>__GUICtrlListView_AddArray