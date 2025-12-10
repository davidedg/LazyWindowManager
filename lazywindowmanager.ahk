#Requires AutoHotkey v2.0
#SingleInstance Force

/*
 * Lazy Window Manager https://github.com/davidedg/LazyWindowManager
 * 
 * Provides Linux-style windows manipulation on Windows:
 * 
 * AUTHOR: Davide Del Grande https://github.com/davidedg/
 * Version: 1.0
 * 
 * 
 * PRIMARY MODES:
 * - Win + Left Click drag: Move window
 * - Win + Right Click drag: Resize window
 *   - Edge zones (outer 30%): resize from clicked edge/corner
 *   - Center zone (inner 70%): resize from all sides simultaneously (centered)
 * 
 * TRIGGER MODE (one hand operation):
 * - Middle Double-Click on window: Activates trigger mode for that window
 * - Middle Double-Click on desktop: Activates trigger mode for any window
 *   - Visual feedback: Desktop borders while active
 *   - Left/Right clicks now work as if Win key is pressed
 *   - Automatically deactivates when clicking a different window
 *   - Single middle-click to manually deactivate
 * 
 */


^!q::ExitApp  ; CTRL+ALT+Q - hard exit


; ============================================================================
; INIT / GLOBAL VARS
; ============================================================================

; Zone detection: 30% edge margin for single-side resize, 70% center for all-sides
global RESIZETHRESHOLD := 0.30

global MTriggered := False
global MTriggered_isDesktop := False
global MWinIDLast



CoordMode("Mouse", "Screen")
DoubleClickTime := DllCall("GetDoubleClickTime")
WDesktop := DllCall("User32.dll\GetDesktopWindow", "UPtr")


; ============================================================================
; HELPER FUNCTIONS
; ============================================================================

DebugLog(message) {
    OutputDebug("AHKPrj - " A_TickCount " - " message)
}

IsDesktop(winId) {
    try {
        winClass := WinGetClass("ahk_id " winId)
        return (winClass = "Progman" || winClass = "WorkerW" || winClass = "Shell_TrayWnd")
    }
    return false
}


; ============================================================================
; Draw Desktop Borders
; ============================================================================

global borderGuis := []
DrawWindowBorders(winId, color := "Red", thickness := 1) {
    global borderGuis
    try {
        RemoveWindowBorders()
        WinGetPos(&x, &y, &w, &h, "ahk_id " winId)
        borderGuis.Push(CreateBorderGui(x, y, w, thickness, color))                 ; Top
        borderGuis.Push(CreateBorderGui(x, y + h - thickness, w, thickness, color)) ; Bottom
        borderGuis.Push(CreateBorderGui(x, y, thickness, h, color))                 ; Left
        borderGuis.Push(CreateBorderGui(x + w - thickness, y, thickness, h, color)) ; Right
    }
}

CreateBorderGui(x, y, w, h, color) {
    g := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20")
    g.BackColor := color
    g.Show("NA x" x " y" y " w" w " h" h)
    return g
}

RemoveWindowBorders() {
    global borderGuis
    for gui in borderGuis {
        gui.Destroy()
    }
    borderGuis := []
}


; ============================================================================
; Middle Double Click Trigger (activates desktop borders)
; ============================================================================

MButton:: {
    global MTriggered := False
    global MTriggered_isDesktop
    global MWinIDLast
    static MWinIDPrev := 0

    RemoveWindowBorders()

    MouseGetPos(, , &MWinIDLast)
    if (MWinIDLast != MWinIDPrev) {
        MWinIDPrev := MWinIDLast
        return
    }
    if (A_TimeSincePriorHotkey < DoubleClickTime && A_ThisHotkey == A_PriorHotkey) {
        MTriggered := True
        MTriggered_isDesktop := IsDesktop(MWinIDLast)
        DrawWindowBorders(WDesktop, "c23cbb", 4)
    } else {
        MWinIDPrev := MWinIDLast
    } ; try/catch on A_TimeSincePriorHotkey is not required because of the double click requirement

    Send("{MButton Down}")
    KeyWait("MButton")
    Send("{MButton Up}")    
}


; ============================================================================
; Window Moving via Win+LeftButton or MTrigger+LeftButton
; ============================================================================

#LButton:: {
    global MTriggered := False
    RemoveWindowBorders()
    MoveWindow()
}

LButton:: {
    global MWinIDLast
    global MTriggered, MTriggered_isDesktop
    
    if (MTriggered) {
        MouseGetPos(, , &winId)
        if (winId != MWinIDLast && !MTriggered_isDesktop) {
            MTriggered := false
            RemoveWindowBorders()
        } else {
            MoveWindow()
            return
        }
    }

    RemoveWindowBorders()
    
    Send("{LButton Down}")
    KeyWait("LButton")
    Send("{LButton Up}")
}

MoveWindow() {
    MouseGetPos(&startX, &startY, &winId)
    
    ; Skip maximized/minimized windows
    try {
        winMinMax := WinGetMinMax("ahk_id " winId)
        if (winMinMax != 0)
            return
    } catch {
        return
    }
    
    ; Bring window to front before manipulation
    try WinActivate("ahk_id " winId)
    
    ; Capture initial window position as anchor point
    try {
        WinGetPos(&winX, &winY, &winW, &winH, "ahk_id " winId)
    } catch {
        return
    }
    
    ; Movement loop: calculate delta from initial click position
    SetWinDelay(-1)
    while GetKeyState("LButton", "P") {
        MouseGetPos(&currentX, &currentY)
        deltaX := currentX - startX
        deltaY := currentY - startY
        
        try WinMove(winX + deltaX, winY + deltaY, , , "ahk_id " winId)
        Sleep(10)
    }
}


; ============================================================================
; Window Resizing via Win+RightButton or MTrigger+RightButton
; ============================================================================

#RButton:: {
    global MTriggered := False
    RemoveWindowBorders()
    ResizeWindow()
}

RButton:: {
    global MWinIDLast
    global MTriggered, MTriggered_isDesktop
    
    if (MTriggered) {
        MouseGetPos(, , &winId)
        if (winId != MWinIDLast && !MTriggered_isDesktop) {
            MTriggered := false
        } else {
            ResizeWindow()
            return
        }
    }

    RemoveWindowBorders()
    
    Send("{RButton Down}")
    KeyWait("RButton")
    Send("{RButton Up}")
}

ResizeWindow() {
    global RESIZETHRESHOLD

    MouseGetPos(&startX, &startY, &winId)
    
    ; Skip maximized/minimized windows
    try {
        winMinMax := WinGetMinMax("ahk_id " winId)
        if (winMinMax != 0)
            return
    } catch {
        return
    }
    
   
    ; Bring window to front before manipulation
    try WinActivate("ahk_id " winId)
    
    ; Capture initial window position as anchor point
    try {
        WinGetPos(&winX, &winY, &winW, &winH, "ahk_id " winId)
    } catch {
        return
    }
    
    ; Convert absolute mouse position to relative position within window (0.0 to 1.0)
    relMouseX := startX - winX
    relMouseY := startY - winY
    
    relX := relMouseX / winW
    relY := relMouseY / winH
    

    resizeLeft := false
    resizeTop := false
    resizeRight := false
    resizeBottom := false
    resizeAll := false
    
    ; Center zone: resize from all edges simultaneously (keeps window centered)
    if (relX > RESIZETHRESHOLD && relX < (1 - RESIZETHRESHOLD) && 
        relY > RESIZETHRESHOLD && relY < (1 - RESIZETHRESHOLD)) {
        resizeAll := true
    } else {
        ; Edge/corner zones: resize from specific sides
        if (relX <= RESIZETHRESHOLD)
            resizeLeft := true
        if (relX >= (1 - RESIZETHRESHOLD))
            resizeRight := true
        if (relY <= RESIZETHRESHOLD)
            resizeTop := true
        if (relY >= (1 - RESIZETHRESHOLD))
            resizeBottom := true
    }
    
    ; Resize loop: use incremental deltas to avoid jitter
    SetWinDelay(-1)
    lastX := startX
    lastY := startY
    
    while GetKeyState("RButton", "P") {
        MouseGetPos(&currentX, &currentY)
        deltaX := currentX - lastX
        deltaY := currentY - lastY
        lastX := currentX
        lastY := currentY
        
        
        newX := winX
        newY := winY
        newW := winW
        newH := winH
        
        if (resizeAll) {
            ; Center-resize: split delta equally to maintain window center position
            halfDeltaX := deltaX / 2
            halfDeltaY := deltaY / 2
            
            newX := winX - halfDeltaX
            newY := winY - halfDeltaY
            newW := winW + deltaX
            newH := winH + deltaY
        } else {
            ; Edge-resize: adjust position when resizing from top/left
            if (resizeLeft) {
                newX := winX + deltaX
                newW := winW - deltaX
            }
            if (resizeRight) {
                newW := winW + deltaX
            }
            if (resizeTop) {
                newY := winY + deltaY
                newH := winH - deltaY
            }
            if (resizeBottom) {
                newH := winH + deltaY
            }
        }
        
        ; Enforce minimum window size to prevent collapse
        minSize := 100
        if (newW < minSize)
            newW := minSize
        if (newH < minSize)
            newH := minSize
        
        ; Apply and update tracking variables for next iteration
        try {
            WinMove(newX, newY, newW, newH, "ahk_id " winId)
            winX := newX
            winY := newY
            winW := newW
            winH := newH
        }
        
        Sleep(10)
    }
}
