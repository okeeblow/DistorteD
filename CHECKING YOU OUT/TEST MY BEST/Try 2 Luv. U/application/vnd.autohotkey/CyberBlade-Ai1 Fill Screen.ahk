#NoEnv  ; Avoid shadowing empty variables with same-name Environment Variables.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Make `Send` synonymous with SendInput rather than the default SendEvent.
SetWorkingDir %A_ScriptDir%  ; Set CWD to our script file's location.

; COOLTRAINER-DOT-ORG Trident CyberBlade-Ai1 "Display Stretch" auto activator 2024-07-04!!
;
; There seems to be no registry key to control this option of `trid3dm.sys` like the
; other keys in `HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\trid3d\Device0`
; and the selection does not persist between reboots (even with clean shutdown),
; so this script run once as a startup item will enable full-screen gaming automatically!

Run control desk.cpl`,`,3  ; Open the Settings tab of Display Properties.

; Focus the Display Properties window.
; ControlClick takes a WinTitle argument directly but I prefer focusing separately and first.
; YES I REALIZE THIS DEPENDS ON LOCALE. I am an American Anglophone so deal with it lol
DisplayProperties = Display Properties
WinActivate %DisplayProperties%
WinWaitActive %DisplayProperties%

ControlClick, Button4  ; Click the `Advanced` butan.

; Switch to partial Window title match because the full window title will depend on the number of
; attached monitors, on the driver version, and on the bus type. For example it is
; "(Multiple Monitors) and Trident Video Accelerator CyberBlade-Ai1 AGP 5.8089-66.100 Properties"
; on my HITACHI FLORA 270HX NW5. Gross!
SetTitleMatchMode, 2
TridentWindow = Trident Video Accelerator CyberBlade-Ai1
WinActivate %TridentWindow%
WinWaitActive %TridentWindow%

; We can't use X/Y position to click this! The number and arrangement of tabs depends on
; this machine's other installed software. SciTech Display Doctor, for example, adds its own
; tab to this window in addition to those stock in Windows and those of the Trident driver.
; Find the tab number by text instead and focus it that way.
ControlGet, FlatPanelTabNumber, Tab, , SysTabControl321, %TridentWindow%, Flat Panel
SendMessage 0x1330, %FlatPanelTabNumber%,, SysTabControl321, A  ; 0x1330 == TCM_SETCURFOCUS

Click, 282 380                          ; Do the thing.
ControlClick, Button1, %TridentWindow%  ; Click OK to save changes.
WinClose %DisplayProperties%            ; Clean up Display Properties window.