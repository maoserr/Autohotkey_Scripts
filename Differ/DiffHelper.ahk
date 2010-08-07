;
; AutoHotkey Version: 1.x
; Language:       English
; Platform:       Win9x/NT
; Author:         Mao Yu
;
; Script Function:
;   Hotkeys
;
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.\
#SingleInstance force
#Persistent
#NoTrayIcon
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.

IniRead,DiffViewer,Settings.ini,Default,DiffProgram,NONE
if DiffViewer=NONE
{
	MsgBox Please run Differ to install first
	ExitApp
}

DiffView(wParam, lParam)
{
    global oldFilename
    StringAddress := NumGet(lParam + 8)  ; lParam+8 is the address of CopyDataStruct's lpData member.
    StringLength := DllCall("lstrlen", UInt, StringAddress)
    if StringLength <= 0
        Popup("Diff","Error getting file name")
    else
    {
        VarSetCapacity(FileName, StringLength)
        DllCall("lstrcpy", "str", FileName, "uint", StringAddress)  ; Copy the string out of the structure.
        if oldFilename
        {
            Popup("Diff Mine:",FileName,true,"",197,56)
            Run,gvim.bat -d "%oldFilename%" "%FileName%"
            ExitApp
        }else{
			Msgbox Error: could not remember old file name
		}
    }
    return 1
}

if 0!=1
{
	Msgbox, You cannot run this directly. Please use context menu entry
	ExitApp
}

oldFilename = %1%
Popup("Diff Base:",oldFilename,false,"",197,56)

OnMessage(0x4a,"DiffView")
return

#include ..\Popup.ahk

