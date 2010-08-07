;
; AutoHotkey Version: 1.x
; Language:       English
; Platform:       Win9x/NT
; Author:         A.N.Other <myemail@nowhere.com>
;
; Script Function:
;	Template script (you can customize this template by editing "ShellNew\Template.ahk" in your Windows folder)
;

#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

if A_IsCompiled
{
	TargetScriptTitle = %A_ScriptDir%\DiffHelper.exe ahk_class AutoHotkey
	TargetCommand = "%A_ScriptFullPath%"
	TargetHelper = %A_ScriptDir%\DiffHelper.exe
}else{
	TargetScriptTitle = %A_ScriptDir%\DiffHelper.ahk ahk_class AutoHotkey
	TargetCommand = "%A_AhkPath%" "%A_ScriptFullPath%"
	TargetHelper = "%A_AhkPath%" "%A_ScriptDir%\DiffHelper.ahk"
}

if 0=1
{
    FileName=%1%
    Prev_DetectHiddenWindows := A_DetectHiddenWindows
    Prev_TitleMatchMode := A_TitleMatchMode
    DetectHiddenWindows On
    SetTitleMatchMode 2
	hwnd := WinExist(TargetScriptTitle)
    DetectHiddenWindows %Prev_DetectHiddenWindows%  ; Restore original setting for the caller.
    SetTitleMatchMode %Prev_TitleMatchMode%         ; Same.
	if !hwnd
	{
		run,%TargetHelper% "%FileName%"
	}else{
		result := Send_WM_COPYDATA(FileName, TargetScriptTitle)
		if result = FAIL
			Popup("Differ","SendMessage failed: " TargetScriptTitle)
		else if result = 0
			Popup("Differ","Message sent, but returned 0.")
		Sleep,2000
	}
	ExitApp
}
else
{
    RegRead,ContextCmd,HKEY_CLASSES_ROOT,*\shell\Differ\command
	if ContextCmd
	{
		MsgBox,4,Uninstall, Uninstall context menu entry?
		IfMsgBox Yes
		{
			RegDelete,HKEY_CLASSES_ROOT,*\shell\Differ
		}
		ExitApp
	}else{
		; Perform install
		Gui,Add,Text,,Enter command to execute diff viewer
		Gui,Add,Edit,vDiffViewer,gvim.bat -d
		Gui,Add,Button,gInstall,Install
		Gui,Add,Button,gCancel,Cancel
		Gui,Show,,Install
	}
}
return

Send_WM_COPYDATA(ByRef StringToSend, ByRef TargetScriptTitle)  ; ByRef saves a little memory in this case.
; This function sends the specified string to the specified window and returns the reply.
; The reply is 1 if the target window processed the message, or 0 if it ignored it.
{
    VarSetCapacity(CopyDataStruct, 12, 0)  ; Set up the structure's memory area.
    ; First set the structure's cbData member to the size of the string, including its zero terminator:
    NumPut(StrLen(StringToSend) + 1, CopyDataStruct, 4)  ; OS requires that this be done.
    NumPut(&StringToSend, CopyDataStruct, 8)  ; Set lpData to point to the string itself.
    Prev_DetectHiddenWindows := A_DetectHiddenWindows
    Prev_TitleMatchMode := A_TitleMatchMode
    DetectHiddenWindows On
    SetTitleMatchMode 2
    SendMessage, 0x4a, 0, &CopyDataStruct,, %TargetScriptTitle%  ; 0x4a is WM_COPYDATA. Must use Send not Post.
    DetectHiddenWindows %Prev_DetectHiddenWindows%  ; Restore original setting for the caller.
    SetTitleMatchMode %Prev_TitleMatchMode%         ; Same.
    return ErrorLevel  ; Return SendMessage's reply back to our caller.
}

Install:
	Gui,Submit
	IniWrite,%DiffViewer%,Settings.ini,Default,DiffProgram
    RegWrite,REG_SZ,HKEY_CLASSES_ROOT,*\shell\Differ\command,,%TargetCommand% "`%1"
    if ErrorLevel=0
        MsgBox,Successfully created context menu entry
    else
        MsgBox,Unable to create context menu entry
	ExitApp

Cancel:
	ExitApp


#include ..\Popup.ahk
