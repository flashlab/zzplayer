#include<Memory.au3>
#include<Array.au3>

Global Const $__MemArray_HEAD = "dword iElSize;"
Global Const $__MemArray_HEADSIZE = __MemArray_SIZEOF($__MemArray_HEAD)
; Author: Prog@ndy
Func __MemArray_SIZEOF($tagStruct)
	Return DllStructGetSize(DllStructCreate($tagStruct, 1))
EndFunc   ;==>__MemArray_SIZEOF

 
Func __MemArrayLockedPtr($hMem)
	If Not IsPtr($hMem) Or $hMem = 0 Or Not __MemIsGlobal($hMem) Then Return SetError(1,0,0)
	Return _MemGlobalLock($hMem)+$__MemArray_HEADSIZE
EndFunc

Func __MemArrayUnLock($hMem)
	If Not IsPtr($hMem) Or $hMem = 0 Or Not __MemIsGlobal($hMem) Then Return SetError(1,0,0)
	_MemGlobalUnlock($hMem)
EndFunc


; Author: Prog@ndy
Func _MemArrayCreate($tagStruct)
	Local $iSize = __MemArray_SIZEOF($tagStruct)
	If $iSize = 0 Then Return SetError(1, 0, 0)
	Local $hMem = _MemGlobalAlloc($__MemArray_HEADSIZE, $GMEM_MOVEABLE)
	If $hMem = 0 Then Return SetError(2, 0, 0)
	DllStructSetData(DllStructCreate($__MemArray_HEAD, _MemGlobalLock($hMem)), 1, $iSize)
	_MemGlobalUnlock($hMem)
	Return $hMem
EndFunc   ;==>_MemArrayCreate
; Author: Prog@ndy
Func __MemArrayElementSize($hMem)
	If Not IsPtr($hMem) Or $hMem = 0 Or Not __MemIsGlobal($hMem) Then Return SetError(1, 0, 0)
	Local $iSize = DllStructGetData(DllStructCreate($__MemArray_HEAD, _MemGlobalLock($hMem)), 1)
	_MemGlobalUnlock($hMem)
	Return $iSize
EndFunc   ;==>__MemArrayElementSize
; Author: Prog@ndy
Func _MemArrayFree($hMem)
	Return _MemGlobalFree($hMem)
EndFunc   ;==>_MemArrayFree
; Author: Prog@ndy
Func _MemArrayAdd($hMem, ByRef $stEntry)
	If Not IsPtr($hMem) Or $hMem = 0 Or Not __MemIsGlobal($hMem) Then Return SetError(1, 0, -1)
	If Not (IsDllStruct($stEntry) Or IsPtr($stEntry)) Then Return SetError(2, 0, -1)
	Local $size = _MemGlobalSize($hMem)
	Local $iElSize = __MemArrayElementSize($hMem)
	Local $result = __MemGlobalReAlloc($hMem, $size + $iElSize, $GHND)
	If Not $result Then Return SetError(2, 0, 0)
	Local $indX = (($size - $__MemArray_HEADSIZE) / $iElSize)
	If IsPtr($stEntry) Then
		__MemCopyMemory($stEntry, _MemGlobalLock($hMem) + $size, $iElSize)
	Else
		__MemCopyMemory(DllStructGetPtr($stEntry), _MemGlobalLock($hMem) + $size, $iElSize)
	EndIf
	_MemGlobalUnlock($hMem)
	Return $indX
EndFunc   ;==>_MemArrayAdd
; Author: Prog@ndy
Func _MemArrayDelete($hMem, $indX)
	If Not IsPtr($hMem) Or $hMem = 0 Or Not __MemIsGlobal($hMem) Then Return SetError(1, 0, 0)
	Local $size = _MemGlobalSize($hMem)
	Local $iElSize = __MemArrayElementSize($hMem)

	Local $maxIndX = ($size - $__MemArray_HEADSIZE) / $iElSize
	If $indX < 0 Or $indX > $maxIndX Then Return SetError(2, 0, 0)
	If $size > ($__MemArray_HEADSIZE + $iElSize) Then
		Local $hPtr = _MemGlobalLock($hMem)
		Local $deletedElementOffset = ($indX * $iElSize) + $__MemArray_HEADSIZE
		_MemMoveMemory($hPtr + $deletedElementOffset + $iElSize, $hPtr + $deletedElementOffset, $size - ($deletedElementOffset + $iElSize))
		_MemGlobalUnlock($hMem)
	EndIf
	__MemGlobalReAlloc($hMem, $size - $iElSize, $GMEM_MOVEABLE)
	Return 1
EndFunc   ;==>_MemArrayDelete
; Author: Prog@ndy
Func _MemArrayGet($hMem, $indX, $tagStruct)
	If Not IsPtr($hMem) Or $hMem = 0 Or Not __MemIsGlobal($hMem) Then Return SetError(1, 0, 0)
	Local $size = _MemGlobalSize($hMem)
	Local $iElSize = __MemArrayElementSize($hMem)

	Local $maxIndX = ($size - $__MemArray_HEADSIZE) / $iElSize
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
EndFunc   ;==>_MemArrayGet

; Author: Prog@ndy
Func _MemArrayGetDelete($hMem, $indX, $tagStruct)
	If Not IsPtr($hMem) Or $hMem = 0 Or Not __MemIsGlobal($hMem) Then Return SetError(1, 0, 0)
	Local $size = _MemGlobalSize($hMem)
	Local $iElSize = __MemArrayElementSize($hMem)

	Local $maxIndX = ($size - $__MemArray_HEADSIZE) / $iElSize
	If $indX < 0 Or $indX > $maxIndX Then Return SetError(2, 0, 0)
	Local $hPtr = _MemGlobalLock($hMem)
	If IsPtr($tagStruct) Then 
		__MemCopyMemory($hPtr + $__MemArray_HEADSIZE + $indX * $iElSize, $tagStruct, $iElSize)
	Else
		Local $struct = DllStructCreate($tagStruct)
		If @error Then Return SetError(2,_MemGlobalUnlock($hMem),0)
		__MemCopyMemory($hPtr + $__MemArray_HEADSIZE + $indX * $iElSize, DllStructGetPtr($struct), $iElSize)
	EndIf
	If $size > ($__MemArray_HEADSIZE + $iElSize) Then
		Local $deletedElementOffset = ($indX * $iElSize) + $__MemArray_HEADSIZE
		_MemMoveMemory($hPtr + $deletedElementOffset + $iElSize, $hPtr + $deletedElementOffset, $size - ($deletedElementOffset + $iElSize))
	EndIf
	_MemGlobalUnlock($hMem)
	__MemGlobalReAlloc($hMem, $size - $iElSize, $GMEM_MOVEABLE)
	Return $struct
EndFunc   ;==>_MemArrayGet

#cs
	Func _MemArrayGetToArray($hMem)
	If Not IsPtr($hMem) Or $hMem = 0 Or Not __MemIsGlobal($hMem) Then Return SetError(1,0,0)
	Local $size = _MemGlobalSize($hMem)
	Local $maxIndX = $size/$__MemArray_PTRSIZE
	If $maxIndX < 1 Then Return SetError(2,0,0)
	Local $struct = DllStructCreate("ptr[" & $maxIndX & "]", _MemGlobalLock($hMem) )
	Local $array[$maxIndX]
	For $i = 1 To $maxIndX
	$array[$i-1] = DllStructGetData($struct,1,$i)
	Next
	_MemGlobalUnlock($hMem)
	Return $array
	EndFunc
#ce
; Author: Prog@ndy
Func _MemArraySet($hMem, $indX, ByRef $stEntry)
	If Not IsPtr($hMem) Or $hMem = 0 Or Not __MemIsGlobal($hMem) Then Return SetError(1, 0, 0)
	Local $size = _MemGlobalSize($hMem)
	Local $iElSize = __MemArrayElementSize($hMem)

	Local $maxIndX = ($size - $__MemArray_HEADSIZE) / $iElSize
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
EndFunc   ;==>_MemArraySet
; Author: Prog@ndy
Func _MemArrayUBound($hMem)
	If Not IsPtr($hMem) Or $hMem = 0 Or Not __MemIsGlobal($hMem) Then Return SetError(1, 0, 0)
	Local $iElSize = __MemArrayElementSize($hMem)
	Return ((_MemGlobalSize($hMem) - $__MemArray_HEADSIZE) / $iElSize)
EndFunc   ;==>_MemArrayUBound

; Author: Prog@ndy
Func __MemIsGlobal($hMem)
	Local $result = __MemGlobalFlags($hMem)
	If @error Or $result == $GMEM_INVALID_HANDLE Then Return 0
	Return 1
EndFunc   ;==>__MemIsGlobal
; Author: Prog@ndy
Func __MemGlobalReAlloc($hMem, $iBytes, $iFlags)
	Local $aResult = DllCall("Kernel32.dll", "ptr", "GlobalReAlloc", "ptr", $hMem, "ulong", $iBytes, "uint", $iFlags)
	Return $aResult[0]
EndFunc   ;==>__MemGlobalReAlloc
; Author: Prog@ndy
Func __MemGlobalFlags($hMem)
	Local $aResult = DllCall("Kernel32.dll", "uint", "GlobalFlags", "ptr", $hMem)
	Return $aResult[0]
EndFunc   ;==>__MemGlobalFlags
; Author: Prog@ndy
Func __MemGlobalDiscard($hMem)
	Return __MemGlobalReAlloc($hMem, 0, $GMEM_MOVEABLE)
EndFunc   ;==>__MemGlobalDiscard
; Author: Prog@ndy
Func __MemCopyMemory($pSource, $pDest, $iLength)
	DllCall("msvcrt.dll", "none:cdecl", "memcpy", "ptr", $pDest, "ptr", $pSource, "dword", $iLength)
EndFunc   ;==>__MemCopyMemory
; Author: Prog@ndy
Func __MemFillMemory($pDest, $ubFill, $iLength)
	DllCall("kernel32.dll", "none", "RtlFillMemory", "ptr", $pDest, "dword", $iLength, "ubyte", $ubFill)
EndFunc   ;==>__MemFillMemory
; Author: Prog@ndy
Func __MemZeroMemory($pDest, $iLength)
	DllCall("kernel32.dll", "none", "RtlZeroMemory", "ptr", $pDest, "dword", $iLength)
EndFunc   ;==>__MemZeroMemory