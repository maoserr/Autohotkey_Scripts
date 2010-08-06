#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.\
#SingleInstance force
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
FileInstall,my_icon.ICO,my_icon.ICO
Menu,Tray,Icon,my_icon.ICO
Menu,Tray,NoStandard
Menu,Tray,Add,Check weather,WeatherPopupLbl
Menu,Tray,Add,Exit,ExitLbl
Menu,Tray,Tip,Hold 'Win' and press '=' to show weather

StringPad(CurrStr,FullLen)
{
    StringLength :=StrLen(CurrStr)
    if StringLength<%FullLen%
    {
        PadLen := FullLen - StringLength
        Loop, %PadLen%
        {
            CurrStr:= CurrStr . A_Space
        }
    }
    return CurrStr
}
Popup(title,action,close=true,image="",w=197,h=46)
{
    SysGet, Screen, MonitorWorkArea
    ScreenRight-=w+3
    ScreenBottom-=h+4
    SplashImage,%image%,CWe0dfe3 b1 x%ScreenRight% y%ScreenBottom% w%w% h%h% C00 FM8 FS8, %action%,%title%,Popup
    WinSet, Transparent, 216, Popup
    if close
        SetTimer, ClosePopup, -2000
    return
}

WeatherPopup()
{
    Popup("Weather","Retrieving Weather...",false)
    UrlDownloadToFile,http://xoap.weather.com/weather/local/27127?cc=*&prod=xoap&par=1058965630&key=f8e6eb87d3bbd2f8&dayf=4&link=xoap
        ,%A_temp%\Weather.xml
    FileRead,WeatherData,%A_temp%\Weather.xml
    ;Get City Name
    RegExMatch(WeatherData,"<dnam>(.*)</dnam>",City)
    ;Parse Current Conditions
    RegExMatch(WeatherData,"s)<cc>(.*)</cc>",CC)
    RegExMatch(CC1,"<tmp>(.*)</tmp>",Temp)
    RegExMatch(CC1,"<icon>(.*)</icon>",Icon)
    RegExMatch(CC1,"<t>(.*)</t>",CondCC)
    RegExMatch(CC1,"<lsup>(.*)</lsup>",Lsup)
    Loop,4
    {
        RegExmatch(WeatherData,"<day d=""" A_Index-1 """ t=""(.*)"" dt=""(.*)"">(?s)(.+?)(</day>)",FC)
        RegExMatch(FC3,"<hi>(.*)</hi>",Hi1)
        RegExMatch(FC3,"<low>(.*)</low>",Low1)
        RegExMatch(FC3,"<t>(.+?)</t>(?s)(.*)<t>(.+?)</t>(.*)<t>(.+?)</t>(.*)<t>(.+?)</t>",Cond1)
        WeatherTxt := StringPad(FC1,10) " `t" Low11 "°F-" Hi11 "°F`n  Day:  `t " Cond11 "`n  Night:`t " Cond15 

        Txt := Txt . WeatherTxt . "`n"
    }
    Header := City1 "`n" Temp1 "°F, " CondCC1
    Txt := Txt "`n`t" Lsup1
    Icon := "WeatherIcons\" . Icon1 . ".gif"
    Popup(Header,Txt,true,Icon,200,260)
}

#=::WeatherPopup()

ClosePopup:
    WinGet,WinID,ID,Popup
    MouseGetPos,,,MouseWinID
    ifEqual,WinID,%MouseWinID%
    {
        SetTimer, ClosePopup, -2000
    }else{
        SplashImage, Off
    }
    return

WeatherPopupLbl:
	WeatherPopup()
	return

ExitLbl:
	ExitApp
	return
