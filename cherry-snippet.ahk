﻿; cherry-snippet 代码片段管理工具 
; Tested on AHK v1.1.33.02 Unicode 32/64-bit, Windows /10
; Script compiler directives
;@Ahk2Exe-SetMainIcon %A_ScriptDir%\Icons\super-command.ico
;@Ahk2Exe-SetVersion 0.1.0

; Script options
#SingleInstance Off  
instance_one()
#NoEnv
#MaxMem 640
#KeyHistory 0
#Persistent
SetBatchLines -1
DetectHiddenWindows On
SetWinDelay -1
SetControlDelay -1
SetWorkingDir %A_ScriptDir%
FileEncoding UTF-8
CoordMode, ToolTip, Screen
CoordMode, Caret , Screen
ListLines Off

;管理员运行
RunAsAdmin()

#include <py>
#include <wubi>
#include <btt>
#include <log>
#include <TextRender>
#include <json>
#include <utility>
#include <gdip_all>
#include <shinsoverlayclass>
#include <Class_SQLiteDB>
#include <cjson>
#Include <ZeroMQ>


OnMessage(0x201, "WM_LBUTTONDOWN")
OnMessage(0x004A, "Receive_WM_COPYDATA")  ; 0x004A 为 WM_COPYDATA
OnMessage(0x100, "GuiKeyDown")
OnMessage(0x002C, "ODLB_MeasureItem") ; WM_MEASUREITEM
OnMessage(0x002B, "ODLB_DrawItem") ; WM_DRAWITEM

log.is_log_open := false
log.is_out_file := true
log.is_enter := true

;加载配置
global g_json_path := A_ScriptDir . "/config/settings.json"
global g_map_py_path := A_ScriptDir . "/config/py_map.bin"
global g_map_py := {}
global g_config := {}
global startuplnk := A_StartMenu . "\Programs\Startup\cherry-snippet.lnk"
if(!loadconfig(g_config))
{
    MsgBox,% "Load config"  g_json_path " failed! will exit!!"
    ExitApp
}
if(!load_obj_config(g_map_py, g_map_py_path))
{
    MsgBox,% "Load config"  g_map_py_path " failed! will exit!!"
    ExitApp
}





;https://www.autohotkey.com/boards/viewtopic.php?t=3938
OD_LB  := "+0x0050" ; LBS_OWNERDRAWFIXED = 0x0010, LBS_HASSTRINGS = 0x0040
ODLB_SetItemHeight("s" g_config.win_list_font_size " Normal", "MS Shell Dlg 2")
ODLB_SetHiLiteColors(g_config.win_list_focus_back_color  , g_config.win_list_focus_text_color)

h1 := g_config.key_open_search_box,
h2 := g_config.key_send
h3 := g_config.key_open_search_box,
h4 := g_config.key_open_editor
h5 := g_config.key_edit_now
help_string =
(
v2.0
取消 [esc]
执行命令 [enter]
右键搜索框打开菜单
编辑所有命令 [%h4%]
打开当前搜索框 [%h1%]
发送命令到窗口 [%h2%]
编辑当前命令 [%h5%],或双击预览
复制当前父路径到搜索框 [Ctrl c]
复制当前文本 [%h3%],或右键单击预览
hook模式参看帮助说明
)
convert_key2str(help_string)
py.allspell_muti_ptr("ahk")
begin := 1
total_command := 0 ;总命令个数
is_get_all_cmd := false
menue_create_pid := 0


global g_is_rain := false
global g_listbox_height := 30
global g_max_listbox_number := 22
global g_curent_text := ""
global g_command := ""
global g_exe_name := ""
global g_exe_id := ""
global BackgroundColor := "1d1d1d"
global TextColor := "999999"
global cmds := ""
global arr_cmds := []
global arr_cmds_pinyin := []
global g_map_cmds := {}
global g_node_path := {}
global g_text_rendor := TextRender()
global g_text_rendor_clip := TextRender()
global g_hook_rendor := TextRender()
global g_hook_rendor_list := {}
global g_hook_strings := ""
global g_hook_array := []
global g_hook_real_index := 1
global g_hook_list_strings := ""
global g_hook_command := ""
global g_hook_mode := false
global g_should_reload := false
global g_my_menu_map := { "编辑当前命令: " convert_key2str(g_config.key_edit_now) : ["edit_now", A_ScriptDir "\Icons\编辑.ico"]
                            , "编辑全部命令: " convert_key2str(g_config.key_open_editor) : ["open_editor", A_ScriptDir "\Icons\编辑全部.ico"]
                            , "cherryTree跳转到当前命令: " convert_key2str(g_config.key_quick_switch_node) : ["key_quick_switch_node", A_ScriptDir "\Icons\cherry_black.ico"]
                            , "发送到窗口: " convert_key2str(g_config.key_send) : ["label_send_command", A_ScriptDir "\Icons\发送.ico"]
                            , "复制结果: " convert_key2str(g_config.key_open_search_box) : ["label_menu_copy_data", A_ScriptDir "\Icons\复制.ico"]
                            , "设置[Need DX11]" : ["open_setv2", A_ScriptDir "\Icons\设置.ico"]}

global g_wubi := ""
global g_total_show_number := g_config["win_hook_total_show_number"]

global TPosObj, pToken_, @TSF
DrawHXGUI("", "init")
if(g_config.is_use_86wubi)
    g_wubi := new wubi(A_ScriptDir "/config/wubi.bin")

if(g_config.tooltip_help)
    g_text_rendor.RenderOnScreen(help_string, "t: 5seconds x:left y:top pt:2", "s:15 j:left ")

ToolTip, 启动中...,0, 0

if !FileExist(g_config.cherry_tree_path)
{
    run,https://www.giuspen.com/cherrytree/
    run,https://pan.baidu.com/s/1_tzJ8SFvCQJXvVo5YxUEMg?pwd=1w2b
    FileSelectFile, SelectedFile, 3, , 选择cherrytree.exe文件, 执行文件 (cherrytree.exe)
    if (SelectedFile = "")
    {
        MsgBox, The user didn't select anything.
        ExitApp
    }
    g_config.cherry_tree_path := SelectedFile
}

if !FileExist(g_config.db_path)
{
    FileSelectFile, SelectedFile, 3, , 选择.ctb文件, ctb文件 (*.ctb)
    if (SelectedFile = "")
    {
        MsgBox, The user didn't select anything.
        ExitApp
    }
    g_config.db_path := SelectedFile
}
global db_file_path := g_config.db_path
saveconfig(g_config)

global DB := new SQLiteDB
Version := DB.Version
If !DB.OpenDB(db_file_path) 
{
   MsgBox, 16, SQLite Error, % "Msg:`t" . DB.ErrorMsg . "`nCode:`t" . DB.ErrorCode
   ExitApp
}

log.info("db parse ")
db_parse(DB)
log.info("end")

;注册热键
Hotkey,% g_config.key_open_search_box , label_key_open_search_box
Hotkey,% g_config.key_send , label_send_command
Hotkey,% g_config.key_open_editor , open_editor
Hotkey,% g_config.key_edit_now , edit_now
Hotkey,% g_config.hook_open , hook_open_label
Hotkey,% g_config.key_quick_switch_node , key_quick_switch_node

Menu, Tray, Icon, %A_ScriptDir%\Icons\super-command.ico
Menu, Tray, NoStandard
Menu, Tray, Add, 开机启动,AutoStart
if(FileExist(startuplnk))
    Menu, Tray, Check, 开机启动
Menu, Tray, add, 帮助,  open_github
Menu, Tray, icon, 帮助,% A_ScriptDir "\Icons\帮助.ico"
;Menu, Tray, add, 设置,  open_set
;Menu, Tray, icon, 设置,% A_ScriptDir "\Icons\设置.ico"
Menu, Tray, add, 设置[Need DX11],  open_setv2
Menu, Tray, icon, 设置[Need DX11],% A_ScriptDir "\Icons\设置.ico"
Menu, Tray, add,% "打开搜索框: " convert_key2str(g_config.key_open_search_box),  main_label
Menu, Tray, icon,% "打开搜索框: " convert_key2str(g_config.key_open_search_box),% A_ScriptDir "\Icons\搜索.ico"
Menu, Tray, add,% "添加命令: " convert_key2str(g_config.key_open_editor),  open_editor
Menu, Tray, icon,% "添加命令: " convert_key2str(g_config.key_open_editor),% A_ScriptDir "\Icons\添加.ico" 
Menu, Tray, Add , 重启, rel
Menu, Tray, icon , 重启,% A_ScriptDir "\Icons\重启.ico" 
Menu, Tray, Add , 退出, Exi
Menu, Tray, icon , 退出,% A_ScriptDir "\Icons\退出.ico" 
Menu, Tray, Default, 退出
Menu, Tray, Icon , %A_ScriptDir%\Icons\super-command.ico,, 1

; 添加一些菜单项来创建弹出菜单.
for k,v in g_my_menu_map
{
    Menu, Mymenu, add,% k,  MenuHandler
    Menu, Mymenu, icon,% k,% v[2]
}

;gdip
If !pToken := Gdip_Startup()
{
    MsgBox, 48, gdiplus error!, Gdiplus failed to start. Please ensure you have gdiplus on your system
    ExitApp
}
Gui, 2: -Caption +E0x80000 +LastFound +AlwaysOnTop +ToolWindow +OwnDialogs +hwndhwnd2
Gui, 2: Show, NA
Gui,2: Hide
pBitmap := Gdip_CreateBitmapFromFile(A_ScriptDir "\Icons\龙.png")
If !pBitmap
{
	MsgBox, 48, File loading error!, Could not load 'background.png'
	ExitApp
}

; Get a handle to this window we have created in order to update it later
; 获取2号句柄。
Width := Gdip_GetImageWidth(pBitmap), Height := Gdip_GetImageHeight(pBitmap)
hbm := CreateDIBSection(Width//2, Height//2)
hdc := CreateCompatibleDC()
obm := SelectObject(hdc, hbm)
G := Gdip_GraphicsFromHDC(hdc)
Gdip_SetInterpolationMode(G, 7)
Gdip_DrawImage(G, pBitmap, 0, 0, Width//2, Height//2, 0, 0, Width, Height)
UpdateLayeredWindow(hwnd2, hdc, 5, 0, Width//2, Height//2)
Gdip_DisposeImage(pBitmap)
Gdip_DeleteGraphics(G)
SelectObject(hdc, obm)
DeleteDC(hdc)
DeleteObject(hbm)

;=================================rain====================================================
SysGet, VirtualScreenWidth, 78
SysGet, VirtualScreenHeight, 79
SysGet, VirtualScreenX, 76
SysGet, VirtualScreenY, 77

;定时监控数据文件修改时间
;目前数据文件锁定状态没法判断，TODO
SetTimer, monitor_date_file, 250
ToolTip


log.info("start")
zmq := new ZeroMQ
context := zmq.context()
; Socket to send messages to
sender := context.socket(zmq.PUSH)
sender.connect("tcp://localhost:19935")
; Process tasks forever

;sender.zmq_send_string("hello world")


;activex gui preview gui
Gui, 3: Add , ActiveX ,x0 y0 w640 h480 vPane , Shell.Explorer
Gui, 3: +AlwaysOntop +hwndHtmlHwnd
Gui, 3: -Caption  +ToolWindow -DPIScale -Border
return  ; 脚本的自动运行段结束.

monitor_date_file:
;获取文件最后修改时间
FileGetTime, date_last_change_time,% db_file_path
SplitPath, db_file_path,, db_dir
;比较时间
if(date_last_change_time > g_config.last_parse_time)
{
    log.info(" - " db_dir " - CherryTree")
    WinGet, id, List,,, Program Manager
    Loop, %id%
    {
        this_id := id%A_Index%
        WinGetTitle, this_title, ahk_id %this_id%
        if(instr(this_title, " - " db_dir " - CherryTree"))
        {
            log.info(this_title)
            if(instr(this_title, "*"))
                log.info("not save")
            else
			{
				if(g_config.is_use_html_preview)
				{
					cmd := """" g_config.cherry_tree_path  """" " " """" g_config.db_path """" " -x "  """" g_config.html_path """" " -w -S"
					run,% cmd
				}
                Reload
			}
        }
    }
}
return

 ;开机启动
AutoStart:
if(FileExist(startuplnk))
	FileDelete, % startuplnk
else
	FileCreateShortcut, % A_ScriptFullpath, % startuplnk
Menu, Tray, ToggleCheck, 开机启动
return

MenuHandler:
if(!WinActive("ahk_id " MyGuiHwnd))
    return
log.info(A_ThisMenu, A_ThisMenuItem)
for k,v in g_my_menu_map
{
    if(A_ThisMenuItem == k)
        Gosub,% v[1]
}
Return

Sus:
    Suspend, Toggle
    if (A_IsSuspended)
        Menu, Tray, Icon , %A_ScriptDir%\Icons\Structor.ico
    Else
        Menu, Tray, Icon , %A_ScriptDir%\Icons\Verifier.ico
Return
Exi:
    ExitApp
Return
Rel:
    Reload
Return

~LButton::
    if(!WinActive("ahk_id " g_text_rendor.hwnd) && !WinActive("ahk_id " myguihwnd))
        return
    if winc_presses > 0 ; SetTimer 已经启动, 所以我们记录键击.
    {
        winc_presses += 1
        return
    }
    winc_presses = 1
    SetTimer, KeyWinC, -400 ; 在 400 毫秒内等待更多的键击.
return
KeyWinC:
    if winc_presses = 2 ; 此键按下了两次.
    {
        Gosub, edit_now_sub
    }
    winc_presses = 0
return

~RButton::
~MButton::
if(!WinActive("ahk_id " MyGuiHwnd))
    return
MouseGetPos, , , id, control
if(id == g_text_rendor.hwnd)
    return
Menu, MyMenu, Show
return

~*esc::
    goto GuiEscape
return

copy_command_to_editor:
    pos := InStr(g_command, "]", CaseSensitive := false, StartingPos := 0, Occurrence := 1)
    command := SubStr(g_command, 2, pos - 2)
    Clipboard := command
    WinWaitActive, ahk_exe cherrytree.exe, , 2
    if(ErrorLevel == 1)
    {
        log.info("no")
        return
    }
    sleep,250
    SendInput, ^t
    WinWaitActive,在多个节点中搜索 , , 2
    if(ErrorLevel == 1)
    {
        log.info("no")
        return
    }
    SendInput, {RShift Down}{Insert}{RShift Up}
    sleep,250
    SendInput, {Enter}
return
edit_new:
    if(!WinActive("ahk_id " MyGuiHwnd))
        return
    if(g_command == "")
    {
        msgbox, 请先在编辑框添加路径和短语, 提示: ctrl+c可复制已有路径
        return
    }
    
    FileDelete,% A_ScriptDir "\cmd\tmp\tmp.ahk"
    FileAppend,% "",% A_ScriptDir "\cmd\tmp\tmp.ahk",UTF-8
    GuiControlGet, Query

    command := ""
    ar := StrSplit(Query, ">", " `t")
    for k,v in ar
    {
        if(A_Index == 1)
            command := v
        else
            command .= " >" v
    }
    command := StrReplace(command, "$")

    tmp_path =
    (
        "%command%"
    ) 
    if(A_IsCompiled)
        run,% A_ScriptDir "\cmd\Adventure\Adventure.exe  " tmp_path " " my_pid
    else
        run,% A_ScriptDir "\v1\AutoHotkey.exe " A_ScriptDir "\cmd\Adventure\Adventure.ahk  " tmp_path " " my_pid
    goto GuiEscape
return

edit_now:
    if(!WinActive("ahk_id " MyGuiHwnd))
        return
edit_now_sub:
    if(g_command == "")
    {
        msgbox, 请输入命令的路径和短语, 提示: Ctrl+C 复制已有命令路径到编辑框
        return
    }
    
    FileDelete,% A_ScriptDir "\cmd\tmp\tmp.ahk"
    FileAppend,% g_curent_text,% A_ScriptDir "\cmd\tmp\tmp.ahk",UTF-8
    ;g_command := StrReplace(g_command, "$")

    id := g_map_cmds[g_command]
    if(g_map_cmds.HasKey(g_command))
        id := g_map_cmds[g_command]
    else
        return

    tmp_path =
    (
        "%id%"
    ) 
    db_file_path_send =
    (
        "%db_file_path%"
    )
    tmp_file_path = 
    (
        "%A_ScriptDir%\cmd\tmp\tmp.ahk"
    )

    Process Exist
    my_pid := ErrorLevel
    if(A_IsCompiled)
        run,% A_ScriptDir "\cmd\Adventure\Adventure.exe  " tmp_path " " my_pid " " db_file_path_send " " tmp_file_path
    else
        run,% A_ScriptDir "\v1\AutoHotkey.exe " A_ScriptDir "\cmd\Adventure\Adventure.ahk  " tmp_path " " my_pid " " db_file_path_send " " tmp_file_path
    goto GuiEscape
return

open_editor:
    Process Exist
    my_pid := ErrorLevel
    run,% "*RunAs " g_config.cherry_tree_path " " g_config.db_path
return

hook_open_label:
	if(g_config.is_hook_open_double_press) ;判断是否双击
	{
		if(!DoublePress())
			return
	}
    g_hook_strings := ""
    g_hook_list_strings := ""
    g_hook_mode := true
    g_hook_real_index := 1
    g_hook_array := []

    global SacHook := InputHook("E", "{Esc}")
    SacHook.OnChar := Func("SacChar")
    SacHook.OnKeyDown := Func("SacKeyDown")
    SacHook.OnEnd := Func("SacEnd")
    SacHook.KeyOpt("{Backspace}", "N")
    SacHook.Start()
    update_btt()
return
key_quick_switch_node:
	if(!WinActive("ahk_id " MyGuiHwnd) || g_command == "")
		return
	gosub GuiEscape

	run,% "*RunAs " g_config.cherry_tree_path " " g_config.db_path
	WinWaitActive, ahk_exe cherrytree.exe, , 2
	if(ErrorLevel == 1)
	{
		log.info("no")
		return
	}
	pos := InStr(g_command, "]", CaseSensitive := false, StartingPos := 0, Occurrence := 1)
	command := SubStr(g_command, 2, pos - 2)
	log.info(command)
	if(command != "")
		sender.zmq_send_string(command, zmq.ZMQ_DONTWAIT)
return

label_key_open_search_box:
if(g_config.is_open_search_box_double_press) ;判断是否双击
{
	if(!DoublePress())
		return
}
!q::
label_menu_copy_data:
main_label:
    x := g_config.win_x + g_config.win_w + 12
    y := g_config.win_y + 12
    if(g_config.tooltip_help)
    {
        if(g_config.tooltip_random == 1)
            g_text_rendor.RenderOnScreen(help_string, "x:" x " y:" y " color:Random", "s:" g_config.tooltip_font_size " j:left ")
        else
            g_text_rendor.RenderOnScreen(help_string, "x:" x " y:" y " color:" g_config.tooltip_back_color, "s:" g_config.tooltip_font_size " j:left " "c:" g_config.tooltip_text_color)
    }

    WinGet, g_exe_name, ProcessName, A
    WinGet, g_exe_id, ID , A
    g_command := ""
    if(g_config.auto_english)
    {
        SetCapsLockState,off
        switchime(0)
    }

    Gui +LastFoundExist
    if WinActive()
    {
        log.info(A_ThisHotkey)
        log.info(g_curent_text)
        if(g_curent_text != "" && (A_ThisHotkey == g_config.key_open_search_box || A_ThisLabel == "label_menu_copy_data"))
        {
            Clipboard := g_curent_text
            g_text_rendor_clip.RenderOnScreen("Saved text to clipboard.", "t:1250 c:#F9E486 y:75vh r:10%")
        }
        goto GuiEscape
    }
    Gui Destroy
    Gui Margin, 0, 0
    Gui, Color,% g_config.win_search_box_back_color,% win_search_box_back_color
    win_search_box_font_size := g_config.win_search_box_font_size
    Gui, Font, s%win_search_box_font_size% Q5, Consolas
    ;Gui, -0x400000 +Border ;WS_DLGFRAME WS_BORDER(细边框)  caption(标题栏和粗边框) = WS_DLGFRAME+WS_BORDER  一定要有WS_BORDER否则没法双缓冲
    gui, -Caption
    Gui, +AlwaysOnTop -DPIScale +ToolWindow +HwndMyGuiHwnd ;+E0x02000000 +E0x00080000 ;+E0x02000000 +E0x00080000 双缓冲
    w := g_config.win_w
    Gui Add, Edit, hwndEDIT x0 y10 w%w%  vQuery gType -E0x200
    SetEditCueBanner(EDIT, "🔍 右键菜单 🙇⌨🛐📜▪例➡🅱󠁁🇩  🚀🚀🚀🚀🚀")
    win_list_font_size := g_config.win_list_font_size
    Gui, Font, s%win_list_font_size%, Consolas
    Gui Add, ListBox, hwndLIST x0 y+0 h20 w%w%  vCommand gSelect AltSubmit -HScroll %OD_LB% -E0x200
    ControlColor(EDIT, MyGuiHwnd, g_config.win_search_box_back_color, g_config.win_search_box_text_color)
    ControlColor(LIST, MyGuiHwnd, g_config.win_list_back_color, g_config.win_list_text_color)

    LB_SetItemHeight(LIST, g_config.win_list_height)
    g_listbox_height := LB_GetItemHeight(LIST)

    win_x := g_config.win_x
    win_y := g_config.win_y
    if(g_config.is_show_logo == 1)
        gui,2: show, NA X%win_x% Y%win_y%
    Gui Show, X%win_x% Y%win_y%
    GuiControl, % "Hide", Command
    Gui, Show, AutoSize
    WinSet, Trans,% g_config.win_trans,ahk_id %myguihwnd%
    if(A_ThisHotkey == "!q")
        GuiControl,,% EDIT ,% " " g_exe_name

    overlay := ""
    ;overlay := new ShinsOverlayClass(win_x, win_y, w, VirtualScreenHeight,1,1,0)
    g_is_rain := true
return

Type:
    SetTimer Refresh, -10
return

Refresh:
    GuiControlGet Query
    r := []
    rows := ""
    row_id := []
    if (Query != "")
    {
	    q := StrSplit(Query, " ")
        r := Filter(arr_cmds_pinyin, q, c, rows, row_id)
    }
    else
    {
        g_text_rendor.clear()
        g_text_rendor.FreeMemory()
    }
    ;stop listbox
    GuiControl, -Redraw, Command
    GuiControl,, Command, % rows ? rows : "|"
    if (Query = "")
        c := row_id.MaxIndex()
    total_command := c
    ;获取item高度
    GuiControl, Move, Command, % "h" g_listbox_height * (total_command > g_max_listbox_number ? g_max_listbox_number : total_command)
    GuiControl, % (total_command && Query != "") ? "Show" : "Hide", Command
    HighlightedCommand := 1
    GuiControl, Choose, Command, 1
    ;redraw
    GuiControl, +Redraw, Command 
    Gui, Show, AutoSize
    WinGetPos, X, Y, W, H, ahk_id %myguihwnd%
    y := y + h
    if(g_config.is_show_logo == 1)
        gui,2: show, NA X%x% Y%y%
Select:
    GuiControlGet Command
    if !Command
        Command := 1
    Command := row_id[Command]
    TargetScriptTitle := "ahk_pid " menue_create_pid " ahk_class AutoHotkey"
    StringToSend := command
    result := Send_WM_COPYDATA(StringToSend, TargetScriptTitle)
    preview_command(command)
    if (A_GuiEvent != "DoubleClick")
        return

Confirm:
    GuiControlGet Command
    if !Command
        Command := 1
    Command := row_id[Command]
    if !GetKeyState("Shift")
        gosub GuiEscape

    if(SubStr(Query, 1 , 1) == "/")
        handle_plug(Query)
    else
        handle_command(Command)
return

label_send_command:
    log.info("send command")
    Gui +LastFoundExist
    if !WinActive()
        return
    GuiControlGet Command
    if !Command
        Command := 1
    Command := row_id[Command]
    gosub GuiEscape
    send_command(Command)
return

GuiEscape:
    g_is_rain := false
    Gui,2: hide
	gui,3: hide
    Gui,Hide
    g_text_rendor.Clear("")
    g_text_rendor.FreeMemory()
    g_text_rendor.DestroyWindow()
    g_text_rendor := ""
    global g_text_rendor := TextRender()

    global g_hook_rendor_list := {}

    g_hook_rendor.Clear("")
    g_hook_rendor.FreeMemory()
    g_hook_rendor.DestroyWindow()
    g_hook_rendor := ""
    global g_hook_rendor := TextRender()
    Process Exist
    my_pid := ErrorLevel
    Try
    {
        ;RunWait, %A_ScriptDir%/lib/empty.exe %my_pid%,,Hide
    }
    if(g_should_reload)
       Reload
return

#if g_hook_mode

+tab::
    up::
    tab_choose("-")
return

tab::
down::
    tab_choose()
return
#If

#IfWinActive, cherry-snippet ahk_class AutoHotkeyGUI

^Backspace::
    Send ^+{Left}{Backspace}
return

+Tab::
Up::
    if(HighlightedCommand == 1)
        HighlightedCommand := total_command
    else
        HighlightedCommand--
    GuiControl, Choose, command, %HighlightedCommand%
    gosub Select
    Gui, Show		
return

Tab::
Down::
    if(HighlightedCommand == total_command)
        HighlightedCommand := 1
    else
		HighlightedCommand++
    GuiControl, Choose, command, %HighlightedCommand%
    gosub Select
    Gui, Show
return
#If

GuiActivate(wParam)
{
    if (A_Gui && wParam = 0)
        SetTimer GuiEscape, -5
}

GuiKeyDown(wParam, lParam)
{
    if !A_Gui
        return
    log.info(A_ThisHotkey)
    if (wParam = GetKeyVK("Enter") && !GetKeyState("LCtrl"))
    {
        gosub Confirm
        return 0
    }
    if (wParam = GetKeyVK(key := "Down")
     || wParam = GetKeyVK(key := "Up"))
    {
        GuiControlGet focus, FocusV
        if (focus != "Command")
        {
            GuiControl Focus, Command
            if (key = "Up")
                Send {End}
            else
                Send {Home}
            return 0
        }
        return
    }
    if (wParam >= 49 && wParam <= 57 && !GetKeyState("Shift") && GetKeyState("LCtrl"))
    {
        SendMessage 0x18E,,, ListBox1
        GuiControl Choose, Command, % wParam-48 + ErrorLevel
        GuiControl Focus, Command
        gosub Select
        return 0
    }
    if (wParam = GetKeyVK(key := "PgUp") || wParam = GetKeyVK(key := "PgDn"))
    {
        GuiControl Focus, Command
        Send {%key%}
        return
    }
}

/** 
@brief 筛选
@param [IN] s 数组，所有命令,包括拼音
@param [IN] q 数组，query空格分割
@param [OUT] count 匹配个个数
return 新的数组
*/
filter(cmds, query, ByRef count, ByRef rows, ByRef row_id)
{
    arr_result := []
    real_index := 1
    for k,v in cmds
    {
        findSign := true
        Loop,% query.MaxIndex()
        {
            if(!InStr(v, query[A_Index], false))
            {
                findSign := false
                break
            }	
        }
        if(findSign == true)
        {
            arr_result.Push(k)
            row_id[real_index] := arr_cmds[k]
            tmp := substr(arr_cmds[k], instr(arr_cmds[k], "]") + 1)
            rows .= "|"  real_index " "  tmp
            real_index++
        }
    }
    count := arr_result.Length()
    return arr_result
}

preview_command(command)
{
    static preview_number := 0
    preview_number++
    if(preview_number == 5000)
        g_should_reload := true
    CoordMode, ToolTip, Screen
    global  menue_create_pid, log, gui_x, gui_y, g_curent_text, g_command, Pane, g_node_path

    id := g_map_cmds[command]
    if(g_map_cmds.HasKey(command))
        id := g_map_cmds[command]
    else
        return

    SQL := "SELECT * FROM node WHERE node_id = " id ";"
    If !DB.GetTable(SQL, Result)
    MsgBox, 16, SQLite Error, % "Msg:`t" . DB.ErrorMsg . "`nCode:`t" . DB.ErrorCode

    UnityPath := result.rows[1][3]


    g_command := command
    g_curent_text := UnityPath
    UnityPath := command "`n" UnityPath
    GuiControlGet, out, Pos, Query

	;html 预览
	log.info(html_file_path)
	html_file_path := g_config.html_path "\data.ctb_HTML\" g_node_path[id]["path_file"] ".html"

	if(g_config.is_use_html_preview && FileExist(html_file_path) && !g_hook_mode)
	{
		Pane.Navigate(html_file_path)

		;hdiv:=WB.document.getElementById("mainDiv").offsetHeight
		element := Pane.document.getElementsByTagName("div")
		log.info(element.Length)
		if(element.Length != 0)
		{
			hdiv:= element[0].offsetHeight
		}

		x := g_config.win_x + g_config.win_w
		y := g_config.win_y
		log.info(Pane.width)
		Gui, 3: Show,% "w760 h530 NoActivate" "x" x " y" y
		return
	}
	Gui, 3: hide

    if(!WinExist("超级命令添加工具") && UnityPath != "")
    {
        x := g_config.win_x + g_config.win_w + 12
        y := g_config.win_y + 12
        if(g_hook_mode)
        {
            g_hook_rendor.RenderOnScreen(substr(UnityPath, 1, 1000), " x:" g_hook_rendor_list.x2 + 10 " y:" g_hook_rendor_list.y + 11  " color:" g_config.tooltip_back_color
                                    , "s:" g_config.tooltip_font_size " j:left")
        }
            
        else
        {
            if(g_config.tooltip_random == 1)
                g_text_rendor.RenderOnScreen(substr(UnityPath, 1, 1000), "x:" x " y:" y " color:Random", "s:" g_config.tooltip_font_size " j:left ")
            else
                g_text_rendor.RenderOnScreen(substr(UnityPath, 1, 1000), "x:" x " y:" y " color:" g_config.tooltip_back_color, "s:" g_config.tooltip_font_size " j:left " "c:" g_config.tooltip_text_color)
        }
    }
    if(UnityPath == "")
    {
        g_text_rendor.Clear("")
        g_text_rendor.FreeMemory()
        g_hook_rendor.Clear("")
        g_hook_rendor.FreeMemory()
    }
}

send_command(command)
{
    global  menue_create_pid, log

    id := g_map_cmds[command]
    if(g_map_cmds.HasKey(command))
        id := g_map_cmds[command]
    else
        return

    SQL := "SELECT * FROM node WHERE node_id = " id ";"
    If !DB.GetTable(SQL, Result)
    MsgBox, 16, SQLite Error, % "Msg:`t" . DB.ErrorMsg . "`nCode:`t" . DB.ErrorCode

    UnityPath := result.rows[1][3]

    old_str := Clipboard
    clipboard := "" ; 清空剪贴板
    Clipboard := UnityPath
    ClipWait, 2
    if ErrorLevel
    {
        Clipboard := old_str
        return
    }
    SendInput, {RShift Down}{Insert}{RShift Up}
    ;sleep,500
    ;Clipboard := old_str
}
handle_plug(command)
{
    log.info(command)
    pos := InStr(command, A_Space)
    log.info(pos)
    if(pos == 0)
    {
        plug := SubStr(command, 2)
        command := ""
    }
    else
    {
        plug := SubStr(command, 2 , pos - 2)
        command := SubStr(command, pos)
        command := Trim(command)
    }
    log.info(plug, command)
    path := A_ScriptDir "\plugin\" plug
    file_path := A_ScriptDir "\plugin\" plug "\" plug ".ahk"
    init_plugin = 
    (%
        command := A_args[1]
        msgbox, 此插件需要完善，你输入的命令是 %command%
    )
    if(FileExist(file_path))
        run,% A_ScriptDir "\v1\autohotkey.exe " file_path " " command 
    else
    {
        FileCreateDir,% path
        FileAppend,% init_plugin ,% file_path,UTF-8
        run,% path
        run,% A_ScriptDir "\v1\autohotkey.exe " file_path " " command 
    }
}
handle_command(command)
{
    global menue_create_pid, log

    id := g_map_cmds[command]
    if(g_map_cmds.HasKey(command))
        id := g_map_cmds[command]
    else
        return

    SQL := "SELECT * FROM node WHERE node_id = " id ";"
    If !DB.GetTable(SQL, Result)
    MsgBox, 16, SQLite Error, % "Msg:`t" . DB.ErrorMsg . "`nCode:`t" . DB.ErrorCode

    UnityPath := result.rows[1][3]

    if(SubStr(UnityPath, 1, 3) == ";v2")
        ExecScript(UnityPath, A_ScriptDir, A_ScriptDir "\v2\AutoHotkey.exe")
    else if(SubStr(UnityPath, 1, 3) == "#py")
        execute_python(UnityPath)
    else if(SubStr(UnityPath, 1, 5) == "::bat")
        execute_bat(UnityPath)
    else if(SubStr(UnityPath, 1, 3) == ";v1" || SubStr(UnityPath, 1, 3) == "run")
    	ExecScript(UnityPath, A_ScriptDir, A_ScriptDir "\v1\AutoHotkey.exe")
    else
        send_command(command)
}

db_parse(DB)
{
    arr_cmds := []
    Script := ""

    SQL := "SELECT * FROM children;"
    If !DB.GetTable(SQL, Result)
        MsgBox, 16, db_parse SQLite Error, % "Msg:`t" . DB.ErrorMsg . "`nCode:`t" . DB.ErrorCode

    map_father := {}
    for k,v in result.rows
    {
        map_father[v[1]] := v[2] 
    }

    SQL := "SELECT * FROM node;"
    If !DB.GetTable(SQL, obj_sql_node)
        MsgBox, 16, SQLite Error, % "Msg:`t" . DB.ErrorMsg . "`nCode:`t" . DB.ErrorCode

    obj_sql_node.map_node := {}
    for k,v in obj_sql_node.rows
    {
        obj_sql_node.map_node[v[1]] := v 
    }

    id_path := {}
	;k id, v father
    for k,v in map_father
    {
        id_path[k] := {}
        id_path[k]["father_id"] := []
        path_string := obj_sql_node["map_node"][k][2]
		path_string_file := obj_sql_node["map_node"][k][2]
		if(instr(obj_sql_node["map_node"][k][5], "屏蔽"))
		{
			log.info("屏蔽节点", k,obj_sql_node["map_node"][k][2])
			id_path.Delete(k)
			Continue
		}
        loop
        {
			if(v != 0)
			{
				tag := obj_sql_node["map_node"][v][5]
				if(InStr(tag, "屏蔽"))
				{
					log.info("屏蔽节点", k,obj_sql_node["map_node"][k][2], "父节点有 屏蔽 标签", v)
					id_path.Delete(k)
					break
				}
			}
            if(map_father.HasKey(v))
            {
                path_string := obj_sql_node["map_node"][v][2] "-" path_string
				path_string_file := obj_sql_node["map_node"][v][2] "--" path_string_file
                id_path[k]["father_id"].Push(v)
            }
            else
            {
                id_path[k]["father_id"].Push(0)
                id_path[k]["path"] :=  "[" k "]" path_string 
				path_string_file := StrReplace(path_string_file, A_Space, "_")
				path_string_file := StrReplace(path_string_file, "/", "-")
                id_path[k]["path_file"] := path_string_file "_" k
                break
            }
            v := map_father[v]
        }
    }
	g_node_path := id_path

    g_map_cmds := {}
    for k,v in id_path
    {
        g_map_cmds[v["path"]] := k
        str := v["path"]
        str_key := str
        arr_cmds.Push(str)
        if(g_map_py.HasKey(str_key))
        {
            py_all := g_map_py[str_key][1]
            py_init := g_map_py[str_key][2]
        }
        else
        {
            py_all := py.allspell_muti_ptr(str_key)
            py_init := py.initials_muti_ptr(str_key)
            g_map_py[str_key] := []
            g_map_py[str_key][1] := py_all
            g_map_py[str_key][2] := py_init
        }
        str .= py_all py_init
        if(g_config.is_use_xiaohe_double_pinyin == 1)
        {
            if(g_map_py.HasKey(str_key) && g_map_py[str_key].HasKey(3))
                py_double := g_map_py[str_key][3]
            else
            {
                py_double := py.double_spell_muti_ptr(str_key)
                g_map_py[str_key][3] := py_double
            }
            str .= " " py_double
        }
        if(g_config.is_use_86wubi == 1)
        {
            if(g_map_py.HasKey(str_key) && g_map_py[str_key].HasKey(4))
                str_wubi := g_map_py[str_key][4]
            else
            {
                str_wubi := g_wubi.code(str)
                g_map_py[str_key][4] := str_wubi
            }
            str .= " " str_wubi
        }
        arr_cmds_pinyin.Push(str)
    }

	/*
    sql := "update node set tags=node_id"
    If !DB.Exec(sql)
        MsgBox, 16, SQLite Error, % "Msg:`t" . DB.ErrorMsg . "`nCode:`t" . DB.ErrorCode
	*/

    save_obj_config(g_map_py, g_map_py_path)
    g_config.last_parse_time := A_now
    saveconfig(g_config)
    g_map_py := ""
}

switchime(ime := "A")
{
	if (ime = 1)
		DllCall("SendMessage", UInt, WinActive("A"), UInt, 80, UInt, 1, UInt, DllCall("LoadKeyboardLayout", Str,"00000804", UInt, 1))
	else if (ime = 0)
		DllCall("SendMessage", UInt, WinActive("A"), UInt, 80, UInt, 1, UInt, DllCall("LoadKeyboardLayout", Str,, UInt, 1))
	else if (ime = "A")
		Send, #{Space}
}
execute_bat(script)
{    
    global g_curent_text,g_config
    FileDelete,% A_ScriptDir "\cmd\tmp\tmp.bat"
    FileAppend,% script,% A_ScriptDir "\cmd\tmp\tmp.bat",UTF-8
    Run,% A_ScriptDir "\cmd\tmp\tmp.bat"
}
execute_python(script)
{
    global g_curent_text,g_config
    FileDelete,% A_ScriptDir "\cmd\tmp\tmp.py"
    FileAppend,% script,% A_ScriptDir "\cmd\tmp\tmp.py",UTF-8
    Run,% ComSpec " /k "  g_config.python_path " """ A_ScriptDir "\cmd\tmp\tmp.py"""
}


RemoveToolTip:
    g_text_rendor.clear()
    g_text_rendor.FreeMemory()
return

Receive_WM_COPYDATA(wParam, lParam)
{
    global
    StringAddress := NumGet(lParam + 2*A_PtrSize)  ; 获取 CopyDataStruct 的 lpData 成员.
    CopyOfData := StrGet(StringAddress)  ; 从结构中复制字符串.
    menue_create_pid := CopyOfData
    ; 比起 MsgBox, 应该用 ToolTip 显示, 这样我们可以及时返回:
    ;ToolTip %A_ScriptName%`nReceived the following string:`n%CopyOfData%
    return true  ; 返回 1(true) 是回复此消息的传统方式.
}
Send_WM_COPYDATA(ByRef StringToSend, ByRef TargetScriptTitle)  ; 在这种情况中使用 ByRef 能节约一些内存.
; 此函数发送指定的字符串到指定的窗口然后返回收到的回复.
; 如果目标窗口处理了消息则回复为 1, 而消息被忽略了则为 0.
{
    VarSetCapacity(CopyDataStruct, 3*A_PtrSize, 0)  ; 分配结构的内存区域.
    ; 首先设置结构的 cbData 成员为字符串的大小, 包括它的零终止符:
    SizeInBytes := (StrLen(StringToSend) + 1) * (A_IsUnicode ? 2 : 1)
    NumPut(SizeInBytes, CopyDataStruct, A_PtrSize)  ; 操作系统要求这个需要完成.
    NumPut(&StringToSend, CopyDataStruct, 2*A_PtrSize)  ; 设置 lpData 为到字符串自身的指针.
    Prev_DetectHiddenWindows := A_DetectHiddenWindows
    Prev_TitleMatchMode := A_TitleMatchMode
    DetectHiddenWindows On
    SetTitleMatchMode 2
    TimeOutTime := 4000  ; 可选的. 等待 receiver.ahk 响应的毫秒数. 默认是 5000
    ; 必须使用发送 SendMessage 而不是投递 PostMessage.
    SendMessage, 0x004A, 0, &CopyDataStruct,, %TargetScriptTitle%  ; 0x004A 为 WM_COPYDAT
    DetectHiddenWindows %Prev_DetectHiddenWindows%  ; 恢复调用者原来的设置.
    SetTitleMatchMode %Prev_TitleMatchMode%         ; 同样.
    return ErrorLevel  ; 返回 SendMessage 的回复给我们的调用者.
}

load_obj_config(ByRef config, json_path)
{
    config := ""
    FileRead, OutputVar,% json_path
    config :=  JSON.Load(outputvar)
    if(config == "")
        return false
    return true
}
save_obj_config(config, json_path)
{
    str := JSON.Dump(config)
    FileDelete, % json_path
    FileAppend,% str,% json_path,UTF-8
}

loadconfig(ByRef config)
{
    Global g_json_path
    config := ""
    FileRead, OutputVar,% g_json_path
    config := json_toobj(outputvar)
    log.info(config)
    if(config == "")
        return false
    return true
}

saveconfig(config)
{
    global g_json_path
    str := json_fromobj(config)
    FileDelete, % g_json_path
    FileAppend,% str,% g_json_path,UTF-8
}

WM_LBUTTONDOWN(wParam, lParam, msg, hwnd) 
{
    global MyGuiHwnd, g_config, HtmlHwnd
	if(WinActive("ahk_id " HtmlHwnd))
	{
		return
	}
	PostMessage, 0xA1, 2 ; WM_NCLBUTTONDOWN
	KeyWait, LButton, U
    WinGetPos, X, Y, W, H, ahk_id %MyGuiHwnd%
    if(x != "" && y != "" && W != "")
    {
        g_config.win_x := X
        g_config.win_y := Y
        g_config.win_w := W
        saveconfig(g_config)
    }
}

SacChar(ih, char)  ; 当一个字符被添加到 SacHook.Input 时调用.
{
    if(GetKeyVK(char) == 13)
    {
        send_command(g_hook_command)
        SacEnd()
        return
    }
    if(char != A_tab)
        g_hook_strings .= char
    if(GetKeyVK(char) == 9)
        log.info("tab")
    else
        hook_mode_quck_search()
    log.info(char, GetKeyVK(char))
    log.info(g_hook_strings)
}

SacKeyDown(ih, vk, sc)
{
    if (vk = 8) ; 退格键
        g_hook_strings := SubStr(g_hook_strings, 1 , -1)
    log.info(g_hook_strings)
    SacChar(ih, "")
}
SacEnd()
{
    g_hook_rendor.Clear("")
    g_hook_rendor.FreeMemory()
    g_hook_rendor := ""
    g_hook_rendor := TextRender()

    g_hook_rendor_list := {}

    g_hook_mode := false
    DrawHXGUI("a", "")
	SacHook.stop()
}

hook_mode_quck_search()
{
	q := StrSplit(g_hook_strings, " ")
    rows := ""
    row_id := []
    r := Filter(arr_cmds_pinyin, q, c, rows, row_id)
    g_hook_list_strings := ""
    g_hook_array := []
    g_hook_real_index := 1
    real_index := 1
    for k,v in r
    {
        if(arr_cmds[v] != "")
        {
            g_hook_array[real_index] := arr_cmds[v]
            if(real_index == 1)
                g_hook_list_strings := real_index " " arr_cmds[v]
            else
                g_hook_list_strings .= "`r`n"  real_index " "  arr_cmds[v]
            real_index++
        }
    }
    update_btt()
}


update_btt()
{
    CoordMode, ToolTip, Screen
    g_hook_command := g_hook_array[g_hook_real_index]
    ps := GetCaretPos()

    midle_show_number := g_total_show_number / 2
    start_index := 1
    if(g_hook_real_index > midle_show_number)
        start_index := ceil(g_hook_real_index - midle_show_number)

    have_show := 1
    tmp_str := []
    loop,% g_total_show_number
    {
        if(start_index + A_index - 1 > g_hook_array.Length())
            break
        tmp_str.Push((start_index + A_index - 1) ". " substr(g_hook_array[start_index + A_index - 1], instr(g_hook_array[start_index + A_index - 1], "]") + 1))
    }
    log.info(g_total_show_number, start_index)
    log.info(tmp_str)
    DrawHXGUI(g_hook_strings == "" ? "⌨" : g_hook_strings, tmp_str, ps.x, ps.y 
                , g_hook_real_index - start_index + 1, 1
                , Font:= g_config["win_hook_font"], BackgroundColor := g_config["win_hook_backgroundcolor"]
                , TextColor := g_config["win_hook_textcolor"], CodeColor := g_config["win_hook_codecolor"]
                , BorderColor := g_config["win_hook_bordercolor"], FocusBackColor := g_config["win_hook_focusbackcolor"]
                , FocusColor := g_config["win_hook_focuscolor"], FontSize := g_config["win_hook_fontsize"]
                , FontBold := g_config["win_hook_fontbold"])
    WinGetPos, X, Y, W, H, ahk_id %@TSF%
    g_hook_rendor_list.x2 := X + w
    g_hook_rendor_list.y := y
    preview_command(g_hook_command)
}

tab_choose(opt := "")
{
    log.info(g_hook_array.Length())
    if(opt == "-") 
        g_hook_real_index--
    else
        g_hook_real_index++
    if(g_hook_real_index > g_hook_array.Length())
        g_hook_real_index := 1
    if(g_hook_real_index == 0)
        g_hook_real_index := g_hook_array.Length()
    update_btt()
}
open_setv2:
    run,% A_ScriptDir "\tool\set-v2\setv2.exe"
return
open_set:
    if(A_IsCompiled)
        run,% A_ScriptDir "\set.exe"
    else
        run,% A_ScriptDir "\v1\autohotkey.exe " A_ScriptDir "\set.ahk"
return

open_github:
;run,https://pan.baidu.com/s/1_tzJ8SFvCQJXvVo5YxUEMg?pwd=1w2b
run,https://github.com/sxzxs/cherry-snippet
run,https://zhangyue667.lanzouh.com/DirectXRepairEnhanced
run,https://blog.csdn.net/vbcom/article/details/7245186
return

convert_key2str(byref help_string)
{
    help_string := StrReplace(help_string, "+", "Shift ")
    help_string := StrReplace(help_string, "^", "Ctrl ")
    help_string := StrReplace(help_string, "!", "Alt ")
    help_string := StrReplace(help_string, "#", "Win ")
    help_string := StrReplace(help_string, "~$")
    StringUpper, help_string, help_string
    return help_string
}

write2db(data, id)
{
    ;SQL := "SELECT * FROM node WHERE node_id = 147;"
    sql := "UPDATE node SET tags = '" data "' WHERE node_id = " id ";"
    log.info(sql)
    If !DB.Exec(sql)
        MsgBox, 16, SQLite Error, % "Msg:`t" . DB.ErrorMsg . "`nCode:`t" . DB.ErrorCode
    return
}

;SQL := "SELECT * FROM children;"
;SQL := "SELECT * FROM node WHERE node_id = " v ";"

;wh := Width_and_Height("hello world!", "s:42")
;MsgBox wh[1] ", " wh[2]

Width_and_Height(text, s1:="", s2:="") {
    static tr := TextRender()
    tr.Draw(text, "x:0 y:0 c:None" . s1, s2) ; only supports string syntax, feel free to check for an object!
    try return [tr.w, tr.h]
    finally tr.Flush() ; Use this to clear the graphics 
}
Gdip_MeasureString2(pGraphics, sString, hFont, hFormat, ByRef RectF){
	Ptr := A_PtrSize ? "UPtr" : "UInt", VarSetCapacity(RC, 16)
	DllCall("gdiplus\GdipMeasureString", Ptr, pGraphics, Ptr, &sString, "int", -1, Ptr, hFont, Ptr, &RectF, Ptr, hFormat, Ptr, &RC, "uint*", Chars, "uint*", Lines)
	return &RC ? [NumGet(RC, 0, "float"), NumGet(RC, 4, "float"), NumGet(RC, 8, "float"), NumGet(RC, 12, "float")] : 0
}
DrawHXGUI(codetext, Textobj, x:=0, y:=0, localpos:= 0, Textdirection:=0
            , Font:="Microsoft YaHei UI", BackgroundColor := "444444"
            , TextColor := "EEECE2", CodeColor := "C9E47E"
            ,BorderColor := "444444", FocusBackColor := "CAE682"
            , FocusColor := "070C0D", FontSize := 20, FontBold := 0, Showdwxgtip := 0, func_key := "/")
{
	Critical
	global TPosObj, pToken_, @TSF
	static init:=0, Hidefg:=0, DPI:=A_ScreenDPI/96, MonCount:=1, MonLeft, MonTop, MonRight, MonBottom, minw:=0
		, MinLeft:=DllCall("GetSystemMetrics", "Int", 76), MinTop:=DllCall("GetSystemMetrics", "Int", 77)
		, MaxRight:=DllCall("GetSystemMetrics", "Int", 78), MaxBottom:=DllCall("GetSystemMetrics", "Int", 79)
		, xoffset, yoffset, hoffset  ; 左边、上边、编码词条间距离增量
		, fontoffset
	If !IsObject(Textobj){
		If (Textobj="init"){
			If !pToken_&&(!pToken_:=Gdip_Startup()){
				MsgBox, 48, GDIPlus Error!, GDIPlus failed to start. Please ensure you have gdiplus on your system, 5
				ExitApp
			}
			Gui, TSF: -Caption +E0x8080088 +AlwaysOnTop +LastFound +hwnd@TSF -DPIScale
			Gui, TSF: Show, NA
			SysGet, MonCount, MonitorCount
			SysGet, Mon, Monitor
		} Else If (Textobj="shutdown"){
			If (pToken_)
				pToken_:=Gdip_Shutdown(pToken_)
			Gui, TSF:Destroy
		} Else If (Textobj=""){
			hbm := CreateDIBSection(1, 1), hdc := CreateCompatibleDC(), obm := SelectObject(hdc, hbm)
			UpdateLayeredWindow(@TSF, hdc, 0, 0, 1, 1), SelectObject(hdc, obm), DeleteObject(hbm), DeleteDC(hdc)
			init:=0, minw:=0
		}
		Return
	} Else If (!init){
		If !pToken_&&(!pToken_:=Gdip_Startup()){
			MsgBox, 48, GDIPlus Error!, GDIPlus failed to start. Please ensure you have gdiplus on your system, 5
			ExitApp
		}
		xoffset:=FontSize*0.45, yoffset:=FontSize/2.5, hoffset:=FontSize/3.2, init:=1, fontoffset:=FontSize/16
		
		; 识别扩展屏坐标范围
		x:=(x<MinLeft?MinLeft:x>MaxRight?MaxRight:x), y:=(y<MinTop?MinTop:y>MaxBottom?MaxBottom:y)
		If (MonCount>1){
			If (MonInfo:=MDMF_GetInfo(MDMF_FromPoint(x,y)))
				MonLeft:=MonInfo.Left, MonTop:=MonInfo.Top, MonRight:=MonInfo.Right, MonBottom:=MonInfo.Bottom
			Else
				SysGet, Mon, Monitor
		}
	} Else
		x:=(x<MinLeft?MinLeft:x>MaxRight?MaxRight:x), y:=(y<MinTop?MinTop:y>MaxBottom?MaxBottom:y)
	hFamily := Gdip_FontFamilyCreate(Font), hFont := Gdip_FontCreate(hFamily, FontSize*DPI, FontBold)
	hFormat := Gdip_StringFormatCreate(0x4000), Gdip_SetStringFormatAlign(hFormat, 0x00000800), pBrush := []
	For __,_value in ["Background","Code","Text","Focus","FocusBack"]
		If (!pBrush[%_value%])
			pBrush[%_value%] := Gdip_BrushCreateSolid("0x" (%_value% := SubStr("FF" %_value%Color, -7)))
	pPen_Border := Gdip_CreatePen("0x" SubStr("FF" BorderColor, -7), 1)
	
	w:=MonRight-MonLeft, h:=MonBottom-MonTop
	; 计算界面长宽像素
	hdc := CreateCompatibleDC(), G := Gdip_GraphicsFromHDC(hdc)
	CreateRectF(RC, 0, 0, w-30, h-30), TPosObj:=[]
	If (!minw)
		minw := Gdip_MeasureString2(G, "⌨", hFont, hFormat, RC)[3]
	CodePos := Gdip_MeasureString2(G, codetext "|", hFont, hFormat, RC), CodePos[1]:=xoffset
	, CodePos[2]:=yoffset, mh:=CodePos[2]+CodePos[4], mw:=Max(CodePos[3], minw)
	If (Textdirection=1||InStr(codetext, func_key)){
		mh+=hoffset
		Loop % Textobj.Length()
			TPosObj[A_Index] := Gdip_MeasureString2(G, Textobj[A_Index], hFont, hFormat, RC), TPosObj[A_Index,2]:=mh
			, mh += TPosObj[A_Index,4], mw:=Max(mw,TPosObj[A_Index,3]), TPosObj[A_Index,1]:=CodePos[1]
		Loop % Textobj[0].Length()
			TPosObj[0,A_Index] := Gdip_MeasureString2(G, Textobj[0,A_Index], hFont, hFormat, RC), TPosObj[0,A_Index,2]:=mh
			, mh += TPosObj[0,A_Index,4], mw:=Max(mw,TPosObj[0,A_Index,3]), TPosObj[0,A_Index,1]:=CodePos[1]
		Loop % Textobj.Length()
			TPosObj[A_Index,3]:=mw
		Loop % Textobj[0].Length()
			TPosObj[0,A_Index,3]:=mw
		mw+=2*xoffset, mh+=yoffset
	} Else {
		t:=xoffset, mh+=hoffset
		TPosObj[1] := Gdip_MeasureString2(G, Textobj[1], hFont, hFormat, RC), TPosObj[1,2]:=mh, TPosObj[1,1]:=t, t+=TPosObj[1,3]+hoffset, maxh:=TPosObj[1, 4]
		Loop % (Textobj.Length()-1){
			TPosObj[A_Index+1]:=Gdip_MeasureString2(G, Textobj[A_Index+1], hFont, hFormat, RC), maxh:=Max(maxh, TPosObj[A_Index+1, 4])
			If (t+TPosObj[A_Index+1,3]<=w-30)
				TPosObj[A_Index+1,1]:=t, TPosObj[A_Index+1,2]:=TPosObj[A_Index,2], t+=TPosObj[A_Index+1,3]+hoffset
			Else
				mw:=Max(mw,t), TPosObj[A_Index+1,1]:=xoffset, mh+=TPosObj[A_Index,4], TPosObj[A_Index+1,2]:=mh, t:=xoffset+TPosObj[A_Index+1,3]+hoffset
		}
		mw:=Max(mw,t)
		mh+=maxh
		Loop % Textobj[0].Length()
			TPosObj[0,A_Index] := Gdip_MeasureString2(G, Textobj[0,A_Index], hFont, hFormat, RC), TPosObj[0,A_Index,1]:=xoffset, TPosObj[0,A_Index,2]:=mh, mh += TPosObj[0,A_Index,4], mw:=Max(mw,TPosObj[0,A_Index,3])	
		Loop % Textobj[0].Length()
			TPosObj[0,A_Index,3]:=mw-xoffset
		mw+=xoffset, mh+=yoffset
	}
	Gdip_DeleteGraphics(G), hbm := CreateDIBSection(mw, mh), obm := SelectObject(hdc, hbm)
	G := Gdip_GraphicsFromHDC(hdc), Gdip_SetSmoothingMode(G, 2), Gdip_SetTextRenderingHint(G, 4+(FontSize<21))
	; 背景色
	Gdip_FillRoundedRectangle(G, pBrush[Background], 0, 0, mw-2, mh-2, 5)
	; 编码
	CreateRectF(RC, CodePos[1], CodePos[2], w-30, h-30), Gdip_DrawString(G, codetext, hFont, hFormat, pBrush[Code], RC)
	Loop % Textobj.Length()
		If (A_Index=localpos)
			Gdip_FillRoundedRectangle(G, pBrush[FocusBack], TPosObj[A_Index,1], TPosObj[A_Index,2]-hoffset/3, TPosObj[A_Index,3], TPosObj[A_Index,4]+hoffset*2/3, 3)
			, CreateRectF(RC, TPosObj[A_Index,1], TPosObj[A_Index,2]+fontoffset, w-30, h-30), Gdip_DrawString(G, Textobj[A_Index], hFont, hFormat, pBrush[Focus], RC)
		Else
			CreateRectF(RC, TPosObj[A_Index,1], TPosObj[A_Index,2]+fontoffset, w-30, h-30), Gdip_DrawString(G, Textobj[A_Index], hFont, hFormat, pBrush[Text], RC)
	Loop % Textobj[0].Length()
		CreateRectF(RC, TPosObj[0,A_Index,1], TPosObj[0,A_Index,2], w-30, h-30), Gdip_DrawString(G, Textobj[0,A_Index], hFont, hFormat, pBrush[Text], RC)

	; 定位提示
	If (Showdwxgtip){
		If !pBrush["FFFF0000"]
			pBrush["FFFF0000"] := Gdip_BrushCreateSolid("0xFFFF0000")	; 红色
		CreateRectF(RC, TPosObj[1,1], TPosObj[1,2]+FontSize*0.70, w-30, h-30)
		Gdip_DrawString(G, "   " SubStr("　ａｂｃｄｅｆｇｈｉｊｋｌｍｎｏｐｑｒｓｔｕｖｗｘｙｚ",1,StrLen(jichu_for_select_Array[1,2])), hFont, hFormat, pBrush["FFFF0000"], RC)
	}
	; 边框、分隔线
	Gdip_DrawRoundedRectangle(G, pPen_Border, 0, 0, mw-2, mh-2, 5)
	Gdip_DrawLine(G, pPen_Border, xoffset, CodePos[4]+CodePos[2], mw-xoffset, CodePos[4]+CodePos[2])
	UpdateLayeredWindow(@TSF, hdc, tx:=Min(x, Max(MonLeft, MonRight-mw)), ty:=Min(y, Max(MonTop, MonBottom-mh)), mw, mh)
	SelectObject(hdc, obm), DeleteObject(hbm), DeleteDC(hdc), Gdip_DeleteGraphics(G)

	Gdip_DeleteStringFormat(hFormat), Gdip_DeleteFont(hFont), Gdip_DeleteFontFamily(hFamily)
	For __,_value in pBrush
		Gdip_DeleteBrush(_value)
	Gdip_DeletePen(pPen_Border)
	WinSet, AlwaysOnTop, On, ahk_id%@TSF%
}
DoublePress() {
    if (A_ThisHotkey = A_PriorHotkey) and (A_TimeSincePriorHotkey < 500) {
        return true
    } else {
        return false
    }
}