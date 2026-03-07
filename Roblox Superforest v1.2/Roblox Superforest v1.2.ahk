#Requires AutoHotkey v2.0
#SingleInstance Force
#Include Lib\OCR.ahk
#Include Lib\JSON.ahk
CoordMode "Mouse", "Client"
Persistent

if !A_IsAdmin {
    Run '*RunAs "' A_ScriptFullPath '"'
    ExitApp
}

if A_IsCompiled {
    mainTemp := A_AppData "\Superforest"
    if not DirExist(mainTemp)
        DirCreate (mainTemp)

    if not DirExist(mainTemp "\Assets")
        DirCreate (mainTemp "\Assets")

    if not DirExist(mainTemp "\Lib")
        DirCreate(mainTemp "\Lib")

    if not FileExist(mainTemp "\Assets\ps to deeplink.txt") {
        FileInstall "Assets\ps to deeplink.txt", mainTemp "\Assets\ps to deeplink.txt", true
    }

    if not FileExist(mainTemp "\Assets\splash.png") {
        FileInstall "Assets\splash.png", mainTemp "\Assets\splash.png", true
    }

    if not FileExist(mainTemp "\Lib\config.ini") {
        FileInstall "Lib\config.ini", mainTemp "\Lib\config.ini", true
    }

    if not FileExist(mainTemp "\Lib\OCR.ahk") {
        FileInstall "Lib\OCR.ahk", mainTemp "\Lib\OCR.ahk", true
    }

    if not FileExist(mainTemp "\Lib\JSON.ahk") {
        FileInstall "Lib\JSON.ahk", mainTemp "\Lib\JSON.ahk", true
    }

    global configIni := mainTemp "\Lib\config.ini"
    global splashImage := mainTemp "\Assets\splash.png"

} else {
    global configIni := A_ScriptDir "\Lib\config.ini"
    global splashImage := A_ScriptDir "\Assets\splash.png"
}

$F5:: PauseMacro()
$F7:: ExitApp

global hwnd
global potionSlot := 0
global discordQueue := []
global deepLinkRun := false
global discordWorkerRunning := false
global TopGui := "", BottomGui := "", LeftGui := "", RightGui := ""
global rblxWindows := WinGetList("ahk_exe RobloxPlayerBeta.exe")

DeepLink := IniRead(configIni, "UserConfig", "DeepLink")
DelayMultiplier := IniRead(configIni, "UserConfig", "DelayMultiplier")
ReconnectionDelay := IniRead(configIni, "UserConfig", "ReconnectionDelay")
WebHookUrl := IniRead(configIni, "UserConfig", "WebHookUrl")
WalkForwardTime := IniRead(configIni, "UserConfig", "WalkForwardTime")
WalkRightTime := IniRead(configIni, "UserConfig", "WalkRightTime")
OnStockPotionPixel := IniRead(configIni, "Pixels", "OnStockPotionPixel")
LeaderboardPixel := IniRead(configIni, "Pixels", "LeaderboardPixel")

GetCoord(section, key) {
    try val := IniRead(configIni, section, key)
    catch {
        MsgBox "Missing INI value: " section " -> " key
        ExitApp
    }

    parts := StrSplit(val, ",")
    return [Trim(parts[1]) + 0, Trim(parts[2]) + 0]
}

CoordsMap := Map()
CoordsMap["BuyButton"] := GetCoord("Coords", "BuyButton")
CoordsMap["BuyPotionButton"] := GetCoord("Coords", "BuyPotionButton")
CoordsMap["ExitWitchButton"] := GetCoord("Coords", "ExitWitchButton")
CoordsMap["ThrowWellButton"] := GetCoord("Coords", "ThrowWellButton")
CoordsMap["BackpackButton"] := GetCoord("Coords", "BackpackButton")
CoordsMap["BackpackSearch"] := GetCoord("Coords", "BackpackSearch")
CoordsMap["FirstItemBackpack"] := GetCoord("Coords", "FirstItemBackpack")
CoordsMap["LeaderboardTab"] := GetCoord("Coords", "LeaderboardTab")
   
; For Splash Screen, will be commented out for now for faster debugging
; maxW := A_ScreenWidth * 0.5
; maxH := A_ScreenHeight * 0.5

; w := Round(Min(maxW, maxH * (16/9)))
; h := Round(w * 9 / 16)

; SplashGui := Gui("+AlwaysOnTop -Caption +ToolWindow", "Splash")
; SplashGui.Add("Picture", Format("x0 y0 w{} h{}", w, h), SplashImage)
; SplashGui.Show(Format("w{} h{} Center", w, h))
; Sleep(3000)

; hWnd := SplashGui.Hwnd
; Loop 30 {
;     level := Round(255 - A_Index * 8.5)
;     WinSetTransparent(level, "ahk_id " hWnd)
;     Sleep(15)
; }
; SplashGui.Destroy()

global MainGui := Gui("+Owner", "Superforest Macro v1.2")
Tabs := MainGui.Add("Tab3", , ["Config", "Coords", "Pixels", "Updates", "Info"])

Tabs.UseTab(1)
MainGui.Add("Text", "x20 y40", "Private Server Deeplink")
DeepLinkControl := MainGui.Add("Edit", "x175 yp-3 h20 w150 -VScroll", DeepLink)

MainGui.Add("Text", "x20 y70", "Delay Multiplier")
DelayMultiplierControl := MainGui.Add("Edit", "x175 yp-3 h20 w150 -VScroll +Right", DelayMultiplier)

MainGui.Add("Text", "x20 y100", "Reconnection Delay (sec)")
ReconnectionDelayControl := MainGui.Add("Edit", "x175 yp-3 h20 w150 -VScroll +Right", ReconnectionDelay)

MainGui.Add("Text", "x20 y130", "Discord Webhook URL")
WebHookUrlControl := MainGui.Add("Edit", "x175 yp-3 h20 w150 -VScroll +Right", WebHookUrl)

MainGui.Add("Button", "x20 y235 w305 h30", "Run Macro (F5 to pause, F7 to stop)").OnEvent("Click", RunMacro)
MainGui.Add("Button", "x20 y270 w305 h30", "Save Settings").OnEvent("Click", SaveSettings)
MainGui.Add("Text", "x20 y305", "Save the config after changing settings before running the macro.")

Tabs.UseTab(2)
MainGui.Add("Text", "x20 y40 w305 +Center", "Edit macro button coordinates. Save after changes.")
MainGui.Add("Text", "x20 y60 w305 +Center", "Use 'Window Spy'  from AutoHotkey to get client coords.")

MainGui.Add("Text", "x20 y90", "Buy Button:")
MainGui.Add("Text", "x170 y90", "X:")
BuyButtonX := MainGui.Add("Edit", "x190 yp-3 w50 +Right", CoordsMap["BuyButton"][1])

MainGui.Add("Text", "x260 y90", "Y:")
BuyButtonY := MainGui.Add("Edit", "x280 yp-3 w50 +Right", CoordsMap["BuyButton"][2])

MainGui.Add("Text", "x20 y120", "Buy Potion Button:")
MainGui.Add("Text", "x170 y120", "X:")
BuyPotionButtonX := MainGui.Add("Edit", "x190 yp-3 w50 +Right", CoordsMap["BuyPotionButton"][1])

MainGui.Add("Text", "x260 y120", "Y:")
BuyPotionButtonY := MainGui.Add("Edit", "x280 yp-3 w50 +Right", CoordsMap["BuyPotionButton"][2])

MainGui.Add("Text", "x20 y150", "Exit Witch Button:")
MainGui.Add("Text", "x170 y150", "X:")
ExitWitchButtonX := MainGui.Add("Edit", "x190 yp-3 w50 +Right", CoordsMap["ExitWitchButton"][1])

MainGui.Add("Text", "x260 y150", "Y:")
ExitWitchButtonY := MainGui.Add("Edit", "x280 yp-3 w50 +Right", CoordsMap["ExitWitchButton"][2])

MainGui.Add("Text", "x20 y180", "Throw Well Button:")
MainGui.Add("Text", "x170 y180", "X:")
ThrowWellButtonX := MainGui.Add("Edit", "x190 yp-3 w50 +Right", CoordsMap["ThrowWellButton"][1])

MainGui.Add("Text", "x260 y180", "Y:")
ThrowWellButtonY := MainGui.Add("Edit", "x280 yp-3 w50 +Right", CoordsMap["ThrowWellButton"][2])

MainGui.Add("Text", "x20 y210", "Backpack Button:")
MainGui.Add("Text", "x170 y210", "X:")
BackpackButtonX := MainGui.Add("Edit", "x190 yp-3 w50 +Right", CoordsMap["BackpackButton"][1])

MainGui.Add("Text", "x260 y210", "Y:")
BackpackButtonY := MainGui.Add("Edit", "x280 yp-3 w50 +Right", CoordsMap["BackpackButton"][2])

MainGui.Add("Text", "x20 y240", "Backpack Search:")
MainGui.Add("Text", "x170 y240", "X:")
BackpackSearchX := MainGui.Add("Edit", "x190 yp-3 w50 +Right", CoordsMap["BackpackSearch"][1])

MainGui.Add("Text", "x260 y240", "Y:")
BackpackSearchY := MainGui.Add("Edit", "x280 yp-3 w50 +Right", CoordsMap["BackpackSearch"][2])

MainGui.Add("Text", "x20 y270", "First Item Backpack:")
MainGui.Add("Text", "x170 y270", "X:")
FirstItemBackpackX := MainGui.Add("Edit", "x190 yp-3 w50 +Right", CoordsMap["FirstItemBackpack"][1])

MainGui.Add("Text", "x260 y270", "Y:")
FirstItemBackpackY := MainGui.Add("Edit", "x280 yp-3 w50 +Right", CoordsMap["FirstItemBackpack"][2])

MainGui.Add("Text", "x20 y300", "Leaderboard Tab:")
MainGui.Add("Text", "x170 y300", "X:")
LeaderboardTabX := MainGui.Add("Edit", "x190 yp-3 w50 +Right", CoordsMap["LeaderboardTab"][1])

MainGui.Add("Text", "x260 y300", "Y:")
LeaderboardTabY := MainGui.Add("Edit", "x280 yp-3 w50 +Right", CoordsMap["LeaderboardTab"][2])

Tabs.UseTab(3)
MainGui.Add("Text", "x20 y40 w305 +Center", "Edit macro pixel hexcodes. Save after changes.")
MainGui.Add("Text", "x20 y60 w305 +Center", "Use 'Window Spy'  from AutoHotkey to get color hexcodes.")

MainGui.Add("Text", "x20 y90", "On Stock Potion Pixel:")
MainGui.Add("Text", "x210 y90", "Hexcode:")
OnStockPixel := MainGui.Add("Edit", "x270 yp-3 w60 +Right", OnStockPotionPixel)

MainGui.Add("Text", "x20 y120", "Leaderboard Pixel:")
MainGui.Add("Text", "x210 y120", "Hexcode:")
LbPixel := MainGui.Add("Edit", "x270 yp-3 w60 +Right", LeaderboardPixel)

Tabs.UseTab(4)
MainGui.Add("Text", "x20 y40", "Updates")
MainGui.Add("Text", "x20 y60", "v1.0 (2/15/26)")
MainGui.Add("Text", "x20 y80", "- Initial release with core functionality.")
MainGui.Add("Text", "x20 y110", "v1.1 (2/17/26)")
MainGui.Add("Text", "x20 y130", "- Discord Webhook integration for notifications.")
MainGui.Add("Text", "x20 y150", "- Improved error handling and logging.")
MainGui.Add("Text", "x20 y180", "v1.2 (3/8/26)")
MainGui.Add("Text", "x20 y200", "- Implemented reconnection logic")

MainGui.Add("Text", "x20 y300 +Right", "Made with love from allyqnts ❤️")

Tabs.UseTab(5)
MainGui.Add("Text", "x20 y40 w305 +Center", "Welcome to Superforest Macro!")
MainGui.Add("Text", "x20 y60 w305 +Center", "Automation macro for potion farming and reconnection handling.")

MainGui.Add("Text", "x20 y90", "Core Funtions:")
MainGui.Add("Text", "x20 y110", "- Detects environment using OCR")
MainGui.Add("Text", "x20 y130", "- Moves character automatically")
MainGui.Add("Text", "x20 y150", "- Buys and uses potions in sequence")
MainGui.Add("Text", "x20 y170", "- Rejoins server if required using deep link")

MainGui.Add("Text", "x20 y200", "Important:")
MainGui.Add("Text", "x20 y220", "Always save config before running.")
MainGui.Add("Text", "x20 y240", "Do not interact with Roblox while macro is running.")

SaveSettings(*) {
    global MainGui, configIni
    MainGui.Submit()

    IniWrite(DeepLinkControl.Text, configIni, "UserConfig", "DeepLink")
    IniWrite(DelayMultiplierControl.Text, configIni, "UserConfig", "DelayMultiplier")
    IniWrite(ReconnectionDelayControl.Text, configIni, "UserConfig", "ReconnectionDelay")
    IniWrite(WebHookUrlControl.Text, configIni, "UserConfig", "WebHookUrl")

    IniWrite(BuyButtonX.Text "," BuyButtonY.Text, configIni, "Coords", "BuyButton")
    IniWrite(BuyPotionButtonX.Text "," BuyPotionButtonY.Text, configIni, "Coords", "BuyPotionButton")
    IniWrite(ExitWitchButtonX.Text "," ExitWitchButtonY.Text, configIni, "Coords", "ExitWitchButton")
    IniWrite(ThrowWellButtonX.Text "," ThrowWellButtonY.Text, configIni, "Coords", "ThrowWellButton")
    IniWrite(BackpackButtonX.Text "," BackpackButtonY.Text, configIni, "Coords", "BackpackButton")
    IniWrite(BackpackSearchX.Text "," BackpackSearchY.Text, configIni, "Coords", "BackpackSearch")
    IniWrite(FirstItemBackpackX.Text "," FirstItemBackpackY.Text, configIni, "Coords", "FirstItemBackpack")
    IniWrite(LeaderboardTabX.Text "," LeaderboardTabY.Text, configIni, "Coords", "LeaderboardTab")

    IniWrite(OnStockPixel.Text, configIni, "Pixels", "OnStockPotionPixel")
    IniWrite(LbPixel.Text, configIni, "Pixels", "LeaderboardPixel")

    MsgBox "Settings saved successfully!"
    ExitApp
}

MainGui.Show()
SendDiscordMessage("Macro started.")
MainGui.OnEvent("Close", (*) => ExitApp())

RunMacro(*) {
    global MainGui

    MainGui.Destroy()
    BlockInput True
    CheckRobloxWindow()
}

CheckRobloxWindow() {
    global potionSlot, deepLinkRun, DeepLink, DelayMultiplier, ReconnectionDelay, CoordsMap, hwnd, rblxWindows

    Loop {
        if (rblxWindows.Length = 0) {
            MsgBox "No Roblox windows found."
            ExitApp
        } else if (rblxWindows.Length > 1) {
            MsgBox "Multiple Roblox windows found. Please close other Roblox windows."
            ExitApp
        }

        hwnd := rblxWindows[1]
        WinActivate(hwnd)
        WinWaitActive(hwnd)
        WinRestore(hwnd)
        WinMove(, , 800, 600, hwnd)
        WinSetTitle("Roblox window activated and resized.", "ahk_id " hwnd)
        SendDiscordMessage("Roblox window activated and resized.")
        Sleep (1000 * DelayMultiplier)
        RemoveLeaderboard()
        Sleep (1000 * DelayMultiplier)
        RemoveOtherItems()
        Sleep (1000 * DelayMultiplier)
        WinSetTitle("Clicking buy button.", "ahk_id " hwnd)
        SendEvent "{Click, " CoordsMap["BuyButton"][1] ", " CoordsMap["BuyButton"][2] "}"
        Sleep (1000 * DelayMultiplier)
        BlackBorderOverlay()
        Sleep (1000 * DelayMultiplier)

        WinGetPos(&x, &y, &w, &h, "ahk_id " hwnd)
        findCharFacing := OCR.FromRect(x, y, w, h, { scale: 4 })
        fullText := findCharFacing.Text

        for line in findCharFacing.Lines {
            line.Highlight(-1000)
        }

        words := ["Rare", "Boosts", "Server", "Shrine", "Keepers", "Top"]

        found := false
        for word in words {
            if InStr(fullText, word) {
                found := true
                break
            }
        }

        if found {
            WinSetTitle("Word found in window, going to Potions.", "ahk_id " hwnd)
            SendDiscordMessage("Word found in window, going to Potions.")
            DisableBlackBorderOverlay()
            Sleep (1500 * DelayMultiplier)
            MoveChars()

            loop {
                reconnectSuccess := ReconnectionPrompt()

                if (reconnectSuccess) {
                    CheckRobloxWindow()
                    return
                }

                BuyPotions()
                UsePotions(potionSlot)

                potionSlot++
                if (potionSlot > 9) {
                    MovePotions()
                    potionSlot := 0
                }

                Sleep (1000 * DelayMultiplier)
            }

            deepLinkRun := false
            break
        }

        WinSetTitle("Word not found in window, Turning character.", "ahk_id " hwnd)
        SendDiscordMessage("Word not found in window, Turning character.")
        Sleep (1000 * DelayMultiplier)
        TurnCharacter180()
        Sleep (1000 * DelayMultiplier)
        BlackBorderOverlay()
        Sleep (1000 * DelayMultiplier)

        findCharFacing := OCR.FromRect(x, y, w, h, { scale: 4 })
        fullText := findCharFacing.Text

        for line in findCharFacing.Lines {
            line.Highlight(-1000)
        }

        foundAfterTurn := false
        for word in words {
            if InStr(fullText, word) {
                foundAfterTurn := true
                break
            }
        }

        if foundAfterTurn {
            WinSetTitle("Word found after turn, going to Potions.", "ahk_id " hwnd)
            SendDiscordMessage("Word found after turn, going to Potions.")
            DisableBlackBorderOverlay()
            Sleep (1500 * DelayMultiplier)
            MoveChars()

            loop {
                reconnectSuccess := ReconnectionPrompt()

                if (reconnectSuccess) {
                    CheckRobloxWindow()
                    return
                }

                BuyPotions()
                UsePotions(potionSlot)

                potionSlot++
                if (potionSlot > 9) {
                    MovePotions()
                    potionSlot := 0
                }

                Sleep (1000 * DelayMultiplier)
            }

            deepLinkRun := false
            break
        }

        if !foundAfterTurn && !deepLinkRun {
            DisableBlackBorderOverlay()
            WinSetTitle("Word not found after turn, rejoining via deeplink.", "ahk_id " hwnd)
            SendDiscordMessage("Word not found after turn, rejoining via deeplink.")

            if (DeepLink = "") {
                Run ("roblox://placeID=81318904502331")
            } else {
                 Run (DeepLink)
            }

            deepLinkRun := true
            totalWait := ReconnectionDelay
            loop totalWait {
                WinSetTitle("Rejoining via deeplink, " (totalWait - A_Index + 1) "s left", "ahk_id " hwnd)
                Sleep (1000)
            }

            deepLinkRun := false
        }

        Sleep (2000 * DelayMultiplier)
    }
}

RemoveLeaderboard() {
    global CoordsMap, hwnd, LeaderboardPixel

    WinSetTitle("Checking for leaderboard.", "ahk_id " hwnd)
    Sleep (250)
    SendEvent "{Click, " CoordsMap["LeaderboardTab"][1] ", " CoordsMap["LeaderboardTab"][2] "}"
    Sleep (500)

    MouseGetPos &X, &Y
    IfLeaderboard := PixelGetColor(X, Y)

    if (IfLeaderboard == LeaderboardPixel) {
        WinSetTitle("Leaderboard detected, closing leaderboard.", "ahk_id " hwnd)
        SendEvent "{Tab}"
        Sleep (500)
    } else {
        WinSetTitle("No leaderboard detected.", "ahk_id " hwnd)
        Sleep (500)
    }
}

BlackBorderOverlay() {
    global hwnd, TopGui, BottomGui, LeftGui, RightGui

    DisableBlackBorderOverlay()
    WinActivate(hwnd)
    WinGetPos(&x, &y, &w, &h, "ahk_id " hwnd)

    TopGui := Gui("-Caption +ToolWindow +AlwaysOnTop")
    TopGui.BackColor := "Black"
    TopGui.Show("x" x " y" y " w" w " h" 85 " NoActivate")

    BottomGui := Gui("-Caption +ToolWindow +AlwaysOnTop")
    BottomGui.BackColor := "Black"
    BottomGui.Show("x" x " y" (y + h - 100) " w" w " h" 100 " NoActivate")

    LeftGui := Gui("-Caption +ToolWindow +AlwaysOnTop")
    LeftGui.BackColor := "Black"
    LeftGui.Show("x" x " y" (y + 60) " w" 95 " h" (h - 370)  " NoActivate")

    RightGui := Gui("-Caption +ToolWindow +AlwaysOnTop")
    RightGui.BackColor := "Black"
    RightGui.Show("x" (x + w - 110) " y" (y + 200) " w" 110 " h" (h - 400) " NoActivate")

    WinActivate(hwnd)
}

DisableBlackBorderOverlay() {
    global TopGui, BottomGui, LeftGui, RightGui, hwnd

    for gui in [TopGui, BottomGui, LeftGui, RightGui] {
        if IsObject(gui)
            gui.Destroy()
    }

    TopGui := BottomGui := LeftGui := RightGui := ""
    WinActivate(hwnd)
}

TurnCharacter180() {
    SendInput "{Right down}"
    Sleep (1500)
    SendInput "{Right up}"
    Sleep (500)
}

RemoveOtherItems() {
    global DelayMultiplier, hwnd

    Sleep (500 * DelayMultiplier)
    SendEvent "{Click, " CoordsMap["BackpackButton"][1] ", " CoordsMap["BackpackButton"][2] "}"
    Sleep (500 * DelayMultiplier)

    startX := 110
    startY1 := 565
    endY := 490
    step := 65

    Loop 10 {
        x := startX + (A_Index - 1) * step
        WinSetTitle("Moving items to backpack… (Slot " A_Index "/10)", "ahk_id " hwnd)

        SendEvent "{Click " x " " startY1 " Down}"
        Sleep (50 * DelayMultiplier)

        SendEvent "{Click " x " " endY " Up}"
        Sleep (75 * DelayMultiplier)
    }

    Sleep (500 * DelayMultiplier)
    SendEvent "{Click, " CoordsMap["BackpackSearch"][1] ", " CoordsMap["BackpackSearch"][2] "}"
    Sleep (500 * DelayMultiplier)
    SendInput "Time Potion"
    Sleep (500 * DelayMultiplier)

    startY2 := 280

    Loop 10 {
        x := startX + (A_Index - 1) * step
        WinSetTitle("Moving potions to hotbar… (Slot " A_Index "/10)", "ahk_id " hwnd)

        SendEvent "{Click " startX " " startY2 " Down}"
        Sleep (50 * DelayMultiplier)

        SendEvent "{Click " x " " startY1 " Up}"
        Sleep (75 * DelayMultiplier)
    }

    Sleep (500 * DelayMultiplier)
    SendEvent "{Click, " CoordsMap["BackpackButton"][1] ", " CoordsMap["BackpackButton"][2] "}"
    Sleep (500 * DelayMultiplier)
}

MoveChars() {
    global WalkForwardTime, WalkRightTime, hwnd

    WinActivate(hwnd)
    WinWaitActive(hwnd)
    WinSetTitle("Moving character forward.", "ahk_id " hwnd)
    SendInput "{w down}"
    Sleep (WalkForwardTime * 1000)
    SendInput "{w up}"
    Sleep (1000)
    WinSetTitle("Moving character to the right.", "ahk_id " hwnd)
    SendInput "{d down}"
    Sleep (WalkRightTime * 1000)
    SendInput "{d up}"
    Sleep (1000)
    WinSetTitle("Facing character towards the potion shop.", "ahk_id " hwnd)
    SendInput "{Right down}"
    Sleep (750)
    SendInput "{Right up}"
    Sleep (500)
}

BuyPotions() {
    global CoordsMap, hwnd, OnStockPotionPixel

    consecutiveClicks := 0
    maxClicks := 4

    SendEvent "{Click, " CoordsMap["BuyPotionButton"][1] ", " CoordsMap["BuyPotionButton"][2] ", Right}"

    Loop {
        WinSetTitle("Checking if potion is in stock.", "ahk_id " hwnd)
        MouseGetPos &X, &Y
        IfPotionOnStock := PixelGetColor(X, Y)

        if (IfPotionOnStock == OnStockPotionPixel && consecutiveClicks < maxClicks) {
            WinSetTitle("Potion is in stock, buying potion.", "ahk_id " hwnd)
            SendEvent "{Click, " CoordsMap["BuyPotionButton"][1] ", " CoordsMap["BuyPotionButton"][2] "}"
            consecutiveClicks++
            Sleep (1000)
        } else {
            if (consecutiveClicks == 0) {
                WinSetTitle("Potion is not in stock.", "ahk_id " hwnd)
            } else {
                WinSetTitle("Reached max potion buy limit or stock unavailable.", "ahk_id " hwnd)
            }
            Sleep (500)
            break
        }
    }
}

UsePotions(slot) {
    global CoordsMap, hwnd

    WinSetTitle("Using potion in slot " slot ".", "ahk_id " hwnd)
    SendEvent "{Click, " CoordsMap["ExitWitchButton"][1] ", " CoordsMap["ExitWitchButton"][2] "}"
    Sleep (500)
    Send "{" slot "}"
    Sleep (500)
    SendEvent "{Click, " CoordsMap["ThrowWellButton"][1] ", " CoordsMap["ThrowWellButton"][2] "}"
    Sleep (500)
}

MovePotions() {
    global CoordsMap, hwnd

    WinSetTitle("Moving potions to backpack.", "ahk_id " hwnd)
    SendEvent "{Click, " CoordsMap["BackpackButton"][1] ", " CoordsMap["BackpackButton"][2] "}"
    Sleep (500)
    SendEvent "{Click, " CoordsMap["BackpackSearch"][1] ", " CoordsMap["BackpackSearch"][2] "}"
    Sleep (500)
    SendInput "Time Potion"
    Sleep (500)
    loop 20 {
        SendEvent "{Click, " CoordsMap["FirstItemBackpack"][1] ", " CoordsMap["FirstItemBackpack"][2] "}"
        Sleep (250)
    }
    SendEvent "{Click, " CoordsMap["BackpackButton"][1] ", " CoordsMap["BackpackButton"][2] "}"
    Sleep (500)
}

ReconnectionPrompt() {
    global CoordsMap, hwnd, ReconnectionDelay, DeepLink, deepLinkRun

    consecutiveNoPrompt := 0
    requiredNoPrompt := 5
    reconnectSuccess := false

    WinSetTitle("Opening Witch's Shop.", "ahk_id " hwnd)
    Sleep (250)
    SendInput "{e down}"
    Sleep (2000)
    SendInput "{e up}"
    Sleep (1500)

    loop {
        WinActivate(hwnd)
        WinWaitActive(hwnd)
        WinSetTitle("Checking for reconnection prompt.", "ahk_id " hwnd)

        isBoostTabOn := OCR.FromWindow(hwnd, { scale: 4 })

        if (InStr(isBoostTabOn.Text, "Boosts", false)) {
            WinSetTitle("Boosts tab detected.", "ahk_id " hwnd)
            Sleep (1000)
            break
        } else {
            WinSetTitle("Boosts tab not detected, rejoining via deeplink.", "ahk_id " hwnd)
            SendDiscordMessage("Boosts tab not detected, rejoining via deeplink.")
            Sleep (1000)
            Run(DeepLink)
            deepLinkRun := true
            reconnectSuccess := true

            totalWait := ReconnectionDelay
            loop totalWait {
                WinSetTitle("Rejoining via deeplink, " (totalWait - A_Index + 1) "s left", "ahk_id " hwnd)
                Sleep (1000)
            }

            deepLinkRun := false
            consecutiveNoPrompt := 0
        }

        Sleep (1000)
        isDisconnected := OCR.FromWindow(hwnd, { scale: 4 })

        if (InStr(isDisconnected.Text, "Please check your internet connection", false) || InStr(isDisconnected.Text, "Reconnect was unsuccessful", false)) {
            WinSetTitle("Reconnection prompt detected, rejoining via deeplink.", "ahk_id " hwnd)
            SendDiscordMessage("Reconnection prompt detected, rejoining via deeplink.")
            Sleep (1000)
            Run(DeepLink)
            deepLinkRun := true
            reconnectSuccess := true

            totalWait := ReconnectionDelay
            loop totalWait {
                WinSetTitle("Rejoining via deeplink, " (totalWait - A_Index + 1) "s left", "ahk_id " hwnd)
                Sleep (1000)
            }

            deepLinkRun := false
            consecutiveNoPrompt := 0
        } else {
            consecutiveNoPrompt++
            remaining := requiredNoPrompt - consecutiveNoPrompt
            if (remaining > 0) {
                WinSetTitle("No prompt detected. Confirming in " remaining " checks...", "ahk_id " hwnd)
            } else {
                break
            }
        }

        Sleep (500)
    }

    return reconnectSuccess
}

SendDiscordMessage(message) {
    global WebHookUrl, discordQueue, discordWorkerRunning

    if !WebHookUrl {
        return  
    }

    time := FormatTime(, "hh:mm:ss tt")
    formatted := time . " - " . message

    discordQueue.Push(formatted)

    if !discordWorkerRunning {
        discordWorkerRunning := true
        SetTimer(DiscordWorker, 1000)
    }
}

DiscordWorker() {
    global configIni, WebHookUrl, discordQueue, discordWorkerRunning

    if (DiscordQueue.Length = 0) {
        DiscordWorkerRunning := false
        SetTimer(DiscordWorker, 0)
        return
    }

    message := DiscordQueue[1]
    payload := JSON.stringify({ content: message })

    try {
        Http := ComObject("WinHttp.WinHttpRequest.5.1")
        Http.Open("POST", WebHookUrl, false)
        Http.SetTimeouts(5000, 5000, 5000, 5000)
        Http.SetRequestHeader("Content-Type", "application/json")
        Http.Send(payload)

        if (Http.Status = 204 || Http.Status = 200) {
            DiscordQueue.RemoveAt(1)
        }
    }
    catch {
        ; keep message in queue for next attempt
    }
}

PauseMacro() {
    isPaused := A_IsPaused

    if !isPaused {
        BlockInput False
        Pause -1
    } else {
        Pause -1
        BlockInput True
    }
}
