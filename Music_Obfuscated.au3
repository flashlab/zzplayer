#Obfuscator_On
Global Const $tagPOINT = "struct;long X;long Y;endstruct"
Global Const $tagRECT = "struct;long Left;long Top;long Right;long Bottom;endstruct"
Global Const $tagSIZE = "struct;long X;long Y;endstruct"
Global Const $tagNMHDR = "struct;hwnd hWndFrom;uint_ptr IDFrom;INT Code;endstruct"
Global Const $tagGDIPRECTF = "float X;float Y;float Width;float Height"
Global Const $tagGDIPSTARTUPINPUT = "uint Version;ptr Callback;bool NoThread;bool NoCodecs"
Global Const $tagHDITEM = "uint Mask;int XY;ptr Text;handle hBMP;int TextMax;int Fmt;lparam Param;int Image;int Order;uint Type;ptr pFilter;uint State"
Global Const $tagLVITEM = "struct;uint Mask;int Item;int SubItem;uint State;uint StateMask;ptr Text;int TextMax;int Image;lparam Param;" & "int Indent;int GroupID;uint Columns;ptr pColumns;ptr piColFmt;int iGroup;endstruct"
Global Const $tagNMLISTVIEW = $tagNMHDR & ";int Item;int SubItem;uint NewState;uint OldState;uint Changed;" & "struct;long ActionX;long ActionY;endstruct;lparam Param"
Global Const $tagNMLVDISPINFO = $tagNMHDR & ";" & $tagLVITEM
Global Const $tagNMITEMACTIVATE = $tagNMHDR & ";int Index;int SubItem;uint NewState;uint OldState;uint Changed;" & $tagPOINT & ";lparam lParam;uint KeyFlags"
Global Const $tagTOKEN_PRIVILEGES = "dword Count;align 4;int64 LUID;dword Attributes"
Global Const $tagMENUINFO = "dword Size;INT Mask;dword Style;uint YMax;handle hBack;dword ContextHelpID;ulong_ptr MenuData"
Global Const $tagMENUITEMINFO = "uint Size;uint Mask;uint Type;uint State;uint ID;handle SubMenu;handle BmpChecked;handle BmpUnchecked;" & "ulong_ptr ItemData;ptr TypeData;uint CCH;handle BmpItem"
Global Const $tagNMTBHOTITEM = $tagNMHDR & ";int idOld;int idNew;dword dwFlags"
Global Const $tagTBBUTTON = "int Bitmap;int Command;byte State;byte Style;align;dword_ptr Param;int_ptr String"
Global Const $tagTBBUTTONINFO = "uint Size;dword Mask;int Command;int Image;byte State;byte Style;word CX;dword_ptr Param;ptr Text;int TextMax"
Global Const $tagBITMAPINFO = "struct;dword Size;long Width;long Height;word Planes;word BitCount;dword Compression;dword SizeImage;" & "long XPelsPerMeter;long YPelsPerMeter;dword ClrUsed;dword ClrImportant;endstruct;dword RGBQuad"
Global Const $tagBLENDFUNCTION = "byte Op;byte Flags;byte Alpha;byte Format"
Global Const $tagLOGFONT = "long Height;long Width;long Escapement;long Orientation;long Weight;byte Italic;byte Underline;" & "byte Strikeout;byte CharSet;byte OutPrecision;byte ClipPrecision;byte Quality;byte PitchAndFamily;wchar FaceName[32]"
Global Const $FO_OVERWRITE = 2
Global Const $FILE_BEGIN = 0
Global Const $FILE_ATTRIBUTE_NORMAL = 0x00000080
Global Const $ERROR_NO_TOKEN = 1008
Global Const $SE_PRIVILEGE_ENABLED = 0x00000002
Global Enum $SECURITYANONYMOUS = 0, $SECURITYIDENTIFICATION, $SECURITYIMPERSONATION, $SECURITYDELEGATION
Global Const $TOKEN_QUERY = 0x00000008
Global Const $TOKEN_ADJUST_PRIVILEGES = 0x00000020
Global Const $READ_CONTROL = 0x00020000
Func _WinAPI_GetLastError($curErr = @error, $curExt = @extended)
Local $aResult = DllCall("kernel32.dll", "dword", "GetLastError")
Return SetError($curErr, $curExt, $aResult[0])
EndFunc
Func _Security__AdjustTokenPrivileges($hToken, $fDisableAll, $pNewState, $iBufferLen, $pPrevState = 0, $pRequired = 0)
Local $aCall = DllCall("advapi32.dll", "bool", "AdjustTokenPrivileges", "handle", $hToken, "bool", $fDisableAll, "struct*", $pNewState, "dword", $iBufferLen, "struct*", $pPrevState, "struct*", $pRequired)
If @error Then Return SetError(1, @extended, False)
Return Not($aCall[0] = 0)
EndFunc
Func _Security__ImpersonateSelf($iLevel = $SECURITYIMPERSONATION)
Local $aCall = DllCall("advapi32.dll", "bool", "ImpersonateSelf", "int", $iLevel)
If @error Then Return SetError(1, @extended, False)
Return Not($aCall[0] = 0)
EndFunc
Func _Security__LookupPrivilegeValue($sSystem, $sName)
Local $aCall = DllCall("advapi32.dll", "bool", "LookupPrivilegeValueW", "wstr", $sSystem, "wstr", $sName, "int64*", 0)
If @error Or Not $aCall[0] Then Return SetError(1, @extended, 0)
Return $aCall[3]
EndFunc
Func _Security__OpenThreadToken($iAccess, $hThread = 0, $fOpenAsSelf = False)
If $hThread = 0 Then $hThread = _WinAPI_GetCurrentThread()
If @error Then Return SetError(1, @extended, 0)
Local $aCall = DllCall("advapi32.dll", "bool", "OpenThreadToken", "handle", $hThread, "dword", $iAccess, "bool", $fOpenAsSelf, "handle*", 0)
If @error Or Not $aCall[0] Then Return SetError(2, @extended, 0)
Return $aCall[4]
EndFunc
Func _Security__OpenThreadTokenEx($iAccess, $hThread = 0, $fOpenAsSelf = False)
Local $hToken = _Security__OpenThreadToken($iAccess, $hThread, $fOpenAsSelf)
If $hToken = 0 Then
If _WinAPI_GetLastError() <> $ERROR_NO_TOKEN Then Return SetError(3, _WinAPI_GetLastError(), 0)
If Not _Security__ImpersonateSelf() Then Return SetError(1, _WinAPI_GetLastError(), 0)
$hToken = _Security__OpenThreadToken($iAccess, $hThread, $fOpenAsSelf)
If $hToken = 0 Then Return SetError(2, _WinAPI_GetLastError(), 0)
EndIf
Return $hToken
EndFunc
Func _Security__SetPrivilege($hToken, $sPrivilege, $fEnable)
Local $iLUID = _Security__LookupPrivilegeValue("", $sPrivilege)
If $iLUID = 0 Then Return SetError(1, @extended, False)
Local $tCurrState = DllStructCreate($tagTOKEN_PRIVILEGES)
Local $iCurrState = DllStructGetSize($tCurrState)
Local $tPrevState = DllStructCreate($tagTOKEN_PRIVILEGES)
Local $iPrevState = DllStructGetSize($tPrevState)
Local $tRequired = DllStructCreate("int Data")
DllStructSetData($tCurrState, "Count", 1)
DllStructSetData($tCurrState, "LUID", $iLUID)
If Not _Security__AdjustTokenPrivileges($hToken, False, $tCurrState, $iCurrState, $tPrevState, $tRequired) Then Return SetError(2, @error, False)
DllStructSetData($tPrevState, "Count", 1)
DllStructSetData($tPrevState, "LUID", $iLUID)
Local $iAttributes = DllStructGetData($tPrevState, "Attributes")
If $fEnable Then
$iAttributes = BitOR($iAttributes, $SE_PRIVILEGE_ENABLED)
Else
$iAttributes = BitAND($iAttributes, BitNOT($SE_PRIVILEGE_ENABLED))
EndIf
DllStructSetData($tPrevState, "Attributes", $iAttributes)
If Not _Security__AdjustTokenPrivileges($hToken, False, $tPrevState, $iPrevState, $tCurrState, $tRequired) Then Return SetError(3, @error, False)
Return True
EndFunc
Func _SendMessage($hWnd, $iMsg, $wParam = 0, $lParam = 0, $iReturn = 0, $wParamType = "wparam", $lParamType = "lparam", $sReturnType = "lresult")
Local $aResult = DllCall("user32.dll", $sReturnType, "SendMessageW", "hwnd", $hWnd, "uint", $iMsg, $wParamType, $wParam, $lParamType, $lParam)
If @error Then Return SetError(@error, @extended, "")
If $iReturn >= 0 And $iReturn <= 4 Then Return $aResult[$iReturn]
Return $aResult
EndFunc
Global $__gaInProcess_WinAPI[64][2] = [[0, 0]]
Global $__gaWinList_WinAPI[64][2] = [[0, 0]]
Global Const $__WINAPICONSTANT_WM_SETFONT = 0x0030
Global Const $__WINAPICONSTANT_FW_NORMAL = 400
Global Const $__WINAPICONSTANT_DEFAULT_CHARSET = 1
Global Const $__WINAPICONSTANT_OUT_DEFAULT_PRECIS = 0
Global Const $__WINAPICONSTANT_CLIP_DEFAULT_PRECIS = 0
Global Const $__WINAPICONSTANT_DEFAULT_QUALITY = 0
Global Const $HGDI_ERROR = Ptr(-1)
Global Const $INVALID_HANDLE_VALUE = Ptr(-1)
Global Const $__WINAPICONSTANT_GW_HWNDNEXT = 2
Global Const $__WINAPICONSTANT_GW_CHILD = 5
Global Const $__WINAPICONSTANT_DI_MASK = 0x0001
Global Const $__WINAPICONSTANT_DI_IMAGE = 0x0002
Global Const $__WINAPICONSTANT_DI_NORMAL = 0x0003
Global Const $__WINAPICONSTANT_DI_COMPAT = 0x0004
Global Const $__WINAPICONSTANT_DI_DEFAULTSIZE = 0x0008
Global Const $__WINAPICONSTANT_DI_NOMIRROR = 0x0010
Global Const $ULW_ALPHA = 0x02
Global Const $KF_EXTENDED = 0x0100
Global Const $KF_ALTDOWN = 0x2000
Global Const $KF_UP = 0x8000
Global Const $LLKHF_EXTENDED = BitShift($KF_EXTENDED, 8)
Global Const $LLKHF_ALTDOWN = BitShift($KF_ALTDOWN, 8)
Global Const $LLKHF_UP = BitShift($KF_UP, 8)
Global Const $tagICONINFO = "bool Icon;dword XHotSpot;dword YHotSpot;handle hMask;handle hColor"
Func _WinAPI_ClientToScreen($hWnd, ByRef $tPoint)
DllCall("user32.dll", "bool", "ClientToScreen", "hwnd", $hWnd, "struct*", $tPoint)
Return SetError(@error, @extended, $tPoint)
EndFunc
Func _WinAPI_CloseHandle($hObject)
Local $aResult = DllCall("kernel32.dll", "bool", "CloseHandle", "handle", $hObject)
If @error Then Return SetError(@error, @extended, False)
Return $aResult[0]
EndFunc
Func _WinAPI_CopyIcon($hIcon)
Local $aResult = DllCall("user32.dll", "handle", "CopyIcon", "handle", $hIcon)
If @error Then Return SetError(@error, @extended, 0)
Return $aResult[0]
EndFunc
Func _WinAPI_CreateCompatibleBitmap($hDC, $iWidth, $iHeight)
Local $aResult = DllCall("gdi32.dll", "handle", "CreateCompatibleBitmap", "handle", $hDC, "int", $iWidth, "int", $iHeight)
If @error Then Return SetError(@error, @extended, 0)
Return $aResult[0]
EndFunc
Func _WinAPI_CreateCompatibleDC($hDC)
Local $aResult = DllCall("gdi32.dll", "handle", "CreateCompatibleDC", "handle", $hDC)
If @error Then Return SetError(@error, @extended, 0)
Return $aResult[0]
EndFunc
Func _WinAPI_CreateFont($nHeight, $nWidth, $nEscape = 0, $nOrientn = 0, $fnWeight = $__WINAPICONSTANT_FW_NORMAL, $bItalic = False, $bUnderline = False, $bStrikeout = False, $nCharset = $__WINAPICONSTANT_DEFAULT_CHARSET, $nOutputPrec = $__WINAPICONSTANT_OUT_DEFAULT_PRECIS, $nClipPrec = $__WINAPICONSTANT_CLIP_DEFAULT_PRECIS, $nQuality = $__WINAPICONSTANT_DEFAULT_QUALITY, $nPitch = 0, $szFace = 'Arial')
Local $aResult = DllCall("gdi32.dll", "handle", "CreateFontW", "int", $nHeight, "int", $nWidth, "int", $nEscape, "int", $nOrientn, "int", $fnWeight, "dword", $bItalic, "dword", $bUnderline, "dword", $bStrikeout, "dword", $nCharset, "dword", $nOutputPrec, "dword", $nClipPrec, "dword", $nQuality, "dword", $nPitch, "wstr", $szFace)
If @error Then Return SetError(@error, @extended, 0)
Return $aResult[0]
EndFunc
Func _WinAPI_CreateSolidBitmap($hWnd, $iColor, $iWidth, $iHeight, $bRGB = 1)
Local $hDC = _WinAPI_GetDC($hWnd)
Local $hDestDC = _WinAPI_CreateCompatibleDC($hDC)
Local $hBitmap = _WinAPI_CreateCompatibleBitmap($hDC, $iWidth, $iHeight)
Local $hOld = _WinAPI_SelectObject($hDestDC, $hBitmap)
Local $tRect = DllStructCreate($tagRECT)
DllStructSetData($tRect, 1, 0)
DllStructSetData($tRect, 2, 0)
DllStructSetData($tRect, 3, $iWidth)
DllStructSetData($tRect, 4, $iHeight)
If $bRGB Then
$iColor = BitOR(BitAND($iColor, 0x00FF00), BitShift(BitAND($iColor, 0x0000FF), -16), BitShift(BitAND($iColor, 0xFF0000), 16))
EndIf
Local $hBrush = _WinAPI_CreateSolidBrush($iColor)
_WinAPI_FillRect($hDestDC, $tRect, $hBrush)
If @error Then
_WinAPI_DeleteObject($hBitmap)
$hBitmap = 0
EndIf
_WinAPI_DeleteObject($hBrush)
_WinAPI_ReleaseDC($hWnd, $hDC)
_WinAPI_SelectObject($hDestDC, $hOld)
_WinAPI_DeleteDC($hDestDC)
If Not $hBitmap Then Return SetError(1, 0, 0)
Return $hBitmap
EndFunc
Func _WinAPI_CreateSolidBrush($nColor)
Local $aResult = DllCall("gdi32.dll", "handle", "CreateSolidBrush", "dword", $nColor)
If @error Then Return SetError(@error, @extended, 0)
Return $aResult[0]
EndFunc
Func _WinAPI_CreateWindowEx($iExStyle, $sClass, $sName, $iStyle, $iX, $iY, $iWidth, $iHeight, $hParent, $hMenu = 0, $hInstance = 0, $pParam = 0)
If $hInstance = 0 Then $hInstance = _WinAPI_GetModuleHandle("")
Local $aResult = DllCall("user32.dll", "hwnd", "CreateWindowExW", "dword", $iExStyle, "wstr", $sClass, "wstr", $sName, "dword", $iStyle, "int", $iX, "int", $iY, "int", $iWidth, "int", $iHeight, "hwnd", $hParent, "handle", $hMenu, "handle", $hInstance, "ptr", $pParam)
If @error Then Return SetError(@error, @extended, 0)
Return $aResult[0]
EndFunc
Func _WinAPI_DeleteDC($hDC)
Local $aResult = DllCall("gdi32.dll", "bool", "DeleteDC", "handle", $hDC)
If @error Then Return SetError(@error, @extended, False)
Return $aResult[0]
EndFunc
Func _WinAPI_DeleteObject($hObject)
Local $aResult = DllCall("gdi32.dll", "bool", "DeleteObject", "handle", $hObject)
If @error Then Return SetError(@error, @extended, False)
Return $aResult[0]
EndFunc
Func _WinAPI_DestroyIcon($hIcon)
Local $aResult = DllCall("user32.dll", "bool", "DestroyIcon", "handle", $hIcon)
If @error Then Return SetError(@error, @extended, False)
Return $aResult[0]
EndFunc
Func _WinAPI_DestroyWindow($hWnd)
Local $aResult = DllCall("user32.dll", "bool", "DestroyWindow", "hwnd", $hWnd)
If @error Then Return SetError(@error, @extended, False)
Return $aResult[0]
EndFunc
Func _WinAPI_DrawIconEx($hDC, $iX, $iY, $hIcon, $iWidth = 0, $iHeight = 0, $iStep = 0, $hBrush = 0, $iFlags = 3)
Local $iOptions
Switch $iFlags
Case 1
$iOptions = $__WINAPICONSTANT_DI_MASK
Case 2
$iOptions = $__WINAPICONSTANT_DI_IMAGE
Case 3
$iOptions = $__WINAPICONSTANT_DI_NORMAL
Case 4
$iOptions = $__WINAPICONSTANT_DI_COMPAT
Case 5
$iOptions = $__WINAPICONSTANT_DI_DEFAULTSIZE
Case Else
$iOptions = $__WINAPICONSTANT_DI_NOMIRROR
EndSwitch
Local $aResult = DllCall("user32.dll", "bool", "DrawIconEx", "handle", $hDC, "int", $iX, "int", $iY, "handle", $hIcon, "int", $iWidth, "int", $iHeight, "uint", $iStep, "handle", $hBrush, "uint", $iOptions)
If @error Then Return SetError(@error, @extended, False)
Return $aResult[0]
EndFunc
Func _WinAPI_EnableWindow($hWnd, $fEnable = True)
Local $aResult = DllCall("user32.dll", "bool", "EnableWindow", "hwnd", $hWnd, "bool", $fEnable)
If @error Then Return SetError(@error, @extended, False)
Return $aResult[0]
EndFunc
Func __WinAPI_EnumWindowsAdd($hWnd, $sClass = "")
If $sClass = "" Then $sClass = _WinAPI_GetClassName($hWnd)
$__gaWinList_WinAPI[0][0] += 1
Local $iCount = $__gaWinList_WinAPI[0][0]
If $iCount >= $__gaWinList_WinAPI[0][1] Then
ReDim $__gaWinList_WinAPI[$iCount + 64][2]
$__gaWinList_WinAPI[0][1] += 64
EndIf
$__gaWinList_WinAPI[$iCount][0] = $hWnd
$__gaWinList_WinAPI[$iCount][1] = $sClass
EndFunc
Func __WinAPI_EnumWindowsInit()
ReDim $__gaWinList_WinAPI[64][2]
$__gaWinList_WinAPI[0][0] = 0
$__gaWinList_WinAPI[0][1] = 64
EndFunc
Func _WinAPI_EnumWindowsTop()
__WinAPI_EnumWindowsInit()
Local $hWnd = _WinAPI_GetWindow(_WinAPI_GetDesktopWindow(), $__WINAPICONSTANT_GW_CHILD)
While $hWnd <> 0
If _WinAPI_IsWindowVisible($hWnd) Then __WinAPI_EnumWindowsAdd($hWnd)
$hWnd = _WinAPI_GetWindow($hWnd, $__WINAPICONSTANT_GW_HWNDNEXT)
WEnd
Return $__gaWinList_WinAPI
EndFunc
Func _WinAPI_ExtractIconEx($sFile, $iIndex, $pLarge, $pSmall, $iIcons)
Local $aResult = DllCall("shell32.dll", "uint", "ExtractIconExW", "wstr", $sFile, "int", $iIndex, "struct*", $pLarge, "struct*", $pSmall, "uint", $iIcons)
If @error Then Return SetError(@error, @extended, 0)
Return $aResult[0]
EndFunc
Func _WinAPI_FillRect($hDC, $ptrRect, $hBrush)
Local $aResult
If IsPtr($hBrush) Then
$aResult = DllCall("user32.dll", "int", "FillRect", "handle", $hDC, "struct*", $ptrRect, "handle", $hBrush)
Else
$aResult = DllCall("user32.dll", "int", "FillRect", "handle", $hDC, "struct*", $ptrRect, "dword_ptr", $hBrush)
EndIf
If @error Then Return SetError(@error, @extended, False)
Return $aResult[0]
EndFunc
Func _WinAPI_GetClassName($hWnd)
If Not IsHWnd($hWnd) Then $hWnd = GUICtrlGetHandle($hWnd)
Local $aResult = DllCall("user32.dll", "int", "GetClassNameW", "hwnd", $hWnd, "wstr", "", "int", 4096)
If @error Then Return SetError(@error, @extended, False)
Return SetExtended($aResult[0], $aResult[2])
EndFunc
Func _WinAPI_GetCurrentThread()
Local $aResult = DllCall("kernel32.dll", "handle", "GetCurrentThread")
If @error Then Return SetError(@error, @extended, 0)
Return $aResult[0]
EndFunc
Func _WinAPI_GetDC($hWnd)
Local $aResult = DllCall("user32.dll", "handle", "GetDC", "hwnd", $hWnd)
If @error Then Return SetError(@error, @extended, 0)
Return $aResult[0]
EndFunc
Func _WinAPI_GetDesktopWindow()
Local $aResult = DllCall("user32.dll", "hwnd", "GetDesktopWindow")
If @error Then Return SetError(@error, @extended, 0)
Return $aResult[0]
EndFunc
Func _WinAPI_GetDIBits($hDC, $hBmp, $iStartScan, $iScanLines, $pBits, $pBI, $iUsage)
Local $aResult = DllCall("gdi32.dll", "int", "GetDIBits", "handle", $hDC, "handle", $hBmp, "uint", $iStartScan, "uint", $iScanLines, "ptr", $pBits, "ptr", $pBI, "uint", $iUsage)
If @error Then Return SetError(@error, @extended, False)
Return $aResult[0]
EndFunc
Func _WinAPI_GetDlgCtrlID($hWnd)
Local $aResult = DllCall("user32.dll", "int", "GetDlgCtrlID", "hwnd", $hWnd)
If @error Then Return SetError(@error, @extended, 0)
Return $aResult[0]
EndFunc
Func _WinAPI_GetIconInfo($hIcon)
Local $tInfo = DllStructCreate($tagICONINFO)
DllCall("user32.dll", "bool", "GetIconInfo", "handle", $hIcon, "struct*", $tInfo)
If @error Then Return SetError(@error, @extended, 0)
Local $aIcon[6]
$aIcon[0] = True
$aIcon[1] = DllStructGetData($tInfo, "Icon") <> 0
$aIcon[2] = DllStructGetData($tInfo, "XHotSpot")
$aIcon[3] = DllStructGetData($tInfo, "YHotSpot")
$aIcon[4] = DllStructGetData($tInfo, "hMask")
$aIcon[5] = DllStructGetData($tInfo, "hColor")
Return $aIcon
EndFunc
Func _WinAPI_GetModuleHandle($sModuleName)
Local $sModuleNameType = "wstr"
If $sModuleName = "" Then
$sModuleName = 0
$sModuleNameType = "ptr"
EndIf
Local $aResult = DllCall("kernel32.dll", "handle", "GetModuleHandleW", $sModuleNameType, $sModuleName)
If @error Then Return SetError(@error, @extended, 0)
Return $aResult[0]
EndFunc
Func _WinAPI_GetMousePos($fToClient = False, $hWnd = 0)
Local $iMode = Opt("MouseCoordMode", 1)
Local $aPos = MouseGetPos()
Opt("MouseCoordMode", $iMode)
Local $tPoint = DllStructCreate($tagPOINT)
DllStructSetData($tPoint, "X", $aPos[0])
DllStructSetData($tPoint, "Y", $aPos[1])
If $fToClient Then
_WinAPI_ScreenToClient($hWnd, $tPoint)
If @error Then Return SetError(@error, @extended, 0)
EndIf
Return $tPoint
EndFunc
Func _WinAPI_GetMousePosX($fToClient = False, $hWnd = 0)
Local $tPoint = _WinAPI_GetMousePos($fToClient, $hWnd)
If @error Then Return SetError(@error, @extended, 0)
Return DllStructGetData($tPoint, "X")
EndFunc
Func _WinAPI_GetMousePosY($fToClient = False, $hWnd = 0)
Local $tPoint = _WinAPI_GetMousePos($fToClient, $hWnd)
If @error Then Return SetError(@error, @extended, 0)
Return DllStructGetData($tPoint, "Y")
EndFunc
Func _WinAPI_GetObject($hObject, $iSize, $pObject)
Local $aResult = DllCall("gdi32.dll", "int", "GetObjectW", "handle", $hObject, "int", $iSize, "ptr", $pObject)
If @error Then Return SetError(@error, @extended, 0)
Return $aResult[0]
EndFunc
Func _WinAPI_GetParent($hWnd)
Local $aResult = DllCall("user32.dll", "hwnd", "GetParent", "hwnd", $hWnd)
If @error Then Return SetError(@error, @extended, 0)
Return $aResult[0]
EndFunc
Func _WinAPI_GetStockObject($iObject)
Local $aResult = DllCall("gdi32.dll", "handle", "GetStockObject", "int", $iObject)
If @error Then Return SetError(@error, @extended, 0)
Return $aResult[0]
EndFunc
Func _WinAPI_GetSysColor($iIndex)
Local $aResult = DllCall("user32.dll", "dword", "GetSysColor", "int", $iIndex)
If @error Then Return SetError(@error, @extended, 0)
Return $aResult[0]
EndFunc
Func _WinAPI_GetWindow($hWnd, $iCmd)
Local $aResult = DllCall("user32.dll", "hwnd", "GetWindow", "hwnd", $hWnd, "uint", $iCmd)
If @error Then Return SetError(@error, @extended, 0)
Return $aResult[0]
EndFunc
Func _WinAPI_GetWindowHeight($hWnd)
Local $tRect = _WinAPI_GetWindowRect($hWnd)
If @error Then Return SetError(@error, @extended, 0)
Return DllStructGetData($tRect, "Bottom") - DllStructGetData($tRect, "Top")
EndFunc
Func _WinAPI_GetWindowRect($hWnd)
Local $tRect = DllStructCreate($tagRECT)
DllCall("user32.dll", "bool", "GetWindowRect", "hwnd", $hWnd, "struct*", $tRect)
If @error Then Return SetError(@error, @extended, 0)
Return $tRect
EndFunc
Func _WinAPI_GetWindowThreadProcessId($hWnd, ByRef $iPID)
Local $aResult = DllCall("user32.dll", "dword", "GetWindowThreadProcessId", "hwnd", $hWnd, "dword*", 0)
If @error Then Return SetError(@error, @extended, 0)
$iPID = $aResult[2]
Return $aResult[0]
EndFunc
Func _WinAPI_GetWindowWidth($hWnd)
Local $tRect = _WinAPI_GetWindowRect($hWnd)
If @error Then Return SetError(@error, @extended, 0)
Return DllStructGetData($tRect, "Right") - DllStructGetData($tRect, "Left")
EndFunc
Func _WinAPI_GetXYFromPoint(ByRef $tPoint, ByRef $iX, ByRef $iY)
$iX = DllStructGetData($tPoint, "X")
$iY = DllStructGetData($tPoint, "Y")
EndFunc
Func _WinAPI_HiWord($iLong)
Return BitShift($iLong, 16)
EndFunc
Func _WinAPI_InProcess($hWnd, ByRef $hLastWnd)
If $hWnd = $hLastWnd Then Return True
For $iI = $__gaInProcess_WinAPI[0][0] To 1 Step -1
If $hWnd = $__gaInProcess_WinAPI[$iI][0] Then
If $__gaInProcess_WinAPI[$iI][1] Then
$hLastWnd = $hWnd
Return True
Else
Return False
EndIf
EndIf
Next
Local $iProcessID
_WinAPI_GetWindowThreadProcessId($hWnd, $iProcessID)
Local $iCount = $__gaInProcess_WinAPI[0][0] + 1
If $iCount >= 64 Then $iCount = 1
$__gaInProcess_WinAPI[0][0] = $iCount
$__gaInProcess_WinAPI[$iCount][0] = $hWnd
$__gaInProcess_WinAPI[$iCount][1] =($iProcessID = @AutoItPID)
Return $__gaInProcess_WinAPI[$iCount][1]
EndFunc
Func _WinAPI_IsClassName($hWnd, $sClassName)
Local $sSeparator = Opt("GUIDataSeparatorChar")
Local $aClassName = StringSplit($sClassName, $sSeparator)
If Not IsHWnd($hWnd) Then $hWnd = GUICtrlGetHandle($hWnd)
Local $sClassCheck = _WinAPI_GetClassName($hWnd)
For $x = 1 To UBound($aClassName) - 1
If StringUpper(StringMid($sClassCheck, 1, StringLen($aClassName[$x]))) = StringUpper($aClassName[$x]) Then Return True
Next
Return False
EndFunc
Func _WinAPI_IsWindowVisible($hWnd)
Local $aResult = DllCall("user32.dll", "bool", "IsWindowVisible", "hwnd", $hWnd)
If @error Then Return SetError(@error, @extended, 0)
Return $aResult[0]
EndFunc
Func _WinAPI_InvalidateRect($hWnd, $tRect = 0, $fErase = True)
Local $aResult = DllCall("user32.dll", "bool", "InvalidateRect", "hwnd", $hWnd, "struct*", $tRect, "bool", $fErase)
If @error Then Return SetError(@error, @extended, False)
Return $aResult[0]
EndFunc
Func _WinAPI_LoadImage($hInstance, $sImage, $iType, $iXDesired, $iYDesired, $iLoad)
Local $aResult, $sImageType = "int"
If IsString($sImage) Then $sImageType = "wstr"
$aResult = DllCall("user32.dll", "handle", "LoadImageW", "handle", $hInstance, $sImageType, $sImage, "uint", $iType, "int", $iXDesired, "int", $iYDesired, "uint", $iLoad)
If @error Then Return SetError(@error, @extended, 0)
Return $aResult[0]
EndFunc
Func _WinAPI_LoadLibrary($sFileName)
Local $aResult = DllCall("kernel32.dll", "handle", "LoadLibraryW", "wstr", $sFileName)
If @error Then Return SetError(@error, @extended, 0)
Return $aResult[0]
EndFunc
Func _WinAPI_LoadShell32Icon($iIconID)
Local $tIcons = DllStructCreate("ptr Data")
Local $iIcons = _WinAPI_ExtractIconEx("shell32.dll", $iIconID, 0, $tIcons, 1)
If @error Then Return SetError(@error, @extended, 0)
If $iIcons <= 0 Then Return SetError(1, 0, 0)
Return DllStructGetData($tIcons, "Data")
EndFunc
Func _WinAPI_LoWord($iLong)
Return BitAND($iLong, 0xFFFF)
EndFunc
Func _WinAPI_MoveWindow($hWnd, $iX, $iY, $iWidth, $iHeight, $fRepaint = True)
Local $aResult = DllCall("user32.dll", "bool", "MoveWindow", "hwnd", $hWnd, "int", $iX, "int", $iY, "int", $iWidth, "int", $iHeight, "bool", $fRepaint)
If @error Then Return SetError(@error, @extended, False)
Return $aResult[0]
EndFunc
Func _WinAPI_MultiByteToWideChar($sText, $iCodePage = 0, $iFlags = 0, $bRetString = False)
Local $sTextType = "str"
If Not IsString($sText) Then $sTextType = "struct*"
Local $aResult = DllCall("kernel32.dll", "int", "MultiByteToWideChar", "uint", $iCodePage, "dword", $iFlags, $sTextType, $sText, "int", -1, "ptr", 0, "int", 0)
If @error Then Return SetError(@error, @extended, 0)
Local $iOut = $aResult[0]
Local $tOut = DllStructCreate("wchar[" & $iOut & "]")
$aResult = DllCall("kernel32.dll", "int", "MultiByteToWideChar", "uint", $iCodePage, "dword", $iFlags, $sTextType, $sText, "int", -1, "struct*", $tOut, "int", $iOut)
If @error Then Return SetError(@error, @extended, 0)
If $bRetString Then Return DllStructGetData($tOut, 1)
Return $tOut
EndFunc
Func _WinAPI_PointFromRect(ByRef $tRect, $fCenter = True)
Local $iX1 = DllStructGetData($tRect, "Left")
Local $iY1 = DllStructGetData($tRect, "Top")
Local $iX2 = DllStructGetData($tRect, "Right")
Local $iY2 = DllStructGetData($tRect, "Bottom")
If $fCenter Then
$iX1 = $iX1 +(($iX2 - $iX1) / 2)
$iY1 = $iY1 +(($iY2 - $iY1) / 2)
EndIf
Local $tPoint = DllStructCreate($tagPOINT)
DllStructSetData($tPoint, "X", $iX1)
DllStructSetData($tPoint, "Y", $iY1)
Return $tPoint
EndFunc
Func _WinAPI_RegisterWindowMessage($sMessage)
Local $aResult = DllCall("user32.dll", "uint", "RegisterWindowMessageW", "wstr", $sMessage)
If @error Then Return SetError(@error, @extended, 0)
Return $aResult[0]
EndFunc
Func _WinAPI_ReleaseDC($hWnd, $hDC)
Local $aResult = DllCall("user32.dll", "int", "ReleaseDC", "hwnd", $hWnd, "handle", $hDC)
If @error Then Return SetError(@error, @extended, False)
Return $aResult[0]
EndFunc
Func _WinAPI_ScreenToClient($hWnd, ByRef $tPoint)
Local $aResult = DllCall("user32.dll", "bool", "ScreenToClient", "hwnd", $hWnd, "struct*", $tPoint)
If @error Then Return SetError(@error, @extended, False)
Return $aResult[0]
EndFunc
Func _WinAPI_SelectObject($hDC, $hGDIObj)
Local $aResult = DllCall("gdi32.dll", "handle", "SelectObject", "handle", $hDC, "handle", $hGDIObj)
If @error Then Return SetError(@error, @extended, False)
Return $aResult[0]
EndFunc
Func _WinAPI_SetFocus($hWnd)
Local $aResult = DllCall("user32.dll", "hwnd", "SetFocus", "hwnd", $hWnd)
If @error Then Return SetError(@error, @extended, 0)
Return $aResult[0]
EndFunc
Func _WinAPI_SetFont($hWnd, $hFont, $fRedraw = True)
_SendMessage($hWnd, $__WINAPICONSTANT_WM_SETFONT, $hFont, $fRedraw, 0, "hwnd")
EndFunc
Func _WinAPI_SetParent($hWndChild, $hWndParent)
Local $aResult = DllCall("user32.dll", "hwnd", "SetParent", "hwnd", $hWndChild, "hwnd", $hWndParent)
If @error Then Return SetError(@error, @extended, 0)
Return $aResult[0]
EndFunc
Func _WinAPI_ShowCursor($fShow)
Local $aResult = DllCall("user32.dll", "int", "ShowCursor", "bool", $fShow)
If @error Then Return SetError(@error, @extended, 0)
Return $aResult[0]
EndFunc
Func _WinAPI_UpdateLayeredWindow($hWnd, $hDCDest, $pPTDest, $pSize, $hDCSrce, $pPTSrce, $iRGB, $pBlend, $iFlags)
Local $aResult = DllCall("user32.dll", "bool", "UpdateLayeredWindow", "hwnd", $hWnd, "handle", $hDCDest, "ptr", $pPTDest, "ptr", $pSize, "handle", $hDCSrce, "ptr", $pPTSrce, "dword", $iRGB, "ptr", $pBlend, "dword", $iFlags)
If @error Then Return SetError(@error, @extended, False)
Return $aResult[0]
EndFunc
Global $ghGDIPDll = 0
Global $giGDIPRef = 0
Global $giGDIPToken = 0
Func _GDIPlus_BitmapCreateFromGraphics($iWidth, $iHeight, $hGraphics)
Local $aResult = DllCall($ghGDIPDll, "int", "GdipCreateBitmapFromGraphics", "int", $iWidth, "int", $iHeight, "handle", $hGraphics, "ptr*", 0)
If @error Then Return SetError(@error, @extended, 0)
Return SetExtended($aResult[0], $aResult[4])
EndFunc
Func _GDIPlus_BitmapCreateHBITMAPFromBitmap($hBitmap, $iARGB = 0xFF000000)
Local $aResult = DllCall($ghGDIPDll, "int", "GdipCreateHBITMAPFromBitmap", "handle", $hBitmap, "ptr*", 0, "dword", $iARGB)
If @error Then Return SetError(@error, @extended, 0)
Return SetExtended($aResult[0], $aResult[2])
EndFunc
Func _GDIPlus_BrushCreateSolid($iARGB = 0xFF000000)
Local $aResult = DllCall($ghGDIPDll, "int", "GdipCreateSolidFill", "int", $iARGB, "ptr*", 0)
If @error Then Return SetError(@error, @extended, 0)
Return SetExtended($aResult[0], $aResult[2])
EndFunc
Func _GDIPlus_BrushDispose($hBrush)
Local $aResult = DllCall($ghGDIPDll, "int", "GdipDeleteBrush", "handle", $hBrush)
If @error Then Return SetError(@error, @extended, False)
Return $aResult[0] = 0
EndFunc
Func _GDIPlus_FontCreate($hFamily, $fSize, $iStyle = 0, $iUnit = 3)
Local $aResult = DllCall($ghGDIPDll, "int", "GdipCreateFont", "handle", $hFamily, "float", $fSize, "int", $iStyle, "int", $iUnit, "ptr*", 0)
If @error Then Return SetError(@error, @extended, 0)
Return SetExtended($aResult[0], $aResult[5])
EndFunc
Func _GDIPlus_FontDispose($hFont)
Local $aResult = DllCall($ghGDIPDll, "int", "GdipDeleteFont", "handle", $hFont)
If @error Then Return SetError(@error, @extended, False)
Return $aResult[0] = 0
EndFunc
Func _GDIPlus_FontFamilyCreate($sFamily)
Local $aResult = DllCall($ghGDIPDll, "int", "GdipCreateFontFamilyFromName", "wstr", $sFamily, "ptr", 0, "handle*", 0)
If @error Then Return SetError(@error, @extended, 0)
Return SetExtended($aResult[0], $aResult[3])
EndFunc
Func _GDIPlus_FontFamilyDispose($hFamily)
Local $aResult = DllCall($ghGDIPDll, "int", "GdipDeleteFontFamily", "handle", $hFamily)
If @error Then Return SetError(@error, @extended, False)
Return $aResult[0] = 0
EndFunc
Func _GDIPlus_GraphicsCreateFromHWND($hWnd)
Local $aResult = DllCall($ghGDIPDll, "int", "GdipCreateFromHWND", "hwnd", $hWnd, "ptr*", 0)
If @error Then Return SetError(@error, @extended, 0)
Return SetExtended($aResult[0], $aResult[2])
EndFunc
Func _GDIPlus_GraphicsDispose($hGraphics)
Local $aResult = DllCall($ghGDIPDll, "int", "GdipDeleteGraphics", "handle", $hGraphics)
If @error Then Return SetError(@error, @extended, False)
Return $aResult[0] = 0
EndFunc
Func _GDIPlus_GraphicsDrawImageRect($hGraphics, $hImage, $iX, $iY, $iW, $iH)
Local $aResult = DllCall($ghGDIPDll, "int", "GdipDrawImageRectI", "handle", $hGraphics, "handle", $hImage, "int", $iX, "int", $iY, "int", $iW, "int", $iH)
If @error Then Return SetError(@error, @extended, False)
Return $aResult[0] = 0
EndFunc
Func _GDIPlus_GraphicsDrawStringEx($hGraphics, $sString, $hFont, $tLayout, $hFormat, $hBrush)
Local $aResult = DllCall($ghGDIPDll, "int", "GdipDrawString", "handle", $hGraphics, "wstr", $sString, "int", -1, "handle", $hFont, "struct*", $tLayout, "handle", $hFormat, "handle", $hBrush)
If @error Then Return SetError(@error, @extended, False)
Return $aResult[0] = 0
EndFunc
Func _GDIPlus_GraphicsMeasureString($hGraphics, $sString, $hFont, $tLayout, $hFormat)
Local $tRectF = DllStructCreate($tagGDIPRECTF)
Local $aResult = DllCall($ghGDIPDll, "int", "GdipMeasureString", "handle", $hGraphics, "wstr", $sString, "int", -1, "handle", $hFont, "struct*", $tLayout, "handle", $hFormat, "struct*", $tRectF, "int*", 0, "int*", 0)
If @error Then Return SetError(@error, @extended, 0)
Local $aInfo[3]
$aInfo[0] = $tRectF
$aInfo[1] = $aResult[8]
$aInfo[2] = $aResult[9]
Return SetExtended($aResult[0], $aInfo)
EndFunc
Func _GDIPlus_ImageDispose($hImage)
Local $aResult = DllCall($ghGDIPDll, "int", "GdipDisposeImage", "handle", $hImage)
If @error Then Return SetError(@error, @extended, False)
Return $aResult[0] = 0
EndFunc
Func _GDIPlus_ImageGetGraphicsContext($hImage)
Local $aResult = DllCall($ghGDIPDll, "int", "GdipGetImageGraphicsContext", "handle", $hImage, "ptr*", 0)
If @error Then Return SetError(@error, @extended, -1)
Return SetExtended($aResult[0], $aResult[2])
EndFunc
Func _GDIPlus_ImageGetHeight($hImage)
Local $aResult = DllCall($ghGDIPDll, "int", "GdipGetImageHeight", "handle", $hImage, "uint*", 0)
If @error Then Return SetError(@error, @extended, -1)
Return SetExtended($aResult[0], $aResult[2])
EndFunc
Func _GDIPlus_ImageGetWidth($hImage)
Local $aResult = DllCall($ghGDIPDll, "int", "GdipGetImageWidth", "handle", $hImage, "uint*", -1)
If @error Then Return SetError(@error, @extended, -1)
Return SetExtended($aResult[0], $aResult[2])
EndFunc
Func _GDIPlus_ImageLoadFromFile($sFileName)
Local $aResult = DllCall($ghGDIPDll, "int", "GdipLoadImageFromFile", "wstr", $sFileName, "ptr*", 0)
If @error Then Return SetError(@error, @extended, -1)
Return SetExtended($aResult[0], $aResult[2])
EndFunc
Func _GDIPlus_RectFCreate($nX = 0, $nY = 0, $nWidth = 0, $nHeight = 0)
Local $tRectF = DllStructCreate($tagGDIPRECTF)
DllStructSetData($tRectF, "X", $nX)
DllStructSetData($tRectF, "Y", $nY)
DllStructSetData($tRectF, "Width", $nWidth)
DllStructSetData($tRectF, "Height", $nHeight)
Return $tRectF
EndFunc
Func _GDIPlus_Shutdown()
If $ghGDIPDll = 0 Then Return SetError(-1, -1, False)
$giGDIPRef -= 1
If $giGDIPRef = 0 Then
DllCall($ghGDIPDll, "none", "GdiplusShutdown", "ptr", $giGDIPToken)
DllClose($ghGDIPDll)
$ghGDIPDll = 0
EndIf
Return True
EndFunc
Func _GDIPlus_Startup()
$giGDIPRef += 1
If $giGDIPRef > 1 Then Return True
$ghGDIPDll = DllOpen("GDIPlus.dll")
If $ghGDIPDll = -1 Then
$giGDIPRef = 0
Return SetError(1, 2, False)
EndIf
Local $tInput = DllStructCreate($tagGDIPSTARTUPINPUT)
Local $tToken = DllStructCreate("ulong_ptr Data")
DllStructSetData($tInput, "Version", 1)
Local $aResult = DllCall($ghGDIPDll, "int", "GdiplusStartup", "struct*", $tToken, "struct*", $tInput, "ptr", 0)
If @error Then Return SetError(@error, @extended, False)
$giGDIPToken = DllStructGetData($tToken, "Data")
Return $aResult[0] = 0
EndFunc
Func _GDIPlus_StringFormatCreate($iFormat = 0, $iLangID = 0)
Local $aResult = DllCall($ghGDIPDll, "int", "GdipCreateStringFormat", "int", $iFormat, "word", $iLangID, "ptr*", 0)
If @error Then Return SetError(@error, @extended, 0)
Return SetExtended($aResult[0], $aResult[3])
EndFunc
Func _GDIPlus_StringFormatDispose($hFormat)
Local $aResult = DllCall($ghGDIPDll, "int", "GdipDeleteStringFormat", "handle", $hFormat)
If @error Then Return SetError(@error, @extended, False)
Return $aResult[0] = 0
EndFunc
Func _ArrayAdd(ByRef $avArray, $vValue)
If Not IsArray($avArray) Then Return SetError(1, 0, -1)
If UBound($avArray, 0) <> 1 Then Return SetError(2, 0, -1)
Local $iUBound = UBound($avArray)
ReDim $avArray[$iUBound + 1]
$avArray[$iUBound] = $vValue
Return $iUBound
EndFunc
Func _ArrayDelete(ByRef $avArray, $iElement)
If Not IsArray($avArray) Then Return SetError(1, 0, 0)
Local $iUBound = UBound($avArray, 1) - 1
If Not $iUBound Then
$avArray = ""
Return 0
EndIf
If $iElement < 0 Then $iElement = 0
If $iElement > $iUBound Then $iElement = $iUBound
Switch UBound($avArray, 0)
Case 1
For $i = $iElement To $iUBound - 1
$avArray[$i] = $avArray[$i + 1]
Next
ReDim $avArray[$iUBound]
Case 2
Local $iSubMax = UBound($avArray, 2) - 1
For $i = $iElement To $iUBound - 1
For $j = 0 To $iSubMax
$avArray[$i][$j] = $avArray[$i + 1][$j]
Next
Next
ReDim $avArray[$iUBound][$iSubMax + 1]
Case Else
Return SetError(3, 0, 0)
EndSwitch
Return $iUBound
EndFunc
Func _ArrayDisplay(Const ByRef $avArray, $sTitle = "Array: ListView Display", $iItemLimit = -1, $iTranspose = 0, $sSeparator = "", $sReplace = "|", $sHeader = "")
If Not IsArray($avArray) Then Return SetError(1, 0, 0)
Local $iDimension = UBound($avArray, 0), $iUBound = UBound($avArray, 1) - 1, $iSubMax = UBound($avArray, 2) - 1
If $iDimension > 2 Then Return SetError(2, 0, 0)
If $sSeparator = "" Then $sSeparator = Chr(124)
If _ArraySearch($avArray, $sSeparator, 0, 0, 0, 1) <> -1 Then
For $x = 1 To 255
If $x >= 32 And $x <= 127 Then ContinueLoop
Local $sFind = _ArraySearch($avArray, Chr($x), 0, 0, 0, 1)
If $sFind = -1 Then
$sSeparator = Chr($x)
ExitLoop
EndIf
Next
EndIf
Local $vTmp, $iBuffer = 4094
Local $iColLimit = 250
Local $iOnEventMode = Opt("GUIOnEventMode", 0), $sDataSeparatorChar = Opt("GUIDataSeparatorChar", $sSeparator)
If $iSubMax < 0 Then $iSubMax = 0
If $iTranspose Then
$vTmp = $iUBound
$iUBound = $iSubMax
$iSubMax = $vTmp
EndIf
If $iSubMax > $iColLimit Then $iSubMax = $iColLimit
If $iItemLimit < 1 Then $iItemLimit = $iUBound
If $iUBound > $iItemLimit Then $iUBound = $iItemLimit
If $sHeader = "" Then
$sHeader = "Row  "
For $i = 0 To $iSubMax
$sHeader &= $sSeparator & "Col " & $i
Next
EndIf
Local $avArrayText[$iUBound + 1]
For $i = 0 To $iUBound
$avArrayText[$i] = "[" & $i & "]"
For $j = 0 To $iSubMax
If $iDimension = 1 Then
If $iTranspose Then
$vTmp = $avArray[$j]
Else
$vTmp = $avArray[$i]
EndIf
Else
If $iTranspose Then
$vTmp = $avArray[$j][$i]
Else
$vTmp = $avArray[$i][$j]
EndIf
EndIf
$vTmp = StringReplace($vTmp, $sSeparator, $sReplace, 0, 1)
If StringLen($vTmp) > $iBuffer Then $vTmp = StringLeft($vTmp, $iBuffer)
$avArrayText[$i] &= $sSeparator & $vTmp
Next
Next
Local Const $_ARRAYCONSTANT_GUI_DOCKBORDERS = 0x66
Local Const $_ARRAYCONSTANT_GUI_DOCKBOTTOM = 0x40
Local Const $_ARRAYCONSTANT_GUI_DOCKHEIGHT = 0x0200
Local Const $_ARRAYCONSTANT_GUI_DOCKLEFT = 0x2
Local Const $_ARRAYCONSTANT_GUI_DOCKRIGHT = 0x4
Local Const $_ARRAYCONSTANT_GUI_EVENT_CLOSE = -3
Local Const $_ARRAYCONSTANT_LVM_GETCOLUMNWIDTH =(0x1000 + 29)
Local Const $_ARRAYCONSTANT_LVM_GETITEMCOUNT =(0x1000 + 4)
Local Const $_ARRAYCONSTANT_LVM_GETITEMSTATE =(0x1000 + 44)
Local Const $_ARRAYCONSTANT_LVM_SETEXTENDEDLISTVIEWSTYLE =(0x1000 + 54)
Local Const $_ARRAYCONSTANT_LVS_EX_FULLROWSELECT = 0x20
Local Const $_ARRAYCONSTANT_LVS_EX_GRIDLINES = 0x1
Local Const $_ARRAYCONSTANT_LVS_SHOWSELALWAYS = 0x8
Local Const $_ARRAYCONSTANT_WS_EX_CLIENTEDGE = 0x0200
Local Const $_ARRAYCONSTANT_WS_MAXIMIZEBOX = 0x00010000
Local Const $_ARRAYCONSTANT_WS_MINIMIZEBOX = 0x00020000
Local Const $_ARRAYCONSTANT_WS_SIZEBOX = 0x00040000
Local $iWidth = 640, $iHeight = 480
Local $hGUI = GUICreate($sTitle, $iWidth, $iHeight, Default, Default, BitOR($_ARRAYCONSTANT_WS_SIZEBOX, $_ARRAYCONSTANT_WS_MINIMIZEBOX, $_ARRAYCONSTANT_WS_MAXIMIZEBOX))
Local $aiGUISize = WinGetClientSize($hGUI)
Local $hListView = GUICtrlCreateListView($sHeader, 0, 0, $aiGUISize[0], $aiGUISize[1] - 26, $_ARRAYCONSTANT_LVS_SHOWSELALWAYS)
Local $hCopy = GUICtrlCreateButton("Copy Selected", 3, $aiGUISize[1] - 23, $aiGUISize[0] - 6, 20)
GUICtrlSetResizing($hListView, $_ARRAYCONSTANT_GUI_DOCKBORDERS)
GUICtrlSetResizing($hCopy, $_ARRAYCONSTANT_GUI_DOCKLEFT + $_ARRAYCONSTANT_GUI_DOCKRIGHT + $_ARRAYCONSTANT_GUI_DOCKBOTTOM + $_ARRAYCONSTANT_GUI_DOCKHEIGHT)
GUICtrlSendMsg($hListView, $_ARRAYCONSTANT_LVM_SETEXTENDEDLISTVIEWSTYLE, $_ARRAYCONSTANT_LVS_EX_GRIDLINES, $_ARRAYCONSTANT_LVS_EX_GRIDLINES)
GUICtrlSendMsg($hListView, $_ARRAYCONSTANT_LVM_SETEXTENDEDLISTVIEWSTYLE, $_ARRAYCONSTANT_LVS_EX_FULLROWSELECT, $_ARRAYCONSTANT_LVS_EX_FULLROWSELECT)
GUICtrlSendMsg($hListView, $_ARRAYCONSTANT_LVM_SETEXTENDEDLISTVIEWSTYLE, $_ARRAYCONSTANT_WS_EX_CLIENTEDGE, $_ARRAYCONSTANT_WS_EX_CLIENTEDGE)
For $i = 0 To $iUBound
GUICtrlCreateListViewItem($avArrayText[$i], $hListView)
Next
$iWidth = 0
For $i = 0 To $iSubMax + 1
$iWidth += GUICtrlSendMsg($hListView, $_ARRAYCONSTANT_LVM_GETCOLUMNWIDTH, $i, 0)
Next
If $iWidth < 250 Then $iWidth = 230
$iWidth += 20
If $iWidth > @DesktopWidth Then $iWidth = @DesktopWidth - 100
WinMove($hGUI, "",(@DesktopWidth - $iWidth) / 2, Default, $iWidth)
GUISetState(@SW_SHOW, $hGUI)
While 1
Switch GUIGetMsg()
Case $_ARRAYCONSTANT_GUI_EVENT_CLOSE
ExitLoop
Case $hCopy
Local $sClip = ""
Local $aiCurItems[1] = [0]
For $i = 0 To GUICtrlSendMsg($hListView, $_ARRAYCONSTANT_LVM_GETITEMCOUNT, 0, 0)
If GUICtrlSendMsg($hListView, $_ARRAYCONSTANT_LVM_GETITEMSTATE, $i, 0x2) Then
$aiCurItems[0] += 1
ReDim $aiCurItems[$aiCurItems[0] + 1]
$aiCurItems[$aiCurItems[0]] = $i
EndIf
Next
If Not $aiCurItems[0] Then
For $sItem In $avArrayText
$sClip &= $sItem & @CRLF
Next
Else
For $i = 1 To UBound($aiCurItems) - 1
$sClip &= $avArrayText[$aiCurItems[$i]] & @CRLF
Next
EndIf
ClipPut($sClip)
EndSwitch
WEnd
GUIDelete($hGUI)
Opt("GUIOnEventMode", $iOnEventMode)
Opt("GUIDataSeparatorChar", $sDataSeparatorChar)
Return 1
EndFunc
Func _ArrayPop(ByRef $avArray)
If(Not IsArray($avArray)) Then Return SetError(1, 0, "")
If UBound($avArray, 0) <> 1 Then Return SetError(2, 0, "")
Local $iUBound = UBound($avArray) - 1, $sLastVal = $avArray[$iUBound]
If Not $iUBound Then
$avArray = ""
Else
ReDim $avArray[$iUBound]
EndIf
Return $sLastVal
EndFunc
Func _ArrayReverse(ByRef $avArray, $iStart = 0, $iEnd = 0)
If Not IsArray($avArray) Then Return SetError(1, 0, 0)
If UBound($avArray, 0) <> 1 Then Return SetError(3, 0, 0)
Local $vTmp, $iUBound = UBound($avArray) - 1
If $iEnd < 1 Or $iEnd > $iUBound Then $iEnd = $iUBound
If $iStart < 0 Then $iStart = 0
If $iStart > $iEnd Then Return SetError(2, 0, 0)
For $i = $iStart To Int(($iStart + $iEnd - 1) / 2)
$vTmp = $avArray[$i]
$avArray[$i] = $avArray[$iEnd]
$avArray[$iEnd] = $vTmp
$iEnd -= 1
Next
Return 1
EndFunc
Func _ArraySearch(Const ByRef $avArray, $vValue, $iStart = 0, $iEnd = 0, $iCase = 0, $iCompare = 0, $iForward = 1, $iSubItem = -1)
If Not IsArray($avArray) Then Return SetError(1, 0, -1)
If UBound($avArray, 0) > 2 Or UBound($avArray, 0) < 1 Then Return SetError(2, 0, -1)
Local $iUBound = UBound($avArray) - 1
If $iEnd < 1 Or $iEnd > $iUBound Then $iEnd = $iUBound
If $iStart < 0 Then $iStart = 0
If $iStart > $iEnd Then Return SetError(4, 0, -1)
Local $iStep = 1
If Not $iForward Then
Local $iTmp = $iStart
$iStart = $iEnd
$iEnd = $iTmp
$iStep = -1
EndIf
Local $iCompType = False
If $iCompare = 2 Then
$iCompare = 0
$iCompType = True
EndIf
Switch UBound($avArray, 0)
Case 1
If Not $iCompare Then
If Not $iCase Then
For $i = $iStart To $iEnd Step $iStep
If $iCompType And VarGetType($avArray[$i]) <> VarGetType($vValue) Then ContinueLoop
If $avArray[$i] = $vValue Then Return $i
Next
Else
For $i = $iStart To $iEnd Step $iStep
If $iCompType And VarGetType($avArray[$i]) <> VarGetType($vValue) Then ContinueLoop
If $avArray[$i] == $vValue Then Return $i
Next
EndIf
Else
For $i = $iStart To $iEnd Step $iStep
If StringInStr($avArray[$i], $vValue, $iCase) > 0 Then Return $i
Next
EndIf
Case 2
Local $iUBoundSub = UBound($avArray, 2) - 1
If $iSubItem > $iUBoundSub Then $iSubItem = $iUBoundSub
If $iSubItem < 0 Then
$iSubItem = 0
Else
$iUBoundSub = $iSubItem
EndIf
For $j = $iSubItem To $iUBoundSub
If Not $iCompare Then
If Not $iCase Then
For $i = $iStart To $iEnd Step $iStep
If $iCompType And VarGetType($avArray[$i][$j]) <> VarGetType($vValue) Then ContinueLoop
If $avArray[$i][$j] = $vValue Then Return $i
Next
Else
For $i = $iStart To $iEnd Step $iStep
If $iCompType And VarGetType($avArray[$i][$j]) <> VarGetType($vValue) Then ContinueLoop
If $avArray[$i][$j] == $vValue Then Return $i
Next
EndIf
Else
For $i = $iStart To $iEnd Step $iStep
If StringInStr($avArray[$i][$j], $vValue, $iCase) > 0 Then Return $i
Next
EndIf
Next
Case Else
Return SetError(7, 0, -1)
EndSwitch
Return SetError(6, 0, -1)
EndFunc
Func _ArraySort(ByRef $avArray, $iDescending = 0, $iStart = 0, $iEnd = 0, $iSubItem = 0)
If Not IsArray($avArray) Then Return SetError(1, 0, 0)
Local $iUBound = UBound($avArray) - 1
If $iEnd < 1 Or $iEnd > $iUBound Then $iEnd = $iUBound
If $iStart < 0 Then $iStart = 0
If $iStart > $iEnd Then Return SetError(2, 0, 0)
Switch UBound($avArray, 0)
Case 1
__ArrayQuickSort1D($avArray, $iStart, $iEnd)
If $iDescending Then _ArrayReverse($avArray, $iStart, $iEnd)
Case 2
Local $iSubMax = UBound($avArray, 2) - 1
If $iSubItem > $iSubMax Then Return SetError(3, 0, 0)
If $iDescending Then
$iDescending = -1
Else
$iDescending = 1
EndIf
__ArrayQuickSort2D($avArray, $iDescending, $iStart, $iEnd, $iSubItem, $iSubMax)
Case Else
Return SetError(4, 0, 0)
EndSwitch
Return 1
EndFunc
Func __ArrayQuickSort1D(ByRef $avArray, ByRef $iStart, ByRef $iEnd)
If $iEnd <= $iStart Then Return
Local $vTmp
If($iEnd - $iStart) < 15 Then
Local $vCur
For $i = $iStart + 1 To $iEnd
$vTmp = $avArray[$i]
If IsNumber($vTmp) Then
For $j = $i - 1 To $iStart Step -1
$vCur = $avArray[$j]
If($vTmp >= $vCur And IsNumber($vCur)) Or(Not IsNumber($vCur) And StringCompare($vTmp, $vCur) >= 0) Then ExitLoop
$avArray[$j + 1] = $vCur
Next
Else
For $j = $i - 1 To $iStart Step -1
If(StringCompare($vTmp, $avArray[$j]) >= 0) Then ExitLoop
$avArray[$j + 1] = $avArray[$j]
Next
EndIf
$avArray[$j + 1] = $vTmp
Next
Return
EndIf
Local $L = $iStart, $R = $iEnd, $vPivot = $avArray[Int(($iStart + $iEnd) / 2)], $fNum = IsNumber($vPivot)
Do
If $fNum Then
While($avArray[$L] < $vPivot And IsNumber($avArray[$L])) Or(Not IsNumber($avArray[$L]) And StringCompare($avArray[$L], $vPivot) < 0)
$L += 1
WEnd
While($avArray[$R] > $vPivot And IsNumber($avArray[$R])) Or(Not IsNumber($avArray[$R]) And StringCompare($avArray[$R], $vPivot) > 0)
$R -= 1
WEnd
Else
While(StringCompare($avArray[$L], $vPivot) < 0)
$L += 1
WEnd
While(StringCompare($avArray[$R], $vPivot) > 0)
$R -= 1
WEnd
EndIf
If $L <= $R Then
$vTmp = $avArray[$L]
$avArray[$L] = $avArray[$R]
$avArray[$R] = $vTmp
$L += 1
$R -= 1
EndIf
Until $L > $R
__ArrayQuickSort1D($avArray, $iStart, $R)
__ArrayQuickSort1D($avArray, $L, $iEnd)
EndFunc
Func __ArrayQuickSort2D(ByRef $avArray, ByRef $iStep, ByRef $iStart, ByRef $iEnd, ByRef $iSubItem, ByRef $iSubMax)
If $iEnd <= $iStart Then Return
Local $vTmp, $L = $iStart, $R = $iEnd, $vPivot = $avArray[Int(($iStart + $iEnd) / 2)][$iSubItem], $fNum = IsNumber($vPivot)
Do
If $fNum Then
While($iStep *($avArray[$L][$iSubItem] - $vPivot) < 0 And IsNumber($avArray[$L][$iSubItem])) Or(Not IsNumber($avArray[$L][$iSubItem]) And $iStep * StringCompare($avArray[$L][$iSubItem], $vPivot) < 0)
$L += 1
WEnd
While($iStep *($avArray[$R][$iSubItem] - $vPivot) > 0 And IsNumber($avArray[$R][$iSubItem])) Or(Not IsNumber($avArray[$R][$iSubItem]) And $iStep * StringCompare($avArray[$R][$iSubItem], $vPivot) > 0)
$R -= 1
WEnd
Else
While($iStep * StringCompare($avArray[$L][$iSubItem], $vPivot) < 0)
$L += 1
WEnd
While($iStep * StringCompare($avArray[$R][$iSubItem], $vPivot) > 0)
$R -= 1
WEnd
EndIf
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
__ArrayQuickSort2D($avArray, $iStep, $iStart, $R, $iSubItem, $iSubMax)
__ArrayQuickSort2D($avArray, $iStep, $L, $iEnd, $iSubItem, $iSubMax)
EndFunc
Func _ArrayToString(Const ByRef $avArray, $sDelim = "|", $iStart = 0, $iEnd = 0)
If Not IsArray($avArray) Then Return SetError(1, 0, "")
If UBound($avArray, 0) <> 1 Then Return SetError(3, 0, "")
Local $sResult, $iUBound = UBound($avArray) - 1
If $iEnd < 1 Or $iEnd > $iUBound Then $iEnd = $iUBound
If $iStart < 0 Then $iStart = 0
If $iStart > $iEnd Then Return SetError(2, 0, "")
For $i = $iStart To $iEnd
$sResult &= $avArray[$i] & $sDelim
Next
Return StringTrimRight($sResult, StringLen($sDelim))
EndFunc
Func _StringRepeat($sString, $iRepeatCount)
Local $sResult
Select
Case Not StringIsInt($iRepeatCount)
SetError(1)
Return ""
Case StringLen($sString) < 1
SetError(1)
Return ""
Case $iRepeatCount <= 0
SetError(1)
Return ""
Case Else
For $iCount = 1 To $iRepeatCount
$sResult &= $sString
Next
Return $sResult
EndSelect
EndFunc
Func _StringReverse($s_String)
Local $i_len = StringLen($s_String)
If $i_len < 1 Then Return SetError(1, 0, "")
Local $t_chars = DllStructCreate("char[" & $i_len + 1 & "]")
DllStructSetData($t_chars, 1, $s_String)
Local $a_rev = DllCall("msvcrt.dll", "ptr:cdecl", "_strrev", "struct*", $t_chars)
If @error Or $a_rev[0] = 0 Then Return SetError(2, 0, "")
Return DllStructGetData($t_chars, 1)
EndFunc
Func _FileCreate($sFilePath)
Local $hOpenFile = FileOpen($sFilePath, $FO_OVERWRITE)
If $hOpenFile = -1 Then Return SetError(1, 0, 0)
Local $hWriteFile = FileWrite($hOpenFile, "")
FileClose($hOpenFile)
If $hWriteFile = -1 Then Return SetError(2, 0, 0)
Return 1
EndFunc
Func _FileListToArray($sPath, $sFilter = "*", $iFlag = 0)
Local $hSearch, $sFile, $sFileList, $sDelim = "|"
$sPath = StringRegExpReplace($sPath, "[\\/]+\z", "") & "\"
If Not FileExists($sPath) Then Return SetError(1, 1, "")
If StringRegExp($sFilter, "[\\/:><\|]|(?s)\A\s*\z") Then Return SetError(2, 2, "")
If Not($iFlag = 0 Or $iFlag = 1 Or $iFlag = 2) Then Return SetError(3, 3, "")
$hSearch = FileFindFirstFile($sPath & $sFilter)
If @error Then Return SetError(4, 4, "")
While 1
$sFile = FileFindNextFile($hSearch)
If @error Then ExitLoop
If($iFlag + @extended = 2) Then ContinueLoop
$sFileList &= $sDelim & $sFile
WEnd
FileClose($hSearch)
If Not $sFileList Then Return SetError(4, 4, "")
Return StringSplit(StringTrimLeft($sFileList, 1), "|")
EndFunc
Dim $ID3Filenames = "",$AlbumArtFilename = ""
Dim $ID3BufferArray[1] = [0]
Func _ID3ReadTag($Filename, $iVersion = 0, $sFilter = -1, $iReturnArray = 0)
If Not(FileExists($Filename)) Then Return 0
Dim $ID3BufferArray[1] = [0]
Switch $iVersion
Case 0
_ReadID3v2($Filename,$ID3BufferArray,$sFilter)
_ReadID3v1($Filename,$ID3BufferArray)
Case 1
_ReadID3v1($Filename,$ID3BufferArray)
Case 2
_ReadID3v2($Filename,$ID3BufferArray,$sFilter)
EndSwitch
_ArrayAdd($ID3BufferArray,'Filename' & '|' & $Filename)
$ID3BufferArray[0] += 1
SetError(0)
If $iReturnArray = 1 Then
Local $ID3Array[1] = [0]
For $i = 3 To $ID3BufferArray[0]
$ID3FrameArray = StringSplit($ID3BufferArray[$i], "|")
_ArrayAdd($ID3Array,$ID3FrameArray[1] & "|" & _ID3GetTagField($ID3FrameArray[1]))
$ID3Array[0] += 1
Next
Return $ID3Array
Elseif $iReturnArray = 2 Then
Local $ID3FullArray[$ID3BufferArray[0]][5]
For $i = 1 To $ID3BufferArray[0]
$ID3FrameArray = StringSplit($ID3BufferArray[$i], "|")
$ID3FullArray[$i-1][0] = $ID3FrameArray[1]
$ID3FullArray[$i-1][1] = $ID3FrameArray[2]
Next
Return $ID3FullArray
Else
Return 1
EndIf
EndFunc
Func _ID3GetTagField($sFieldIDRequest)
If $ID3BufferArray[0] == 0 Then
SetError(1)
Return ""
EndIf
Local $sFieldID, $sFieldString = "", $TagFound = False, $NumFound = 0
For $i = 1 To $ID3BufferArray[0]
$aBufferFrameString = StringSplit($ID3BufferArray[$i],"|")
If $aBufferFrameString[0] > 1 Then
$sFieldID = $aBufferFrameString[1]
If $sFieldID == $sFieldIDRequest Then
$TagFound = True
$sFieldString = _GetID3FrameString($ID3BufferArray[$i])
EndIf
EndIf
Next
SetError(Not($TagFound),$NumFound)
Return $sFieldString
EndFunc
Func _ID3SetTagField($sFieldIDRequest, $sFieldValue)
Local $FrameID = ""
Local $FrameIDFound = False, $tagSIZE = 0
Local $ArrayIndex = 0, $TagSizeIndex = 0
For $i = 1 To $ID3BufferArray[0]
$aBufferFrameString = StringSplit($ID3BufferArray[$i],"|")
If $aBufferFrameString[0] > 1 Then
$FrameID = $aBufferFrameString[1]
If $FrameID == "TagSize" Then
$tagSIZE = Number($aBufferFrameString[2])
$TagSizeIndex = $i
EndIf
If StringCompare($FrameID, $sFieldIDRequest,1) == 0 Then
$FrameIDFound = True
$ArrayIndex = $i
ExitLoop
EndIf
EndIf
Next
If Not $FrameIDFound Then
_ArrayAdd($ID3BufferArray,"")
$ID3BufferArray[0] += 1
$ArrayIndex = $ID3BufferArray[0]
$FrameID = $sFieldIDRequest
EndIf
If(StringMid($FrameID,1,1) == "T") and(StringLen($FrameID) == 4) and($FrameID <> "TXXX") Then
$bFrameData = Binary("0x00")
$bFrameData &= StringToBinary($sFieldValue)
$ID3BufferArray[$ArrayIndex] = $FrameID & "|" & $bFrameData & "|" & BinaryLen($bFrameData)
Elseif $FrameID == "TXXX" Then
$bFrameData = Binary("0x00")
$bFrameData = Binary("0x00")
$bFrameData &= StringToBinary($sFieldValue)
$ID3BufferArray[$ArrayIndex] = $FrameID & "|" & $bFrameData & "|" & BinaryLen($bFrameData)
ElseIf(StringMid($FrameID,1,1) == "W") and(StringLen($FrameID) == 4) and($FrameID <> "WXXX") Then
$bFrameData = StringToBinary($sFieldValue)
$ID3BufferArray[$ArrayIndex] = $FrameID & "|" & $bFrameData & "|" & BinaryLen($bFrameData)
ElseIf $FrameID == "WXXX" Then
$bFrameData = Binary("0x00")
$bFrameData = Binary("0x00")
$bFrameData &= StringToBinary($sFieldValue)
$ID3BufferArray[$ArrayIndex] = $FrameID & "|" & $bFrameData & "|" & BinaryLen($bFrameData)
Else
Switch $FrameID
Case "COMM"
$bFrameData = Binary("0x00")
$bFrameData &= StringToBinary("eng")
$bFrameData &= Binary("0x00")
if isbinary($sFieldValue) then
$bFrameData &= $sFieldValue
Else
$bFrameData &= StringToBinary($sFieldValue)
EndIf
$ID3BufferArray[$ArrayIndex] = $FrameID & "|" & $bFrameData & "|" & BinaryLen($bFrameData)
Case "APIC"
$bFrameData = Binary("0x00")
If StringRight($sFieldValue,3) = "png" Then
$bFrameData &= StringToBinary("image/png") & Binary("0x00")
Else
$bFrameData &= StringToBinary("image/jpg") & Binary("0x00")
EndIf
$bFrameData &= Binary("0x03")
$bFrameData &= StringToBinary("Cover Image") & Binary("0x00")
$FrameSize = FileGetSize($sFieldValue) + BinaryLen($bFrameData)
$ID3BufferArray[$ArrayIndex] = $FrameID & "|" & $bFrameData & "|" & $sFieldValue & "|" & $FrameSize
Case "USLT"
$bFrameData = Binary("0x00")
$bFrameData &= StringToBinary("eng")
$bFrameData &= Binary("0x00")
$FrameSize = FileGetSize($sFieldValue) + BinaryLen($bFrameData)
$ID3BufferArray[$ArrayIndex] = $FrameID & "|" & $bFrameData & "|" & $sFieldValue & "|" & $FrameSize
Case "SYLT"
$bFrameData = Binary("0x00")
$bFrameData &= StringToBinary("eng")
$bFrameData &= Binary("0x02")
$bFrameData &= Binary("0x01")
$bFrameData &= Binary("0x00")
$FrameSize = FileGetSize($sFieldValue) + BinaryLen($bFrameData)
$ID3BufferArray[$ArrayIndex] = $FrameID & "|" & $bFrameData & "|" & $sFieldValue & "|" & $FrameSize
Case "UFID"
Case "Title" Or "Artist" Or "Album" Or "Year" or "Track" Or "Comment" or "Genre"
$ID3BufferArray[$ArrayIndex] = $FrameID & "|" & $sFieldValue
EndSwitch
EndIf
EndFunc
Func _ID3WriteTag($Filename,$iFlag = 0)
Dim $ZPAD = Binary("0x00")
Local $TagFile = StringTrimRight($Filename,4) & "_ID3TAG.mp3"
If Not _FileCreate($TagFile) Then Return MsgBox(16,'错误','无法创建临时文件')
Local $OldTagSize = 0, $ID3v1Tag = StringToBinary("TAG"), $ID3v1_Artist = ""
Local $ID3v1_Title = "",$ID3v1_Album = "",$ID3v1_Year = "",$ID3v1_Comment = ""
Local $ID3v1_Genre = "", $ID3v1_Track = ""
Local $hfile,$hTagFile
$hTagFile = Fileopen($TagFile,2)
Switch $iFlag
Case 0
FileWrite($hTagFile,StringToBinary("ID3"))
FileWrite($hTagFile,Binary("0x" & Hex(Number(3),2)))
FileWrite($hTagFile,Binary("0x" & Hex(Number(0),2)))
FileWrite($hTagFile,Binary("0x00"))
Dim $NewTagSize = 0
For $i = 1 To $ID3BufferArray[0]
$aBufferFrameString = StringSplit($ID3BufferArray[$i],"|")
If $aBufferFrameString[0] > 2 Then
$NewTagSize += Number($aBufferFrameString[$aBufferFrameString[0]]) + 10
EndIf
If $aBufferFrameString[1] == "ZPAD" Then
$NewTagSize += Number($aBufferFrameString[$aBufferFrameString[0]])
EndIf
Next
$sTagSize = $NewTagSize
$iTagSize = Hex($NewTagSize)
$bTagSize = _HexToBin_ID3($iTagSize)
$bTagSize = _StringReverse($bTagSize)
$bTagSize = StringLeft($bTagSize,28)
$TagHeaderBin = StringMid($bTagSize,1,7) & "0" & StringMid($bTagSize,8,7) & "0" & StringMid($bTagSize,15,7) & "0" & StringMid($bTagSize,22,7) & "0"
$TagHeaderBin = _StringReverse($TagHeaderBin)
$TagHeader = _BinToHex_ID3($TagHeaderBin)
FileWrite($hTagFile,Binary("0x" & $TagHeader))
For $i = 1 To $ID3BufferArray[0]
$aBufferFrameString = StringSplit($ID3BufferArray[$i],"|")
If $aBufferFrameString[1] == "ZPAD" Then
For $iZPAD = 2 to Number($aBufferFrameString[$aBufferFrameString[0]])
$ZPAD &= Binary("0x00")
Next
$NewTagSize += Number($aBufferFrameString[$aBufferFrameString[0]])
ElseIf $aBufferFrameString[1] == "TagSize" Then
$OldTagSize = Number($aBufferFrameString[2])
ElseIf $aBufferFrameString[1] == "Title" Then
$ID3v1_Title = StringToBinary(StringLeft($aBufferFrameString[2],30))
for $iPAD = 1 to(30 - BinaryLen($ID3v1_Title))
$ID3v1_Title &= Binary("0x00")
Next
ElseIf $aBufferFrameString[1] == "Artist" Then
$ID3v1_Artist = StringToBinary(StringLeft($aBufferFrameString[2],30))
for $iPAD = 1 to(30 - BinaryLen($ID3v1_Artist))
$ID3v1_Artist &= Binary("0x00")
Next
ElseIf $aBufferFrameString[1] == "Album" Then
$ID3v1_Album = StringToBinary(StringLeft($aBufferFrameString[2],30))
for $iPAD = 1 to(30 - BinaryLen($ID3v1_Album))
$ID3v1_Album &= Binary("0x00")
Next
ElseIf $aBufferFrameString[1] == "Year" Then
$ID3v1_Year = StringToBinary(StringLeft($aBufferFrameString[2],4))
ElseIf $aBufferFrameString[1] == "Comment" Then
$ID3v1_Comment = StringToBinary(StringLeft($aBufferFrameString[2],28))
for $iPAD = 1 to(28 - BinaryLen($ID3v1_Comment))
$ID3v1_Comment &= Binary("0x00")
Next
ElseIf $aBufferFrameString[1] == "Track" Then
$ID3v1_Track = StringLeft($aBufferFrameString[2],3)
ElseIf $aBufferFrameString[1] == "Genre" Then
$ID3v1_Genre = $aBufferFrameString[2]
EndIf
If $aBufferFrameString[0] > 2 Then
If $aBufferFrameString[1] == "APIC" Then
FileWrite($hTagFile,StringToBinary($aBufferFrameString[1]))
FileWrite($hTagFile,Binary("0x" & Hex($aBufferFrameString[$aBufferFrameString[0]],8)))
FileWrite($hTagFile,Binary("0x" & Hex(0,2)))
FileWrite($hTagFile,Binary("0x" & Hex(0,2)))
FileWrite($hTagFile,Binary($aBufferFrameString[2]))
$PicFile_h = FileOpen($aBufferFrameString[3], 16)
$WriteError = FileWrite($hTagFile,FileRead($PicFile_h))
FileClose($PicFile_h)
ElseIf $aBufferFrameString[1] == "USLT" Or $aBufferFrameString[1] == "SYLT" Then
FileWrite($hTagFile,StringToBinary($aBufferFrameString[1]))
FileWrite($hTagFile,Binary("0x" & Hex($aBufferFrameString[$aBufferFrameString[0]],8)))
FileWrite($hTagFile,Binary("0x" & Hex(0,2)))
FileWrite($hTagFile,Binary("0x" & Hex(0,2)))
FileWrite($hTagFile,Binary($aBufferFrameString[2]))
$LyricsFile_h = FileOpen($aBufferFrameString[3], 16)
$LyricData = FileRead($LyricsFile_h)
$WriteError = FileWrite($hTagFile,$LyricData)
FileClose($LyricsFile_h)
Else
FileWrite($hTagFile,StringToBinary($aBufferFrameString[1]))
FileWrite($hTagFile,Binary("0x" & Hex($aBufferFrameString[$aBufferFrameString[0]],8)))
FileWrite($hTagFile,Binary("0x" & Hex(0,2)))
FileWrite($hTagFile,Binary("0x" & Hex(0,2)))
FileWrite($hTagFile,Binary($aBufferFrameString[2]))
EndIf
$NewTagSize += Number($aBufferFrameString[$aBufferFrameString[0]]) + 10
EndIf
Next
FileWrite($hTagFile,$ZPAD)
$hFile = FileOpen($Filename,16)
FileSetPos($hFile, $OldTagSize, $FILE_BEGIN)
FileWrite($hTagFile,FileRead($hFile,FileGetSize($Filename) - 128 - $OldTagSize))
$ID3v1Tag &= $ID3v1_Title
$ID3v1Tag &= $ID3v1_Artist
$ID3v1Tag &= $ID3v1_Album
$ID3v1Tag &= $ID3v1_Year
$ID3v1Tag &= $ID3v1_Comment
$ID3v1Tag &= Binary("0x00")
$ID3v1Tag &= Binary("0x" & Hex(Number($ID3v1_Track),2))
$ID3v1Tag &= Binary("0x" & Hex(_GetGenreID($ID3v1_Genre),2))
FileWrite($hTagFile,$ID3v1Tag)
Case 1
Dim $ID3BufferArray[1] = [0]
$OldTagSize=_ReadID3v2($Filename,$ID3BufferArray,-1,True)
$hFile = FileOpen($Filename,16)
FileSetPos($hFile, $OldTagSize, $FILE_BEGIN)
FileWrite($hTagFile,FileRead($hFile,FileGetSize($Filename) - 128 - $OldTagSize))
$ID3v1Tag=FileRead($hFile)
If Not(BinaryToString(BinaryMid($ID3v1Tag,1,3)) == 'TAG') Then FileWrite($hTagFile,$ID3v1Tag)
EndSwitch
FileClose($hFile)
FileClose($hTagFile)
If not FileMove($TagFile,$Filename,1) Then Return MsgBox(262144,'','无法覆盖原文件或覆盖时出现错误！')
Return 1
EndFunc
Func _ID3DeleteFiles()
If $ID3Filenames == "" Then Return 1
$aID3File = StringSplit($ID3Filenames,"|")
For $i = 1 To $aID3File[0]
If FileExists($aID3File[$i]) Then
$ret = FileDelete($aID3File[$i])
If $ret == 0 Then Return 0
EndIf
Next
$ID3Filenames = ""
Return 1
EndFunc
Func _ReadID3v2($Filename, ByRef $aID3V2Tag, $sFilter = -1, $HeadOnly = False)
Local $ZPAD = 0, $BytesRead = 0
Local $hFile = FileOpen($Filename,16)
Local $iFilterNum
If $sFilter <> -1 Then
$aFilter = StringSplit($sFilter,"|")
$iFilterNum = $aFilter[0]
EndIf
Local $ID3v2Header = FileRead($hFile, 10)
_ArrayAdd($aID3V2Tag,"Header" & "|" & $ID3v2Header)
$aID3V2Tag[0] += 1
$BytesRead = 10
If Not(BinaryToString(BinaryMid($ID3v2Header,1,3)) == "ID3") Then
FileClose($hFile)
SetError(1)
Return 0
EndIf
Local $FrameIDLen
Local $ID3v2Version = String(Number(BinaryMid($ID3v2Header,4,1))) & "." & String(Number(BinaryMid($ID3v2Header,5,1)))
If $sFilter == -1 Then
_ArrayAdd($aID3V2Tag,"Version" & "|" & "ID3v2." & $ID3v2Version)
$aID3V2Tag[0] += 1
EndIf
If StringInStr($ID3v2Version,"2.") Then
$FrameIDLen = 3
If $sFilter <> -1 Then
_ConvertFilterToID3v2_2($sFilter)
EndIf
Else
$FrameIDLen = 4
EndIf
Local $TagFlagsBin = BinaryMid($ID3v2Header,6,1)
Local $TagFlags = _HexToBin_ID3(StringTrimLeft($TagFlagsBin,2))
Local $Unsynchronisation = StringMid($TagFlags,1,1)
Local $ExtendedHeader = StringMid($TagFlags,2,1)
Local $ExperimentalIndicator = StringMid($TagFlags,3,1)
Local $Footer = StringMid($TagFlags,4,1)
If Not $TagFlags == "00000000" Then
EndIf
If $sFilter == -1 Then
_ArrayAdd($aID3V2Tag,"Unsynchronisation" & "|" & $Unsynchronisation)
_ArrayAdd($aID3V2Tag,"ExtendedHeader" & "|" & $ExtendedHeader)
_ArrayAdd($aID3V2Tag,"ExperimentalIndicator" & "|" & $ExperimentalIndicator)
_ArrayAdd($aID3V2Tag,"Footer" & "|" & $Footer)
$aID3V2Tag[0] += 4
EndIf
Local $TagSizeBin = ""
$TagHeaderBin = _HexToBin_ID3(StringTrimLeft(BinaryMid($ID3v2Header,7,4),2))
For $i = 1 To 33 Step 8
$TagSizeBin &= StringMid($TagHeaderBin,$i + 1,7)
Next
Local $tagSIZE = Dec(_BinToHex_ID3($TagSizeBin)) + 10
If($sFilter == -1) or StringInStr($sFilter,"TagSize") Then
_ArrayAdd($aID3V2Tag,"TagSize" & "|" & $tagSIZE)
$aID3V2Tag[0] += 1
If $aID3V2Tag[0] ==($iFilterNum + 1) Then
FileClose($hFile)
Return 1
EndIf
EndIf
If $HeadOnly Then
FileClose($hFile)
Return $tagSIZE
EndIf
Local $ZPadding, $FrameIDFristHex, $FrameID, $FrameSizeHex, $FrameSize, $FrameFlag1, $FrameFlag2, $FoundTag, $index
Local $FrameHeader
While $BytesRead < $tagSIZE
$ZPadding = 0
$FrameIDFristHex = StringTrimLeft(FileRead($hFile,1),2)
$BytesRead += 1
If $FrameIDFristHex == "00" Then
$ZPadding += 1
While $FrameIDFristHex == "00"
$FrameIDFristHex = StringTrimLeft(FileRead($hFile,1),2)
$BytesRead += 1
$ZPadding += 1
If $BytesRead >= $tagSIZE Then
ExitLoop
EndIf
WEnd
$ZPAD = $ZPadding
ExitLoop
Else
$FrameID = Chr(Dec($FrameIDFristHex)) & BinaryToString(FileRead($hFile,$FrameIDLen-1))
$BytesRead += $FrameIDLen-1
If StringIsAlNum($FrameID) Then
If $FrameIDLen == 4 Then
$bFrameHeader = FileRead($hFile,6)
$BytesRead += 6
$FrameSizeHex = StringTrimLeft(BinaryMid($bFrameHeader,1,4),2)
$FrameSize = _HexToUint32_ID3($FrameSizeHex)
$FrameFlag1 = _HexToBin_ID3(StringTrimLeft(BinaryMid($bFrameHeader,5,1),2))
$FrameFlag2 = _HexToBin_ID3(StringTrimLeft(BinaryMid($bFrameHeader,6,1),2))
ElseIf $FrameIDLen == 3 Then
$bFrameHeader = FileRead($hFile,3)
$BytesRead += 3
$FrameSizeHex = StringTrimLeft(BinaryMid($bFrameHeader,1,3),2)
$FrameSize = Dec($FrameSizeHex)
EndIf
If $sFilter == -1 Then
Switch $FrameID
Case "APIC"
$FrameData = _GetAlbumArt($hFile,$FrameSize)
Case "USLT"
$FrameData = _GetSongLyrics($hFile,$FrameSize)
Case "SYLT"
$FrameData = _GetSynLyrics($hFile,$FrameSize)
Case Else
$FrameData = FileRead($hFile,$FrameSize)
EndSwitch
_ArrayAdd($aID3V2Tag,$FrameID & "|" & $FrameData & "|" & $FrameSize)
$aID3V2Tag[0] += 1
$BytesRead += $FrameSize
Else
If $aID3V2Tag[0] ==($iFilterNum + 1) Then
ExitLoop
EndIf
If StringInStr($sFilter,$FrameID) Then
Switch $FrameID
Case "APIC"
$FrameData = _GetAlbumArt($hFile,$FrameSize)
Case "USLT"
$FrameData = _GetSongLyrics($hFile,$FrameSize)
Case "SYLT"
$FrameData = _GetSynLyrics($hFile,$FrameSize)
Case Else
$FrameData = FileRead($hFile,$FrameSize)
EndSwitch
_ArrayAdd($aID3V2Tag,$FrameID & "|" & $FrameData & "|" & $FrameSize)
$aID3V2Tag[0] += 1
Else
FileRead($hFile,$FrameSize)
EndIf
$BytesRead += $FrameSize
EndIf
EndIf
EndIf
WEnd
If($sFilter == -1) or StringInStr($sFilter,"MPEG") or StringInStr($sFilter,"ZPAD") Then
Local $MPEGHeaderCheck = $FrameIDFristHex & StringTrimLeft(FileRead($hFile,50),2)
Local $index = StringInStr($MPEGHeaderCheck,"FF")
Local $MPEGHeaderHex = StringMid($MPEGHeaderCheck,$index,8)
If _CheckMPEGHeader($MPEGHeaderHex) and(StringInStr($sFilter,"MPEG") or($sFilter == -1)) Then
_ArrayAdd($aID3V2Tag,"MPEG" & "|" & $MPEGHeaderHex)
$aID3V2Tag[0] += 1
EndIf
If StringInStr($sFilter,"ZPAD") or($sFilter == -1) Then
_ArrayAdd($aID3V2Tag,"ZPAD" & "|" & $ZPAD)
$aID3V2Tag[0] += 1
EndIf
EndIf
FileClose($hFile)
Return 1
EndFunc
Func _ReadID3v1($Filename, ByRef $aID3V1Tag)
Local $hfile = FileOpen($Filename,16)
FileRead($hfile,FileGetSize($Filename)-128)
Local $ID3v1Tag = FileRead($hfile)
FileClose($hfile)
Local $ID3v1ID = BinaryToString(BinaryMid($ID3v1Tag,1,3))
If Not($ID3v1ID == "TAG") Then
FileClose($hfile)
SetError(-1)
Return 0
EndIf
Local $Title, $Artist, $Album, $Year, $Comment, $Track, $GenreID, $Genre
$Title = BinaryToString(BinaryMid($ID3v1Tag,4,30))
_ArrayAdd($aID3V1Tag,"Title" & "|" & $Title)
$aID3V1Tag[0] += 1
$Artist = BinaryToString(BinaryMid($ID3v1Tag,34,30))
_ArrayAdd($aID3V1Tag,"Artist" & "|" & $Artist)
$aID3V1Tag[0] += 1
$Album = BinaryToString(BinaryMid($ID3v1Tag,64,30))
_ArrayAdd($aID3V1Tag,"Album" & "|" & $Album)
$aID3V1Tag[0] += 1
$Year = BinaryToString(BinaryMid($ID3v1Tag,94,4))
_ArrayAdd($aID3V1Tag,"Year" & "|" & $Year)
$aID3V1Tag[0] += 1
$Comment = BinaryToString(BinaryMid($ID3v1Tag,98,28))
_ArrayAdd($aID3V1Tag,"Comment" & "|" & $Comment)
$aID3V1Tag[0] += 1
$Track = Dec(StringTrimLeft(BinaryMid($ID3v1Tag,126,2),2))
If $Track < 1000 And $Track > 0 Then
_ArrayAdd($aID3V1Tag,"Track" & "|" & $Track)
$aID3V1Tag[0] += 1
Else
_ArrayAdd($aID3V1Tag,"Track" & "|" & "")
$aID3V1Tag[0] += 1
EndIf
$GenreID = Dec(StringTrimLeft(BinaryMid($ID3v1Tag,128,1),2))
$Genre = _GetGenreByID($GenreID)
_ArrayAdd($aID3V1Tag,"Genre" & "|" & $Genre)
$aID3V1Tag[0] += 1
If $Track == 0 Then
_ArrayAdd($aID3V1Tag,"Version1" & "|" & "ID3v1.0")
$aID3V1Tag[0] += 1
Else
_ArrayAdd($aID3V1Tag,"Version1" & "|" & "ID3v1.1")
$aID3V1Tag[0] += 1
EndIf
FileClose($hfile)
Return 1
EndFunc
Func _GetID3FrameString($sFrameData)
Local $bTagFieldFound = False, $sFrameString = ""
Local $bText_Encoding_Description_Byte
Local $bUnicode_BOM
Local $BinaryToString_Flag = 1
$aFrameData = StringSplit($sFrameData,"|")
$FrameID = $aFrameData[1]
If(StringMid($FrameID,1,1) == "T") and(StringLen($FrameID) == 4) and($FrameID <> "TXXX") and($FrameID <> "TCON") Then
$bTagFieldFound = True
$bFrameData = Binary($aFrameData[2])
$bText_Encoding_Description_Byte = Int(BinaryMid($bFrameData,1,1))
If $bText_Encoding_Description_Byte <> 0 Then
$bUnicode_BOM = BinaryMid($bFrameData,2,2)
If $bUnicode_BOM = "0xFFFE" Then
$BinaryToString_Flag = 2
EndIf
If $bUnicode_BOM = "0xFEFF" Then
$BinaryToString_Flag = 3
EndIf
$sFrameString = BinaryToString(BinaryMid($bFrameData,4),$BinaryToString_Flag)
Else
$sFrameString = BinaryToString(BinaryMid($bFrameData,2))
EndIf
Elseif $FrameID == "TXXX" Then
$bTagFieldFound = True
$bFrameData = Binary($aFrameData[2])
$bText_Encoding_Description_Byte = BinaryMid($bFrameData,1,1)
$ByteIndex = 2
$Description = ""
$Byte = ""
$BinaryToString_Flag = 1
If $bText_Encoding_Description_Byte <> 0 Then
If BinaryMid($bFrameData,$ByteIndex,2) = "0xFFFE" Then
$BinaryToString_Flag = 2
$ByteIndex += 2
EndIf
If BinaryMid($bFrameData,$ByteIndex,2) = "0xFEFF" Then
$BinaryToString_Flag = 3
$ByteIndex += 2
EndIf
EndIf
While BinaryMid($bFrameData,$ByteIndex,1) <> "0x00"
$Byte = binary($Byte & BinaryMid($bFrameData,$ByteIndex,1))
$ByteIndex += 1
WEnd
While BinaryMid($bFrameData,$ByteIndex,1) == "0x00"
$ByteIndex += 1
WEnd
$Description = BinaryToString($Byte,$BinaryToString_Flag)
$BinaryToString_Flag = 1
If $bText_Encoding_Description_Byte <> 0 Then
If BinaryMid($bFrameData,$ByteIndex,2) = "0xFFFE" Then
$BinaryToString_Flag = 2
EndIf
If BinaryMid($bFrameData,$ByteIndex,2) = "0xFEFF" Then
$BinaryToString_Flag = 3
EndIf
$ByteIndex += 2
EndIf
$sFrameString = BinaryToString(BinaryMid($bFrameData,$ByteIndex),$BinaryToString_Flag)
If $Description <> "" then
$sFrameString = $Description & "-" & $sFrameString
EndIf
Elseif $FrameID == "TCON" Then
$bTagFieldFound = True
$bFrameData = Binary($aFrameData[2])
$bText_Encoding_Description_Byte = Int(BinaryMid($bFrameData,1,1))
If $bText_Encoding_Description_Byte <> 0 Then
$bUnicode_BOM = BinaryMid($bFrameData,2,2)
If $bUnicode_BOM = "0xFFFE" Then
$BinaryToString_Flag = 2
EndIf
If $bUnicode_BOM = "0xFEFF" Then
$BinaryToString_Flag = 3
EndIf
$Genre = BinaryToString(BinaryMid($bFrameData,4),$BinaryToString_Flag)
Else
$Genre = BinaryToString(BinaryMid($bFrameData,2))
EndIf
If StringMid($Genre,1,1) == "(" Then
$closeparindex = StringInStr($Genre,")")
$GenreID = StringMid($Genre,2,$closeparindex-1)
$Genre = _GetGenreByID($GenreID)
EndIf
$sFrameString = $Genre
ElseIf(StringMid($FrameID,1,1) == "W") and(StringLen($FrameID) == 4) and($FrameID <> "WXXX") Then
$bTagFieldFound = True
$bFrameData = Binary($aFrameData[2])
$sFrameString = BinaryToString($bFrameData)
ElseIf $FrameID == "WXXX" Then
$bTagFieldFound = True
$bFrameData = Binary($aFrameData[2])
$bText_Encoding = BinaryMid($bFrameData,1,1)
$ByteIndex = 2
$Description = ""
$Byte = BinaryMid($bFrameData,$ByteIndex,1)
$ByteIndex += 1
While $Byte <> "0x00"
$Description &= BinaryToString($Byte)
$Byte = BinaryMid($bFrameData,$ByteIndex,1)
$ByteIndex += 1
WEnd
$sFrameString = BinaryToString(BinaryMid($bFrameData,$ByteIndex))
Else
Switch $FrameID
Case "COMM", "COM"
$bTagFieldFound = True
$bFrameData = Binary($aFrameData[2])
$bText_Encoding_Description_Byte = BinaryMid($bFrameData,1,1)
$Language = BinaryToString(BinaryMid($bFrameData,2,3))
if $Language <> "eng" Then
EndIf
$ByteIndex = 5
$Short_Content_Descrip = ""
$Byte = ""
$BinaryToString_Flag = 1
If $bText_Encoding_Description_Byte <> 0 Then
If BinaryMid($bFrameData,$ByteIndex,2) = "0xFFFE" Then
$BinaryToString_Flag = 2
$ByteIndex += 2
EndIf
If BinaryMid($bFrameData,$ByteIndex,2) = "0xFEFF" Then
$BinaryToString_Flag = 3
$ByteIndex += 2
EndIf
EndIf
While BinaryMid($bFrameData,$ByteIndex,1) <> "0x00"
$Byte = binary($Byte & BinaryMid($bFrameData,$ByteIndex,1))
$ByteIndex += 1
WEnd
While BinaryMid($bFrameData,$ByteIndex,1) == "0x00"
$ByteIndex += 1
WEnd
$Short_Content_Descrip = BinaryToString($Byte,$BinaryToString_Flag)
$BinaryToString_Flag = 1
If $bText_Encoding_Description_Byte <> 0 Then
If BinaryMid($bFrameData,$ByteIndex,2) = "0xFFFE" Then
$BinaryToString_Flag = 2
EndIf
If BinaryMid($bFrameData,$ByteIndex,2) = "0xFEFF" Then
$BinaryToString_Flag = 3
EndIf
$ByteIndex += 2
EndIf
$sFrameString = BinaryToString(BinaryMid($bFrameData,$ByteIndex),$BinaryToString_Flag)
If $Short_Content_Descrip <> "" then
$sFrameString = $Short_Content_Descrip & "-" & $sFrameString
EndIf
Case "APIC"
$bTagFieldFound = True
$sFrameString = $aFrameData[3]
Case "USLT"
$bTagFieldFound = True
$sFrameString = $aFrameData[3]
Case "SYLT"
Local $hSyn, $SynText, $SynLength,$nByte, $SynTemp, $i=1
$sFrameString=Binary('')
$bTagFieldFound = True
$hSyn=FileOpen($aFrameData[3],16)
$SynBin=FileRead($hSyn)
$SynLength=FileGetPos($hSyn)
FileClose($hSyn)
While $i<$SynLength
$SynTemp=Binary('')
While 1
$nByte=BinaryMid($SynBin,$i,1)
$i+=1
If $nByte="0x00" Then ExitLoop
$SynTemp &= $SynTemp
WEnd
$sFrameString&=Binary('0x5b')
$sFrameString&=StringToBinary(Dec(Hex(BinaryMid($SynBin,$i,4))),1)
$sFrameString&=Binary('0x5d')
$sFrameString&=$SynTemp
$sFrameString&=Binary('0x0A0D')
$i+=4
WEnd
$sFrameString=StringStripWS(BinaryToString($sFrameString,$BinaryToString_Flag),2)
Case "UFID"
$bTagFieldFound = True
$bFrameData = Binary($aFrameData[2])
$sFrameString = BinaryToString(BinaryMid($bFrameData,2))
Case "Artist"
$bTagFieldFound = True
$sFrameString = $aFrameData[2]
Case "Title"
$bTagFieldFound = True
$sFrameString = $aFrameData[2]
Case "Album"
$bTagFieldFound = True
$sFrameString = $aFrameData[2]
Case "Track"
$bTagFieldFound = True
$sFrameString = $aFrameData[2]
Case "Year"
$bTagFieldFound = True
$sFrameString = $aFrameData[2]
Case "Genre"
$bTagFieldFound = True
$sFrameString = $aFrameData[2]
Case "Comment"
$bTagFieldFound = True
$sFrameString = $aFrameData[2]
Case "ZPAD"
$bTagFieldFound = True
$sFrameString = $aFrameData[2]
Case "MPEG"
$bTagFieldFound = True
$sFrameString = $aFrameData[2]
Case "NCON"
$bTagFieldFound = True
$sFrameString &= "Non-Standard NCON Frame"
Case "PRIV"
$bTagFieldFound = True
Case Else
$sFrameString &= "Undefined FrameID"
EndSwitch
EndIf
If $bTagFieldFound == False Then
SetError(1)
EndIf
Return $sFrameString
EndFunc
Func _CheckMPEGHeader($MPEGFrameSyncHex)
$MPEGFrameSyncUint32 = _HexToUint32_ID3($MPEGFrameSyncHex)
If $MPEGFrameSyncUint32 > _HexToUint32_ID3("FFE00000") Then
If $MPEGFrameSyncUint32 < _HexToUint32_ID3("FFFFEC00") Then
If Not(StringMid($MPEGFrameSyncHex,4,1) == "0") Then
If Not(StringMid($MPEGFrameSyncHex,4,1) == "1") Then
If Not(StringMid($MPEGFrameSyncHex,4,1) == "9") Then
Return 1
EndIf
EndIf
EndIf
EndIf
EndIf
Return 0
EndFunc
Func _GetAlbumArt($hFile,$FrameLen)
Local $LengthToRead = $FrameLen, $AlbumArtFilename = @TempDir & "AlbumArt", $bReturn
$bText_Encoding = FileRead($hFile,1)
$LengthToRead -= 1
$MIME_Type = ""
$Byte = FileRead($hFile,1)
$bMIME_Type = $Byte
$LengthToRead -= 1
While $Byte <> "0x00"
$MIME_Type &= BinaryToString($Byte)
$Byte = FileRead($hFile,1)
$bMIME_Type &= $Byte
$LengthToRead -= 1
WEnd
$bPicture_Type = FileRead($hFile,1)
$LengthToRead -= 1
$Description = ""
$Byte = FileRead($hFile,1)
$bDescription = $Byte
$LengthToRead -= 1
While $Byte <> "0x00"
$Description &= BinaryToString($Byte)
$Byte = FileRead($hFile,1)
$bDescription &= $Byte
$LengthToRead -= 1
WEnd
If StringInStr($MIME_Type,"jpg") Or StringInStr($MIME_Type,"jpeg") Then
$AlbumArtFilename &= ".jpg"
$ID3Filenames &= $AlbumArtFilename & "|"
ElseIf StringInStr($MIME_Type,"png") Then
$AlbumArtFilename &= ".png"
$ID3Filenames &= $AlbumArtFilename & "|"
Else
$AlbumArtFilename = "File Type Unknown"
EndIf
$PicFile_h = FileOpen($AlbumArtFilename, 2)
$WriteError = FileWrite($PicFile_h,FileRead($hFile, $LengthToRead))
FileClose($PicFile_h)
$bReturn = $bText_Encoding & $bMIME_Type
$bReturn &= $bPicture_Type & $bDescription
$bReturn &= "|" & $AlbumArtFilename
Return $bReturn
EndFunc
Func _GetSongLyrics($hFile,$FrameLen)
Local $LengthToRead = $FrameLen, $LyricsFilename = @TempDir & "SongLyrics.txt", $bReturn
$ID3Filenames &= $LyricsFilename & "|"
$bText_Encoding = FileRead($hFile,1)
$LengthToRead -= 1
$bLanguage = FileRead($hFile,3)
$LengthToRead -= 3
$Content_Descriptor = ""
$Byte = FileRead($hFile,1)
$bContent_Descriptor = $Byte
$LengthToRead -= 1
While $Byte <> "0x00"
$Content_Descriptor &= BinaryToString($Byte)
$Byte = FileRead($hFile,1)
$bContent_Descriptor &= $Byte
$LengthToRead -= 1
WEnd
$bLyrics_Text = FileRead($hFile,$LengthToRead)
Switch $bText_Encoding
Case 0x00
$Lyrics_Text = BinaryToString($bLyrics_Text)
Case 0x01
$Lyrics_Text = BinaryToString($bLyrics_Text,2)
EndSwitch
$hLyricFile = FileOpen($LyricsFilename, 2)
FileWrite($hLyricFile,$Lyrics_Text)
FileClose($hLyricFile)
$bReturn = $bText_Encoding & $bLanguage & $bContent_Descriptor
$bReturn &= "|" & $LyricsFilename
Return $bReturn
EndFunc
Func _GetSynLyrics($hFile,$FrameLen)
Local $LengthToRead = $FrameLen, $_head, $LyricsFilename = @TempDir & "SynLyrics.txt", $bReturn
$ID3Filenames &= $LyricsFilename & "|"
$s_head = FileRead($hFile,6)
$s_Encoding = BinaryMid($s_head,1,1)
$s_Language = BinaryMid($s_head,2,3)
$s_Stamp = BinaryMid($s_head,5,1)
$s_Type = BinaryMid($s_head,6,1)
$LengthToRead -= 6
$s_Descriptor = ''
$Byte = FileRead($hFile,1)
$sb_Descriptor = $Byte
$LengthToRead -= 1
While $Byte <> "0x00"
$s_Descriptor &= BinaryToString($Byte)
$Byte = FileRead($hFile,1)
$sb_Descriptor &= $Byte
$LengthToRead -= 1
WEnd
$bLyrics_Bin = FileRead($hFile,$LengthToRead)
$hLyricFile = FileOpen($LyricsFilename, 2)
FileWrite($hLyricFile,$bLyrics_Bin)
FileClose($hLyricFile)
$bReturn = $s_Encoding & $s_Language & $s_Stamp & $s_Type & $sb_Descriptor
$bReturn &= "|" & $LyricsFilename
Return $bReturn
EndFunc
Func _ConvertFilterToID3v2_2(ByRef $sFilter)
$sFilter = StringReplace($sFilter,"TIT1", "TT1")
$sFilter = StringReplace($sFilter,"TIT2", "TT2")
$sFilter = StringReplace($sFilter,"TIT3", "TT3")
$sFilter = StringReplace($sFilter,"TEXT", "TXT")
$sFilter = StringReplace($sFilter,"TLAN", "TLA")
$sFilter = StringReplace($sFilter,"TKEY", "TKE")
$sFilter = StringReplace($sFilter,"TMED", "TMT")
$sFilter = StringReplace($sFilter,"TOAL", "TOT")
$sFilter = StringReplace($sFilter,"TOFN", "TOF")
$sFilter = StringReplace($sFilter,"TOLY", "TOL")
$sFilter = StringReplace($sFilter,"TOPE", "TOA")
$sFilter = StringReplace($sFilter,"TORY", "TOR")
$sFilter = StringReplace($sFilter,"TPE1", "TP1")
$sFilter = StringReplace($sFilter,"TPE2", "TP2")
$sFilter = StringReplace($sFilter,"TPE3", "TP3")
$sFilter = StringReplace($sFilter,"TPE4", "TP4")
$sFilter = StringReplace($sFilter,"TPOS", "TPA")
$sFilter = StringReplace($sFilter,"TALB", "TRK")
$sFilter = StringReplace($sFilter,"TRCK", "TP2")
$sFilter = StringReplace($sFilter,"TYER", "TYE")
$sFilter = StringReplace($sFilter,"COMM", "COM")
$sFilter = StringReplace($sFilter,"APIC", "PIC")
$sFilter = StringReplace($sFilter,"USLT", "ULT")
$sFilter = StringReplace($sFilter,"SYLT", "SLT")
$sFilter = StringReplace($sFilter,"TSSE", "TSS")
$sFilter = StringReplace($sFilter,"TENC", "TEN")
$sFilter = StringReplace($sFilter,"TCOP", "TCR")
$sFilter = StringReplace($sFilter,"TBPM", "TBP")
$sFilter = StringReplace($sFilter,"TRDA", "TRD")
$sFilter = StringReplace($sFilter,"TSIZ", "TSI")
$sFilter = StringReplace($sFilter,"TSRC", "TRC")
$sFilter = StringReplace($sFilter,"TCON", "TCO")
$sFilter = StringReplace($sFilter,"TLEN", "TLE")
$sFilter = StringReplace($sFilter,"TPUB", "TPB")
$sFilter = StringReplace($sFilter,"TFLT", "TFT")
$sFilter = StringReplace($sFilter,"UFID", "UFI")
$sFilter = StringReplace($sFilter,"TCOM", "TCM")
$sFilter = StringReplace($sFilter,"WCOM", "WCM")
$sFilter = StringReplace($sFilter,"WCOP", "WCP")
$sFilter = StringReplace($sFilter,"WXXX", "WXX")
$sFilter = StringReplace($sFilter,"WOAR", "WAR")
$sFilter = StringReplace($sFilter,"WOAS", "WAS")
$sFilter = StringReplace($sFilter,"WOAF", "WAF")
$sFilter = StringReplace($sFilter,"WPUB", "WPB")
$sFilter = StringReplace($sFilter,"PCNT", "CNT")
EndFunc
Func _GetGenreByID($iID)
Local $asGenre = StringSplit("Blues,Classic Rock,Country,Dance,Disco,Funk,Grunge,Hip-Hop," & "Jazz,Metal,New Age, Oldies,Other,Pop,R&B,Rap,Reggae,Rock,Techno,Industrial,Alternative," & "Ska,Death Metal,Pranks,Soundtrack,Euro-Techno,Ambient,Trip-Hop,Vocal,Jazz+Funk,Fusion," & "Trance,Classical,Instrumental,Acid,House,Game,Sound Clip,Gospel,Noise,Alternative Rock," & "Bass,Soul,Punk,Space,Meditative,Instrumental Pop,Instrumental Rock,Ethnic,Gothic,Darkwave," & "Techno-Industrial,Electronic,Pop-Folk,Eurodance,Dream,Southern Rock,Comedy,Cult,Gangsta," & "Top 40,Christian Rap,Pop/Funk,Jungle,Native US,Cabaret,New Wave,Psychadelic,Rave,Showtunes," & "Trailer,Lo-Fi,Tribal,Acid Punk,Acid Jazz,Polka,Retro,Musical,Rock & Roll,Hard Rock,Folk," & "Folk-Rock,National Folk,Swing,Fast Fusion,Bebob,Latin,Revival,Celtic,Bluegrass,Avantgarde," & "Gothic Rock,Progressive Rock,Psychedelic Rock,Symphonic Rock,Slow Rock,Big Band,Chorus," & "Easy Listening,Acoustic,Humour,Speech,Chanson,Opera,Chamber Music,Sonata,Symphony,Booty Bass," & "Primus,Porn Groove,Satire,Slow Jam,Club,Tango,Samba,Folklore,Ballad,Power Ballad,Rhytmic Soul," & "Freestyle,Duet,Punk Rock,Drum Solo,Acapella,Euro-House,Dance Hall,Goa,Drum & Bass,Club-House," & "Hardcore,Terror,Indie,BritPop,Negerpunk,Polsk Punk,Beat,Christian Gangsta,Heavy Metal,Black Metal," & "Crossover,Contemporary C,Christian Rock,Merengue,Salsa,Thrash Metal,Anime,JPop,SynthPop", ",")
If($iID >= 0) and($iID < 148) Then Return $asGenre[$iID + 1]
Return("")
EndFunc
Func _GetGenreID($sGrenre)
Local $asGenre = StringSplit("Blues,Classic Rock,Country,Dance,Disco,Funk,Grunge,Hip-Hop," & "Jazz,Metal,New Age, Oldies,Other,Pop,R&B,Rap,Reggae,Rock,Techno,Industrial,Alternative," & "Ska,Death Metal,Pranks,Soundtrack,Euro-Techno,Ambient,Trip-Hop,Vocal,Jazz+Funk,Fusion," & "Trance,Classical,Instrumental,Acid,House,Game,Sound Clip,Gospel,Noise,Alternative Rock," & "Bass,Soul,Punk,Space,Meditative,Instrumental Pop,Instrumental Rock,Ethnic,Gothic,Darkwave," & "Techno-Industrial,Electronic,Pop-Folk,Eurodance,Dream,Southern Rock,Comedy,Cult,Gangsta," & "Top 40,Christian Rap,Pop/Funk,Jungle,Native US,Cabaret,New Wave,Psychadelic,Rave,Showtunes," & "Trailer,Lo-Fi,Tribal,Acid Punk,Acid Jazz,Polka,Retro,Musical,Rock & Roll,Hard Rock,Folk," & "Folk-Rock,National Folk,Swing,Fast Fusion,Bebob,Latin,Revival,Celtic,Bluegrass,Avantgarde," & "Gothic Rock,Progressive Rock,Psychedelic Rock,Symphonic Rock,Slow Rock,Big Band,Chorus," & "Easy Listening,Acoustic,Humour,Speech,Chanson,Opera,Chamber Music,Sonata,Symphony,Booty Bass," & "Primus,Porn Groove,Satire,Slow Jam,Club,Tango,Samba,Folklore,Ballad,Power Ballad,Rhytmic Soul," & "Freestyle,Duet,Punk Rock,Drum Solo,Acapella,Euro-House,Dance Hall,Goa,Drum & Bass,Club-House," & "Hardcore,Terror,Indie,BritPop,Negerpunk,Polsk Punk,Beat,Christian Gangsta,Heavy Metal,Black Metal," & "Crossover,Contemporary C,Christian Rock,Merengue,Salsa,Thrash Metal,Anime,JPop,SynthPop", ",")
For $i = 1 to $asGenre[0]
If $sGrenre == $asGenre[$i] Then
Return $i - 1
EndIf
Next
Return 12
EndFunc
Func _HexToUint32_ID3($HexString4Byte)
Return Dec(StringLeft($HexString4Byte,2)) * Dec("FFFFFF") + Dec(StringTrimLeft($HexString4Byte,2))
EndFunc
Func _HexToBin_ID3($HexString)
Local $Bin = ""
For $i = 1 To StringLen($HexString) Step 1
$Hex = StringRight(StringLeft($HexString, $i), 1)
Select
Case $Hex = "0"
$Bin = $Bin & "0000"
Case $Hex = "1"
$Bin = $Bin & "0001"
Case $Hex = "2"
$Bin = $Bin & "0010"
Case $Hex = "3"
$Bin = $Bin & "0011"
Case $Hex = "4"
$Bin = $Bin & "0100"
Case $Hex = "5"
$Bin = $Bin & "0101"
Case $Hex = "6"
$Bin = $Bin & "0110"
Case $Hex = "7"
$Bin = $Bin & "0111"
Case $Hex = "8"
$Bin = $Bin & "1000"
Case $Hex = "9"
$Bin = $Bin & "1001"
Case $Hex = "A"
$Bin = $Bin & "1010"
Case $Hex = "B"
$Bin = $Bin & "1011"
Case $Hex = "C"
$Bin = $Bin & "1100"
Case $Hex = "D"
$Bin = $Bin & "1101"
Case $Hex = "E"
$Bin = $Bin & "1110"
Case $Hex = "F"
$Bin = $Bin & "1111"
Case Else
SetError(-1)
EndSelect
Next
If @error Then
Return "ERROR"
Else
Return $Bin
EndIf
EndFunc
Func _BinToHex_ID3($BinString)
Local $Hex = ""
If Not IsInt(StringLen($BinString) / 4) Then
$Num =((StringLen($BinString) / 4) - Int(StringLen($BinString) / 4)) * 4
For $i = 1 To 4 - $Num Step 1
$BinString = "0" & $BinString
Next
EndIf
For $i = 4 To StringLen($BinString) Step 4
$Bin = StringLeft(StringRight($BinString, $i), 4)
Select
Case $Bin = "0000"
$Hex = $Hex & "0"
Case $Bin = "0001"
$Hex = $Hex & "1"
Case $Bin = "0010"
$Hex = $Hex & "2"
Case $Bin = "0011"
$Hex = $Hex & "3"
Case $Bin = "0100"
$Hex = $Hex & "4"
Case $Bin = "0101"
$Hex = $Hex & "5"
Case $Bin = "0110"
$Hex = $Hex & "6"
Case $Bin = "0111"
$Hex = $Hex & "7"
Case $Bin = "1000"
$Hex = $Hex & "8"
Case $Bin = "1001"
$Hex = $Hex & "9"
Case $Bin = "1010"
$Hex = $Hex & "A"
Case $Bin = "1011"
$Hex = $Hex & "B"
Case $Bin = "1100"
$Hex = $Hex & "C"
Case $Bin = "1101"
$Hex = $Hex & "D"
Case $Bin = "1110"
$Hex = $Hex & "E"
Case $Bin = "1111"
$Hex = $Hex & "F"
Case Else
SetError(-1)
EndSelect
Next
If @error Then
Return "ERROR"
Else
Return _StringReverse($Hex)
EndIf
EndFunc
Global Const $__WINVER = __Ver()
Global Const $tagBITMAP = 'long bmType;long bmWidth;long bmHeight;long bmWidthBytes;ushort bmPlanes;ushort bmBitsPixel;ptr bmBits;'
Global Const $tagPRINTDLG = 'align 2;dword_ptr Size;hwnd hOwner;ptr hDevMode;ptr hDevNames;hwnd hDC;dword Flags;ushort FromPage;ushort ToPage;ushort MinPage;ushort MaxPage;' & __Iif(@AutoItX64, 'uint', 'ushort') & ' Copies;ptr hInstance;lparam lParam;ptr PrintHook;ptr SetupHook;ptr PrintTemplateName;ptr SetupTemplateName;ptr hPrintTemplate;ptr hSetupTemplate;'
Global Const $tagSHFILEINFO = 'ptr hIcon;int iIcon;dword Attributes;wchar DisplayName[260];wchar TypeName[80];'
Global $__Data, $__Dlg, $__Dll = 0, $__Ext = 0, $__Val, $__Heap = 0, $__Text = 0, $__FR, $__Buff = 16385, $__Enum = 8388608, $__RGB = 1
Func _WinAPI_BringWindowToTop($hWnd)
Local $Ret = DllCall('user32.dll', 'int', 'BringWindowToTop', 'hwnd', $hWnd)
If(@error) Or(Not $Ret[0]) Then
Return SetError(1, 0, 0)
EndIf
Return 1
EndFunc
Func _WinAPI_CoInitialize($iFlags = 0)
Local $Ret = DllCall('ole32.dll', 'uint', 'CoInitializeEx', 'ptr', 0, 'dword', $iFlags)
If @error Then
Return SetError(1, 0, 0)
Else
If $Ret[0] Then
Return SetError(1, $Ret[0], 0)
EndIf
EndIf
Return 1
EndFunc
Func _WinAPI_CoTaskMemFree($pMemory)
DllCall('ole32.dll', 'none', 'CoTaskMemFree', 'ptr', $pMemory)
If @error Then
Return SetError(1, 0, 0)
EndIf
Return 1
EndFunc
Func _WinAPI_CoUninitialize()
DllCall('ole32.dll', 'none', 'CoUninitialize')
If @error Then
Return SetError(1, 0, 0)
EndIf
Return 1
EndFunc
Func _WinAPI_GetBkColor($hDC)
Local $Ret = DllCall('gdi32.dll', 'int', 'GetBkColor', 'hwnd', $hDC)
If(@error) Or($Ret[0] = -1) Then
Return SetError(1, 0, -1)
EndIf
Return __RGB($Ret[0])
EndFunc
Func _WinAPI_GetModuleHandleEx($sModule, $iFlags = 0)
Local $TypeOfModule = 'ptr'
If IsString($sModule) Then
If StringStripWS($sModule, 3) Then
$TypeOfModule = 'wstr'
Else
$sModule = 0
EndIf
EndIf
Local $Ret = DllCall('kernel32.dll', 'int', 'GetModuleHandleExW', 'dword', $iFlags, $TypeOfModule, $sModule, 'ptr*', 0)
If(@error) Or(Not $Ret[0]) Then
Return SetError(1, 0, 0)
EndIf
Return $Ret[3]
EndFunc
Func _WinAPI_GetProcessMemoryInfo($PID = 0)
If Not $PID Then
$PID = @AutoItPID
EndIf
Local $hProcess = DllCall('kernel32.dll', 'ptr', 'OpenProcess', 'dword', __Iif($__WINVER < 0x0600, 0x00000410, 0x00001010), 'int', 0, 'dword', $PID)
If(@error) Or(Not $hProcess[0]) Then
Return SetError(1, 0, 0)
EndIf
Local $tPMC_EX = DllStructCreate('dword;dword;ulong_ptr;ulong_ptr;ulong_ptr;ulong_ptr;ulong_ptr;ulong_ptr;ulong_ptr;ulong_ptr;ulong_ptr')
Local $Ret = DllCall(@SystemDir & '\psapi.dll', 'int', 'GetProcessMemoryInfo', 'ptr', $hProcess[0], 'ptr', DllStructGetPtr($tPMC_EX), 'int', DllStructGetSize($tPMC_EX))
If(@error) Or(Not $Ret[0]) Then
$Ret = 0
EndIf
_WinAPI_CloseHandle($hProcess[0])
If Not IsArray($Ret) Then
Return SetError(1, 0, 0)
EndIf
Local $Result[10]
For $i = 0 To 9
$Result[$i] = DllStructGetData($tPMC_EX, $i + 2)
Next
Return $Result
EndFunc
Func _WinAPI_GetVersion()
Return _WinAPI_HiByte($__WINVER) & '.' & _WinAPI_LoByte($__WINVER)
EndFunc
Func _WinAPI_HiByte($iValue)
Return BitAND(BitShift($iValue, 8), 0xFF)
EndFunc
Func _WinAPI_IsInternetConnected()
If Not __DLL('connect.dll') Then
Return SetError(3, 0, 0)
EndIf
Local $Ret = DllCall('connect.dll', 'uint', 'IsInternetConnected')
If @error Then
Return SetError(1, 0, 0)
Else
Switch $Ret[0]
Case 0, 1
Case Else
Return SetError(1, $Ret[0], 0)
EndSwitch
EndIf
Return Number(Not $Ret[0])
EndFunc
Func _WinAPI_LoByte($iValue)
Return BitAND($iValue, 0xFF)
EndFunc
Func _WinAPI_PathIsDirectory($sPath)
Local $Ret = DllCall('shlwapi.dll', 'int', 'PathIsDirectoryW', 'wstr', $sPath)
If @error Then
Return SetError(1, 0, 0)
EndIf
Return $Ret[0]
EndFunc
Func _WinAPI_PathRemoveBackslash($sPath)
Local $Ret = DllCall('shlwapi.dll', 'ptr', 'PathRemoveBackslashW', 'wstr', $sPath)
If @error Then
Return SetError(1, 0, '')
Else
If Not $Ret[0] Then
Return $sPath
EndIf
EndIf
Return $Ret[1]
EndFunc
Func _WinAPI_PathSearchAndQualify($sPath, $fExists = 0)
Local $Ret = DllCall('shlwapi.dll', 'int', 'PathSearchAndQualifyW', 'wstr', $sPath, 'wstr', '', 'int', 4096)
If(@error) Or(Not $Ret[0]) Then
Return SetError(1, 0, '')
EndIf
If($fExists) And(Not FileExists($Ret[2])) Then
Return SetError(2, 0, '')
EndIf
Return $Ret[2]
EndFunc
Func _WinAPI_SetWindowTheme($hWnd, $sName = 0, $sList = 0)
Local $TypeOfName = 'wstr', $TypeOfList = 'wstr'
If Not IsString($sName) Then
$TypeOfName = 'ptr'
$sName = 0
EndIf
If Not IsString($sList) Then
$TypeOfList = 'ptr'
$sList = 0
EndIf
Local $Ret = DllCall('uxtheme.dll', 'uint', 'SetWindowTheme', 'hwnd', $hWnd, $TypeOfName, $sName, $TypeOfList, $sList)
If @error Then
Return SetError(1, 0, 0)
Else
If $Ret[0] Then
Return SetError(1, $Ret[0], 0)
EndIf
EndIf
Return 1
EndFunc
Func _WinAPI_ShellILCreateFromPath($sPath)
Local $Ret = DllCall('shell32.dll', 'uint', 'SHILCreateFromPath', 'wstr', $sPath, 'ptr*', 0, 'dword*', 0)
If @error Then
Return SetError(1, 0, 0)
Else
If $Ret[0] Then
Return SetError(1, $Ret[0], 0)
EndIf
EndIf
Return $Ret[2]
EndFunc
Func _WinAPI_ShellOpenFolderAndSelectItems($sPath, $aNames = 0, $iStart = 0, $iEnd = -1, $iFlags = 0)
Local $PIDL, $Ret, $tPtr = 0, $Count = 0, $Obj = 0
$sPath = _WinAPI_PathRemoveBackslash(_WinAPI_PathSearchAndQualify($sPath))
If IsArray($aNames) Then
If($sPath) And(Not _WinAPI_PathIsDirectory($sPath)) Then
Return SetError(1, 0, 0)
EndIf
EndIf
$PIDL = _WinAPI_ShellILCreateFromPath($sPath)
If @error Then
Return SetError(1, 0, 0)
EndIf
If IsArray($aNames) Then
If $iStart < 0 Then
$iStart = 0
EndIf
If($iEnd < 0) Or($iEnd > UBound($aNames) - 1) Then
$iEnd = UBound($aNames) - 1
EndIf
$tPtr = DllStructCreate('ptr[' &($iEnd - $iStart + 1) & ']')
If @error Then
Else
For $i = $iStart To $iEnd
$Count += 1
If $aNames[$i] Then
DllStructSetData($tPtr, 1, _WinAPI_ShellILCreateFromPath($sPath & '\' & $aNames[$i]), $Count)
Else
DllStructSetData($tPtr, 1, 0, $Count)
EndIf
Next
EndIf
EndIf
If _WinAPI_CoInitialize() Then
$Obj = 1
EndIf
$Ret = DllCall('shell32.dll', 'uint', 'SHOpenFolderAndSelectItems', 'ptr', $PIDL, 'uint', $Count, 'ptr', DllStructGetPtr($tPtr), 'dword', $iFlags)
If @error Then
$Ret = 0
Else
If $Ret[0] Then
$Ret = $Ret[0]
EndIf
EndIf
If $Obj Then
_WinAPI_CoUninitialize()
EndIf
_WinAPI_CoTaskMemFree($PIDL)
For $i = 1 To $Count
$PIDL = DllStructGetData($tPtr, $i)
If $PIDL Then
_WinAPI_CoTaskMemFree($PIDL)
EndIf
Next
If Not IsArray($Ret) Then
Return SetError(1, $Ret, 0)
EndIf
Return 1
EndFunc
Func _WinAPI_SwitchColor($iColor)
Return BitOR(BitAND($iColor, 0x00FF00), BitShift(BitAND($iColor, 0x0000FF), -16), BitShift(BitAND($iColor, 0xFF0000), 16))
EndFunc
Func __DLL($sPath, $fPin = 0)
If Not _WinAPI_GetModuleHandleEx($sPath, __Iif($fPin, 0x0001, 0x0002)) Then
If Not _WinAPI_LoadLibrary($sPath) Then
Return 0
EndIf
EndIf
Return 1
EndFunc
Func __Iif($fTest, $iTrue, $iFalse)
If $fTest Then
Return $iTrue
Else
Return $iFalse
EndIf
EndFunc
Func __RGB($iColor)
If $__RGB Then
$iColor = _WinAPI_SwitchColor($iColor)
EndIf
Return $iColor
EndFunc
Func __Ver()
Local $tOSVI = DllStructCreate('dword;dword;dword;dword;dword;wchar[128]')
DllStructSetData($tOSVI, 1, DllStructGetSize($tOSVI))
Local $Ret = DllCall('kernel32.dll', 'int', 'GetVersionExW', 'ptr', DllStructGetPtr($tOSVI))
If(@error) Or(Not $Ret[0]) Then
Return SetError(1, 0, 0)
EndIf
Return BitOR(BitShift(DllStructGetData($tOSVI, 2), -8), DllStructGetData($tOSVI, 3))
EndFunc
Global Const $PROCESS_VM_OPERATION = 0x00000008
Global Const $PROCESS_VM_READ = 0x00000010
Global Const $PROCESS_VM_WRITE = 0x00000020
Global Const $LR_LOADFROMFILE = 0x0010
Global Const $TRAY_EVENT_PRIMARYUP = -8
Global Const $STDOUT_CHILD = 2
Global Const $FW_BOLD = 700
Global Const $CF_SCREENFONTS = 0x1
Global Const $CF_NOSCRIPTSEL = 0x800000
Global Const $CF_INITTOLOGFONTSTRUCT = 0x40
Global Const $LOGPIXELSX = 88
Global Const $GMEM_FIXED = 0x0000
Global Const $GMEM_MOVEABLE = 0x0002
Global Const $GMEM_ZEROINIT = 0x0040
Global Const $GMEM_INVALID_HANDLE = 0x8000
Global Const $GPTR = $GMEM_FIXED + $GMEM_ZEROINIT
Global Const $GHND = $GMEM_MOVEABLE + $GMEM_ZEROINIT
Global Const $MEM_COMMIT = 0x00001000
Global Const $MEM_RESERVE = 0x00002000
Global Const $PAGE_READWRITE = 0x00000004
Global Const $PAGE_EXECUTE_READWRITE = 0x00000040
Global Const $MEM_RELEASE = 0x00008000
Global Const $MF_DISABLED = 0x00000002
Global Const $MF_BYPOSITION = 0x00000400
Global Const $MF_SEPARATOR = 0x00000800
Global Const $MFS_GRAYED = 0x00000003
Global Const $MFS_DISABLED = $MFS_GRAYED
Global Const $MFT_SEPARATOR = $MF_SEPARATOR
Global Const $MIIM_STATE = 0x00000001
Global Const $MIIM_ID = 0x00000002
Global Const $MIIM_SUBMENU = 0x00000004
Global Const $MIIM_DATA = 0x00000020
Global Const $MIIM_DATAMASK = 0x0000003F
Global Const $MIIM_STRING = 0x00000040
Global Const $MIIM_BITMAP = 0x00000080
Global Const $MIIM_FTYPE = 0x00000100
Global Const $MIM_STYLE = 0x00000010
Global Const $TPM_LEFTBUTTON = 0x0
Global Const $TPM_LEFTALIGN = 0x0
Global Const $TPM_TOPALIGN = 0x0
Global Const $TPM_RIGHTBUTTON = 0x00000002
Global Const $TPM_CENTERALIGN = 0x00000004
Global Const $TPM_RIGHTALIGN = 0x00000008
Global Const $TPM_VCENTERALIGN = 0x00000010
Global Const $TPM_BOTTOMALIGN = 0x00000020
Global Const $TPM_NONOTIFY = 0x00000080
Global Const $TPM_RETURNCMD = 0x00000100
Global Const $SC_SIZE = 0xF000
Global Const $SC_MOVE = 0xF010
Global Const $WS_VISIBLE = 0x10000000
Global Const $WS_CHILD = 0x40000000
Global Const $WS_POPUP = 0x80000000
Global Const $WS_EX_CLIENTEDGE = 0x00000200
Global Const $WS_EX_TOOLWINDOW = 0x00000080
Global Const $WS_EX_TOPMOST = 0x00000008
Global Const $WS_EX_WINDOWEDGE = 0x00000100
Global Const $WS_EX_LAYERED = 0x00080000
Global Const $WM_DRAWITEM = 0x002B
Global Const $WM_MEASUREITEM = 0x002C
Global Const $WM_NOTIFY = 0x004E
Global Const $WM_EXITSIZEMOVE = 0x0232
Global Const $WM_NCHITTEST = 0x0084
Global Const $WM_COMMAND = 0x0111
Global Const $WM_SYSCOMMAND = 0x0112
Global Const $WM_HSCROLL = 0x0114
Global Const $NM_FIRST = 0
Global Const $NM_CLICK = $NM_FIRST - 2
Global Const $NM_DBLCLK = $NM_FIRST - 3
Global Const $NM_RCLICK = $NM_FIRST - 5
Global Const $WM_MOUSEWHEEL = 0x020A
Global Const $OPAQUE = 2
Global Const $HTCAPTION = 2
Global Const $COLOR_MENU = 4
Global Const $SHGFI_LARGEICON = 0x00000000
Global Const $SHGFI_SMALLICON = 0x00000001
Global Const $SHGFI_SYSICONINDEX = 0x00004000
Global Const $SHGFI_USEFILEATTRIBUTES = 0x00000010
Global Const $SHOP_FILEPATH = 2
Global Const $ES_LEFT = 0
Global Const $ES_AUTOHSCROLL = 128
Global Const $ES_READONLY = 2048
Global Const $EM_LIMITTEXT = 0xC5
Global Const $EM_SETLIMITTEXT = $EM_LIMITTEXT
Global Const $EM_SETSEL = 0xB1
Global Const $EN_KILLFOCUS = 0x200
Global Const $SS_SUNKEN = 0x1000
Global Const $GUI_EVENT_CLOSE = -3
Global Const $GUI_EVENT_MINIMIZE = -4
Global Const $GUI_EVENT_RESTORE = -5
Global Const $GUI_EVENT_RESIZED = -12
Global Const $GUI_RUNDEFMSG = 'GUI_RUNDEFMSG'
Global Const $GUI_CHECKED = 1
Global Const $GUI_UNCHECKED = 4
Global Const $GUI_SHOW = 16
Global Const $GUI_HIDE = 32
Global Const $GUI_ENABLE = 64
Global Const $GUI_DISABLE = 128
Global Const $GUI_FOCUS = 256
Global Const $GUI_DEFBUTTON = 512
Global Const $GUI_BKCOLOR_TRANSPARENT = -2
Global Const $GUI_BKCOLOR_LV_ALTERNATE = 0xFE000000
Global Const $GUI_WS_EX_PARENTDRAG = 0x00100000
Global Const $BS_MULTILINE = 0x2000
Global Const $BS_FLAT = 0x8000
Global Const $BCM_FIRST = 0x1600
Global Const $BCM_SETIMAGELIST =($BCM_FIRST + 0x0002)
Global Const $BCM_SETSHIELD =($BCM_FIRST + 0x000C)
Global Const $BN_CLICKED = 0
Global Const $CB_ERR = -1
Global Const $CB_GETCURSEL = 0x147
Global Const $CB_GETLBTEXT = 0x148
Global Const $CB_GETLBTEXTLEN = 0x149
Global Const $CBN_EDITCHANGE = 5
Global Const $CBN_SELENDOK = 9
Global Const $LVS_EDITLABELS = 0x0200
Global Const $LVS_NOCOLUMNHEADER = 0x4000
Global Const $LVS_REPORT = 0x0001
Global Const $LVS_SHOWSELALWAYS = 0x0008
Global Const $LVS_EX_DOUBLEBUFFER = 0x00010000
Global Const $LVS_EX_FULLROWSELECT = 0x00000020
Global Const $LVS_EX_HEADERDRAGDROP = 0x00000010
Global Const $LV_ERR = -1
Global Const $LVCF_FMT = 0x0001
Global Const $LVCF_IMAGE = 0x0010
Global Const $LVCF_TEXT = 0x0004
Global Const $LVCF_WIDTH = 0x0002
Global Const $LVCFMT_BITMAP_ON_RIGHT = 0x1000
Global Const $LVCFMT_CENTER = 0x0002
Global Const $LVCFMT_COL_HAS_IMAGES = 0x8000
Global Const $LVCFMT_IMAGE = 0x0800
Global Const $LVCFMT_LEFT = 0x0000
Global Const $LVCFMT_RIGHT = 0x0001
Global Const $LVGA_HEADER_LEFT = 0x00000001
Global Const $LVGA_HEADER_CENTER = 0x00000002
Global Const $LVGA_HEADER_RIGHT = 0x00000004
Global Const $LVGF_ALIGN = 0x00000008
Global Const $LVGF_GROUPID = 0x00000010
Global Const $LVGF_HEADER = 0x00000001
Global Const $LVIF_GROUPID = 0x00000100
Global Const $LVIF_IMAGE = 0x00000002
Global Const $LVIF_PARAM = 0x00000004
Global Const $LVIF_STATE = 0x00000008
Global Const $LVIF_TEXT = 0x00000001
Global Const $LVIR_BOUNDS = 0
Global Const $LVIR_ICON = 1
Global Const $LVIR_LABEL = 2
Global Const $LVIS_FOCUSED = 0x0001
Global Const $LVIS_SELECTED = 0x0002
Global Const $LVM_FIRST = 0x1000
Global Const $LVM_DELETEALLITEMS =($LVM_FIRST + 9)
Global Const $LVM_DELETEITEM =($LVM_FIRST + 8)
Global Const $LVM_EDITLABELA =($LVM_FIRST + 23)
Global Const $LVM_EDITLABELW =($LVM_FIRST + 118)
Global Const $LVM_EDITLABEL = $LVM_EDITLABELA
Global Const $LVM_ENABLEGROUPVIEW =($LVM_FIRST + 157)
Global Const $LVM_ENSUREVISIBLE =($LVM_FIRST + 19)
Global Const $LVM_GETHEADER =($LVM_FIRST + 31)
Global Const $LVM_GETITEMA =($LVM_FIRST + 5)
Global Const $LVM_GETITEMW =($LVM_FIRST + 75)
Global Const $LVM_GETITEMCOUNT =($LVM_FIRST + 4)
Global Const $LVM_GETITEMPOSITION =($LVM_FIRST + 16)
Global Const $LVM_GETITEMRECT =($LVM_FIRST + 14)
Global Const $LVM_GETITEMSTATE =($LVM_FIRST + 44)
Global Const $LVM_GETITEMTEXTA =($LVM_FIRST + 45)
Global Const $LVM_GETITEMTEXTW =($LVM_FIRST + 115)
Global Const $LVM_GETNEXTITEM =($LVM_FIRST + 12)
Global Const $LVM_GETSELECTEDCOUNT =($LVM_FIRST + 50)
Global Const $LVM_GETSUBITEMRECT =($LVM_FIRST + 56)
Global Const $LVM_GETUNICODEFORMAT = 0x2000 + 6
Global Const $LVM_INSERTCOLUMNA =($LVM_FIRST + 27)
Global Const $LVM_INSERTCOLUMNW =($LVM_FIRST + 97)
Global Const $LVM_INSERTGROUP =($LVM_FIRST + 145)
Global Const $LVM_INSERTITEMA =($LVM_FIRST + 7)
Global Const $LVM_INSERTITEMW =($LVM_FIRST + 77)
Global Const $LVM_REDRAWITEMS =($LVM_FIRST + 21)
Global Const $LVM_SETCOLUMNA =($LVM_FIRST + 26)
Global Const $LVM_SETCOLUMNW =($LVM_FIRST + 96)
Global Const $LVM_SETCOLUMNORDERARRAY =($LVM_FIRST + 58)
Global Const $LVM_SETCOLUMNWIDTH =($LVM_FIRST + 30)
Global Const $LVM_SETEXTENDEDLISTVIEWSTYLE =($LVM_FIRST + 54)
Global Const $LVM_SETIMAGELIST =($LVM_FIRST + 3)
Global Const $LVM_SETITEMA =($LVM_FIRST + 6)
Global Const $LVM_SETITEMW =($LVM_FIRST + 76)
Global Const $LVM_SETITEMCOUNT =($LVM_FIRST + 47)
Global Const $LVM_SETITEMSTATE =($LVM_FIRST + 43)
Global Const $LVM_SETUNICODEFORMAT = 0x2000 + 5
Global Const $LVN_FIRST = -100
Global Const $LVN_BEGINDRAG =($LVN_FIRST - 9)
Global Const $LVN_BEGINLABELEDITW =($LVN_FIRST - 75)
Global Const $LVN_COLUMNCLICK =($LVN_FIRST - 8)
Global Const $LVN_ENDLABELEDITW =($LVN_FIRST - 76)
Global Const $LVNI_ABOVE = 0x0100
Global Const $LVNI_BELOW = 0x0200
Global Const $LVNI_TOLEFT = 0x0400
Global Const $LVNI_TORIGHT = 0x0800
Global Const $LVNI_ALL = 0x0000
Global Const $LVNI_CUT = 0x0004
Global Const $LVNI_DROPHILITED = 0x0008
Global Const $LVNI_FOCUSED = 0x0001
Global Const $LVNI_SELECTED = 0x0002
Global Const $LVSCW_AUTOSIZE_USEHEADER = -2
Global Const $LVSICF_NOINVALIDATEALL = 0x00000001
Global Const $LVSICF_NOSCROLL = 0x00000002
Global Const $LVSIL_NORMAL = 0
Global Const $LVSIL_SMALL = 1
Global Const $LVSIL_STATE = 2
Global Const $HDF_SORTDOWN = 0x00000200
Global Const $HDF_SORTUP = 0x00000400
Global Const $HDI_FORMAT = 0x00000004
Global Const $HDM_FIRST = 0x1200
Global Const $HDM_GETITEMA = $HDM_FIRST + 3
Global Const $HDM_GETITEMW = $HDM_FIRST + 11
Global Const $HDM_GETITEMCOUNT = $HDM_FIRST + 0
Global Const $HDM_GETUNICODEFORMAT = 0x2000 + 6
Global Const $HDM_SETITEMA = $HDM_FIRST + 4
Global Const $HDM_SETITEMW = $HDM_FIRST + 12
Global Const $tagMEMMAP = "handle hProc;ulong_ptr Size;ptr Mem"
Func _MemFree(ByRef $tMemMap)
Local $pMemory = DllStructGetData($tMemMap, "Mem")
Local $hProcess = DllStructGetData($tMemMap, "hProc")
Local $bResult = _MemVirtualFreeEx($hProcess, $pMemory, 0, $MEM_RELEASE)
DllCall("kernel32.dll", "bool", "CloseHandle", "handle", $hProcess)
If @error Then Return SetError(@error, @extended, False)
Return $bResult
EndFunc
Func _MemGlobalAlloc($iBytes, $iFlags = 0)
Local $aResult = DllCall("kernel32.dll", "handle", "GlobalAlloc", "uint", $iFlags, "ulong_ptr", $iBytes)
If @error Then Return SetError(@error, @extended, 0)
Return $aResult[0]
EndFunc
Func _MemGlobalFree($hMem)
Local $aResult = DllCall("kernel32.dll", "ptr", "GlobalFree", "handle", $hMem)
If @error Then Return SetError(@error, @extended, False)
Return $aResult[0]
EndFunc
Func _MemGlobalLock($hMem)
Local $aResult = DllCall("kernel32.dll", "ptr", "GlobalLock", "handle", $hMem)
If @error Then Return SetError(@error, @extended, 0)
Return $aResult[0]
EndFunc
Func _MemGlobalSize($hMem)
Local $aResult = DllCall("kernel32.dll", "ulong_ptr", "GlobalSize", "handle", $hMem)
If @error Then Return SetError(@error, @extended, 0)
Return $aResult[0]
EndFunc
Func _MemGlobalUnlock($hMem)
Local $aResult = DllCall("kernel32.dll", "bool", "GlobalUnlock", "handle", $hMem)
If @error Then Return SetError(@error, @extended, 0)
Return $aResult[0]
EndFunc
Func _MemInit($hWnd, $iSize, ByRef $tMemMap)
Local $aResult = DllCall("User32.dll", "dword", "GetWindowThreadProcessId", "hwnd", $hWnd, "dword*", 0)
If @error Then Return SetError(@error, @extended, 0)
Local $iProcessID = $aResult[2]
If $iProcessID = 0 Then Return SetError(1, 0, 0)
Local $iAccess = BitOR($PROCESS_VM_OPERATION, $PROCESS_VM_READ, $PROCESS_VM_WRITE)
Local $hProcess = __Mem_OpenProcess($iAccess, False, $iProcessID, True)
Local $iAlloc = BitOR($MEM_RESERVE, $MEM_COMMIT)
Local $pMemory = _MemVirtualAllocEx($hProcess, 0, $iSize, $iAlloc, $PAGE_READWRITE)
If $pMemory = 0 Then Return SetError(2, 0, 0)
$tMemMap = DllStructCreate($tagMEMMAP)
DllStructSetData($tMemMap, "hProc", $hProcess)
DllStructSetData($tMemMap, "Size", $iSize)
DllStructSetData($tMemMap, "Mem", $pMemory)
Return $pMemory
EndFunc
Func _MemMoveMemory($pSource, $pDest, $iLength)
DllCall("kernel32.dll", "none", "RtlMoveMemory", "struct*", $pDest, "struct*", $pSource, "ulong_ptr", $iLength)
If @error Then Return SetError(@error, @extended)
EndFunc
Func _MemRead(ByRef $tMemMap, $pSrce, $pDest, $iSize)
Local $aResult = DllCall("kernel32.dll", "bool", "ReadProcessMemory", "handle", DllStructGetData($tMemMap, "hProc"), "ptr", $pSrce, "struct*", $pDest, "ulong_ptr", $iSize, "ulong_ptr*", 0)
If @error Then Return SetError(@error, @extended, False)
Return $aResult[0]
EndFunc
Func _MemWrite(ByRef $tMemMap, $pSrce, $pDest = 0, $iSize = 0, $sSrce = "struct*")
If $pDest = 0 Then $pDest = DllStructGetData($tMemMap, "Mem")
If $iSize = 0 Then $iSize = DllStructGetData($tMemMap, "Size")
Local $aResult = DllCall("kernel32.dll", "bool", "WriteProcessMemory", "handle", DllStructGetData($tMemMap, "hProc"), "ptr", $pDest, $sSrce, $pSrce, "ulong_ptr", $iSize, "ulong_ptr*", 0)
If @error Then Return SetError(@error, @extended, False)
Return $aResult[0]
EndFunc
Func _MemVirtualAlloc($pAddress, $iSize, $iAllocation, $iProtect)
Local $aResult = DllCall("kernel32.dll", "ptr", "VirtualAlloc", "ptr", $pAddress, "ulong_ptr", $iSize, "dword", $iAllocation, "dword", $iProtect)
If @error Then Return SetError(@error, @extended, 0)
Return $aResult[0]
EndFunc
Func _MemVirtualAllocEx($hProcess, $pAddress, $iSize, $iAllocation, $iProtect)
Local $aResult = DllCall("kernel32.dll", "ptr", "VirtualAllocEx", "handle", $hProcess, "ptr", $pAddress, "ulong_ptr", $iSize, "dword", $iAllocation, "dword", $iProtect)
If @error Then Return SetError(@error, @extended, 0)
Return $aResult[0]
EndFunc
Func _MemVirtualFree($pAddress, $iSize, $iFreeType)
Local $aResult = DllCall("kernel32.dll", "bool", "VirtualFree", "ptr", $pAddress, "ulong_ptr", $iSize, "dword", $iFreeType)
If @error Then Return SetError(@error, @extended, False)
Return $aResult[0]
EndFunc
Func _MemVirtualFreeEx($hProcess, $pAddress, $iSize, $iFreeType)
Local $aResult = DllCall("kernel32.dll", "bool", "VirtualFreeEx", "handle", $hProcess, "ptr", $pAddress, "ulong_ptr", $iSize, "dword", $iFreeType)
If @error Then Return SetError(@error, @extended, False)
Return $aResult[0]
EndFunc
Func __Mem_OpenProcess($iAccess, $fInherit, $iProcessID, $fDebugPriv = False)
Local $aResult = DllCall("kernel32.dll", "handle", "OpenProcess", "dword", $iAccess, "bool", $fInherit, "dword", $iProcessID)
If @error Then Return SetError(@error, @extended, 0)
If $aResult[0] Then Return $aResult[0]
If Not $fDebugPriv Then Return 0
Local $hToken = _Security__OpenThreadTokenEx(BitOR($TOKEN_ADJUST_PRIVILEGES, $TOKEN_QUERY))
If @error Then Return SetError(@error, @extended, 0)
_Security__SetPrivilege($hToken, "SeDebugPrivilege", True)
Local $iError = @error
Local $iLastError = @extended
Local $iRet = 0
If Not @error Then
$aResult = DllCall("kernel32.dll", "handle", "OpenProcess", "dword", $iAccess, "bool", $fInherit, "dword", $iProcessID)
$iError = @error
$iLastError = @extended
If $aResult[0] Then $iRet = $aResult[0]
_Security__SetPrivilege($hToken, "SeDebugPrivilege", False)
If @error Then
$iError = @error
$iLastError = @extended
EndIf
EndIf
DllCall("kernel32.dll", "bool", "CloseHandle", "handle", $hToken)
Return SetError($iError, $iLastError, $iRet)
EndFunc
Global Const $_UDF_GlobalIDs_OFFSET = 2
Global Const $_UDF_GlobalID_MAX_WIN = 16
Global Const $_UDF_STARTID = 10000
Global Const $_UDF_GlobalID_MAX_IDS = 55535
Global Const $__UDFGUICONSTANT_WS_VISIBLE = 0x10000000
Global Const $__UDFGUICONSTANT_WS_CHILD = 0x40000000
Global $_UDF_GlobalIDs_Used[$_UDF_GlobalID_MAX_WIN][$_UDF_GlobalID_MAX_IDS + $_UDF_GlobalIDs_OFFSET + 1]
Func __UDF_GetNextGlobalID($hWnd)
Local $nCtrlID, $iUsedIndex = -1, $fAllUsed = True
If Not WinExists($hWnd) Then Return SetError(-1, -1, 0)
For $iIndex = 0 To $_UDF_GlobalID_MAX_WIN - 1
If $_UDF_GlobalIDs_Used[$iIndex][0] <> 0 Then
If Not WinExists($_UDF_GlobalIDs_Used[$iIndex][0]) Then
For $x = 0 To UBound($_UDF_GlobalIDs_Used, 2) - 1
$_UDF_GlobalIDs_Used[$iIndex][$x] = 0
Next
$_UDF_GlobalIDs_Used[$iIndex][1] = $_UDF_STARTID
$fAllUsed = False
EndIf
EndIf
Next
For $iIndex = 0 To $_UDF_GlobalID_MAX_WIN - 1
If $_UDF_GlobalIDs_Used[$iIndex][0] = $hWnd Then
$iUsedIndex = $iIndex
ExitLoop
EndIf
Next
If $iUsedIndex = -1 Then
For $iIndex = 0 To $_UDF_GlobalID_MAX_WIN - 1
If $_UDF_GlobalIDs_Used[$iIndex][0] = 0 Then
$_UDF_GlobalIDs_Used[$iIndex][0] = $hWnd
$_UDF_GlobalIDs_Used[$iIndex][1] = $_UDF_STARTID
$fAllUsed = False
$iUsedIndex = $iIndex
ExitLoop
EndIf
Next
EndIf
If $iUsedIndex = -1 And $fAllUsed Then Return SetError(16, 0, 0)
If $_UDF_GlobalIDs_Used[$iUsedIndex][1] = $_UDF_STARTID + $_UDF_GlobalID_MAX_IDS Then
For $iIDIndex = $_UDF_GlobalIDs_OFFSET To UBound($_UDF_GlobalIDs_Used, 2) - 1
If $_UDF_GlobalIDs_Used[$iUsedIndex][$iIDIndex] = 0 Then
$nCtrlID =($iIDIndex - $_UDF_GlobalIDs_OFFSET) + 10000
$_UDF_GlobalIDs_Used[$iUsedIndex][$iIDIndex] = $nCtrlID
Return $nCtrlID
EndIf
Next
Return SetError(-1, $_UDF_GlobalID_MAX_IDS, 0)
EndIf
$nCtrlID = $_UDF_GlobalIDs_Used[$iUsedIndex][1]
$_UDF_GlobalIDs_Used[$iUsedIndex][1] += 1
$_UDF_GlobalIDs_Used[$iUsedIndex][($nCtrlID - 10000) + $_UDF_GlobalIDs_OFFSET] = $nCtrlID
Return $nCtrlID
EndFunc
Func __UDF_FreeGlobalID($hWnd, $iGlobalID)
If $iGlobalID - $_UDF_STARTID < 0 Or $iGlobalID - $_UDF_STARTID > $_UDF_GlobalID_MAX_IDS Then Return SetError(-1, 0, False)
For $iIndex = 0 To $_UDF_GlobalID_MAX_WIN - 1
If $_UDF_GlobalIDs_Used[$iIndex][0] = $hWnd Then
For $x = $_UDF_GlobalIDs_OFFSET To UBound($_UDF_GlobalIDs_Used, 2) - 1
If $_UDF_GlobalIDs_Used[$iIndex][$x] = $iGlobalID Then
$_UDF_GlobalIDs_Used[$iIndex][$x] = 0
Return True
EndIf
Next
Return SetError(-3, 0, False)
EndIf
Next
Return SetError(-2, 0, False)
EndFunc
Func __UDF_DebugPrint($sText, $iLine = @ScriptLineNumber, $err = @error, $ext = @extended)
ConsoleWrite( "!===========================================================" & @CRLF & "+======================================================" & @CRLF & "-->Line(" & StringFormat("%04d", $iLine) & "):" & @TAB & $sText & @CRLF & "+======================================================" & @CRLF)
Return SetError($err, $ext, 1)
EndFunc
Func __UDF_ValidateClassName($hWnd, $sClassNames)
__UDF_DebugPrint("This is for debugging only, set the debug variable to false before submitting")
If _WinAPI_IsClassName($hWnd, $sClassNames) Then Return True
Local $sSeparator = Opt("GUIDataSeparatorChar")
$sClassNames = StringReplace($sClassNames, $sSeparator, ",")
__UDF_DebugPrint("Invalid Class Type(s):" & @LF & @TAB & "Expecting Type(s): " & $sClassNames & @LF & @TAB & "Received Type : " & _WinAPI_GetClassName($hWnd))
Exit
EndFunc
Global $_ghHDRLastWnd
Global $Debug_HDR = False
Global Const $__HEADERCONSTANT_ClassName = "SysHeader32"
Func _GUICtrlHeader_GetItem($hWnd, $iIndex, ByRef $tItem)
If $Debug_HDR Then __UDF_ValidateClassName($hWnd, $__HEADERCONSTANT_ClassName)
Local $fUnicode = _GUICtrlHeader_GetUnicodeFormat($hWnd)
Local $iRet
If _WinAPI_InProcess($hWnd, $_ghHDRLastWnd) Then
$iRet = _SendMessage($hWnd, $HDM_GETITEMW, $iIndex, $tItem, 0, "wparam", "struct*")
Else
Local $iItem = DllStructGetSize($tItem)
Local $tMemMap
Local $pMemory = _MemInit($hWnd, $iItem, $tMemMap)
_MemWrite($tMemMap, $tItem)
If $fUnicode Then
$iRet = _SendMessage($hWnd, $HDM_GETITEMW, $iIndex, $pMemory, 0, "wparam", "ptr")
Else
$iRet = _SendMessage($hWnd, $HDM_GETITEMA, $iIndex, $pMemory, 0, "wparam", "ptr")
EndIf
_MemRead($tMemMap, $pMemory, $tItem, $iItem)
_MemFree($tMemMap)
EndIf
Return $iRet <> 0
EndFunc
Func _GUICtrlHeader_GetItemCount($hWnd)
If $Debug_HDR Then __UDF_ValidateClassName($hWnd, $__HEADERCONSTANT_ClassName)
Return _SendMessage($hWnd, $HDM_GETITEMCOUNT)
EndFunc
Func _GUICtrlHeader_GetItemFormat($hWnd, $iIndex)
If $Debug_HDR Then __UDF_ValidateClassName($hWnd, $__HEADERCONSTANT_ClassName)
Local $tItem = DllStructCreate($tagHDITEM)
DllStructSetData($tItem, "Mask", $HDI_FORMAT)
_GUICtrlHeader_GetItem($hWnd, $iIndex, $tItem)
Return DllStructGetData($tItem, "Fmt")
EndFunc
Func _GUICtrlHeader_GetUnicodeFormat($hWnd)
If $Debug_HDR Then __UDF_ValidateClassName($hWnd, $__HEADERCONSTANT_ClassName)
Return _SendMessage($hWnd, $HDM_GETUNICODEFORMAT) <> 0
EndFunc
Func _GUICtrlHeader_SetItem($hWnd, $iIndex, ByRef $tItem)
If $Debug_HDR Then __UDF_ValidateClassName($hWnd, $__HEADERCONSTANT_ClassName)
Local $fUnicode = _GUICtrlHeader_GetUnicodeFormat($hWnd)
Local $iRet
If _WinAPI_InProcess($hWnd, $_ghHDRLastWnd) Then
$iRet = _SendMessage($hWnd, $HDM_SETITEMW, $iIndex, $tItem, 0, "wparam", "struct*")
Else
Local $iItem = DllStructGetSize($tItem)
Local $tMemMap
Local $pMemory = _MemInit($hWnd, $iItem, $tMemMap)
_MemWrite($tMemMap, $tItem)
If $fUnicode Then
$iRet = _SendMessage($hWnd, $HDM_SETITEMW, $iIndex, $pMemory, 0, "wparam", "ptr")
Else
$iRet = _SendMessage($hWnd, $HDM_SETITEMA, $iIndex, $pMemory, 0, "wparam", "ptr")
EndIf
_MemFree($tMemMap)
EndIf
Return $iRet <> 0
EndFunc
Func _GUICtrlHeader_SetItemFormat($hWnd, $iIndex, $iFormat)
If $Debug_HDR Then __UDF_ValidateClassName($hWnd, $__HEADERCONSTANT_ClassName)
Local $tItem = DllStructCreate($tagHDITEM)
DllStructSetData($tItem, "Mask", $HDI_FORMAT)
DllStructSetData($tItem, "Fmt", $iFormat)
Return _GUICtrlHeader_SetItem($hWnd, $iIndex, $tItem)
EndFunc
Global $_lv_ghLastWnd
Global $Debug_LV = False
Global Const $__LISTVIEWCONSTANT_ClassName = "SysListView32"
Global Const $__LISTVIEWCONSTANT_WM_SETREDRAW = 0x000B
Global Const $tagLVCOLUMN = "uint Mask;int Fmt;int CX;ptr Text;int TextMax;int SubItem;int Image;int Order;int cxMin;int cxDefault;int cxIdeal"
Global Const $tagLVGROUP = "uint Size;uint Mask;ptr Header;int HeaderMax;ptr Footer;int FooterMax;int GroupID;uint StateMask;uint State;uint Align;" & "ptr  pszSubtitle;uint cchSubtitle;ptr pszTask;uint cchTask;ptr pszDescriptionTop;uint cchDescriptionTop;ptr pszDescriptionBottom;" & "uint cchDescriptionBottom;int iTitleImage;int iExtendedImage;int iFirstItem;uint cItems;ptr pszSubsetTitle;uint cchSubsetTitle"
Func _GUICtrlListView_AddArray($hWnd, ByRef $aItems)
If $Debug_LV Then __UDF_ValidateClassName($hWnd, $__LISTVIEWCONSTANT_ClassName)
Local $fUnicode = _GUICtrlListView_GetUnicodeFormat($hWnd)
Local $tItem = DllStructCreate($tagLVITEM)
Local $tBuffer
If $fUnicode Then
$tBuffer = DllStructCreate("wchar Text[4096]")
Else
$tBuffer = DllStructCreate("char Text[4096]")
EndIf
DllStructSetData($tItem, "Mask", $LVIF_TEXT)
DllStructSetData($tItem, "Text", DllStructGetPtr($tBuffer))
DllStructSetData($tItem, "TextMax", 4096)
Local $iLastItem = _GUICtrlListView_GetItemCount($hWnd)
_GUICtrlListView_BeginUpdate($hWnd)
If IsHWnd($hWnd) Then
If _WinAPI_InProcess($hWnd, $_lv_ghLastWnd) Then
For $iI = 0 To UBound($aItems) - 1
DllStructSetData($tItem, "Item", $iI)
DllStructSetData($tItem, "SubItem", 0)
DllStructSetData($tBuffer, "Text", $aItems[$iI][0])
_SendMessage($hWnd, $LVM_INSERTITEMW, 0, $tItem, 0, "wparam", "struct*")
For $iJ = 1 To UBound($aItems, 2) - 1
DllStructSetData($tItem, "SubItem", $iJ)
DllStructSetData($tBuffer, "Text", $aItems[$iI][$iJ])
_SendMessage($hWnd, $LVM_SETITEMW, 0, $tItem, 0, "wparam", "struct*")
Next
Next
Else
Local $iBuffer = DllStructGetSize($tBuffer)
Local $iItem = DllStructGetSize($tItem)
Local $tMemMap
Local $pMemory = _MemInit($hWnd, $iItem + $iBuffer, $tMemMap)
Local $pText = $pMemory + $iItem
DllStructSetData($tItem, "Text", $pText)
For $iI = 0 To UBound($aItems) - 1
DllStructSetData($tItem, "Item", $iI + $iLastItem)
DllStructSetData($tItem, "SubItem", 0)
DllStructSetData($tBuffer, "Text", $aItems[$iI][0])
_MemWrite($tMemMap, $tItem, $pMemory, $iItem)
_MemWrite($tMemMap, $tBuffer, $pText, $iBuffer)
If $fUnicode Then
_SendMessage($hWnd, $LVM_INSERTITEMW, 0, $pMemory, 0, "wparam", "ptr")
Else
_SendMessage($hWnd, $LVM_INSERTITEMA, 0, $pMemory, 0, "wparam", "ptr")
EndIf
For $iJ = 1 To UBound($aItems, 2) - 1
DllStructSetData($tItem, "SubItem", $iJ)
DllStructSetData($tBuffer, "Text", $aItems[$iI][$iJ])
_MemWrite($tMemMap, $tItem, $pMemory, $iItem)
_MemWrite($tMemMap, $tBuffer, $pText, $iBuffer)
If $fUnicode Then
_SendMessage($hWnd, $LVM_SETITEMW, 0, $pMemory, 0, "wparam", "ptr")
Else
_SendMessage($hWnd, $LVM_SETITEMA, 0, $pMemory, 0, "wparam", "ptr")
EndIf
Next
Next
_MemFree($tMemMap)
EndIf
Else
Local $pItem = DllStructGetPtr($tItem)
For $iI = 0 To UBound($aItems) - 1
DllStructSetData($tItem, "Item", $iI + $iLastItem)
DllStructSetData($tItem, "SubItem", 0)
DllStructSetData($tBuffer, "Text", $aItems[$iI][0])
If $fUnicode Then
GUICtrlSendMsg($hWnd, $LVM_INSERTITEMW, 0, $pItem)
Else
GUICtrlSendMsg($hWnd, $LVM_INSERTITEMA, 0, $pItem)
EndIf
For $iJ = 1 To UBound($aItems, 2) - 1
DllStructSetData($tItem, "SubItem", $iJ)
DllStructSetData($tBuffer, "Text", $aItems[$iI][$iJ])
If $fUnicode Then
GUICtrlSendMsg($hWnd, $LVM_SETITEMW, 0, $pItem)
Else
GUICtrlSendMsg($hWnd, $LVM_SETITEMA, 0, $pItem)
EndIf
Next
Next
EndIf
_GUICtrlListView_EndUpdate($hWnd)
EndFunc
Func _GUICtrlListView_BeginUpdate($hWnd)
If $Debug_LV Then __UDF_ValidateClassName($hWnd, $__LISTVIEWCONSTANT_ClassName)
If Not IsHWnd($hWnd) Then $hWnd = GUICtrlGetHandle($hWnd)
Return _SendMessage($hWnd, $__LISTVIEWCONSTANT_WM_SETREDRAW) = 0
EndFunc
Func _GUICtrlListView_ClickItem($hWnd, $iIndex, $sButton = "left", $fMove = False, $iClicks = 1, $iSpeed = 1)
If $Debug_LV Then __UDF_ValidateClassName($hWnd, $__LISTVIEWCONSTANT_ClassName)
If Not IsHWnd($hWnd) Then $hWnd = GUICtrlGetHandle($hWnd)
_GUICtrlListView_EnsureVisible($hWnd, $iIndex, False)
Local $tRect = _GUICtrlListView_GetItemRectEx($hWnd, $iIndex, $LVIR_LABEL)
Local $tPoint = _WinAPI_PointFromRect($tRect, True)
$tPoint = _WinAPI_ClientToScreen($hWnd, $tPoint)
Local $iX, $iY
_WinAPI_GetXYFromPoint($tPoint, $iX, $iY)
Local $iMode = Opt("MouseCoordMode", 1)
If Not $fMove Then
Local $aPos = MouseGetPos()
_WinAPI_ShowCursor(False)
MouseClick($sButton, $iX, $iY, $iClicks, $iSpeed)
MouseMove($aPos[0], $aPos[1], 0)
_WinAPI_ShowCursor(True)
Else
MouseClick($sButton, $iX, $iY, $iClicks, $iSpeed)
EndIf
Opt("MouseCoordMode", $iMode)
EndFunc
Func _GUICtrlListView_DeleteAllItems($hWnd)
If $Debug_LV Then __UDF_ValidateClassName($hWnd, $__LISTVIEWCONSTANT_ClassName)
If _GUICtrlListView_GetItemCount($hWnd) == 0 Then Return True
If IsHWnd($hWnd) Then
Return _SendMessage($hWnd, $LVM_DELETEALLITEMS) <> 0
Else
Local $ctrlID
For $index = _GUICtrlListView_GetItemCount($hWnd) - 1 To 0 Step -1
$ctrlID = _GUICtrlListView_GetItemParam($hWnd, $index)
If $ctrlID Then GUICtrlDelete($ctrlID)
Next
If _GUICtrlListView_GetItemCount($hWnd) == 0 Then Return True
EndIf
Return False
EndFunc
Func _GUICtrlListView_DeleteItem($hWnd, $iIndex)
If $Debug_LV Then __UDF_ValidateClassName($hWnd, $__LISTVIEWCONSTANT_ClassName)
If IsHWnd($hWnd) Then
Return _SendMessage($hWnd, $LVM_DELETEITEM, $iIndex) <> 0
Else
Local $ctrlID = _GUICtrlListView_GetItemParam($hWnd, $iIndex)
If $ctrlID Then Return GUICtrlDelete($ctrlID) <> 0
EndIf
Return False
EndFunc
Func _GUICtrlListView_DeleteItemsSelected($hWnd)
If $Debug_LV Then __UDF_ValidateClassName($hWnd, $__LISTVIEWCONSTANT_ClassName)
Local $ItemCount = _GUICtrlListView_GetItemCount($hWnd)
If(_GUICtrlListView_GetSelectedCount($hWnd) == $ItemCount) Then
Return _GUICtrlListView_DeleteAllItems($hWnd)
Else
Local $items = _GUICtrlListView_GetSelectedIndices($hWnd, 1)
If Not IsArray($items) Then Return SetError($LV_ERR, $LV_ERR, 0)
_GUICtrlListView_SetItemSelected($hWnd, -1, False)
For $i = $items[0] To 1 Step -1
If Not _GUICtrlListView_DeleteItem($hWnd, $items[$i]) Then Return False
Next
Return True
EndIf
EndFunc
Func _GUICtrlListView_EditLabel($hWnd, $iIndex)
If $Debug_LV Then __UDF_ValidateClassName($hWnd, $__LISTVIEWCONSTANT_ClassName)
Local $fUnicode = _GUICtrlListView_GetUnicodeFormat($hWnd)
Local $aResult
If IsHWnd($hWnd) Then
$aResult = DllCall("user32.dll", "hwnd", "SetFocus", "hwnd", $hWnd)
If @error Then Return SetError(@error, @extended, 0)
If $aResult = 0 Then Return 0
If $fUnicode Then
Return _SendMessage($hWnd, $LVM_EDITLABELW, $iIndex, 0, 0, "wparam", "lparam", "hwnd")
Else
Return _SendMessage($hWnd, $LVM_EDITLABEL, $iIndex, 0, 0, "wparam", "lparam", "hwnd")
EndIf
Else
$aResult = DllCall("user32.dll", "hwnd", "SetFocus", "hwnd", GUICtrlGetHandle($hWnd))
If @error Then Return SetError(@error, @extended, 0)
If $aResult = 0 Then Return 0
If $fUnicode Then
Return HWnd(GUICtrlSendMsg($hWnd, $LVM_EDITLABELW, $iIndex, 0))
Else
Return HWnd(GUICtrlSendMsg($hWnd, $LVM_EDITLABEL, $iIndex, 0))
EndIf
EndIf
EndFunc
Func _GUICtrlListView_EnableGroupView($hWnd, $fEnable = True)
If $Debug_LV Then __UDF_ValidateClassName($hWnd, $__LISTVIEWCONSTANT_ClassName)
If IsHWnd($hWnd) Then
Return _SendMessage($hWnd, $LVM_ENABLEGROUPVIEW, $fEnable)
Else
Return GUICtrlSendMsg($hWnd, $LVM_ENABLEGROUPVIEW, $fEnable, 0)
EndIf
EndFunc
Func _GUICtrlListView_EndUpdate($hWnd)
If $Debug_LV Then __UDF_ValidateClassName($hWnd, $__LISTVIEWCONSTANT_ClassName)
If Not IsHWnd($hWnd) Then $hWnd = GUICtrlGetHandle($hWnd)
Return _SendMessage($hWnd, $__LISTVIEWCONSTANT_WM_SETREDRAW, 1) = 0
EndFunc
Func _GUICtrlListView_EnsureVisible($hWnd, $iIndex, $fPartialOK = False)
If $Debug_LV Then __UDF_ValidateClassName($hWnd, $__LISTVIEWCONSTANT_ClassName)
If IsHWnd($hWnd) Then
Return _SendMessage($hWnd, $LVM_ENSUREVISIBLE, $iIndex, $fPartialOK)
Else
Return GUICtrlSendMsg($hWnd, $LVM_ENSUREVISIBLE, $iIndex, $fPartialOK)
EndIf
EndFunc
Func _GUICtrlListView_GetColumnCount($hWnd)
If $Debug_LV Then __UDF_ValidateClassName($hWnd, $__LISTVIEWCONSTANT_ClassName)
Return _SendMessage(_GUICtrlListView_GetHeader($hWnd), 0x1200)
EndFunc
Func _GUICtrlListView_GetHeader($hWnd)
If $Debug_LV Then __UDF_ValidateClassName($hWnd, $__LISTVIEWCONSTANT_ClassName)
If IsHWnd($hWnd) Then
Return HWnd(_SendMessage($hWnd, $LVM_GETHEADER))
Else
Return HWnd(GUICtrlSendMsg($hWnd, $LVM_GETHEADER, 0, 0))
EndIf
EndFunc
Func _GUICtrlListView_GetItemCount($hWnd)
If $Debug_LV Then __UDF_ValidateClassName($hWnd, $__LISTVIEWCONSTANT_ClassName)
If IsHWnd($hWnd) Then
Return _SendMessage($hWnd, $LVM_GETITEMCOUNT)
Else
Return GUICtrlSendMsg($hWnd, $LVM_GETITEMCOUNT, 0, 0)
EndIf
EndFunc
Func _GUICtrlListView_GetItemEx($hWnd, ByRef $tItem)
If $Debug_LV Then __UDF_ValidateClassName($hWnd, $__LISTVIEWCONSTANT_ClassName)
Local $fUnicode = _GUICtrlListView_GetUnicodeFormat($hWnd)
Local $iRet
If IsHWnd($hWnd) Then
If _WinAPI_InProcess($hWnd, $_lv_ghLastWnd) Then
$iRet = _SendMessage($hWnd, $LVM_GETITEMW, 0, $tItem, 0, "wparam", "struct*")
Else
Local $iItem = DllStructGetSize($tItem)
Local $tMemMap
Local $pMemory = _MemInit($hWnd, $iItem, $tMemMap)
_MemWrite($tMemMap, $tItem)
If $fUnicode Then
_SendMessage($hWnd, $LVM_GETITEMW, 0, $pMemory, 0, "wparam", "ptr")
Else
_SendMessage($hWnd, $LVM_GETITEMA, 0, $pMemory, 0, "wparam", "ptr")
EndIf
_MemRead($tMemMap, $pMemory, $tItem, $iItem)
_MemFree($tMemMap)
EndIf
Else
Local $pItem = DllStructGetPtr($tItem)
If $fUnicode Then
$iRet = GUICtrlSendMsg($hWnd, $LVM_GETITEMW, 0, $pItem)
Else
$iRet = GUICtrlSendMsg($hWnd, $LVM_GETITEMA, 0, $pItem)
EndIf
EndIf
Return $iRet <> 0
EndFunc
Func _GUICtrlListView_GetItemParam($hWnd, $iIndex)
Local $tItem = DllStructCreate($tagLVITEM)
DllStructSetData($tItem, "Mask", $LVIF_PARAM)
DllStructSetData($tItem, "Item", $iIndex)
_GUICtrlListView_GetItemEx($hWnd, $tItem)
Return DllStructGetData($tItem, "Param")
EndFunc
Func _GUICtrlListView_GetItemPosition($hWnd, $iIndex)
If $Debug_LV Then __UDF_ValidateClassName($hWnd, $__LISTVIEWCONSTANT_ClassName)
Local $aPoint[2], $iRet
Local $tPoint = DllStructCreate($tagPOINT)
If IsHWnd($hWnd) Then
If _WinAPI_InProcess($hWnd, $_lv_ghLastWnd) Then
If Not _SendMessage($hWnd, $LVM_GETITEMPOSITION, $iIndex, $tPoint, 0, "wparam", "struct*") Then Return $aPoint
Else
Local $iPoint = DllStructGetSize($tPoint)
Local $tMemMap
Local $pMemory = _MemInit($hWnd, $iPoint, $tMemMap)
If Not _SendMessage($hWnd, $LVM_GETITEMPOSITION, $iIndex, $pMemory, 0, "wparam", "ptr") Then Return $aPoint
_MemRead($tMemMap, $pMemory, $tPoint, $iPoint)
_MemFree($tMemMap)
EndIf
Else
$iRet = GUICtrlSendMsg($hWnd, $LVM_GETITEMPOSITION, $iIndex, DllStructGetPtr($tPoint))
If Not $iRet Then Return $aPoint
EndIf
$aPoint[0] = DllStructGetData($tPoint, "X")
$aPoint[1] = DllStructGetData($tPoint, "Y")
Return $aPoint
EndFunc
Func _GUICtrlListView_GetItemPositionY($hWnd, $iIndex)
Local $aPoint = _GUICtrlListView_GetItemPosition($hWnd, $iIndex)
Return $aPoint[1]
EndFunc
Func _GUICtrlListView_GetItemRectEx($hWnd, $iIndex, $iPart = 3)
If $Debug_LV Then __UDF_ValidateClassName($hWnd, $__LISTVIEWCONSTANT_ClassName)
Local $tRect = DllStructCreate($tagRECT)
DllStructSetData($tRect, "Left", $iPart)
If IsHWnd($hWnd) Then
If _WinAPI_InProcess($hWnd, $_lv_ghLastWnd) Then
_SendMessage($hWnd, $LVM_GETITEMRECT, $iIndex, $tRect, 0, "wparam", "struct*")
Else
Local $iRect = DllStructGetSize($tRect)
Local $tMemMap
Local $pMemory = _MemInit($hWnd, $iRect, $tMemMap)
_MemWrite($tMemMap, $tRect, $pMemory, $iRect)
_SendMessage($hWnd, $LVM_GETITEMRECT, $iIndex, $pMemory, 0, "wparam", "ptr")
_MemRead($tMemMap, $pMemory, $tRect, $iRect)
_MemFree($tMemMap)
EndIf
Else
GUICtrlSendMsg($hWnd, $LVM_GETITEMRECT, $iIndex, DllStructGetPtr($tRect))
EndIf
Return $tRect
EndFunc
Func _GUICtrlListView_GetItemText($hWnd, $iIndex, $iSubItem = 0)
If $Debug_LV Then __UDF_ValidateClassName($hWnd, $__LISTVIEWCONSTANT_ClassName)
Local $fUnicode = _GUICtrlListView_GetUnicodeFormat($hWnd)
Local $tBuffer
If $fUnicode Then
$tBuffer = DllStructCreate("wchar Text[4096]")
Else
$tBuffer = DllStructCreate("char Text[4096]")
EndIf
Local $pBuffer = DllStructGetPtr($tBuffer)
Local $tItem = DllStructCreate($tagLVITEM)
DllStructSetData($tItem, "SubItem", $iSubItem)
DllStructSetData($tItem, "TextMax", 4096)
If IsHWnd($hWnd) Then
If _WinAPI_InProcess($hWnd, $_lv_ghLastWnd) Then
DllStructSetData($tItem, "Text", $pBuffer)
_SendMessage($hWnd, $LVM_GETITEMTEXTW, $iIndex, $tItem, 0, "wparam", "struct*")
Else
Local $iItem = DllStructGetSize($tItem)
Local $tMemMap
Local $pMemory = _MemInit($hWnd, $iItem + 4096, $tMemMap)
Local $pText = $pMemory + $iItem
DllStructSetData($tItem, "Text", $pText)
_MemWrite($tMemMap, $tItem, $pMemory, $iItem)
If $fUnicode Then
_SendMessage($hWnd, $LVM_GETITEMTEXTW, $iIndex, $pMemory, 0, "wparam", "ptr")
Else
_SendMessage($hWnd, $LVM_GETITEMTEXTA, $iIndex, $pMemory, 0, "wparam", "ptr")
EndIf
_MemRead($tMemMap, $pText, $tBuffer, 4096)
_MemFree($tMemMap)
EndIf
Else
Local $pItem = DllStructGetPtr($tItem)
DllStructSetData($tItem, "Text", $pBuffer)
If $fUnicode Then
GUICtrlSendMsg($hWnd, $LVM_GETITEMTEXTW, $iIndex, $pItem)
Else
GUICtrlSendMsg($hWnd, $LVM_GETITEMTEXTA, $iIndex, $pItem)
EndIf
EndIf
Return DllStructGetData($tBuffer, "Text")
EndFunc
Func _GUICtrlListView_GetItemTextString($hWnd, $iItem = -1)
If $Debug_LV Then __UDF_ValidateClassName($hWnd, $__LISTVIEWCONSTANT_ClassName)
Local $sRow = "", $SeparatorChar = Opt('GUIDataSeparatorChar'), $iSelected
If $iItem = -1 Then
$iSelected = _GUICtrlListView_GetNextItem($hWnd)
Else
$iSelected = $iItem
EndIf
For $x = 0 To _GUICtrlListView_GetColumnCount($hWnd) - 1
$sRow &= _GUICtrlListView_GetItemText($hWnd, $iSelected, $x) & $SeparatorChar
Next
Return StringTrimRight($sRow, 1)
EndFunc
Func _GUICtrlListView_GetNextItem($hWnd, $iStart = -1, $iSearch = 0, $iState = 8)
If $Debug_LV Then __UDF_ValidateClassName($hWnd, $__LISTVIEWCONSTANT_ClassName)
Local $aSearch[5] = [$LVNI_ALL, $LVNI_ABOVE, $LVNI_BELOW, $LVNI_TOLEFT, $LVNI_TORIGHT]
Local $iFlags = $aSearch[$iSearch]
If BitAND($iState, 1) <> 0 Then $iFlags = BitOR($iFlags, $LVNI_CUT)
If BitAND($iState, 2) <> 0 Then $iFlags = BitOR($iFlags, $LVNI_DROPHILITED)
If BitAND($iState, 4) <> 0 Then $iFlags = BitOR($iFlags, $LVNI_FOCUSED)
If BitAND($iState, 8) <> 0 Then $iFlags = BitOR($iFlags, $LVNI_SELECTED)
If IsHWnd($hWnd) Then
Return _SendMessage($hWnd, $LVM_GETNEXTITEM, $iStart, $iFlags)
Else
Return GUICtrlSendMsg($hWnd, $LVM_GETNEXTITEM, $iStart, $iFlags)
EndIf
EndFunc
Func _GUICtrlListView_GetSelectedCount($hWnd)
If $Debug_LV Then __UDF_ValidateClassName($hWnd, $__LISTVIEWCONSTANT_ClassName)
If IsHWnd($hWnd) Then
Return _SendMessage($hWnd, $LVM_GETSELECTEDCOUNT)
Else
Return GUICtrlSendMsg($hWnd, $LVM_GETSELECTEDCOUNT, 0, 0)
EndIf
EndFunc
Func _GUICtrlListView_GetSelectedIndices($hWnd, $fArray = False)
If $Debug_LV Then __UDF_ValidateClassName($hWnd, $__LISTVIEWCONSTANT_ClassName)
Local $sIndices, $aIndices[1] = [0]
Local $iRet, $iCount = _GUICtrlListView_GetItemCount($hWnd)
For $iItem = 0 To $iCount
If IsHWnd($hWnd) Then
$iRet = _SendMessage($hWnd, $LVM_GETITEMSTATE, $iItem, $LVIS_SELECTED)
Else
$iRet = GUICtrlSendMsg($hWnd, $LVM_GETITEMSTATE, $iItem, $LVIS_SELECTED)
EndIf
If $iRet Then
If(Not $fArray) Then
If StringLen($sIndices) Then
$sIndices &= "|" & $iItem
Else
$sIndices = $iItem
EndIf
Else
ReDim $aIndices[UBound($aIndices) + 1]
$aIndices[0] = UBound($aIndices) - 1
$aIndices[UBound($aIndices) - 1] = $iItem
EndIf
EndIf
Next
If(Not $fArray) Then
Return String($sIndices)
Else
Return $aIndices
EndIf
EndFunc
Func _GUICtrlListView_GetSubItemRect($hWnd, $iIndex, $iSubItem, $iPart = 0)
If $Debug_LV Then __UDF_ValidateClassName($hWnd, $__LISTVIEWCONSTANT_ClassName)
Local $aPart[2] = [$LVIR_BOUNDS, $LVIR_ICON]
Local $tRect = DllStructCreate($tagRECT)
DllStructSetData($tRect, "Top", $iSubItem)
DllStructSetData($tRect, "Left", $aPart[$iPart])
If IsHWnd($hWnd) Then
If _WinAPI_InProcess($hWnd, $_lv_ghLastWnd) Then
_SendMessage($hWnd, $LVM_GETSUBITEMRECT, $iIndex, $tRect, 0, "wparam", "struct*")
Else
Local $iRect = DllStructGetSize($tRect)
Local $tMemMap
Local $pMemory = _MemInit($hWnd, $iRect, $tMemMap)
_MemWrite($tMemMap, $tRect, $pMemory, $iRect)
_SendMessage($hWnd, $LVM_GETSUBITEMRECT, $iIndex, $pMemory, 0, "wparam", "ptr")
_MemRead($tMemMap, $pMemory, $tRect, $iRect)
_MemFree($tMemMap)
EndIf
Else
GUICtrlSendMsg($hWnd, $LVM_GETSUBITEMRECT, $iIndex, DllStructGetPtr($tRect))
EndIf
Local $aRect[4]
$aRect[0] = DllStructGetData($tRect, "Left")
$aRect[1] = DllStructGetData($tRect, "Top")
$aRect[2] = DllStructGetData($tRect, "Right")
$aRect[3] = DllStructGetData($tRect, "Bottom")
Return $aRect
EndFunc
Func _GUICtrlListView_GetUnicodeFormat($hWnd)
If $Debug_LV Then __UDF_ValidateClassName($hWnd, $__LISTVIEWCONSTANT_ClassName)
If IsHWnd($hWnd) Then
Return _SendMessage($hWnd, $LVM_GETUNICODEFORMAT) <> 0
Else
Return GUICtrlSendMsg($hWnd, $LVM_GETUNICODEFORMAT, 0, 0) <> 0
EndIf
EndFunc
Func _GUICtrlListView_HideColumn($hWnd, $iCol)
If $Debug_LV Then __UDF_ValidateClassName($hWnd, $__LISTVIEWCONSTANT_ClassName)
If IsHWnd($hWnd) Then
Return _SendMessage($hWnd, $LVM_SETCOLUMNWIDTH, $iCol) <> 0
Else
Return GUICtrlSendMsg($hWnd, $LVM_SETCOLUMNWIDTH, $iCol, 0) <> 0
EndIf
EndFunc
Func _GUICtrlListView_InsertColumn($hWnd, $iIndex, $sText, $iWidth = 50, $iAlign = -1, $iImage = -1, $fOnRight = False)
If $Debug_LV Then __UDF_ValidateClassName($hWnd, $__LISTVIEWCONSTANT_ClassName)
Local $aAlign[3] = [$LVCFMT_LEFT, $LVCFMT_RIGHT, $LVCFMT_CENTER]
Local $fUnicode = _GUICtrlListView_GetUnicodeFormat($hWnd)
Local $iBuffer = StringLen($sText) + 1
Local $tBuffer
If $fUnicode Then
$tBuffer = DllStructCreate("wchar Text[" & $iBuffer & "]")
$iBuffer *= 2
Else
$tBuffer = DllStructCreate("char Text[" & $iBuffer & "]")
EndIf
Local $pBuffer = DllStructGetPtr($tBuffer)
Local $tColumn = DllStructCreate($tagLVCOLUMN)
Local $iMask = BitOR($LVCF_FMT, $LVCF_WIDTH, $LVCF_TEXT)
If $iAlign < 0 Or $iAlign > 2 Then $iAlign = 0
Local $iFmt = $aAlign[$iAlign]
If $iImage <> -1 Then
$iMask = BitOR($iMask, $LVCF_IMAGE)
$iFmt = BitOR($iFmt, $LVCFMT_COL_HAS_IMAGES, $LVCFMT_IMAGE)
EndIf
If $fOnRight Then $iFmt = BitOR($iFmt, $LVCFMT_BITMAP_ON_RIGHT)
DllStructSetData($tBuffer, "Text", $sText)
DllStructSetData($tColumn, "Mask", $iMask)
DllStructSetData($tColumn, "Fmt", $iFmt)
DllStructSetData($tColumn, "CX", $iWidth)
DllStructSetData($tColumn, "TextMax", $iBuffer)
DllStructSetData($tColumn, "Image", $iImage)
Local $iRet
If IsHWnd($hWnd) Then
If _WinAPI_InProcess($hWnd, $_lv_ghLastWnd) Then
DllStructSetData($tColumn, "Text", $pBuffer)
$iRet = _SendMessage($hWnd, $LVM_INSERTCOLUMNW, $iIndex, $tColumn, 0, "wparam", "struct*")
Else
Local $iColumn = DllStructGetSize($tColumn)
Local $tMemMap
Local $pMemory = _MemInit($hWnd, $iColumn + $iBuffer, $tMemMap)
Local $pText = $pMemory + $iColumn
DllStructSetData($tColumn, "Text", $pText)
_MemWrite($tMemMap, $tColumn, $pMemory, $iColumn)
_MemWrite($tMemMap, $tBuffer, $pText, $iBuffer)
If $fUnicode Then
$iRet = _SendMessage($hWnd, $LVM_INSERTCOLUMNW, $iIndex, $pMemory, 0, "wparam", "ptr")
Else
$iRet = _SendMessage($hWnd, $LVM_INSERTCOLUMNA, $iIndex, $pMemory, 0, "wparam", "ptr")
EndIf
_MemFree($tMemMap)
EndIf
Else
Local $pColumn = DllStructGetPtr($tColumn)
DllStructSetData($tColumn, "Text", $pBuffer)
If $fUnicode Then
$iRet = GUICtrlSendMsg($hWnd, $LVM_INSERTCOLUMNW, $iIndex, $pColumn)
Else
$iRet = GUICtrlSendMsg($hWnd, $LVM_INSERTCOLUMNA, $iIndex, $pColumn)
EndIf
EndIf
If $iAlign > 0 Then _GUICtrlListView_SetColumn($hWnd, $iRet, $sText, $iWidth, $iAlign, $iImage, $fOnRight)
Return $iRet
EndFunc
Func _GUICtrlListView_InsertGroup($hWnd, $iIndex, $iGroupID, $sHeader, $iAlign = 0)
If $Debug_LV Then __UDF_ValidateClassName($hWnd, $__LISTVIEWCONSTANT_ClassName)
Local $aAlign[3] = [$LVGA_HEADER_LEFT, $LVGA_HEADER_CENTER, $LVGA_HEADER_RIGHT]
If $iAlign < 0 Or $iAlign > 2 Then $iAlign = 0
Local $tHeader = _WinAPI_MultiByteToWideChar($sHeader)
Local $pHeader = DllStructGetPtr($tHeader)
Local $iHeader = StringLen($sHeader)
Local $tGroup = DllStructCreate($tagLVGROUP)
Local $iGroup = DllStructGetSize($tGroup)
Local $iMask = BitOR($LVGF_HEADER, $LVGF_ALIGN, $LVGF_GROUPID)
DllStructSetData($tGroup, "Size", $iGroup)
DllStructSetData($tGroup, "Mask", $iMask)
DllStructSetData($tGroup, "HeaderMax", $iHeader)
DllStructSetData($tGroup, "GroupID", $iGroupID)
DllStructSetData($tGroup, "Align", $aAlign[$iAlign])
Local $iRet
If IsHWnd($hWnd) Then
If _WinAPI_InProcess($hWnd, $_lv_ghLastWnd) Then
DllStructSetData($tGroup, "Header", $pHeader)
$iRet = _SendMessage($hWnd, $LVM_INSERTGROUP, $iIndex, $tGroup, 0, "wparam", "struct*")
Else
Local $tMemMap
Local $pMemory = _MemInit($hWnd, $iGroup + $iHeader, $tMemMap)
Local $pText = $pMemory + $iGroup
DllStructSetData($tGroup, "Header", $pText)
_MemWrite($tMemMap, $tGroup, $pMemory, $iGroup)
_MemWrite($tMemMap, $tHeader, $pText, $iHeader)
$iRet = _SendMessage($hWnd, $LVM_INSERTGROUP, $iIndex, $tGroup, 0, "wparam", "struct*")
_MemFree($tMemMap)
EndIf
Else
DllStructSetData($tGroup, "Header", $pHeader)
$iRet = GUICtrlSendMsg($hWnd, $LVM_INSERTGROUP, $iIndex, DllStructGetPtr($tGroup))
EndIf
Return $iRet
EndFunc
Func _GUICtrlListView_JustifyColumn($hWnd, $iIndex, $iAlign = -1)
If $Debug_LV Then __UDF_ValidateClassName($hWnd, $__LISTVIEWCONSTANT_ClassName)
Local $aAlign[3] = [$LVCFMT_LEFT, $LVCFMT_RIGHT, $LVCFMT_CENTER]
Local $fUnicode = _GUICtrlListView_GetUnicodeFormat($hWnd)
Local $tColumn = DllStructCreate($tagLVCOLUMN)
If $iAlign < 0 Or $iAlign > 2 Then $iAlign = 0
Local $iMask = $LVCF_FMT
Local $iFmt = $aAlign[$iAlign]
DllStructSetData($tColumn, "Mask", $iMask)
DllStructSetData($tColumn, "Fmt", $iFmt)
Local $iRet
If IsHWnd($hWnd) Then
If _WinAPI_InProcess($hWnd, $_lv_ghLastWnd) Then
$iRet = _SendMessage($hWnd, $LVM_SETCOLUMNW, $iIndex, $tColumn, 0, "wparam", "struct*")
Else
Local $iColumn = DllStructGetSize($tColumn)
Local $tMemMap
Local $pMemory = _MemInit($hWnd, $iColumn, $tMemMap)
_MemWrite($tMemMap, $tColumn, $pMemory, $iColumn)
If $fUnicode Then
$iRet = _SendMessage($hWnd, $LVM_SETCOLUMNW, $iIndex, $pMemory, 0, "wparam", "ptr")
Else
$iRet = _SendMessage($hWnd, $LVM_SETCOLUMNA, $iIndex, $pMemory, 0, "wparam", "ptr")
EndIf
_MemFree($tMemMap)
EndIf
Else
Local $pColumn = DllStructGetPtr($tColumn)
If $fUnicode Then
$iRet = GUICtrlSendMsg($hWnd, $LVM_SETCOLUMNW, $iIndex, $pColumn)
Else
$iRet = GUICtrlSendMsg($hWnd, $LVM_SETCOLUMNA, $iIndex, $pColumn)
EndIf
EndIf
Return $iRet <> 0
EndFunc
Func _GUICtrlListView_RedrawItems($hWnd, $iFirst, $iLast)
If $Debug_LV Then __UDF_ValidateClassName($hWnd, $__LISTVIEWCONSTANT_ClassName)
If IsHWnd($hWnd) Then
Return _SendMessage($hWnd, $LVM_REDRAWITEMS, $iFirst, $iLast) <> 0
Else
Return GUICtrlSendMsg($hWnd, $LVM_REDRAWITEMS, $iFirst, $iLast) <> 0
EndIf
EndFunc
Func _GUICtrlListView_SetColumn($hWnd, $iIndex, $sText, $iWidth = -1, $iAlign = -1, $iImage = -1, $fOnRight = False)
If $Debug_LV Then __UDF_ValidateClassName($hWnd, $__LISTVIEWCONSTANT_ClassName)
Local $fUnicode = _GUICtrlListView_GetUnicodeFormat($hWnd)
Local $aAlign[3] = [$LVCFMT_LEFT, $LVCFMT_RIGHT, $LVCFMT_CENTER]
Local $iBuffer = StringLen($sText) + 1
Local $tBuffer
If $fUnicode Then
$tBuffer = DllStructCreate("wchar Text[" & $iBuffer & "]")
$iBuffer *= 2
Else
$tBuffer = DllStructCreate("char Text[" & $iBuffer & "]")
EndIf
Local $pBuffer = DllStructGetPtr($tBuffer)
Local $tColumn = DllStructCreate($tagLVCOLUMN)
Local $iMask = $LVCF_TEXT
If $iAlign < 0 Or $iAlign > 2 Then $iAlign = 0
$iMask = BitOR($iMask, $LVCF_FMT)
Local $iFmt = $aAlign[$iAlign]
If $iWidth <> -1 Then $iMask = BitOR($iMask, $LVCF_WIDTH)
If $iImage <> -1 Then
$iMask = BitOR($iMask, $LVCF_IMAGE)
$iFmt = BitOR($iFmt, $LVCFMT_COL_HAS_IMAGES, $LVCFMT_IMAGE)
Else
$iImage = 0
EndIf
If $fOnRight Then $iFmt = BitOR($iFmt, $LVCFMT_BITMAP_ON_RIGHT)
DllStructSetData($tBuffer, "Text", $sText)
DllStructSetData($tColumn, "Mask", $iMask)
DllStructSetData($tColumn, "Fmt", $iFmt)
DllStructSetData($tColumn, "CX", $iWidth)
DllStructSetData($tColumn, "TextMax", $iBuffer)
DllStructSetData($tColumn, "Image", $iImage)
Local $iRet
If IsHWnd($hWnd) Then
If _WinAPI_InProcess($hWnd, $_lv_ghLastWnd) Then
DllStructSetData($tColumn, "Text", $pBuffer)
$iRet = _SendMessage($hWnd, $LVM_SETCOLUMNW, $iIndex, $tColumn, 0, "wparam", "struct*")
Else
Local $iColumn = DllStructGetSize($tColumn)
Local $tMemMap
Local $pMemory = _MemInit($hWnd, $iColumn + $iBuffer, $tMemMap)
Local $pText = $pMemory + $iColumn
DllStructSetData($tColumn, "Text", $pText)
_MemWrite($tMemMap, $tColumn, $pMemory, $iColumn)
_MemWrite($tMemMap, $tBuffer, $pText, $iBuffer)
If $fUnicode Then
$iRet = _SendMessage($hWnd, $LVM_SETCOLUMNW, $iIndex, $pMemory, 0, "wparam", "ptr")
Else
$iRet = _SendMessage($hWnd, $LVM_SETCOLUMNA, $iIndex, $pMemory, 0, "wparam", "ptr")
EndIf
_MemFree($tMemMap)
EndIf
Else
Local $pColumn = DllStructGetPtr($tColumn)
DllStructSetData($tColumn, "Text", $pBuffer)
If $fUnicode Then
$iRet = GUICtrlSendMsg($hWnd, $LVM_SETCOLUMNW, $iIndex, $pColumn)
Else
$iRet = GUICtrlSendMsg($hWnd, $LVM_SETCOLUMNA, $iIndex, $pColumn)
EndIf
EndIf
Return $iRet <> 0
EndFunc
Func _GUICtrlListView_SetColumnOrder($hWnd, $sOrder)
Local $SeparatorChar = Opt('GUIDataSeparatorChar')
Return _GUICtrlListView_SetColumnOrderArray($hWnd, StringSplit($sOrder, $SeparatorChar))
EndFunc
Func _GUICtrlListView_SetColumnOrderArray($hWnd, $aOrder)
If $Debug_LV Then __UDF_ValidateClassName($hWnd, $__LISTVIEWCONSTANT_ClassName)
Local $tBuffer = DllStructCreate("int[" & $aOrder[0] & "]")
For $iI = 1 To $aOrder[0]
DllStructSetData($tBuffer, 1, $aOrder[$iI], $iI)
Next
Local $iRet
If IsHWnd($hWnd) Then
If _WinAPI_InProcess($hWnd, $_lv_ghLastWnd) Then
$iRet = _SendMessage($hWnd, $LVM_SETCOLUMNORDERARRAY, $aOrder[0], $tBuffer, 0, "wparam", "struct*")
Else
Local $iBuffer = DllStructGetSize($tBuffer)
Local $tMemMap
Local $pMemory = _MemInit($hWnd, $iBuffer, $tMemMap)
_MemWrite($tMemMap, $tBuffer, $pMemory, $iBuffer)
$iRet = _SendMessage($hWnd, $LVM_SETCOLUMNORDERARRAY, $aOrder[0], $pMemory, 0, "wparam", "ptr")
_MemFree($tMemMap)
EndIf
Else
$iRet = GUICtrlSendMsg($hWnd, $LVM_SETCOLUMNORDERARRAY, $aOrder[0], DllStructGetPtr($tBuffer))
EndIf
Return $iRet <> 0
EndFunc
Func _GUICtrlListView_SetColumnWidth($hWnd, $iCol, $iWidth)
If $Debug_LV Then __UDF_ValidateClassName($hWnd, $__LISTVIEWCONSTANT_ClassName)
If IsHWnd($hWnd) Then
Return _SendMessage($hWnd, $LVM_SETCOLUMNWIDTH, $iCol, $iWidth)
Else
Return GUICtrlSendMsg($hWnd, $LVM_SETCOLUMNWIDTH, $iCol, $iWidth)
EndIf
EndFunc
Func _GUICtrlListView_SetExtendedListViewStyle($hWnd, $iExStyle, $iExMask = 0)
If $Debug_LV Then __UDF_ValidateClassName($hWnd, $__LISTVIEWCONSTANT_ClassName)
Local $iRet
If IsHWnd($hWnd) Then
$iRet = _SendMessage($hWnd, $LVM_SETEXTENDEDLISTVIEWSTYLE, $iExMask, $iExStyle)
_WinAPI_InvalidateRect($hWnd)
Else
$iRet = GUICtrlSendMsg($hWnd, $LVM_SETEXTENDEDLISTVIEWSTYLE, $iExMask, $iExStyle)
_WinAPI_InvalidateRect(GUICtrlGetHandle($hWnd))
EndIf
Return $iRet
EndFunc
Func _GUICtrlListView_SetImageList($hWnd, $hHandle, $iType = 0)
If $Debug_LV Then __UDF_ValidateClassName($hWnd, $__LISTVIEWCONSTANT_ClassName)
Local $aType[3] = [$LVSIL_NORMAL, $LVSIL_SMALL, $LVSIL_STATE]
If IsHWnd($hWnd) Then
Return _SendMessage($hWnd, $LVM_SETIMAGELIST, $aType[$iType], $hHandle, 0, "wparam", "handle", "handle")
Else
Return Ptr(GUICtrlSendMsg($hWnd, $LVM_SETIMAGELIST, $aType[$iType], $hHandle))
EndIf
EndFunc
Func _GUICtrlListView_SetItemCount($hWnd, $iItems)
If $Debug_LV Then __UDF_ValidateClassName($hWnd, $__LISTVIEWCONSTANT_ClassName)
If IsHWnd($hWnd) Then
Return _SendMessage($hWnd, $LVM_SETITEMCOUNT, $iItems, BitOR($LVSICF_NOINVALIDATEALL, $LVSICF_NOSCROLL)) <> 0
Else
Return GUICtrlSendMsg($hWnd, $LVM_SETITEMCOUNT, $iItems, BitOR($LVSICF_NOINVALIDATEALL, $LVSICF_NOSCROLL)) <> 0
EndIf
EndFunc
Func _GUICtrlListView_SetItemEx($hWnd, ByRef $tItem)
If $Debug_LV Then __UDF_ValidateClassName($hWnd, $__LISTVIEWCONSTANT_ClassName)
Local $fUnicode = _GUICtrlListView_GetUnicodeFormat($hWnd)
Local $iRet
If IsHWnd($hWnd) Then
Local $iItem = DllStructGetSize($tItem)
Local $iBuffer = DllStructGetData($tItem, "TextMax")
Local $pBuffer = DllStructGetData($tItem, "Text")
If $fUnicode Then $iBuffer *= 2
Local $tMemMap
Local $pMemory = _MemInit($hWnd, $iItem + $iBuffer, $tMemMap)
Local $pText = $pMemory + $iItem
DllStructSetData($tItem, "Text", $pText)
_MemWrite($tMemMap, $tItem, $pMemory, $iItem)
If $pBuffer <> 0 Then _MemWrite($tMemMap, $pBuffer, $pText, $iBuffer)
If $fUnicode Then
$iRet = _SendMessage($hWnd, $LVM_SETITEMW, 0, $pMemory, 0, "wparam", "ptr")
Else
$iRet = _SendMessage($hWnd, $LVM_SETITEMA, 0, $pMemory, 0, "wparam", "ptr")
EndIf
_MemFree($tMemMap)
Else
Local $pItem = DllStructGetPtr($tItem)
If $fUnicode Then
$iRet = GUICtrlSendMsg($hWnd, $LVM_SETITEMW, 0, $pItem)
Else
$iRet = GUICtrlSendMsg($hWnd, $LVM_SETITEMA, 0, $pItem)
EndIf
EndIf
Return $iRet <> 0
EndFunc
Func _GUICtrlListView_SetItemGroupID($hWnd, $iIndex, $iGroupID)
Local $tItem = DllStructCreate($tagLVITEM)
DllStructSetData($tItem, "Mask", $LVIF_GROUPID)
DllStructSetData($tItem, "Item", $iIndex)
DllStructSetData($tItem, "GroupID", $iGroupID)
_GUICtrlListView_SetItemEx($hWnd, $tItem)
EndFunc
Func _GUICtrlListView_SetItemSelected($hWnd, $iIndex, $fSelected = True, $fFocused = False)
If $Debug_LV Then __UDF_ValidateClassName($hWnd, $__LISTVIEWCONSTANT_ClassName)
Local $tStruct = DllStructCreate($tagLVITEM)
Local $iRet, $iSelected = 0, $iFocused = 0, $iSize, $tMemMap, $pMemory
If($fSelected = True) Then $iSelected = $LVIS_SELECTED
If($fFocused = True And $iIndex <> -1) Then $iFocused = $LVIS_FOCUSED
DllStructSetData($tStruct, "Mask", $LVIF_STATE)
DllStructSetData($tStruct, "Item", $iIndex)
DllStructSetData($tStruct, "State", BitOR($iSelected, $iFocused))
DllStructSetData($tStruct, "StateMask", BitOR($LVIS_SELECTED, $iFocused))
$iSize = DllStructGetSize($tStruct)
If IsHWnd($hWnd) Then
$pMemory = _MemInit($hWnd, $iSize, $tMemMap)
_MemWrite($tMemMap, $tStruct, $pMemory, $iSize)
$iRet = _SendMessage($hWnd, $LVM_SETITEMSTATE, $iIndex, $pMemory)
_MemFree($tMemMap)
Else
$iRet = GUICtrlSendMsg($hWnd, $LVM_SETITEMSTATE, $iIndex, DllStructGetPtr($tStruct))
EndIf
Return $iRet <> 0
EndFunc
Func _GUICtrlListView_SetItemText($hWnd, $iIndex, $sText, $iSubItem = 0)
If $Debug_LV Then __UDF_ValidateClassName($hWnd, $__LISTVIEWCONSTANT_ClassName)
Local $fUnicode = _GUICtrlListView_GetUnicodeFormat($hWnd)
Local $iRet
If $iSubItem = -1 Then
Local $SeparatorChar = Opt('GUIDataSeparatorChar')
Local $i_cols = _GUICtrlListView_GetColumnCount($hWnd)
Local $a_text = StringSplit($sText, $SeparatorChar)
If $i_cols > $a_text[0] Then $i_cols = $a_text[0]
For $i = 1 To $i_cols
$iRet = _GUICtrlListView_SetItemText($hWnd, $iIndex, $a_text[$i], $i - 1)
If Not $iRet Then ExitLoop
Next
Return $iRet
EndIf
Local $iBuffer = StringLen($sText) + 1
Local $tBuffer
If $fUnicode Then
$tBuffer = DllStructCreate("wchar Text[" & $iBuffer & "]")
$iBuffer *= 2
Else
$tBuffer = DllStructCreate("char Text[" & $iBuffer & "]")
EndIf
Local $pBuffer = DllStructGetPtr($tBuffer)
Local $tItem = DllStructCreate($tagLVITEM)
DllStructSetData($tBuffer, "Text", $sText)
DllStructSetData($tItem, "Mask", $LVIF_TEXT)
DllStructSetData($tItem, "item", $iIndex)
DllStructSetData($tItem, "SubItem", $iSubItem)
If IsHWnd($hWnd) Then
If _WinAPI_InProcess($hWnd, $_lv_ghLastWnd) Then
DllStructSetData($tItem, "Text", $pBuffer)
$iRet = _SendMessage($hWnd, $LVM_SETITEMW, 0, $tItem, 0, "wparam", "struct*")
Else
Local $iItem = DllStructGetSize($tItem)
Local $tMemMap
Local $pMemory = _MemInit($hWnd, $iItem + $iBuffer, $tMemMap)
Local $pText = $pMemory + $iItem
DllStructSetData($tItem, "Text", $pText)
_MemWrite($tMemMap, $tItem, $pMemory, $iItem)
_MemWrite($tMemMap, $tBuffer, $pText, $iBuffer)
If $fUnicode Then
$iRet = _SendMessage($hWnd, $LVM_SETITEMW, 0, $pMemory, 0, "wparam", "ptr")
Else
$iRet = _SendMessage($hWnd, $LVM_SETITEMA, 0, $pMemory, 0, "wparam", "ptr")
EndIf
_MemFree($tMemMap)
EndIf
Else
Local $pItem = DllStructGetPtr($tItem)
DllStructSetData($tItem, "Text", $pBuffer)
If $fUnicode Then
$iRet = GUICtrlSendMsg($hWnd, $LVM_SETITEMW, 0, $pItem)
Else
$iRet = GUICtrlSendMsg($hWnd, $LVM_SETITEMA, 0, $pItem)
EndIf
EndIf
Return $iRet <> 0
EndFunc
Func _GUICtrlListView_SetUnicodeFormat($hWnd, $fUnicode)
If $Debug_LV Then __UDF_ValidateClassName($hWnd, $__LISTVIEWCONSTANT_ClassName)
If IsHWnd($hWnd) Then
Return _SendMessage($hWnd, $LVM_SETUNICODEFORMAT, $fUnicode)
Else
Return GUICtrlSendMsg($hWnd, $LVM_SETUNICODEFORMAT, $fUnicode, 0)
EndIf
EndFunc
Global Const $E_INVALIDARG = 0x80070057
Global Const $ILC_MASK = 0x00000001
Global Const $ILC_COLOR = 0x00000000
Global Const $ILC_COLORDDB = 0x000000FE
Global Const $ILC_COLOR4 = 0x00000004
Global Const $ILC_COLOR8 = 0x00000008
Global Const $ILC_COLOR16 = 0x00000010
Global Const $ILC_COLOR24 = 0x00000018
Global Const $ILC_COLOR32 = 0x00000020
Global Const $ILC_MIRROR = 0x00002000
Global Const $ILC_PERITEMMIRROR = 0x00008000
Global Const $__IMAGELISTCONSTANT_IMAGE_BITMAP = 0
Global Const $__IMAGELISTCONSTANT_LR_LOADFROMFILE = 0x0010
Func _GUIImageList_Add($hWnd, $hImage, $hMask = 0)
Local $aResult = DllCall("comctl32.dll", "int", "ImageList_Add", "handle", $hWnd, "handle", $hImage, "handle", $hMask)
If @error Then Return SetError(@error, @extended, -1)
Return $aResult[0]
EndFunc
Func _GUIImageList_AddBitmap($hWnd, $sImage, $sMask = "")
Local $aSize = _GUIImageList_GetIconSize($hWnd)
Local $hImage = _WinAPI_LoadImage(0, $sImage, $__IMAGELISTCONSTANT_IMAGE_BITMAP, $aSize[0], $aSize[1], $__IMAGELISTCONSTANT_LR_LOADFROMFILE)
If $hImage = 0 Then Return SetError(_WinAPI_GetLastError(), 1, -1)
Local $hMask = 0
If $sMask <> "" Then
$hMask = _WinAPI_LoadImage(0, $sMask, $__IMAGELISTCONSTANT_IMAGE_BITMAP, $aSize[0], $aSize[1], $__IMAGELISTCONSTANT_LR_LOADFROMFILE)
If $hMask = 0 Then Return SetError(_WinAPI_GetLastError(), 2, -1)
EndIf
Local $iRet = _GUIImageList_Add($hWnd, $hImage, $hMask)
_WinAPI_DeleteObject($hImage)
If $hMask <> 0 Then _WinAPI_DeleteObject($hMask)
Return $iRet
EndFunc
Func _GUIImageList_AddIcon($hWnd, $sFile, $iIndex = 0, $fLarge = False)
Local $iRet, $tIcon = DllStructCreate("handle Handle")
If $fLarge Then
$iRet = _WinAPI_ExtractIconEx($sFile, $iIndex, $tIcon, 0, 1)
Else
$iRet = _WinAPI_ExtractIconEx($sFile, $iIndex, 0, $tIcon, 1)
EndIf
If $iRet <= 0 Then Return SetError(-1, $iRet, -1)
Local $hIcon = DllStructGetData($tIcon, "Handle")
$iRet = _GUIImageList_ReplaceIcon($hWnd, -1, $hIcon)
_WinAPI_DestroyIcon($hIcon)
If $iRet = -1 Then Return SetError(-2, $iRet, -1)
Return $iRet
EndFunc
Func _GUIImageList_Create($iCX = 16, $iCY = 16, $iColor = 4, $iOptions = 0, $iInitial = 4, $iGrow = 4)
Local Const $aColor[7] = [$ILC_COLOR, $ILC_COLOR4, $ILC_COLOR8, $ILC_COLOR16, $ILC_COLOR24, $ILC_COLOR32, $ILC_COLORDDB]
Local $iFlags = 0
If BitAND($iOptions, 1) <> 0 Then $iFlags = BitOR($iFlags, $ILC_MASK)
If BitAND($iOptions, 2) <> 0 Then $iFlags = BitOR($iFlags, $ILC_MIRROR)
If BitAND($iOptions, 4) <> 0 Then $iFlags = BitOR($iFlags, $ILC_PERITEMMIRROR)
$iFlags = BitOR($iFlags, $aColor[$iColor])
Local $aResult = DllCall("comctl32.dll", "handle", "ImageList_Create", "int", $iCX, "int", $iCY, "uint", $iFlags, "int", $iInitial, "int", $iGrow)
If @error Then Return SetError(@error, @extended, 0)
Return $aResult[0]
EndFunc
Func _GUIImageList_GetIconSize($hWnd)
Local $aSize[2]
Local $tPoint = _GUIImageList_GetIconSizeEx($hWnd)
$aSize[0] = DllStructGetData($tPoint, "X")
$aSize[1] = DllStructGetData($tPoint, "Y")
Return $aSize
EndFunc
Func _GUIImageList_GetIconSizeEx($hWnd)
Local $tPoint = DllStructCreate($tagPOINT)
Local $pPointX = DllStructGetPtr($tPoint, "X")
Local $pPointY = DllStructGetPtr($tPoint, "Y")
Local $aResult = DllCall("comctl32.dll", "bool", "ImageList_GetIconSize", "hwnd", $hWnd, "struct*", $pPointX, "struct*", $pPointY)
If @error Then Return SetError(@error, @extended, 0)
Return SetExtended($aResult[0], $tPoint)
EndFunc
Func _GUIImageList_ReplaceIcon($hWnd, $iIndex, $hIcon)
Local $aResult = DllCall("comctl32.dll", "int", "ImageList_ReplaceIcon", "handle", $hWnd, "int", $iIndex, "handle", $hIcon)
If @error Then Return SetError(@error, @extended, -1)
Return $aResult[0]
EndFunc
Global Const $SBARS_TOOLTIPS = 0x800
Global Const $__STATUSBARCONSTANT_WM_USER = 0X400
Global Const $SB_GETBORDERS =($__STATUSBARCONSTANT_WM_USER + 7)
Global Const $SB_GETRECT =($__STATUSBARCONSTANT_WM_USER + 10)
Global Const $SB_GETTEXTA =($__STATUSBARCONSTANT_WM_USER + 2)
Global Const $SB_GETTEXTW =($__STATUSBARCONSTANT_WM_USER + 13)
Global Const $SB_GETTEXT = $SB_GETTEXTA
Global Const $SB_GETTEXTLENGTHA =($__STATUSBARCONSTANT_WM_USER + 3)
Global Const $SB_GETTEXTLENGTHW =($__STATUSBARCONSTANT_WM_USER + 12)
Global Const $SB_GETTEXTLENGTH = $SB_GETTEXTLENGTHA
Global Const $SB_GETUNICODEFORMAT = 0x2000 + 6
Global Const $SB_ISSIMPLE =($__STATUSBARCONSTANT_WM_USER + 14)
Global Const $SB_SETICON =($__STATUSBARCONSTANT_WM_USER + 15)
Global Const $SB_SETMINHEIGHT =($__STATUSBARCONSTANT_WM_USER + 8)
Global Const $SB_SETPARTS =($__STATUSBARCONSTANT_WM_USER + 4)
Global Const $SB_SETTEXTA =($__STATUSBARCONSTANT_WM_USER + 1)
Global Const $SB_SETTEXTW =($__STATUSBARCONSTANT_WM_USER + 11)
Global Const $SB_SETTEXT = $SB_SETTEXTA
Global Const $SB_SETTIPTEXTA =($__STATUSBARCONSTANT_WM_USER + 16)
Global Const $SB_SETTIPTEXTW =($__STATUSBARCONSTANT_WM_USER + 17)
Global Const $SB_SIMPLEID = 0xff
Global $__ghSBLastWnd
Global $Debug_SB = False
Global Const $__STATUSBARCONSTANT_ClassName = "msctls_statusbar32"
Global Const $__STATUSBARCONSTANT_WM_SIZE = 0x05
Global Const $tagBORDERS = "int BX;int BY;int RX"
Func _GUICtrlStatusBar_Create($hWnd, $vPartEdge = -1, $vPartText = "", $iStyles = -1, $iExStyles = -1)
If Not IsHWnd($hWnd) Then Return SetError(1, 0, 0)
Local $iStyle = BitOR($__UDFGUICONSTANT_WS_CHILD, $__UDFGUICONSTANT_WS_VISIBLE)
If $iStyles = -1 Then $iStyles = 0x00000000
If $iExStyles = -1 Then $iExStyles = 0x00000000
Local $aPartWidth[1], $aPartText[1]
If @NumParams > 1 Then
If IsArray($vPartEdge) Then
$aPartWidth = $vPartEdge
Else
$aPartWidth[0] = $vPartEdge
EndIf
If @NumParams = 2 Then
ReDim $aPartText[UBound($aPartWidth)]
Else
If IsArray($vPartText) Then
$aPartText = $vPartText
Else
$aPartText[0] = $vPartText
EndIf
If UBound($aPartWidth) <> UBound($aPartText) Then
Local $iLast
If UBound($aPartWidth) > UBound($aPartText) Then
$iLast = UBound($aPartText)
ReDim $aPartText[UBound($aPartWidth)]
For $x = $iLast To UBound($aPartText) - 1
$aPartWidth[$x] = ""
Next
Else
$iLast = UBound($aPartWidth)
ReDim $aPartWidth[UBound($aPartText)]
For $x = $iLast To UBound($aPartWidth) - 1
$aPartWidth[$x] = $aPartWidth[$x - 1] + 75
Next
$aPartWidth[UBound($aPartText) - 1] = -1
EndIf
EndIf
EndIf
If Not IsHWnd($hWnd) Then $hWnd = HWnd($hWnd)
If @NumParams > 3 Then $iStyle = BitOR($iStyle, $iStyles)
EndIf
Local $nCtrlID = __UDF_GetNextGlobalID($hWnd)
If @error Then Return SetError(@error, @extended, 0)
Local $hWndSBar = _WinAPI_CreateWindowEx($iExStyles, $__STATUSBARCONSTANT_ClassName, "", $iStyle, 0, 0, 0, 0, $hWnd, $nCtrlID)
If @error Then Return SetError(@error, @extended, 0)
If @NumParams > 1 Then
_GUICtrlStatusBar_SetParts($hWndSBar, UBound($aPartWidth), $aPartWidth)
For $x = 0 To UBound($aPartText) - 1
_GUICtrlStatusBar_SetText($hWndSBar, $aPartText[$x], $x)
Next
EndIf
Return $hWndSBar
EndFunc
Func _GUICtrlStatusBar_EmbedControl($hWnd, $iPart, $hControl, $iFit = 4)
Local $aRect = _GUICtrlStatusBar_GetRect($hWnd, $iPart)
Local $iBarX = $aRect[0]
Local $iBarY = $aRect[1]
Local $iBarW = $aRect[2] - $iBarX
Local $iBarH = $aRect[3] - $iBarY
Local $iConX = $iBarX
Local $iConY = $iBarY
Local $iConW = _WinAPI_GetWindowWidth($hControl)
Local $iConH = _WinAPI_GetWindowHeight($hControl)
If $iConW > $iBarW Then $iConW = $iBarW
If $iConH > $iBarH Then $iConH = $iBarH
Local $iPadX =($iBarW - $iConW) / 2
Local $iPadY =($iBarH - $iConH) / 2
If $iPadX < 0 Then $iPadX = 0
If $iPadY < 0 Then $iPadY = 0
If BitAND($iFit, 1) = 1 Then $iConX = $iBarX + $iPadX
If BitAND($iFit, 2) = 2 Then $iConY = $iBarY + $iPadY
If BitAND($iFit, 4) = 4 Then
$iPadX = _GUICtrlStatusBar_GetBordersRect($hWnd)
$iPadY = _GUICtrlStatusBar_GetBordersVert($hWnd)
$iConX = $iBarX
If _GUICtrlStatusBar_IsSimple($hWnd) Then $iConX += $iPadX
$iConY = $iBarY + $iPadY
$iConW = $iBarW -($iPadX * 2)
$iConH = $iBarH -($iPadY * 2)
EndIf
_WinAPI_SetParent($hControl, $hWnd)
_WinAPI_MoveWindow($hControl, $iConX, $iConY, $iConW, $iConH)
EndFunc
Func _GUICtrlStatusBar_GetBorders($hWnd)
If $Debug_SB Then __UDF_ValidateClassName($hWnd, $__STATUSBARCONSTANT_ClassName)
Local $tBorders = DllStructCreate($tagBORDERS)
Local $iRet
If _WinAPI_InProcess($hWnd, $__ghSBLastWnd) Then
$iRet = _SendMessage($hWnd, $SB_GETBORDERS, 0, $tBorders, 0, "wparam", "struct*")
Else
Local $iSize = DllStructGetSize($tBorders)
Local $tMemMap
Local $pMemory = _MemInit($hWnd, $iSize, $tMemMap)
$iRet = _SendMessage($hWnd, $SB_GETBORDERS, 0, $pMemory, 0, "wparam", "ptr")
_MemRead($tMemMap, $pMemory, $tBorders, $iSize)
_MemFree($tMemMap)
EndIf
Local $aBorders[3]
If $iRet = 0 Then Return SetError(-1, -1, $aBorders)
$aBorders[0] = DllStructGetData($tBorders, "BX")
$aBorders[1] = DllStructGetData($tBorders, "BY")
$aBorders[2] = DllStructGetData($tBorders, "RX")
Return $aBorders
EndFunc
Func _GUICtrlStatusBar_GetBordersRect($hWnd)
Local $aBorders = _GUICtrlStatusBar_GetBorders($hWnd)
Return SetError(@error, @extended, $aBorders[2])
EndFunc
Func _GUICtrlStatusBar_GetBordersVert($hWnd)
Local $aBorders = _GUICtrlStatusBar_GetBorders($hWnd)
Return SetError(@error, @extended, $aBorders[1])
EndFunc
Func _GUICtrlStatusBar_GetRect($hWnd, $iPart)
Local $tRect = _GUICtrlStatusBar_GetRectEx($hWnd, $iPart)
If @error Then Return SetError(@error, 0, 0)
Local $aRect[4]
$aRect[0] = DllStructGetData($tRect, "Left")
$aRect[1] = DllStructGetData($tRect, "Top")
$aRect[2] = DllStructGetData($tRect, "Right")
$aRect[3] = DllStructGetData($tRect, "Bottom")
Return $aRect
EndFunc
Func _GUICtrlStatusBar_GetRectEx($hWnd, $iPart)
If $Debug_SB Then __UDF_ValidateClassName($hWnd, $__STATUSBARCONSTANT_ClassName)
Local $tRect = DllStructCreate($tagRECT)
Local $iRet
If _WinAPI_InProcess($hWnd, $__ghSBLastWnd) Then
$iRet = _SendMessage($hWnd, $SB_GETRECT, $iPart, $tRect, 0, "wparam", "struct*")
Else
Local $iRect = DllStructGetSize($tRect)
Local $tMemMap
Local $pMemory = _MemInit($hWnd, $iRect, $tMemMap)
$iRet = _SendMessage($hWnd, $SB_GETRECT, $iPart, $pMemory, 0, "wparam", "ptr")
_MemRead($tMemMap, $pMemory, $tRect, $iRect)
_MemFree($tMemMap)
EndIf
Return SetError($iRet = 0, 0, $tRect)
EndFunc
Func _GUICtrlStatusBar_GetText($hWnd, $iPart)
If $Debug_SB Then __UDF_ValidateClassName($hWnd, $__STATUSBARCONSTANT_ClassName)
Local $fUnicode = _GUICtrlStatusBar_GetUnicodeFormat($hWnd)
Local $iBuffer = _GUICtrlStatusBar_GetTextLength($hWnd, $iPart)
If $iBuffer = 0 Then Return SetError(1, 0, "")
Local $tBuffer
If $fUnicode Then
$tBuffer = DllStructCreate("wchar Text[" & $iBuffer & "]")
$iBuffer *= 2
Else
$tBuffer = DllStructCreate("char Text[" & $iBuffer & "]")
EndIf
If _WinAPI_InProcess($hWnd, $__ghSBLastWnd) Then
_SendMessage($hWnd, $SB_GETTEXTW, $iPart, $tBuffer, 0, "wparam", "struct*")
Else
Local $tMemMap
Local $pMemory = _MemInit($hWnd, $iBuffer, $tMemMap)
If $fUnicode Then
_SendMessage($hWnd, $SB_GETTEXTW, $iPart, $pMemory, 0, "wparam", "ptr")
Else
_SendMessage($hWnd, $SB_GETTEXT, $iPart, $pMemory, 0, "wparam", "ptr")
EndIf
_MemRead($tMemMap, $pMemory, $tBuffer, $iBuffer)
_MemFree($tMemMap)
EndIf
Return DllStructGetData($tBuffer, "Text")
EndFunc
Func _GUICtrlStatusBar_GetTextFlags($hWnd, $iPart)
If $Debug_SB Then __UDF_ValidateClassName($hWnd, $__STATUSBARCONSTANT_ClassName)
If _GUICtrlStatusBar_GetUnicodeFormat($hWnd) Then
Return _SendMessage($hWnd, $SB_GETTEXTLENGTHW, $iPart)
Else
Return _SendMessage($hWnd, $SB_GETTEXTLENGTH, $iPart)
EndIf
EndFunc
Func _GUICtrlStatusBar_GetTextLength($hWnd, $iPart)
Return _WinAPI_LoWord(_GUICtrlStatusBar_GetTextFlags($hWnd, $iPart))
EndFunc
Func _GUICtrlStatusBar_GetUnicodeFormat($hWnd)
If $Debug_SB Then __UDF_ValidateClassName($hWnd, $__STATUSBARCONSTANT_ClassName)
Return _SendMessage($hWnd, $SB_GETUNICODEFORMAT) <> 0
EndFunc
Func _GUICtrlStatusBar_IsSimple($hWnd)
If $Debug_SB Then __UDF_ValidateClassName($hWnd, $__STATUSBARCONSTANT_ClassName)
Return _SendMessage($hWnd, $SB_ISSIMPLE) <> 0
EndFunc
Func _GUICtrlStatusBar_Resize($hWnd)
If $Debug_SB Then __UDF_ValidateClassName($hWnd, $__STATUSBARCONSTANT_ClassName)
_SendMessage($hWnd, $__STATUSBARCONSTANT_WM_SIZE)
EndFunc
Func _GUICtrlStatusBar_SetIcon($hWnd, $iPart, $hIcon = -1, $sIconFile = "")
If $Debug_SB Then __UDF_ValidateClassName($hWnd, $__STATUSBARCONSTANT_ClassName)
If $hIcon = -1 Then Return _SendMessage($hWnd, $SB_SETICON, $iPart, $hIcon, 0, "wparam", "handle") <> 0
If StringLen($sIconFile) <= 0 Then Return _SendMessage($hWnd, $SB_SETICON, $iPart, $hIcon) <> 0
Local $tIcon = DllStructCreate("handle")
Local $vResult = DllCall("shell32.dll", "uint", "ExtractIconExW", "wstr", $sIconFile, "int", $hIcon, "ptr", 0, "struct*", $tIcon, "uint", 1)
If @error Then Return SetError(@error, @extended, False)
$vResult = $vResult[0]
If $vResult > 0 Then $vResult = _SendMessage($hWnd, $SB_SETICON, $iPart, DllStructGetData($tIcon, 1), 0, "wparam", "handle")
DllCall("user32.dll", "bool", "DestroyIcon", "handle", DllStructGetData($tIcon, 1))
Return $vResult
EndFunc
Func _GUICtrlStatusBar_SetMinHeight($hWnd, $iMinHeight)
If $Debug_SB Then __UDF_ValidateClassName($hWnd, $__STATUSBARCONSTANT_ClassName)
_SendMessage($hWnd, $SB_SETMINHEIGHT, $iMinHeight)
_GUICtrlStatusBar_Resize($hWnd)
EndFunc
Func _GUICtrlStatusBar_SetParts($hWnd, $iaParts = -1, $iaPartWidth = 25)
If $Debug_SB Then __UDF_ValidateClassName($hWnd, $__STATUSBARCONSTANT_ClassName)
Local $tParts, $iParts = 1
If IsArray($iaParts) <> 0 Then
$iaParts[UBound($iaParts) - 1] = -1
$iParts = UBound($iaParts)
$tParts = DllStructCreate("int[" & $iParts & "]")
For $x = 0 To $iParts - 2
DllStructSetData($tParts, 1, $iaParts[$x], $x + 1)
Next
DllStructSetData($tParts, 1, -1, $iParts)
ElseIf IsArray($iaPartWidth) <> 0 Then
$iParts = UBound($iaPartWidth)
$tParts = DllStructCreate("int[" & $iParts & "]")
For $x = 0 To $iParts - 2
DllStructSetData($tParts, 1, $iaPartWidth[$x], $x + 1)
Next
DllStructSetData($tParts, 1, -1, $iParts)
ElseIf $iaParts > 1 Then
$iParts = $iaParts
$tParts = DllStructCreate("int[" & $iParts & "]")
For $x = 1 To $iParts - 1
DllStructSetData($tParts, 1, $iaPartWidth * $x, $x)
Next
DllStructSetData($tParts, 1, -1, $iParts)
Else
$tParts = DllStructCreate("int")
DllStructSetData($tParts, $iParts, -1)
EndIf
If _WinAPI_InProcess($hWnd, $__ghSBLastWnd) Then
_SendMessage($hWnd, $SB_SETPARTS, $iParts, $tParts, 0, "wparam", "struct*")
Else
Local $iSize = DllStructGetSize($tParts)
Local $tMemMap
Local $pMemory = _MemInit($hWnd, $iSize, $tMemMap)
_MemWrite($tMemMap, $tParts)
_SendMessage($hWnd, $SB_SETPARTS, $iParts, $pMemory, 0, "wparam", "ptr")
_MemFree($tMemMap)
EndIf
_GUICtrlStatusBar_Resize($hWnd)
Return True
EndFunc
Func _GUICtrlStatusBar_SetText($hWnd, $sText = "", $iPart = 0, $iUFlag = 0)
If $Debug_SB Then __UDF_ValidateClassName($hWnd, $__STATUSBARCONSTANT_ClassName)
Local $fUnicode = _GUICtrlStatusBar_GetUnicodeFormat($hWnd)
Local $iBuffer = StringLen($sText) + 1
Local $tText
If $fUnicode Then
$tText = DllStructCreate("wchar Text[" & $iBuffer & "]")
$iBuffer *= 2
Else
$tText = DllStructCreate("char Text[" & $iBuffer & "]")
EndIf
DllStructSetData($tText, "Text", $sText)
If _GUICtrlStatusBar_IsSimple($hWnd) Then $iPart = $SB_SIMPLEID
Local $iRet
If _WinAPI_InProcess($hWnd, $__ghSBLastWnd) Then
$iRet = _SendMessage($hWnd, $SB_SETTEXTW, BitOR($iPart, $iUFlag), $tText, 0, "wparam", "struct*")
Else
Local $tMemMap
Local $pMemory = _MemInit($hWnd, $iBuffer, $tMemMap)
_MemWrite($tMemMap, $tText)
If $fUnicode Then
$iRet = _SendMessage($hWnd, $SB_SETTEXTW, BitOR($iPart, $iUFlag), $pMemory, 0, "wparam", "ptr")
Else
$iRet = _SendMessage($hWnd, $SB_SETTEXT, BitOR($iPart, $iUFlag), $pMemory, 0, "wparam", "ptr")
EndIf
_MemFree($tMemMap)
EndIf
Return $iRet <> 0
EndFunc
Func _GUICtrlStatusBar_SetTipText($hWnd, $iPart, $sText)
If $Debug_SB Then __UDF_ValidateClassName($hWnd, $__STATUSBARCONSTANT_ClassName)
Local $fUnicode = _GUICtrlStatusBar_GetUnicodeFormat($hWnd)
Local $iBuffer = StringLen($sText) + 1
Local $tText
If $fUnicode Then
$tText = DllStructCreate("wchar TipText[" & $iBuffer & "]")
$iBuffer *= 2
Else
$tText = DllStructCreate("char TipText[" & $iBuffer & "]")
EndIf
DllStructSetData($tText, "TipText", $sText)
If _WinAPI_InProcess($hWnd, $__ghSBLastWnd) Then
_SendMessage($hWnd, $SB_SETTIPTEXTW, $iPart, $tText, 0, "wparam", "struct*")
Else
Local $tMemMap
Local $pMemory = _MemInit($hWnd, $iBuffer, $tMemMap)
_MemWrite($tMemMap, $tText, $pMemory, $iBuffer)
If $fUnicode Then
_SendMessage($hWnd, $SB_SETTIPTEXTW, $iPart, $pMemory, 0, "wparam", "ptr")
Else
_SendMessage($hWnd, $SB_SETTIPTEXTA, $iPart, $pMemory, 0, "wparam", "ptr")
EndIf
_MemFree($tMemMap)
EndIf
EndFunc
Global $_ghEditLastWnd
Global $Debug_Ed = False
Global Const $__EDITCONSTANT_ClassName = "Edit"
Global Const $__EDITCONSTANT_WS_TABSTOP = 0x00010000
Global Const $__EDITCONSTANT_DEFAULT_GUI_FONT = 17
Global Const $__EDITCONSTANT_WM_SETFONT = 0x0030
Global Const $__EDITCONSTANT_WM_SETTEXT = 0x000C
Func _GUICtrlEdit_Create($hWnd, $sText, $iX, $iY, $iWidth = 150, $iHeight = 150, $iStyle = 0x003010C4, $iExStyle = 0x00000200)
If Not IsHWnd($hWnd) Then Return SetError(1, 0, 0)
If Not IsString($sText) Then Return SetError(2, 0, 0)
If $iWidth = -1 Then $iWidth = 150
If $iHeight = -1 Then $iHeight = 150
If $iStyle = -1 Then $iStyle = 0x003010C4
If $iExStyle = -1 Then $iExStyle = 0x00000200
If BitAND($iStyle, $ES_READONLY) = $ES_READONLY Then
$iStyle = BitOR($__UDFGUICONSTANT_WS_CHILD, $__UDFGUICONSTANT_WS_VISIBLE, $iStyle)
Else
$iStyle = BitOR($__UDFGUICONSTANT_WS_CHILD, $__UDFGUICONSTANT_WS_VISIBLE, $__EDITCONSTANT_WS_TABSTOP, $iStyle)
EndIf
Local $nCtrlID = __UDF_GetNextGlobalID($hWnd)
If @error Then Return SetError(@error, @extended, 0)
Local $hEdit = _WinAPI_CreateWindowEx($iExStyle, $__EDITCONSTANT_ClassName, "", $iStyle, $iX, $iY, $iWidth, $iHeight, $hWnd, $nCtrlID)
_SendMessage($hEdit, $__EDITCONSTANT_WM_SETFONT, _WinAPI_GetStockObject($__EDITCONSTANT_DEFAULT_GUI_FONT), True)
_GUICtrlEdit_SetText($hEdit, $sText)
_GUICtrlEdit_SetLimitText($hEdit, 0)
Return $hEdit
EndFunc
Func _GUICtrlEdit_Destroy(ByRef $hWnd)
If $Debug_Ed Then __UDF_ValidateClassName($hWnd, $__EDITCONSTANT_ClassName)
If Not _WinAPI_IsClassName($hWnd, $__EDITCONSTANT_ClassName) Then Return SetError(2, 2, False)
Local $Destroyed = 0
If IsHWnd($hWnd) Then
If _WinAPI_InProcess($hWnd, $_ghEditLastWnd) Then
Local $nCtrlID = _WinAPI_GetDlgCtrlID($hWnd)
Local $hParent = _WinAPI_GetParent($hWnd)
$Destroyed = _WinAPI_DestroyWindow($hWnd)
Local $iRet = __UDF_FreeGlobalID($hParent, $nCtrlID)
If Not $iRet Then
EndIf
Else
Return SetError(1, 1, False)
EndIf
Else
$Destroyed = GUICtrlDelete($hWnd)
EndIf
If $Destroyed Then $hWnd = 0
Return $Destroyed <> 0
EndFunc
Func _GUICtrlEdit_SetLimitText($hWnd, $iLimit)
If $Debug_Ed Then __UDF_ValidateClassName($hWnd, $__EDITCONSTANT_ClassName)
If Not IsHWnd($hWnd) Then $hWnd = GUICtrlGetHandle($hWnd)
_SendMessage($hWnd, $EM_SETLIMITTEXT, $iLimit)
EndFunc
Func _GUICtrlEdit_SetSel($hWnd, $iStart, $iEnd)
If $Debug_Ed Then __UDF_ValidateClassName($hWnd, $__EDITCONSTANT_ClassName)
If Not IsHWnd($hWnd) Then $hWnd = GUICtrlGetHandle($hWnd)
_SendMessage($hWnd, $EM_SETSEL, $iStart, $iEnd)
EndFunc
Func _GUICtrlEdit_SetText($hWnd, $sText)
If $Debug_Ed Then __UDF_ValidateClassName($hWnd, $__EDITCONSTANT_ClassName)
If Not IsHWnd($hWnd) Then $hWnd = GUICtrlGetHandle($hWnd)
_SendMessage($hWnd, $__EDITCONSTANT_WM_SETTEXT, 0, $sText, 0, "wparam", "wstr")
EndFunc
Global Const $TBIF_TEXT = 0x00000002
Global Const $__TOOLBARCONSTANTS_WM_USER = 0X400
Global Const $TB_ENABLEBUTTON = $__TOOLBARCONSTANTS_WM_USER + 1
Global Const $TB_GETSTATE = $__TOOLBARCONSTANTS_WM_USER + 18
Global Const $TB_ADDBUTTONSA = $__TOOLBARCONSTANTS_WM_USER + 20
Global Const $TB_ADDSTRINGA = $__TOOLBARCONSTANTS_WM_USER + 28
Global Const $TB_ADDSTRINGW = $__TOOLBARCONSTANTS_WM_USER + 77
Global Const $TB_BUTTONSTRUCTSIZE = $__TOOLBARCONSTANTS_WM_USER + 30
Global Const $TB_AUTOSIZE = $__TOOLBARCONSTANTS_WM_USER + 33
Global Const $TB_SETIMAGELIST = $__TOOLBARCONSTANTS_WM_USER + 48
Global Const $TB_GETRECT = $__TOOLBARCONSTANTS_WM_USER + 51
Global Const $TB_SETBUTTONINFOW = $__TOOLBARCONSTANTS_WM_USER + 64
Global Const $TB_ADDBUTTONSW = $__TOOLBARCONSTANTS_WM_USER + 68
Global Const $TB_SETEXTENDEDSTYLE = $__TOOLBARCONSTANTS_WM_USER + 84
Global Const $TB_SETUNICODEFORMAT = 0x2000 + 5
Global Const $TB_GETUNICODEFORMAT = 0x2000 + 6
Global Const $TBN_FIRST = -700
Global Const $TBN_DROPDOWN = $TBN_FIRST - 10
Global Const $TBN_HOTITEMCHANGE = $TBN_FIRST - 13
Global Const $BTNS_DROPDOWN = 0x00000008
Global Const $TBSTYLE_EX_DRAWDDARROWS = 0x00000001
Global $gh_TBLastWnd
Global $Debug_TB = False
Global Const $__TOOLBARCONSTANT_ClassName = "ToolbarWindow32"
Global Const $__TOOLBARCONSTANT_WS_CLIPSIBLINGS = 0x04000000
Func _GUICtrlToolbar_AddButton($hWnd, $iID, $iImage, $iString = 0, $iStyle = 0, $iState = 4, $iParam = 0)
If $Debug_TB Then __UDF_ValidateClassName($hWnd, $__TOOLBARCONSTANT_ClassName)
Local $fUnicode = _GUICtrlToolbar_GetUnicodeFormat($hWnd)
Local $tButton = DllStructCreate($tagTBBUTTON)
DllStructSetData($tButton, "Bitmap", $iImage)
DllStructSetData($tButton, "Command", $iID)
DllStructSetData($tButton, "State", $iState)
DllStructSetData($tButton, "Style", $iStyle)
DllStructSetData($tButton, "Param", $iParam)
DllStructSetData($tButton, "String", $iString)
Local $iRet
If _WinAPI_InProcess($hWnd, $gh_TBLastWnd) Then
$iRet = _SendMessage($hWnd, $TB_ADDBUTTONSW, 1, $tButton, 0, "wparam", "struct*")
Else
Local $iButton = DllStructGetSize($tButton)
Local $tMemMap
Local $pMemory = _MemInit($hWnd, $iButton, $tMemMap)
_MemWrite($tMemMap, $tButton, $pMemory, $iButton)
If $fUnicode Then
$iRet = _SendMessage($hWnd, $TB_ADDBUTTONSW, 1, $pMemory, 0, "wparam", "ptr")
Else
$iRet = _SendMessage($hWnd, $TB_ADDBUTTONSA, 1, $pMemory, 0, "wparam", "ptr")
EndIf
_MemFree($tMemMap)
EndIf
__GUICtrlToolbar_AutoSize($hWnd)
Return $iRet <> 0
EndFunc
Func _GUICtrlToolbar_AddString($hWnd, $sString)
If $Debug_TB Then __UDF_ValidateClassName($hWnd, $__TOOLBARCONSTANT_ClassName)
Local $fUnicode = _GUICtrlToolbar_GetUnicodeFormat($hWnd)
Local $iBuffer = StringLen($sString) + 2
Local $tBuffer
If $fUnicode Then
$tBuffer = DllStructCreate("wchar Text[" & $iBuffer & "]")
$iBuffer *= 2
Else
$tBuffer = DllStructCreate("char Text[" & $iBuffer & "]")
EndIf
DllStructSetData($tBuffer, "Text", $sString)
Local $iRet
If _WinAPI_InProcess($hWnd, $gh_TBLastWnd) Then
$iRet = _SendMessage($hWnd, $TB_ADDSTRINGW, 0, $tBuffer, 0, "wparam", "struct*")
Else
Local $tMemMap
Local $pMemory = _MemInit($hWnd, $iBuffer, $tMemMap)
_MemWrite($tMemMap, $tBuffer, $pMemory, $iBuffer)
If $fUnicode Then
$iRet = _SendMessage($hWnd, $TB_ADDSTRINGW, 0, $pMemory, 0, "wparam", "ptr")
Else
$iRet = _SendMessage($hWnd, $TB_ADDSTRINGA, 0, $pMemory, 0, "wparam", "ptr")
EndIf
_MemFree($tMemMap)
EndIf
Return $iRet
EndFunc
Func __GUICtrlToolbar_AutoSize($hWnd)
_SendMessage($hWnd, $TB_AUTOSIZE)
EndFunc
Func __GUICtrlToolbar_ButtonStructSize($hWnd)
If $Debug_TB Then __UDF_ValidateClassName($hWnd, $__TOOLBARCONSTANT_ClassName)
Local $tButton = DllStructCreate($tagTBBUTTON)
_SendMessage($hWnd, $TB_BUTTONSTRUCTSIZE, DllStructGetSize($tButton), 0, 0, "wparam", "ptr")
EndFunc
Func _GUICtrlToolbar_Create($hWnd, $iStyle = 0x00000800, $iExStyle = 0x00000000)
$iStyle = BitOR($iStyle, $__UDFGUICONSTANT_WS_CHILD, $__TOOLBARCONSTANT_WS_CLIPSIBLINGS, $__UDFGUICONSTANT_WS_VISIBLE)
Local $nCtrlID = __UDF_GetNextGlobalID($hWnd)
If @error Then Return SetError(@error, @extended, 0)
Local $hTool = _WinAPI_CreateWindowEx($iExStyle, $__TOOLBARCONSTANT_ClassName, "", $iStyle, 0, 0, 0, 0, $hWnd, $nCtrlID)
__GUICtrlToolbar_ButtonStructSize($hTool)
Return $hTool
EndFunc
Func _GUICtrlToolbar_EnableButton($hWnd, $iCommandID, $fEnable = True)
If $Debug_TB Then __UDF_ValidateClassName($hWnd, $__TOOLBARCONSTANT_ClassName)
Return _SendMessage($hWnd, $TB_ENABLEBUTTON, $iCommandID, $fEnable) <> 0
EndFunc
Func _GUICtrlToolbar_GetButtonRect($hWnd, $iCommandID)
Local $aRect[4]
Local $tRect = _GUICtrlToolbar_GetButtonRectEx($hWnd, $iCommandID)
$aRect[0] = DllStructGetData($tRect, "Left")
$aRect[1] = DllStructGetData($tRect, "Top")
$aRect[2] = DllStructGetData($tRect, "Right")
$aRect[3] = DllStructGetData($tRect, "Bottom")
Return $aRect
EndFunc
Func _GUICtrlToolbar_GetButtonRectEx($hWnd, $iCommandID)
If $Debug_TB Then __UDF_ValidateClassName($hWnd, $__TOOLBARCONSTANT_ClassName)
Local $tRect = DllStructCreate($tagRECT)
If _WinAPI_InProcess($hWnd, $gh_TBLastWnd) Then
_SendMessage($hWnd, $TB_GETRECT, $iCommandID, $tRect, 0, "wparam", "struct*")
Else
Local $iRect = DllStructGetSize($tRect)
Local $tMemMap
Local $pMemory = _MemInit($hWnd, $iRect, $tMemMap)
_SendMessage($hWnd, $TB_GETRECT, $iCommandID, $pMemory, 0, "wparam", "ptr")
_MemRead($tMemMap, $pMemory, $tRect, $iRect)
_MemFree($tMemMap)
EndIf
Return $tRect
EndFunc
Func _GUICtrlToolbar_GetButtonState($hWnd, $iCommandID)
If $Debug_TB Then __UDF_ValidateClassName($hWnd, $__TOOLBARCONSTANT_ClassName)
Return _SendMessage($hWnd, $TB_GETSTATE, $iCommandID)
EndFunc
Func _GUICtrlToolbar_GetUnicodeFormat($hWnd)
If $Debug_TB Then __UDF_ValidateClassName($hWnd, $__TOOLBARCONSTANT_ClassName)
Return _SendMessage($hWnd, $TB_GETUNICODEFORMAT) <> 0
EndFunc
Func _GUICtrlToolbar_SetButtonInfoEx($hWnd, $iCommandID, $tButton)
If $Debug_TB Then __UDF_ValidateClassName($hWnd, $__TOOLBARCONSTANT_ClassName)
Local $iButton = DllStructGetSize($tButton)
DllStructSetData($tButton, "Size", $iButton)
Local $iRet
If _WinAPI_InProcess($hWnd, $gh_TBLastWnd) Then
$iRet = _SendMessage($hWnd, $TB_SETBUTTONINFOW, $iCommandID, $tButton, 0, "wparam", "struct*")
Else
Local $iBuffer = DllStructGetData($tButton, "TextMax")
Local $tMemMap
Local $pMemory = _MemInit($hWnd, $iButton + $iBuffer, $tMemMap)
Local $pBuffer = $pMemory + $iButton
DllStructSetData($tButton, "Text", $pBuffer)
_MemWrite($tMemMap, $tButton, $pMemory, $iButton)
_MemWrite($tMemMap, $pBuffer, $pBuffer, $iBuffer)
$iRet = _SendMessage($hWnd, $TB_SETBUTTONINFOW, $iCommandID, $pMemory, 0, "wparam", "ptr")
_MemFree($tMemMap)
EndIf
Return $iRet <> 0
EndFunc
Func _GUICtrlToolbar_SetButtonText($hWnd, $iCommandID, $sText)
Local $iBuffer = StringLen($sText) + 1
Local $tBuffer = DllStructCreate("wchar Text[" & $iBuffer * 2 & "]")
$iBuffer *= 2
Local $pBuffer = DllStructGetPtr($tBuffer)
Local $tButton = DllStructCreate($tagTBBUTTONINFO)
DllStructSetData($tBuffer, "Text", $sText)
DllStructSetData($tButton, "Mask", $TBIF_TEXT)
DllStructSetData($tButton, "Text", $pBuffer)
DllStructSetData($tButton, "TextMax", $iBuffer)
Return _GUICtrlToolbar_SetButtonInfoEx($hWnd, $iCommandID, $tButton)
EndFunc
Func _GUICtrlToolbar_SetExtendedStyle($hWnd, $iStyle)
If $Debug_TB Then __UDF_ValidateClassName($hWnd, $__TOOLBARCONSTANT_ClassName)
Return _SendMessage($hWnd, $TB_SETEXTENDEDSTYLE, 0, $iStyle)
EndFunc
Func _GUICtrlToolbar_SetImageList($hWnd, $hImageList)
If $Debug_TB Then __UDF_ValidateClassName($hWnd, $__TOOLBARCONSTANT_ClassName)
Return _SendMessage($hWnd, $TB_SETIMAGELIST, 0, $hImageList, 0, "wparam", "handle", "handle")
EndFunc
Func _GUICtrlToolbar_SetUnicodeFormat($hWnd, $fUnicode = False)
If $Debug_TB Then __UDF_ValidateClassName($hWnd, $__TOOLBARCONSTANT_ClassName)
Return _SendMessage($hWnd, $TB_SETUNICODEFORMAT, $fUnicode)
EndFunc
Global $Debug_CB = False
Global Const $__COMBOBOXCONSTANT_ClassName = "ComboBox"
Func _GUICtrlComboBox_GetCurSel($hWnd)
If $Debug_CB Then __UDF_ValidateClassName($hWnd, $__COMBOBOXCONSTANT_ClassName)
If Not IsHWnd($hWnd) Then $hWnd = GUICtrlGetHandle($hWnd)
Return _SendMessage($hWnd, $CB_GETCURSEL)
EndFunc
Func _GUICtrlComboBox_GetLBText($hWnd, $iIndex, ByRef $sText)
If $Debug_CB Then __UDF_ValidateClassName($hWnd, $__COMBOBOXCONSTANT_ClassName)
If Not IsHWnd($hWnd) Then $hWnd = GUICtrlGetHandle($hWnd)
Local $iLen = _GUICtrlComboBox_GetLBTextLen($hWnd, $iIndex)
Local $tBuffer = DllStructCreate("wchar Text[" & $iLen + 1 & "]")
Local $iRet = _SendMessage($hWnd, $CB_GETLBTEXT, $iIndex, $tBuffer, 0, "wparam", "struct*")
If($iRet == $CB_ERR) Then Return SetError($CB_ERR, $CB_ERR, $CB_ERR)
$sText = DllStructGetData($tBuffer, "Text")
Return $iRet
EndFunc
Func _GUICtrlComboBox_GetLBTextLen($hWnd, $iIndex)
If $Debug_CB Then __UDF_ValidateClassName($hWnd, $__COMBOBOXCONSTANT_ClassName)
If Not IsHWnd($hWnd) Then $hWnd = GUICtrlGetHandle($hWnd)
Return _SendMessage($hWnd, $CB_GETLBTEXTLEN, $iIndex)
EndFunc
Global $Debug_Btn = False
Global Const $tagBUTTON_IMAGELIST = "ptr ImageList;" & $tagRECT & ";uint Align"
Global Const $__BUTTONCONSTANT_ClassName = "Button"
Func _GUICtrlButton_Enable($hWnd, $fEnable = True)
If $Debug_Btn Then __UDF_ValidateClassName($hWnd, $__BUTTONCONSTANT_ClassName)
If Not IsHWnd($hWnd) Then $hWnd = GUICtrlGetHandle($hWnd)
If _WinAPI_IsClassName($hWnd, $__BUTTONCONSTANT_ClassName) Then Return _WinAPI_EnableWindow($hWnd, $fEnable) = $fEnable
EndFunc
Func _GUICtrlButton_SetImageList($hWnd, $hImage, $nAlign = 0, $iLeft = 1, $iTop = 1, $iRight = 1, $iBottom = 1)
If $Debug_Btn Then __UDF_ValidateClassName($hWnd, $__BUTTONCONSTANT_ClassName)
If Not IsHWnd($hWnd) Then $hWnd = GUICtrlGetHandle($hWnd)
If $nAlign < 0 Or $nAlign > 4 Then $nAlign = 0
Local $tBUTTON_IMAGELIST = DllStructCreate($tagBUTTON_IMAGELIST)
DllStructSetData($tBUTTON_IMAGELIST, "ImageList", $hImage)
DllStructSetData($tBUTTON_IMAGELIST, "Left", $iLeft)
DllStructSetData($tBUTTON_IMAGELIST, "Top", $iTop)
DllStructSetData($tBUTTON_IMAGELIST, "Right", $iRight)
DllStructSetData($tBUTTON_IMAGELIST, "Bottom", $iBottom)
DllStructSetData($tBUTTON_IMAGELIST, "Align", $nAlign)
Local $fEnabled = _GUICtrlButton_Enable($hWnd, False)
Local $iRet = _SendMessage($hWnd, $BCM_SETIMAGELIST, 0, $tBUTTON_IMAGELIST, 0, "wparam", "struct*") <> 0
_GUICtrlButton_Enable($hWnd)
If Not $fEnabled Then _GUICtrlButton_Enable($hWnd, False)
Return $iRet
EndFunc
Func _GUICtrlButton_SetShield($hWnd, $fRequired = True)
If $Debug_Btn Then __UDF_ValidateClassName($hWnd, $__BUTTONCONSTANT_ClassName)
If Not IsHWnd($hWnd) Then $hWnd = GUICtrlGetHandle($hWnd)
Return _SendMessage($hWnd, $BCM_SETSHIELD, 0, $fRequired) = 1
EndFunc
Func _GUICtrlMenu_AddMenuItem($hMenu, $sText, $iCmdID = 0, $hSubMenu = 0)
Local $iIndex = _GUICtrlMenu_GetItemCount($hMenu)
Local $tMenu = DllStructCreate($tagMENUITEMINFO)
DllStructSetData($tMenu, "Size", DllStructGetSize($tMenu))
DllStructSetData($tMenu, "Mask", BitOR($MIIM_ID, $MIIM_STRING, $MIIM_SUBMENU))
DllStructSetData($tMenu, "ID", $iCmdID)
DllStructSetData($tMenu, "SubMenu", $hSubMenu)
If $sText = "" Then
DllStructSetData($tMenu, "Mask", $MIIM_FTYPE)
DllStructSetData($tMenu, "Type", $MFT_SEPARATOR)
Else
DllStructSetData($tMenu, "Mask", BitOR($MIIM_ID, $MIIM_STRING, $MIIM_SUBMENU))
Local $tText = DllStructCreate("wchar Text[" & StringLen($sText) + 1 & "]")
DllStructSetData($tText, "Text", $sText)
DllStructSetData($tMenu, "TypeData", DllStructGetPtr($tText))
EndIf
Local $aResult = DllCall("User32.dll", "bool", "InsertMenuItemW", "handle", $hMenu, "uint", $iIndex, "bool", True, "struct*", $tMenu)
If @error Then Return SetError(@error, @extended, -1)
Return SetExtended($aResult[0], $iIndex)
EndFunc
Func _GUICtrlMenu_CreateMenu($iStyle = 8)
Local $aResult = DllCall("User32.dll", "handle", "CreateMenu")
If @error Then Return SetError(@error, @extended, 0)
If $aResult[0] = 0 Then Return SetError(10, 0, 0)
_GUICtrlMenu_SetMenuStyle($aResult[0], $iStyle)
Return $aResult[0]
EndFunc
Func _GUICtrlMenu_CreatePopup($iStyle = 8)
Local $aResult = DllCall("User32.dll", "handle", "CreatePopupMenu")
If @error Then Return SetError(@error, @extended, 0)
If $aResult[0] = 0 Then Return SetError(10, 0, 0)
_GUICtrlMenu_SetMenuStyle($aResult[0], $iStyle)
Return $aResult[0]
EndFunc
Func _GUICtrlMenu_DeleteMenu($hMenu, $iItem, $fByPos = True)
Local $iByPos = 0
If $fByPos Then $iByPos = $MF_BYPOSITION
Local $aResult = DllCall("User32.dll", "bool", "DeleteMenu", "handle", $hMenu, "uint", $iItem, "uint", $iByPos)
If @error Then Return SetError(@error, @extended, False)
If $aResult[0] = 0 Then Return SetError(10, 0, False)
_GUICtrlMenu_DrawMenuBar(_GUICtrlMenu_FindParent($hMenu))
Return True
EndFunc
Func _GUICtrlMenu_DestroyMenu($hMenu)
Local $aResult = DllCall("User32.dll", "bool", "DestroyMenu", "handle", $hMenu)
If @error Then Return SetError(@error, @extended, False)
Return $aResult[0]
EndFunc
Func _GUICtrlMenu_DrawMenuBar($hWnd)
Local $aResult = DllCall("User32.dll", "bool", "DrawMenuBar", "hwnd", $hWnd)
If @error Then Return SetError(@error, @extended, False)
Return $aResult[0]
EndFunc
Func _GUICtrlMenu_FindParent($hMenu)
Local $hList = _WinAPI_EnumWindowsTop()
For $iI = 1 To $hList[0][0]
If _GUICtrlMenu_GetMenu($hList[$iI][0]) = $hMenu Then Return $hList[$iI][0]
Next
EndFunc
Func _GUICtrlMenu_GetItemBmp($hMenu, $iItem, $fByPos = True)
Local $tInfo = _GUICtrlMenu_GetItemInfo($hMenu, $iItem, $fByPos)
Return DllStructGetData($tInfo, "BmpItem")
EndFunc
Func _GUICtrlMenu_GetItemCount($hMenu)
Local $aResult = DllCall("User32.dll", "int", "GetMenuItemCount", "handle", $hMenu)
If @error Then Return SetError(@error, @extended, -1)
Return $aResult[0]
EndFunc
Func _GUICtrlMenu_GetItemData($hMenu, $iItem, $fByPos = True)
Local $tInfo = _GUICtrlMenu_GetItemInfo($hMenu, $iItem, $fByPos)
Return DllStructGetData($tInfo, "ItemData")
EndFunc
Func _GUICtrlMenu_GetItemDisabled($hMenu, $iItem, $fByPos = True)
Return BitAND(_GUICtrlMenu_GetItemStateEx($hMenu, $iItem, $fByPos), $MF_DISABLED) <> 0
EndFunc
Func _GUICtrlMenu_GetItemInfo($hMenu, $iItem, $fByPos = True)
Local $tInfo = DllStructCreate($tagMENUITEMINFO)
DllStructSetData($tInfo, "Size", DllStructGetSize($tInfo))
DllStructSetData($tInfo, "Mask", $MIIM_DATAMASK)
Local $aResult = DllCall("User32.dll", "bool", "GetMenuItemInfo", "handle", $hMenu, "uint", $iItem, "bool", $fByPos, "struct*", $tInfo)
If @error Then Return SetError(@error, @extended, 0)
Return SetExtended($aResult[0], $tInfo)
EndFunc
Func _GUICtrlMenu_GetItemStateEx($hMenu, $iItem, $fByPos = True)
Local $tInfo = _GUICtrlMenu_GetItemInfo($hMenu, $iItem, $fByPos)
Return DllStructGetData($tInfo, "State")
EndFunc
Func _GUICtrlMenu_GetMenu($hWnd)
Local $aResult = DllCall("User32.dll", "handle", "GetMenu", "hwnd", $hWnd)
If @error Then Return SetError(@error, @extended, 0)
Return $aResult[0]
EndFunc
Func _GUICtrlMenu_SetItemBmp($hMenu, $iItem, $hBmp, $fByPos = True)
Local $tInfo = DllStructCreate($tagMENUITEMINFO)
DllStructSetData($tInfo, "Size", DllStructGetSize($tInfo))
DllStructSetData($tInfo, "Mask", $MIIM_BITMAP)
DllStructSetData($tInfo, "BmpItem", $hBmp)
Return _GUICtrlMenu_SetItemInfo($hMenu, $iItem, $tInfo, $fByPos)
EndFunc
Func _GUICtrlMenu_SetItemData($hMenu, $iItem, $iData, $fByPos = True)
Local $tInfo = DllStructCreate($tagMENUITEMINFO)
DllStructSetData($tInfo, "Size", DllStructGetSize($tInfo))
DllStructSetData($tInfo, "Mask", $MIIM_DATA)
DllStructSetData($tInfo, "ItemData", $iData)
Return _GUICtrlMenu_SetItemInfo($hMenu, $iItem, $tInfo, $fByPos)
EndFunc
Func _GUICtrlMenu_SetItemDisabled($hMenu, $iItem, $fState = True, $fByPos = True)
Return _GUICtrlMenu_SetItemState($hMenu, $iItem, BitOR($MFS_DISABLED, $MFS_GRAYED), $fState, $fByPos)
EndFunc
Func _GUICtrlMenu_SetItemEnabled($hMenu, $iItem, $fState = True, $fByPos = True)
Return _GUICtrlMenu_SetItemState($hMenu, $iItem, BitOR($MFS_DISABLED, $MFS_GRAYED), Not $fState, $fByPos)
EndFunc
Func _GUICtrlMenu_SetItemInfo($hMenu, $iItem, ByRef $tInfo, $fByPos = True)
DllStructSetData($tInfo, "Size", DllStructGetSize($tInfo))
Local $aResult = DllCall("User32.dll", "bool", "SetMenuItemInfoW", "handle", $hMenu, "uint", $iItem, "bool", $fByPos, "struct*", $tInfo)
If @error Then Return SetError(@error, @extended, False)
Return $aResult[0]
EndFunc
Func _GUICtrlMenu_SetItemState($hMenu, $iItem, $iState, $fState = True, $fByPos = True)
Local $iFlag = _GUICtrlMenu_GetItemStateEx($hMenu, $iItem, $fByPos)
If $fState Then
$iState = BitOR($iFlag, $iState)
Else
$iState = BitAND($iFlag, BitNOT($iState))
EndIf
Local $tInfo = DllStructCreate($tagMENUITEMINFO)
DllStructSetData($tInfo, "Size", DllStructGetSize($tInfo))
DllStructSetData($tInfo, "Mask", $MIIM_STATE)
DllStructSetData($tInfo, "State", $iState)
Return _GUICtrlMenu_SetItemInfo($hMenu, $iItem, $tInfo, $fByPos)
EndFunc
Func _GUICtrlMenu_SetItemType($hMenu, $iItem, $iType, $fByPos = True)
Local $tInfo = DllStructCreate($tagMENUITEMINFO)
DllStructSetData($tInfo, "Size", DllStructGetSize($tInfo))
DllStructSetData($tInfo, "Mask", $MIIM_FTYPE)
DllStructSetData($tInfo, "Type", $iType)
Return _GUICtrlMenu_SetItemInfo($hMenu, $iItem, $tInfo, $fByPos)
EndFunc
Func _GUICtrlMenu_SetMenuInfo($hMenu, ByRef $tInfo)
DllStructSetData($tInfo, "Size", DllStructGetSize($tInfo))
Local $aResult = DllCall("User32.dll", "bool", "SetMenuInfo", "handle", $hMenu, "struct*", $tInfo)
If @error Then Return SetError(@error, @extended, False)
Return $aResult[0]
EndFunc
Func _GUICtrlMenu_SetMenuStyle($hMenu, $iStyle)
Local $tInfo = DllStructCreate($tagMENUINFO)
DllStructSetData($tInfo, "Mask", $MIM_STYLE)
DllStructSetData($tInfo, "Style", $iStyle)
Return _GUICtrlMenu_SetMenuInfo($hMenu, $tInfo)
EndFunc
Func _GUICtrlMenu_TrackPopupMenu($hMenu, $hWnd, $iX = -1, $iY = -1, $iAlignX = 1, $iAlignY = 1, $iNotify = 0, $iButtons = 0)
If $iX = -1 Then $iX = _WinAPI_GetMousePosX()
If $iY = -1 Then $iY = _WinAPI_GetMousePosY()
Local $iFlags = 0
Switch $iAlignX
Case 1
$iFlags = BitOR($iFlags, $TPM_LEFTALIGN)
Case 2
$iFlags = BitOR($iFlags, $TPM_RIGHTALIGN)
Case Else
$iFlags = BitOR($iFlags, $TPM_CENTERALIGN)
EndSwitch
Switch $iAlignY
Case 1
$iFlags = BitOR($iFlags, $TPM_TOPALIGN)
Case 2
$iFlags = BitOR($iFlags, $TPM_VCENTERALIGN)
Case Else
$iFlags = BitOR($iFlags, $TPM_BOTTOMALIGN)
EndSwitch
If BitAND($iNotify, 1) <> 0 Then $iFlags = BitOR($iFlags, $TPM_NONOTIFY)
If BitAND($iNotify, 2) <> 0 Then $iFlags = BitOR($iFlags, $TPM_RETURNCMD)
Switch $iButtons
Case 1
$iFlags = BitOR($iFlags, $TPM_RIGHTBUTTON)
Case Else
$iFlags = BitOR($iFlags, $TPM_LEFTBUTTON)
EndSwitch
Local $aResult = DllCall("User32.dll", "bool", "TrackPopupMenu", "handle", $hMenu, "uint", $iFlags, "int", $iX, "int", $iY, "int", 0, "hwnd", $hWnd, "ptr", 0)
If @error Then Return SetError(@error, @extended, 0)
Return $aResult[0]
EndFunc
Global $_Timers_aTimerIDs[1][3]
Func _Timer_KillAllTimers($hWnd)
Local $iNumTimers = $_Timers_aTimerIDs[0][0]
If $iNumTimers = 0 Then Return False
Local $aResult, $hCallBack = 0
For $x = $iNumTimers To 1 Step -1
If IsHWnd($hWnd) Then
$aResult = DllCall("user32.dll", "bool", "KillTimer", "hwnd", $hWnd, "uint_ptr", $_Timers_aTimerIDs[$x][1])
Else
$aResult = DllCall("user32.dll", "bool", "KillTimer", "hwnd", $hWnd, "uint_ptr", $_Timers_aTimerIDs[$x][0])
EndIf
If @error Or $aResult[0] = 0 Then Return SetError(@error, @extended, False)
$hCallBack = $_Timers_aTimerIDs[$x][2]
If $hCallBack <> 0 Then DllCallbackFree($hCallBack)
$_Timers_aTimerIDs[0][0] -= 1
Next
ReDim $_Timers_aTimerIDs[1][3]
Return True
EndFunc
Func _Timer_SetTimer($hWnd, $iElapse = 250, $sTimerFunc = "", $iTimerID = -1)
Local $aResult[1] = [0], $pTimerFunc = 0, $hCallBack = 0, $iIndex = $_Timers_aTimerIDs[0][0] + 1
If $iTimerID = -1 Then
ReDim $_Timers_aTimerIDs[$iIndex + 1][3]
$_Timers_aTimerIDs[0][0] = $iIndex
$iTimerID = $iIndex + 1000
For $x = 1 To $iIndex
If $_Timers_aTimerIDs[$x][0] = $iTimerID Then
$iTimerID = $iTimerID + 1
$x = 0
EndIf
Next
If $sTimerFunc <> "" Then
$hCallBack = DllCallbackRegister($sTimerFunc, "none", "hwnd;int;uint_ptr;dword")
If $hCallBack = 0 Then Return SetError(-1, -1, 0)
$pTimerFunc = DllCallbackGetPtr($hCallBack)
If $pTimerFunc = 0 Then Return SetError(-1, -1, 0)
EndIf
$aResult = DllCall("user32.dll", "uint_ptr", "SetTimer", "hwnd", $hWnd, "uint_ptr", $iTimerID, "uint", $iElapse, "ptr", $pTimerFunc)
If @error Or $aResult[0] = 0 Then Return SetError(@error, @extended, 0)
$_Timers_aTimerIDs[$iIndex][0] = $aResult[0]
$_Timers_aTimerIDs[$iIndex][1] = $iTimerID
$_Timers_aTimerIDs[$iIndex][2] = $hCallBack
Else
For $x = 1 To $iIndex - 1
If $_Timers_aTimerIDs[$x][0] = $iTimerID Then
If IsHWnd($hWnd) Then $iTimerID = $_Timers_aTimerIDs[$x][1]
$hCallBack = $_Timers_aTimerIDs[$x][2]
If $hCallBack <> 0 Then
$pTimerFunc = DllCallbackGetPtr($hCallBack)
If $pTimerFunc = 0 Then Return SetError(-1, -1, 0)
EndIf
$aResult = DllCall("user32.dll", "uint_ptr", "SetTimer", "hwnd", $hWnd, "uint_ptr", $iTimerID, "int", $iElapse, "ptr", $pTimerFunc)
If @error Or $aResult[0] = 0 Then Return SetError(@error, @extended, 0)
ExitLoop
EndIf
Next
EndIf
Return $aResult[0]
EndFunc
Global Const $BASS_ERROR_HANDLE = 5
Global Const $BASS_ERROR_NOTAVAIL = 37
$BASS_INFO = 'dword flags;' & 'dword hwsize;' & 'dword hwfree;' & 'dword freesam;' & 'dword free3d;' & 'dword minrate;' & 'dword maxrate;' & 'int eax;' & 'dword minbuf;' & 'dword dsver;' & 'dword latency;' & 'dword initflags;' & 'dword speakers;' & 'dword freq'
$BASS_RECORDINFO = "dword flags;" & 'dword formats;' & 'dword inputs;' & 'int singlein;' & 'dword freq'
$BASS_SAMPLE = 'dword freq;' & 'float volume;' & 'float pan;' & 'dword flags;' & 'dword length;' & 'dword max;' & 'dword origres;' & 'dword chans;' & 'dword mingap;' & 'dword mode3d;' & 'float mindist;' & 'float MAXDIST;' & 'dword iangle;' & 'dword oangle;' & 'float outvol;' & 'dword vam;' & 'dword priority;'
Global Const $BASS_UNICODE = 0x80000000
$BASS_CHANNELINFO = 'dword freq;' & 'dword chans;' & 'dword flags;' & 'dword ctype;' & 'dword origres;' & 'dword plugin;' & 'dword sample;' & 'ptr filename;'
$BASS_PLUGINFORM = 'dword;ptr;ptr;'
$BASS_PLUGININFO = 'dword version;' & 'dword formatc;' & 'ptr formats;'
$BASS_3DVECTOR = 'float X;' & 'float Y;' & 'float z;'
Global Const $BASS_FILEPOS_END = 2
Global Const $BASS_ATTRIB_VOL = 2
Global Const $BASS_POS_BYTE = 0
$BASS_DX8_CHORUS = 'float;' & 'float;' & 'float;' & 'float;' & 'dword;' & 'float;' & 'dword;'
$BASS_DX8_COMPRESSOR = 'float;' & 'float;' & 'float;' & 'float;' & 'float;' & 'float;'
$BASS_DX8_DISTORTION = 'float;' & 'float;' & 'float;' & 'float;' & 'float;'
$BASS_DX8_ECHO = 'float;' & 'float;' & 'float;' & 'float;' & 'int;'
$BASS_DX8_FLANGER = 'float;' & 'float;' & 'float;' & 'float;' & 'dword;' & 'float;' & 'dword;'
$BASS_DX8_GARGLE = 'dword;' & 'dword;'
$BASS_DX8_I3DL2REVERB = 'int;' & 'int;' & 'float;' & 'float;' & 'float;' & 'int;' & 'float;' & 'int;' & 'float;' & 'float;' & 'float;' & 'float;'
$BASS_DX8_PARAMEQ = 'float;' & 'float;' & 'float;'
$BASS_DX8_REVERB = 'float;' & 'float;' & 'float;' & 'float;'
$ogg_tag = "char id[3];wchar title[30];wchar artist[30];wchar album[30];char year[4];wchar comment[30];ubyte genre;"
Global Const $__MISCCONSTANT_CC_ANYCOLOR = 0x0100
Global Const $__MISCCONSTANT_CC_FULLOPEN = 0x0002
Global Const $__MISCCONSTANT_CC_RGBINIT = 0x0001
Global Const $tagCHOOSECOLOR = "dword Size;hwnd hWndOwnder;handle hInstance;dword rgbResult;ptr CustColors;dword Flags;lparam lCustData;" & "ptr lpfnHook;ptr lpTemplateName"
Func _ChooseColor($iReturnType = 0, $iColorRef = 0, $iRefType = 0, $hWndOwnder = 0)
Local $custcolors = "dword[16]"
Local $tChoose = DllStructCreate($tagCHOOSECOLOR)
Local $tcc = DllStructCreate($custcolors)
If $iRefType = 1 Then
$iColorRef = Int($iColorRef)
ElseIf $iRefType = 2 Then
$iColorRef = Hex(String($iColorRef), 6)
$iColorRef = '0x' & StringMid($iColorRef, 5, 2) & StringMid($iColorRef, 3, 2) & StringMid($iColorRef, 1, 2)
EndIf
DllStructSetData($tChoose, "Size", DllStructGetSize($tChoose))
DllStructSetData($tChoose, "hWndOwnder", $hWndOwnder)
DllStructSetData($tChoose, "rgbResult", $iColorRef)
DllStructSetData($tChoose, "CustColors", DllStructGetPtr($tcc))
DllStructSetData($tChoose, "Flags", BitOR($__MISCCONSTANT_CC_ANYCOLOR, $__MISCCONSTANT_CC_FULLOPEN, $__MISCCONSTANT_CC_RGBINIT))
Local $aResult = DllCall("comdlg32.dll", "bool", "ChooseColor", "struct*", $tChoose)
If @error Then Return SetError(@error, @extended, -1)
If $aResult[0] = 0 Then Return SetError(-3, -3, -1)
Local $color_picked = DllStructGetData($tChoose, "rgbResult")
If $iReturnType = 1 Then
Return '0x' & Hex(String($color_picked), 6)
ElseIf $iReturnType = 2 Then
$color_picked = Hex(String($color_picked), 6)
Return '0x' & StringMid($color_picked, 5, 2) & StringMid($color_picked, 3, 2) & StringMid($color_picked, 1, 2)
ElseIf $iReturnType = 0 Then
Return $color_picked
Else
Return SetError(-4, -4, -1)
EndIf
EndFunc
Func _ClipPutFile($sFile, $sSeparator = "|")
Local Const $GMEM_MOVEABLE = 0x0002, $CF_HDROP = 15
$sFile &= $sSeparator & $sSeparator
Local $nGlobMemSize = 2 *(StringLen($sFile) + 20)
Local $aResult = DllCall("user32.dll", "bool", "OpenClipboard", "hwnd", 0)
If @error Or $aResult[0] = 0 Then Return SetError(1, _WinAPI_GetLastError(), False)
Local $iError = 0, $iLastError = 0
$aResult = DllCall("user32.dll", "bool", "EmptyClipboard")
If @error Or Not $aResult[0] Then
$iError = 2
$iLastError = _WinAPI_GetLastError()
Else
$aResult = DllCall("kernel32.dll", "handle", "GlobalAlloc", "uint", $GMEM_MOVEABLE, "ulong_ptr", $nGlobMemSize)
If @error Or Not $aResult[0] Then
$iError = 3
$iLastError = _WinAPI_GetLastError()
Else
Local $hGlobal = $aResult[0]
$aResult = DllCall("kernel32.dll", "ptr", "GlobalLock", "handle", $hGlobal)
If @error Or Not $aResult[0] Then
$iError = 4
$iLastError = _WinAPI_GetLastError()
Else
Local $hLock = $aResult[0]
Local $DROPFILES = DllStructCreate("dword pFiles;" & $tagPOINT & ";bool fNC;bool fWide;wchar[" & StringLen($sFile) + 1 & "]", $hLock)
If @error Then Return SetError(5, 6, False)
Local $tempStruct = DllStructCreate("dword;long;long;bool;bool")
DllStructSetData($DROPFILES, "pFiles", DllStructGetSize($tempStruct))
DllStructSetData($DROPFILES, "X", 0)
DllStructSetData($DROPFILES, "Y", 0)
DllStructSetData($DROPFILES, "fNC", 0)
DllStructSetData($DROPFILES, "fWide", 1)
DllStructSetData($DROPFILES, 6, $sFile)
For $i = 1 To StringLen($sFile)
If DllStructGetData($DROPFILES, 6, $i) = $sSeparator Then DllStructSetData($DROPFILES, 6, Chr(0), $i)
Next
$aResult = DllCall("user32.dll", "handle", "SetClipboardData", "uint", $CF_HDROP, "handle", $hGlobal)
If @error Or Not $aResult[0] Then
$iError = 6
$iLastError = _WinAPI_GetLastError()
EndIf
$aResult = DllCall("kernel32.dll", "bool", "GlobalUnlock", "handle", $hGlobal)
If(@error Or Not $aResult[0]) And Not $iError And _WinAPI_GetLastError() Then
$iError = 8
$iLastError = _WinAPI_GetLastError()
EndIf
EndIf
$aResult = DllCall("kernel32.dll", "ptr", "GlobalFree", "handle", $hGlobal)
If(@error Or $aResult[0]) And Not $iError Then
$iError = 9
$iLastError = _WinAPI_GetLastError()
EndIf
EndIf
EndIf
$aResult = DllCall("user32.dll", "bool", "CloseClipboard")
If(@error Or Not $aResult[0]) And Not $iError Then Return SetError(7, _WinAPI_GetLastError(), False)
If $iError Then Return SetError($iError, $iLastError, False)
Return True
EndFunc
Func _Iif($fTest, $vTrueVal, $vFalseVal)
If $fTest Then
Return $vTrueVal
Else
Return $vFalseVal
EndIf
EndFunc
Func _VersionCompare($sVersion1, $sVersion2)
If $sVersion1 = $sVersion2 Then Return 0
Local $sep = "."
If StringInStr($sVersion1, $sep) = 0 Then $sep = ","
Local $aVersion1 = StringSplit($sVersion1, $sep)
Local $aVersion2 = StringSplit($sVersion2, $sep)
If UBound($aVersion1) <> UBound($aVersion2) Or UBound($aVersion1) = 0 Then
SetExtended(1)
If $sVersion1 > $sVersion2 Then
Return 1
ElseIf $sVersion1 < $sVersion2 Then
Return -1
EndIf
Else
For $i = 1 To UBound($aVersion1) - 1
If StringIsDigit($aVersion1[$i]) And StringIsDigit($aVersion2[$i]) Then
If Number($aVersion1[$i]) > Number($aVersion2[$i]) Then
Return 1
ElseIf Number($aVersion1[$i]) < Number($aVersion2[$i]) Then
Return -1
EndIf
Else
SetExtended(1)
If $aVersion1[$i] > $aVersion2[$i] Then
Return 1
ElseIf $aVersion1[$i] < $aVersion2[$i] Then
Return -1
EndIf
EndIf
Next
EndIf
Return SetError(2, 0, 0)
EndFunc
Func __MISC_GetDC($hWnd)
Local $aResult = DllCall("User32.dll", "handle", "GetDC", "hwnd", $hWnd)
If @error Or Not $aResult[0] Then Return SetError(1, _WinAPI_GetLastError(), 0)
Return $aResult[0]
EndFunc
Func __MISC_GetDeviceCaps($hDC, $iIndex)
Local $aResult = DllCall("GDI32.dll", "int", "GetDeviceCaps", "handle", $hDC, "int", $iIndex)
If @error Then Return SetError(@error, @extended, 0)
Return $aResult[0]
EndFunc
Func __MISC_ReleaseDC($hWnd, $hDC)
Local $aResult = DllCall("User32.dll", "int", "ReleaseDC", "hwnd", $hWnd, "handle", $hDC)
If @error Then Return SetError(@error, @extended, False)
Return $aResult[0] <> 0
EndFunc
Global $_ghBassDll = -1
Global $_gbBASSULONGLONGFIXED = _VersionCompare(@AutoItVersion, "3.3.0.0") = 1
Global $BASS_DLL_UDF_VER = "2.4.5.0"
Global $BASS_ERR_DLL_NO_EXIST = -1
GLOBAL $BASS_STARTUP_BYPASS_VERSIONCHECK = 0
Func _BASS_Startup($sBassDLL="bass.dll")
If $_ghBassDll <> -1 Then Return True
If Not FileExists($sBassDLL) Then Return SetError($BASS_ERR_DLL_NO_EXIST, 0, False)
If $BASS_STARTUP_BYPASS_VERSIONCHECK Then
If _VersionCompare(FileGetVersion($sBassDLL), $BASS_DLL_UDF_VER) = -1 Then
MsgBox(0, "ERROR", "This version of BASS.au3 is made for Bass.dll V" & $BASS_DLL_UDF_VER & ".  Please update")
Exit
EndIf
EndIf
$_ghBassDll = DllOpen($sBassDLL)
Return $_ghBassDll <> -1
EndFunc
Func _BASS_ErrorGetCode()
Local $BASS_ret_ = DllCall($_ghBassDll, "int", "BASS_ErrorGetCode")
If @error Then Return SetError(1,0,-1)
Return $BASS_ret_[0]
EndFunc
Func _BASS_Init($flags, $device = -1, $freq = 44100, $win = 0, $clsid = "")
Local $BASS_ret_ = DllCall($_ghBassDll, "int", "BASS_Init", "int", $device, "dword", $freq, "dword", $flags, "hwnd", $win, "hwnd", $clsid)
If @error Then Return SetError(1,1,0)
If $BASS_ret_[0] = 0 Then Return SetError(_BASS_ErrorGetCode(),0,0)
Return $BASS_ret_[0]
EndFunc
Func _BASS_Free()
Local $BASS_ret_ = DllCall($_ghBassDll, "int", "BASS_Free")
If @error Then Return SetError(1,1,0)
If $BASS_ret_[0] = 0 Then Return SetError(_BASS_ErrorGetCode(),0,0)
Return $BASS_ret_[0]
EndFunc
Func _BASS_PluginLoad($filename, $flags = 0)
Local $BASS_ret_ = DllCall($_ghBassDll, "dword", "BASS_PluginLoad", "wstr", $filename, "dword", BitOR($flags, $BASS_UNICODE))
If @error Then Return SetError(1,1,0)
If $BASS_ret_[0] = 0 Then Return SetError(_BASS_ErrorGetCode(),0,0)
Return $BASS_ret_[0]
EndFunc
Func _BASS_PluginFree($handle)
Local $BASS_ret_ = DllCall($_ghBassDll, "int", "BASS_PluginFree", "dword", $handle)
If @error Then Return SetError(1,1,0)
If $BASS_ret_[0] = 0 Then Return SetError(_BASS_ErrorGetCode(),0,0)
Return $BASS_ret_[0]
EndFunc
Func _BASS_StreamCreateFile($mem, $file, $offset, $length, $flags)
Local $tpFile = "ptr"
If IsString($file) Then $tpFile = "wstr"
Local $BASS_ret_ = DllCall($_ghBassDll, "dword", "BASS_StreamCreateFile", "int", $mem, $tpFile, $file, "uint64", $offset, "uint64", $length, "DWORD", BitOR($flags, $BASS_UNICODE))
If @error Then Return SetError(1,1,0)
If $BASS_ret_[0] = 0 Then Return SetError(_BASS_ErrorGetCode(),0,0)
Return $BASS_ret_[0]
EndFunc
Func _BASS_StreamFree($handle)
Local $BASS_ret_ = DllCall($_ghBassDll, "int", "BASS_StreamFree", "dword", $handle)
If @error Then Return SetError(1,1,0)
If $BASS_ret_[0] = 0 Then Return SetError(_BASS_ErrorGetCode(),0,0)
Return $BASS_ret_[0]
EndFunc
Func _BASS_StreamGetFilePosition($handle, $mode)
Local $BASS_ret_ = DllCall($_ghBassDll, "uint64", "BASS_StreamGetFilePosition", "dword", $handle, "dword", $mode)
If @error Then Return SetError(1,1,0)
If $BASS_ret_[0] = 0 Then Return SetError(_BASS_ErrorGetCode(),0,0)
Return __BASS_ReOrderULONGLONG($BASS_ret_[0])
EndFunc
Func _BASS_ChannelBytes2Seconds($handle, $pos)
Local $BASS_ret_ = DllCall($_ghBassDll, "double", "BASS_ChannelBytes2Seconds", "dword", $handle, "uint64", $pos)
If @error Then Return SetError(1,1,0)
If $BASS_ret_[0] < 0 Then Return SetError(_BASS_ErrorGetCode(),0,0)
Return $BASS_ret_[0]
EndFunc
Func _BASS_ChannelIsActive($handle)
Local $BASS_ret_ = DllCall($_ghBassDll, "int", "BASS_ChannelIsActive", "DWORD", $handle)
If @error Then Return SetError(1,1,0)
Return $BASS_ret_[0]
EndFunc
Func _BASS_ChannelGetTags($handle, $tags)
Local $BASS_ret_ = DllCall($_ghBassDll, "ptr", "BASS_ChannelGetTags", "DWORD", $handle, "DWORD", $tags)
If @error Then Return SetError(1,1,0)
If $BASS_ret_[0] = 0 Then Return SetError(_BASS_ErrorGetCode(),0,0)
Return $BASS_ret_[0]
EndFunc
Func _BASS_ChannelPlay($handle, $restart)
Local $BASS_ret_ = DllCall($_ghBassDll, "int", "BASS_ChannelPlay", "DWORD", $handle, "int", $restart)
If @error Then Return SetError(1,1,0)
If $BASS_ret_[0] = 0 Then Return SetError(_BASS_ErrorGetCode(),0,0)
Return $BASS_ret_[0]
EndFunc
Func _BASS_ChannelStop($handle)
Local $BASS_ret_ = DllCall($_ghBassDll, "int", "BASS_ChannelStop", "DWORD", $handle)
If @error Then Return SetError(1,1,0)
If $BASS_ret_[0] = 0 Then Return SetError(_BASS_ErrorGetCode(),0,0)
Return $BASS_ret_[0]
EndFunc
Func _BASS_ChannelPause($handle)
Local $BASS_ret_ = DllCall($_ghBassDll, "int", "BASS_ChannelPause", "DWORD", $handle)
If @error Then Return SetError(1,1,0)
If $BASS_ret_[0] = 0 Then Return SetError(_BASS_ErrorGetCode(),0,0)
Return $BASS_ret_[0]
EndFunc
Func _BASS_ChannelSetAttribute($handle, $attrib, $value)
Local $BASS_ret_ = DllCall($_ghBassDll, "int", "BASS_ChannelSetAttribute", "DWORD", $handle, "DWORD", $attrib, "float", $value)
If @error Then Return SetError(1,1,0)
If $BASS_ret_[0] = 0 Then Return SetError(_BASS_ErrorGetCode(),0,0)
Return $BASS_ret_[0]
EndFunc
Func _BASS_ChannelGetAttribute($handle, $attrib)
Local $BASS_ret_ = DllCall($_ghBassDll, "int", "BASS_ChannelGetAttribute", "DWORD", $handle, "DWORD", $attrib, "float*", 0)
If @error Then Return SetError(1,1,0)
If $BASS_ret_[0] = 0 Then Return SetError(_BASS_ErrorGetCode(),0,0)
Return $BASS_ret_[3]
EndFunc
Func _BASS_ChannelGetLength($handle, $mode)
Local $BASS_ret_ = DllCall($_ghBassDll, "uint64", "BASS_ChannelGetLength", "DWORD", $handle, "DWORD", $mode)
If @error Then Return SetError(1,1,0)
$BASS_ret_[0] = __BASS_ReOrderULONGLONG($BASS_ret_[0])
If $BASS_ret_[0] = -1 Then Return SetError(_BASS_ErrorGetCode(),0,0)
Return $BASS_ret_[0]
EndFunc
Func _BASS_ChannelSetPosition($handle, $pos, $mode)
Local $BASS_ret_ = DllCall($_ghBassDll, "int", "BASS_ChannelSetPosition", "DWORD", $handle, "uint64", $pos, "DWORD", $mode)
If @error Then Return SetError(1,1,0)
If $BASS_ret_[0] = 0 Then Return SetError(_BASS_ErrorGetCode(),0,0)
Return $BASS_ret_[0]
EndFunc
Func _BASS_ChannelGetPosition($handle, $mode)
Local $BASS_ret_ = DllCall($_ghBassDll, "uint64", "BASS_ChannelGetPosition", "DWORD", $handle, "DWORD", $mode)
If @error Then Return SetError(1,1,0)
$BASS_ret_[0] = __BASS_ReOrderULONGLONG($BASS_ret_[0])
If $BASS_ret_[0] = -1 Then Return SetError(_BASS_ErrorGetCode(),0,0)
Return $BASS_ret_[0]
EndFunc
Func _BASS_PtrStringLen($ptr, $IsUniCode = False)
Local $UniCodeFunc = ""
If $IsUniCode Then $UniCodeFunc = "W"
Local $BASS_ret_ = DllCall("kernel32.dll", "int", "lstrlen" & $UniCodeFunc, "ptr", $ptr)
If @error Then Return SetError(1, 0, -1)
Return $BASS_ret_[0]
EndFunc
Func _BASS_PtrStringRead($ptr, $IsUniCode = False, $StringLen = -1)
Local $UniCodeString = ""
If $IsUniCode Then $UniCodeString = "W"
If $StringLen < 1 Then $StringLen = _BASS_PtrStringLen($ptr, $IsUniCode)
If $StringLen < 1 Then Return SetError(1, 0, "")
Local $struct = DllStructCreate($UniCodeString & "char[" &($StringLen + 1) & "]", $ptr)
Return DllStructGetData($struct, 1)
EndFunc
Func _GetID3StructFromOGGComment($ptr)
Local $s,$string
Local $tags = DllStructCreate($ogg_tag)
Local $bin=Binary('')
Do
$s=DllStructCreate("BYTE", $ptr)
$string = DllStructGetData($s, 1)
If $string = 0x00 Then
If BinaryMid($bin,BinaryLen($bin),1)=0x0A Then ExitLoop
$string=0x0A
EndIf
$bin&=BinaryMid($string,1,1)
$ptr += 1
Until False
$tag_array=StringSplit(BinaryToString($bin,4),@LF)
For $i = 1 To $tag_array[0]
Switch StringLeft($tag_array[$i], StringInStr($tag_array[$i], "=") - 1)
Case "title"
DllStructSetData($tags, "title", StringTrimLeft($tag_array[$i], StringInStr($tag_array[$i], "=")))
Case "artist"
DllStructSetData($tags, "artist", StringTrimLeft($tag_array[$i], StringInStr($tag_array[$i], "=")))
Case "album"
DllStructSetData($tags, "album", StringTrimLeft($tag_array[$i], StringInStr($tag_array[$i], "=")))
Case "date"
DllStructSetData($tags, "year", StringTrimLeft($tag_array[$i], StringInStr($tag_array[$i], "=")))
Case "genre"
DllStructSetData($tags, "genre", StringTrimLeft($tag_array[$i], StringInStr($tag_array[$i], "=")))
Case "comment"
DllStructSetData($tags, "comment", StringTrimLeft($tag_array[$i], StringInStr($tag_array[$i], "=")))
EndSwitch
Next
Return $tags
EndFunc
Func _HiWord($value)
Return BitShift($value, 16)
EndFunc
Func _LoWord($value)
Return BitAND($value, 0xFFFF)
EndFunc
Func __BASS_ReOrderULONGLONG($UINT64)
If $_gbBASSULONGLONGFIXED Then Return $UINT64
Local $int = DllStructCreate("uint64")
Local $longlong = DllStructCreate("ulong;ulong", DllStructGetPtr($int))
DllStructSetData($int, 1, $UINT64)
Return 4294967296 * DllStructGetData($longlong, 1) + DllStructGetData($longlong, 2)
EndFunc
Global $hGUI, $hReBar, $hToolbar, $Tbar, $TbarMenu, $LyrMenu, $ListMenu, $SubMenu, $SubMenu2, $Lrc_Choose, $Setting, $hGIF, $dGUI, $ID3_lst, $ID3_dial, $ID3_btn, $hIcons[19]
Global Enum $idAdd = 1000, $idOpen, $idAbt, $idSet, $idSav, $idDat, $idLst
Global $iItem, $iSelected = -1, $old_name, $pre_name='', $lyr_select[1] = [0], $fDblClk = 0, $Changed = -1, $_Free = 0, $show_lyric = True, $drop_DIR = False
Global Enum $qqjt = 2000, $kwyy, $mngc, $bdyy, $ilrc, $qqyy, $tq, $tq1, $tq2, $yh, $yh1, $yh2, $sc, $cr,$hd,$save_as_lrc,$save_as_srt
Global Enum $copy_item = 3000, $rn_item, $copy_qq_item, $rm_item, $edit_item, $reload_item, $id3_item, $del_id3_item, $copy_lyr_item, $load_cover, $shell_item
Global $hToolBar_image[7], $hToolBar_strings[7], $Fonts[6], $Top_set, $layOut1, $layOut2, $layOut0, $Fade_set, $FadeOut=25, $Slider1,$cnc, $Ping
Global $StatusBar, $StatusBar_PartsWidth[5] = [24, 190, 533, 750, -1], $NetState[6], $L_process, $OldParam=-1
Global $Sound_Play, $Sound_Stop, $Sound_Flag, $s_flag=False, $MusicHandle, $Data_Count=0, $mode = -1
Global $IWndListView, $hWndListView, $lWndListView, $hListView, $Lrc_List, $hHeader, $l_btn_header, $tab_Save, $Save_Checkbox, $Save_Auto, $Reg_Checkbox, $Lrc_Checkbox, $SubSel_Deep, $Copy_Checkbox, $Search_Button, $ProxyCheck, $ProxyIP, $port_input, $cover, $save_cover, $shell_bt, $align_check, $download_cover, $filter,$bar,$reg_order=1,$old_keyword=''
Global $sub_list, $sub_OK, $Label5, $Button1, $Button2, $n=0, $move_timer=-1, $col_def
Global $col_1, $col_2, $col_3, $col_4, $col_5, $col_6
Global $setpos, $time_pos=0, $length, $vol=1, $lrc_text, $lrc_Format, $lrc_Show, $lyr_changed = False, $root_folder, $cover_Dir, $load_flag = 1, $load_Pro, $pre_get[1] = [-1], $aLVItems[1] = [0], $bLVItems[2][1] = [[0],[0]], $toolbar_subitem[2]=[0,0], $l_head, $file_list,$deep
Global $font_name = "Arial", $font_var = 0, $font_size = 16, $font_xing = 400, $font_color = 0xFF0000, $list_bk_color,$lrc_text_back_color=0xFFFFFF, $lrc_text_front_color=0xEE0000
Global $list_name, $list_var, $list_size, $list_xing
Global $lGUI,$h[4],$head_OK,$sTab
Global $play_control, $tray_play, $tray_stop
Global $ct, $cnc, $big, $small
Global Const $TBDDRET_DEFAULT = 0
Global Const $TB_LINEUP = 0
Global Const $TB_LINEDOWN = 1
Global Const $TB_PAGEUP = 2
Global Const $TB_PAGEDOWN = 3
Global Const $TB_THUMBPOSITION = 4
Global Const $TB_THUMBTRACK = 5
Global Const $TB_ENDTRACK = 8
Global Const $TBS_NOTICKS = 0x0010
Global Const $PBS_MARQUEE = 0x00000008
Global Const $WHEEL_DELTA = 120
Global Const $MK_LBUTTON = 0x1
Global Const $MK_RBUTTON = 0x2
Global Const $L[6] = ['简短说明', '这里显示同步歌词', '双击定位时间戳', '点击两次修改内容', '接受jpg/lrc/krc/mp3/wma/ogg/wav/acc/m4a/flac/ape文件', 'enjoy yourself!']
Global Const $key[27]=['吖','八','擦','耷','俄','发','噶','哈','丌','丌','卡','拉','马','拿','哦','趴','七','然','撒','他','挖','挖','挖','西','丫','匝','匝']
Global Const $ID3_v2_kword[8]=['标题','艺术家','专辑','流派','轨道','年份','备注','长度']
Global Const $ID3_v2_kword_Ex[11]=['异步歌词','商业性息链接','空位填充','自定义链接','编码器','艺术家(表演者)链接','唯一编号', '作曲家','乐队/乐团/伴奏','发布人','封面']
Global Const $PBM_SETMARQUEE = 0X400 + 10
Global $about = '此工具仅供学习使用，请勿作商业用途' & @LF & '杀毒软件可能会报毒，请自行斟酌' & @LF & 'bug较多，重要文件请备份或慎用' & @LF & '进度条滚动时请尽量减少操作' & @LF & '有更多建议请联系zhengjuefei25@gmail.com'
Global Const $_tagCHOOSEFONT = "dword Size;hwnd hWndOwner;handle hDC;ptr LogFont;int PointSize;dword Flags;dword rgbColors;lparam CustData;" & "ptr fnHook;ptr TemplateName;handle hInstance;ptr szStyle;word FontType;int nSizeMin;int nSizeMax"
Global $AlbumArtFile, $LyricsFile, $tr, $current_time, $current_song, $coverStartIndex=0, $douban2, $cover_key_input, $slider
Global $sFile = @ScriptDir & '\ICON\test.png'
Global $iW, $iH, $hBmp
Global $ti,$ar,$al,$by
Global $d_trans
Global $FileDir, $temp_stat="欢迎使用！", $prop_item, $hEdit
Global $begin, $lastClick=0, $Stop_l=False
Global Const $list_baidu="/x?op=12&count=1&title=%s$$%s$$$$"
Global Const $list_qq='/fcgi-bin/qm_getLyricId.fcg?name=%s&singer=%s&from=qqplayer'
Global $oMyError = ObjEvent("AutoIt.Error","MyErrFunc")
Switch @OSLang
Case "0804", "0404", "", "0c04", "1004", "1404"
Switch @OSVersion
Case 'WIN_XP'
$sTab = '摘要'
Case Else
$sTab = '详细信息'
EndSwitch
Case "1009", "0409", "0809", "0c09", "1409", "1809", "1c09", "2009", "2409", "2809", "2c09", "3009", "3409"
$sTab = "Details"
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
Global $__RegAsmPath, $ShellContextMenu
Func _NETFramework_Load($DLL_File, $flag)
If Not FileExists($DLL_File) Then Return SetError(2,0,0)
Local $sRoot = RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\.NETFramework", "InstallRoot")
If @error Then Return SetError(3,0,0)
Local $aFolder = _FileListToArray($sRoot , "*", 2), $sNETFolder = ''
For $i = $aFolder[0] To 1 Step -1
If StringRegExp($aFolder[$i], "v2\.0\.\d+", 0) Then
$sNETFolder = $aFolder[$i]
ExitLoop
EndIf
Next
If $sNETFolder = '' Then Return SetError(3,0,0)
$__RegAsmPath = $sRoot & $sNETFolder & "\RegAsm.exe"
If Not ShellExecuteWait($__RegAsmPath, _Iif($flag, "/codebase ", "/u ") & $DLL_File, @ScriptDir, "runas", @SW_HIDE) Then Return SetError(4,0,0)
Return 1
EndFunc
Func MyErrFunc()
If Not $hGUI Then Return
TrayTip("COM ERROR !!", "" & @CRLF & @CRLF & "err.description is: " & @TAB & $oMyError.description & @CRLF & "err.windescription:" & @TAB & $oMyError.windescription & @CRLF & "err.number is: " & @TAB & Hex($oMyError.number, 8) & @CRLF & "err.lastdllerror is: " & @TAB & $oMyError.lastdllerror & @CRLF & "err.scriptline is: " & @TAB & $oMyError.scriptline & @CRLF & "err.source is: " & @TAB & $oMyError.source & @CRLF & "err.helpfile is: " & @TAB & $oMyError.helpfile & @CRLF & "err.helpcontext is: " & @TAB & $oMyError.helpcontext, 3, 3 )
Local $err = $oMyError.number
If $err = 0 Then $err = -1
$g_eventerror = $err
EndFunc
Func _ReduceMemory($i_PID = -1)
If $i_PID <> -1 Then
Local $ai_Handle = DllCall("kernel32.dll", 'int', 'OpenProcess', 'int', 0x1f0fff, 'int', False, 'int', $i_PID)
Local $ai_Return = DllCall("psapi.dll", 'int', 'EmptyWorkingSet', 'long', $ai_Handle[0])
DllCall('kernel32.dll', 'int', 'CloseHandle', 'int', $ai_Handle[0])
Else
Local $ai_Return = DllCall("psapi.dll", 'int', 'EmptyWorkingSet', 'long', -1)
EndIf
Return $ai_Return[0]
EndFunc
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
GUICtrlSetBkColor(-1,$GUI_BKCOLOR_LV_ALTERNATE)
$IWndListView = GUICtrlGetHandle($ID3_lst)
_GUICtrlListView_SetUnicodeFormat(-1, True)
_GUICtrlListView_EnableGroupView($ID3_lst)
_GUICtrlListView_InsertGroup($ID3_lst, -1, 1, "ID3V2/ACC")
_GUICtrlListView_InsertGroup($ID3_lst, -1, 2, "ID3V1")
_GUICtrlListView_InsertGroup($ID3_lst, -1, 3, "ID3V2 More")
_GUICtrlListView_InsertColumn($ID3_lst, 0, "选择封面", 320, 0, 0)
_GUICtrlListView_InsertColumn($ID3_lst, 1, "缓存数据", 50)
_GUICtrlListView_InsertColumn($ID3_lst, 1, "写入标签", 50, 0, 1)
_GUICtrlListView_SetColumnOrder($ID3_lst, "1|0|2")
Local $item
For $ii = 0 To 7
$item = GUICtrlCreateListViewItem('|'&$ID3_v2_kword[$ii],$ID3_lst)
_GUICtrlListView_SetItemGroupID($ID3_lst,$ii,1)
GUICtrlSetBkColor($item, 0xEEEEEE)
Next
For $ii = 0 To 6
$item = GUICtrlCreateListViewItem('|'&$ID3_v2_kword[$ii],$ID3_lst)
_GUICtrlListView_SetItemGroupID($ID3_lst,8+$ii,2)
GUICtrlSetBkColor($item, 0xEEEEEE)
Next
For $ii = 0 To 10
$item = GUICtrlCreateListViewItem('|'&$ID3_v2_kword_Ex[$ii],$ID3_lst)
_GUICtrlListView_SetItemGroupID($ID3_lst,15+$ii,3)
GUICtrlSetBkColor($item, 0xEEEEEE)
Next
EndFunc
Func _Edit_ID3($Filename)
$FileDir=$Filename
_GUICtrlStatusBar_SetText($StatusBar , "Reading Tags...",1)
WinSetTitle($ID3_dial, '', '编辑ID3 - '&StringRegExpReplace($Filename,'.*\\',''))
_ID3ReadTag($Filename)
_GUICtrlListView_SetItemText($ID3_lst,0,_ID3GetTagField("TIT2"))
_GUICtrlListView_SetItemText($ID3_lst,1,_ID3GetTagField("TPE1"))
_GUICtrlListView_SetItemText($ID3_lst,2,_ID3GetTagField("TALB"))
_GUICtrlListView_SetItemText($ID3_lst,3,_ID3GetTagField("TCON"))
_GUICtrlListView_SetItemText($ID3_lst,4,_ID3GetTagField("TRCK"))
_GUICtrlListView_SetItemText($ID3_lst,5,_ID3GetTagField("TYER"))
_GUICtrlListView_SetItemText($ID3_lst,6,_ID3GetTagField("COMM"))
_GUICtrlListView_SetItemText($ID3_lst,8,_ID3GetTagField("Title"))
_GUICtrlListView_SetItemText($ID3_lst,9,_ID3GetTagField("Artist"))
_GUICtrlListView_SetItemText($ID3_lst,10,_ID3GetTagField("Album"))
_GUICtrlListView_SetItemText($ID3_lst,11,_ID3GetTagField("Genre"))
_GUICtrlListView_SetItemText($ID3_lst,12,_ID3GetTagField("Track"))
_GUICtrlListView_SetItemText($ID3_lst,13,_ID3GetTagField("Year"))
_GUICtrlListView_SetItemText($ID3_lst,14,_ID3GetTagField("Comment"))
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
_ID3SetTagField("Title",_GUICtrlListView_GetItemText($ID3_lst,8))
_ID3SetTagField("Artist",_GUICtrlListView_GetItemText($ID3_lst,9))
_ID3SetTagField("Album",_GUICtrlListView_GetItemText($ID3_lst,10))
_ID3SetTagField("Genre",_GUICtrlListView_GetItemText($ID3_lst,11))
_ID3SetTagField("Track",_GUICtrlListView_GetItemText($ID3_lst,12))
_ID3SetTagField("Year",_GUICtrlListView_GetItemText($ID3_lst,13))
_ID3SetTagField("Comment",_GUICtrlListView_GetItemText($ID3_lst,14))
If $cover_put<>$AlbumArtFile Then _ID3SetTagField("APIC",$cover_put)
_ID3WriteTag($FileDir)
Else
Local $foo=Run(@ScriptDir & "\AACTagReader.exe", @ScriptDir, @SW_HIDE, $STDOUT_CHILD)
StdinWrite($foo, StringToBinary(" -writetags "& StringMid(WinGetTitle($ID3_dial),13)&' '& StringFormat('name=%s artist=%s album=%s genre=%s track=%s composer=%s year=%s',  _GUICtrlListView_GetItemText($ID3_lst,0),_GUICtrlListView_GetItemText($ID3_lst,1),  _GUICtrlListView_GetItemText($ID3_lst,2),_GUICtrlListView_GetItemText($ID3_lst,3),  _GUICtrlListView_GetItemText($ID3_lst,4),_GUICtrlListView_GetItemText($ID3_lst,22),  _GUICtrlListView_GetItemText($ID3_lst,5)),4))
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
_GDIPlus_GraphicsDrawImageRect($hGraphic, $hImage, 0, 0, 182, 182)
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
For $i = $d_trans To 0 Step(-1)*$FadeOut
SetBitmap($dGUI, $hBmp, $i)
$tr=$i
Sleep(50)
Next
_WinAPI_DeleteObject($hBmp)
GUISetState(@SW_HIDE, $dGUI)
EndFunc
Func move_list($hWnd, $Msg, $iIDTimer, $dwTime)
Local $tm_show
Local $pos = _BASS_ChannelGetPosition($MusicHandle, $BASS_POS_BYTE)
If @error Then Return GUICtrlSetData($slider, 0)
$time_pos = Round(_BASS_ChannelBytes2Seconds($MusicHandle, $pos) * 1000, 0)
_TicksToTime($time_pos, $tm_show)
If GUICtrlRead($current_time)<>$tm_show Then
GUICtrlSetData($current_time, $tm_show)
GUICtrlSetData($slider, Int($time_pos / Round(_BASS_ChannelBytes2Seconds($MusicHandle, $length) * 1000, 0) * 100))
EndIf
If($pos>=$length And $length > 0) Or _BASS_ChannelIsActive($MusicHandle) = 0 Then
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
If $n = 0 And $time_pos>=$lrc_Show[0][0] Then
GUICtrlSetColor(_GUICtrlListView_GetItemParam($Lrc_List, 0), $lrc_text_front_color)
_GUICtrlListView_EnsureVisible($Lrc_List, 0)
$hBmp = _ImageDrawText($hImage1, $lrc_Show[0][1], 0,0, $font_color, $font_size, $font_var, $font_name)
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
$hBmp = _ImageDrawText($hImage1, 'Desk Lyrics', 230, 18, $font_color,16)
Else
$hBmp = _ImageDrawText($hImage1, $lrc_Show[$n-1][1], 0, 0, $font_color, $font_size, $font_var, $font_name)
EndIf
SetBitmap($dGUI, $hBmp, $tr)
_WinAPI_DeleteObject($hBmp)
EndFunc
Func _Stop()
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
_GUICtrlStatusBar_SetText($StatusBar , $temp_stat,1)
EndFunc
Func _ShowLoading()
_GUICtrlStatusBar_SetText($StatusBar , "加载中... 按Esc键退出",1)
_SendMessage(GUICtrlGetHandle($L_process), $PBM_SETMARQUEE, True, 100)
EndFunc
Func WM_NCHITTEST($hWnd, $iMsg, $iwParam, $ilParam)
If($hWnd = $dGUI) Or($hWnd = $lGUI) And($iMsg = $WM_NCHITTEST) Then Return $HTCAPTION
EndFunc
Func _ImageDrawText($hImage, $sText, $iX = 0, $iY = 0, $iRGB = 0x3f3e3c, $iSize = 9, $iStyle = 0, $sFont = "Arial")
Local $w, $h, $hGraphic1, $hBitmap, $hGraphic2, $hBrush, $hFormat, $hFamily, $hFont, $tLayout, $aInfo
$w = _GDIPlus_ImageGetWidth($hImage)
$h = _GDIPlus_ImageGetHeight($hImage)
$hGraphic1 = _GDIPlus_GraphicsCreateFromHWND(_WinAPI_GetDesktopWindow())
$hBitmap = _GDIPlus_BitmapCreateFromGraphics($w, $h, $hGraphic1)
$hGraphic2 = _GDIPlus_ImageGetGraphicsContext($hBitmap)
_GDIPlus_GraphicsDrawImageRect($hGraphic2, $hImage, 0, 0, $w, $h)
$hBrush = _GDIPlus_BrushCreateSolid("0xFF" & Hex($iRGB, 6))
$hFormat = _GDIPlus_StringFormatCreate()
$hFamily = _GDIPlus_FontFamilyCreate($sFont)
$hFont = _GDIPlus_FontCreate($hFamily, $iSize, $iStyle,2)
$tLayout = _GDIPlus_RectFCreate($iX, $iY, 0, 0)
$aInfo = _GDIPlus_GraphicsMeasureString($hGraphic2, $sText, $hFont, $tLayout, $hFormat)
$tLayout = _GDIPlus_RectFCreate(Floor($w / 2 -(DllStructGetData($aInfo[0], "Width") / 2)), Floor($h / 2 -(DllStructGetData($aInfo[0], "Height") / 2)), 0, 0)
$aInfo = _GDIPlus_GraphicsMeasureString($hGraphic2, $sText, $hFont, $tLayout, $hFormat)
_GDIPlus_GraphicsDrawStringEx($hGraphic2, $sText, $hFont, $aInfo[0], $hFormat, $hBrush)
_GDIPlus_FontDispose($hFont)
_GDIPlus_FontFamilyDispose($hFamily)
_GDIPlus_StringFormatDispose($hFormat)
_GDIPlus_BrushDispose($hBrush)
_GDIPlus_GraphicsDispose($hGraphic2)
_GDIPlus_GraphicsDispose($hGraphic1)
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
EndFunc
Global Const $INTERNET_DEFAULT_PORT = 0
Global Const $WINHTTP_FLAG_ESCAPE_DISABLE = 0x00000040
Global Const $WINHTTP_ACCESS_TYPE_NO_PROXY = 1
Global Const $WINHTTP_ACCESS_TYPE_NAMED_PROXY = 3
Global Const $WINHTTP_NO_PROXY_NAME = ""
Global Const $WINHTTP_NO_PROXY_BYPASS = ""
Global Const $WINHTTP_NO_REFERER = ""
Global Const $WINHTTP_DEFAULT_ACCEPT_TYPES = 0
Global Const $WINHTTP_NO_ADDITIONAL_HEADERS = ""
Global Const $WINHTTP_NO_REQUEST_DATA = ""
Global Const $WINHTTP_OPTION_CALLBACK = 1
Global Const $WINHTTP_OPTION_RESOLVE_TIMEOUT = 2
Global Const $WINHTTP_OPTION_CONNECT_TIMEOUT = 3
Global Const $WINHTTP_OPTION_CONNECT_RETRIES = 4
Global Const $WINHTTP_OPTION_SEND_TIMEOUT = 5
Global Const $WINHTTP_OPTION_RECEIVE_TIMEOUT = 6
Global Const $WINHTTP_OPTION_RECEIVE_RESPONSE_TIMEOUT = 7
Global Const $WINHTTP_OPTION_READ_BUFFER_SIZE = 12
Global Const $WINHTTP_OPTION_WRITE_BUFFER_SIZE = 13
Global Const $WINHTTP_OPTION_SECURITY_FLAGS = 31
Global Const $WINHTTP_OPTION_SECURITY_KEY_BITNESS = 36
Global Const $WINHTTP_OPTION_PROXY = 38
Global Const $WINHTTP_OPTION_USER_AGENT = 41
Global Const $WINHTTP_OPTION_CONTEXT_VALUE = 45
Global Const $WINHTTP_OPTION_CLIENT_CERT_CONTEXT = 47
Global Const $WINHTTP_OPTION_REQUEST_PRIORITY = 58
Global Const $WINHTTP_OPTION_HTTP_VERSION = 59
Global Const $WINHTTP_OPTION_DISABLE_FEATURE = 63
Global Const $WINHTTP_OPTION_CODEPAGE = 68
Global Const $WINHTTP_OPTION_MAX_CONNS_PER_SERVER = 73
Global Const $WINHTTP_OPTION_MAX_CONNS_PER_1_0_SERVER = 74
Global Const $WINHTTP_OPTION_AUTOLOGON_POLICY = 77
Global Const $WINHTTP_OPTION_ENABLE_FEATURE = 79
Global Const $WINHTTP_OPTION_WORKER_THREAD_COUNT = 80
Global Const $WINHTTP_OPTION_CONFIGURE_PASSPORT_AUTH = 83
Global Const $WINHTTP_OPTION_SECURE_PROTOCOLS = 84
Global Const $WINHTTP_OPTION_ENABLETRACING = 85
Global Const $WINHTTP_OPTION_PASSPORT_SIGN_OUT = 86
Global Const $WINHTTP_OPTION_REDIRECT_POLICY = 88
Global Const $WINHTTP_OPTION_MAX_HTTP_AUTOMATIC_REDIRECTS = 89
Global Const $WINHTTP_OPTION_MAX_HTTP_STATUS_CONTINUE = 90
Global Const $WINHTTP_OPTION_MAX_RESPONSE_HEADER_SIZE = 91
Global Const $WINHTTP_OPTION_MAX_RESPONSE_DRAIN_SIZE = 92
Global Const $WINHTTP_OPTION_SPN = 96
Global Const $WINHTTP_OPTION_GLOBAL_PROXY_CREDS = 97
Global Const $WINHTTP_OPTION_GLOBAL_SERVER_CREDS = 98
Global Const $WINHTTP_OPTION_REJECT_USERPWD_IN_URL = 100
Global Const $WINHTTP_OPTION_USE_GLOBAL_SERVER_CREDENTIALS = 101
Global Const $WINHTTP_OPTION_USERNAME = 0x1000
Global Const $WINHTTP_OPTION_PASSWORD = 0x1001
Global Const $WINHTTP_OPTION_PROXY_USERNAME = 0x1002
Global Const $WINHTTP_OPTION_PROXY_PASSWORD = 0x1003
Global Const $WINHTTP_AUTH_SCHEME_BASIC = 0x00000001
Global Const $WINHTTP_AUTH_TARGET_PROXY = 0x00000001
Global Const $hWINHTTPDLL__WINHTTP = DllOpen("winhttp.dll")
DllOpen("winhttp.dll")
Func _WinHttpCloseHandle($hInternet)
Local $aCall = DllCall($hWINHTTPDLL__WINHTTP, "bool", "WinHttpCloseHandle", "handle", $hInternet)
If @error Or Not $aCall[0] Then Return SetError(1, 0, 0)
Return 1
EndFunc
Func _WinHttpConnect($hSession, $sServerName, $iServerPort = Default)
__WinHttpDefault($iServerPort, $INTERNET_DEFAULT_PORT)
Local $aCall = DllCall($hWINHTTPDLL__WINHTTP, "handle", "WinHttpConnect", "handle", $hSession, "wstr", $sServerName, "dword", $iServerPort, "dword", 0)
If @error Or Not $aCall[0] Then Return SetError(1, 0, 0)
Return $aCall[0]
EndFunc
Func _WinHttpOpen($sUserAgent = Default, $iAccessType = Default, $sProxyName = Default, $sProxyBypass = Default, $iFlag = Default)
__WinHttpDefault($sUserAgent, "AutoIt/3.3")
__WinHttpDefault($iAccessType, $WINHTTP_ACCESS_TYPE_NO_PROXY)
__WinHttpDefault($sProxyName, $WINHTTP_NO_PROXY_NAME)
__WinHttpDefault($sProxyBypass, $WINHTTP_NO_PROXY_BYPASS)
__WinHttpDefault($iFlag, 0)
Local $aCall = DllCall($hWINHTTPDLL__WINHTTP, "handle", "WinHttpOpen", "wstr", $sUserAgent, "dword", $iAccessType, "wstr", $sProxyName, "wstr", $sProxyBypass, "dword", $iFlag)
If @error Or Not $aCall[0] Then Return SetError(1, 0, 0)
Return $aCall[0]
EndFunc
Func _WinHttpOpenRequest($hConnect, $sVerb = Default, $sObjectName = Default, $sVersion = Default, $sReferrer = Default, $sAcceptTypes = Default, $iFlags = Default)
__WinHttpDefault($sVerb, "GET")
__WinHttpDefault($sObjectName, "")
__WinHttpDefault($sVersion, "HTTP/1.1")
__WinHttpDefault($sReferrer, $WINHTTP_NO_REFERER)
__WinHttpDefault($iFlags, $WINHTTP_FLAG_ESCAPE_DISABLE)
Local $pAcceptTypes
If $sAcceptTypes = Default Or Number($sAcceptTypes) = -1 Then
$pAcceptTypes = $WINHTTP_DEFAULT_ACCEPT_TYPES
Else
Local $aTypes = StringSplit($sAcceptTypes, ",", 2)
Local $tAcceptTypes = DllStructCreate("ptr[" & UBound($aTypes) + 1 & "]")
Local $tType[UBound($aTypes)]
For $i = 0 To UBound($aTypes) - 1
$tType[$i] = DllStructCreate("wchar[" & StringLen($aTypes[$i]) + 1 & "]")
DllStructSetData($tType[$i], 1, $aTypes[$i])
DllStructSetData($tAcceptTypes, 1, DllStructGetPtr($tType[$i]), $i + 1)
Next
$pAcceptTypes = DllStructGetPtr($tAcceptTypes)
EndIf
Local $aCall = DllCall($hWINHTTPDLL__WINHTTP, "handle", "WinHttpOpenRequest", "handle", $hConnect, "wstr", StringUpper($sVerb), "wstr", $sObjectName, "wstr", StringUpper($sVersion), "wstr", $sReferrer, "ptr", $pAcceptTypes, "dword", $iFlags)
If @error Or Not $aCall[0] Then Return SetError(1, 0, 0)
Return $aCall[0]
EndFunc
Func _WinHttpQueryDataAvailable($hRequest)
Local $aCall = DllCall($hWINHTTPDLL__WINHTTP, "bool", "WinHttpQueryDataAvailable", "handle", $hRequest, "dword*", 0)
If @error Then Return SetError(1, 0, 0)
Return SetExtended($aCall[2], $aCall[0])
EndFunc
Func _WinHttpReadData($hRequest, $iMode = Default, $iNumberOfBytesToRead = Default, $pBuffer = Default)
__WinHttpDefault($iMode, 0)
__WinHttpDefault($iNumberOfBytesToRead, 8192)
Local $tBuffer
Switch $iMode
Case 1, 2
If $pBuffer And $pBuffer <> Default Then
$tBuffer = DllStructCreate("byte[" & $iNumberOfBytesToRead & "]", $pBuffer)
Else
$tBuffer = DllStructCreate("byte[" & $iNumberOfBytesToRead & "]")
EndIf
Case Else
$iMode = 0
If $pBuffer And $pBuffer <> Default Then
$tBuffer = DllStructCreate("char[" & $iNumberOfBytesToRead & "]", $pBuffer)
Else
$tBuffer = DllStructCreate("char[" & $iNumberOfBytesToRead & "]")
EndIf
EndSwitch
Local $aCall = DllCall($hWINHTTPDLL__WINHTTP, "bool", "WinHttpReadData", "handle", $hRequest, "ptr", DllStructGetPtr($tBuffer), "dword", $iNumberOfBytesToRead, "dword*", 0)
If @error Or Not $aCall[0] Then Return SetError(1, 0, "")
If Not $aCall[4] Then Return SetError(-1, 0, "")
If $aCall[4] < $iNumberOfBytesToRead Then
Switch $iMode
Case 0
Return SetExtended($aCall[4], StringLeft(DllStructGetData($tBuffer, 1), $aCall[4]))
Case 1
Return SetExtended($aCall[4], BinaryToString(BinaryMid(DllStructGetData($tBuffer, 1), 1, $aCall[4]), 4))
Case 2
Return SetExtended($aCall[4], BinaryMid(DllStructGetData($tBuffer, 1), 1, $aCall[4]))
EndSwitch
Else
Switch $iMode
Case 0, 2
Return SetExtended($aCall[4], DllStructGetData($tBuffer, 1))
Case 1
Return SetExtended($aCall[4], BinaryToString(DllStructGetData($tBuffer, 1), 4))
EndSwitch
EndIf
EndFunc
Func _WinHttpReceiveResponse($hRequest)
Local $aCall = DllCall($hWINHTTPDLL__WINHTTP, "bool", "WinHttpReceiveResponse", "handle", $hRequest, "ptr", 0)
If @error Or Not $aCall[0] Then Return SetError(1, 0, 0)
Return 1
EndFunc
Func _WinHttpSendRequest($hRequest, $sHeaders = Default, $sOptional = Default, $iTotalLength = Default, $iContext = Default)
__WinHttpDefault($sHeaders, $WINHTTP_NO_ADDITIONAL_HEADERS)
__WinHttpDefault($sOptional, $WINHTTP_NO_REQUEST_DATA)
__WinHttpDefault($iTotalLength, 0)
__WinHttpDefault($iContext, 0)
Local $pOptional = 0, $iOptionalLength = 0
If @NumParams > 2 Then
Local $tOptional
$iOptionalLength = BinaryLen($sOptional)
$tOptional = DllStructCreate("byte[" & $iOptionalLength & "]")
If $iOptionalLength Then $pOptional = DllStructGetPtr($tOptional)
DllStructSetData($tOptional, 1, $sOptional)
EndIf
If Not $iTotalLength Or $iTotalLength < $iOptionalLength Then $iTotalLength += $iOptionalLength
Local $aCall = DllCall($hWINHTTPDLL__WINHTTP, "bool", "WinHttpSendRequest", "handle", $hRequest, "wstr", $sHeaders, "dword", 0, "ptr", $pOptional, "dword", $iOptionalLength, "dword", $iTotalLength, "dword_ptr", $iContext)
If @error Or Not $aCall[0] Then Return SetError(1, 0, 0)
Return 1
EndFunc
Func _WinHttpSetCredentials($hRequest, $iAuthTargets, $iAuthScheme, $sUserName, $sPassword)
Local $aCall = DllCall($hWINHTTPDLL__WINHTTP, "bool", "WinHttpSetCredentials", "handle", $hRequest, "dword", $iAuthTargets, "dword", $iAuthScheme, "wstr", $sUserName, "wstr", $sPassword, "ptr", 0)
If @error Or Not $aCall[0] Then Return SetError(1, 0, 0)
Return 1
EndFunc
Func _WinHttpSetOption($hInternet, $iOption, $vSetting, $iSize = Default)
If $iSize = Default Then $iSize = -1
If IsBinary($vSetting) Then
$iSize = DllStructCreate("byte[" & BinaryLen($vSetting) & "]")
DllStructSetData($iSize, 1, $vSetting)
$vSetting = $iSize
$iSize = DllStructGetSize($vSetting)
EndIf
Local $sType
Switch $iOption
Case $WINHTTP_OPTION_AUTOLOGON_POLICY, $WINHTTP_OPTION_CODEPAGE, $WINHTTP_OPTION_CONFIGURE_PASSPORT_AUTH, $WINHTTP_OPTION_CONNECT_RETRIES, $WINHTTP_OPTION_CONNECT_TIMEOUT, $WINHTTP_OPTION_DISABLE_FEATURE, $WINHTTP_OPTION_ENABLE_FEATURE, $WINHTTP_OPTION_ENABLETRACING, $WINHTTP_OPTION_MAX_CONNS_PER_1_0_SERVER, $WINHTTP_OPTION_MAX_CONNS_PER_SERVER, $WINHTTP_OPTION_MAX_HTTP_AUTOMATIC_REDIRECTS, $WINHTTP_OPTION_MAX_HTTP_STATUS_CONTINUE, $WINHTTP_OPTION_MAX_RESPONSE_DRAIN_SIZE, $WINHTTP_OPTION_MAX_RESPONSE_HEADER_SIZE, $WINHTTP_OPTION_READ_BUFFER_SIZE, $WINHTTP_OPTION_RECEIVE_TIMEOUT, $WINHTTP_OPTION_RECEIVE_RESPONSE_TIMEOUT, $WINHTTP_OPTION_REDIRECT_POLICY, $WINHTTP_OPTION_REJECT_USERPWD_IN_URL, $WINHTTP_OPTION_REQUEST_PRIORITY, $WINHTTP_OPTION_RESOLVE_TIMEOUT, $WINHTTP_OPTION_SECURE_PROTOCOLS, $WINHTTP_OPTION_SECURITY_FLAGS, $WINHTTP_OPTION_SECURITY_KEY_BITNESS, $WINHTTP_OPTION_SEND_TIMEOUT, $WINHTTP_OPTION_SPN, $WINHTTP_OPTION_USE_GLOBAL_SERVER_CREDENTIALS, $WINHTTP_OPTION_WORKER_THREAD_COUNT, $WINHTTP_OPTION_WRITE_BUFFER_SIZE
$sType = "dword*"
$iSize = 4
Case $WINHTTP_OPTION_CALLBACK, $WINHTTP_OPTION_PASSPORT_SIGN_OUT
$sType = "ptr*"
$iSize = 4
If @AutoItX64 Then $iSize = 8
If Not IsPtr($vSetting) Then Return SetError(3, 0, 0)
Case $WINHTTP_OPTION_CONTEXT_VALUE
$sType = "dword_ptr"
$iSize = 4
If @AutoItX64 Then $iSize = 8
Case $WINHTTP_OPTION_PASSWORD, $WINHTTP_OPTION_PROXY_PASSWORD, $WINHTTP_OPTION_PROXY_USERNAME, $WINHTTP_OPTION_USER_AGENT, $WINHTTP_OPTION_USERNAME
$sType = "wstr"
If(IsDllStruct($vSetting) Or IsPtr($vSetting)) Then Return SetError(3, 0, 0)
If $iSize < 1 Then $iSize = StringLen($vSetting)
Case $WINHTTP_OPTION_CLIENT_CERT_CONTEXT, $WINHTTP_OPTION_GLOBAL_PROXY_CREDS, $WINHTTP_OPTION_GLOBAL_SERVER_CREDS, $WINHTTP_OPTION_HTTP_VERSION, $WINHTTP_OPTION_PROXY
$sType = "ptr"
If Not(IsDllStruct($vSetting) Or IsPtr($vSetting)) Then Return SetError(3, 0, 0)
Case Else
Return SetError(1, 0, 0)
EndSwitch
If $iSize < 1 Then
If IsDllStruct($vSetting) Then
$iSize = DllStructGetSize($vSetting)
Else
Return SetError(2, 0, 0)
EndIf
EndIf
Local $aCall
If IsDllStruct($vSetting) Then
$aCall = DllCall($hWINHTTPDLL__WINHTTP, "bool", "WinHttpSetOption", "handle", $hInternet, "dword", $iOption, $sType, DllStructGetPtr($vSetting), "dword", $iSize)
Else
$aCall = DllCall($hWINHTTPDLL__WINHTTP, "bool", "WinHttpSetOption", "handle", $hInternet, "dword", $iOption, $sType, $vSetting, "dword", $iSize)
EndIf
If @error Or Not $aCall[0] Then Return SetError(4, 0, 0)
Return 1
EndFunc
Func _WinHttpSetTimeouts($hInternet, $iResolveTimeout = Default, $iConnectTimeout = Default, $iSendTimeout = Default, $iReceiveTimeout = Default)
__WinHttpDefault($iResolveTimeout, 0)
__WinHttpDefault($iConnectTimeout, 60000)
__WinHttpDefault($iSendTimeout, 30000)
__WinHttpDefault($iReceiveTimeout, 30000)
Local $aCall = DllCall($hWINHTTPDLL__WINHTTP, "bool", "WinHttpSetTimeouts", "handle", $hInternet, "int", $iResolveTimeout, "int", $iConnectTimeout, "int", $iSendTimeout, "int", $iReceiveTimeout)
If @error Or Not $aCall[0] Then Return SetError(1, 0, 0)
Return 1
EndFunc
Func _WinHttpSimpleReadData($hRequest, $iMode = Default)
__WinHttpDefault($iMode, 0)
If $iMode > 2 Or $iMode < 0 Then Return SetError(1, 0, '')
Local $vData = ''
If $iMode = 2 Then $vData = Binary('')
If _WinHttpQueryDataAvailable($hRequest) Then
If $iMode = 0 Then
Do
$vData &= _WinHttpReadData($hRequest, 0)
Until @error
Return $vData
Else
$vData = Binary('')
Do
$vData &= _WinHttpReadData($hRequest, 2)
Until @error
If $iMode = 1 Then Return BinaryToString($vData, 4)
Return $vData
EndIf
EndIf
Return SetError(2, 0, $vData)
EndFunc
Func __WinHttpDefault(ByRef $vInput, $vOutput)
If $vInput = Default Or Number($vInput) = -1 Then $vInput = $vOutput
EndFunc
Global $_MD5Opcode = '0xC85800005356576A006A006A008D45A850E8280000006A00FF750CFF75088D45A850E8440000006A006A008D45A850FF7510E8710700005F5E5BC9C210005589E58B4D0831C0894114894110C70101234567C7410489ABCDEFC74108FEDCBA98C7410C765432105DC21000C80C0000538B5D088B4310C1E80383E03F8945F88B4510C1E0030143103943107303FF43148B4510C1E81D0143146A40582B45F88945F4394510724550FF750C8B45F88D44031850E8A00700008D43185053E84E0000008B45F48945FC8B45FC83C03F39451076138B450C0345FC5053E8300000008345FC40EBE28365F800EB048365FC008B45102B45FC508B450C0345FC508B45F88D44031850E84D0700005BC9C21000C84000005356576A40FF750C8D45C050E8330700008B45088B088B50048B70088B780C89D021F089D3F7D321FB09D801C1034DC081C178A46AD7C1C10701D189C821D089CBF7D321F309D801C7037DC481C756B7C7E8C1C70C01CF89F821C889FBF7D321D309D801C60375C881C6DB702024C1C61101FE89F021F889F3F7D321CB09D801C20355CC81C2EECEBDC1C1C21601F289D021F089D3F7D321FB09D801C1034DD081C1AF0F7CF5C1C10701D189C821D089CBF7D321F309D801C7037DD481C72AC68747C1C70C01CF89F821C889FBF7D321D309D801C60375D881C6134630A8C1C61101FE89F021F889F3F7D321CB09D801C20355DC81C2019546FDC1C21601F289D021F089D3F7D321FB09D801C1034DE081C1D8988069C1C10701D189C821D089CBF7D321F309D801C7037DE481C7AFF7448BC1C70C01CF89F821C889FBF7D321D309D801C60375E881C6B15BFFFFC1C61101FE89F021F889F3F7D321CB09D801C20355EC81C2BED75C89C1C21601F289D021F089D3F7D321FB09D801C1034DF081C12211906BC1C10701D189C821D089CBF7D321F309D801C7037DF481C7937198FDC1C70C01CF89F821C889FBF7D321D309D801C60375F881C68E4379A6C1C61101FE89F021F889F3F7D321CB09D801C20355FC81C22108B449C1C21601F289D021F889FBF7D321F309D801C1034DC481C162251EF6C1C10501D189C821F089F3F7D321D309D801C7037DD881C740B340C0C1C70901CF89F821D089D3F7D321CB09D801C60375EC81C6515A5E26C1C60E01FE89F021C889CBF7D321FB09D801C20355C081C2AAC7B6E9C1C21401F289D021F889FBF7D321F309D801C1034DD481C15D102FD6C1C10501D189C821F089F3F7D321D309D801C7037DE881C753144402C1C70901CF89F821D089D3F7D321CB09D801C60375FC81C681E6A1D8C1C60E01FE89F021C889CBF7D321FB09D801C20355D081C2C8FBD3E7C1C21401F289D021F889FBF7D321F309D801C1034DE481C1E6CDE121C1C10501D189C821F089F3F7D321D309D801C7037D'
$_MD5Opcode &= 'F881C7D60737C3C1C70901CF89F821D089D3F7D321CB09D801C60375CC81C6870DD5F4C1C60E01FE89F021C889CBF7D321FB09D801C20355E081C2ED145A45C1C21401F289D021F889FBF7D321F309D801C1034DF481C105E9E3A9C1C10501D189C821F089F3F7D321D309D801C7037DC881C7F8A3EFFCC1C70901CF89F821D089D3F7D321CB09D801C60375DC81C6D9026F67C1C60E01FE89F021C889CBF7D321FB09D801C20355F081C28A4C2A8DC1C21401F289D031F031F801C1034DD481C14239FAFFC1C10401D189C831D031F001C7037DE081C781F67187C1C70B01CF89F831C831D001C60375EC81C622619D6DC1C61001FE89F031F831C801C20355F881C20C38E5FDC1C21701F289D031F031F801C1034DC481C144EABEA4C1C10401D189C831D031F001C7037DD081C7A9CFDE4BC1C70B01CF89F831C831D001C60375DC81C6604BBBF6C1C61001FE89F031F831C801C20355E881C270BCBFBEC1C21701F289D031F031F801C1034DF481C1C67E9B28C1C10401D189C831D031F001C7037DC081C7FA27A1EAC1C70B01CF89F831C831D001C60375CC81C68530EFD4C1C61001FE89F031F831C801C20355D881C2051D8804C1C21701F289D031F031F801C1034DE481C139D0D4D9C1C10401D189C831D031F001C7037DF081C7E599DBE6C1C70B01CF89F831C831D001C60375FC81C6F87CA21FC1C61001FE89F031F831C801C20355C881C26556ACC4C1C21701F289F8F7D009D031F001C1034DC081C1442229F4C1C10601D189F0F7D009C831D001C7037DDC81C797FF2A43C1C70A01CF89D0F7D009F831C801C60375F881C6A72394ABC1C60F01FE89C8F7D009F031F801C20355D481C239A093FCC1C21501F289F8F7D009D031F001C1034DF081C1C3595B65C1C10601D189F0F7D009C831D001C7037DCC81C792CC0C8FC1C70A01CF89D0F7D009F831C801C60375E881C67DF4EFFFC1C60F01FE89C8F7D009F031F801C20355C481C2D15D8485C1C21501F289F8F7D009D031F001C1034DE081C14F7EA86FC1C10601D189F0F7D009C831D001C7037DFC81C7E0E62CFEC1C70A01CF89D0F7D009F831C801C60375D881C6144301A3C1C60F01FE89C8F7D009F031F801C20355F481C2A111084EC1C21501F289F8F7D009D031F001C1034DD081C1827E53F7C1C10601D189F0F7D009C831D001C7037DEC81C735F23ABDC1C70A01CF89D0F7D009F831C801C60375C881C6BBD2D72AC1C60F01FE89C8F7D009F031F801C20355E481C291D386EBC1C21501F28B4508010801500401700801780C5F5E5BC9C20800C814000053E840000000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008F45EC8B5D0C6A088D4310508D'
$_MD5Opcode &= '45F850E8510000008B4310C1E80383E03F8945F483F838730B6A38582B45F48945F0EB096A78582B45F48945F0FF75F0FF75ECFF750CE831F8FFFF6A088D45F850FF750CE823F8FFFF6A1053FF7508E8050000005BC9C210005589E55156578B7D088B750C8B4D10FCF3A45F5E595DC20C00'
Global $_MD5CodeBuffer='',$_SHA1CodeBuffer='',$CodeBuffer
If @AutoItX64 Then
MsgBox(32,"ACN_HASH","此加密函数不能用于64位AutoIt版本,请编译为32位版本.",5)
Exit
EndIf
Func _MD5Init()
If Not IsDeclared("_MD5CodeBuffer") Or Not IsDllStruct($_MD5CodeBuffer) Then
Global $_MD5CodeBuffer = DllStructCreate("byte[" & BinaryLen($_MD5Opcode) & "]")
DllStructSetData($_MD5CodeBuffer, 1, $_MD5Opcode)
EndIf
Local $OpcodeStart = 62
Local $MD5CTX = DllStructCreate("dword[22]")
DllCall("user32.dll", "none", "CallWindowProc", "ptr", DllStructGetPtr($_MD5CodeBuffer) + $OpcodeStart, "ptr", DllStructGetPtr($MD5CTX), "int", 0, "int", 0, "int", 0)
$CodeBuffer = 0
Return $MD5CTX
EndFunc
Func _MD5Input(ByRef $MD5CTX, $Data)
If Not IsDeclared("_MD5CodeBuffer") Or Not IsDllStruct($_MD5CodeBuffer) Then Return
Local $OpcodeStart = 107
Local $Input = DllStructCreate("byte[" & BinaryLen($Data) & "]")
DllStructSetData($Input, 1, $Data)
DllCall("user32.dll", "none", "CallWindowProc", "ptr", DllStructGetPtr($_MD5CodeBuffer) + $OpcodeStart, "ptr", DllStructGetPtr($MD5CTX), "ptr", DllStructGetPtr($Input), "int", BinaryLen($Data), "int", 0)
$Input = 0
EndFunc
Func _MD5Result(ByRef $MD5CTX)
If Not IsDeclared("_MD5CodeBuffer") Or Not IsDllStruct($_MD5CodeBuffer) Then Return Binary(0)
Local $OpcodeStart = 1960
Local $Digest = DllStructCreate("byte[16]")
DllCall("user32.dll", "none", "CallWindowProc", "ptr", DllStructGetPtr($_MD5CodeBuffer) + $OpcodeStart, "ptr", DllStructGetPtr($Digest), "ptr", DllStructGetPtr($MD5CTX), "int", 0, "int", 0)
Local $Ret = DllStructGetData($Digest, 1)
$CodeBuffer = 0
$Digest = 0
$MD5CTX = 0
$_MD5CodeBuffer = 0
Return $Ret
EndFunc
Global $gar_msgQueue[1]
Global $gi_CoProcParent = 0
Global $gs_CoProcReciverFunction = ""
Func _CoProc($sFunction = Default, $vParameter = Default)
Local $iPid, $iOldRunErrorsFatal
If IsKeyword($sFunction) Or $sFunction = "" Then $sFunction = "__CoProcDummy"
EnvSet("CoProc", "0x" & Hex(StringToBinary($sFunction)))
EnvSet("CoProcParent", @AutoItPID)
If Not IsKeyword($vParameter) Then
EnvSet("CoProcParameterPresent", "True")
EnvSet("CoProcParameter", StringToBinary($vParameter))
Else
EnvSet("CoProcParameterPresent", "False")
EndIf
If @Compiled Then
$iPid = Run(FileGetShortName(@AutoItExe), @WorkingDir, @SW_HIDE, 1 + 2 + 4)
Else
$iPid = Run(FileGetShortName(@AutoItExe) & ' "' & @ScriptFullPath & '"', @WorkingDir, @SW_HIDE, 1 + 2 + 4)
EndIf
If @error Then SetError(1)
Return $iPid
EndFunc
Func _ProcessGetWinList($vProcess, $sTitle = Default, $iOption = 0)
Local $aWinList, $iCnt, $aTmp, $aResult[1], $iPid, $fMatch, $sClassname
$iPid = ProcessExists($vProcess)
If Not $iPid Then Return SetError(1)
If $sTitle = "" Or IsKeyword($sTitle) Then
$aWinList = WinList()
Else
$aWinList = WinList($sTitle)
EndIf
For $iCnt = 1 To $aWinList[0][0]
$hWnd = $aWinList[$iCnt][1]
$iProcessId = WinGetProcess($hWnd)
If $iProcessId = $iPid Then
If $iOption = 0 Or IsKeyword($iOption) Or $iOption = 16 Then
$fMatch = True
Else
$fMatch = False
$sClassname = DllCall("user32.dll", "int", "GetClassName", "hwnd", $hWnd, "str", "", "int", 1024)
If @error Then Return SetError(3)
If $sClassname[0] = 0 Then Return SetError(3)
$sClassname = $sClassname[2]
If BitAND($iOption, 2) Then
If $sClassname = "AutoIt v3 GUI" Then $fMatch = True
EndIf
If BitAND($iOption, 4) Then
If $sClassname = "AutoIt v3" Then $fMatch = True
EndIf
EndIf
If $fMatch Then
If BitAND($iOption, 16) Then Return $hWnd
ReDim $aResult[UBound($aResult) + 1]
$aResult[UBound($aResult) - 1] = $hWnd
EndIf
EndIf
Next
$aResult[0] = UBound($aResult) - 1
If $aResult[0] < 1 Then Return SetError(2, 0, 0)
Return $aResult
EndFunc
Func _CoProcReciver($sFunction = Default)
Local $sHandlerFuction = "__CoProcReciverHandler", $hWnd, $aTmp
If IsKeyword($sFunction) Then $sFunction = ""
$hWnd = _ProcessGetWinList(@AutoItPID, "", 16 + 2)
If Not IsHWnd($hWnd) Then
$hWnd = GUICreate("CoProcEventReciver")
If @error Then Return SetError(1, 0, False)
EndIf
If $sFunction = "" Or IsKeyword($sFunction) Then $sHandlerFuction = ""
If Not GUIRegisterMsg(0x4A, $sHandlerFuction) Then Return SetError(2, 0, False)
If Not GUIRegisterMsg(0x400 + 0x64, $sHandlerFuction) Then Return SetError(2, 0, False)
$gs_CoProcReciverFunction = $sFunction
Return True
EndFunc
Func __CoProcReciverHandler($hWnd, $iMsg, $WParam, $LParam)
If $iMsg = 0x4A Then
Local $COPYDATA, $MyData
$COPYDATA = DllStructCreate("ptr;dword;ptr", $LParam)
$MyData = DllStructCreate("char[" & DllStructGetData($COPYDATA, 2) & "]", DllStructGetData($COPYDATA, 3))
$msgParameter = DllStructGetData($MyData, 1)
_ArrayAdd($gar_msgQueue, $msgParameter)
Return 256
ElseIf $iMsg = 0x400 + 0x64 Then
If UBound($gar_msgQueue)>1 Then
$msgParameter = _ArrayPop($gar_msgQueue)
Call($gs_CoProcReciverFunction, $msgParameter)
If @error And @Compiled = 0 Then MsgBox(16, "CoProc Error", "Unable to Call: " & $gs_CoProcReciverFunction)
$msgParameter = 0
Return 0
EndIf
EndIf
EndFunc
Func _CoProcSend($vProcess, $vParameter, $iTimeout = 500, $fAbortIfHung = True)
Local $iPid, $hWndTarget, $MyData, $aTmp, $COPYDATA, $iFuFlags
$iPid = ProcessExists($vProcess)
If Not $iPid Then Return SetError(1, 0, False)
$hWndTarget = _ProcessGetWinList($vProcess, "", 16 + 2)
If @error Or(Not $hWndTarget) Then Return SetError(2, 0, False)
$MyData = DllStructCreate("char[" & StringLen($vParameter) + 1 & "]")
$COPYDATA = DllStructCreate("ptr;dword;ptr")
DllStructSetData($MyData, 1, $vParameter)
DllStructSetData($COPYDATA, 1, 1)
DllStructSetData($COPYDATA, 2, DllStructGetSize($MyData))
DllStructSetData($COPYDATA, 3, DllStructGetPtr($MyData))
If $fAbortIfHung Then
$iFuFlags = 0x2
Else
$iFuFlags = 0x0
EndIf
$aTmp = DllCall("user32.dll", "int", "SendMessageTimeout", "hwnd", $hWndTarget, "int", 0x4A , "int", 0, "ptr", DllStructGetPtr($COPYDATA), "int", $iFuFlags, "int", $iTimeout, "long*", 0)
If @error Then Return SetError(3, 0, False)
If Not $aTmp[0] Then Return SetError(3, 0, False)
If $aTmp[7] <> 256 Then Return SetError(3, 0, False)
$aTmp = DllCall("user32.dll", "int", "PostMessage", "hwnd", $hWndTarget, "int", 0x400 + 0x64, "int", 0, "int", 0)
If @error Then Return SetError(4, 0, False)
If Not $aTmp[0] Then Return SetError(4, 0, False)
Return True
EndFunc
Func __CoProcStartup()
Local $sCmd = EnvGet("CoProc")
If StringLeft($sCmd, 2) = "0x" Then
$sCmd = BinaryToString($sCmd)
$gi_CoProcParent = Number(EnvGet("CoProcParent"))
If StringInStr($sCmd, "(") And StringInStr($sCmd, ")") Then
Execute($sCmd)
If @error And Not @Compiled Then MsgBox(16, "CoProc Error", "Unable to Execute: " & $sCmd)
Exit
EndIf
If EnvGet("CoProcParameterPresent") = "True" Then
Call($sCmd, BinaryToString(EnvGet("CoProcParameter")))
If @error And Not @Compiled Then MsgBox(16, "CoProc Error", "Unable to Call: " & $sCmd & @LF & "Parameter: " & BinaryToString(EnvGet("CoProcParameter")))
Else
Call($sCmd)
If @error And Not @Compiled Then MsgBox(16, "CoProc Error", "Unable to Call: " & $sCmd)
EndIf
Exit
EndIf
EndFunc
Func __CoProcDummy($vPar = Default)
If Not IsKeyword($vPar) Then _CoProcReciver($vPar)
While ProcessExists($gi_CoProcParent)
Sleep(500)
WEnd
EndFunc
__CoProcStartup()
Global $_ZLIB_CodeBuffer, $_ZLIB_CodeBufferMemory, $_ZLIB_CodeBufferPtr
Global $_ZLIB_Alloc_Callback, $_ZLIB_Free_Callback
Global $_ZLIB_DeflateInit, $_ZLIB_DeflateInit2, $_ZLIB_Deflate, $_ZLIB_DeflateEnd, $_ZLIB_DeflateBound
Global $_ZLIB_InflateInit, $_ZLIB_InflateInit2, $_ZLIB_Inflate, $_ZLIB_InflateEnd
Global $_ZLIB_ZError
Global Const $_ZLIB_tagZStream = "ptr next_in;uint avail_in;uint total_in;ptr next_out;uint avail_out;uint total_out;ptr msg;ptr state;ptr zalloc;ptr zfree;ptr opaque;int data_type;uint adler;uint reserved"
Global Const $_ZLIB_USER32DLL = DllOpen("user32.dll")
Global Const $Z_NO_FLUSH = 0
Global Const $Z_NEED_DICT = 2
Global Const $Z_DATA_ERROR = -3
Global Const $Z_MAX_WBITS = 15
Func _ZLIB_Alloc($OPAQUE, $Items, $Size)
Return _MemGlobalAlloc($Items * $Size, $GPTR)
EndFunc
Func _ZLIB_Free($OPAQUE, $Addr)
_MemGlobalFree($Addr)
EndFunc
Func _ZLIB_Exit()
$_ZLIB_CodeBuffer = 0
_MemVirtualFree($_ZLIB_CodeBufferMemory, 0, $MEM_RELEASE)
DllCallbackFree($_ZLIB_Alloc_Callback)
DllCallbackFree($_ZLIB_Free_Callback)
EndFunc
Func _ZLIB_Startup()
If Not IsDllStruct($_ZLIB_CodeBuffer) Then
Local $Code
If @AutoItX64 Then
Else
$Code = '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'
$Code &= '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'
$Code &= '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'
$Code &= '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'
$Code &= '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'
$Code &= '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'
$Code &= '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'
$Code &= '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'
$Code &= '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'
$Code &= 'CgVBH4nI6zTSK0QnusZ4MhSHlAYY/46Xqc5c90jRAoMCKYZ0j6FOinyyqKdI+0oE7VBLmSnQ+MMl0fvwLBN8EVPBVF7sAktfDHYjfVHv6wbXBoQp+IzvR27UnvmXFUiJFBtqAWTRjmAjrW1xUgELg8roAZadka2OQQaJnN6IOBN5hA1Elx20HQMSn8TNQb+PipQeCd2MTcYRgzjKMO3SM3MDCtECRf7CiJQOiRnYQ6YlzguftH2KQYhsSOgloev5MiPshw+NQv0DFHMRmwYoli+yrCmJlM2i8EVAOAEKjZY8xkK8/dNSpXjwzWgcKWZ+fxToAe7hiigSiIgJQu/tD4mGsLfh/aB6DLhLEiEEKeAFC9BYQSABOwLljn4KJ3VsMBGERMJUeQLIM5bERgX43zAxTAH+pTIQOjjfwsj9cTDp6EDl+AN9ApWNTEARAUbvsLBTSA2ZQgJaDyMDS0wvW4hy/2nUipMUp22lnXhmiEs6QyDu8SspYCyWSmUGhQMCnuh2+3Uay1AANVUUy6HsKa3JEG5z22RT/Ckaoxy6AieS1XZ4IS2tCMO6xEqnKcUBcKNA5jKGqFK/TErKCoXrCVKUo2HTEoyjApKgakenavAx/5WXWJIJsk6F6Ju8dUJsdpb0QynKOVwLk/oJDrjlFPXkLYMb7ehZjVn2Au4eQrAX6LnSoV5ZcZEHShAO/+KclR0l+WonWMa3KRiGxYQr4FcUx0X8CDB+MD6DfzAsAjLo5feyFHtHsHtDGBBm+kyTSk9MUY1aGTuEvdHYPPwSltagRI6iABvCCvafI+oDq+mcoHY5C9F3B+sDFEsF48qpQwT50PkbLhMK8W4D3H2YV1NQsN0o2fxKDBDpTgF5vl6IkM4PhLXbD3QlEK1lPTBfjVcEkZ0UUvUl0GJvVDJEhmhGiQEPeoFOFz8ohk0zU0DBCXTqg8AEpYZill6DclQc2lT5MfIoCxKW5J0AQFBBUUJS6K9c74qEiAlWYq9RSAKY8qTCFRTpjK2xRwIdKmvf2jJWa1nzG9GtxeiZ1fAGoQzcDYmRBw1HnX9EjuUWsLAHoRX3OiwTVx5WU4MHJItUNzhHTHc8g0J42pqQvTnYzxY0x1p8GQG86wJL0OMQDAnDiRxOglKQ2Q9adDnDfAKJJyRcXL0Pcjg/+7sEg2psjXw1h76e3yDB+PfYg+BDj0TbFAmILC0GIM0pxX8CNjHtuyuhmMaDYwgPtx9bf4fCUzj/BxMMi3pANxRw6xoh0d8mR0856WWG/S4QgepvgISI1Kx4iUR4SAzYdd2LigTcGswBOxAQ/M9liWyLJoH1NwHON/G6+P4kmrw3OAjzcrQwgAeLBDIz5jpQdZBE8evPTz+9JwdwHf7pO+txwKm3rzCMBhQCn+DELAHw0tpqVgBOKfg9AsR5fUyNHQOjHBn4fxPXCEmrCbKk8qolyjCoBthOhkpwRCJ9LVIE45Hcb1uRyCFMmcfQW1poY1vKGypTQX9DOcToW15fTl3nqAAgZGVmbGF06+J3EzTwQ29wA3lyaWdodDggOf8dLTIw+XoPSmVhbkFsb3Vw6UflaePLeb4ee2R7TTxya7xBf53CznkcA1BT6DQxD4mseAidD0N/lKkJCDIUBiAELMIdDIQOOAhEGVAGXAJoAnRbiYbUkfAaWoEEmAUICVNbogxXr8vUDMkGVGY5Uwx+2DEERl62Kr1VGBgMgOHKOSAVGt8ZKgoTlAQMmxQhGRAtGsjGn3tXF9+F0ggH1UJyHN4olMoLWEKZFr8ITloYGbYYsxYSXgHA2n4EKv6Fa6Qf2CxcFGFQZTCwGSdF00TiPolBYHeD+wNyYH5wLDnLdg8Gic8pyQGA9lY4V1Cw3Taqrk0WwTZYiX5slgZcFJucFkZIGG4QSgEeMcgj01THeIfSU8f9cy1MfRI7fm5X3xg4QEQQfgIlXkDByE4wrvjZUzY0k0lmAoJBIdfY2mx7MFZGZ0QUFHJCO4LadsXAiDHAn2TyyRK4rrhfJ9lPRAigGxnuQGAcDxKDeBgnAnXYXeaJLUgcUo6i'
$Code &= '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'
$Code &= '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'
$Code &= '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'
$Code &= '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'
$Code &= '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'
$Code &= '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'
$Code &= '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'
$Code &= 'urYpAynKidFAOxp4csaRfUDkCl1Jw2bIV0TKInvWN0e/CL3kaHWAYn88CFtzgi37/zoYQO4fViZ0T5IEPInBuXIGZzgpyMJfx9V98a8gTPgkCHLgA3c4ileft+ixiFQN/MHu7kFoiSIcQXPnjeFoIZDWYSrHaEWF6Cj/zGuLWEsKKjMbMOgWJQFDCHMpdgRIA/R40DuDPmhIuhBeX6fYDlMUVxMZBWOs5Y2h705OuDwnXpk/X3+dzH7ay1ZsIyECGoM4DVVAtXg8oeAJLGCQJV6KMslRXSLZU1ZCDuqcQt3dFtFlXorb84Je4UB5jSIVkJW9aXsLQRVOKHpwjlH/0Ia3CwzQdUg6Uy40Yb9wi+o7hPQk1Uu5cploIKVc/LZtWrFEqnUbZiYjVy3uy5uGoJmX8Y4iZijzpZxQ/KfoJIVeDYdDTI3ry9Faj6CNNvqTabxF3wDcLCnYLaAYwfgKAo2Ehgot2GuBglBwRoFU6Rj5gJSOhjNWUIxsKcQMMmSMYU5sUsUYkLhDNI6/6veJmxrwyv9B8zRgGHFaHOOyS+zK5hqdcxtEGpiHE78WuabbnXFI2U5ILUf9MAj5Jw91/vA/+r8S5nRkCQHImJH5GLXhb4hpwSsrHegPSQihEetiWrLh/0ziSFkAEBqkfJk7FgOsIgLIWln/4H+wll2LgLOMgFKNgcaICTuOEbkQZo8QEpAityBEkUShyIncEZSSscMJBZMCYSTZRMGUBMWXCMuI1pkILJoIipsR1xCmnCLKIImdICqeRDOCihyfRrmjNjLPRwllJHZLWFRx4WNvcsVl1uJaf7urnhpoa5Qe8v9kPoQcWliiq70/zu31qjstnb146eaIgkDchCNOUb4j2MhGkErPYjTrtA/ZcCphTvoOf64tPhtt5o4oe2fPWGTHb2YzYmytOdcI622hkHlZSkQlOeLceW0fYm9saVd6NKKPmLZ8indl71RnZCh5JAgddCR5cCBahpFhrs76Y3ypsCCTSHSjRhsOdW5rR293VSA0I+/Ci2dPPqncSEXK3nRudxK7jHtwJHplVFyMY8aSbXCUqy/uGPWUxGjrcMAA'
EndIf
Local $Opcode = String(_ZLIB_CodeDecompress($Code))
$_ZLIB_DeflateInit =(StringInStr($Opcode, "FF01") + 1) / 2
$_ZLIB_DeflateInit2 =(StringInStr($Opcode, "FF02") + 1) / 2
$_ZLIB_Deflate =(StringInStr($Opcode, "FF03") + 1) / 2
$_ZLIB_DeflateEnd =(StringInStr($Opcode, "FF04") + 1) / 2
$_ZLIB_DeflateBound =(StringInStr($Opcode, "FF05") + 1) / 2
$_ZLIB_InflateInit =(StringInStr($Opcode, "FF21") + 1) / 2
$_ZLIB_InflateInit2 =(StringInStr($Opcode, "FF22") + 1) / 2
$_ZLIB_Inflate =(StringInStr($Opcode, "FF23") + 1) / 2
$_ZLIB_InflateEnd =(StringInStr($Opcode, "FF24") + 1) / 2
$_ZLIB_ZError =(StringInStr($Opcode, "FF61") + 1) / 2
$Opcode = Binary($Opcode)
$_ZLIB_CodeBufferMemory = _MemVirtualAlloc(0, BinaryLen($Opcode), $MEM_COMMIT, $PAGE_EXECUTE_READWRITE)
$_ZLIB_CodeBuffer = DllStructCreate("byte[" & BinaryLen($Opcode) & "]", $_ZLIB_CodeBufferMemory)
DllStructSetData($_ZLIB_CodeBuffer, 1, $Opcode)
$_ZLIB_CodeBufferPtr = DllStructGetPtr($_ZLIB_CodeBuffer)
$_ZLIB_DeflateInit = $_ZLIB_CodeBufferPtr + $_ZLIB_DeflateInit
$_ZLIB_DeflateInit2 = $_ZLIB_CodeBufferPtr + $_ZLIB_DeflateInit2
$_ZLIB_Deflate = $_ZLIB_CodeBufferPtr + $_ZLIB_Deflate
$_ZLIB_DeflateEnd = $_ZLIB_CodeBufferPtr + $_ZLIB_DeflateEnd
$_ZLIB_DeflateBound = $_ZLIB_CodeBufferPtr + $_ZLIB_DeflateBound
$_ZLIB_InflateInit = $_ZLIB_CodeBufferPtr + $_ZLIB_InflateInit
$_ZLIB_InflateInit2 = $_ZLIB_CodeBufferPtr + $_ZLIB_InflateInit2
$_ZLIB_Inflate = $_ZLIB_CodeBufferPtr + $_ZLIB_Inflate
$_ZLIB_InflateEnd = $_ZLIB_CodeBufferPtr + $_ZLIB_InflateEnd
$_ZLIB_ZError = $_ZLIB_CodeBufferPtr + $_ZLIB_ZError
$_ZLIB_Alloc_Callback = DllCallbackRegister("_ZLIB_Alloc", "ptr:cdecl", "ptr;uint;uint")
$_ZLIB_Free_Callback = DllCallbackRegister("_ZLIB_Free", "none:cdecl", "ptr;ptr")
OnAutoItExitRegister("_ZLIB_Exit")
EndIf
EndFunc
Func _ZLIB_CodeDecompress($Code)
Local $Opcode
If @AutoItX64 Then
Else
$Opcode = '0x89C0608B7424248B7C2428FCB28031DBA4B302E86D00000073F631C9E864000000731C31C0E85B0000007323B30241B010E84F00000010C073F7753FAAEBD4E84D00000029D97510E842000000EB28ACD1E8744D11C9EB1C9148C1E008ACE82C0000003D007D0000730A80FC05730683F87F770241419589E8B3015689FE29C6F3A45EEB8E00D275058A164610D2C331C941E8EEFFFFFF11C9E8E7FFFFFF72F2C32B7C2428897C241C61C389D28B442404C70000000000C6400400C2100089F65557565383EC1C8B6C243C8B5424388B5C24308B7424340FB6450488028B550083FA010F84A1000000733F8B5424388D34338954240C39F30F848B0100000FB63B83C301E8CD0100008D57D580FA5077E50FBED20FB6041084C00FBED078D78B44240CC1E2028810EB6B83FA020F841201000031C083FA03740A83C41C5B5E5F5DC210008B4C24388D3433894C240C39F30F84CD0000000FB63B83C301E8740100008D57D580FA5077E50FBED20FB6041084C078DA8B54240C83E03F080283C2018954240CE96CFFFFFF8B4424388D34338944240C39F30F84D00000000FB63B83C301E82E0100008D57D580FA5077E50FBED20FB6141084D20FBEC278D78B4C240C89C283E230C1FA04C1E004081189CF83C70188410139F374750FB60383C3018844240CE8EC0000000FB654240C83EA2B80FA5077E00FBED20FB6141084D20FBEC278D289C283E23CC1FA02C1E006081739F38D57018954240C8847010F8533FFFFFFC74500030000008B4C240C0FB60188450489C82B44243883C41C5B5E5F5DC210008D34338B7C243839F3758BC74500020000000FB60788450489F82B44243883C41C5B5E5F5DC210008B54240CC74500010000000FB60288450489D02B442438E9B1FEFFFFC7450000000000EB9956578B7C240C8B7424108B4C241485C9742FFC83F9087227F7C7010000007402A449F7C702000000740566A583E90289CAC1E902F3A589D183E103F3A4EB02F3A45F5EC3E8500000003EFFFFFF3F3435363738393A3B3C3DFFFFFFFEFFFFFF000102030405060708090A0B0C0D0E0F10111213141516171819FFFFFFFFFFFF1A1B1C1D1E1F202122232425262728292A2B2C2D2E2F3031323358C3'
EndIf
Local $AP_Decompress =(StringInStr($Opcode, "89C0") - 3) / 2
Local $B64D_DecodeData =(StringInStr($Opcode, "89F6") - 3) / 2
$Opcode = Binary($Opcode)
Local $CodeBufferMemory = _MemVirtualAlloc(0, BinaryLen($Opcode), $MEM_COMMIT, $PAGE_EXECUTE_READWRITE)
Local $CodeBuffer = DllStructCreate("byte[" & BinaryLen($Opcode) & "]", $CodeBufferMemory)
DllStructSetData($CodeBuffer, 1, $Opcode)
Local $CodeBufferPtr = DllStructGetPtr($CodeBuffer)
Local $B64D_State = DllStructCreate("byte[16]")
Local $length = StringLen($Code)
Local $Output = DllStructCreate("byte[" & $length & "]")
DllCall($_ZLIB_USER32DLL, "int", "CallWindowProc", "ptr", $CodeBufferPtr + $B64D_DecodeData, "str", $Code, "uint", $length, "ptr", DllStructGetPtr($Output), "ptr", DllStructGetPtr($B64D_State))
Local $ResultLen = DllStructGetData(DllStructCreate("uint", DllStructGetPtr($Output)), 1)
Local $Result = DllStructCreate("byte[" &($ResultLen + 16) & "]")
Local $Ret = DllCall("user32.dll", "uint", "CallWindowProc", "ptr", $CodeBufferPtr + $AP_Decompress, "ptr", DllStructGetPtr($Output) + 4, "ptr", DllStructGetPtr($Result), "int", 0, "int", 0)
_MemVirtualFree($CodeBufferMemory, 0, $MEM_RELEASE)
Return BinaryMid(DllStructGetData($Result, 1), 1, $Ret[0])
EndFunc
Func _ZLIB_InflateInit2($Strm, $WindowBits = $Z_MAX_WBITS)
DllStructSetData($Strm, "zalloc", DllCallbackGetPtr($_ZLIB_Alloc_Callback))
DllStructSetData($Strm, "zfree", DllCallbackGetPtr($_ZLIB_Free_Callback))
Local $Ret = DllCall($_ZLIB_USER32DLL, "int", "CallWindowProc", "ptr", $_ZLIB_InflateInit2, "ptr", DllStructGetPtr($Strm), "int", $WindowBits, "int", 0, "int", 0)
Return $Ret[0]
EndFunc
Func _ZLIB_Inflate($Strm, $Flush = $Z_NO_FLUSH)
Local $Ret = DllCall($_ZLIB_USER32DLL, "int", "CallWindowProc", "ptr", $_ZLIB_Inflate, "ptr", DllStructGetPtr($Strm), "int", $Flush, "int", 0, "int", 0)
Return $Ret[0]
EndFunc
Func _ZLIB_InflateEnd($Strm)
Local $Ret = DllCall($_ZLIB_USER32DLL, "int", "CallWindowProc", "ptr", $_ZLIB_InflateEnd, "ptr", DllStructGetPtr($Strm), "int", 0, "int", 0, "int", 0)
Return $Ret[0]
EndFunc
Func _ZLIB_UncompressCore(ByRef $Data, $WindowBits = $Z_MAX_WBITS)
If Not IsDllStruct($_ZLIB_CodeBuffer) Then _ZLIB_Startup()
Local $Stream = DllStructCreate($_ZLIB_tagZStream)
_ZLIB_InflateInit2($Stream, $WindowBits)
Local $SourceLen = BinaryLen($Data)
Local $DestLen = $SourceLen * 2
Local $Source = DllStructCreate("byte[" & $SourceLen & "]")
Local $Dest = DllStructCreate("byte[" & $DestLen & "]")
Local $DestPtr = DllStructGetPtr($Dest)
DllStructSetData($Source, 1, $Data)
DllStructSetData($Stream, "next_in", DllStructGetPtr($Source))
DllStructSetData($Stream, "avail_in", $SourceLen)
Local $Ret = Binary("")
Do
DllStructSetData($Stream, "next_out", $DestPtr)
DllStructSetData($Stream, "avail_out", $DestLen)
Local $Error = _ZLIB_Inflate($Stream, $Z_NO_FLUSH)
If $Error = $Z_NEED_DICT Then $Error = $Z_DATA_ERROR
If $Error < 0 Then
_ZLIB_InflateEnd($Stream)
Return SetError($Error, 0, $Ret)
EndIf
Local $AvailOut = DllStructGetData($Stream, "avail_out")
Local $Got = $DestLen - $AvailOut
$Ret &= BinaryMid(DllStructGetData($Dest, 1), 1, $Got)
Until $AvailOut <> 0
_ZLIB_InflateEnd($Stream)
Return $Ret
EndFunc
Func _ZLIB_Uncompress($Data)
Local $Ret = _ZLIB_UncompressCore($Data, $Z_MAX_WBITS)
Return SetError(@Error, 0, $Ret)
EndFunc
Func _LrcList_qianqian($a,$t,$s=0, $xml='')
Local $url
If Not $xml Then
If $s=0 Then
$url='ttlrcct.qianqian.com'
Else
$url='ttlrccnc.qianqian.com'
EndIf
$a=StringLower(_clear($a))
$t=StringLower(_clear($t))
Local $send = $url & '|' & '/dll/lyricsvr.dll?sh?Artist=' & StringTrimLeft(StringToBinary($a,2),2) & '&Title=' & StringTrimLeft(StringToBinary($t,2),2) & '&Flags=0' & '|1' & '||||'
If _CoProcSend($load_Pro, $send) Then
Else
_ToolTip('错误', "Worker not Responding (" & @error & ")", 3,3)
EndIf
Else
$list = StringRegExp($xml,'(?i)<lrc\s(.*?)></lrc>',3,1)
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
Func _LrcDownLoad_qianqian($lrcid,$artist,$title,$s=0)
Local $utfURL,$url,$url2,$len,$c,$i,$j,$t4,$t5,$t6
If $s=0 Then
$url='ttlrcct.qianqian.com'
Else
$url='ttlrccnc.qianqian.com'
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
Func _LrcList_mini($a,$t,$xml='')
Local $check, $head, $result, $total=0, $ta='',$x=''
If Not $xml Then
$xml = "<?xml version=""1.0"" encoding='utf-8'?>" & @CRLF & StringFormat("<search artist=""%s"" title=""%s"" ",_clear($a),_clear($t)) & 'ProtoVer="0.9" client="MiniLyrics 7.0.676 for Windows Media Player" ClientCharEncoding="gb2312"/>' & @CRLF
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
For $i = 1 To(BinaryLen($xml)-22)
$x&=Hex(BitXOR($check,BinaryMid($xml,$i+22,1)),2)
Next
$result = BinaryToString(Binary('0x'& $x),4)
Return _xmlPrase_mini($result)
EndIf
EndFunc
Func _LrcList_kuwo($a,$t,$xml='')
Local $i=0
If Not $xml Then
$a=StringReplace(_UrlToHex(_clear($a),1,'ansi'),'%20','+')
$t=StringReplace(_UrlToHex(_clear($t),1,'ansi'),'%20','+')
Local $send = 'search.koowo.com|' & StringFormat('/r.s?client=kowoo&Name=&Artist=%s&SongName=%s&Sig1=&Sig2=&Provider=&ft=lyric',$a,$t)&'|0||||'
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
Func _LrcDownLoad_baidu($a,$t,$xml='')
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
Func _LrcList_ilrc($a,$t, $xml='')
Local $send, $temp1,$temp2,$temp3,$temp4,$tem='',$i_url,$p_url,$tt=0
If Not $xml Then
$send = 'www.5ilrc.com|/souge1.asp|0||POST|radiobutton=jq&zj=&gm='&_UrlToHex(_clear($t,False),1,'ansi') & '&gs='&_UrlToHex(_clear($a,False),1,'ansi')&'|http://www.5ilrc.com/souge1.asp|Content-Type: application/x-www-form-urlencoded'
If _CoProcSend($load_Pro, $send) Then
Else
_ToolTip('错误', "Worker not Responding (" & @error & ")", 3,3)
EndIf
Return
Else
MsgBox(0,"",$xml)
$temp1 = StringRegExp(StringRegExpReplace($xml,'\r?\n',''),'\<TD width\="30%".*?</tr>',3,1)
If Not @error Then
Dim $i_url[UBound($temp1)][4]
For $i=0 To UBound($temp1)-1
$temp3 = StringRegExp($temp1[$i],'href="(/Song_\d+.html)"',3,1)
If @error Then ContinueLoop
$temp1[$i]=StringReplace($temp1[$i],'</td>','%%')
$temp2=StringSplit(StringRegExpReplace($temp1[$i],'\h*<[^>]+>\h*',''),'%%',1+2)
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
Local $hOpen, $hConnect, $hRequest, $hProxy=False, $ProxyServer, $sReturned, $ProcessAddy, $net=0, $ret = '',$Ping=''
Local $timeout=7000, $ttl=255, $count=0, $pingID, $status
Global $Addr[8] = ["ttlrcct.qianqian.com","search.koowo.com","newlyric.koowo.com","search.crintsoft.com","viewlyrics.com","box.zhangmen.baidu.com","www.9ilrc.com","qqmusic.qq.com"]
Global Const $tagWINHTTP_PROXY_INFO = "DWORD  dwAccessType;ptr lpszProxy;ptr lpszProxyBypass;"
Global Const $DONT_FRAGMENT = 2, $IP_SUCCESS = 0, $IP_DEST_NET_UNREACHABLE = 11002, $IP_DEST_HOST_UNREACHABLE = 11003, $IP_DEST_PROT_UNREACHABLE = 11004, $IP_DEST_PORT_UNREACHABLE = 11005, $IP_NO_RESOURCES = 11006, $IP_HW_ERROR = 11008, $IP_PACKET_TOO_BIG = 11009, $IP_REQ_TIMED_OUT = 11010, $IP_BAD_REQ = 11011, $IP_BAD_ROUTE = 11012, $IP_TTL_EXPIRED_TRANSIT = 11013, $IP_TTL_EXPIRED_REASSEM = 11014, $IP_PARAM_PROBLEM = 11015, $IP_SOURCE_QUENCH = 11016, $IP_BAD_DESTINATION =11018, $IP_GENERAL_FAILURE = 11050, $NO_STATUS = 10000
Global $hkernel32Dll = DllOpen("kernel32.dll")
Global $hKrn = _WinAPI_GetModuleHandle("kernel32.dll")
Local $LibHandle = DllCall($hkernel32Dll, "int", "LoadLibraryA", "str", "ICMP.dll")
Global $hICMPDll = $LibHandle[0]
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
_CoProcReciver("_loadReciver")
While 1
Sleep(100)
$count+=1
If $count>=30 Then
$count=0
_CoProcSend($gi_CoProcParent, Binary("0x22")&StringToBinary(_GetProcessMemory($gi_CoProcParent)))
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
Dim $PingBack[8], $pings[1] = [0]
$Addr[0]=_Iif($info[1],'ttlrccnc.qianqian.com','ttlrcct.qianqian.com')
For $i= 0 To 7
Local $data=_StringRepeat("x",$i+1)
Local $hexIP = encodeIP($Addr[$i])
If $hexIP == 0 Then ContinueLoop
$pings[0] = UBound($pings)
ReDim $pings[$pings[0]+1]
$pings[$pings[0]] = DllStructCreate("char ip[" & StringLen($Addr[$i]) & "];ulong reply;ulong status;int datasize")
DllStructSetData($pings[$pings[0]],"ip",$Addr[$i])
DllStructSetData($pings[$pings[0]],"status",$NO_STATUS)
$pingID = $pings[0]
DllStructSetData($pings[$pingID],"datasize",StringLen($data))
Local $CodeBuffer = DllStructCreate("byte[696]")
Local $RemoteCode = _MemVirtualAlloc(0, DllStructGetSize($CodeBuffer), $MEM_COMMIT, $PAGE_EXECUTE_READWRITE)
DllStructSetData($CodeBuffer, 1, "0x" & "E889000000" & "A3" & SwapEndian($RemoteCode + 410) & "C605" & SwapEndian($RemoteCode + 418) & Hex($ttl,2) & "C605" & SwapEndian($RemoteCode + 419) & "00" & "C605" & SwapEndian($RemoteCode + 420) & Hex(0,2) & "C605" & SwapEndian($RemoteCode + 421) & "00" & "C705" & SwapEndian($RemoteCode + 422) & "00000000" & "68" & SwapEndian(Dec(Hex($timeout,4))) & "681E010000" & "68" & SwapEndian($RemoteCode + 426) & "68" & SwapEndian($RemoteCode + 418) & "6A" & Hex(StringLen($data),2) & "68" & SwapEndian($RemoteCode + 154) & "68" & SwapEndian(Dec($hexIP)) & "FF35" & SwapEndian($RemoteCode + 410) & "E839000000" & "A1" & SwapEndian($RemoteCode + 434) & "A3" & SwapEndian(DllStructGetPtr($pings[$pingID],"reply")) & "A1" & SwapEndian($RemoteCode + 430) & "A3" & SwapEndian(DllStructGetPtr($pings[$pingID],"status")) & "FF35" & SwapEndian($RemoteCode + 410) & "E80E000000" & "6A00" & "E801000000" & "CC" & "FF25" & SwapEndian(DllStructGetPtr($hPointers,"ExitThread")) & "FF25" & SwapEndian(DllStructGetPtr($hPointers,"IcmpCloseHandle")) & "FF25" & SwapEndian(DllStructGetPtr($hPointers,"IcmpCreateFile")) & "FF25" & SwapEndian(DllStructGetPtr($hPointers,"IcmpSendEcho"))& SwapEndian(StringToBinary($data)) )
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
Else
$PingBack[Number(DllStructGetData($pings[$pingID],"datasize"))-1]=DllStructGetData($pings[$pingID],"reply")
EndIf
Case $IP_REQ_TIMED_OUT
$PingBack[Number(DllStructGetData($pings[$pingID],"datasize"))-1]=-1
Case $IP_DEST_NET_UNREACHABLE
Case $IP_DEST_HOST_UNREACHABLE
Case $IP_DEST_PROT_UNREACHABLE
Case $IP_DEST_PORT_UNREACHABLE
Case $IP_NO_RESOURCES
Case $IP_HW_ERROR
Case $IP_PACKET_TOO_BIG
Case $IP_BAD_REQ
Case $IP_BAD_ROUTE
Case $IP_TTL_EXPIRED_TRANSIT
Case $IP_TTL_EXPIRED_REASSEM
Case $IP_PARAM_PROBLEM
Case $IP_SOURCE_QUENCH
Case $IP_BAD_DESTINATION
Case $IP_GENERAL_FAILURE
EndSwitch
If $pingID <= $pings[0] Then
$pings[$pingID] = 0
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
If $info[3]='' Then
$hOpen = _WinHttpOpen()
Else
$hOpen = _WinHttpOpen($info[3])
EndIf
_WinHttpSetTimeouts($hOpen,2000)
If $hProxy Then
Local $tProxyInfo[2] = [DllStructCreate($tagWINHTTP_PROXY_INFO), DllStructCreate('wchar proxychars[' & StringLen($ProxyServer)+1 & ']; wchar proxybypasschars[' & StringLen("localhost")+1 & ']')]
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
Local $hHeader = -1
If UBound($info) = 8 Then $hHeader = $info[7]
If _WinHttpSendRequest($hRequest, $hHeader, $info[5]) Then
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
EndIf
If $sReturned='' Then $sReturned=Binary('0x24')
_CoProcSend($gi_CoProcParent, $sReturned)
$info = ''
WEnd
TCPShutdown()
DllCall($hkernel32Dll, "int", "FreeLibrary", "int", $hICMPDll)
DllClose($hkernel32Dll)
EndFunc
Func _loadReciver($vParameter)
Dim $info = StringSplit($vParameter,"|",2)
EndFunc
Func _GetProcessMemory($iPid, $NFormat = 1)
Local $Data = _WinAPI_GetProcessMemoryInfo($iPid)
If Not IsArray($Data) Then Return SetError(1, '', '')
If Not $NFormat Then Return $Data[2]
Return StringRegExpReplace($Data[2] / 1024, '(\d+?)(?=(?:\d{3})+\Z)', '$1,') & ' (K)'
EndFunc
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
Func _UrlToHex($URL,$flag,$encode)
If Not $URL Then Return ''
Switch $encode
Case 'unicode'
$Binary = StringReplace(StringToBinary($URL, 4), '0x', '', 1)
Case 'ansi'
$Binary=StringReplace(StringToBinary($URL), '0x', '', 1)
EndSwitch
Local $EncodedString
For $i = 1 To StringLen($Binary) Step 2
$BinaryChar = StringMid($Binary, $i, 2)
Switch $flag
Case 0
$EncodedString &= $BinaryChar
Case 1
If StringInStr("$-_.+!*'(),;/?:@=&abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890", BinaryToString('0x' & $BinaryChar, 4)) Then
$EncodedString &= BinaryToString('0x' & $BinaryChar)
Else
$EncodedString &= '%'&$BinaryChar
EndIf
EndSwitch
Next
Return $EncodedString
EndFunc
Func _clear($s,$rm_space=True)
$s=StringReplace($s,"'",'')
$Bstr='`~!@#$%^&*()-+_=,<.>/?;:"[{]}\|�' & '　。，、；：？！…—·ˉ¨‘’“”々～‖∶＂＇｀｜〃〔〕〈〉《》「」『』．〖〗【】（）［］｛｝' & '≈≡≠＝≤≥＜＞≮≯∷±＋－×÷／∫∮∝∞∧∨∑∏∪∩∈∵∴⊥∥∠⌒⊙≌∽√' & '§№☆★○●◎◇◆□℃‰■△▲※→←↑↓〓¤°＃＆＠＼︿＿￣―♂♀' & 'ⅠⅡⅢⅣⅤⅥⅦⅧⅨⅩⅪⅫ⒈⒉⒊⒋⒌⒍⒎⒏⒐⒑⒒⒓⒔⒕⒖⒗⒘⒙⒚⒛㈠㈡㈢㈣㈤㈥㈦㈧㈨㈩' & '①②③④⑤⑥⑦⑧⑨⑩⑴⑵⑶⑷⑸⑹⑺⑻⑼⑽⑾⑿⒀⒁⒂⒃⒄⒅⒆⒇' & '┌┍┎┏┐┑┒┓─┄┈└┕┖┗┘┙┚┛━┅┉├┝┞┟┠┡┢┣│┆┊┤┥┦┧┨┩┪┫┃┇┋' & '┬┭┮┯┰┱┲┳┴┵┶┷┸┹┺┻┼┽┾┿╀╁╂╃╄╅╆╇╈╉╊╋'
If $rm_space Then
$Bstr&=' '
EndIf
For $i = 1 To StringLen($Bstr)
$s=StringReplace($s,StringMid($Bstr,$i,1),'')
Next
Return $s
EndFunc
Func _Conv($i)
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
EndFunc
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
For $j = 0 To 3
_ArrayAdd($decout,StringMid($k3,BitShift(BitAND($bits,BitShift($site,$j*6)),(3-$j)*6)+1,1))
Next
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
HotKeySet("{Esc}", "_StopLoading")
Func _lrc_Prase($src_Lrc, $flag=0)
Local $k=0, $L
$l_head=DllStructCreate('wchar title[30];wchar artist[30];wchar album[30];wchar editor[30]')
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
$L = StringSplit($src_Lrc,@CRLF,1)
ElseIf StringInStr($src_Lrc,@LF) Then
$L = StringSplit($src_Lrc,@LF,1)
Else
Return $src_Lrc
EndIf
If $flag=1 And UBound($L)-1<>UBound($lrc) Then Return
If Not $flag Then
For $i = 1 To $L[0]
$temp = StringReplace(StringStripWS($L[$i],1),'[','')
$my = StringSplit($temp,']')
If $my[0]=1 Then ContinueLoop
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
For $i = 1 To $L[0]
$my=StringSplit(StringTrimLeft($L[$i],1),']',2)
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
Return $lrc
EndFunc
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
Switch StringLen($tt[2]) - StringInStr($tt[2],'.')
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
Return SetError(0)
ElseIf Number($iTicks) = 0 Then
$iFormat = '00:00:00'
Return SetError(0)
Else
Return SetError(1)
EndIf
EndFunc
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
EndFunc
Func _File_Rename($File_Old_Name, $File_New_Name)
If Not FileExists($File_Old_Name) Then Return SetError(1, 0, 0)
If $File_New_Name = '' Then Return SetError(2, 0, 0)
If StringRight($File_Old_Name, 1) = '\' Then $File_Old_Name = StringTrimRight($File_Old_Name, 1)
If StringInStr($File_New_Name, '\') Then $File_New_Name = StringRegExpReplace($File_New_Name, '.+\\', '')
If StringRegExp($File_New_Name, '(\/|\:|\*|\?|\"|\<|\>|\|)') Then Return SetError(3, 0, 0)
Local $fPath = ''
If StringRegExp($File_Old_Name, '\\') Then $fPath = StringRegExpReplace($File_Old_Name, '(.+\\).+', '\1')
If FileExists($fPath & $File_New_Name) Then Return SetError(4, 0, 0)
FileMove($File_Old_Name,$fPath & $File_New_Name,1)
If FileExists($fPath & $File_New_Name) Then Return 1
If Not FileExists($fPath & $File_New_Name) Then Return SetError(5, 0, 0)
EndFunc
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
Local $bitrate=Round(_BASS_StreamGetFilePosition($stream, $BASS_FILEPOS_END)/$len/125, 0)
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
Local $bitrate=Round(_BASS_StreamGetFilePosition($stream, $BASS_FILEPOS_END)/$len/125, 0)
Else
$bitrate=-1
$tFormat='00:00:00'
EndIf
Dim $info[8] = [StringRegExpReplace($sFile[$i],'^.*\\',''), DllStructGetData($temp, "title"),DllStructGetData($temp, "artist"),DllStructGetData($temp, "album"),$bitrate&'kbps',$size,$tFormat,$sub_folder]
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
ElseIf @extended=1 Then
If $d<$deep Then
_filelist($searchdir & "\" & $file,$d+1)
EndIf
Else
$file_list &= $searchdir & "\" & $file & @CRLF
EndIf
WEnd
EndFunc
Func _ANSI_FIX($UN_FIX_TEXT)
Local $temp= $UN_FIX_TEXT
Local $cnTEXTnumber = BinaryLen(StringToBinary($temp,4))-StringLen($temp)
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
If $iEnd < 1 Or $iEnd > $iUBound Then $iEnd = $iUBound
If $iStart < 0 Then $iStart = 0
If $iStart > $iEnd Then Return SetError(2, 0, 0)
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
EndFunc
Func _ArrayQuickSort2D(ByRef $avArray, ByRef $iStep, ByRef $iStart, ByRef $iEnd, ByRef $iSubItem, ByRef $iSubMax, $forceNUM)
If $iEnd <= $iStart Then Return
Local $vTmp, $L = $iStart, $R = $iEnd, $vPivot = $avArray[Int(($iStart + $iEnd) / 2)][$iSubItem], $fNum = IsNumber($vPivot)
Do
If Not $forceNUM Then
If $fNum Then
While($iStep *($avArray[$L][$iSubItem] - $vPivot) < 0 And IsNumber($avArray[$L][$iSubItem])) Or(Not IsNumber($avArray[$L][$iSubItem]) And $iStep * StringCompare($avArray[$L][$iSubItem], $vPivot) < 0)
$L += 1
WEnd
While($iStep *($avArray[$R][$iSubItem] - $vPivot) > 0 And IsNumber($avArray[$R][$iSubItem])) Or(Not IsNumber($avArray[$R][$iSubItem]) And $iStep * StringCompare($avArray[$R][$iSubItem], $vPivot) > 0)
$R -= 1
WEnd
Else
While($iStep * StringCompare($avArray[$L][$iSubItem], $vPivot) < 0)
$L += 1
WEnd
While($iStep * StringCompare($avArray[$R][$iSubItem], $vPivot) > 0)
$R -= 1
WEnd
EndIf
Else
$vPivot=Number($vPivot)
While($iStep *(Number($avArray[$L][$iSubItem]) - $vPivot)) < 0
$L += 1
WEnd
While($iStep *(Number($avArray[$R][$iSubItem]) - $vPivot)) > 0
$R -= 1
WEnd
EndIf
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
EndFunc
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
If $aResult[0] = 0 Then Return SetError(-3, -3, -1)
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
EndFunc
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
Func _GUIImageList_GetSystemImageList($bLargeIcons = False)
Local $dwFlags, $hIml, $FileInfo = DllStructCreate($tagSHFILEINFO)
$dwFlags = BitOR($SHGFI_USEFILEATTRIBUTES, $SHGFI_SYSICONINDEX)
If Not($bLargeIcons) Then
$dwFlags = BitOR($dwFlags, $SHGFI_SMALLICON)
EndIf
$hIml = _WinAPI_SHGetFileInfo(".mp3", $FILE_ATTRIBUTE_NORMAL, DllStructGetPtr($FileInfo), DllStructGetSize($FileInfo), $dwFlags)
Return $hIml
EndFunc
Func _WinAPI_SHGetFileInfo($pszPath, $dwFileAttributes, $psfi, $cbFileInfo, $uFlags)
Local $return = DllCall("shell32.dll", "DWORD*", "SHGetFileInfo", "str", $pszPath, "DWORD", $dwFileAttributes, "ptr", $psfi, "UINT", $cbFileInfo, "UINT", $uFlags)
If @error Then Return SetError(@error, 0, 0)
Return $return[0]
EndFunc
Func _GUIImageList_GetFileIconIndex($sFileSpec, $bLargeIcons = False, $bForceLoadFromDisk = False)
Local $dwFlags, $FileInfo = DllStructCreate($tagSHFILEINFO)
$dwFlags = $SHGFI_SYSICONINDEX
If $bLargeIcons Then
$dwFlags = BitOR($dwFlags, $SHGFI_LARGEICON)
Else
$dwFlags = BitOR($dwFlags, $SHGFI_SMALLICON)
EndIf
If Not $bForceLoadFromDisk Then
$dwFlags = BitOR($dwFlags, $SHGFI_USEFILEATTRIBUTES)
EndIf
Local $lR = _WinAPI_SHGetFileInfo( $sFileSpec, $FILE_ATTRIBUTE_NORMAL, DllStructGetPtr($FileInfo), DllStructGetSize($FileInfo), $dwFlags )
If($lR = 0) Then
Return SetError(1, 0, -1)
Else
Return DllStructGetData($FileInfo, "iIcon")
EndIf
EndFunc
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
EndFunc
Global Const $__MemArray_HEAD = "dword iElSize;"
Global Const $__MemArray_HEADSIZE = __MemArray_SIZEOF($__MemArray_HEAD)
Func __MemArray_SIZEOF($tagStruct)
Return DllStructGetSize(DllStructCreate($tagStruct, 1))
EndFunc
Func __MemArrayLockedPtr($hMem)
If Not IsPtr($hMem) Or $hMem = 0 Or Not __MemIsGlobal($hMem) Then Return SetError(1,0,0)
Return _MemGlobalLock($hMem)+$__MemArray_HEADSIZE
EndFunc
Func __MemArrayUnLock($hMem)
If Not IsPtr($hMem) Or $hMem = 0 Or Not __MemIsGlobal($hMem) Then Return SetError(1,0,0)
_MemGlobalUnlock($hMem)
EndFunc
Func _MemArrayCreate($tagStruct)
Local $iSize = __MemArray_SIZEOF($tagStruct)
If $iSize = 0 Then Return SetError(1, 0, 0)
Local $hMem = _MemGlobalAlloc($__MemArray_HEADSIZE, $GMEM_MOVEABLE)
If $hMem = 0 Then Return SetError(2, 0, 0)
DllStructSetData(DllStructCreate($__MemArray_HEAD, _MemGlobalLock($hMem)), 1, $iSize)
_MemGlobalUnlock($hMem)
Return $hMem
EndFunc
Func __MemArrayElementSize($hMem)
If Not IsPtr($hMem) Or $hMem = 0 Or Not __MemIsGlobal($hMem) Then Return SetError(1, 0, 0)
Local $iSize = DllStructGetData(DllStructCreate($__MemArray_HEAD, _MemGlobalLock($hMem)), 1)
_MemGlobalUnlock($hMem)
Return $iSize
EndFunc
Func _MemArrayFree($hMem)
Return _MemGlobalFree($hMem)
EndFunc
Func _MemArrayAdd($hMem, ByRef $stEntry)
If Not IsPtr($hMem) Or $hMem = 0 Or Not __MemIsGlobal($hMem) Then Return SetError(1, 0, -1)
If Not(IsDllStruct($stEntry) Or IsPtr($stEntry)) Then Return SetError(2, 0, -1)
Local $size = _MemGlobalSize($hMem)
Local $iElSize = __MemArrayElementSize($hMem)
Local $result = __MemGlobalReAlloc($hMem, $size + $iElSize, $GHND)
If Not $result Then Return SetError(2, 0, 0)
Local $indX =(($size - $__MemArray_HEADSIZE) / $iElSize)
If IsPtr($stEntry) Then
__MemCopyMemory($stEntry, _MemGlobalLock($hMem) + $size, $iElSize)
Else
__MemCopyMemory(DllStructGetPtr($stEntry), _MemGlobalLock($hMem) + $size, $iElSize)
EndIf
_MemGlobalUnlock($hMem)
Return $indX
EndFunc
Func _MemArrayGet($hMem, $indX, $tagStruct)
If Not IsPtr($hMem) Or $hMem = 0 Or Not __MemIsGlobal($hMem) Then Return SetError(1, 0, 0)
Local $size = _MemGlobalSize($hMem)
Local $iElSize = __MemArrayElementSize($hMem)
Local $maxIndX =($size - $__MemArray_HEADSIZE) / $iElSize
If $indX < 0 Or $indX > $maxIndX Then Return SetError(2, 0, 0)
If IsPtr($tagStruct) Then
__MemCopyMemory(_MemGlobalLock($hMem) + $__MemArray_HEADSIZE + $indX * $iElSize, $tagStruct, $iElSize)
Local $struct = $tagStruct
Else
Local $struct = DllStructCreate($tagStruct)
If @error Then Return SetError(2,0,0)
__MemCopyMemory(_MemGlobalLock($hMem) + $__MemArray_HEADSIZE + $indX * $iElSize, DllStructGetPtr($struct), $iElSize)
EndIf
_MemGlobalUnlock($hMem)
Return $struct
EndFunc
Func _MemArraySet($hMem, $indX, ByRef $stEntry)
If Not IsPtr($hMem) Or $hMem = 0 Or Not __MemIsGlobal($hMem) Then Return SetError(1, 0, 0)
Local $size = _MemGlobalSize($hMem)
Local $iElSize = __MemArrayElementSize($hMem)
Local $maxIndX =($size - $__MemArray_HEADSIZE) / $iElSize
If $indX < 0 Or $indX > $maxIndX Then Return SetError(2, 0, 0)
Local $pEntry = _MemGlobalLock($hMem) + $__MemArray_HEADSIZE + $indX * $iElSize
__MemZeroMemory($pEntry, $iElSize)
If IsPtr($stEntry) Then
__MemCopyMemory($stEntry, $pEntry, $iElSize)
ElseIf IsDllStruct($stEntry) Then
__MemCopyMemory(DllStructGetPtr($stEntry), $pEntry, $iElSize)
Else
Return SetError(2,0,0)
EndIf
_MemGlobalUnlock($hMem)
Return 1
EndFunc
Func __MemIsGlobal($hMem)
Local $result = __MemGlobalFlags($hMem)
If @error Or $result == $GMEM_INVALID_HANDLE Then Return 0
Return 1
EndFunc
Func __MemGlobalReAlloc($hMem, $iBytes, $iFlags)
Local $aResult = DllCall("Kernel32.dll", "ptr", "GlobalReAlloc", "ptr", $hMem, "ulong", $iBytes, "uint", $iFlags)
Return $aResult[0]
EndFunc
Func __MemGlobalFlags($hMem)
Local $aResult = DllCall("Kernel32.dll", "uint", "GlobalFlags", "ptr", $hMem)
Return $aResult[0]
EndFunc
Func __MemCopyMemory($pSource, $pDest, $iLength)
DllCall("msvcrt.dll", "none:cdecl", "memcpy", "ptr", $pDest, "ptr", $pSource, "dword", $iLength)
EndFunc
Func __MemZeroMemory($pDest, $iLength)
DllCall("kernel32.dll", "none", "RtlZeroMemory", "ptr", $pDest, "dword", $iLength)
EndFunc
Global Const $OLE32 = DllOpen("ole32.dll")
Global Const $CLSCTX_INPROC_SERVER = 1
Global Const $HRESULT = "lresult"
Global Const $S_OK = 0
Global Const $E_NOINTERFACE = 0x80004002
Global Const $E_NOTIMPL = 0x80004001
Global Const $E_OUTOFMEMORY = 0x8007000E
Global Const $E_POINTER = 0x80004003
Global Const $OLE_E_ADVISENOTSUPPORTED = 0x80040003
Global $IID_IUnknown = _GUID("{00000000-0000-0000-C000-000000000046}")
Global Const $tagIID = "DWORD Data1;  ushort Data2;  ushort Data3;  BYTE Data4[8];"
Func _GUID($IID)
$IID = StringRegExpReplace($IID,"([}{])","")
$IID = StringSplit($IID,"-")
Local $_GUID = "DWORD Data1;  ushort Data2;  ushort Data3;  BYTE Data4[8];"
Local $GUID = DllStructCreate($_GUID)
If $IID[0] = 5 Then $IID[4] &= $IID[5]
If $IID[0] > 5 Or $IID[0] < 4 Then Return SetError(1,0,0)
DllStructSetData($GUID,1,Dec($IID[1]))
DllStructSetData($GUID,2,Dec($IID[2]))
DllStructSetData($GUID,3,Dec($IID[3]))
DllStructSetData($GUID,4,Binary("0x"&$IID[4]))
Return $GUID
EndFunc
Func _GUID_Compare(ByRef $IID1, ByRef $IID2)
Local $a,$b
For $i = 1 To 4
$a = DllStructGetData($IID1,$i)
If @error Then Return SetError(1,0,0)
$b = DllStructGetData($IID2,$i)
If @error Then Return SetError(1,0,0)
If $a <> $b Then Return 0
Next
Return 1
EndFunc
Global Const $IUnknown_vTable = "ptr QueryInterface; ptr AddRef; ptr Release;"
Func _IUnknown_AddRef(ByRef $ObjArr)
Local $ret = _ObjFuncCall("ULONG", $ObjArr, "AddRef")
If @error Then Return SetError(1,0,0)
Return SetError($ret[0]<1,0,$ret[0])
EndFunc
Func _IUnknown_Release(ByRef $ObjArr)
Local $ret = _ObjFuncCall("ULONG", $ObjArr, "Release")
If @error Then Return SetError(1,0,0)
Return SetError($ret[0],0,$ret[0]=0)
EndFunc
Global $__COMFN_HookPtr, $__COMFN_HookBak, $__COMFN_HookApi = "LocalCompact", $__COMFN_Kernel32Dll = DllOpen("kernel32.dll")
Func _ObjFuncInit()
Local $KernelHandle = DllCall($__COMFN_Kernel32Dll, "ptr", "LoadLibrary", "str", "kernel32.dll")
Local $HookPtr = DllCall($__COMFN_Kernel32Dll, "ptr", "GetProcAddress", "ptr", $KernelHandle[0], "str", $__COMFN_HookApi)
$__COMFN_HookPtr = $HookPtr[0]
$__COMFN_HookBak = DllStructCreate("ubyte[7]")
DllCall($__COMFN_Kernel32Dll, "int", "WriteProcessMemory", "ptr", -1, "ptr", DllStructGetPtr($__COMFN_HookBak), "ptr", $__COMFN_HookPtr, "uint", 7, "uint*", 0)
DllCall($__COMFN_Kernel32Dll, "int", "WriteProcessMemory", "ptr", -1, "ptr", $__COMFN_HookPtr, "byte*", 0xB8, "uint", 1, "uint*", 0)
DllCall($__COMFN_Kernel32Dll, "int", "WriteProcessMemory", "ptr", -1, "ptr", $__COMFN_HookPtr + 5, "ushort*", 0xE0FF, "uint", 2, "uint*", 0)
EndFunc
Func _ObjFuncCall($RetType, ByRef $ObjArr, $sFuncName, $Type1 = "", $Param1 = 0, $Type2 = "", $Param2 = 0, $Type3 = "", $Param3 = 0, $Type4 = "", $Param4 = 0, $Type5 = "", $Param5 = 0, $Type6 = "", $Param6 = 0, $Type7 = "", $Param7 = 0, $Type8 = "", $Param8 = 0, $Type9 = "", $Param9 = 0, $Type10 = "", $Param10 = 0, $Type11 = "", $Param11 = 0, $Type12 = "", $Param12 = 0, $Type13 = "", $Param13 = 0, $Type14 = "", $Param14 = 0, $Type15 = "", $Param15 = 0, $Type16 = "", $Param16 = 0, $Type17 = "", $Param17 = 0, $Type18 = "", $Param18 = 0, $Type19 = "", $Param19 = 0, $Type20 = "", $Param20 = 0)
If Not IsDllStruct($__COMFN_HookBak) Then _ObjFuncInit()
Local $Address = _ObjGetFuncPtr($ObjArr,$sFuncName)
If @error Then Return SetError(1,-1,0)
If $Address = 0 Then Return SetError(3,-1,0)
_ObjFuncSet($Address)
Local $Ret
Switch @NumParams
Case 3
$Ret = DllCall($__COMFN_Kernel32Dll, $RetType, $__COMFN_HookApi, "ptr", $ObjArr[0])
Case 5
$Ret = DllCall($__COMFN_Kernel32Dll, $RetType, $__COMFN_HookApi, "ptr", $ObjArr[0], $Type1, $Param1)
Case 7
$Ret = DllCall($__COMFN_Kernel32Dll, $RetType, $__COMFN_HookApi, "ptr", $ObjArr[0], $Type1, $Param1, $Type2, $Param2)
Case 9
$Ret = DllCall($__COMFN_Kernel32Dll, $RetType, $__COMFN_HookApi, "ptr", $ObjArr[0], $Type1, $Param1, $Type2, $Param2, $Type3, $Param3)
Case 11
$Ret = DllCall($__COMFN_Kernel32Dll, $RetType, $__COMFN_HookApi, "ptr", $ObjArr[0], $Type1, $Param1, $Type2, $Param2, $Type3, $Param3, $Type4, $Param4)
Case 13
$Ret = DllCall($__COMFN_Kernel32Dll, $RetType, $__COMFN_HookApi, "ptr", $ObjArr[0], $Type1, $Param1, $Type2, $Param2, $Type3, $Param3, $Type4, $Param4, $Type5, $Param5)
Case Else
If Mod(@NumParams,2)=0 Then Return SetError(2,-1,0)
Local $DllCallStr = 'DllCall($__COMFN_Kernel32Dll, $RetType, $__COMFN_HookApi, "ptr", $ObjArr[0]', $n, $i
For $i = 5 To @NumParams Step 2
$n =($i - 3) / 2
$DllCallStr &= ', $Type' & $n & ', $Param' & $n
Next
$DllCallStr &= ')'
$Ret = Execute($DllCallStr)
EndSwitch
SetError(@error,@extended)
Return $Ret
EndFunc
Func _ObjFuncSet($Address)
DllCall($__COMFN_Kernel32Dll, "int", "WriteProcessMemory", "ptr", -1, "ptr", $__COMFN_HookPtr + 1, "uint*", $Address, "uint", 4, "uint*", 0)
EndFunc
Func _ObjCreateFromPtr($ObjPointer, $vTable)
If Not $ObjPointer Then Return SetError(1,0,0)
Local $object[3] = [$ObjPointer]
$object[1] = DllStructCreate("ptr lpvTable",Ptr($object[0]))
If @error Then Return SetError(2,0 ,0)
$object[2] = DllStructCreate($vTable,DllStructGetData($object[1],1))
If @error Then Return SetError(3,0,0)
Return $object
EndFunc
Func _ObjCoCreateInstance(ByRef $CLSID,ByRef $IID,$ObjvTable)
Local $ret = DllCall($OLE32,"long_ptr","CoCreateInstance","ptr",DllStructGetPtr($CLSID),"ptr",0,"dword",$CLSCTX_INPROC_SERVER, "ptr",DllStructGetPtr($IID),"ptr*",0)
Local $object[3] = [$ret[5],0,0]
$object[1] = DllStructCreate("ptr lpvTable",$object[0])
$object[2] = DllStructCreate($ObjvTable,DllStructGetData($object[1],1))
Return $object
EndFunc
Func _ObjGetFuncPtr(ByRef $ObjArr, $FuncName)
If UBound($ObjArr)<>3 Then Return SetError(1,0,0)
Return DllStructGetData($ObjArr[2],$FuncName)
EndFunc
Func _ObjGetObjPtr(ByRef $ObjArr)
If UBound($ObjArr)<>3 Then Return SetError(1,0,0)
If DllStructGetData($ObjArr[1],1)=0 Then Return SetError(2,0,0)
Return $ObjArr[0]
EndFunc
Func _OLEInitialize()
Local $result = DllCall($OLE32,$HRESULT,"OleInitialize","ptr",0)
Return $result[0]
EndFunc
Func _OLEUnInitialize()
Local $result = DllCall($OLE32,$HRESULT,"OleUninitialize")
Return $result[0]
EndFunc
Func _CoTaskMemAlloc($iSize)
Local $result = DllCall($OLE32, "ptr", "CoTaskMemAlloc", "ulong", $iSize)
Return $result[0]
EndFunc
Func _CoTaskMemFree($pMem)
DllCall($OLE32, "none", "CoTaskMemFree", "ptr", $pMem)
EndFunc
Global Const $DRAGDROP_S_DROP = 0x40100
Global Const $DRAGDROP_S_CANCEL = 0x40101
Global Const $DRAGDROP_S_USEDEFAULTCURSORS = 0x40102
Global Const $DROPEFFECT_NONE = 0
Global Const $DROPEFFECT_COPY = 1
Global Const $DROPEFFECT_MOVE = 2
Global Const $DROPEFFECT_LINK = 4
Global Const $DROPEFFECT_SCROLL = 0x80000000
Global $IID_IDropTarget = _GUID("{00000122-0000-0000-C000-000000000046}")
Global Const $IDropSource_vTable = $IUnknown_vTable & "ptr QueryContinueDrag; ptr GiveFeedback;"
Global Const $tagIDropSource = "ptr vTable; dword dwRefCount;"
Global $IID_IDropSource = _GUID("{00000121-0000-0000-C000-000000000046}")
Global Const $__IDropSource_vTable = DllStructCreate($IDropSource_vTable)
Func _CreateIDropSource()
Local $hMem = _MemGlobalAlloc(_DragDrop_SIZEOF($tagIDropSource),$GPTR)
Local $IDropSource[3] = [$hMem, DllStructCreate($tagIDropSource,$hMem), $__IDropSource_vTable]
DllStructSetData($IDropSource[1], 1, DllStructGetPtr($__IDropSource_vTable))
__IDropSource_AddRef($hMem)
Return $IDropSource
EndFunc
Func _ReleaseIDropSource(ByRef $IDropSource)
Local $res = _ObjFuncCall("ulong",$IDropSource,"Release")
If @error Then Return SetError(1,0,-1)
If $res[0] = 0 Then
$IDropSource = 0
EndIf
Return $res[0]
EndFunc
Global Const $__IDropSource_QueryInterface = DllCallbackRegister("__IDropSource_QueryInterface", $HRESULT, "ptr;ptr;ptr")
DllStructSetData($__IDropSource_vTable, "QueryInterface", DllCallbackGetPtr($__IDropSource_QueryInterface))
Global Const $__IDropSource_AddRef = DllCallbackRegister("__IDropSource_AddRef", $HRESULT, "ptr")
DllStructSetData($__IDropSource_vTable, "AddRef", DllCallbackGetPtr($__IDropSource_AddRef))
Global Const $__IDropSource_Release = DllCallbackRegister("__IDropSource_Release", $HRESULT, "ptr")
DllStructSetData($__IDropSource_vTable, "Release", DllCallbackGetPtr($__IDropSource_Release))
Global Const $__IDropSource_QueryContinueDrag = DllCallbackRegister("__IDropSource_QueryContinueDrag", $HRESULT, "ptr;int;dword")
DllStructSetData($__IDropSource_vTable, "QueryContinueDrag", DllCallbackGetPtr($__IDropSource_QueryContinueDrag))
Global Const $__IDropSource_GiveFeedback = DllCallbackRegister("__IDropSource_GiveFeedback", $HRESULT, "ptr;dword")
DllStructSetData($__IDropSource_vTable, "GiveFeedback", DllCallbackGetPtr($__IDropSource_GiveFeedback))
Func __IDropSource_QueryInterface($pObject, $iid, $ppvObject)
If $ppvObject = 0 Or $iid = 0 Then Return $E_NOINTERFACE
Local $stIID = DllStructCreate($tagIID, $iid), $pvObject = DllStructCreate("ptr", $ppvObject)
If _GUID_Compare($stIID, $IID_IDropSource) Or _GUID_Compare($stIID, $IID_IUnknown) Then
DllStructSetData($pvObject, 1, $pObject)
__IDropSource_AddRef($pObject)
Return $S_OK
EndIf
DllStructSetData($pvObject,1, 0)
Return $E_NOINTERFACE
EndFunc
Func __IDropSource_AddRef($pObject)
Local $st = DllStructCreate("ptr;dword", $pObject)
Local $iCount = DllStructGetData($st, 2) + 1
DllStructSetData($st, 2, $iCount)
Return $iCount
EndFunc
Func __IDropSource_Release($pObject)
Local $st = DllStructCreate("ptr;dword", $pObject)
Local $iCount = DllStructGetData($st, 2) - 1
If $iCount < 0 Then Return 0
DllStructSetData($st,2,$iCount)
Return $iCount
EndFunc
Func __IDropSource_QueryContinueDrag($pObject, $fEscapePressed, $grfKeyState)
Select
Case $fEscapePressed <> 0
Return $DRAGDROP_S_CANCEL
Case Not BitAND($grfKeyState, $MK_LBUTTON)
Return $DRAGDROP_S_DROP
Case Else
Return $S_OK
EndSelect
EndFunc
Func __IDropSource_GiveFeedback($pObject, $dwEffect)
Select
Case $dwEffect = $DROPEFFECT_NONE
Case BitAND($dwEffect, $DROPEFFECT_LINK) = $DROPEFFECT_LINK
Case BitAND($dwEffect, $DROPEFFECT_MOVE) = $DROPEFFECT_MOVE
Case BitAND($dwEffect, $DROPEFFECT_COPY) = $DROPEFFECT_COPY
Case BitAND($dwEffect, $DROPEFFECT_SCROLL) = $DROPEFFECT_SCROLL
Case Else
Return $E_INVALIDARG
EndSelect
Return $DRAGDROP_S_USEDEFAULTCURSORS
EndFunc
Global Const $tagFORMATETC = "dword cfFormat; ptr ptd; DWORD  dwAspect; LONG lindex; DWORD tymed;"
Global Const $tagSTGMEDIUM = "DWORD tymed; ptr hGlobal; ptr pUnkForRelease;"
Global Const $sizeFORMATETC = _DragDrop_SIZEOF($tagFORMATETC)
Global Const $sizeSTGMEDIUM = _DragDrop_SIZEOF($tagSTGMEDIUM)
Global Const $tagDVTARGETDEVICE = "DWORD tdSize; USHORT  tdDriverNameOffset; USHORT  tdDeviceNameOffset; USHORT  tdPortNameOffset; USHORT  tdExtDevmodeOffset; BYTE  tdData[1];"
Global Const $tagIDataObject = "ptr vTable; dword dwRefCount; dword Count; ptr pFORMATETC; ptr pSTGMEDIUM;"
Global Const $TYMED_HGLOBAL = 1
Global Const $TYMED_FILE = 2
Global Const $TYMED_ISTREAM = 4
Global Const $TYMED_ISTORAGE = 8
Global Const $TYMED_GDI = 16
Global Const $TYMED_MFPICT = 32
Global Const $TYMED_ENHMF = 64
Global Const $TYMED_NULL = 0
Global Const $DVASPECT_CONTENT = 1
Global Const $DATADIR_GET = 1
Global $IID_IDataObject = _GUID("{0000010E-0000-0000-C000-000000000046}")
Global Const $DV_E_FORMATETC = 0x80040064
Global Const $DATA_E_FORMATETC = $DV_E_FORMATETC
Global Const $OLE_S_USEREG = 0x00040000
Global Const $IDataObject_vTable = $IUnknown_vTable & "ptr GetData; ptr GetDataHere; ptr QueryGetData; ptr GetCanonicalFormatEtc; " & "ptr SetData; ptr EnumFormatEtc; ptr DAdvise; ptr DUnadvise; ptr EnumDAdvise; "
Global Const $__IDataObj_QueryInterface = DllCallbackRegister( "__IDataObj_QueryInterface", $HRESULT, "ptr;ptr;ptr")
Global Const $__IDataObj_AddRef = DllCallbackRegister( "__IDataObj_AddRef", "ULONG", "ptr")
Global Const $__IDataObj_Release = DllCallbackRegister( "__IDataObj_Release", "ULONG", "ptr")
Global Const $__IDataObj_GetData = DllCallbackRegister( "__IDataObj_GetData", $HRESULT, "ptr;ptr;ptr")
Global Const $__IDataObj_GetDataHere = DllCallbackRegister( "__IDataObj_GetDataHere", $HRESULT, "ptr;ptr;ptr")
Global Const $__IDataObj_QueryGetData = DllCallbackRegister( "__IDataObj_QueryGetData", $HRESULT, "ptr;ptr")
Global Const $__IDataObj_GetCanonicalFormatEtc = DllCallbackRegister( "__IDataObj_GetCanonicalFormatEtc", $HRESULT, "ptr;ptr;ptr")
Global Const $__IDataObj_SetData = DllCallbackRegister( "__IDataObj_SetData", $HRESULT, "ptr;ptr;ptr;int")
Global Const $__IDataObj_EnumFormatEtc = DllCallbackRegister( "__IDataObj_EnumFormatEtc", $HRESULT, "ptr;dword;ptr")
Global Const $__IDataObj_DAdvise = DllCallbackRegister( "__IDataObj_DAdvise", $HRESULT, "ptr;ptr;DWORD;ptr;ptr")
Global Const $__IDataObj_DUnadvise = DllCallbackRegister( "__IDataObj_DUnadvise", $HRESULT, "ptr;dword")
Global Const $__IDataObj_EnumDAdvise = DllCallbackRegister( "__IDataObj_EnumDAdvise", $HRESULT, "ptr;ptr")
Global Const $__IDataObj_vTable = DllStructCreate($IDataObject_vTable)
DllStructSetData($__IDataObj_vTable, "QueryInterface", DllCallbackGetPtr($__IDataObj_QueryInterface))
DllStructSetData($__IDataObj_vTable, "AddRef", DllCallbackGetPtr($__IDataObj_AddRef))
DllStructSetData($__IDataObj_vTable, "Release", DllCallbackGetPtr($__IDataObj_Release))
DllStructSetData($__IDataObj_vTable, "GetData", DllCallbackGetPtr($__IDataObj_GetData))
DllStructSetData($__IDataObj_vTable, "GetDataHere", DllCallbackGetPtr($__IDataObj_GetDataHere))
DllStructSetData($__IDataObj_vTable, "QueryGetData", DllCallbackGetPtr($__IDataObj_QueryGetData))
DllStructSetData($__IDataObj_vTable, "GetCanonicalFormatEtc", DllCallbackGetPtr($__IDataObj_GetCanonicalFormatEtc))
DllStructSetData($__IDataObj_vTable, "SetData", DllCallbackGetPtr($__IDataObj_SetData))
DllStructSetData($__IDataObj_vTable, "EnumFormatEtc", DllCallbackGetPtr($__IDataObj_EnumFormatEtc))
DllStructSetData($__IDataObj_vTable, "DAdvise", DllCallbackGetPtr($__IDataObj_DAdvise))
DllStructSetData($__IDataObj_vTable, "DUnadvise", DllCallbackGetPtr($__IDataObj_DUnadvise))
DllStructSetData($__IDataObj_vTable, "EnumDAdvise", DllCallbackGetPtr($__IDataObj_EnumDAdvise))
Func __IDataObj_QueryInterface($pObject, $iid, $ppvObject)
Local $stIID = DllStructCreate($tagIID, $iid), $pvObject = DllStructCreate("ptr", $ppvObject)
If _GUID_Compare($stIID, $IID_IDataObject) Or _GUID_Compare($stIID, $IID_IUnknown) Then
__IDataObj_AddRef($pObject)
DllStructSetData($pvObject,1, $pObject)
Return $S_OK
EndIf
DllStructSetData($pvObject,1, 0)
Return $E_NOINTERFACE
EndFunc
Func __IDataObj_AddRef($pObject)
Local $st = DllStructCreate($tagIDataObject, $pObject)
Local $iCount = DllStructGetData($st, "dwRefCount") + 1
DllStructSetData($st, "dwRefCount", $iCount)
Return $iCount
EndFunc
Func __IDataObj_Release($pObject)
Local $st = DllStructCreate($tagIDataObject, $pObject)
Local $iCount = DllStructGetData($st, "dwRefCount") - 1
DllStructSetData($st, "dwRefCount", $iCount)
If $iCount = 0 Then
Local $pFORMATETC = DllStructGetData($st, "pFORMATETC")
Local $pSTGMEDIUM = DllStructGetData($st, "pSTGMEDIUM")
Local $STGMED = DllStructCreate($tagSTGMEDIUM)
Local $FMTETC = DllStructCreate($tagFORMATETC)
Local $pSTGMED = DllStructGetPtr($STGMED)
Local $pFMTETC = DllStructGetPtr($FMTETC)
For $i = 0 To DllStructGetData($st, "Count")-1
_MemArrayGet($pFORMATETC, $i, $pFMTETC)
If DllStructGetData($FMTETC, "ptd") Then _CoTaskMemFree(DllStructGetData($FMTETC, "ptd"))
_MemArrayGet($pSTGMEDIUM, $i, $pSTGMED)
_ReleaseStgMedium($STGMED)
Next
_MemArrayFree($pFORMATETC)
_MemArrayFree($pSTGMEDIUM)
_MemGlobalFree($pObject)
EndIf
Return $iCount
EndFunc
Func __IDataObj_GetData($pObject, $pFormatEtc, $pMedium)
If $pMedium = 0 Or $pFormatEtc = 0 Then Return $E_POINTER
Local $st = DllStructCreate($tagIDataObject, $pObject)
Local $dwCount = DllStructGetData($st, "Count")
Local $pArrFormatEtc = DllStructGetData($st, "pFORMATETC")
Local $idx = __DataObj_LookupFormatEtc($pFormatEtc, $pArrFormatEtc, $dwCount)
If $idx == -1 Then Return $DV_E_FORMATETC
Local $stFORMATETC = DllStructCreate($tagFORMATETC, $pFormatEtc)
Local $tymed = DllStructGetData(_MemArrayGet($pArrFormatEtc, $idx, $tagFORMATETC),"tymed")
Local $Medium = DllStructCreate($tagSTGMEDIUM,$pMedium)
DllStructSetData($Medium,"tymed", $tymed)
DllStructSetData($Medium,"pUnkForRelease", 0)
Switch $tymed
Case $TYMED_ENHMF, $TYMED_GDI, $TYMED_HGLOBAL, $TYMED_MFPICT, $TYMED_NULL, $TYMED_ISTREAM, $TYMED_ISTORAGE
Local $IntMedium = _MemArrayGet(DllStructGetData($st,"pSTGMEDIUM"), $idx, $tagSTGMEDIUM)
If Not DeepCopyStgMedium($pMedium, DllStructGetPtr($IntMedium)) Then Return $DV_E_FORMATETC
Case Else
return $DV_E_FORMATETC
EndSwitch
Return $S_OK
EndFunc
Func __IDataObj_GetDataHere($pObject, $pFormatEtc, $pMedium)
Return $DATA_E_FORMATETC
EndFunc
Func __IDataObj_QueryGetData($pObject, $pFormatEtc)
Local $st = DllStructCreate($tagIDataObject, $pObject)
Return _Iif( __DataObj_LookupFormatEtc($pFormatEtc, DllStructGetData($st, "pFORMATETC"), DllStructGetData($st, "Count")) = -1, $DV_E_FORMATETC, $S_OK)
EndFunc
Func __IDataObj_GetCanonicalFormatEtc($pObject, $pFormatEtc, $pFormatEtcOut)
Local $FormatEtcOut = DllStructCreate($tagFORMATETC, $pFormatEtcOut)
DllStructSetData($FormatEtcOut, "ptd", 0)
Return $E_NOTIMPL
EndFunc
Func __IDataObj_SetData($pObject, $pFormatEtc, $pMedium, $fRelease)
Local $STGMED = DllStructCreate($tagSTGMEDIUM,$pMedium)
Switch DllStructGetData($STGMED,"tymed")
Case $TYMED_ENHMF, $TYMED_GDI, $TYMED_HGLOBAL, $TYMED_MFPICT, $TYMED_NULL, $TYMED_ISTREAM, $TYMED_ISTORAGE
Case Else
If Not $fRelease And DllStructGetData($STGMED,"tymed")=$TYMED_FILE Then Return $DV_E_FORMATETC
EndSwitch
If Not $fRelease Then
$STGMED = DllStructCreate($tagSTGMEDIUM)
Local $FormatEtc = DllStructCreate($tagFORMATETC)
If Not DeepCopyStgMedium(DllStructGetPtr($STGMED) , $pMedium) Then Return $E_OUTOFMEMORY
DeepCopyFormatEtc(DllStructGetPtr($FormatEtc) , $pFormatEtc)
$pMedium = DllStructGetPtr($STGMED)
$pFormatEtc = DllStructGetPtr($FormatEtc)
EndIf
Local $st = DllStructCreate($tagIDataObject, $pObject)
Local $pArrFormatEtc = DllStructGetData($st, "pFORMATETC")
Local $pArrStgMedium = DllStructGetData($st, "pSTGMEDIUM")
Local $dwCount = DllStructGetData($st, "Count")
Local $idx = __DataObj_LookupFormatEtc($pFormatEtc, $pArrFormatEtc, $dwCount)
If $idx == -1 Then
_MemArrayAdd($pArrFormatEtc, $pFormatEtc)
_MemArrayAdd($pArrStgMedium, $pMedium)
DllStructSetData($st, "Count", $dwCount+1)
Else
Local $ptd = DllStructGetData(_MemArrayGet($pArrFormatEtc, $idx, $tagFORMATETC),"ptd")
If $ptd Then _CoTaskMemFree($ptd)
_MemArraySet($pArrFormatEtc, $idx, $pFormatEtc)
Local $Med = _MemArrayGet($pArrStgMedium, $idx, $tagSTGMEDIUM)
_ReleaseStgMedium($Med)
_MemArraySet($pArrStgMedium, $idx, $pMedium)
EndIf
If DllStructGetData($STGMED,"pUnkForRelease") = $pObject Then
Local $IUnk = _ObjCreateFromPtr($pMedium,$IUnknown_vTable)
_IUnknown_Release($IUnk)
EndIf
Return $S_OK
EndFunc
Func __IDataObj_EnumFormatEtc($pObject, $dwDirection, $ppEnumFormatEtc)
Switch $dwDirection
Case $DATADIR_GET
Local $st = DllStructCreate($tagIDataObject, $pObject)
Local $pFORMATETC = DllStructGetData($st, "pFORMATETC")
Local $result = DllCall("shell32.dll", $HRESULT, "SHCreateStdEnumFmtEtc", "uint", DllStructGetData($st, "Count"), "ptr", __MemArrayLockedPtr($pFORMATETC), "ptr*", 0)
__MemArrayUnLock($pFORMATETC)
Local $pEnumFormatEtc = DllStructCreate("ptr",$ppEnumFormatEtc)
DllStructSetData($pEnumFormatEtc,1,$result[3])
Return _Iif($result[3]=0, $E_OUTOFMEMORY, $S_OK)
Case Else
Return $OLE_S_USEREG
EndSwitch
EndFunc
Func __IDataObj_DAdvise($pObject, $pFormatEtc, $advf, $pAdvSink, $pdwConnection)
Return $OLE_E_ADVISENOTSUPPORTED
EndFunc
Func __IDataObj_DUnadvise($pObject, $dwConnection)
Return $OLE_E_ADVISENOTSUPPORTED
EndFunc
Func __IDataObj_EnumDAdvise($pObject, $ppEnumAdvise)
Return $OLE_E_ADVISENOTSUPPORTED
EndFunc
Func _DragDrop_SIZEOF($tagStruct)
Return DllStructGetSize(DllStructCreate($tagStruct, 1))
EndFunc
Func _CreateIDataObject(ByRef $fmtetc, ByRef $stgmed)
If Not IsArray($fmtetc) Or UBound($fmtetc) <> UBound($stgmed) Then Return SetError(1, 0, 0)
Local $iCount = UBound($fmtetc)
Local $sizeIDataObj = _DragDrop_SIZEOF($tagIDataObject)
Local $pObj = _MemGlobalAlloc($sizeIDataObj, $GPTR)
Local $pFORMATETC = _MemArrayCreate($tagFORMATETC)
Local $pSTGMEDIUM = _MemArrayCreate($tagSTGMEDIUM)
Local $stObj = DllStructCreate($tagIDataObject, $pObj)
DllStructSetData($stObj, "vTable", DllStructGetPtr($__IDataObj_vTable))
DllStructSetData($stObj, "dwRefCount", 1)
DllStructSetData($stObj, "Count", $iCount)
DllStructSetData($stObj, "pFORMATETC", $pFORMATETC)
For $i = 0 To $iCount - 1
_MemArrayAdd($pFORMATETC, $fmtetc[$i])
Next
DllStructSetData($stObj, "pSTGMEDIUM", $pSTGMEDIUM)
For $i = 0 To $iCount - 1
_MemArrayAdd($pSTGMEDIUM, $stgmed[$i])
Next
Local $result[3] = [$pObj, $stObj, $__IDataObj_vTable]
Return $result
EndFunc
Func _ReleaseIDataObject(ByRef $IDataObj)
Local $res = _ObjFuncCall("ulong",$IDataObj,"Release")
If @error Then Return SetError(1,0,-1)
If $res[0] = 0 Then
$IDataObj = 0
EndIf
Return $res[0]
EndFunc
Func DeepCopyStgMedium($pDest, $pSource)
__MemCopyMemory($pSource,$pDest,$sizeSTGMEDIUM)
Local $stSource = DllStructCreate($tagSTGMEDIUM,$pSource)
Local $Souce_tymed = DllStructGetData($stSource,"tymed")
Local $data = DllStructGetData($stSource,"hGlobal"), $newData
Switch $Souce_tymed
Case $TYMED_NULL
Return True
Case $TYMED_HGLOBAL
$newData = _CloneHGLOBAL($data)
Case $TYMED_GDI
$newData = _CloneBitmap($data)
Case $TYMED_ENHMF
$newData = _CloneEnhMetaFile($data)
Case $TYMED_MFPICT
$newData = _CloneMetaFile($data)
Case $TYMED_ISTREAM, $TYMED_ISTORAGE
Local $IUnk = _ObjCreateFromPtr($data,$IUnknown_vTable)
_IUnknown_AddRef($IUnk)
Return True
Case Else
Return False
EndSwitch
If DllStructGetData($stSource,"pUnkForRelease") Then
Local $IUnk = _ObjCreateFromPtr(DllStructGetData($stSource,"pUnkForRelease"),$IUnknown_vTable)
_IUnknown_AddRef($IUnk)
EndIf
DllStructSetData(DllStructCreate($tagSTGMEDIUM,$pDest),"hGlobal",$newData)
Return True
EndFunc
Func _CloneBitmap($hBmp)
Local $result = DllCall("user32.dll", "ptr", "CopyImage", "ptr", $hBmp, "uint", 0, "int",0, "int",0, "uint", 0)
Return $result[0]
EndFunc
Func _CloneEnhMetaFile($hemfSrc)
Local $result = DllCall("Gdi32.dll", "ptr", "CopyEnhMetaFileW", "ptr", $hemfSrc, "ptr", 0)
Return $result[0]
EndFunc
Func _CloneMetaFile($hemfSrc)
Local $result = DllCall("Gdi32.dll", "ptr", "CopyMetaFileW", "ptr", $hemfSrc, "ptr", 0)
Return $result[0]
EndFunc
Func _CloneHGLOBAL($hMem)
Local $Size = _MemGlobalSize($hMem)
Local $Flags = __MemGlobalFlags($hMem)
If $Flags = $GMEM_INVALID_HANDLE Then Return SetError(1,0,0)
Local $hNewMem = _MemGlobalAlloc($Size,$Flags)
Local $pNewMem = _MemGlobalLock($hNewMem)
Local $pMem = _MemGlobalLock($hMem)
__MemCopyMemory($pMem, $pNewMem, $Size)
_MemGlobalUnlock($hNewMem)
_MemGlobalUnlock($hMem)
Return $hNewMem
EndFunc
Func DeepCopyFormatEtc($pDest, $pSource)
__MemCopyMemory($pSource,$pDest,$sizeFORMATETC)
Local $Souce_ptd = DllStructGetData(DllStructCreate($tagFORMATETC,$pSource),"ptd")
if($Souce_ptd) Then
Local $dest_ptd = _CoTaskMemAlloc(_DragDrop_SIZEOF($tagDVTARGETDEVICE))
__MemCopyMemory($Souce_ptd, $dest_ptd, _DragDrop_SIZEOF($tagDVTARGETDEVICE))
DllStructSetData(DllStructCreate($tagFORMATETC,$pDest),"ptd",$dest_ptd)
EndIf
EndFunc
Func __DataObj_LookupFormatEtc($pFormatEtc, $pAvailableFormats, $dwCount)
Local $FormatEtc = DllStructCreate($tagFORMATETC, $pFormatEtc), $next
For $i = 0 To $dwCount - 1
$next = _MemArrayGet($pAvailableFormats, $i, $tagFORMATETC)
If((DllStructGetData($next, 1) = DllStructGetData($FormatEtc, 1) ) And(DllStructGetData($next, 3) = DllStructGetData($FormatEtc, 3) ) And(DllStructGetData($next, 4) = DllStructGetData($FormatEtc, 4) ) And(BitAND(DllStructGetData($next, 5), DllStructGetData($FormatEtc, 5)) <> 0 ) ) Then
Return $i
EndIf
Next
Return -1
EndFunc
Func _ReleaseStgMedium(ByRef $stgmed)
Local $ptr
If IsDllStruct($stgmed) Then
$ptr = DllStructGetPtr($stgmed)
ElseIf IsPtr($stgmed) Then
$ptr = $stgmed
Else
Return SetError(1)
EndIf
DllCall("ole32.dll","none", "ReleaseStgMedium", "ptr", $ptr)
EndFunc
Func _DoDragDrop(ByRef $objIDataSource, ByRef $objIDropSource, $dwDropEffects, ByRef $dwPerformedEffect)
Local $result = DllCall($OLE32,$HRESULT,"DoDragDrop", "ptr", _ObjGetObjPtr($objIDataSource),"ptr", _ObjGetObjPtr($objIDropSource), "dword", BitOR($DROPEFFECT_MOVE,$DROPEFFECT_COPY,$DROPEFFECT_LINK), "dword*", 0)
$dwPerformedEffect = $result[4]
Return $result[0]
EndFunc
Global Const $DROPFILES = "DWORD pFiles; int pt[2]; int fNC; int fWide;"
Global Const $CF_HDROP = 15
Func _CreateHDROP_FORMATETC()
Local $FMTETC = DllStructCreate($tagFORMATETC)
DllStructSetData($FMTETC,1,$CF_HDROP)
DllStructSetData($FMTETC,2,0)
DllStructSetData($FMTETC,3,$DVASPECT_CONTENT)
DllStructSetData($FMTETC,4,-1)
DllStructSetData($FMTETC,5,$TYMED_HGLOBAL)
Return $FMTETC
EndFunc
Func _CreateDROPFILES($Files)
$Files = String($Files)
$hMem = _MemGlobalAlloc(_DragDrop_SIZEOF($DROPFILES) +((StringLen($Files)+2)*2),$GPTR)
$Files = StringSplit($Files,"|")
$stDROPFILES = DllStructCreate($DROPFILES,$hMem)
$hPtr = $hMem + DllStructGetSize($stDROPFILES)
DllStructSetData($stDROPFILES, "fWide", 1)
DllStructSetData($stDROPFILES, 1, DllStructGetSize($stDROPFILES))
For $i = 1 To $Files[0]
$next = DllStructCreate("wchar[" & StringLen($Files[$i])+1 & "]", $hPtr)
DllStructSetData($next,1,$Files[$i] & ChrW(0))
$hPtr +=(StringLen($Files[$i])+1)*2
Next
$next = DllStructCreate("wchar[1]", $hPtr)
DllStructSetData($next,1,ChrW(0))
Return $hMem
EndFunc
Func _CreateDROPFILES_STGMEDIUM($Files)
Local $STGMD = DllStructCreate($tagSTGMEDIUM)
DllStructSetData($STGMD,1,$TYMED_HGLOBAL)
Local $DF = _CreateDROPFILES($Files)
If Not $DF Then Return SetError(1,0,0)
DllStructSetData($STGMD,2,$DF)
Return $STGMD
EndFunc
_OLEInitialize()
Global $objIDropSource = _CreateIDropSource()
Global Const $DI_GETDRAGIMAGE = "ShellGetDragImage"
Global Const $WM_DI_GETDRAGIMAGE = _WinAPI_RegisterWindowMessage($DI_GETDRAGIMAGE)
Global Const $CFSTR_PERFORMEDDROPEFFECT = "Performed DropEffect"
Global Const $CF_PERFORMEDDROPEFFECT = _WinAPI_RegisterWindowMessage($CFSTR_PERFORMEDDROPEFFECT)
Global Const $tagSHDRAGIMAGE = "long sizeDragImage[2];long ptOffset[2]; ptr hbmpDragImage; dword crColorKey;"
Global $CLSID_DragDropHelper = _GUID("4657278A-411B-11D2-839A-00C04FD918D0")
Global $IID_IDragSourceHelper = _GUID("DE5BF786-477A-11D2-839D00C04FD918D0")
Global $IID_IDropTargetHelper =  _GUID("4657278B-411B-11D2-839A00C04FD918D0")
Global $IDragSourceHelper_vTable = $IUnknown_vTable & "ptr InitializeFromBitmap; ptr InitializeFromWindow;"
Func _SetBMP(ByRef $IDragSourceHelper, ByRef $IDataObject)
Local $SHDRAGIMAGE = DllStructCreate($tagSHDRAGIMAGE)
Local $hBmp = _WinAPI_LoadImage(0,"C:\Windows\Feder.bmp",0,0,0,$LR_LOADFROMFILE)
DllStructSetData($SHDRAGIMAGE,"hbmpDragImage",$hBmp)
DllStructSetData($SHDRAGIMAGE,"sizeDragImage",96,1)
DllStructSetData($SHDRAGIMAGE,"sizeDragImage",96,2)
DllStructSetData($SHDRAGIMAGE,"ptOffset",45,1)
DllStructSetData($SHDRAGIMAGE,"ptOffset",69,2)
DllStructSetData($SHDRAGIMAGE,"crColorKey",0x00FF00FF)
_ObjFuncCall($HRESULT, $IDragSourceHelper, "InitializeFromBitmap", "ptr", DllStructGetPtr($SHDRAGIMAGE), "ptr", _ObjGetObjPtr($IDataObject))
EndFunc
Func _MemGlobalGetValue($hMem, $DataType, $Offset=0)
If _MemGlobalSize($hMem) < __MemArray_SIZEOF($DataType) Then Return SetError(1,0,0)
Local $hPtr = _MemGlobalLock($hMem)
If Not $hPtr Then Return SetError(2,0,0)
Local $Data = DllStructGetData(DllStructCreate($DataType,$hPtr+$Offset),1)
If @error Then Return SetError(1,_MemGlobalUnlock($hMem))
_MemGlobalUnlock($hMem)
Return $Data
EndFunc
Func _GetUnoptimizedEffect(ByRef $objIDataSource, $Effect)
Local $FormatEtc = _CreateHDROP_FORMATETC()
DllStructSetData($FormatEtc,1,$CF_PERFORMEDDROPEFFECT)
Local $result = _ObjFuncCall($HRESULT, $objIDataSource, "QueryGetData", "ptr", DllStructGetPtr($FormatEtc))
If $S_OK = $result[0] Then
Local $StgMedium = DllStructCreate($tagSTGMEDIUM)
$result = _ObjFuncCall($HRESULT, $objIDataSource, "GetData", "ptr", DllStructGetPtr($FormatEtc), "ptr", DllStructGetPtr($StgMedium))
If $S_OK = $result[0] Then
$Effect = _MemGlobalGetValue(DllStructGetData($StgMedium,"hGlobal"),"dword")
EndIf
_ReleaseStgMedium($StgMedium)
EndIf
Return $Effect
EndFunc
Global $__g_GUICtrlMenuEx_UseCallback
Func _GUICtrlMenuEx_Startup($UseCallback = Default)
If IsKeyword($UseCallback) Then
If __GUICtrlMenuEx_VistaAndLater() Then
$UseCallback = False
Else
$UseCallback = True
EndIf
EndIf
If $UseCallback Then
GUIRegisterMsg($WM_DRAWITEM, "__GUICtrlMenuEx_WM_DRAWITEM")
GUIRegisterMsg($WM_MEASUREITEM, "__GUICtrlMenuEx_WM_MEASUREITEM")
Else
GUIRegisterMsg($WM_DRAWITEM, "")
GUIRegisterMsg($WM_MEASUREITEM, "")
EndIf
$__g_GUICtrlMenuEx_UseCallback = $UseCallback
EndFunc
Func _GUICtrlMenuEx_SetItemIcon($Menu, $Item, $Icon, $ByPos = True)
If $Icon Then
If $__g_GUICtrlMenuEx_UseCallback Then
$Icon = _WinAPI_CopyIcon($Icon)
Local $MENUITEMINFO = _GUICtrlMenu_GetItemInfo($Menu, $Item, $ByPos)
DllStructSetData($MENUITEMINFO, "Mask", $MIIM_BITMAP)
DllStructSetData($MENUITEMINFO, "BmpItem", -1)
_GUICtrlMenu_SetItemInfo($Menu, $Item, $MENUITEMINFO, $ByPos)
_GUICtrlMenu_SetItemData($Menu, $Item, $Icon)
Else
Local $Bitmap = __GUICtrlMenuEx_CreateBitmapFromIcon($Icon)
_GUICtrlMenu_SetItemBmp($Menu, $Item, $Bitmap, $ByPos)
EndIf
Return True
EndIf
Return False
EndFunc
Func _GUICtrlMenuEx_AddMenuItem($Menu, $Text, $CmdID = 0, $Icon = 0, $SubMenu = 0)
Local $Index = _GUICtrlMenu_AddMenuItem($Menu, $Text, $CmdID, $SubMenu)
_GUICtrlMenuEx_SetItemIcon($Menu, $Index, $Icon)
Return $Index
EndFunc
Func _GUICtrlMenuEx_AddMenuBar($Menu)
Local $Item = _GUICtrlMenu_AddMenuItem($Menu, "")
_GUICtrlMenu_SetItemType($Menu, $Item, $MFT_SEPARATOR)
EndFunc
Func _GUICtrlMenuEx_DeleteMenu($Menu, $Item, $ByPos = True)
If $__g_GUICtrlMenuEx_UseCallback Then
Local $Icon = _GUICtrlMenu_GetItemData($Menu, $Item, $ByPos)
_WinAPI_DestroyIcon($Icon)
Else
Local $Bitmap = _GUICtrlMenu_GetItemBmp($Menu, $Item, $ByPos)
_WinAPI_DeleteObject($Bitmap)
EndIf
Return _GUICtrlMenu_DeleteMenu($Menu, $Item, $ByPos)
EndFunc
Func _GUICtrlMenuEx_DestroyMenu($Menu)
Local $Count = _GUICtrlMenu_GetItemCount($Menu)
For $i = 1 To $Count
_GUICtrlMenuEx_DeleteMenu($Menu, 0)
Next
Return _GUICtrlMenu_DestroyMenu($Menu)
EndFunc
Func __GUICtrlMenuEx_WM_MEASUREITEM($hWnd, $Msg, $wParam, $lParam)
If $__g_GUICtrlMenuEx_UseCallback Then
Local $MeasureItem = DllStructCreate('UINT CtlType;UINT CtlID;UINT itemID;UINT itemWidth;UINT itemHeight;ULONG_PTR itemData', $lParam)
If DllStructGetData($MeasureItem, "CtlType") = 1 Then
Local $Icon = DllStructGetData($MeasureItem, "itemData")
If $Icon Then
Local $Size = __GUICtrlMenuEx_GetIconSize($Icon)
DllStructSetData($MeasureItem, "itemWidth", $Size[0])
DllStructSetData($MeasureItem, "itemHeight", $Size[1])
Return TRUE
EndIf
EndIf
EndIf
Return 0
EndFunc
Func __GUICtrlMenuEx_WM_DRAWITEM($hWnd, $Msg, $wParam, $lParam)
If $__g_GUICtrlMenuEx_UseCallback Then
Local $DrawItem = DllStructCreate('UINT CtlType;UINT CtlID;UINT itemID;UINT itemAction;UINT itemState;HWND hwndItem;HWND hDC;INT rcItem[4];ULONG_PTR itemData', $lParam)
If DllStructGetData($DrawItem, "CtlType") = 1 Then
Local $Icon = DllStructGetData($DrawItem, "itemData")
If $Icon Then
Local $hDC = DllStructGetData($DrawItem, "hDC")
Local $Left = DllStructGetData($DrawItem, "rcItem", 1)
Local $Top = DllStructGetData($DrawItem, "rcItem", 2)
_WinAPI_DrawIconEx($hDC, $Left / 2, $Top, $Icon, 0, 0, 0, 0, 3)
EndIf
Return TRUE
EndIf
EndIf
Return 0
EndFunc
Func __GUICtrlMenuEx_GetIconSize($Icon)
Local Const $tagBITMAP = "LONG bmType;LONG bmWidth;LONG bmHeight;LONG bmWidthBytes;WORD bmPlanes;WORD bmBitsPixel;ptr bmBits"
Local $IconInfo = _WinAPI_GetIconInfo($Icon)
Local $BITMAP = DllStructCreate($tagBITMAP)
_WinAPI_GetObject($IconInfo[5], DllStructGetSize($BITMAP), DllStructGetPtr($BITMAP))
Local $Width = DllStructGetData($BITMAP, "bmWidth")
Local $Height = DllStructGetData($BITMAP, "bmHeight")
_WinAPI_DeleteObject($IconInfo[4])
_WinAPI_DeleteObject($IconInfo[5])
Local $Ret[2] = [$Width, $Height]
Return $Ret
EndFunc
Func __GUICtrlMenuEx_CreateBitmapFromIcon($Icon)
Switch @OSVersion
Case "WIN_2008R2", "WIN_7", "WIN_2008", "WIN_VISTA"
Return __GUICtrlMenuEx_CreateBitmapFromIcon_Vista($Icon)
Case Else
Return __GUICtrlMenuEx_CreateBitmapFromIcon_XP($Icon)
EndSwitch
EndFunc
Func __GUICtrlMenuEx_CreateBitmapFromIcon_XP($Icon)
Local $Size = __GUICtrlMenuEx_GetIconSize($Icon)
Local $DC = _WinAPI_GetDC(0)
Local $DestDC = _WinAPI_CreateCompatibleDC($DC)
Local $Bitmap = _WinAPI_CreateSolidBitmap(0, _WinAPI_GetSysColor($COLOR_MENU), $Size[0], $Size[1])
Local $OldBitmap = _WinAPI_SelectObject($DestDC, $Bitmap)
If $OldBitmap > 0 Then
_WinAPI_DrawIconEx($DestDC, 0, 0, $Icon, 0, 0, 0, 0, 3)
_WinAPI_SelectObject($DestDC, $OldBitmap)
EndIf
_WinAPI_ReleaseDC(0, $DC)
_WinAPI_DeleteDC($DestDC)
Return $Bitmap
EndFunc
Func __GUICtrlMenuEx_CreateBitmapFromIcon_Vista($Icon)
Local $Size = __GUICtrlMenuEx_GetIconSize($Icon)
Local $DestDC = _WinAPI_CreateCompatibleDC(0)
Local $Bitmap = __GUICtrlMenuEx_Create32BitHBITMAP($DestDC, $Size)
Local $OldBitmap = _WinAPI_SelectObject($DestDC, $Bitmap)
If $OldBitmap > 0 Then
Local $BlendFunction = DllStructCreate("BYTE BlendOp; BYTE BlendFlags; BYTE SourceConstantAlpha; BYTE AlphaFormat")
DllStructSetData($BlendFunction, 1, 0)
DllStructSetData($BlendFunction, 2, 0)
DllStructSetData($BlendFunction, 3, 255)
DllStructSetData($BlendFunction, 4, 1)
Local $PaintParams = DllStructCreate("DWORD Size; DWORD Flags; ptr Exclude; ptr BlendFunction")
DllStructSetData($PaintParams, "Size", DllStructGetSize($PaintParams))
DllStructSetData($PaintParams, "Flags", 1)
DllStructSetData($PaintParams, "BlendFunction", DllStructGetPtr($BlendFunction))
Local $Rect = DllStructCreate($tagRECT)
DllStructSetData($Rect, "Right", $Size[0])
DllStructSetData($Rect, "Bottom", $Size[1])
Local $PaintBuffer = __GUICtrlMenuEx_BeginBufferedPaint($DestDC, DllStructGetPtr($Rect), 1, DllStructGetPtr($PaintParams))
If Not @Error And $PaintBuffer[0] Then
If _WinAPI_DrawIconEx($PaintBuffer[1], 0, 0, $Icon, 0, 0, 0, 0, 3) Then
__GUICtrlMenuEx_ConvertBufferToPARGB32($PaintBuffer[0], $DestDC, $Icon, $Size)
EndIf
__GUICtrlMenuEx_EndBufferedPaint($PaintBuffer[0], True)
EndIf
_WinAPI_SelectObject($DestDC, $OldBitmap)
EndIf
_WinAPI_DeleteDC($DestDC)
Return $Bitmap
EndFunc
Func __GUICtrlMenuEx_ConvertBufferToPARGB32($BufferedPaint, $hDC, $Icon, $Size)
Local $Row
Local $ARGBPtr = __GUICtrlMenuEx_GetBufferedPaintBits($BufferedPaint, $Row)
If $ARGBPtr Then
Local $ARGB = DllStructCreate("dword[" &($Size[0] * $Size[1]) & "]", $ARGBPtr)
If Not __GUICtrlMenuEx_HasAlpha($ARGB, $Size, $Row) Then
Local $IconInfo = _WinAPI_GetIconInfo($Icon)
If $IconInfo[4] Then
__GUICtrlMenuEx_ConvertToPARGB32($hDC, $ARGB, $IconInfo[4], $Size, $Row)
EndIf
_WinAPI_DeleteObject($IconInfo[4])
_WinAPI_DeleteObject($IconInfo[5])
EndIf
EndIf
EndFunc
Func __GUICtrlMenuEx_HasAlpha($ARGB, $Size, $Row)
Local $Delta = $Row - $Size[0]
Local $Pos = 1
For $Y = $Size[1] To 1 Step -1
For $X = $Size[0] To 1 Step -1
If BitAND(DllStructGetData($ARGB, 1, $Pos), 0xFF000000) Then
Return True
EndIf
$Pos += 1
Next
$Pos += $Delta
Next
Return False
EndFunc
Func __GUICtrlMenuEx_ConvertToPARGB32($hDC, ByRef $ARGB, $hBmp, $Size, $Row)
Local $BITMAPINFO = DllStructCreate($tagBITMAPINFO)
DllStructSetData($BITMAPINFO, "Size", DllStructGetSize($BITMAPINFO))
DllStructSetData($BITMAPINFO, "Planes", 1)
DllStructSetData($BITMAPINFO, "Compression", 0)
DllStructSetData($BITMAPINFO, "Width", $Size[0])
DllStructSetData($BITMAPINFO, "Height", $Size[1])
DllStructSetData($BITMAPINFO, "BitCount", 32)
Local $ARGBMask = DllStructCreate("dword[" &($Size[0] * $Size[1]) & "]")
If _WinAPI_GetDIBits($hDC, $hBmp, 0, $Size[1], DllStructGetPtr($ARGBMask), DllStructGetPtr($BITMAPINFO), 0) = $Size[1] Then
Local $Delta = $Row - $Size[0]
Local $Pos = 1
For $Y = $Size[1] To 1 Step -1
For $X = $Size[0] To 1 Step -1
If DllStructGetData($ARGBMask, 1, $Pos) Then
DllStructSetData($ARGB, 1, 0, $Pos)
Else
DllStructSetData($ARGB, 1, BitOR(DllStructGetData($ARGB, 1, $Pos), 0xFF000000), $Pos)
EndIf
$Pos += 1
Next
Next
EndIf
EndFunc
Func __GUICtrlMenuEx_Create32BitHBITMAP($hDC, $Size, $Bits = 0)
Local $BITMAPINFO = DllStructCreate($tagBITMAPINFO)
DllStructSetData($BITMAPINFO, "Size", DllStructGetSize($BITMAPINFO))
DllStructSetData($BITMAPINFO, "Planes", 1)
DllStructSetData($BITMAPINFO, "Compression", 0)
DllStructSetData($BITMAPINFO, "Width", $Size[0])
DllStructSetData($BITMAPINFO, "Height", $Size[1])
DllStructSetData($BITMAPINFO, "BitCount", 32)
Return __GUICtrlMenuEx_CreateDIBSection($hDC, DllStructGetPtr($BITMAPINFO), 0, $Bits, 0, 0)
EndFunc
Func __GUICtrlMenuEx_CreateDIBSection($hDC, $BMI, $Usage, $Bits, $Section, $Offset)
Local $Ret = DllCall("gdi32.dll", "hwnd", "CreateDIBSection", "hwnd", $hDC, "ptr", $BMI, "uint", $Usage, "ptr*", $Bits, "hwnd", $Section, "dword", $Offset)
If Not @Error Then
Return $Ret[0]
EndIf
Return SetError(1, 0, 0)
EndFunc
Func __GUICtrlMenuEx_BeginBufferedPaint($DCTarget, $RectTarget, $Format, $PaintParams)
Local $Ret = DllCall("UxTheme.dll", "hwnd", "BeginBufferedPaint", "hwnd", $DCTarget, "ptr", $RectTarget, "dword", $Format, "ptr", $PaintParams, "hwnd*", 0)
If Not @Error Then
Local $Array[2] = [$Ret[0], $Ret[5]]
Return $Array
EndIf
Return SetError(1, 0, 0)
EndFunc
Func __GUICtrlMenuEx_EndBufferedPaint($BufferedPaint, $UpdateTarget = True)
Local $Ret = DllCall("UxTheme.dll", "hwnd", "EndBufferedPaint", "hwnd", $BufferedPaint, "int", $UpdateTarget)
If Not @Error Then
Return $Ret[0]
EndIf
Return SetError(1, 0, 0)
EndFunc
Func __GUICtrlMenuEx_GetBufferedPaintBits($BufferedPaint, ByRef $Row)
Local $Ret = DllCall("UxTheme.dll", "int", "GetBufferedPaintBits", "hwnd", $BufferedPaint, "ptr*", 0, "int*", 0)
If Not @Error Then
$Row = $Ret[3]
Return $Ret[2]
EndIf
Return SetError(1, 0, 0)
EndFunc
Func __GUICtrlMenuEx_VistaAndLater()
Local $OSVI = DllStructCreate("DWORD OSVersionInfoSize; DWORD MajorVersion; DWORD MinorVersion; DWORD BuildNumber; DWORD PlatformId; wchar CSDVersion[128]")
DllStructSetData($OSVI, "OSVersionInfoSize", DllStructGetSize($OSVI))
DllCall("kernel32.dll", "bool", "GetVersionExW", "ptr", DllStructGetPtr($OSVI))
Return DllStructGetData($OSVI, "MajorVersion") >= 6
EndFunc
Opt("GUIOnEventMode", 1)
Opt("TrayOnEventMode", 1)
Opt("GUIResizeMode", 802)
Opt("MouseCoordMode", 0)
Opt("TrayMenuMode", 1)
OnAutoItExitRegister("_OnAutoItExit")
HotKeySet('+!i', 'ID')
$FilesDir = @ScriptDir & '\ICON'
Global $cover_put = @ScriptDir & "\ICON\music-default.jpg"
DirCreate($FilesDir)
FileInstall('music-default.jpg', $FilesDir & '\music-default.jpg')
FileInstall('test.png', $FilesDir & '\test.png')
_BASS_Startup("BASS.dll")
_BASS_PluginLoad("bassflac.dll")
_BASS_PluginLoad("bass_ape.dll")
_BASS_PluginLoad("basswma.dll")
_BASS_PluginLoad('bass_aac.dll')
_BASS_Init(0, -1, 44100, 0, "")
If @error Then
MsgBox(0, "Error Code: " & @error, "无法使用音频播放功能，请检查设备是否正常！", 4)
EndIf
Global $IDragSourceHelper = _ObjCoCreateInstance($CLSID_DragDropHelper, $IID_IDragSourceHelper, $IDragSourceHelper_vTable)
Global $Font1 = _WinAPI_CreateFont(14, 0, 0, 0, $FW_BOLD)
$ShellContextMenu = ObjCreate("ExplorerShellContextMenu.ShowContextMenu")
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
EndFunc
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
$hListView = GUICtrlCreateListView("      文件名        |歌名          |歌手       |   专辑        |  位速  | 大小  | 时长 |文件夹", 8, 92, 764, _Iif($onlylist = 2, 437, 214), BitOR($LVS_EDITLABELS, $LVS_REPORT, $LVS_SHOWSELALWAYS))
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
$Lrc_List = GUICtrlCreateListView('lyrics', 8, 346, _Iif($onlylist = 1, 764, 500), 190, BitOR($LVS_REPORT, $LVS_EDITLABELS, $LVS_NOCOLUMNHEADER))
_GUICtrlListView_SetExtendedListViewStyle(-1, BitOR($LVS_EX_FULLROWSELECT, $WS_EX_CLIENTEDGE, $LVS_EX_DOUBLEBUFFER))
GUICtrlSetResizing(-1, 582)
$hWndListView = GUICtrlGetHandle($hListView)
$lWndListView = GUICtrlGetHandle($Lrc_List)
_GUICtrlListView_SetColumnWidth(-1, 0, $LVSCW_AUTOSIZE_USEHEADER)
_GUICtrlListView_SetUnicodeFormat(-1, True)
_GUICtrlListView_JustifyColumn(-1, 0, $list_align)
GUICtrlSetFont(-1, $list_size, $list_xing, $list_var, $list_name)
GUICtrlSetColor(-1, $lrc_text_back_color)
GUICtrlSetBkColor(-1, $list_bk_color)
_GUICtrlListView_SetItemCount(-1, 6)
For $i = 0 To 5
GUICtrlCreateListViewItem($L[$i], $Lrc_List)
Next
GUICtrlCreateGroup("播放控制", 535, 8, 235, 80)
$Sound_Flag = GUICtrlCreateButton("=", 545, 48, 30, 25, $BS_FLAT)
GUICtrlSetFont(-1, 14, 800, 0, "Webdings")
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
$filter = GUICtrlCreateCombo("", 45, 69, 125, 21)
GUICtrlSetData(-1, "<\.mp3(?# 仅mp3文件)>|<^[\w\s\']+\.[\w]{2,4}(?# 仅英文文件名)>|<林俊杰(?# 指定歌手)>|<.*?(?# 所有歌曲)>", "")
$artist = GUICtrlCreateInput("", 180, 69, 82, 19)
GUICtrlSetTip(-1, '歌手')
$title = GUICtrlCreateInput("", 281, 69, 146, 19)
GUICtrlSetTip(-1, '歌名')
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
GUICtrlSetResizing(-1, 836)
$cover = GUICtrlCreatePic($cover_put, 553, 340, 182, 182)
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
GUIRegisterMsg(0x233, "WM_DROPFILES")
GUIRegisterMsg($WM_HSCROLL, "MY_WM_HSCROLL")
GUIRegisterMsg($WM_EXITSIZEMOVE, "WM_EXITSIZEMOVE")
GUIRegisterMsg($WM_SYSCOMMAND, "On_WM_SYSCOMMAND")
GUIRegisterMsg($WM_MOUSEWHEEL, "WM_MOUSEWHEEL")
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
$url = '/newlyric.lrc?' & _encode(_UrlToHex(StringFormat('user=377471152,LYRIC_1.2.1.5,KwLyric(1).exe,' & 'wmp&requester=localhost&type=full&req=3&songname=%s&artist=%s&path=%s&FileName=&zipsig=', $pre_get[2], $pre_get[1], $pre_get[0]), 1, 'ansi'))
If _CoProcSend($load_Pro, $host & '|' & $url & '|2' & '||||') Then
_ShowLoading()
Else
_ToolTip('错误', "Worker not Responding (" & @error & ")", 3, 3)
EndIf
ElseIf $mode = 4 Then
If _CoProcSend($load_Pro, 'www.5ilrc.com|/downlrc.asp|0||POST|gm_down=%31&id_gc=' & StringTrimLeft(StringTrimRight($pre_get[0], 4), 6)&'|http://www.5ilrc.com|Content-Type: application/x-www-form-urlencoded') Then
_ShowLoading()
Else
_ToolTip('错误', "Worker not Responding (" & @error & ")", 3, 3)
EndIf
ElseIf $mode = 9 Then
If _CoProcSend($load_Pro, 'music.qq.com|/miniportal/static/lyric/' & StringRight($pre_get[0], 2) & '/' & $pre_get[0] & '.xml|0||||') Then
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
$lrc_text = FileRead($root_folder & '\' & $bLVItems[$iSelected][7] & StringRegExpReplace($bLVItems[$iSelected][0], '\.(\w+)$', '') & '.lrc')
If @error Then Return
$lrc_Format = _lrc_Prase($lrc_text)
If UBound($lrc_Format, 0) = 2 Then
Update_L()
EndIf
Case $save_cover
Local $cover_name = StringRegExp($cover_put, '^.*\\(.*?)\.(\w+)$', 3, 1)
If @error Or $cover_put = @ScriptDir & "\ICON\music-default.jpg" Then Return
Local $Save_cover_Dir = FileSaveDialog('保存图片', $root_folder, '图像文件(*.' & $cover_name[1] & ')|所有文件(*.*)', 16, $cover_name[0] & '.' & $cover_name[1], $hGUI)
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
Return ShellExecute($s_url & _UrlToHex(GUICtrlRead($title), 1, 'ansi') & '+' &  _UrlToHex(GUICtrlRead($artist), 1, 'ansi'))
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
EndFunc
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
EndFunc
Func tray()
Switch @TRAY_ID
Case $tray_play
_Play()
Case $tray_stop
_StopPlay()
EndSwitch
EndFunc
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
_Chek_net($NetState[1], _Iif(($Ping[1] = -1) Or($Ping[2] = -1), 0,(Number($Ping[1]) + Number($Ping[2])) / 2))
_Chek_net($NetState[2], _Iif(($Ping[3] = -1) Or($Ping[4] = -1), 0,(Number($Ping[3]) + Number($Ping[4])) / 2))
_Chek_net($NetState[3], Number($Ping[5]))
_Chek_net($NetState[4], Number($Ping[6]))
_Chek_net($NetState[5], Number($Ping[7]))
_ExitLoading()
Case 0x24
_ToolTip("抱歉", "可能由于网络问题，导致无法获取数据", 3, 1)
Return _ExitLoading()
Case 0x25
BinaryToString(BinaryMid($vParameter, 2))
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
_Chek_net($NetState[1], _Iif(($Ping[1] = -1) Or($Ping[2] = -1), 0,(Number($Ping[1]) + Number($Ping[2])) / 2))
_Chek_net($NetState[2], _Iif(($Ping[3] = -1) Or($Ping[4] = -1), 0,(Number($Ping[3]) + Number($Ping[4])) / 2))
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
EndFunc
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
If UBound($lrc_Format, 0) <> 2 Then
GUICtrlSetColor($Lrc_List, $Ch)
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
$hListView_height -=(33 + $lrc_height)
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
EndFunc
Func _Play()
Local $lrc_exist
If $iSelected = -1 Then Return _ToolTip('错误', '请选择一首歌曲', 3)
If _BASS_ChannelIsActive($MusicHandle) = 0 Then
$MusicHandle = _BASS_StreamCreateFile(False, $root_folder & '\' & $bLVItems[$iSelected][7] & $bLVItems[$iSelected][0], 0, 0, 0)
If @error Then Return _ToolTip('错误', '未选中或其他错误' & @LF & '错误代码：' & @error, 3)
$length = _BASS_ChannelGetLength($MusicHandle, $BASS_POS_BYTE)
_BASS_ChannelPlay($MusicHandle, 1)
If(Not UBound($lrc_Format, 0) = 2) Or($current_song And $current_song <> $bLVItems[$iSelected][0]) Then
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
ElseIf UBound($lrc_Format, 0) = 2 Then
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
EndFunc
Func _StopPlay()
_Stop()
GUICtrlSetData($current_time, '00:00:00')
WinSetTitle($hGUI, '', '音乐管理器 v2.0')
EndFunc
Func _ToolBar()
$hToolbar = _GUICtrlToolbar_Create($hGUI)
_GUICtrlToolbar_SetExtendedStyle($hToolbar, $TBSTYLE_EX_DRAWDDARROWS)
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
_GUICtrlToolbar_AddButton($hToolbar, $idSet, $hToolBar_image[3], $hToolBar_strings[3])
_GUICtrlToolbar_AddButton($hToolbar, $idLst, $hToolBar_image[4], $hToolBar_strings[4])
_GUICtrlToolbar_AddButton($hToolbar, $idSav, $hToolBar_image[5], $hToolBar_strings[5], $BTNS_DROPDOWN)
_GUICtrlToolbar_AddButton($hToolbar, $idDat, $hToolBar_image[6], $hToolBar_strings[6], $BTNS_DROPDOWN)
EndFunc
Func _Setting_Gui()
$Setting = GUICreate("设置", 375, 260, 466, 121, -1, -1, $hGUI)
GUISetOnEvent($GUI_EVENT_CLOSE, "gui")
$Button1 = GUICtrlCreateButton("保存配置", 220, 232, 77, 25)
_GUICtrlButton_SetImageList(-1, _GetImageListHandle("icon.dll", 13), 0)
GUICtrlSetOnEvent(-1, "set")
$Button2 = GUICtrlCreateButton("关闭", 301, 232, 57, 25)
GUICtrlSetOnEvent(-1, "set")
$Setting_tab = GUICtrlCreateTab(5, 6, 365, 225)
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
EndFunc
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
EndFunc
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
EndFunc
Func _Save()
If IsArray($lrc_Format) Then
Local $temp_select = $iSelected
If $iSelected < 0 Then
$iSelected = 0
$bLVItems[0][0] = GUICtrlRead($title)
EndIf
If $lyr_changed And $toolbar_subitem[1] = 0 Then
$lrc_text = StringFormat('[ti:%s]' & @CRLF & '[ar:%s]' & @CRLF & '[al:%s]' & @CRLF & '[by:%s]' & @CRLF, DllStructGetData($l_head, 1), DllStructGetData($l_head, 2), DllStructGetData($l_head, 3), DllStructGetData($l_head, 4))
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
$Save_txt_dir = FileSaveDialog('选择保存的文件夹', $root_folder & '\' & $bLVItems[$iSelected][7], '文本文件(*.txt)|所有文件(*.*)', 16, GUICtrlRead($title) & '.txt', $hGUI)
If Not @error Then
FileWrite($Save_txt_dir, StringStripWS(StringRegExpReplace($lrc_text, '(?m)\[[^\]]+\]', ''), 3))
_ToolTip('保存成功', '现在可以到工作目录查看', 5, 1)
EndIf
ElseIf $toolbar_subitem[1] = 1 Then
$lrc_text = ''
For $i = 1 To UBound($lrc_Format) - 1
$lrc_text &= $i & @CRLF & '00:' & StringReplace(_TickToTime($lrc_Format[$i - 1][0]), '.', ',') & '0 --> 00:' & StringReplace(_TickToTime($lrc_Format[$i][0] - 1), '.', ',') & '0' & @CRLF & $lrc_Format[$i - 1][1] & @CRLF & @CRLF
Next
$lrc_text &= UBound($lrc_Format) & @CRLF & '00:' & StringReplace(_TickToTime($lrc_Format[UBound($lrc_Format) - 1][0]), '.', ',') & '0 --> 00:00:00,000' & @CRLF & $lrc_Format[UBound($lrc_Format) - 1][1] & @CRLF & @CRLF
$Dir = FileSaveDialog('选择保存的位置', '', '字幕文件(*.srt)|所有文件(*.*)', 16, StringRegExpReplace($bLVItems[$iSelected][0], '\.(\w+)$', '') & '.srt', $hGUI)
If Not @error Then
Local $lrc_file = FileOpen($Dir, 10)
FileWrite($lrc_file, $lrc_text)
FileClose($lrc_file)
_ToolTip('保存成功', '已保存至 ' & $Dir, 2, 1)
EndIf
Else
If $save_always_ask Or $temp_select < 0 Then
$Dir = FileSaveDialog('选择保存的位置', '', '歌词文件(*.lrc)|所有文件(*.*)', 16, StringRegExpReplace($bLVItems[$iSelected][0], '\.(\w+)$', '') & '.lrc', $hGUI)
Else
$Dir = $root_folder & '\' & $bLVItems[$iSelected][7] & StringRegExpReplace($bLVItems[$iSelected][0], '\.(\w+)$', '') & '.lrc'
If FileExists($Dir) Then
Local $oo = MsgBox(259, '提示', '存在同名文件，是否覆盖？' & @CRLF & '点否选择其他文件夹', 10, $hGUI)
If $oo = 7 Then
$Dir = FileSaveDialog('选择其他文件夹', '', '歌词文件(*.lrc)|所有文件(*.*)', 16, StringRegExpReplace($bLVItems[$iSelected][0], '\.(\w+)$', '') & '.lrc', $hGUI)
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
EndFunc
Func _FilterItem($keyword)
Local $num = 0, $temp, $mm, $j = 1, $k = 1, $key
If Not $keyword Then Return _FilterItem('<.*>')
StringRegExp($keyword, '\<[^\>]*$', 3, 1)
If $aLVItems[0] = 0 Or @error = 0 Then Return
ReDim $bLVItems[$aLVItems[0]][8]
If Not(StringLeft($keyword, 1) == '<') Then
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
EndFunc
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
EndFunc
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
$aLVItems[$sel_index] = StringFormat('%s|%s|%s|%s|%s|%s|%s|%s', $bLVItems[$iSelected][0], $bLVItems[$iSelected][1], $bLVItems[$iSelected][2], $bLVItems[$iSelected][3], $bLVItems[$iSelected][4], $bLVItems[$iSelected][5], $bLVItems[$iSelected][6], $bLVItems[$iSelected][7])
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
$intReturn = DllCall("shell32.dll", "int", "SHObjectProperties", "hwnd", 0, "dword", $SHOP_FILEPATH, "wstr", $sel_dir, "wstr", $sTab)
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
$cover_key_input = InputBox('专辑', '专辑名正确吗？' & @LF & '专辑未知可以尝试搜歌名或歌手名', $bLVItems[$iSelected][3], '', 300, 150, Default, Default, 30, $hGUI)
Else
$cover_key_input = InputBox('专辑', '请输入专辑名' & @LF & '专辑未知可以尝试搜歌名或歌手名', '', '', 300, 150, Default, Default, 30, $hGUI)
EndIf
If @error Or(Not $cover_key_input) Then Return $GUI_RUNDEFMSG
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
EndFunc
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
If Not @error And $bLVItems[$i][1] And $bLVItems[$i][2] Then $List_data &= StringFormat('#EXTINF:%s,%s - %s', Number($ti[1]) * 3600 + Number($ti[2]) * 60 + Number($ti[3]), $bLVItems[$i][2], $bLVItems[$i][1]) & @CRLF
$List_data &= $root_folder & '\' & $bLVItems[$i][7] & $bLVItems[$i][0] & @CRLF
Next
Local $m3u_file = FileOpen($List_Dir, 10)
FileWrite($m3u_file, $List_data)
FileClose($m3u_file)
Case $idDat
_Search($toolbar_subitem[0])
EndSwitch
Return
EndFunc
Func _StatusBar_Click()
$load_flag = 1
If _CoProcSend($load_Pro, 'ping|' & $isCnc) Then
_ShowLoading()
Else
_ToolTip('错误', "Worker not Responding (" & @error & ")", 3, 3)
EndIf
EndFunc
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
_GUICtrlListView_EditLabel($Lrc_List, $lyr_select[1])
EndSwitch
$lyr_changed = True
EndFunc
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
Else
_ToolTip('tips', 'Error on DoDragDrop', 3, 1)
EndIf
_ReleaseIDataObject($objIDataSource)
Return GUISetStyle(-1, 0x00000010, $hGUI)
Case 3
Local $aRect = _GUICtrlListView_GetSubItemRect($IWndListView, 15, 1)
Local $aPos = ControlGetPos($ID3_dial, '', $IWndListView)
Local $text = FileRead($LyricsFile)
$hEdit = _GUICtrlEdit_Create($ID3_dial, $text, $aPos[0] + $aRect[0], $aPos[1] + $aRect[1], 120, 20, BitOR($WS_CHILD, $WS_VISIBLE, $ES_AUTOHSCROLL, $ES_LEFT))
_GUICtrlEdit_SetSel($hEdit, 0, -1)
_WinAPI_SetFocus($hEdit)
_WinAPI_BringWindowToTop($hEdit)
EndSwitch
Return
EndFunc
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
EndFunc
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
EndFunc
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
EndFunc
Func Check_Prop()
If Not WinExists('[CLASS:#32770;TITLE:' & $prop_item & ']', '') Then
Local $iSelected = _ArraySearch($bLVItems, $prop_item, 1, 0, 0, 1, 1)
GUICtrlSendToDummy($ListMenu, $reload_item)
AdlibUnRegister('Check_Prop')
EndIf
EndFunc
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
EndFunc
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
Func GUIGetBkColor($hHandle)
Local $bGetBkColor, $hDC
$hDC = _WinAPI_GetDC($hHandle)
$bGetBkColor = _WinAPI_GetBkColor($hDC)
_WinAPI_ReleaseDC($hHandle, $hDC)
Return $bGetBkColor
EndFunc
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
_ReleaseIDropSource($objIDropSource)
_OLEUnInitialize()
_IUnknown_Release($IDragSourceHelper)
_BASS_PluginFree(0)
_BASS_Free()
$_Free = 1
_ID3DeleteFiles()
Exit
EndFunc
Func _OnAutoItExit()
If $_Free = 0 Then _exit()
EndFunc
Func ID()
GUICtrlSendToDummy($ListMenu, $id3_item)
EndFunc
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
$iMenuID = _GUICtrlMenu_TrackPopupMenu($hMenu, $hToolbar, $aRet[0], $aRet[1], 1, 1, 2)
_GUICtrlMenu_DestroyMenu($hMenu)
If Not $iMenuID Then Return $TBDDRET_DEFAULT
GUICtrlSendToDummy($TbarMenu, $iMenuID)
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
Case $LVN_COLUMNCLICK
Local $iFormat, $asc
If $Changed <> -1 Or _GUICtrlListView_GetItemCount($hWndListView) <= 1 Then Return $GUI_RUNDEFMSG
$tInfo = DllStructCreate($tagNMLISTVIEW, $LParam)
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
_GUICtrlListView_SetItemCount($hWndListView, UBound($bLVItems))
__GUICtrlListView_AddArray($hListView, $bLVItems)
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
If FileExists($root_folder & '\' & $bLVItems[$iSelected][7] & StringRegExpReplace($bLVItems[$iSelected][0], '\.(\w+)$', '') & '.lrc') Then GUICtrlSetState($l_btn_header, $GUI_ENABLE)
Else
If Not FileExists($root_folder & '\' & $bLVItems[$iSelected][7] & StringRegExpReplace($bLVItems[$iSelected][0], '\.(\w+)$', '') & '.lrc') Then GUICtrlSetState($l_btn_header, $GUI_DISABLE)
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
Local $tBuffer = DllStructCreate("wchar Text[" & DllStructGetData($tInfo, "TextMax") & "]", DllStructGetData($tInfo, "Text"))
$pre_name = DllStructGetData($tBuffer, "Text")
GUICtrlSendToDummy($FileChange, 1)
If StringLen($pre_name) Then Return True
EndSwitch
Case $lWndListView
Switch $code
Case $NM_CLICK
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
Case $LVN_ENDLABELEDITW
Local $tInfo = DllStructCreate($tagNMLVDISPINFO, $LParam)
$Index = DllStructGetData($tInfo, "Item")
Local $tBuffer = DllStructCreate("wchar Text[" & DllStructGetData($tInfo, "TextMax") & "]", DllStructGetData($tInfo, "Text"))
Local $sNewText = DllStructGetData($tBuffer, "Text")
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
Local $tBuffer = DllStructCreate("wchar Text[" & DllStructGetData($tInfo, "TextMax") & "]", DllStructGetData($tInfo, "Text"))
If StringLen(DllStructGetData($tBuffer, "Text")) Then Return True
EndSwitch
EndSwitch
Return $GUI_RUNDEFMSG
EndFunc
Func MY_WM_HSCROLL($hWnd, $msg, $WParam, $LParam)
Local $slide, $s_show, $time_pos
Local $nScrollCode, $nPos, $hwndScrollBar, $hwnd_slider
$nScrollCode = BitAND($WParam, 0x0000FFFF)
$nPos = BitShift($WParam, 16)
$hwndScrollBar = $LParam
$hwnd_slider = GUICtrlGetHandle($slider)
Switch $hwndScrollBar
Case $hwnd_slider
Switch $nScrollCode
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
EndFunc
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
EndFunc
Func On_WM_SYSCOMMAND($hWnd, $msg, $WParam, $LParam)
Switch BitAND($WParam, 0xFFF0)
Case $SC_SIZE
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
EndFunc
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
Return $GUI_RUNDEFMSG
EndFunc
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
Return 0
EndFunc
Func ClientToScreen($hWnd, ByRef $x, ByRef $y)
Local $stPoint = DllStructCreate("int;int")
DllStructSetData($stPoint, 1, $x)
DllStructSetData($stPoint, 2, $y)
DllCall("user32.dll", "int", "ClientToScreen", "hwnd", $hWnd, "ptr", DllStructGetPtr($stPoint))
$x = DllStructGetData($stPoint, 1)
$y = DllStructGetData($stPoint, 2)
$stPoint = 0
EndFunc
Func _GetToolbarButtonScreenPos($hWnd, $hTbar, $iCmdID, $iOffset = 0, $iIndex = 0, $hRbar = -1)
Local $aBorders, $aBandRect, $aRect, $tpoint, $pPoint, $aRet[2]
Local $aRect = _GUICtrlToolbar_GetButtonRect($hTbar, $iCmdID)
If Not IsArray($aRect) Then Return SetError(@error, 0, "")
$tpoint = DllStructCreate("int X;int Y")
DllStructSetData($tpoint, "X", $aRect[0])
DllStructSetData($tpoint, "Y", $aRect[3])
$pPoint = DllStructGetPtr($tpoint)
DllCall("User32.dll", "int", "ClientToScreen", "hwnd", $hWnd, "ptr", $pPoint)
If @error Then Return SetError(@error, 0, "")
$aRet[0] = DllStructGetData($tpoint, "X")
If $aRet[0] < 0 Then $aRet[0] = 0
$aRet[1] = DllStructGetData($tpoint, "Y") + Number($iOffset)
If $hRbar <> -1 And IsHWnd($hRbar) And IsNumber($iIndex) Then
$aBorders = _GUICtrlRebar_GetBandBorders($hRbar, $iIndex)
If Not IsArray($aBorders) Then Return SetError(@error, 0, "")
$aBandRect = _GUICtrlRebar_GetBandRect($hRbar, $iIndex)
If Not IsArray($aBandRect) Then Return SetError(@error, 0, "")
If $aRet[0] <> 0 Then $aRet[0] +=($aBorders[0] - $aBandRect[0])
EndIf
Return $aRet
EndFunc
Func _WinAPI_ShellExtractIcons($Icon, $Index, $Width, $Height)
Local $Ret = DllCall('shell32.dll', 'int', 'SHExtractIconsW', 'wstr', $Icon, 'int', $Index, 'int', $Width, 'int', $Height, 'ptr*', 0, 'ptr*', 0, 'int', 1, 'int', 0)
If @error Or $Ret[0] = 0 Or $Ret[5] = Ptr(0) Then Return SetError(1, 0, 0)
Return $Ret[5]
EndFunc
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
If Not(StringInStr($rfolder, $root_folder, 1) And $root_folder) Then
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
$aLVItems[$new_count] = StringFormat('%s|%s|%s|%s|%s|%s|%s|%s', $bLVItems[$Data_Count - 1][0], $bLVItems[$Data_Count - 1][1], $bLVItems[$Data_Count - 1][2], $bLVItems[$Data_Count - 1][3], $bLVItems[$Data_Count - 1][4], $bLVItems[$Data_Count - 1][5], $bLVItems[$Data_Count - 1][6], $bLVItems[$Data_Count - 1][7])
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
EndFunc
