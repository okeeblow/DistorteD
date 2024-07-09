@ECHO OFF
:: okeeblow's lazy game picking + network error avoiding batch script.
::
:: This script assumes games will be laid out in a consistent directory structure.
:: My IIDX25 PC has a 1TB drive with the stock D: partition expanded to fill that space.
:: Games all live in D:\IIDX\<number>\contents\.
:: Only one copy of a game will ever have Omnimix installed, it will be replaced when
:: the next one is available, and the previous version will be replaced with a clean copy.
:: Same goes for BMS-in-IIDX mods like (red emoji 'B') [b]opula, [B]ino[B]uz, [B]ANNON [B]ALLERS.
::
:: Install this script in place of D:\SELECT.BAT (after renaming KONAMI's original to .bak)
:: and you won't have to touch the C: drive at all.
:: This script avoids clearing the screen (CLS) so it looks like a natural part of the normal
:: KONAMI boot sequence unless you unlock the cabinet and press the key to show the menu.
::
:: Notes:
:: I use this on Windows 7 Embedded, and the arguments to 64-bit CHOICE.EXE (Vista and newer)
:: differ from the version of CHOICE found on the old NT/2000 Resource Kit which
:: was the version in my XP Embedded OS image on the LDJ PC.
::
:: WinNT CHOICE:
:: - Default choice and timeout in the same argument: /T,[default],[timeout] e.g. /T:A,10
:: - Case-sensitivity is enabled with /S
::
:: 64-bit CHOICE:
:: - Default choice and timeout are separate arguments: /T:[timeout] /D:[default] e.g. /T:10 /D:A
:: - Case-sensitivity is enabled with /CS
::
:: Both CHOICE versions:
:: - Choices can be any combination of letters and numbers.
:: - Specify your choices with the argument /C:[choices] e.g. /C:ABC456
:: - Selecting a choice fills the %ERRORLEVEL% variable with the 1-indexed number of that choice
::   in the order they were specified to /C, so choosing 'A' from /C:BCA321 gives %ERRORLEVEL% == 3.
:: - Use /M to add a text prompt
::   e.g. /M:"Where do you want to go today?" /C:KTN prompts "Where do you want to go today? [K,T,N]?".
:: - Use /N to disable showing choices in the prompt e.g. "[Y/N]?".
::   Any text from an /M argument is still shown, so you can build your own prompt format e.g.
::   /C:KTN /N /M:"Where do you want to go today? [K]nowledge Base, [T]echnet, The Microsoft [N]etwork"

:: Where do your games live?
SET "GAMEDIR=D:\IIDX"

:: Network test will depend on pinging this hostname.
SET "XRPC=xrpc.example.com"

:: What to boot by default if nothing is manually selected.
SET "DEFAULTGAMEVER=26"

:: What version has Omnimix installed?
SET "OMNIGAMEVER=25"

:: These are what :Launch_Game will use. The menu will override these defaults.
SET "DEFAULTGAMESCRIPT=gamestart.bat"
SET "GAMEVER=%DEFAULTGAMEVER%"
SET "GAMESCRIPT=%DEFAULTGAMESCRIPT%"

:: And start the script.
CD C:\

:: The stock SELECT.BAT uses a 30-second ping to localhost to add this delay while
:: the network / DHCP comes up, but I found that to not always be long enough
:: in situations of weak WiFi or a network cable with a broken wire inside.
ECHO Initialize Network...
:: 'G' doesn't get checked here but use it for consistency with :Network_Fail.
CHOICE.EXE /C:TG /N /T:30 /D:T > NUL
IF "%ERRORLEVEL%" == "1" GOTO Network_Test

:: Normally you'd want to `EXIT /B` here before labeled subroutine definitions,
:: but try to avoid the possibility of exiting to a blank desktop on the cabinet
:: by launching the game instead, even if the game launches to a network error.
:: This should never get called since Network_Test will get there eventually.
GOTO Launch_Game

:: The stock SELECT.BAT doesn't try to ping services at all, just localhost as a
:: way to wait 30 seconds. I prefer to ping the actual XRPC server in case the
:: cabinet gets unplugged while I'm away and somebody forgets the network cable
:: when plugging it back in. This provides a way to wait and retry before starting
:: the game, because once the game hits a 5-2xxx error it will never continue
:: unless somebody has the key and hits the Test button inside.
:: Relying on PING's %ERRORLEVEL% is unreliable because it can still be set
:: to 0 (success) depending on if a failure is Unreachable vs Timeout.
:: Work around this by piping to FIND to look for the string TTL= from a true success.
::
:: I purposefully avoid showing a prompt to escape to game menu (/N) so it can't
:: be seen in public if the machine reboots unattended for some reason.
:Network_Test
ECHO Check Network...
ping -n 5 %XRPC% | FIND "TTL=" > NUL
IF "%ERRORLEVEL%" == "1" GOTO Network_Fail
IF "%ERRORLEVEL%" == "0" (
  ECHO Network OK.
  CHOICE.EXE /C:GM /N /T:10 /D:G > NUL
  IF "%ERRORLEVEL%" == "1" GOTO Launch_Game
  IF "%ERRORLEVEL%" == "2" GOTO Game_Menu
)
:: Safety net
GOTO Launch_Game

:: As above, I hide the choices here on purpose so this can run in public without
:: appearing to be interactive. The keyboard will always be locked away but the
:: machine may still get unplugged and have to boot unattended.
:Network_Fail
ECHO Failed to check network. Retrying...
CHOICE.EXE /C:TGMSC /N /T:5 /D:T > NUL
IF "%ERRORLEVEL%" == "1" GOTO Network_Test
IF "%ERRORLEVEL%" == "2" GOTO Launch_Game
IF "%ERRORLEVEL%" == "3" GOTO Game_Menu
IF "%ERRORLEVEL%" == "4" GOTO Launch_Shell
IF "%ERRORLEVEL%" == "5" GOTO Launch_CMD

:: This menu times out aggressively to avoid the possibility that the cabinet
:: could get stuck here if it reboots and something fell on the 'M' key.
:Game_Menu
CLS
CD C:\
ECHO beatmania IIDX launch menu
ECHO ----------
ECHO 1) Lincle
ECHO 2) tricoro
ECHO 3) SPADA
ECHO 4) PENDUAL
ECHO 5) copula
ECHO 6) SINOBUZ
ECHO 7) CANNON BALLERS
ECHO 8) Rootage
ECHO -
ECHO D) Default version
ECHO O) IIDX Omnimix
ECHO B) BMS in IIDX engine
ECHO -
ECHO S) Exit to Shell
ECHO C) Exit to CMD
ECHO ----------
ECHO Automatic launch in 30 seconds...
CHOICE.EXE /C:123456789DOBSC /N /T:30 /D:D > NUL

IF "%ERRORLEVEL%" == "1" SET "GAMEVER=19" & SET "GAMESCRIPT=gamestart-KDZ.bat"
IF "%ERRORLEVEL%" == "2" SET "GAMEVER=20" & SET "GAMESCRIPT=%DEFAULTGAMESCRIPT%"
IF "%ERRORLEVEL%" == "3" SET "GAMEVER=21" & SET "GAMESCRIPT=%DEFAULTGAMESCRIPT%"
IF "%ERRORLEVEL%" == "4" SET "GAMEVER=22" & SET "GAMESCRIPT=%DEFAULTGAMESCRIPT%"
IF "%ERRORLEVEL%" == "5" SET "GAMEVER=23" & SET "GAMESCRIPT=%DEFAULTGAMESCRIPT%"
IF "%ERRORLEVEL%" == "6" SET "GAMEVER=24" & SET "GAMESCRIPT=%DEFAULTGAMESCRIPT%"
IF "%ERRORLEVEL%" == "7" SET "GAMEVER=25" & SET "GAMESCRIPT=%DEFAULTGAMESCRIPT%"
IF "%ERRORLEVEL%" == "8" SET "GAMEVER=26" & SET "GAMESCRIPT=%DEFAULTGAMESCRIPT%"
IF "%ERRORLEVEL%" == "10" SET "GAMEVER=%DEFAULTGAMEVER%" & SET "GAMESCRIPT=%DEFAULTGAMESCRIPT%"
IF "%ERRORLEVEL%" == "11" SET "GAMEVER=%OMNIGAMEVER%" & SET "GAMESCRIPT=gamestart_omni.bat"
IF "%ERRORLEVEL%" == "12" SET "GAMEVER=BMS" & SET "GAMESCRIPT=%DEFAULTGAMESCRIPT%"
IF "%ERRORLEVEL%" == "13" GOTO Launch_Shell
IF "%ERRORLEVEL%" == "14" GOTO Launch_CMD
GOTO Launch_Game

:Launch_Game
ECHO Launching...
cd "%GAMEDIR%\%GAMEVER%\contents\"
call "%GAMESCRIPT%"
GOTO Game_Menu

:Launch_Shell
ECHO Launching shell...
Start explorer.exe
exit /b

:Launch_CMD
ECHO Launching cmd...
Start cmd.exe
exit /b
