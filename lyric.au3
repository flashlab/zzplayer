#include <WinHttp.au3>
#Include <WinAPIEx.au3>
#include <ACN_HASH.au3>
#include <CoProc.au3>
#include <String.au3>
#include "ZLIB.au3"

; #FUNCTION# ;===============================================================================
; Name...........: _LrcList_qianqian
; Description ...: 获取千千静听搜索结果
; Syntax.........: _LrcList_qianqian ($artist, $title [, $server = Default ])
; Parameters ....: $artist - 歌手
;                  $title - 歌名
;                  $server - 歌词服务器。0=电信；1=网通
; Return values .: Success - Returns 包含搜索结果的数组
;                  Failure - Returns 0
; Author ........: flashlab
; Modified.......:
; Remarks .......: 歌名参数不能为空
; Related .......:
; Link ..........:
; Example .......:
;============================================================================================
Func _LrcList_qianqian($a,$t,$s=0, $xml='')  ;参数（歌手名，歌曲名，服务器）
Local $url
If Not $xml Then
    If $s=0 Then
    	$url='ttlrcct.qianqian.com'   ;电信服务器
    Else
    	$url='ttlrccnc.qianqian.com'   ;网通服务器
    EndIf
    $a=StringLower(_clear($a))
    $t=StringLower(_clear($t))
	Local $send = $url & '|' & '/dll/lyricsvr.dll?sh?Artist=' & _
    	StringTrimLeft(StringToBinary($a,2),2) & '&Title=' & StringTrimLeft(StringToBinary($t,2),2) & '&Flags=0' & '|1' & '||||'
    If _CoProcSend($load_Pro, $send) Then

	Else
		_ToolTip('错误', "Worker not Responding (" & @error & ")", 3,3)
	EndIf
Else
    $list = StringRegExp($xml,'(?i)<lrc\s(.*?)></lrc>',3,1);结果保存在数组中
	If @error Then
		Return _ToolTip("抱歉","没有在千千静听搜索到歌词", 3,1)
	Else
		Local $link[UBound($list)][3]
		For $i = 0 To UBound($list)-1
			$temp=StringRegExp(_ClearXml($list[$i]),'(?i)id="(.*?)"\sartist="(.*?)"\stitle="(.*?)"',3,1)
			$link[$i][0]=Number($temp[0])
			$link[$i][1]=$temp[1]
			$link[$i][2]=$temp[2]
		Next
		Return $link
	EndIf
EndIf
EndFunc
; #FUNCTION# ;===============================================================================
; Name...........: _LrcDownLoad_qianqian
; Description ...: 下载歌词
; Syntax.........: _LrcDownLoad_qianqian ($ID, $artist, $title [, $server = Default ])
; Parameters ....: $ID - 从_LrcList_qianqian()获得
;                  $artist - 歌手
;                  $title - 歌名
;                  $server - 歌词服务器。0=电信；1=网通
; Return values .: Success - Returns lrc歌词
;                  Failure - Returns ''
; Author ........: flashlab
; Modified.......:
; Remarks .......: 歌名参数不能为空
; Related .......:
; Link ..........:
; Example .......:
;============================================================================================
Func _LrcDownLoad_qianqian($lrcid,$artist,$title,$s=0)  ;参数（歌曲ID，艺术家，歌名）
	Local $utfURL,$url,$url2,$len,$c,$i,$j,$t4,$t5,$t6
	If $s=0 Then
    	$url='ttlrcct.qianqian.com'   ;电信服务器
    Else
    	$url='ttlrccnc.qianqian.com'   ;网通服务器
    EndIf
	$utfURL=_UrlToHex($artist & $title,0,'unicode')
	If Mod(StringLen($utfURL),2)=1 Then $utfURL &= 0
	$len=Int(StringLen($utfURL)/2)
	Dim $song[$len]
	For $i=0 To $len-1
		$song[$i]=Int('0x'&StringMid($utfURL,$i*2+1,2))
	Next
	Local $t1=0,$t2=0,$t3=0
	$t1=BitShift(BitAND($lrcid,0x0000FF00),8)
	If BitAND($lrcid,0x00FF0000)==0 Then
		$t3=BitAND(0x000000FF,BitNOT($t1))
	Else
		$t3=BitAND(0x000000FF,BitShift(BitAND($lrcid,0x00FF0000),16))
	EndIf
	$t3=BitOR($t3,BitShift(BitAND($lrcid,0x000000FF),-8))
	$t3=BitShift($t3,-8)
	$t3=BitOR($t3,BitAND($t1,0x000000FF))
	$t3=BitShift($t3,-8)
	If BitAND($lrcid,0xFF000000)==0 Then
		$t3=BitOR($t3,BitAND(0x000000FF,BitNOT($lrcid)))
	Else
		$t3=BitOR($t3,BitAND(0x000000FF,BitShift($lrcid,24)))
	EndIf
	$j=$len-1
	While $j>=0
		$c=$song[$j]
		If $c>=0x80 Then $c=$c-0x100
		$t1=BitAND($c+$t2,0xFFFFFFFF)
		$t2=BitAND(BitShift($t2,-(Mod($j,2)+4)),0xFFFFFFFF)
		$t2=BitAND($t1+$t2,0xFFFFFFFF)
		$j-=1
	WEnd
	$j=0
	$t1=0
	While $j<=$len-1
		$c=$song[$j]
		If $c>=128 Then $c-=256
		$t4=BitAND($c+$t1,0xFFFFFFFF)
		$t1=BitAND(BitShift($t1,-(Mod($j,2)+3)),0xFFFFFFFF)
		$t1=BitAND($t1+$t4,0xFFFFFFFF)
		$j+=1
	WEnd
	$t5=_Conv(BitXOR($t2,$t3))
	$t5=_Conv($t5+BitOR($t1,$lrcid))
	$t5=_Conv($t5*BitOR($t1,$t3))
	$t5=_Conv($t5*BitXOR($t2,$lrcid))
	$t6=$t5
	If $t6>2147483648 Then $t5=$t6-4294967296
	$url2='/dll/lyricsvr.dll?dl?Id='&String($lrcid)&'&Code='&String($t5)
    Return $url&'|'&$url2&'|1'&'||||'
EndFunc
; #FUNCTION# ;===============================================================================
; Name...........: _LrcList_mini
; Description ...: 获取迷你歌词搜索结果
; Syntax.........: _LrcList_mini ($artist, $title)
; Parameters ....: $artist - 歌手
;                  $title - 歌名
; Return values .: Success - Returns 包含搜索结果的数组
;                  Failure - Returns 0 没有搜索到结果
;                                   -1 联网错误
; Author ........: flashlab
; Modified.......:
; Remarks .......: 歌名参数不能为空
; Related .......:
; Link ..........:
; Example .......:
;============================================================================================
Func _LrcList_mini($a,$t,$xml='')
   Local $check, $head, $result, $total=0, $ta='',$x=''
   If Not $xml Then
        $xml = "<?xml version=""1.0"" encoding='utf-8'?>" & _
        @CRLF & StringFormat("<search artist=""%s"" title=""%s"" ",_clear($a),_clear($t)) & _
        'ProtoVer="0.9" client="MiniLyrics 7.0.676 for Windows Media Player" ClientCharEncoding="gb2312"/>' & @CRLF
        $xml=StringToBinary($xml,4)
        For $i = 1 To BinaryLen($xml)
	        $total+=Dec(StringTrimLeft(BinaryMid($xml,$i,1),2))
        Next
        $head=Int($total/BinaryLen($xml))
        For $i = 1 To BinaryLen($xml)
	        $ta&=Hex(BitXOR(BinaryMid($xml,$i,1),$head),2)
        Next
        $request = StringFormat('0x02%s04000000%s',Hex($head,2),StringTrimLeft(_hash($xml),2)&$ta)
		Local $send = 'search.crintsoft.com|/searchlyrics.htm|2|MiniLyrics|POST|'&$request&'|'
        If _CoProcSend($load_Pro, $send) Then

	    Else
	    	 _ToolTip('错误', "Worker not Responding (" & @error & ")", 3,3)
		EndIf
		Return
   Else
        $check=BinaryMid($xml,2,1)
        For $i = 1 To (BinaryLen($xml)-22)
	       $x&=Hex(BitXOR($check,BinaryMid($xml,$i+22,1)),2)
	    Next
        $result = BinaryToString(Binary('0x'& $x),4)
        Return _xmlPrase_mini($result)
	EndIf
EndFunc
; #FUNCTION# ;===============================================================================
; Name...........: _LrcList_kuwo
; Description ...: 获取酷我音乐搜索结果
; Syntax.........: _LrcList_kuwo ($artist, $title)
; Parameters ....: $artist - 歌手
;                  $title - 歌名
; Return values .: Success - Returns 包含搜索结果的数组
;                  Failure - Returns 0 没有搜索到结果
;                                   -1 联网错误
; Author ........: flashlab
; Modified.......:
; Remarks .......: 歌名参数不能为空
; Related .......:
; Link ..........:
; Example .......:
;============================================================================================
Func _LrcList_kuwo($a,$t,$xml='')
	Local $i=0
	If Not $xml Then
	    $a=StringReplace(_UrlToHex(_clear($a),1,'ansi'),'%20','+')
	    $t=StringReplace(_UrlToHex(_clear($t),1,'ansi'),'%20','+')
		Local $send = 'search.koowo.com|' & _
		StringFormat('/r.s?client=kowoo&Name=&Artist=%s&SongName=%s&Sig1=&Sig2=&Provider=&ft=lyric',$a,$t)&'|0||||'
        If _CoProcSend($load_Pro, $send) Then

	    Else
	    	 _ToolTip('错误', "Worker not Responding (" & @error & ")", 3,3)
		EndIf
		Return
	Else
	    $show = StringRegExp($xml,'(?m)(?i)^show=(\d+)',3,1)
	    If Not IsArray($show) Then Return _ToolTip("提示","没有在酷我搜索到歌词或其他错误", 3,3)
	    If Not Number($show[0])>0 Then Return _ToolTip("抱歉","没有在酷我搜索到歌词", 3,1)
	    $ini=StringStripWS(BinaryToString($xml),3)
	    Do
	    	$ini=StringReplace($ini,@CRLF&@CRLF,@CRLF&'['&$i&']'&@CRLF,1)
	    	$i+=1
	    Until @extended=0
	    Local $list[$i-1][3]
	    $kfile = FileOpen(@TempDir&'\temp_kuwo.ini',10)
	    FileWrite($kfile,$ini)
	    For $j = 0 To $i-2
	    	$list[$j][0]=IniRead(@TempDir&'\temp_kuwo.ini', $j, "PATH", "")
	    	$list[$j][1]=IniRead(@TempDir&'\temp_kuwo.ini', $j, "ARTIST", "")
	    	$list[$j][2]=IniRead(@TempDir&'\temp_kuwo.ini', $j, "SONGNAME", "")
	    Next
	    FileClose($kfile)
	    FileDelete(@TempDir&'\temp_kuwo.ini')
	    Return $list
	EndIf
EndFunc
; #FUNCTION# ;===============================================================================
; Name...........: _LrcDownLoad_kuwo
; Description ...: 下载酷我歌词
; Syntax.........: _LrcDownLoad_kuwo ($PATH, $artist, $title)
; Parameters ....: $PATH - 从_LrcList_kuwo()获得
;                  $artist - 歌手
;                  $title - 歌名
; Return values .: Success - Returns lrc歌词以及专辑、MTV封面图片路径
;                  Failure - Returns ''
; Author ........: flashlab
; Modified.......:
; Remarks .......: 所有参数均不能为空
; Related .......:
; Link ..........:
; Example .......:
;============================================================================================
Func _LrcDownLoad_kuwo($zip)
	Local $kfile, $folderName,$zipDir,$p=0, $bit_filename,$pk_ptr,$pre_unc
	Local $cut_pos = StringInStr($zip,'504B',0,1,1)
	$zip=BinaryMid($zip,($cut_pos-1)/2)
    $zipDir=BinaryMid($zip, _SwapEndian(BinaryMid($zip, BinaryLen($zip)-5, 4))+1, _SwapEndian(BinaryMid($zip, BinaryLen($zip)-9, 4)))
    While 1
    	$p=(StringInStr($zipDir,'504B0102',0, 1, $p*2+2)-1)/2
    	If @error Then ExitLoop
    	$bit_filename=_SwapEndian(BinaryMid($zipDir, $p+28,2))
        If StringInStr(BinaryMid($zipDir, $p+46, $bit_filename), '2E6C7263') Then ExitLoop
    WEnd
    $pk_ptr=_SwapEndian(BinaryMid($zipDir, $p+42,4))
    $pre_unc=binary('0x78DA')&BinaryMid($zip, $pk_ptr+31+$bit_filename+_SwapEndian(BinaryMid($zip, $pk_ptr+29,2)), _SwapEndian(BinaryMid($zip, $pk_ptr+19,4)))
    Return BinaryToString(_ZLIB_Uncompress($pre_unc))
EndFunc

; #FUNCTION# ;===============================================================================
; Name...........: _LrcDownLoad_baidu
; Description ...: 获取百度音乐盒歌词
; Syntax.........: _LrcList_baidu ($artist, $title)
; Parameters ....: $artist - 歌手
;                  $title - 歌名
; Return values .: Success - Returns 包含搜索结果的数组
;                  Failure - Returns 0 没有搜索到结果
;                                   -1 联网错误
; Author ........: flashlab
; Modified.......:
; Remarks .......: 歌名参数不能为空
; Related .......:
; Link ..........:
; Example .......:
;============================================================================================
Func _LrcDownLoad_baidu($a,$t,$xml="")
	Local $send
	If Not $xml Then
	    $send='box.zhangmen.baidu.com|'&StringFormat($list_baidu,_UrlToHex(_clear($t,False),1,'ansi'),_UrlToHex(_clear($a,False),1,'ansi'))&'|0||||'
	    If _CoProcSend($load_Pro, $send) Then

	    Else
			_ToolTip('错误', "Worker not Responding (" & @error & ")", 3,3)
		EndIf
	Else
	    $xml=_ClearXml($xml)
	    $LrcId=StringRegExp($xml,'<lrcid>(\d+)</lrcid>',3,1)
	    If Not @error Then
            $DownLink='box.zhangmen.baidu.com|'&'/bdlrc/'&Int(Number($LrcId[0])/100)&'/'&$LrcId[0]&'.lrc'&'|0||||'
;~ 			ClipPut($DownLink)
			$load_flag=0
	        If _CoProcSend($load_Pro, $DownLink) Then

	        Else
		    	_ToolTip('错误', "Worker not Responding (" & @error & ")", 3,3)
		    EndIf
	    	Return
	    Else
		    _ExitLoading()
	    	Return _ToolTip("抱歉","没有在百度音乐搜索到歌词", 3,1)
	    EndIf
	EndIf
EndFunc
; #FUNCTION# ;===============================================================================
; Name...........: _LrcList_ilrc
; Description ...: 获取9ilrc搜索结果
; Syntax.........: _LrcList_ilrc($key,$ki)
; Parameters ....: $key - 关键词
;                  $ki - 关键词类别
; Return values .: Success - Returns 包含搜索结果的数组
;                            |$i_url[][0] - url
;                            |$i_url[][1] - artist
;                            |$i_url[][2] - title
;                            |$i_url[][3] - album
;                  Failure - Returns 0 没有搜索到结果
;                                   -1 联网错误
; Author ........: flashlab
; Modified.......:
; Remarks .......: 歌名参数不能为空；关键词类别可以是 歌名--1 专辑--2
; Related .......:
; Link ..........:
; Example .......:
;============================================================================================
Func _LrcList_ilrc($key,$ki=1, $xml='')
	Local $send, $temp1,$temp2,$temp3,$temp4,$tem='',$i_url,$p_url,$tt=0
	If Not $xml Then
	    If $ki=1 Then
	       $send = 'www.9ilrc.com|/search.php?keyword='&_UrlToHex(_clear($key,False),1,'unicode')&'&radio=song'&'|1||||'
	    Else
		   $send = 'www.9ilrc.com|/search.php?keyword='&_UrlToHex(_clear($key,False),1,'unicode')&'&radio=album'&'|1||||'
	    EndIf
		If _CoProcSend($load_Pro, $send) Then

	    Else
	    	 _ToolTip('错误', "Worker not Responding (" & @error & ")", 3,3)
		EndIf
		Return
    Else
	    $temp1 = StringRegExp(StringRegExpReplace($xml,'\r?\n',''),'<tr>(?=\<td)(.*?)(?<=td\>)</tr>',3,1)
	    If Not @error Then
	    	Dim $i_url[UBound($temp1)][4]
	    	For $i=0 To UBound($temp1)-1
	    		$temp3 = StringRegExp($temp1[$i],'href="(lrc.php.*?)"',3,1)
	    		If @error Then ContinueLoop
	    		$temp1[$i]=StringReplace($temp1[$i],'</td>','%%')
	    		$temp2=StringSplit(StringRegExpReplace($temp1[$i],'<[^>]+>',''),'%%',1+2)
	    		$p_url=StringSplit($temp3[0]&'|'&$temp2[2]&'|'&$temp2[0]&'|'&$temp2[1],'|',2)
	    		For $j=0 To 3
	    			$i_url[$i][$j]=$p_url[$j]
	    		Next
				$tt+=1
	    	Next
			ReDim $i_url[$tt][4]
	    	Return $i_url
	    Else
	    	Return _ToolTip("抱歉","没有在9ilrc搜索到歌词", 3,1)
	    EndIf
	EndIf
EndFunc

; #FUNCTION# ;===============================================================================
; Name...........: _LrcList_qq
; Description ...: 获取QQ音乐歌词
; Syntax.........: _LrcList_qq ($artist, $title)
; Parameters ....: $artist - 歌手
;                  $title - 歌名
; Return values .: Success - Returns 包含搜索结果的数组
;                  Failure - Returns 0 没有搜索到结果
;                                   -1 联网错误
; Author ........: flashlab
; Modified.......:
; Remarks .......: 歌名参数不能为空
; Related .......:
; Link ..........:
; Example .......:
;============================================================================================
Func _LrcList_qq($a,$t,$xml="")
	Local $send
	If Not $xml Then
	    $send='qqmusic.qq.com|'&StringFormat($list_qq,_UrlToHex(_clear($t,False),1,'ansi'),_UrlToHex(_clear($a,False),1,'ansi'))&'|0||||'
	    If _CoProcSend($load_Pro, $send) Then

	    Else
			_ToolTip('错误', "Worker not Responding (" & @error & ")", 3,3)
		EndIf
	Else
	    $xml=_ClearXml($xml)
		$xml = StringRegExpReplace($xml,'\v','')
		Dim $total = StringRegExp($xml,'<songcount>(\d+)<\/songcount>',3,1)
		If @error Then Return SetError(2)
		If $total[0]=0 Then Return _ToolTip("抱歉","没有在QQ音乐搜索到歌词", 3,1)
		Dim $songinfo=StringRegExp($xml,'<songinfo\sid="(\d+)"[^>]*?>(.*?)<\/songinfo>',3,1)
		If @error Then Return SetError(2)
		If UBound($songinfo)/2>=$total[0] Then
			Dim $qq_info[UBound($songinfo)/2][3]
			For $i = 0 To UBound($songinfo)/2-1
				$qq_info[$i][0]=$songinfo[$i*2]
				$qq_detail=StringRegExp($songinfo[$i*2+1],'!\[CDATA\[([^]]+)\]\]',3,1)
				$qq_info[$i][1]=$qq_detail[1]
				$qq_info[$i][2]=$qq_detail[0]
			Next
			Return $qq_info
		Else
			Return SetError(2)
		EndIf
	EndIf
EndFunc

Func _load_()
	Opt("TrayIconHide", 1)
	Global $info[1]=['net']
	Local $hOpen, $hConnect, $hRequest, $hProxy=False, $ProxyServer, $sReturned, $ProcessAddy, $net=0, $ret = '',$ping=''
	Local $timeout=7000, $ttl=255, $count=0, $pingID, $status
	Global $Addr[8] = ["ttlrcct.qianqian.com","search.koowo.com","newlyric.koowo.com","search.crintsoft.com","viewlyrics.com","box.zhangmen.baidu.com","www.9ilrc.com","qqmusic.qq.com"]
	Global Const $tagWINHTTP_PROXY_INFO = "DWORD  dwAccessType;ptr lpszProxy;ptr lpszProxyBypass;"
	Global Const $DONT_FRAGMENT = 2, $IP_SUCCESS = 0, $IP_DEST_NET_UNREACHABLE = 11002, $IP_DEST_HOST_UNREACHABLE = 11003, $IP_DEST_PROT_UNREACHABLE = 11004, $IP_DEST_PORT_UNREACHABLE = 11005, _
    $IP_NO_RESOURCES = 11006, $IP_HW_ERROR = 11008, $IP_PACKET_TOO_BIG = 11009, $IP_REQ_TIMED_OUT = 11010, $IP_BAD_REQ = 11011, $IP_BAD_ROUTE = 11012, _
    $IP_TTL_EXPIRED_TRANSIT = 11013, $IP_TTL_EXPIRED_REASSEM = 11014, $IP_PARAM_PROBLEM = 11015, $IP_SOURCE_QUENCH = 11016, $IP_BAD_DESTINATION =11018, _
    $IP_GENERAL_FAILURE = 11050, $NO_STATUS = 10000     ;We will use 10000 as the no status indicator since 0 meens successful reply
    Global $hkernel32Dll = DllOpen("kernel32.dll")
    Global $hKrn = _WinAPI_GetModuleHandle("kernel32.dll")
	Local $LibHandle = DllCall($hkernel32Dll, "int", "LoadLibraryA", "str", "ICMP.dll")
    Global $hICMPDll =  $LibHandle[0]
    Local $hPointers = DllStructCreate("ptr IcmpCloseHandle;ptr IcmpSendEcho;ptr IcmpCreateFile;ptr ExitThread")
	$ProcessAddy = DllCall($hkernel32Dll,"int","GetProcAddress","int",$hKrn,"str","ExitThread")
    DllStructSetData($hPointers,"ExitThread",$ProcessAddy[0])
	$ProcessAddy = DllCall($hkernel32Dll,"int","GetProcAddress","int",$hICMPDll,"str","IcmpCloseHandle")
    DllStructSetData($hPointers,"IcmpCloseHandle",$ProcessAddy[0])
	$ProcessAddy = DllCall($hkernel32Dll,"int","GetProcAddress","int",$hICMPDll,"str","IcmpSendEcho")
    DllStructSetData($hPointers,"IcmpSendEcho",$ProcessAddy[0])
	$ProcessAddy = DllCall($hkernel32Dll,"int","GetProcAddress","int",$hICMPDll,"str","IcmpCreateFile")
    DllStructSetData($hPointers,"IcmpCreateFile",$ProcessAddy[0])
    TCPStartup()
	_CoProcReciver ("_loadReciver")
	While 1
		Sleep(100)
        $count+=1
		If $count>=30 Then
			$count=0
            _CoProcSend ($gi_CoProcParent, Binary("0x22")&StringToBinary(_GetProcessMemory($gi_CoProcParent)))
			_ReduceMemory(@AutoItPID)
			ContinueLoop
		EndIf
		If Not ProcessExists($gi_CoProcParent) Then ExitLoop
		If Not IsArray($info) Then ContinueLoop
		If $info[0] = 'net' Then
            If _WinAPI_GetVersion() < '6.0' Then
			    $sReturned = Binary('0x21') & StringToBinary(Ping("qq.com",500))
			Else
                $sReturned = Binary('0x21') & StringToBinary(_WinAPI_IsInternetConnected())
			EndIf
		    Local $iproxy = IniRead(@ScriptDir&'\config.ini', "server", "proxy", "0")
            StringRegExp($iproxy, '^(\d{1,2}|1\d\d|2[0-4]\d|25[0-5])\.(\d{1,2}|1\d\d|2[0-4]\d|25[0-5])\.(\d{1,2}|1\d\d|2[0-4]\d|25[0-5])\.(\d{1,2}|1\d\d|2[0-4]\d|25[0-5])\:\d+$', 3, 1)
            If Not @error Then
				$hProxy=True
				$ProxyServer=$iproxy
			EndIf
		ElseIf $info[0] = 'exit' Then
			ExitLoop
		ElseIf $info[0] = 'ping' Then
			Dim $PingBack[8], $pings[1]  = [0]
			$Addr[0]=_Iif($info[1],'ttlrccnc.qianqian.com','ttlrcct.qianqian.com')
            For $i= 0 To 7
            	Local $data=_StringRepeat("x",$i+1)
            	Local $hexIP = encodeIP($Addr[$i])
            	If $hexIP == 0 Then ContinueLoop
            	$pings[0] = UBound($pings)
                ReDim $pings[$pings[0]+1]
                $pings[$pings[0]] = DllStructCreate("char ip[" & StringLen($Addr[$i]) & "];ulong reply;ulong status;int datasize");You could add a timeout struct here
                DllStructSetData($pings[$pings[0]],"ip",$Addr[$i])
                DllStructSetData($pings[$pings[0]],"status",$NO_STATUS)
            	$pingID = $pings[0]
            	DllStructSetData($pings[$pingID],"datasize",StringLen($data))
                Local $CodeBuffer = DllStructCreate("byte[696]"); Code=154, Data=256, Echo reply Struct + ICMP_OPTIONS Struct = 286
                Local $RemoteCode = _MemVirtualAlloc(0, DllStructGetSize($CodeBuffer), $MEM_COMMIT, $PAGE_EXECUTE_READWRITE)
                DllStructSetData($CodeBuffer, 1, _
                    "0x" & _                                                            ;Original Assembly started at 401000
                    "E889000000" & _                                                ;Call 0040108E  <IcmpCreateFile>
                    "A3" & SwapEndian($RemoteCode + 410) & _                            ;mov dword ptr [00403010], eax  <hIcmp = IcmpCreateFile Handle>
                    "C605" & SwapEndian($RemoteCode + 418) & Hex($ttl,2) & _            ;mov byte ptr [00403024], xx    <TTL>
                    "C605" & SwapEndian($RemoteCode + 419) & "00" & _                                   ;mov byte ptr [00403025], 00    <TOS>
                    "C605" & SwapEndian($RemoteCode + 420) & Hex(0,2) & _          ;mov byte ptr [00403026], 02    <Flags, 0x02=DF Bit Set>
                    "C605" & SwapEndian($RemoteCode + 421) & "00" & _                   ;mov byte ptr [00403027], 00
                    "C705" & SwapEndian($RemoteCode + 422) & "00000000" & _         ;mov dword ptr [00403028], 00000000
                    "68" & SwapEndian(Dec(Hex($timeout,4))) & _                                 ;push 0000xxxx  <Timeout>
                    "681E010000" & _                                                ;push 0000011E  <Size of Echo reply Struct + ICMP_OPTIONS Struct>
                    "68" & SwapEndian($RemoteCode + 426) & _                            ;push 0040302C  <icmpReply>
                    "68" & SwapEndian($RemoteCode + 418) & _                            ;push 00403024  <icmpOptions>
                    "6A" & Hex(StringLen($data),2) & _                                  ;push 000000xx  <Data Size>
                    "68" & SwapEndian($RemoteCode + 154) & _                            ;push 00403000  <Data>
                    "68" & SwapEndian(Dec($hexIP)) & _                              ;push <Hex(IP ADDRESS)>
                    "FF35" & SwapEndian($RemoteCode + 410) & _                      ;push dword ptr [00403010]  <hIcmp>
                    "E839000000" & _                                                ;Call 00401094  <IcmpSendEcho>
                    "A1" & SwapEndian($RemoteCode + 434) & _                            ;mov eax, dword ptr [00403034]  <Get the ms responce time from icmpReply.RoundTripTime>
                    "A3" & SwapEndian(DllStructGetPtr($pings[$pingID],"reply")) & _         ;mov dword ptr [0040301C], eax  <Store the ms responce time>
                    "A1" & SwapEndian($RemoteCode + 430) & _                            ;mov eax, dword ptr [00403030]  <Get the status from icmpReply.Status>
                    "A3" & SwapEndian(DllStructGetPtr($pings[$pingID],"status")) & _        ;mov dword ptr [00403020], eax  <Store the status>
                    "FF35" & SwapEndian($RemoteCode + 410) & _                      ;push dword ptr [00403010]  <hIcmp>
                    "E80E000000" & _                                                ;Call 00401088  <IcmpCloseHandle>
                    "6A00" & _                                                      ;push 00000000
                    "E801000000" & _                                                ;Call 00401082  <ExitThread>
                    "CC" & _                                                            ;int 03
                    "FF25" & SwapEndian(DllStructGetPtr($hPointers,"ExitThread")) & _       ;JMP dword ptr  <kernel32.ExitThread>
                    "FF25" & SwapEndian(DllStructGetPtr($hPointers,"IcmpCloseHandle")) & _  ;JMP dword ptr  <ICMP.IcmpCloseHandle>
                    "FF25" & SwapEndian(DllStructGetPtr($hPointers,"IcmpCreateFile")) & _   ;JMP dword ptr  <ICMP.IcmpCreateFile>
                    "FF25" & SwapEndian(DllStructGetPtr($hPointers,"IcmpSendEcho"))& _  ;JMP dword ptr  <ICMP.IcmpSendEcho>
                    SwapEndian(StringToBinary($data)) _                             ;This is our ping Data, Max 256 bytes of space here.
                )
                _MemMoveMemory(DllStructGetPtr($CodeBuffer), $RemoteCode, DllStructGetSize($CodeBuffer))
                Local $aCall = DllCall($hkernel32Dll, "ptr", "CreateThread", "ptr", 0, "int", 0, "ptr", $RemoteCode, "ptr", 0, "int", 0, "dword*", 0)
            Next
            	Local $s=TimerInit()
            While 1
            	If TimerDiff($s)>=6000 Then
            	    ExitLoop
                EndIf
            	$pingID=1
            	While $pingID <= $pings[0]
            		$status = DllStructGetData($pings[$pingID],"status")
            			If $status <> $NO_STATUS Then
                        Switch $status
                            Case $IP_SUCCESS
                                If DllStructGetData($pings[$pingID],"reply") = 0 Then
									$PingBack[Number(DllStructGetData($pings[$pingID],"datasize"))-1]=1
;~                                     ConsoleWrite("Ping with " & DllStructGetData($pings[$pingID],"datasize") & " byte(s) to " & DllStructGetData($pings[$pingID],"ip") & " replied in <1ms" & @CRLF)
                                Else
            ;~                         ConsoleWrite("Ping with " & DllStructGetData($pings[$pingID],"datasize") & " byte(s) to " & DllStructGetData($pings[$pingID],"ip") & " replied in " & DllStructGetData($pings[$pingID],"reply") & "ms" & @CRLF)
									$PingBack[Number(DllStructGetData($pings[$pingID],"datasize"))-1]=DllStructGetData($pings[$pingID],"reply")
                                EndIf
                            Case $IP_REQ_TIMED_OUT
								$PingBack[Number(DllStructGetData($pings[$pingID],"datasize"))-1]=-1
;~                                 ConsoleWrite("Ping with " & DllStructGetData($pings[$pingID],"datasize") & " byte(s) to " & DllStructGetData($pings[$pingID],"ip") & " timed-out" & @CRLF)
                            Case $IP_DEST_NET_UNREACHABLE
;~                                 ConsoleWrite("Ping with " & DllStructGetData($pings[$pingID],"datasize") & " byte(s) to " & DllStructGetData($pings[$pingID],"ip") & " The destination network was unreachable." & @CRLF)
                            Case $IP_DEST_HOST_UNREACHABLE
;~                                 ConsoleWrite("Ping with " & DllStructGetData($pings[$pingID],"datasize") & " byte(s) to " & DllStructGetData($pings[$pingID],"ip") & " The destination host was unreachable." & @CRLF)
                            Case $IP_DEST_PROT_UNREACHABLE
;~                                 ConsoleWrite("Ping with " & DllStructGetData($pings[$pingID],"datasize") & " byte(s) to " & DllStructGetData($pings[$pingID],"ip") & " The destination protocol was unreachable." & @CRLF)
                            Case $IP_DEST_PORT_UNREACHABLE
;~                                 ConsoleWrite("Ping with " & DllStructGetData($pings[$pingID],"datasize") & " byte(s) to " & DllStructGetData($pings[$pingID],"ip") & " The destination port was unreachable." & @CRLF)
                            Case $IP_NO_RESOURCES
;~                                 ConsoleWrite("Ping with " & DllStructGetData($pings[$pingID],"datasize") & " byte(s) to " & DllStructGetData($pings[$pingID],"ip") & " Insufficient IP resources were available." & @CRLF)
                            Case $IP_HW_ERROR
;~                                 ConsoleWrite("Ping with " & DllStructGetData($pings[$pingID],"datasize") & " byte(s) to " & DllStructGetData($pings[$pingID],"ip") & " A hardware error occurred." & @CRLF)
                            Case $IP_PACKET_TOO_BIG
;~                                 ConsoleWrite("Ping with " & DllStructGetData($pings[$pingID],"datasize") & " byte(s) to " & DllStructGetData($pings[$pingID],"ip") & " The packet was too big." & @CRLF)
                            Case $IP_BAD_REQ
;~                                 ConsoleWrite("Ping with " & DllStructGetData($pings[$pingID],"datasize") & " byte(s) to " & DllStructGetData($pings[$pingID],"ip") & " A bad request." & @CRLF)
                            Case $IP_BAD_ROUTE
;~                                 ConsoleWrite("Ping with " & DllStructGetData($pings[$pingID],"datasize") & " byte(s) to " & DllStructGetData($pings[$pingID],"ip") & " A bad route." & @CRLF)
                            Case $IP_TTL_EXPIRED_TRANSIT
;~                                 ConsoleWrite("Ping with " & DllStructGetData($pings[$pingID],"datasize") & " byte(s) to " & DllStructGetData($pings[$pingID],"ip") & " The time to live (TTL) expired in transit." & @CRLF)
                            Case $IP_TTL_EXPIRED_REASSEM
;~                                 ConsoleWrite("Ping with " & DllStructGetData($pings[$pingID],"datasize") & " byte(s) to " & DllStructGetData($pings[$pingID],"ip") & " The time to live expired during fragment reassembly." & @CRLF)
                            Case $IP_PARAM_PROBLEM
;~                                 ConsoleWrite("Ping with " & DllStructGetData($pings[$pingID],"datasize") & " byte(s) to " & DllStructGetData($pings[$pingID],"ip") & " A parameter problem." & @CRLF)
                            Case $IP_SOURCE_QUENCH
;~                                 ConsoleWrite("Ping with " & DllStructGetData($pings[$pingID],"datasize") & " byte(s) to " & DllStructGetData($pings[$pingID],"ip") & " Datagrams are arriving too fast to be processed and datagrams may have been discarded." & @CRLF)
                            Case $IP_BAD_DESTINATION
;~                                 ConsoleWrite("Ping with " & DllStructGetData($pings[$pingID],"datasize") & " byte(s) to " & DllStructGetData($pings[$pingID],"ip") & " A bad destination." & @CRLF)
                            Case $IP_GENERAL_FAILURE
;~                                 ConsoleWrite("Ping with " & DllStructGetData($pings[$pingID],"datasize") & " byte(s) to " & DllStructGetData($pings[$pingID],"ip") & " A general failure. This error can be returned for some malformed ICMP packets or lost network connection." & @CRLF)
            			EndSwitch
            			If $pingID <= $pings[0] Then ;Ensure our ID is valid
                            $pings[$pingID] = 0 ;Free the DLLStruct
                            _ArrayDelete($pings,$pingID)
                            $pings[0] -= 1
            			EndIf
                    EndIf
            		$pingID += 1
            	WEnd
            WEnd
			$sReturned = BinaryMid(Binary('0x23'),1) & StringToBinary(_ArrayToString($PingBack, '|'))
		ElseIf $info[0] = 'proxy' Then
			If $info[1] Then
				$hProxy=True
				$ProxyServer=$info[1]
			Else
				$hProxy=False
			EndIf
			ContinueLoop
		Else
;~ 			Local $hWINHTTP_STATUS_CALLBACK = DllCallbackRegister("__WINHTTP_STATUS_CALLBACK", "none", "handle;dword_ptr;dword;ptr;dword")
	        If $info[3]='' Then
                $hOpen = _WinHttpOpen()
	        Else
	        	$hOpen = _WinHttpOpen($info[3])
	        EndIf
 			_WinHttpSetTimeouts($hOpen,2000)
;~ 			_WinHttpSetStatusCallback($hOpen, $hWINHTTP_STATUS_CALLBACK)
			If $hProxy Then
            Local $tProxyInfo[2] = [DllStructCreate($tagWINHTTP_PROXY_INFO), _
	        DllStructCreate('wchar proxychars[' & StringLen($ProxyServer)+1 & ']; wchar proxybypasschars[' & StringLen("localhost")+1 & ']')]
			DllStructSetData($tProxyInfo[0], "dwAccessType", $WINHTTP_ACCESS_TYPE_NAMED_PROXY)
			If StringLen($ProxyServer) Then DllStructSetData($tProxyInfo[0], "lpszProxy", DllStructGetPtr($tProxyInfo[1], 'proxychars'))
			If StringLen("localhost") Then DllStructSetData($tProxyInfo[0], "lpszProxyBypass", DllStructGetPtr($tProxyInfo[1], 'proxybypasschars'))
			DllStructSetData($tProxyInfo[1], "proxychars", $ProxyServer)
			DllStructSetData($tProxyInfo[1], "proxybypasschars", "localhost")
                _WinHttpSetOption($hOpen, $WINHTTP_OPTION_PROXY, $tProxyInfo[0])
                $hConnect = _WinHttpConnect($hOpen, $info[0])
			    _WinHttpSetOption($hConnect, $WINHTTP_OPTION_PROXY_USERNAME, "usrname")
                _WinHttpSetOption($hConnect, $WINHTTP_OPTION_PROXY_PASSWORD, "passwd")
			    $hRequest = _WinHttpOpenRequest($hConnect, $info[4], $info[1])
				_WinHttpSetCredentials($hRequest, $WINHTTP_AUTH_TARGET_PROXY, $WINHTTP_AUTH_SCHEME_BASIC, "usrname", "passwd")
			Else
				$hConnect = _WinHttpConnect($hOpen, $info[0])
				$hRequest = _WinHttpOpenRequest($hConnect, $info[4], $info[1], 'HTTP/1.1', $info[6])
			EndIf
			If _WinHttpSendRequest($hRequest, Default,$info[5]) Then
				_WinHttpReceiveResponse($hRequest)
				If $info[2]=2 Then
					$sReturned=_WinHttpSimpleReadData($hRequest,2)
				Else
					$sReturned = StringToBinary(_WinHttpSimpleReadData($hRequest,Number($info[2])))
				EndIf
			Else
				$sReturned=''
			EndIf
			_WinHttpCloseHandle($hRequest)
            _WinHttpCloseHandle($hConnect)
            _WinHttpCloseHandle($hOpen)
;~ 			DllCallbackFree($hWINHTTP_STATUS_CALLBACK)
		EndIf
;~ 		Sleep(100)              ;~~~~~~~~~~~~~~~~~~~~~~~~避免下载过快引起程序异常
        If $sReturned='' Then $sReturned=Binary('0x24')
;~ 		ToolTip(BinaryToString($sReturned))
		_CoProcSend ($gi_CoProcParent, $sReturned)
        $info = ''
	WEnd
	TCPShutdown()
    DllCall($hkernel32Dll, "int", "FreeLibrary", "int", $hICMPDll)
    DllClose($hkernel32Dll)
EndFunc

Func _loadReciver($vParameter)
	Dim $info = StringSplit($vParameter,"|",2)
EndFunc   ;==>_loadReciver

Func _GetProcessMemory($iPid, $NFormat = 1)
	;afan提示：默认返回以千位逗号分割的内存占用KB值；$NFormat 参数为0则返回字节数
	Local $Data = _WinAPI_GetProcessMemoryInfo($iPid)
	If Not IsArray($Data) Then Return SetError(1, '', '')
	If Not $NFormat Then Return $Data[2]
	Return StringRegExpReplace($Data[2] / 1024, '(\d+?)(?=(?:\d{3})+\Z)', '$1,') & ' (K)'
EndFunc   ;==>_GetProcessMemory

;~ Func _WinHttpProxyInfoCreate($dwAccessType, $sProxy, $sProxyBypass)
;~     Local $tWINHTTP_PROXY_INFO[2] = [DllStructCreate($tagWINHTTP_PROXY_INFO), DllStructCreate('wchar proxychars[' & StringLen($sProxy)+1 & ']; wchar proxybypasschars[' & StringLen($sProxyBypass)+1 & ']')]
;~     DllStructSetData($tWINHTTP_PROXY_INFO[0], "dwAccessType", $dwAccessType)
;~     If StringLen($sProxy) Then DllStructSetData($tWINHTTP_PROXY_INFO[0], "lpszProxy", DllStructGetPtr($tWINHTTP_PROXY_INFO[1], 'proxychars'))
;~     If StringLen($sProxyByPass) Then DllStructSetData($tWINHTTP_PROXY_INFO[0], "lpszProxyBypass", DllStructGetPtr($tWINHTTP_PROXY_INFO[1], 'proxybypasschars'))
;~     DllStructSetData($tWINHTTP_PROXY_INFO[1], "proxychars", $sProxy)
;~     DllStructSetData($tWINHTTP_PROXY_INFO[1], "proxybypasschars", $sProxyBypass)
;~     Return $tWINHTTP_PROXY_INFO
;~ EndFunc

Func encodeIP($ip_addr)
    Local $ip_addr_temp = $ip_addr
    If Not _isIP($ip_addr) Then $ip_addr = TCPNameToIP($ip_addr)
        If Not _isIP($ip_addr) Then
        ConsoleWrite($ip_addr_temp & " is not a valid IP Address. If you supplied a hostname ensure DNS is available." & @CRLF)
        Return 0
    EndIf
    Return getHexIP($ip_addr)
EndFunc

Func getHexIP($ip_addr)
    Return Hex(_getIPOctet($ip_addr,4),2) & Hex(_getIPOctet($ip_addr,3),2) & Hex(_getIPOctet($ip_addr,2),2) & Hex(_getIPOctet($ip_addr,1),2)
EndFunc

Func SwapEndian($hex)
    ;trancexx
    Return Hex(Binary($hex))
EndFunc

Func _getIPOctet($ip_addr,$octet=1)
    Switch $octet
        Case 1
        Return Int(StringMid($ip_addr,1,StringInStr($ip_addr,".")))
    Case 4
        Return Int(StringMid($ip_addr,StringInStr($ip_addr,".",0,3)+1))
    Case Else
        Return Int(StringMid($ip_addr,StringInStr($ip_addr,".",0,$octet - 1)+1,StringInStr($ip_addr,".",0,$octet)+1))
    EndSwitch
EndFunc

Func _isIP($text)
    Return StringRegExp($text, "(((25[0-5])|(2[0-4][0-9])|(1[0-9][0-9])|([1-9]?[0-9]))\.){3}((25[0-5])|(2[0-4][0-9])|(1[0-9][0-9])|([1-9]?[0-9]))")
EndFunc

Func _chk_net()
	If _CoProcSend($load_Pro, 'net|') Then

    Else
	    _ToolTip('错误', "Worker not Responding (" & @error & ")", 3,3)
    EndIf
EndFunc

Func _ClearXml($x)
	$x=StringReplace($x,'&amp;','&')
	$x=StringReplace($x,'&apos;',"'")
	$x=StringReplace($x,'&quot;','"')
	$x=StringReplace($x,'&lt;','<')
	$x=StringReplace($x,'&gt;','>')
	Return $x
EndFunc

Func _UrlToHex($URL,$flag,$encode)   ;url编码
	Switch $encode
		Case 'unicode'
            $Binary = StringReplace(StringToBinary ($URL, 4), '0x', '', 1)
	    Case 'ansi'
	        $Binary=StringReplace(StringToBinary ($URL), '0x', '', 1)
	EndSwitch
    Local $EncodedString
    For $i = 1 To StringLen($Binary) Step 2
		$BinaryChar = StringMid($Binary, $i, 2)
		Switch $flag
		Case 0
			$EncodedString &= $BinaryChar
		Case 1
			If StringInStr("$-_.+!*'(),;/?:@=&abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890", BinaryToString ('0x' & $BinaryChar, 4)) Then
			    $EncodedString &= BinaryToString ('0x' & $BinaryChar)
			Else
			    $EncodedString &= '%'&$BinaryChar
			EndIf
		EndSwitch
    Next
    Return $EncodedString
EndFunc

Func _clear($s,$rm_space=True)   ;去掉提交内容的半全角字符
	$s=StringReplace($s,"'",'')
	$Bstr='`~!@#$%^&*()-+_=,<.>/?;:"[{]}\|�' & _
	'　。，、；：？！…—·ˉ¨‘’“”々～‖∶＂＇｀｜〃〔〕〈〉《》「」『』．〖〗【】（）［］｛｝' & _
	'≈≡≠＝≤≥＜＞≮≯∷±＋－×÷／∫∮∝∞∧∨∑∏∪∩∈∵∴⊥∥∠⌒⊙≌∽√' & _
	'§№☆★○●◎◇◆□℃‰■△▲※→←↑↓〓¤°＃＆＠＼︿＿￣―♂♀' & _
	'ⅠⅡⅢⅣⅤⅥⅦⅧⅨⅩⅪⅫ⒈⒉⒊⒋⒌⒍⒎⒏⒐⒑⒒⒓⒔⒕⒖⒗⒘⒙⒚⒛㈠㈡㈢㈣㈤㈥㈦㈧㈨㈩' & _
	'①②③④⑤⑥⑦⑧⑨⑩⑴⑵⑶⑷⑸⑹⑺⑻⑼⑽⑾⑿⒀⒁⒂⒃⒄⒅⒆⒇' & _
	'┌┍┎┏┐┑┒┓─┄┈└┕┖┗┘┙┚┛━┅┉├┝┞┟┠┡┢┣│┆┊┤┥┦┧┨┩┪┫┃┇┋' & _
	'┬┭┮┯┰┱┲┳┴┵┶┷┸┹┺┻┼┽┾┿╀╁╂╃╄╅╆╇╈╉╊╋'
	If $rm_space Then
		$Bstr&=' '
	EndIf
	For $i = 1 To StringLen($Bstr)
	   $s=StringReplace($s,StringMid($Bstr,$i,1),'')
    Next
    Return $s
EndFunc

Func _Conv($i)   ;一些转换
	$r=Mod($i,4294967296)
	If $i>=0 And $r > 2147483648 Then $r = $r - 4294967296
	If $i<0 And $r < 2147483648 Then $r = $r + 4294967296
	Return $r
EndFunc

Func _xmlPrase_mini($src)
	Local $temp,$tem,$te,$ii,$j=0
	Local $item='artist="(.*?)"|title="(.*?)"|album="(.*?)"|rate="(.*?)"|ratecount="(.*?)"'
	Local $_i=StringSplit($item,'|',2)
	$src=_ClearXml($src)
	$temp=StringRegExp($src,'(?m)<fileinfo.*?\/>',3,1)
	If @error Then Return _ToolTip("提示","没有在MiniLyrics搜索到歌词", 3,1)
	Local $list[UBound($temp)][6]
	For $i = 0 To UBound($temp)-1
		$tem=StringRegExp($temp[$i],'link="(.*?)"',3,1)
		If Not @error Then
			$list[$j][0]=$tem[0]
			For $ii = 0 To 4
				$te = StringRegExp($temp[$i],$_i[$ii],3,1)
				If Not @error Then
					$list[$j][$ii+1]=$te[0]
				Else
					$list[$j][$ii+1]=''
				EndIf
			Next
			$j+=1
		Else
;~ 			MsgBox(0,'',$i)
		EndIf
	Next
	Return $list
EndFunc

Func _SwapEndian($_h)
	Local $rh=Binary(''),$i=0
	For $i=BinaryLen($_h) To 1 Step -1
        $rh&=BinaryMid($_h,$i,1)
	Next
	Return Dec(StringTrimLeft($rh, 2))
EndFunc;==>SwapEndian

Func _hash($x)
   Local $MD5CTX = _MD5Init()
   _MD5Input($MD5CTX, $x)
   _MD5Input($MD5CTX, "Mlv1clt4.0")
   Return _MD5Result($MD5CTX)
EndFunc

Func _encode($var1,$key='yeelion')
	Local $k3 = $var1
	Dim $var2[1]
    $temp=StringToBinary($k3)
    For $i = 1 To BinaryLen($temp)
		_ArrayAdd($var2,BitXOR(BinaryMid($temp,$i,1),Asc(StringMid($key, Mod($i-1,7)+1, 1))))
	Next
		_ArrayDelete($var2, 0)
		Return(_secode($var2))
EndFunc

Func _secode($opArray)
    If IsArray($opArray) Then
        Local $k2=$opArray,$decout[1]
		Local $k3='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
		Local $bits, $strEnd='=', $k1=0, $j=0, $site=16515072
		While $k1<UBound($k2)
		Switch UBound($k2)-$k1
			Case 3
				$strEnd=''
				ContinueCase
			Case 4 To UBound($k2)
				$bits = BitOR(BitShift($k2[$k1],-16),BitShift($k2[$k1+1],-8),$k2[$k1+2])
				;$bits='13877084'
				For $j = 0 To 3
				_ArrayAdd($decout,StringMid($k3,BitShift(BitAND($bits,BitShift($site,$j*6)),(3-$j)*6)+1,1))
			    Next
			    ;_ArrayDisplay($decout)
				$k1+=3
            Case 2
				$bits = BitOR(BitShift($k2[$k1],-16),BitShift($k2[$k1+1],-8))
				For $j = 0 To 2
				_ArrayAdd($decout,StringMid($k3,BitShift(BitAND($bits,BitShift($site,$j*6)),(3-$j)*6)+1,1))
				Next
				$k1+=3
			Case 1
				$strEnd='=='
				$bits = BitShift($k2[$k1],-16)
				For $j = 0 To 1
				_ArrayAdd($decout,StringMid($k3,BitShift(BitAND($bits,BitShift($site,$j*6)),(3-$j)*6)+1,1))
				Next
				$k1+=3
		EndSwitch
		WEnd
		_ArrayDelete($decout, 0)
		_ArrayAdd($decout,$strEnd)
		Return _ArrayToString($decout, '')
	Else
		Return 0
	EndIf
EndFunc

Func __WINHTTP_STATUS_CALLBACK($hInternet, $iContext, $iInternetStatus, $pStatusInformation, $iStatusInformationLength)
    #forceref $hInternet, $iContext, $pStatusInformation, $iStatusInformationLength
    Local $sStatus
    Switch $iInternetStatus
        Case $WINHTTP_CALLBACK_STATUS_CLOSING_CONNECTION
            $sStatus = "Closing the connection to the server"
        Case $WINHTTP_CALLBACK_STATUS_CONNECTED_TO_SERVER
            $sStatus = "Successfully connected to the server."
        Case $WINHTTP_CALLBACK_STATUS_CONNECTING_TO_SERVER
            $sStatus = "Connecting to the server."
        Case $WINHTTP_CALLBACK_STATUS_CONNECTION_CLOSED
            $sStatus = "Successfully closed the connection to the server."
        Case $WINHTTP_CALLBACK_STATUS_DATA_AVAILABLE
            $sStatus = "Data is available to be retrieved with WinHttpReadData."
        Case $WINHTTP_CALLBACK_STATUS_HANDLE_CREATED
            $sStatus = "An HINTERNET handle has been created."
        Case $WINHTTP_CALLBACK_STATUS_HANDLE_CLOSING
            $sStatus = "This handle value has been terminated."
        Case $WINHTTP_CALLBACK_STATUS_HEADERS_AVAILABLE
            $sStatus = "The response header has been received and is available with WinHttpQueryHeaders."
        Case $WINHTTP_CALLBACK_STATUS_INTERMEDIATE_RESPONSE
            $sStatus = "Received an intermediate (100 level) status code message from the server."
        Case $WINHTTP_CALLBACK_STATUS_NAME_RESOLVED
            $sStatus = "Successfully found the IP address of the server."
        Case $WINHTTP_CALLBACK_STATUS_READ_COMPLETE
            $sStatus = "Data was successfully read from the server."
        Case $WINHTTP_CALLBACK_STATUS_RECEIVING_RESPONSE
            $sStatus = "Waiting for the server to respond to a request."
        Case $WINHTTP_CALLBACK_STATUS_REDIRECT
            $sStatus = "An HTTP request is about to automatically redirect the request."
        Case $WINHTTP_CALLBACK_STATUS_REQUEST_ERROR
            $sStatus = "An error occurred while sending an HTTP request."
        Case $WINHTTP_CALLBACK_STATUS_REQUEST_SENT
            $sStatus = "Successfully sent the information request to the server."
        Case $WINHTTP_CALLBACK_STATUS_RESOLVING_NAME
            $sStatus = "Looking up the IP address of a server name."
        Case $WINHTTP_CALLBACK_STATUS_RESPONSE_RECEIVED
            $sStatus = "Successfully received a response from the server."
        Case $WINHTTP_CALLBACK_STATUS_SECURE_FAILURE
            $sStatus = "One or more errors were encountered while retrieving a Secure Sockets Layer (SSL) certificate from the server."
        Case $WINHTTP_CALLBACK_STATUS_SENDING_REQUEST
            $sStatus = "Sending the information request to the server."
        Case $WINHTTP_CALLBACK_STATUS_SENDREQUEST_COMPLETE
            $sStatus = "The request completed successfully."
        Case $WINHTTP_CALLBACK_STATUS_WRITE_COMPLETE
            $sStatus = "Data was successfully written to the server."
    EndSwitch
;~         _CoProcSend($gi_CoProcParent, BinaryMid(Binary('0x25'),1) & StringToBinary($iInternetStatus & " " &$sStatus))  ;may cause crash
EndFunc