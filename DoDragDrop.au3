#include <memory.au3>
#include "MemArray.au3"
#include "objbase.au3"
#include <Misc.au3>
#include <WinAPI.au3>
#include <Constants.au3>
;+------------------------------------------------------------------------+
;|                                                                        |
;| UDF for OLE-DragDrop                                                   |
;| Author: Prog@ndy                                                       |
;|                                                                        |
;+------------------------------------------------------------------------+

;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
;!!                                                                      !!
;!! VARIABLES AND FUNCTIONS WITH DOUBLE UNDERSCORE ARE INTERNAL USE ONLY !!
;!!                                                                      !!
;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

;~ Global Const $MK_LBUTTON = 1

Global Const $DRAGDROP_S_DROP = 0x40100
Global Const $DRAGDROP_S_CANCEL = 0x40101
Global Const $DRAGDROP_S_FIRST = 0x40100
Global Const $DRAGDROP_S_LAST = 0x4010F
Global Const $DRAGDROP_S_USEDEFAULTCURSORS = 0x40102
Global Const $DRAGDROP_E_NOTREGISTERED = 0x80040100
Global Const $DRAGDROP_E_INVALIDHWND = 0x80040102
Global Const $DRAGDROP_E_LAST = 0x8004010F
Global Const $DRAGDROP_E_FIRST = 0x80040100
Global Const $DRAGDROP_E_ALREADYREGISTERED = 0x80040101
Global Const $DRAGLISTMSGSTRING = "commctrl_DragListMsg"
;~ typedef enum tagDROPEFFECT
;~ {
Global Const $DROPEFFECT_NONE = 0
Global Const $DROPEFFECT_COPY = 1
Global Const $DROPEFFECT_MOVE = 2
Global Const $DROPEFFECT_LINK = 4
Global Const $DROPEFFECT_SCROLL = 0x80000000
;~ }

Global $IID_IDropTarget = _GUID("{00000122-0000-0000-C000-000000000046}")

; -- #Region IDropSource -------------------------------------------------------------
#Region IDropSource

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
EndFunc   ;==>__IDropSource_QueryInterface

Func __IDropSource_AddRef($pObject)
	Local $st = DllStructCreate("ptr;dword", $pObject)
	Local $iCount = DllStructGetData($st, 2) + 1
	DllStructSetData($st, 2, $iCount)
	Return $iCount
EndFunc   ;==>__IDropSource_AddRef

Func __IDropSource_Release($pObject)
	Local $st = DllStructCreate("ptr;dword", $pObject)
	Local $iCount = DllStructGetData($st, 2) - 1
	If $iCount < 0 Then Return 0
	DllStructSetData($st,2,$iCount)
	Return $iCount
EndFunc   ;==>__IDropSource_Release

Func __IDropSource_QueryContinueDrag($pObject, $fEscapePressed, $grfKeyState)
	Select
		Case $fEscapePressed <> 0
			Return $DRAGDROP_S_CANCEL
		Case Not BitAND($grfKeyState, $MK_LBUTTON)
			Return $DRAGDROP_S_DROP
		Case Else
			Return $S_OK
	EndSelect
EndFunc   ;==>__IDropSource_QueryContinueDrag

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
EndFunc   ;==>__IDropSource_GiveFeedback

#EndRegion
; -- #EndRegion IDropSource -------------------------------------------------------------

; -- #Region IDataObject -------------------------------------------------------------
#Region IDataObject

Global Const $tagFORMATETC = "dword cfFormat; ptr ptd; DWORD  dwAspect; LONG lindex; DWORD tymed;"
Global Const $tagSTGMEDIUM = "DWORD tymed; ptr hGlobal; ptr pUnkForRelease;"
Global Const $sizeFORMATETC = _DragDrop_SIZEOF($tagFORMATETC)
Global Const $sizeSTGMEDIUM = _DragDrop_SIZEOF($tagSTGMEDIUM)

Global Const $tagDVTARGETDEVICE = "DWORD tdSize; USHORT  tdDriverNameOffset; USHORT  tdDeviceNameOffset; USHORT  tdPortNameOffset; USHORT  tdExtDevmodeOffset; BYTE  tdData[1];"


Global Const $tagIDataObject = "ptr vTable; dword dwRefCount; dword Count; ptr pFORMATETC; ptr pSTGMEDIUM;"
    Global Const $TYMED_HGLOBAL     = 1 
    Global Const $TYMED_FILE        = 2 
    Global Const $TYMED_ISTREAM     = 4 
    Global Const $TYMED_ISTORAGE    = 8 
    Global Const $TYMED_GDI         = 16 
    Global Const $TYMED_MFPICT      = 32 
    Global Const $TYMED_ENHMF       = 64 
    Global Const $TYMED_NULL        = 0 
    Global Const $DVASPECT_CONTENT    = 1 
    Global Const $DVASPECT_THUMBNAIL  = 2 
    Global Const $DVASPECT_ICON       = 4 
    Global Const $DVASPECT_DOCPRINT   = 8 
    Global Const $DATADIR_GET = 1 
    Global Const $DATADIR_SET = 2



Global $IID_IDataObject = _GUID("{0000010E-0000-0000-C000-000000000046}")

Global Const $DV_E_FORMATETC = 0x80040064
Global Const $DATA_E_FORMATETC = $DV_E_FORMATETC
Global Const $DV_E_TYMED = 0x80040069
Global Const $OLE_S_USEREG = 0x00040000

Global Const $IDataObject_vTable = $IUnknown_vTable & _ 
						"ptr GetData; ptr GetDataHere; ptr QueryGetData; ptr GetCanonicalFormatEtc; " & _ 
						"ptr SetData; ptr EnumFormatEtc; ptr DAdvise; ptr DUnadvise; ptr EnumDAdvise; "
						
Global Const $__IDataObj_QueryInterface = DllCallbackRegister( "__IDataObj_QueryInterface", $HRESULT, "ptr;ptr;ptr")
Global Const $__IDataObj_AddRef = DllCallbackRegister( "__IDataObj_AddRef", "ULONG", "ptr")
Global Const $__IDataObj_Release = DllCallbackRegister( "__IDataObj_Release", "ULONG", "ptr")

Global Const $__IDataObj_GetData = DllCallbackRegister( "__IDataObj_GetData", $HRESULT, "ptr;ptr;ptr")
Global Const $__IDataObj_GetDataHere = DllCallbackRegister( "__IDataObj_GetDataHere", $HRESULT, "ptr;ptr;ptr")
Global Const $__IDataObj_QueryGetData = DllCallbackRegister( "__IDataObj_QueryGetData", $HRESULT, "ptr;ptr")
Global Const $__IDataObj_GetCanonicalFormatEtc = DllCallbackRegister( "__IDataObj_GetCanonicalFormatEtc", $HRESULT, "ptr;ptr;ptr")
Global Const $__IDataObj_SetData  = DllCallbackRegister( "__IDataObj_SetData", $HRESULT, "ptr;ptr;ptr;int")
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

; Author: Prog@ndy
Func __IDataObj_QueryInterface($pObject, $iid, $ppvObject)
	Local $stIID = DllStructCreate($tagIID, $iid), $pvObject = DllStructCreate("ptr", $ppvObject)
;~ 	ConsoleWrite(_WinAPI_StringFromGUID($iid) & @CRLF) 
	If _GUID_Compare($stIID, $IID_IDataObject) Or _GUID_Compare($stIID, $IID_IUnknown) Then
		__IDataObj_AddRef($pObject)
		DllStructSetData($pvObject,1, $pObject)
		Return $S_OK
	EndIf
	DllStructSetData($pvObject,1, 0)
	Return $E_NOINTERFACE
EndFunc   ;==>__IDataObj_QueryInterface

; Author: Prog@ndy
Func __IDataObj_AddRef($pObject)
	Local $st = DllStructCreate($tagIDataObject, $pObject)
	Local $iCount = DllStructGetData($st, "dwRefCount") + 1
	DllStructSetData($st, "dwRefCount", $iCount)
	Return $iCount
EndFunc   ;==>__IDataObj_AddRef

; Author: Prog@ndy
Func __IDataObj_Release($pObject)
	Local $st = DllStructCreate($tagIDataObject, $pObject)
	Local $iCount = DllStructGetData($st, "dwRefCount") - 1
	DllStructSetData($st, "dwRefCount", $iCount)
	If $iCount = 0 Then
		;[[[ Array
			Local $pFORMATETC = DllStructGetData($st, "pFORMATETC")
			Local $pSTGMEDIUM = DllStructGetData($st, "pSTGMEDIUM")
			Local $STGMED = DllStructCreate($tagSTGMEDIUM)
			Local $FMTETC = DllStructCreate($tagFORMATETC)
;~ 			Local $STGMED
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
		;]]] Array
		_MemGlobalFree($pObject)
	EndIf
	Return $iCount
EndFunc   ;==>__IDataObj_Release

; Author: Prog@ndy
Func __IDataObj_GetData($pObject, $pFormatEtc, $pMedium)
	If $pMedium = 0 Or $pFormatEtc = 0 Then Return $E_POINTER
	Local $st = DllStructCreate($tagIDataObject, $pObject)
	Local $dwCount = DllStructGetData($st, "Count")
	Local $pArrFormatEtc = DllStructGetData($st, "pFORMATETC")
	Local $idx = __DataObj_LookupFormatEtc($pFormatEtc, $pArrFormatEtc, $dwCount)
	If $idx == -1 Then Return $DV_E_FORMATETC
	Local $stFORMATETC = DllStructCreate($tagFORMATETC, $pFormatEtc)
	
;~ 	Local $tymed = DllStructGetData(DllStructCreate($tagFORMATETC,$pArrFormatEtc+ $idx*$sizeFORMATETC),"tymed")
	;[[[ Array
		Local $tymed = DllStructGetData(_MemArrayGet($pArrFormatEtc, $idx, $tagFORMATETC),"tymed")
	;]]] Array
	Local $Medium = DllStructCreate($tagSTGMEDIUM,$pMedium)
	DllStructSetData($Medium,"tymed", $tymed)
	DllStructSetData($Medium,"pUnkForRelease", 0)
	Switch $tymed
		Case $TYMED_ENHMF, $TYMED_GDI, $TYMED_HGLOBAL, $TYMED_MFPICT, $TYMED_NULL, $TYMED_ISTREAM, $TYMED_ISTORAGE
;~ 			Local $IntMedium = DllStructCreate($tagSTGMEDIUM,DllStructGetData($st,"pSTGMEDIUM") + $idx*$sizeSTGMEDIUM)
			;[[[ Array
				Local $IntMedium = _MemArrayGet(DllStructGetData($st,"pSTGMEDIUM"),  $idx, $tagSTGMEDIUM)
			;]]] Array
;~ 			DllStructSetData($Medium,"hGlobal", DupGlobalMemMem(DllStructGetData($IntMedium,"hGlobal")))
			If Not DeepCopyStgMedium($pMedium, DllStructGetPtr($IntMedium)) Then Return $DV_E_FORMATETC
		Case Else
			return $DV_E_FORMATETC;
	EndSwitch
	
	Return $S_OK
EndFunc   ;==>__IDataObj_GetData

; Author: Prog@ndy
Func __IDataObj_GetDataHere($pObject, $pFormatEtc, $pMedium)
	Return $DATA_E_FORMATETC;
EndFunc   ;==>__IDataObj_GetDataHere

; Author: Prog@ndy
Func __IDataObj_QueryGetData($pObject, $pFormatEtc)
	Local $st = DllStructCreate($tagIDataObject, $pObject)
	Return _Iif( __DataObj_LookupFormatEtc($pFormatEtc, DllStructGetData($st, "pFORMATETC"), DllStructGetData($st, "Count")) = -1, $DV_E_FORMATETC, $S_OK);
EndFunc   ;==>__IDataObj_QueryGetData

; Author: Prog@ndy
Func __IDataObj_GetCanonicalFormatEtc($pObject, $pFormatEtc, $pFormatEtcOut)
;~     // Apparently we have to set this field to NULL even though we don't do anything else
	Local $FormatEtcOut = DllStructCreate($tagFORMATETC, $pFormatEtcOut)
	DllStructSetData($FormatEtcOut, "ptd", 0);
	Return $E_NOTIMPL;
EndFunc   ;==>__IDataObj_GetCanonicalFormatEtc

; Author: Prog@ndy
Func __IDataObj_SetData($pObject, $pFormatEtc, $pMedium, $fRelease)
;~ 	Return $E_NOTIMPL;
	Local $STGMED = DllStructCreate($tagSTGMEDIUM,$pMedium)
	Switch DllStructGetData($STGMED,"tymed")
		Case $TYMED_ENHMF, $TYMED_GDI, $TYMED_HGLOBAL, $TYMED_MFPICT, $TYMED_NULL, $TYMED_ISTREAM, $TYMED_ISTORAGE
			; they are accepted
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
EndFunc   ;==>__IDataObj_SetData

; Author: Prog@ndy
Func __IDataObj_EnumFormatEtc($pObject, $dwDirection, $ppEnumFormatEtc)
	Switch $dwDirection
		Case $DATADIR_GET
			Local $st = DllStructCreate($tagIDataObject, $pObject)
;~ 			Local $result = DllCall("shell32.dll", $HRESULT, "SHCreateStdEnumFmtEtc", "uint", DllStructGetData($st, "Count"), "ptr", DllStructGetData($st, "pFORMATETC"), "ptr*", 0)
			;[[[ Array
				Local $pFORMATETC = DllStructGetData($st, "pFORMATETC")
				Local $result = DllCall("shell32.dll", $HRESULT, "SHCreateStdEnumFmtEtc", "uint", DllStructGetData($st, "Count"), "ptr", __MemArrayLockedPtr($pFORMATETC), "ptr*", 0)
				__MemArrayUnLock($pFORMATETC)
			;]]] Array
			Local $pEnumFormatEtc = DllStructCreate("ptr",$ppEnumFormatEtc)
			DllStructSetData($pEnumFormatEtc,1,$result[3])
			Return _Iif($result[3]=0, $E_OUTOFMEMORY, $S_OK)
		Case Else
;~ 			Return $E_NOTIMPL
			Return $OLE_S_USEREG ; No support for all formats, but this is easier :P
	EndSwitch
EndFunc   ;==>__IDataObj_EnumFormatEtc

; Author: Prog@ndy
Func __IDataObj_DAdvise($pObject, $pFormatEtc, $advf, $pAdvSink, $pdwConnection)
	Return $OLE_E_ADVISENOTSUPPORTED;
EndFunc   ;==>__IDataObj_DAdvise

; Author: Prog@ndy
Func __IDataObj_DUnadvise($pObject, $dwConnection)
	Return $OLE_E_ADVISENOTSUPPORTED;
EndFunc   ;==>__IDataObj_DUnadvise

; Author: Prog@ndy
Func __IDataObj_EnumDAdvise($pObject, $ppEnumAdvise)
	Return $OLE_E_ADVISENOTSUPPORTED;
EndFunc   ;==>__IDataObj_EnumDAdvise

; Author: Prog@ndy
Func _DragDrop_SIZEOF($tagStruct)
	Return DllStructGetSize(DllStructCreate($tagStruct, 1))
EndFunc   ;==>_DragDrop_SIZEOF

; Author: Prog@ndy
Func _CreateIDataObject(ByRef $fmtetc, ByRef $stgmed)
	If Not IsArray($fmtetc) Or UBound($fmtetc) <> UBound($stgmed) Then Return SetError(1, 0, 0)
	Local $iCount = UBound($fmtetc)

	Local $sizeIDataObj = _DragDrop_SIZEOF($tagIDataObject)

;~ 	Local $pObj = _MemGlobalAlloc($sizeIDataObj + ($iCount * $sizeFORMATETC) + ($iCount * $sizeSTGMEDIUM), $GPTR)
	;[[[ Array
		Local $pObj = _MemGlobalAlloc($sizeIDataObj, $GPTR)
		Local $pFORMATETC = _MemArrayCreate($tagFORMATETC)
		Local $pSTGMEDIUM = _MemArrayCreate($tagSTGMEDIUM)
	;]]] Array
	Local $stObj = DllStructCreate($tagIDataObject, $pObj)
	DllStructSetData($stObj, "vTable", DllStructGetPtr($__IDataObj_vTable))
	DllStructSetData($stObj, "dwRefCount", 1)
	

;~ 	Local $pPtr = $pObj + $sizeIDataObj

	DllStructSetData($stObj, "Count", $iCount)
;~ 	DllStructSetData($stObj, "pFORMATETC", $pPtr)
	DllStructSetData($stObj, "pFORMATETC", $pFORMATETC)
	For $i = 0 To $iCount - 1
;~ 		_MemMoveMemory(DllStructGetPtr($fmtetc[$i]), $pPtr, $sizeFORMATETC)
;~ 		_RtlCopyMemory(DllStructGetPtr($fmtetc[$i]), $pPtr, $sizeFORMATETC)
		_MemArrayAdd($pFORMATETC, $fmtetc[$i])
;~ 		$pPtr += $sizeFORMATETC
	Next
;~ 	DllStructSetData($stObj, "pSTGMEDIUM", $pPtr)
	DllStructSetData($stObj, "pSTGMEDIUM", $pSTGMEDIUM)
	For $i = 0 To $iCount - 1
;~ 		_MemMoveMemory(DllStructGetPtr($stgmed[$i]), $pPtr, $sizeSTGMEDIUM)
;~ 		_RtlCopyMemory(DllStructGetPtr($stgmed[$i]), $pPtr, $sizeSTGMEDIUM)
		_MemArrayAdd($pSTGMEDIUM, $stgmed[$i])
;~ 		$pPtr += $sizeSTGMEDIUM
	Next
	Local $result[3] = [$pObj, $stObj, $__IDataObj_vTable]
	Return $result
EndFunc   ;==>_CreateIDataObject

; Author: Prog@ndy
Func _ReleaseIDataObject(ByRef $IDataObj)
	Local $res = _ObjFuncCall("ulong",$IDataObj,"Release")
	If @error Then Return SetError(1,0,-1)
	If $res[0] = 0 Then 
		$IDataObj = 0
	EndIf
	Return $res[0]
EndFunc

; Author: Prog@ndy
Func _RtlCopyMemory($pSource, $pDest, $iLength)
	DllCall("msvcrt.dll", "none:cdecl", "memcpy", "ptr", $pDest, "ptr", $pSource, "dword", $iLength)
EndFunc   ;==>_RtlCopyMemory

; Author: Prog@ndy
; translated from C++
Func DupGlobalMemMem($hMem)
	Local $len = _MemGlobalSize($hMem);
	Local $source = _MemGlobalLock($hMem);
	If $source = 0 Then $source = $hMem

;~ 	Local $dest = _MemGlobalAlloc($len, BitOR($GMEM_MOVEABLE,$GMEM_SHARE));
	Local $dest = _MemGlobalAlloc($len, BitOR($GMEM_FIXED,$GMEM_SHARE));
	
;~ 	_MemMoveMemory($source, _MemGlobalLock($dest), $len);
	_RtlCopyMemory($source, _MemGlobalLock($dest), $len);

	_MemGlobalUnlock($dest);
	_MemGlobalUnlock($hMem);
	Return $dest;
EndFunc   ;==>DupGlobalMemMem

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


; Author: Prog@ndy
Func _CloneBitmap($hBmp)
	Local $result = DllCall("user32.dll", "ptr", "CopyImage", "ptr", $hBmp, "uint", 0, "int",0, "int",0, "uint", 0)
	Return $result[0]
EndFunc
; Author: Prog@ndy
Func _CloneEnhMetaFile($hemfSrc)
	Local $result = DllCall("Gdi32.dll", "ptr", "CopyEnhMetaFileW", "ptr", $hemfSrc, "ptr", 0)
	Return $result[0]
EndFunc
; Author: Prog@ndy
Func _CloneMetaFile($hemfSrc)
	Local $result = DllCall("Gdi32.dll", "ptr", "CopyMetaFileW", "ptr", $hemfSrc, "ptr", 0)
	Return $result[0]
EndFunc
; Author: Prog@ndy
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

; Author: Prog@ndy
; translated from C++
Func DeepCopyFormatEtc($pDest, $pSource)
    ;// copy the source FORMATETC into dest

	__MemCopyMemory($pSource,$pDest,$sizeFORMATETC)
	
	Local $Souce_ptd = DllStructGetData(DllStructCreate($tagFORMATETC,$pSource),"ptd")
    if($Souce_ptd) Then
        ;// allocate memory for the DVTARGETDEVICE if necessary
        Local $dest_ptd = _CoTaskMemAlloc(_DragDrop_SIZEOF($tagDVTARGETDEVICE));

        ;// copy the contents of the source DVTARGETDEVICE into dest->ptd
		__MemCopyMemory($Souce_ptd, $dest_ptd, _DragDrop_SIZEOF($tagDVTARGETDEVICE))
        ;*(dest->ptd) = *(source->ptd);
		DllStructSetData(DllStructCreate($tagFORMATETC,$pDest),"ptd",$dest_ptd)
    EndIf
EndFunc


; Author: Prog@ndy
; translated from C++
Func __DataObj_LookupFormatEtc($pFormatEtc, $pAvailableFormats, $dwCount)

	Local $FormatEtc = DllStructCreate($tagFORMATETC, $pFormatEtc), $next

	;// check each of our formats in turn to see if one matches
;~ 	Local $pPtr = $pAvailableFormats
	For $i = 0 To $dwCount - 1
;~ 		$next = DllStructCreate($tagFORMATETC, $pPtr)
		$next = _MemArrayGet($pAvailableFormats, $i, $tagFORMATETC)
		;  "dword cfFormat; ptr ptd; DWORD  dwAspect; LONG lindex; DWORD tymed;"
		If ( ( DllStructGetData($next, 1) =  DllStructGetData($FormatEtc, 1) ) And _
			 ( DllStructGetData($next, 3) = DllStructGetData($FormatEtc, 3) ) And _
			 ( DllStructGetData($next, 4) = DllStructGetData($FormatEtc, 4) ) And _
			 ( BitAND(DllStructGetData($next, 5), DllStructGetData($FormatEtc, 5)) <> 0 ) ) Then

			;// return index of stored format
			Return $i;
;~ 			$pPtr += $sizeFORMATETC
		EndIf
	Next

	;// error, format not found
	Return -1;
EndFunc   ;==>__DataObj_LookupFormatEtc

; Author: Prog@ndy
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

#EndRegion IDataObject
; -- #EndRegion IDataObject -------------------------------------------------------------

; Author: Prog@ndy
Func _DoDragDrop(ByRef $objIDataSource, ByRef $objIDropSource, $dwDropEffects, ByRef $dwPerformedEffect)
	Local $result = DllCall($OLE32,$HRESULT,"DoDragDrop", "ptr", _ObjGetObjPtr($objIDataSource),"ptr", _ObjGetObjPtr($objIDropSource), "dword", BitOR($DROPEFFECT_MOVE,$DROPEFFECT_COPY,$DROPEFFECT_LINK), "dword*", 0)
	$dwPerformedEffect = $result[4]
	Return $result[0]
EndFunc

;~ ==========================================================================================

Global Const $DROPFILES = "DWORD pFiles; int pt[2]; int fNC; int fWide;"
Global Const $CF_HDROP = 15 ; Handle to type HDROP that identifies a list of files
;===============================================================================
;
; Function Name:   _CreateHDROP_FORMATETC()
; Description::    Creates a FORMATETC-structure with the needed values to do a HDROP (Drag Files like explorer)
; Parameter(s):    none
; Requirement(s):  COM/OLE UDF
; Return Value(s): FORMATETC DLL-structure
; Author(s):       prog@ndy
;
;===============================================================================
;
Func _CreateHDROP_FORMATETC()
	Local $FMTETC = DllStructCreate($tagFORMATETC)
		DllStructSetData($FMTETC,1,$CF_HDROP)
		DllStructSetData($FMTETC,2,0)
		DllStructSetData($FMTETC,3,$DVASPECT_CONTENT)
		DllStructSetData($FMTETC,4,-1)
		DllStructSetData($FMTETC,5,$TYMED_HGLOBAL)
	Return $FMTETC
EndFunc

;===============================================================================
;
; Function Name:   _CreateDROPFILES
; Description::    Creates a DROPFILES-structure
; Parameter(s):    $Files - Pipe-separated list of files to copy: example: C:\File1.bin|D:\AnotherFile.dat
; Requirement(s):  COM/OLE UDF
; Return Value(s): HGLOBAL-Pointer to a DROPFILES structure
; Author(s):       prog@ndy
;
;===============================================================================
;
Func _CreateDROPFILES($Files)
	$Files = String($Files)

    $hMem = _MemGlobalAlloc(_DragDrop_SIZEOF($DROPFILES) + ((StringLen($Files)+2)*2),$GPTR)
	$Files = StringSplit($Files,"|")
	$stDROPFILES = DllStructCreate($DROPFILES,$hMem)
	$hPtr = $hMem + DllStructGetSize($stDROPFILES)
	DllStructSetData($stDROPFILES, "fWide", 1)
	DllStructSetData($stDROPFILES, 1, DllStructGetSize($stDROPFILES))
	For $i = 1 To $Files[0]
		$next = DllStructCreate("wchar[" & StringLen($Files[$i])+1 & "]", $hPtr)
		DllStructSetData($next,1,$Files[$i] & ChrW(0))
		$hPtr += (StringLen($Files[$i])+1)*2
	Next
	$next = DllStructCreate("wchar[1]", $hPtr)
	DllStructSetData($next,1,ChrW(0))
	Return $hMem
EndFunc

;===============================================================================
;
; Function Name:   _CreateDROPFILES_STGMEDIUM
; Description::    Creates a STGMEDIUM with a DROPFILES-structure
; Parameter(s):    $Files - Pipe-separated list of files to copy: example: C:\File1.bin|D:\AnotherFile.dat
; Requirement(s):  COM/OLE UDF
; Return Value(s): STGMEDIUM-DLLStruct
; Author(s):       prog@ndy
;
;===============================================================================
;
Func _CreateDROPFILES_STGMEDIUM($Files)
	Local $STGMD = DllStructCreate($tagSTGMEDIUM)
	DllStructSetData($STGMD,1,$TYMED_HGLOBAL)
	Local $DF = _CreateDROPFILES($Files)
	If Not $DF Then Return SetError(1,0,0)
	DllStructSetData($STGMD,2,$DF)
	Return $STGMD
EndFunc


; do on Startup
	_OLEInitialize()
	; init DropSource Handler
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
;~ 	Local $deskDC = _WinAPI_GetDC(_WinAPI_GetDesktopWindow())
;~ 	Local $hBMP = _WinAPI_CreateCompatibleBitmap($deskDC,96,96)
;~ 	_WinAPI_ReleaseDC(_WinAPI_GetDesktopWindow(),$deskDC)
	Local $hBMP = _WinAPI_LoadImage(0,"C:\Windows\Feder.bmp",0,0,0,$LR_LOADFROMFILE)
	DllStructSetData($SHDRAGIMAGE,"hbmpDragImage",$hBMP)
	DllStructSetData($SHDRAGIMAGE,"sizeDragImage",96,1)
	DllStructSetData($SHDRAGIMAGE,"sizeDragImage",96,2)
	DllStructSetData($SHDRAGIMAGE,"ptOffset",45,1)
	DllStructSetData($SHDRAGIMAGE,"ptOffset",69,2)
	DllStructSetData($SHDRAGIMAGE,"crColorKey",0x00FF00FF)
	_ObjFuncCall($HRESULT, $IDragSourceHelper, "InitializeFromBitmap", "ptr", DllStructGetPtr($SHDRAGIMAGE), "ptr", _ObjGetObjPtr($IDataObject))
EndFunc

; Author: Prog@ndy
Func _MemGlobalGetValue($hMem, $DataType, $Offset=0)
	If _MemGlobalSize($hMem) < __MemArray_SIZEOF($DataType) Then Return SetError(1,0,0)
	Local $hPtr = _MemGlobalLock($hMem)
	If Not $hPtr Then Return SetError(2,0,0)
	Local $Data = DllStructGetData(DllStructCreate($DataType,$hPtr+$Offset),1)
	If @error Then Return SetError(1,_MemGlobalUnlock($hMem))
	_MemGlobalUnlock($hMem)
	Return $Data
EndFunc

; Prog@ndy
Func _GetUnoptimizedEffect(ByRef $objIDataSource, $Effect)
	Local $FormatEtc = _CreateHDROP_FORMATETC()
	DllStructSetData($FormatEtc,1,$CF_PERFORMEDDROPEFFECT)
	Local $result = _ObjFuncCall($HRESULT, $objIDataSource, "QueryGetData",  "ptr", DllStructGetPtr($FormatEtc))
	If $S_OK = $result[0] Then
		Local $StgMedium = DllStructCreate($tagSTGMEDIUM)
		$result = _ObjFuncCall($HRESULT, $objIDataSource, "GetData",  "ptr", DllStructGetPtr($FormatEtc), "ptr", DllStructGetPtr($StgMedium))
		If $S_OK = $result[0] Then
			$Effect = _MemGlobalGetValue(DllStructGetData($StgMedium,"hGlobal"),"dword")
		EndIf
		_ReleaseStgMedium($StgMedium)
	EndIf
	Return $Effect
EndFunc


Func _SHDoDragDrop($hWnd, ByRef $objIDataSource, ByRef $objIDropSource, $dwDropEffects, ByRef $dwPerformedEffect)
	Local $result = DllCall("shell32.dll",$HRESULT,"SHDoDragDrop", "hwnd", $hWnd, "ptr", _ObjGetObjPtr($objIDataSource),"ptr", _ObjGetObjPtr($objIDropSource), "dword", BitOR($DROPEFFECT_MOVE,$DROPEFFECT_COPY,$DROPEFFECT_LINK), "dword*", 0)
	$dwPerformedEffect = $result[5]
	Return $result[0]
EndFunc
