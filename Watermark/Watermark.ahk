;
; AutoHotkey Version: 1.x
; Language:       English
; Platform:       Win9x/NT
; Author:         A.N.Other <myemail@nowhere.com>
;
; Script Function:
;	Template script (you can customize this template by editing "ShellNew\Template.ahk" in your Windows folder)
;
#NoTrayIcon
#SingleInstance Force
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

; Settings
IniRead,ExistFrames,Settings.ini,Output,ExistFrames,50 ; Number of frames to keep watermark
IniRead,FadeFrames,Settings.ini,Output,FadeFrames,20   ; Number of frames to fade at end
IniRead,VDub,Settings.ini,VirtualDub,Program
	,C:\Programs\VirtualDub\VirtualDub.exe
IniRead,Watermark_D,Settings.ini,Watermark,Image,Watermark.bmp
IniRead,WmMask_D,Settings.ini,Watermark,Mask,Watermark_Mask.bmp
IniRead,DirectShow,Settings.ini,Codec,DirectShow,0

Gui,Add,Text,xm,Watermark:
Gui,Add,Edit,xp+80 w400 vWatermark,%Watermark_D%
Gui,Add,Button,xp+405 gBrowseWm,...
Gui,Add,Text,xm,Mask:
Gui,Add,Edit,xp+80 vWmMask w400,%WmMask_D%
Gui,Add,Button,xp+405 gBrowseM,...
Gui,Add,Text,xm,VirtualDUb:
Gui,Add,Edit,xp+80 vVDUBEXE w400,%VDUB%
Gui,Add,Button,xp+405 gBrowseV,...
Gui,Add,Text,xm,Exist (Frames):
Gui,Add,Edit,xp+80 vEdtExistFrame w50,%ExistFrames%
Gui,Add,Text,xp+60,Fade (Frames):
Gui,Add,Edit,xp+80 vEdtFadeFrames w50,%FadeFrames%
Gui,Add,Checkbox,vChkDShow xp+60 Checked%DirectShow%,Use DirectShow Codecs?
Gui,Add,Text,xm,Movies:
Gui,Add,Button,xp+485 gBrowseMov vBrowseMov,...
Gui,Add,ListView,xm w500 Grid -Multi, Name|Size (MB)
Gui,Add,Button,xm gAddWM vAddWM,Add Watermarks
Gui,Add,Button,xp+100 gTranscode vTranscode,Enc. (Cinepak)
Gui,Add,Button,xp+100 gClear vClear,Clear List
Gui,Show,,Watermarker
return


BrowseWM:
     FileSelectFile,Wmfile,,,Locate Watermark,Images (*.bmp;*.png;*.jpg;*.jpeg)
     if ErrorLevel=1
          return
     GuiControl,,Watermark,%Wmfile%
return

BrowseM:
     FileSelectFile,Mfile,,,Locate Mask,Images (*.bmp;*.png;*.jpg;*.jpeg)
     if ErrorLevel=1
          return
     GuiControl,,WmMask,%Mfile%
return

BrowseV:
     FileSelectFile,VdubExe,,,Locate VirtualDub,Executeables (VirtualDub.exe)
     if ErrorLevel=1
          return
     GuiControl,,VDUBEXE,%VdubExe%
return

BrowseMov:
    FileSelectFile,MovFiles,M,,Locate Movies,Movies (*.avi;*.mpg)
    if ErrorLevel=1
        return
    StringSplit,Movs,MovFiles,`n
    Path := Movs1
    FileCnt := Movs0 - 1
    SetFormat,Float,0.2
    Loop, %FileCnt%
    {
        Ind := A_Index+1
        CurrFile := Movs%Ind%
        CurrFile := Path . "\" . CurrFile
        if FileExist(CurrFile)
        {
            FileGetSize,CurrSize,%CurrFile%, K
            CurrSize := CurrSize / 1024
            LV_Add("",CurrFile,CurrSize)
        }
    }
    LV_ModifyCol(1,"AutoHdr")
    LV_ModifyCol(2,"AutoHdr")
return

Clear:
    LV_Delete()
return

Transcode:
    Gui,Submit,NoHide
    TempVScript := A_Temp . "\VDubScript.vcf"
    Loop % LV_GetCount()
    {
        LV_GetText(CurrMovFile,A_Index,1)
        LV_Modify(A_Index,"Col2","Processing...")
        if FileExist(TempVScript)
            FileDelete,%TempVScript%
        SplitPath,CurrMovFile,CurrFile,CurrDir
        OutDir := CurrDir . "\Transcoded"
        if !FileExist(OutDir)
            FileCreateDir, %OutDir%
        VDubCine(TempVScript,OutDir "\" CurrFile)
        Run, %VDUBEXE% "%CurrMovFile%" /s "%TempVScript%" /x,,Min,CurrPID
        CurrInd := A_Index
        GoSub,VDubProg
    }
return

AddWM:
    Gui,Submit,NoHide
    TempFile := "LastJob.avs"
    TempVScript := "LastJob.vcf"
	; Check if we're using direct show
	if ChkDShow{
		SourceCmd=DirectShowSource
	}else{
		SourceCmd=AVISource
	}
    Loop % LV_GetCount()
    {
        LV_GetText(CurrMovFile,A_Index,1)
        LV_Modify(A_Index,"Col2","Processing...")
        if FileExist(TempFile)
            FileDelete,%TempFile%
        if FileExist(TempVScript)
            FileDelete,%TempVScript%
        SplitPath,CurrMovFile,CurrFile,CurrDir
        OutDir := CurrDir . "\Watermarked"
        if !FileExist(OutDir)
            FileCreateDir, %OutDir%
        FileAppend,
(
basevid=%SourceCmd%("%CurrMovFile%")
logo = ImageReader("%Watermark%", 0, 0, 1, true)
logo = logo.AssumeFPS(basevid.FrameRate())
logoMask = ImageReader("%WmMask%", 0, 0, 1, true)
logoMask = logoMask.AssumeFPS(basevid.FrameRate()).Loop(%EdtExistFrame%).FadeOut(%EdtFadeFrames%)
Overlay(basevid, logo, x=0, y=(basevid.Height() - logo.Height()),
\       mask=logoMask,opacity=0.7)


),%TempFile%
        VDubCine(TempVScript,OutDir "\" CurrFile)
		; Disable gui before we run
		GuiControl,Disable,BrowseMov
		GuiControl,Disable,AddWM
		GuiControl,Disable,Transcode
		GuiControl,Disable,Clear
        Run, %VDUBEXE% "%TempFile%" /s "%TempVScript%" /x,,Min,CurrPID
        CurrInd := A_Index
        GoSub,VDubProg
    }
return

VDubProg:
        LV_Modify(CurrInd,"Select")
        SetTimer, VDubCheckPerc, 1000
        Process,Wait, %CurrPID%,10
        Process,WaitClose, %CurrPID%
        SetTimer, VDubCheckPerc, Off
        LV_Modify(CurrInd,"Col2","Done")
		GuiControl,Enable,BrowseMov
		GuiControl,Enable,AddWM
		GuiControl,Enable,Transcode
		GuiControl,Enable,Clear
return

VDubCheckPerc:
    WinGetTitle,VDubTitle, ahk_pid %CurrPID%
    StringGetPos, PercPos, VDubTitle, %A_Space%
    VDubTitle :=SubStr(VDubTitle,1,PercPos)
    LV_Modify(CurrInd,"Col2",VDubTitle)
return

GuiClose:
	Gui,Submit
	IniWrite,%EdtExistFrame%,Settings.ini,Output,ExistFrames
	IniWrite,%EdtFadeFrames%,Settings.ini,Output,FadeFrames
	IniWrite,%VDUBEXE%,Settings.ini,VirtualDub,Program
	IniWrite,%Watermark%,Settings.ini,Watermark,Image
	IniWrite,%WmMask%,Settings.ini,Watermark,Mask
	IniWrite,%ChkDShow%,Settings.ini,Codec,DirectShow
    Exitapp
return

VDubCine(TempVScript,OutFile)
{
    FileAppend,
    (
    VirtualDub.audio.SetSource(1);
    VirtualDub.audio.SetMode(0);
    VirtualDub.audio.SetInterleave(1,500,1,0,0);
    VirtualDub.audio.SetClipMode(1,1);
    VirtualDub.audio.SetConversion(0,0,0,0,0);
    VirtualDub.audio.SetVolume();
    VirtualDub.audio.SetCompression();
    VirtualDub.audio.EnableFilterGraph(0);
    VirtualDub.video.SetInputFormat(0);
    VirtualDub.video.SetOutputFormat(7);
    VirtualDub.video.SetMode(3);
    VirtualDub.video.SetSmartRendering(0);
    VirtualDub.video.SetPreserveEmptyFrames(0);
    VirtualDub.video.SetFrameRate2(0,0,1);
    VirtualDub.video.SetIVTC(0,0,-1,0);
    VirtualDub.video.SetCompression(0x64697663,0,10000,0);
    VirtualDub.video.SetCompData(4,"Y29scg==");
    VirtualDub.video.filters.Clear();
    VirtualDub.audio.filters.Clear();
    VirtualDub.SaveAVI(U"%OutFile%");
    ),%TempVScript%
}
