#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.\
#SingleInstance force

SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
Menu,Tray,Icon,my_icon.ICO
Menu,Tray,NoStandard
Menu,Tray,Add,Check weather,WeatherPopupLbl
Menu,Tray,Add,Change location,WeatherSearch
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
WeatherPopup()
{
	global locid
    Popup("Weather","Retrieving Weather...",false)
    UrlDownloadToFile,http://xoap.weather.com/weather/local/%locid%?cc=*&prod=xoap&par=1058965630&key=f8e6eb87d3bbd2f8&dayf=4&link=xoap
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

IniRead,locid,%A_ScriptDir%\Settings.ini,Default,Location,NONE
IniRead,locname,%A_ScriptDir%\Settings.ini,Default,LocName,NONE
if locid=NONE
{
	GoSub,WeatherSearch
}

#=::WeatherPopup()

WeatherSearch:
	if !GuiShown
	{
		Gui,Add,Text,,Enter address or zip code to search for new location
		Gui,Add,Edit,vlocsearch
		Gui,Add,Button,gSearch,Search
		Gui,Add,ListBox,vresults
		Gui,Add,Button,gDoneS,Done
	}
	Gui,Show,,Location
	GuiShown=1
	return

Search:
	Gui,Submit,NoHide
	UrlDownloadToFile,http://xoap.weather.com/search/search?where=%locsearch%
		,%A_temp%\Search.xml
	FileRead,SearchData,%A_temp%\Search.xml
	Pos = 1
	SearchCnt = 0
	ListBox =
	Loop{
		Pos := RegExMatch(SearchData,"<loc id=""(.*)"" type=""(.*)"">(.*)</loc>",LL,Pos)
		if Pos=0
			Break
		SearchCnt += 1
		Pos += 1
		Res%SearchCnt% := LL1
		ResN%SearchCnt% := LL3
		ListBox = %ListBox%|%LL3%
	}
	GuiControl,,results,%ListBox%
	return

DoneS:
	Gui,Submit
	Loop,%SearchCnt%
	{
		if ResN%A_index%=%results%
		{
			locid := Res%A_index%
			locname := ResN%A_index%
			Break
		}
	}
	IniWrite,%locid%,%A_ScriptDir%\Settings.ini,Default,Location
	IniWrite,%locname%,%A_ScriptDir%\Settings.ini,Default,LocName
	return

WeatherPopupLbl:
	WeatherPopup()
	return

ExitLbl:
	ExitApp
	return

#include ../Popup.ahk

