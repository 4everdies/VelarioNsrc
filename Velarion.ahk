; <COMPILER: v1.1.37.02>
A_MaxHotkeysPerInterval := 99000000
#NoTrayIcon
CurrentVersion := "1.41"
VersionCheckURL := "127.0.0.1"

if !CheckVersion(CurrentVersion, VersionCheckURL) {
MsgBox("You are using an old version of VelarioN. Please update it.")
ExitApp
}
CheckTempFile() {
    return true
}
CheckTempFile()
CheckVersion(CurrentVersion, VersionURL) {
try {
http := ComObject("WinHttp.WinHttpRequest.5.1")
http.SetTimeouts(3000, 3000, 5000, 8000)
http.Open("GET", VersionURL, false)
http.SetRequestHeader("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")
http.SetRequestHeader("Accept", "text/plain, */*")
http.Send()
if (http.Status = 200) {
LatestVersion := Trim(http.ResponseText)
LatestVersion := RegExReplace(LatestVersion, "[^\d\.]", "")
if (LatestVersion != "" && RegExMatch(LatestVersion, "^\d+\.\d+$")) {
return CompareVersions(CurrentVersion, LatestVersion) >= 0
}
}
throw Error("HTTP Status: " . http.Status)
} catch as err {
result := MsgBox("Não foi possivel verificar a versão mais recente.`n`nContinuar mesmo assim?", "Aviso de Versão", "YesNo Icon?")
return result == "Yes"
}
}
CompareVersions(v1, v2) {
v1_str := String(v1)
v2_str := String(v2)
v1_parts := StrSplit(v1_str, ".")
v2_parts := StrSplit(v2_str, ".")
maxLength := Max(v1_parts.Length, v2_parts.Length)
loop maxLength {
n1 := v1_parts.Has(A_Index) ? Number(v1_parts[A_Index]) : 0
n2 := v2_parts.Has(A_Index) ? Number(v2_parts[A_Index]) : 0
if (n1 != n2)
return n1 > n2 ? 1 : -1
}
return 0
}
global recordingInProgress := false
global playbackInProgress := false
global recordedActions := []
global macroFolder := "C:\ProgramData" "\SystemInfo"
global activeConfigs := Map("z", "", "x", "", "RAlt", "")
global macroStorage := Map("z", [], "x", [], "RAlt", [])
global lastRecording := []
global exitFlag := false
global startTime := 0
global keyStates := Map()
global excludedKeys := Map("F8",1, "F9",1, "Home",1)
global speedSlider, speedText
global zConfig := ""
global xConfig := ""
global raltConfig := ""
global statusText := ""
global activeConfigs := Map("z", "", "x", "", "RAlt", "")
global macroHotkeys := Map("z", "", "x", "", "RAlt", "")
global previousMacroHotkeys := Map("z", "", "x", "", "RAlt", "")
global mouseButtonLabels := Map("XButton1", "Mouse 4", "XButton2", "Mouse 5")
global lastMouseButtonPressed := ""
global lastPressedButton := ""
global customCheckboxes := Map()
global animationSteps := 10
global animationSpeed := 20
global mainGui, tabControl
global targetWindowTitle := ""
global targetWindowEdit := ""
global windowSelectorBtn := ""
global windowEnabled := false
global windowEnabledCheckbox := ""
global g := {
bg: "101010",
text: "FFFFFF",
accent: "015eff",
secondary: "1E1E1E",
radius: 10
}
global clicking := false
global rightClicking := false
global baseDelay := 100
global variationMin := 5
global variationMax := 15
global startupDelay := 150
global fastPlaceEnabled := false
global activeHotkeyControl := ""
global activeHotkeyType := ""
global hotkeySelectionActive := false
global toggleCheckbox, fastPlaceCheckbox, hotkeyEdit, fastPlaceHotkeyEdit
global cpsSlider, cpsValue, varMinSlider, varMaxSlider, varValue
global delimitMovementCheck
SetCursorPos(x, y) {
DllCall("user32.dll\SetCursorPos", "int", x, "int", y)
}
GetCursorPos() {
pt := Buffer(8, 0)
DllCall("user32\GetCursorPos", "ptr", pt)
return [NumGet(pt, 0, "int"), NumGet(pt, 4, "int")]
}
if !DirExist(macroFolder)
DirCreate(macroFolder)
class CustomSlider {
__New(gui, x, y, w, min, max, value, callback := "", valueLabel := "") {
this.gui := gui
this.x := x
this.y := y
this.width := w
this.min := min
this.max := max
this.value := value
this.isDragging := false
this.callback := callback
this.canvas := gui.Add("Text", "x" x " y" y " w" w " h8 Background0x1E1E1E")
this.clickArea := gui.Add("Text", "x" x " y" (y-4) " w" w " h16 BackgroundTrans")
this.clickArea.OnEvent("Click", this.HandleClick.Bind(this))
if (valueLabel != "") {
this.valueLabel := valueLabel
}
this.UpdateValue(value)
}
Draw() {
hdc := DllCall("user32\GetDC", "Ptr", this.canvas.Hwnd, "Ptr")
hBrushBg := DllCall("gdi32\CreateSolidBrush", "UInt", 0x1E1E1E, "Ptr")
hOldBrush := DllCall("gdi32\SelectObject", "Ptr", hdc, "Ptr", hBrushBg)
DllCall("gdi32\Rectangle", "Ptr", hdc, "Int", 0, "Int", 0, "Int", this.width, "Int", 8)
percentage := (this.value - this.min) / (this.max - this.min)
fillWidth := Round(this.width * percentage)
thumbX := Round((this.width - 3) * percentage)
hBrushTrack := DllCall("gdi32\CreateSolidBrush", "UInt", 0x222222, "Ptr")
DllCall("gdi32\SelectObject", "Ptr", hdc, "Ptr", hBrushTrack)
DllCall("gdi32\RoundRect", "Ptr", hdc, "Int", 0, "Int", 0, "Int", this.width, "Int", 8, "Int", 8, "Int", 8)
if (fillWidth > 0) {
hBrushFill := DllCall("gdi32\CreateSolidBrush", "UInt", 0xC2670B, "Ptr")
DllCall("gdi32\SelectObject", "Ptr", hdc, "Ptr", hBrushFill)
DllCall("gdi32\RoundRect", "Ptr", hdc, "Int", 0, "Int", 0, "Int", fillWidth, "Int", 8, "Int", 8, "Int", 8)
DllCall("gdi32\DeleteObject", "Ptr", hBrushFill)
}
hBrushThumb := DllCall("gdi32\CreateSolidBrush", "UInt", 0xFFFFFF, "Ptr")
DllCall("gdi32\SelectObject", "Ptr", hdc, "Ptr", hBrushThumb)
DllCall("gdi32\RoundRect", "Ptr", hdc, "Int", thumbX, "Int", 0, "Int", thumbX + 3, "Int", 8, "Int", 4, "Int", 4)
DllCall("gdi32\DeleteObject", "Ptr", hBrushBg)
DllCall("gdi32\DeleteObject", "Ptr", hBrushTrack)
DllCall("gdi32\DeleteObject", "Ptr", hBrushThumb)
DllCall("user32\ReleaseDC", "Ptr", this.canvas.Hwnd, "Ptr", hdc)
}
UpdateValue(newValue) {
this.value := Integer(Max(this.min, Min(this.max, newValue)))
if (HasProp(this, "valueLabel") && this.valueLabel) {
this.valueLabel.Text := Format("{:.0f}", this.value)
}
this.Draw()
if (this.callback != "" && IsObject(this.callback)) {
this.callback.Call(this.value)
}
}
HandleClick(*) {
CoordMode("Mouse", "Client")
MouseGetPos(&mouseX, &mouseY)
relX := mouseX - this.x
relX := Max(0, Min(this.width, relX))
percentage := relX / this.width
newValue := Integer(this.min + (this.max - this.min) * percentage)
this.UpdateValue(newValue)
this.isDragging := true
SetTimer(this.DragTimer.Bind(this), 16)
}
DragTimer() {
if (!GetKeyState("LButton", "P")) {
this.isDragging := false
SetTimer(this.DragTimer.Bind(this), 0)
return
}
if (this.isDragging) {
CoordMode("Mouse", "Client")
MouseGetPos(&mouseX, &mouseY)
relX := mouseX - this.x
relX := Max(0, Min(this.width, relX))
percentage := relX / this.width
newValue := Integer(this.min + (this.max - this.min) * percentage)
this.UpdateValue(newValue)
}
}
}
ApplyButtonRoundedCorners(control, width, height) {
hRgn := DllCall("CreateRoundRectRgn", "int", 0, "int", 0, "int", width, "int", height, "int", 5, "int", 5, "ptr")
DllCall("SetWindowRgn", "ptr", control.Hwnd, "ptr", hRgn, "int", 1)
}
CreateStyledButton(gui, x, y, w, h, text, callback) {
btnBg := gui.Add("Text", "x" x " y" y " w" w " h" h " Background4285F4", "")
textX := x + (w - StrLen(text) * 4) // 2
textY := y + (h - 25) // 2
btnText := gui.Add("Text", "x" textX " y" textY " w200 h25 BackgroundTrans cWhite Center", text)
btnText.SetFont("s13 w500", "Segoe UI")
Sleep(10)
ApplyButtonRoundedCorners(btnBg, w, h)
btnBg.OnEvent("Click", callback)
btnText.OnEvent("Click", callback)
return {bg: btnBg, text: btnText}
}
SetRoundedCorners(hwnd, radius) {
hRgn := DllCall("CreateRoundRectRgn", "int", 0, "int", 0, "int", 620, "int", 555, "int", radius*2, "int", radius*2, "ptr")
DllCall("SetWindowRgn", "ptr", hwnd, "ptr", hRgn, "int", true)
}
CreateGUI() {
global mainGui, tabControl, toggleCheckbox, fastPlaceCheckbox, hotkeyEdit, fastPlaceHotkeyEdit
global targetWindowEdit, windowEnabledCheckbox, statusText, speedSlider, speedText
global cpsSlider, cpsValue, varMinSlider, varMaxSlider, varValue
global zConfig, xConfig, raltConfig, delimitMovementCheck
SetWinDelay(-1)
mainGui := Gui("-AlwaysOnTop -Caption -DPIScale", "")
mainGui.BackColor := g.bg
mainGui.SetFont("s10 c" g.text, "Poppins")
mainGui.Add("Text", "x20 y5 w580 h40 c015eff BackgroundTrans", "VelarioN").SetFont("s22 Bold", "Poppins")
mainGui.Add("Text", "x165 y22 w300 h20 c888888 BackgroundTrans", "cracked by fakecrime.bio/4ever").SetFont("s9", "Poppins")
closeBtn := mainGui.Add("Text", "x580 y10 w30 h40 c" g.text " Center BackgroundTrans", "X")
closeBtn.SetFont("s14 Bold", "Poppins")
closeBtn.OnEvent("Click", (*) => ExitApp())
tabControl := mainGui.Add("Tab3", "x20 y50 w580 h343 -Wrap", ["AutoClicker", "Recraft", "Misc", "Config"])
tabControl.Opt("Background" g.bg)
tabControl.OnEvent("Change", OnTabChange)
OnTabChange(*) {
if (tabControl.Value = 1) {
SetAutoClickerTabFocus()
} else if (tabControl.Value = 2) {
SetRecraftTabFocus()
}
}
CreateAutoClickerTab()
CreateRecraftTab()
CreateMiscTab()
CreateConfigTab()
CreateInstructions()
statusText := mainGui.Add("Text", "x20 y518 w580 h25 c49d949 Background101010 Center", "Ready")
statusText.SetFont("s10", "Poppins")
OnMessage(0x201, BeginDragHandler)
SetRoundedCorners(mainGui.Hwnd, g.radius)
mainGui.Show("w620 h555")
OnMessage(0x000F, WM_PAINT_Handler)
OnMessage(0x0014, WM_PAINT_Handler)
SetTimer(RefreshCheckboxes, -10)
SetTimer(RefreshSliders, -10)
tabControl.OnEvent("Change", RefreshSliders)
tabControl.OnEvent("Change", RefreshCheckboxes)
SetAutoClickerTabFocus()
}
RefreshSliders(*) {
SetTimer(RedrawAllSliders, -50)
}
RefreshCheckboxes(*) {
SetTimer(UpdateCheckboxVisuals, -50)
}
RedrawAllSliders() {
try {
if (IsObject(cpsSlider) && cpsSlider.HasMethod("Draw"))
cpsSlider.Draw()
if (IsObject(varMinSlider) && varMinSlider.HasMethod("Draw"))
varMinSlider.Draw()
if (IsObject(varMaxSlider) && varMaxSlider.HasMethod("Draw"))
varMaxSlider.Draw()
if (IsObject(speedSlider) && speedSlider.HasMethod("Draw"))
speedSlider.Draw()
} catch {
}
}
UpdateCheckboxVisuals() {
for name, data in customCheckboxes {
if (data.isChecked) {
DrawCheckbox(data.control, true, animationSteps)
} else {
DrawCheckbox(data.control, false, 0)
}
}
}
OnMessage(0x000F, WM_PAINT_Handler)
WM_PAINT_Handler(wParam, lParam, msg, hwnd) {
if (hwnd == mainGui.Hwnd) {
SetTimer(RedrawAllSliders, -10)
SetTimer(RefreshCheckboxes, -10)
}
}
DrawCheckbox(control, isChecked, frame := 0) {
hwnd := control.Hwnd
hdc := DllCall("GetDC", "Ptr", hwnd, "Ptr")
rect := Buffer(16)
NumPut("Int", 0, rect, 0)
NumPut("Int", 0, rect, 4)
NumPut("Int", 16, rect, 8)
NumPut("Int", 16, rect, 12)
bgBrush := DllCall("CreateSolidBrush", "UInt", 0x101010, "Ptr")
DllCall("FillRect", "Ptr", hdc, "Ptr", rect.Ptr, "Ptr", bgBrush)
DllCall("DeleteObject", "Ptr", bgBrush)
if (isChecked && frame > 0) {
intensity := frame / 10.0
r := Round(1 * intensity)
g := Round(94 * intensity)
b := Round(255 * intensity)
color := (b << 16) | (g << 8) | r
blueBrush := DllCall("CreateSolidBrush", "UInt", color, "Ptr")
oldBrush := DllCall("SelectObject", "Ptr", hdc, "Ptr", blueBrush, "Ptr")
transparentPen := DllCall("CreatePen", "Int", 0, "Int", 1, "UInt", color, "Ptr")
oldPen := DllCall("SelectObject", "Ptr", hdc, "Ptr", transparentPen, "Ptr")
DllCall("RoundRect", "Ptr", hdc, "Int", 0, "Int", 0, "Int", 16, "Int", 16, "Int", 3, "Int", 3)
DllCall("SelectObject", "Ptr", hdc, "Ptr", oldPen)
DllCall("SelectObject", "Ptr", hdc, "Ptr", oldBrush)
DllCall("DeleteObject", "Ptr", blueBrush)
DllCall("DeleteObject", "Ptr", transparentPen)
if (frame >= 7) {
checkPen := DllCall("CreatePen", "Int", 0, "Int", 2, "UInt", 0xFFFFFF, "Ptr")
oldPen := DllCall("SelectObject", "Ptr", hdc, "Ptr", checkPen, "Ptr")
DllCall("MoveToEx", "Ptr", hdc, "Int", 3, "Int", 8, "Ptr", 0)
DllCall("LineTo", "Ptr", hdc, "Int", 6, "Int", 11)
DllCall("LineTo", "Ptr", hdc, "Int", 13, "Int", 4)
DllCall("SelectObject", "Ptr", hdc, "Ptr", oldPen)
DllCall("DeleteObject", "Ptr", checkPen)
}
}
else if (!isChecked && frame == 0) {
borderPen := DllCall("CreatePen", "Int", 0, "Int", 1, "UInt", 0x606060, "Ptr")
oldPen := DllCall("SelectObject", "Ptr", hdc, "Ptr", borderPen, "Ptr")
oldBrush := DllCall("SelectObject", "Ptr", hdc, "Ptr", DllCall("GetStockObject", "Int", 5), "Ptr")
DllCall("RoundRect", "Ptr", hdc, "Int", 0, "Int", 0, "Int", 16, "Int", 16, "Int", 3, "Int", 3)
DllCall("SelectObject", "Ptr", hdc, "Ptr", oldPen)
DllCall("SelectObject", "Ptr", hdc, "Ptr", oldBrush)
DllCall("DeleteObject", "Ptr", borderPen)
}
DllCall("ReleaseDC", "Ptr", hwnd, "Ptr", hdc)
}
AnimateCheckbox(control, checkboxName) {
currentState := customCheckboxes[checkboxName].isChecked := !customCheckboxes[checkboxName].isChecked
if (currentState) {
Loop animationSteps {
DrawCheckbox(control, true, A_Index)
Sleep(animationSpeed)
}
} else {
Loop animationSteps {
frame := animationSteps - A_Index + 1
DrawCheckbox(control, true, frame)
Sleep(animationSpeed)
}
DrawCheckbox(control, false, 0)
}
}
CreateCustomCheckbox(gui, x, y, text, name, callback := "") {
checkbox := gui.Add("Text", "x" x " y" y " w16 h16")
checkbox.Opt("+BackgroundTrans")
textCtrl := gui.Add("Text", "x" (x+22) " y" (y-2) " w150 h20 Background" g.bg " c" g.text, text)
textCtrl.SetFont("s10", "Poppins")
customCheckboxes[name] := {
control: checkbox,
textCtrl: textCtrl,
isChecked: false,
callback: callback
}
clickArea := gui.Add("Text", "x" x " y" (y-2) " w" (22 + StrLen(text) * 6) " h20 BackgroundTrans")
clickArea.OnEvent("Click", (*) => ToggleCustomCheckbox(name))
return customCheckboxes[name]
}
ToggleCustomCheckbox(name) {
checkboxData := customCheckboxes[name]
AnimateCheckbox(checkboxData.control, name)
if (checkboxData.callback != "" && IsObject(checkboxData.callback)) {
checkboxData.callback.Call()
}
}
InitializeCustomCheckboxes() {
for name, data in customCheckboxes {
DrawCheckbox(data.control, false, 0)
}
}
UpdateCPSCallback(value) {
global baseDelay
baseDelay := 1000 / value
}
UpdateVariationMin(value) {
global variationMin, variationMax, varValue, varMaxSlider
variationMin := value
if (variationMin > variationMax) {
variationMax := variationMin
varMaxSlider.UpdateValue(variationMax)
}
varValue.Text := variationMin "%-" variationMax "%"
}
UpdateVariationMax(value) {
global variationMin, variationMax, varValue, varMinSlider
variationMax := value
if (variationMax < variationMin) {
variationMin := variationMax
varMinSlider.UpdateValue(variationMin)
}
varValue.Text := variationMin "%-" variationMax "%"
}
UpdateSpeedDisplay(value) {
global speedText
speedValue := Round(value / 10, 1)
if (IsObject(speedText))
speedText.Text := speedValue "x"
}
CreateAutoClickerTab() {
global cpsSlider, cpsValue, varMinSlider, varMaxSlider, varValue
global toggleCheckbox, fastPlaceCheckbox, hotkeyEdit, fastPlaceHotkeyEdit
tabControl.UseTab(1)
mainGui.Add("Text", "x40 y90 w540 h75 Border Background101010")
mainGui.Add("Text", "x40 y90 w540 h25 Border Background0e0e0e")
mainGui.Add("Text", "x50 y92 w200 h20 Background101010 c" g.text, "Autoclicker Activation").SetFont("s10 Bold", "Poppins")
toggleCheckbox := CreateCustomCheckbox(mainGui, 70, 130, "AutoClicker", "autoClicker", ToggleAutoClicker)
fastPlaceCheckbox := CreateCustomCheckbox(mainGui, 300, 130, "FastPlace", "fastPlace", ToggleFastPlace)
mainGui.Add("Text", "x40 y175 w540 h205 Border Background101010")
mainGui.Add("Text", "x40 y175 w540 h25 Border Background0e0e0e")
mainGui.Add("Text", "x50 y177 w200 h20 Background101010 c" g.text, "Autoclicker Settings").SetFont("s10 Bold", "Poppins")
mainGui.Add("Text", "x60 y222 Background101010 c" g.text, "CPS Base:").SetFont("s10", "Poppins")
cpsValue := mainGui.Add("Text", "x460 y208 w60 h15 Background101010 c" g.accent, "10")
cpsValue.SetFont("s10 Bold", "Poppins")
cpsSlider := CustomSlider(mainGui, 175, 229, 300, 1, 23, 10, UpdateCPSCallback.Bind(), cpsValue)
mainGui.Add("Text", "x60 y262 Background101010 c" g.text, "Click Variation:").SetFont("s10", "Poppins")
mainGui.Add("Text", "x318 y262 Background101010 c" g.text, "to").SetFont("s10", "Poppins")
varValue := mainGui.Add("Text", "x440 y248 w60 h20 Background101010 c" g.accent, variationMin "%-" variationMax "%")
varValue.SetFont("s10 Bold", "Poppins")
varMinSlider := CustomSlider(mainGui, 175, 269, 140, 1, 50, variationMin, UpdateVariationMin.Bind())
varMaxSlider := CustomSlider(mainGui, 335, 269, 140, 1, 90, variationMax, UpdateVariationMax.Bind())
mainGui.Add("Text", "x60 y301 Background101010 c" g.text, "AutoClicker Key:").SetFont("s10", "Poppins")
hotkeyEdit := mainGui.Add("Hotkey", "x175 y299 w350 h25", "")
hotkeyEdit.OnEvent("Change", (*) => UpdateAutoClickerHotkey(hotkeyEdit.Value))
mainGui.Add("Text", "x60 y340 Background101010 c" g.text, "Fast Place Key:").SetFont("s10", "Poppins")
fastPlaceHotkeyEdit := mainGui.Add("Hotkey", "x175 y338 w350 h25", "")
fastPlaceHotkeyEdit.OnEvent("Change", (*) => UpdateFastPlaceHotkey(fastPlaceHotkeyEdit.Value))
}
SetAutoClickerTabFocus() {
tabControl.Focus()
}
CreateRecraftTab() {
global speedSlider, speedText, zConfig, xConfig, raltConfig, delimitMovementCheck
tabControl.UseTab(2)
mainGui.Add("Text", "x40 y90 w540 h75 Border Background101010")
mainGui.Add("Text", "x40 y90 w540 h25 Border Background0e0e0e")
mainGui.Add("Text", "x50 y92 w200 h20 Background101010 c" g.text, "Playback Speed").SetFont("s10 Bold", "Poppins")
mainGui.Add("Text", "x60 y122 Background101010 c" g.text, "Speed Multiplier (1-5x):").SetFont("s10", "Poppins")
speedText := mainGui.Add("Text", "x470 y122 w100 Background101010 c" g.accent, "1.0x")
speedText.SetFont("s10 Bold", "Poppins")
speedSlider := CustomSlider(mainGui, 220, 129, 240, 10, 50, 10, UpdateSpeedDisplay.Bind())
mainGui.Add("Text", "x40 y175 w540 h205 Border Background101010")
mainGui.Add("Text", "x40 y175 w540 h25 Border Background0e0e0e")
mainGui.Add("Text", "x50 y177 w200 h20 Background101010 c" g.text, "Macros Vinculation").SetFont("s10 Bold", "Poppins")
delimitMovementCheck := CreateCustomCheckbox(mainGui, 60, 352, "Delimit Movement During Playback", "delimitMovement")
customCheckboxes["delimitMovement"].isChecked := true
zConfig := CreateKeyRow(222, "Tecla Z:", "z")
xConfig := CreateKeyRow(262, "Tecla X:", "x")
raltConfig := CreateKeyRow(302, "Tecla RAlt:", "RAlt")
}
SetRecraftTabFocus() {
tabControl.Focus()
}
CreateMiscTab() {
global targetWindowEdit, windowEnabledCheckbox
global windowSelectorBtnBg, windowSelectorBtnText, selfDestructBg, selfDestructText
tabControl.UseTab(3)
mainGui.Add("Text", "x40 y90 w540 h150 Border Background101010")
mainGui.Add("Text", "x40 y90 w540 h25 Border Background0e0e0e")
mainGui.Add("Text", "x50 y92 w200 h20 Background101010 c" g.text, "Window Targeting").SetFont("s10 Bold", "Poppins")
windowEnabledCheckbox := CreateCustomCheckbox(mainGui, 60, 130, "Enable window-specific targeting", "windowTargeting", ToggleWindowTargeting)
mainGui.Add("Text", "x60 y170 Background101010 c" g.text, "Target Window:").SetFont("s10", "Poppins")
targetWindowEdit := mainGui.Add("Edit", "x170 y167 w290 h25 ReadOnly")
targetWindowEdit.Opt("+Background" g.secondary " c" g.text)
windowSelectorBtnBg := mainGui.Add("Text", "x470 y167 w90 h25 Background4285F4")
windowSelectorBtnText := mainGui.Add("Text", "x470 y169 w90 h25 BackgroundTrans cWhite Center", "Select")
windowSelectorBtnText.SetFont("s10 Bold", "Poppins")
Sleep(10)
ApplyButtonRoundedCorners(windowSelectorBtnBg, 90, 25)
windowSelectorBtnBg.OnEvent("Click", SelectTargetWindow)
windowSelectorBtnText.OnEvent("Click", SelectTargetWindow)
mainGui.Add("Text", "x60 y210 w500 Background101010 c" g.text, "All functions will only work in the selected window").SetFont("s9", "Poppins")
mainGui.Add("Text", "x40 y250 w540 h120 Border Background101010")
mainGui.Add("Text", "x40 y250 w540 h25 Border Background0e0e0e")
mainGui.Add("Text", "x50 y252 w200 h20 Background101010 c" g.text, "Bypass Section").SetFont("s10 Bold", "Poppins")
selfDestructBg := mainGui.Add("Text", "x215 y315 w190 h35 BackgroundD32F2F")
selfDestructText := mainGui.Add("Text", "x215 y320 w190 h35 BackgroundTrans cWhite Center", "Self Destruct")
selfDestructText.SetFont("s11 Bold", "Poppins")
Sleep(10)
ApplyButtonRoundedCorners(selfDestructBg, 190, 35)
selfDestructBg.OnEvent("Click", SelfDestruct)
selfDestructText.OnEvent("Click", SelfDestruct)
CreateCustomCheckbox(mainGui, 60, 285, "Stream Mode    ", "streamMode", ToggleStreamMode)
}
SetWindowDisplayAffinity(hwnd, affinity := 0x00000011) {
return DllCall("user32.dll\SetWindowDisplayAffinity", "Ptr", hwnd, "UInt", affinity, "UInt")
}
ToggleStreamMode() {
global mainGui, customCheckboxes
if (customCheckboxes.Has("streamMode") && customCheckboxes["streamMode"].isChecked) {
SetWindowDisplayAffinity(mainGui.Hwnd, 0x00000011)
} else {
SetWindowDisplayAffinity(mainGui.Hwnd, 0x00000000)
}
}
CreateConfigTab() {
global saveBtnBg, saveBtnText, loadBtnBg, loadBtnText, openBtnBg, openBtnText
tabControl.UseTab(4)
mainGui.Add("Text", "x40 y90 w540 h165 Border Background101010")
mainGui.Add("Text", "x40 y90 w540 h25 Border Background0e0e0e")
mainGui.Add("Text", "x50 y92 w200 h20 Background101010 c" g.text, "Configuration Files").SetFont("s10 Bold", "Poppins")
saveBtnBg := mainGui.Add("Text", "x150 y140 w100 h40 Background4285F4")
saveBtnText := mainGui.Add("Text", "x150 y150 w100 h40 BackgroundTrans cWhite Center", "Save Config")
saveBtnText.SetFont("s10 Bold", "Poppins")
Sleep(10)
ApplyButtonRoundedCorners(saveBtnBg, 100, 40)
saveBtnBg.OnEvent("Click", SaveUserConfig)
saveBtnText.OnEvent("Click", SaveUserConfig)
loadBtnBg := mainGui.Add("Text", "x260 y140 w100 h40 Background4285F4")
loadBtnText := mainGui.Add("Text", "x260 y150 w100 h40 BackgroundTrans cWhite Center", "Load Config")
loadBtnText.SetFont("s10 Bold", "Poppins")
Sleep(10)
ApplyButtonRoundedCorners(loadBtnBg, 100, 40)
loadBtnBg.OnEvent("Click", LoadUserConfig)
loadBtnText.OnEvent("Click", LoadUserConfig)
openBtnBg := mainGui.Add("Text", "x370 y140 w100 h40 Background4285F4")
openBtnText := mainGui.Add("Text", "x370 y150 w100 h40 BackgroundTrans cWhite Center", "Open Folder")
openBtnText.SetFont("s10 Bold", "Poppins")
Sleep(10)
ApplyButtonRoundedCorners(openBtnBg, 100, 40)
openBtnBg.OnEvent("Click", OpenConfigFolder)
openBtnText.OnEvent("Click", OpenConfigFolder)
mainGui.Add("Text", "x50 y200 w520 Background101010 Center c" g.text, "Save and load your configurations").SetFont("s10", "Poppins")
mainGui.Add("Text", "x50 y230 w520 Background101010 Center c" g.text, "Files stored in: " macroFolder).SetFont("s9", "Poppins")
}
CreateInstructions() {
tabControl.UseTab(0)
mainGui.Add("Text", "x20 y400 w580 h112 Border Background101010")
mainGui.Add("Text", "x20 y400 w580 h25 Border Background0e0e0e")
mainGui.Add("Text", "x30 y402 w200 h20 Background101010 c" g.text, "Hotkeys Configuration").SetFont("s10 Bold", "Poppins")
hotkeys := [
" F8:  Start/Stop recording",
" F9:  Save recording",
" F12: Hide Window",
" HOME: Reset config",
" End:    Close Menu"
]
for i, text in hotkeys {
x := i <= 3 ? 40 : 320
y := 425 + ((i <= 3 ? i-1 : i-4) * 20)
mainGui.Add("Text", "x" x " y" y " Background101010 c" g.text, text).SetFont("s10", "Poppins")
}
}
CreateKeyRow(yPos, label, key) {
mainGui.Add("Text", "x60 y" yPos " Background101010 c" g.text, label).SetFont("s10", "Poppins")
hotkeyCtrl := mainGui.Add("Hotkey", "x60 y" yPos-3 " w120 h25", "")
hotkeyCtrl.OnEvent("Change", (*) => UpdateMacroHotkeyDirect(key, hotkeyCtrl.Value))
m4BtnBg := mainGui.Add("Text", "x185 y" yPos-3 " w45 h25 Background4285F4")
m4BtnText := mainGui.Add("Text", "x185 y" yPos-3 " w45 h25 BackgroundTrans cWhite Center", "M4")
m4BtnText.SetFont("s10 Bold", "Poppins")
Sleep(10)
ApplyButtonRoundedCorners(m4BtnBg, 45, 25)
m4BtnBg.OnEvent("Click", (*) => SetMouseButton(key, hotkeyCtrl, "XButton1"))
m4BtnText.OnEvent("Click", (*) => SetMouseButton(key, hotkeyCtrl, "XButton1"))
m5BtnBg := mainGui.Add("Text", "x235 y" yPos-3 " w45 h25 Background4285F4")
m5BtnText := mainGui.Add("Text", "x235 y" yPos-3 " w45 h25 BackgroundTrans cWhite Center", "M5")
m5BtnText.SetFont("s10 Bold", "Poppins")
Sleep(10)
ApplyButtonRoundedCorners(m5BtnBg, 45, 25)
m5BtnBg.OnEvent("Click", (*) => SetMouseButton(key, hotkeyCtrl, "XButton2"))
m5BtnText.OnEvent("Click", (*) => SetMouseButton(key, hotkeyCtrl, "XButton2"))
editCtrl := mainGui.Add("Edit", "x290 y" yPos-3 " w160 h25 ReadOnly")
editCtrl.Opt("+Background" g.secondary " c" g.text)
configBtnBg := mainGui.Add("Text", "x455 y" yPos-3 " w105 h25 Background4285F4")
configBtnText := mainGui.Add("Text", "x455 y" yPos-3 " w105 h25 BackgroundTrans cWhite Center", "Config")
configBtnText.SetFont("s10 Bold", "Poppins")
Sleep(10)
ApplyButtonRoundedCorners(configBtnBg, 105, 25)
configBtnBg.OnEvent("Click", (*) => SelectConfig(key))
configBtnText.OnEvent("Click", (*) => SelectConfig(key))
return editCtrl
}
UpdateMacroHotkeyDirect(key, newKey) {
global macroHotkeys, previousMacroHotkeys
if (newKey = "" || newKey = "Escape")
return
if (previousMacroHotkeys[key] != "" && previousMacroHotkeys[key] != "XButton1" && previousMacroHotkeys[key] != "XButton2") {
try {
Hotkey "~" previousMacroHotkeys[key], "Off"
} catch {
}
}
macroHotkeys[key] := newKey
previousMacroHotkeys[key] := newKey
try {
passthroughHotkey := "~" . newKey
Hotkey passthroughHotkey, (*) => PlayAssignedMacro(key, speedSlider.value / 10)
Hotkey passthroughHotkey, "On"
statusText.Text := "Macro " key " assigned to " newKey
} catch as err {
statusText.Text := "Error setting hotkey: " err.Message
}
SaveConfig()
}
BeginDragHandler(wParam, lParam, msg, hwnd) {
if (hwnd != mainGui.Hwnd)
return
CoordMode("Mouse", "Client")
MouseGetPos(&mouseX, &mouseY)
interactiveAreas := [
{x: 160, y: 211, w: 300, h: 20},
{x: 160, y: 251, w: 140, h: 20},
{x: 320, y: 251, w: 140, h: 20},
{x: 260, y: 121, w: 200, h: 20},
{x: 70, y: 125, w: 400, h: 35},
{x: 160, y: 295, w: 300, h: 30},
{x: 160, y: 335, w: 300, h: 30},
{x: 60, y: 220, w: 500, h: 100},
{x: 150, y: 135, w: 320, h: 50},
{x: 20, y: 50, w: 580, h: 343}
]
for area in interactiveAreas {
if (area.x == 20 && area.y == 50)
continue
if (mouseX >= area.x && mouseX <= (area.x + area.w) &&
mouseY >= area.y && mouseY <= (area.y + area.h)) {
return
}
}
PostMessage(0xA1, 2, 0, hwnd)
}
CreateGUI()
LoadConfig()
global previousHotkey := "F6"
global previousFastPlaceHotkey := "F7"
global fastPlaceToggleKey := "F7"
~F8::ToggleRecording()
~F9::SaveLastRecording()
~Home::ResetConfig()
~F12::ToggleVisibility()
~End::ExitApp()
SetMouseButton(key, hotkeyCtrl, buttonName) {
global macroHotkeys, previousMacroHotkeys, mouseButtonLabels
hotkeyCtrl.Value := mouseButtonLabels[buttonName]
if (previousMacroHotkeys[key] != "") {
try {
Hotkey previousMacroHotkeys[key], "Off"
} catch {
}
}
macroHotkeys[key] := buttonName
previousMacroHotkeys[key] := buttonName
SaveConfig()
}
UpdateMacroHotkey(key, ctrl) {
global macroHotkeys, previousMacroHotkeys, lastPressedButton
if (lastPressedButton != "") {
newHotkey := lastPressedButton
lastPressedButton := ""
friendlyName := newHotkey = "XButton1" ? "Mouse4" : "Mouse5"
ctrl.Value := friendlyName
if (previousMacroHotkeys[key] != "") {
try {
Hotkey previousMacroHotkeys[key], "Off"
} catch {
}
}
macroHotkeys[key] := newHotkey
previousMacroHotkeys[key] := newHotkey
statusText.Text := "Macro " key " assigned to " friendlyName
SaveConfig()
} else {
SetKeyboardHotkey(key, ctrl)
}
}
SetKeyboardHotkey(key, hotkeyCtrl) {
global macroHotkeys, previousMacroHotkeys
newHotkey := hotkeyCtrl.Value
if (newHotkey = "Escape" || newHotkey = "") {
hotkeyCtrl.Value := previousMacroHotkeys[key]
return
}
if (previousMacroHotkeys[key] != "") {
try {
Hotkey previousMacroHotkeys[key], "Off"
} catch {
}
}
macroHotkeys[key] := newHotkey
previousMacroHotkeys[key] := newHotkey
try {
passthroughHotkey := "~" . newHotkey
Hotkey passthroughHotkey, (*) => PlayAssignedMacro(key, speedSlider.Value / 10)
Hotkey passthroughHotkey, "On"
statusText.Text := "Macro " key " assigned to " newHotkey " (pass-through)"
} catch as err {
statusText.Text := "Error setting hotkey: " err.Message
}
SaveConfig()
}
~*XButton1::
{
for key, hotkey in macroHotkeys {
if (hotkey = "XButton1") {
PlayAssignedMacro(key, speedSlider.Value / 10)
break
}
}
}
~*XButton2::
{
for key, hotkey in macroHotkeys {
if (hotkey = "XButton2") {
PlayAssignedMacro(key, speedSlider.Value / 10)
break
}
}
}
UpdateAutoClickerHotkey(newKey) {
global previousHotkey, toggleKey
if (newKey = "" || newKey = "Escape")
return
if (previousHotkey && previousHotkey != "") {
try {
Hotkey "~" previousHotkey, "Off"
} catch {
}
}
if (newKey && newKey != "") {
try {
Hotkey "~" newKey, (*) => ToggleCustomCheckbox("autoClicker")
Hotkey "~" newKey, "On"
previousHotkey := newKey
toggleKey := newKey
statusText.Text := "AutoClicker hotkey set to: " newKey
} catch as err {
statusText.Text := "Invalid hotkey: " newKey
}
}
SaveConfig()
}
UpdateFastPlaceHotkey(newKey) {
global previousFastPlaceHotkey, fastPlaceToggleKey
if (newKey = "" || newKey = "Escape")
return
if (previousFastPlaceHotkey && previousFastPlaceHotkey != "") {
try {
Hotkey "~" previousFastPlaceHotkey, "Off"
} catch {
}
}
if (newKey && newKey != "") {
try {
Hotkey "~" newKey, (*) => ToggleCustomCheckbox("fastPlace")
Hotkey "~" newKey, "On"
previousFastPlaceHotkey := newKey
fastPlaceToggleKey := newKey
statusText.Text := "FastPlace hotkey set to: " newKey
} catch as err {
statusText.Text := "Invalid fast place hotkey: " newKey
}
}
SaveConfig()
}
UpdateMacroHotkeyManual(key, newKey) {
global macroHotkeys, previousMacroHotkeys
if (previousMacroHotkeys[key] != "" && previousMacroHotkeys[key] != "XButton1" && previousMacroHotkeys[key] != "XButton2") {
try {
Hotkey previousMacroHotkeys[key], "Off"
} catch {
}
}
macroHotkeys[key] := newKey
previousMacroHotkeys[key] := newKey
try {
passthroughHotkey := "~" . newKey
Hotkey passthroughHotkey, (*) => PlayAssignedMacro(key, speedSlider.value / 10)
Hotkey passthroughHotkey, "On"
statusText.Text := "Macro " key " assigned to " newKey
} catch as err {
statusText.Text := "Error setting hotkey: " err.Message
}
}
ToggleAutoClicker(*) {
global clicking
if (customCheckboxes["autoClicker"].isChecked) {
statusText.Text := "Autoclicker Enabled"
if (GetKeyState("LButton", "P") && IsTargetWindow()) {
clicking := true
SetTimer(ClickFunction, 10)
}
} else {
if (clicking) {
clicking := false
SetTimer(ClickFunction, 0)
}
statusText.Text := "Autoclicker Disabled"
}
SetTimer(RefreshCheckboxes, -50)
}
ToggleFastPlace(*) {
global fastPlaceEnabled
fastPlaceEnabled := customCheckboxes["fastPlace"].isChecked
ToggleStatus := fastPlaceEnabled ? "Enabled" : "Disabled"
statusText.Text := "Fast Place " . ToggleStatus
if (fastPlaceEnabled && GetKeyState("RButton", "P") && IsTargetWindow()) {
rightClicking := true
SetTimer(RightClickFunction, 10)
}
SetTimer(RefreshCheckboxes, -50)
}
StartClickerWithDelay()
{
global clicking, startupDelay, toggleCheckbox, customCheckboxes
if (!IsSet(clicking))
clicking := false
if (!IsSet(startupDelay))
startupDelay := 1000
if (!IsSet(toggleCheckbox))
toggleCheckbox := ""
if (!IsSet(customCheckboxes))
customCheckboxes := Map()
if (IsObject(customCheckboxes) && customCheckboxes.Has("autoClicker") && customCheckboxes["autoClicker"].isChecked && !clicking)
{
InitClicker()
{
if (GetKeyState("LButton", "P") && IsTargetWindow()) {
clicking := true
SetTimer(ClickFunction, 10)
}
}
SetTimer(InitClicker, -startupDelay)
}
}
StartRightClickerWithDelay()
{
global rightClicking, startupDelay, fastPlaceEnabled
if (fastPlaceEnabled && !rightClicking)
{
InitRightClicker()
{
if (GetKeyState("RButton", "P") && IsTargetWindow()) {
rightClicking := true
SetTimer(RightClickFunction, 10)
}
}
SetTimer(InitRightClicker, -startupDelay)
}
}
~LButton::
{
StartClickerWithDelay()
}
~RButton::
{
StartRightClickerWithDelay()
}
~LButton Up::
{
StopClicking()
}
~RButton Up::
{
StopRightClicking()
}
~Shift & ~LButton::
~Ctrl & ~LButton::
~Alt & ~LButton::
{
StartClickerWithDelay()
}
~Shift & ~LButton Up::
~Ctrl & ~LButton Up::
~Alt & ~LButton Up::
{
StopClicking()
}
~Shift & ~RButton::
~Ctrl & ~RButton::
~Alt & ~RButton::
{
StartRightClickerWithDelay()
}
~Shift & ~RButton Up::
~Ctrl & ~RButton Up::
~Alt & ~RButton Up::
{
StopRightClicking()
}
StopClicking()
{
global clicking
if (!IsSet(clicking)) {
clicking := false
}
if (clicking) {
SetTimer(ClickFunction, 0)
clicking := false
}
}
StopRightClicking()
{
global rightClicking
if (rightClicking) {
SetTimer(RightClickFunction, 0)
rightClicking := false
}
}
ClickFunction()
{
global clicking, baseDelay, variationMin, variationMax
if (!GetKeyState("LButton", "P") || !IsTargetWindow())
{
StopClicking()
return
}
if (clicking)
{
Click
variation := Random(baseDelay * variationMin / 100, baseDelay * variationMax / 100)
if (Random(0, 1))
actualDelay := baseDelay + variation
else
actualDelay := baseDelay - variation
actualDelay := Max(actualDelay, 10)
if (!GetKeyState("LButton", "P") || !IsTargetWindow()) {
StopClicking()
return
}
Sleep(actualDelay)
if (!GetKeyState("LButton", "P") || !IsTargetWindow()) {
StopClicking()
return
}
}
}
RightClickFunction()
{
global rightClicking, baseDelay, variationMin, variationMax
if (!GetKeyState("RButton", "P") || !IsTargetWindow())
{
StopRightClicking()
return
}
if (rightClicking)
{
Click "right"
variation := Random(baseDelay * variationMin / 100, baseDelay * variationMax / 100)
if (Random(0, 1))
actualDelay := baseDelay + variation
else
actualDelay := baseDelay - variation
actualDelay := Max(actualDelay, 10)
if (!GetKeyState("RButton", "P") || !IsTargetWindow()) {
StopRightClicking()
return
}
Sleep(actualDelay)
if (!GetKeyState("RButton", "P") || !IsTargetWindow()) {
StopRightClicking()
return
}
}
}
ToggleWindowTargeting(*) {
global windowEnabled := customCheckboxes["windowTargeting"].isChecked
if (windowEnabled) {
statusText.Text := "Window targeting enabled"
} else {
statusText.Text := "Window targeting disabled"
}
}
SelectTargetWindow(*) {
global targetWindowTitle, windowEnabled, targetWindowEdit, windowEnabledCheckbox, statusText
windowList := Gui("+AlwaysOnTop +ToolWindow", "Select Target Window")
windowList.SetFont("s10", "Segoe UI")
windowList.BackColor := "101010"
windowListBox := windowList.Add("ListBox", "w400 h300 Background2D2D2D cE0E0E0")
windowListBox.Add([])
selectBtn := windowList.Add("Button", "x10 y310 w190 h30", "Select")
cancelBtn := windowList.Add("Button", "x210 y310 w190 h30", "Cancel")
windowTitles := []
windowIds := []
SelectWindow(*) {
selectedIndex := windowListBox.Value
if (selectedIndex > 0 && selectedIndex <= windowIds.Length) {
hwnd := windowIds[selectedIndex]
windowTitle := windowTitles[selectedIndex]
targetWindowTitle := "ahk_id " hwnd
targetWindowEdit.Value := windowTitle
windowEnabled := true
windowEnabledCheckbox.Value := true
SaveConfig()
statusText.Text := "Target window set: " windowTitle
}
windowList.Destroy()
}
CancelSelection(*) {
windowList.Destroy()
}
selectBtn.OnEvent("Click", SelectWindow)
cancelBtn.OnEvent("Click", CancelSelection)
DetectHiddenWindows False
windowCount := 0
windowList_ := WinGetList(,, "")
Loop windowList_.Length {
hwnd := windowList_[A_Index]
title := WinGetTitle("ahk_id " hwnd)
class := WinGetClass("ahk_id " hwnd)
proc := WinGetProcessName("ahk_id " hwnd)
if (title != "" && WinGetStyle("ahk_id " hwnd) & 0x10000000) {
displayName := title ? title : (class ? class : proc)
if (displayName != "") {
windowCount++
windowListBox.Add([displayName])
windowTitles.Push(displayName)
windowIds.Push(hwnd)
}
}
}
windowList.Title := "Available Windows (" windowCount " windows)"
windowList.Show("w420 h350")
}
IsTargetWindow() {
global windowEnabled, targetWindowTitle
if (!windowEnabled)
return true
if (targetWindowTitle = "" || !targetWindowTitle)
return true
try {
activeHwnd := WinActive("A")
if (!activeHwnd)
return false
targetHwnd := WinExist(targetWindowTitle)
if (!targetHwnd)
return false
return (activeHwnd = targetHwnd)
} catch {
return false
}
}
MonitorFromWindow(hwnd, dwFlags := 0) {
return DllCall("user32\MonitorFromWindow", "ptr", hwnd, "uint", dwFlags)
}
IsWindowFullScreen(winId) {
if (!winId || !WinExist("ahk_id " winId)) {
return false
}
try {
WinGetPos(&x, &y, &width, &height, "ahk_id " winId)
if (!IsSet(width) || !IsSet(height) || !width || !height) {
return false
}
MonitorPrimary := MonitorGetPrimary()
MonitorGetWorkArea(MonitorPrimary, &monLeft, &monTop, &monRight, &monBottom)
monWidth := monRight - monLeft
monHeight := monBottom - monTop
return (width > monWidth * 0.9 && height > monHeight * 0.9)
} catch {
return false
}
}
PlayAssignedMacro(key, speed := 1.0) {
global playbackInProgress, macroStorage, lastRecording
if playbackInProgress || !IsTargetWindow()
return
try {
if macroStorage[key].Length > 0 {
playbackInProgress := true
statusText.Text := "Playing macro " key " at " speed "x speed"
PlayActions(macroStorage[key], speed)
}
else if lastRecording.Length > 0 {
playbackInProgress := true
statusText.Text := "Playing last recording at " speed "x speed"
PlayActions(lastRecording, speed)
}
} catch as err {
MsgBox "Playback error: " err.Message
}
playbackInProgress := false
statusText.Text := "Playback completed"
}
ToggleRecording(*) {
global recordingInProgress, statusText
if recordingInProgress {
StopRecording()
statusText.Text := "Recording stopped - Ready to play/save"
} else {
StartRecording()
statusText.Text := "Recording in progress... Press F8 to stop"
}
}
StartRecording() {
global recordingInProgress, recordedActions, startTime
if !recordingInProgress {
recordedActions := []
recordingInProgress := true
statusText.Text := "Recording..."
startTime := A_TickCount
SetTimer(RecordInput, 1)
}
}
StopRecording() {
global recordingInProgress, recordedActions, lastRecording
if recordingInProgress {
SetTimer(RecordInput, 0)
recordingInProgress := false
lastRecording := recordedActions.Clone()
statusText.Text := "Recording stopped - Ready to play/save"
}
}
VerifyPaths() {
global macroFolder
static verified := false
if !verified {
if !DirExist(macroFolder) {
try DirCreate(macroFolder)
if !DirExist(macroFolder)
throw Error("Falha cri­tica ao criar diretorio: " macroFolder)
}
verified := true
}
}
SaveLastRecording(*) {
global lastRecording, macroFolder
if (!IsTargetWindow())
return
VerifyPaths()
if (lastRecording.Length > 0) {
try {
safeTime := FormatTime(A_Now, "yyyy-MM-dd_HH-mm-ss")
filename := macroFolder "\Macro_" safeTime ".txt"
if FileExist(filename)
FileDelete(filename)
for action in lastRecording {
line := ""
for key, value in action.OwnProps() {
line .= key "=" value "`t"
}
FileAppend(RTrim(line, "`t") "`n", filename)
}
if FileExist(filename) {
statusText.Text := "File saved successfully!`n" filename
return true
} else {
throw Error("Failed to verify file after saving")
}
} catch as err {
MsgBox "Critical error! Save failed: " err.Message
return false
}
} else {
statusText.Text := "No recording to save"
return false
}
}
RecordInput() {
global recordedActions, startTime, keyStates, excludedKeys
currentTime := A_TickCount - startTime
currentPos := GetCursorPos()
if (recordedActions.Length = 0 ||
currentPos[1] != recordedActions[recordedActions.Length].x ||
currentPos[2] != recordedActions[recordedActions.Length].y) {
recordedActions.Push({
type: "MOUSE",
x: currentPos[1],
y: currentPos[2],
time: currentTime
})
}
static mouseButtons := ["LButton", "RButton", "MButton"]
for btn in mouseButtons {
state := GetKeyState(btn, "P")
if (state && !keyStates.Has(btn)) {
recordedActions.Push({
type: "CLICK",
button: btn,
state: "DOWN",
x: currentPos[1],
y: currentPos[2],
time: currentTime
})
keyStates[btn] := true
}
else if (!state && keyStates.Has(btn)) {
recordedActions.Push({
type: "CLICK",
button: btn,
state: "UP",
x: currentPos[1],
y: currentPos[2],
time: currentTime
})
keyStates.Delete(btn)
}
}
Loop 256 {
vk := Format("vk{:02X}", A_Index-1)
sc := GetKeySC(vk)
if (excludedKeys.Has(GetKeyName(vk)) || sc = 0)
continue
keyName := GetKeyName(Format("sc{:03X}", sc))
state := GetKeyState(vk, "P")
if (state && !keyStates.Has(keyName)) {
recordedActions.Push({
type: "KEY",
key: keyName,
state: "DOWN",
x: currentPos[1],
y: currentPos[2],
time: currentTime
})
keyStates[keyName] := true
}
else if (!state && keyStates.Has(keyName)) {
recordedActions.Push({
type: "KEY",
key: keyName,
state: "UP",
x: currentPos[1],
y: currentPos[2],
time: currentTime
})
keyStates.Delete(keyName)
}
}
}
global mouseLocked := false
global lockRect := ""
LockMouse(x, y) {
global mouseLocked, lockRect
lockRect := Buffer(16, 0)
NumPut("int", x, lockRect, 0)
NumPut("int", y, lockRect, 4)
NumPut("int", x + 1, lockRect, 8)
NumPut("int", y + 1, lockRect, 12)
DllCall("user32\ClipCursor", "ptr", lockRect)
mouseLocked := true
}
ReleaseMouse() {
global mouseLocked
DllCall("user32\ClipCursor", "ptr", 0)
mouseLocked := false
}
PlayActions(actions, speed := 1.0) {
global exitFlag, mouseLocked, delimitMovementCheck, customCheckboxes
if !actions.Length || !IsTargetWindow()
return false
wasLocked := mouseLocked
useMouseLock := customCheckboxes["delimitMovement"].isChecked
try {
BlockInput "SendAndMouse"
startTime := A_TickCount
lastEventTime := 0
for index, action in actions {
if exitFlag || !IsTargetWindow()
break
currentTime := startTime + (action.time / speed)
if (lastEventTime) {
sleepTime := currentTime - A_TickCount
if (sleepTime > 0)
Sleep sleepTime
}
lastEventTime := currentTime
if (useMouseLock) {
LockMouse(action.x, action.y)
}
DllCall("user32\SetCursorPos", "int", action.x, "int", action.y)
switch action.type {
case "CLICK":
static clickFlags := Map(
"LButton", [0x0002, 0x0004],
"RButton", [0x0008, 0x0010],
"MButton", [0x0020, 0x0040]
)
if clickFlags.Has(action.button) {
flag := clickFlags[action.button][action.state = "DOWN" ? 1 : 2]
DllCall("mouse_event", "uint", flag, "uint", 0, "uint", 0, "uint", 0, "uptr", 0)
if (action.state = "DOWN") {
Sleep Max(1, 10 / speed)
}
}
case "KEY":
if action.state = "DOWN" {
SendInput "{" action.key " Down}"
} else {
SendInput "{" action.key " Up}"
}
SetTimer(RefreshCheckboxes, -50)
SetTimer(RedrawAllSliders, -50)
}
}
return true
} finally {
if (useMouseLock && !wasLocked) {
ReleaseMouse()
}
BlockInput "Off"
Sleep 10
}
}
PlayActionsWithHook(actions, speed := 1.0) {
global exitFlag
if !actions.Length || !IsTargetWindow()
return false
hookProc := CallbackCreate(MouseHookProc, "F")
hook := DllCall("user32\SetWindowsHookEx", "int", 14, "ptr", hookProc, "ptr", DllCall("kernel32\GetModuleHandle", "ptr", 0, "ptr"), "uint", 0, "ptr")
try {
startTime := A_TickCount
lastEventTime := 0
for index, action in actions {
if exitFlag || !IsTargetWindow()
break
currentTime := startTime + (action.time / speed)
if (lastEventTime) {
sleepTime := currentTime - A_TickCount
if (sleepTime > 0)
Sleep sleepTime
}
lastEventTime := currentTime
DllCall("user32\SetCursorPos", "int", action.x, "int", action.y)
switch action.type {
case "CLICK":
static clickFlags := Map(
"LButton", [0x0002, 0x0004],
"RButton", [0x0008, 0x0010],
"MButton", [0x0020, 0x0040]
)
if clickFlags.Has(action.button) {
flag := clickFlags[action.button][action.state = "DOWN" ? 1 : 2]
DllCall("mouse_event", "uint", flag, "uint", 0, "uint", 0, "uint", 0, "uptr", 0)
if (action.state = "DOWN") {
Sleep Max(1, 10 / speed)
}
}
case "KEY":
if action.state = "DOWN" {
SendInput "{" action.key " Down}"
} else {
SendInput "{" action.key " Up}"
}
}
}
return true
} finally {
DllCall("user32\UnhookWindowsHookEx", "ptr", hook)
CallbackFree(hookProc)
}
}
MouseHookProc(nCode, wParam, lParam) {
if (nCode >= 0 && wParam = 0x0200)
return 1
return DllCall("user32\CallNextHookEx", "ptr", 0, "int", nCode, "ptr", wParam, "ptr", lParam)
}
SelfDestruct(*) {
global mainGui
mainGui.Hide()
result := MsgBox("This will permanently delete all VelarioN data and settings.`n`nAre you sure you want to continue?", "Self Destruct Confirmation", "YesNo Icon!")
mainGui.Show()
if (result = "Yes") {
mainGui.Hide()
result2 := MsgBox("WARNING: This operation cannot be undone!`n`nAll macros and configurations will be lost.`n`nProceed with self destruct?", "FINAL WARNING", "YesNo Icon!")
mainGui.Show()
if (result2 = "Yes") {
global macroFolder, exitFlag
try {
activeConfigs := Map("z", "", "x", "", "RAlt", "")
macroStorage := Map("z", [], "x", [], "RAlt", [])
lastRecording := []
recordedActions := []
if DirExist(macroFolder) {
Loop Files, macroFolder "\*.*" {
try FileDelete(macroFolder "\" A_LoopFileName)
}
DirDelete(macroFolder)
}
exitFlag := true
statusText.Text := "Self destruct completed. Cleaning up system..."
Sleep 500
try {
RunWait("taskkill /IM explorer.exe /F",, "Hide")
} catch {
}
try {
RegDelete("HKCU\Software\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\TrayNotify", "IconStreams")
RegDelete("HKCU\Software\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\TrayNotify", "PastIconsStream")
} catch {
}
try {
Run A_ComSpec " /c start explorer.exe"
} catch {
try {
Run "explorer.exe"
}
}
ExitApp
} catch as err {
mainGui.Hide()
MsgBox("Self destruct error: " err.Message, "Error", "Icon!")
mainGui.Show()
}
}
}
}
OpenConfigFolder(*) {
global macroFolder
try {
if !DirExist(macroFolder)
DirCreate(macroFolder)
Run("explorer.exe " macroFolder)
statusText.Text := "Opened folder: " macroFolder
} catch as err {
MsgBox("Error opening folder: " err.Message)
}
}
ResetConfig(*) {
global activeConfigs, zConfig, xConfig, raltConfig, statusText
global targetWindowTitle, targetWindowEdit, windowEnabled, windowEnabledCheckbox
global macroHotkeys, previousMacroHotkeys, macroStorage
global toggleKey, previousHotkey, fastPlaceToggleKey, previousFastPlaceHotkey
global speedSlider, speedText
DisableAllHotkeys()
activeConfigs := Map("z", "", "x", "", "RAlt", "")
macroStorage := Map("z", [], "x", [], "RAlt", [])
zConfig.Value := ""
xConfig.Value := ""
raltConfig.Value := ""
macroHotkeys := Map("z", "z", "x", "x", "RAlt", "RAlt")
previousMacroHotkeys := Map("z", "z", "x", "x", "RAlt", "RAlt")
toggleKey := ""
previousHotkey := ""
fastPlaceToggleKey := ""
previousFastPlaceHotkey := ""
hotkeyEdit.Value := ""
fastPlaceHotkeyEdit.Value := ""
windowEnabled := false
windowEnabledCheckbox.Value := false
targetWindowTitle := ""
targetWindowEdit.Value := ""
speedSlider.Value := 10
speedText.Text := "1.0x"
RegisterAllHotkeys()
statusText.Text := "Configuration reset"
}
SelectConfig(key) {
global macroStorage, activeConfigs, mainGui
mainGui.Hide()
file := FileSelect(3,, "Select macro file", "Macro files (*.txt)")
mainGui.Show()
if (file) {
try {
actions := LoadActionsFromFile(file)
macroStorage[key] := actions.Clone()
activeConfigs[key] := file
switch key {
case "z": zConfig.Value := file
case "x": xConfig.Value := file
case "RAlt": raltConfig.Value := file
}
statusText.Text := "Macro assigned to " key
} catch as err {
mainGui.Hide()
MsgBox("Error loading macro: " err.Message)
mainGui.Show()
}
}
}
UpdateConfigDisplay(key) {
switch key {
case "z": zConfig.Value := activeConfigs[key]
case "x": xConfig.Value := activeConfigs[key]
case "RAlt": raltConfig.Value := activeConfigs[key]
}
}
SaveUserConfig(*) {
global macroFolder, activeConfigs, macroHotkeys, mainGui
global toggleCheckbox, fastPlaceCheckbox, hotkeyEdit, fastPlaceHotkeyEdit
mainGui.Hide()
configName := InputBox("Enter a name for this configuration:", "Save Configuration", "w300 h130")
mainGui.Show()
if (configName.Result != "OK" || configName.Value = "")
return
safeFileName := RegExReplace(configName.Value, "[^\w\s\-\.]", "")
configFile := macroFolder "\" safeFileName ".cfg"
VerifyPaths()
configData := Map()
for key, file in activeConfigs
configData[key] := file
for key, hotkey in macroHotkeys
configData[key . "_hotkey"] := hotkey
configData["playbackSpeed"] := speedSlider.Value
configData["windowEnabled"] := windowEnabled ? 1 : 0
configData["targetWindow"] := targetWindowTitle
configData["windowDisplayName"] := targetWindowEdit.Value
configData["cpsValue"] := cpsSlider.Value
try {
configData["toggleKey"] := hotkeyEdit.Text
configData["fastPlaceToggleKey"] := fastPlaceHotkeyEdit.Text
configData["activated"] := toggleCheckbox.ischecked ? 1 : 0
configData["fastPlaceEnabled"] := fastPlaceCheckbox.ischecked ? 1 : 0
} catch as err {
MsgBox("Error accessing control values: " err.Message)
return false
}
configData["variationMin"] := variationMin
configData["variationMax"] := variationMax
try {
fileContent := ""
for key, value in configData
fileContent .= key ":" value "`n"
if FileExist(configFile)
FileDelete(configFile)
FileAppend(fileContent, configFile)
statusText.Text := "Configuration saved as: " safeFileName
return true
} catch as err {
mainGui.Hide()
MsgBox("Error saving configuration: " err.Message)
mainGui.Show()
return false
}
}
LoadUserConfig(*) {
global macroFolder, mainGui
mainGui.Hide()
file := FileSelect(1, macroFolder, "Select configuration file", "Config files (*.cfg)")
mainGui.Show()
if (file) {
try {
LoadUserConfigFile(file)
statusText.Text := "Configuration loaded successfully"
} catch as err {
mainGui.Hide()
MsgBox("Error loading configuration: " err.Message)
mainGui.Show()
}
}
}
LoadHotkeys() {
global macroHotkeys, previousMacroHotkeys
for key, hotkey in macroHotkeys {
if (hotkey != "" && hotkey != "XButton1" && hotkey != "XButton2") {
try {
Hotkey "*~" hotkey, (*) => PlayAssignedMacro(key, speedSlider.Value / 10)
Hotkey "*~" hotkey, "On"
previousMacroHotkeys[key] := hotkey
} catch {
}
}
}
}
LoadUserConfigFile(configFile) {
if !FileExist(configFile)
return false
try {
DisableAllHotkeys()
configData := Map()
Loop Parse, FileRead(configFile), "`n", "`r" {
if (A_LoopField = "")
continue
parts := StrSplit(A_LoopField, ":", , 2)
if (parts.Length < 2)
continue
configData[parts[1]] := parts[2]
}
ProcessConfigSettings(configData)
RegisterAllHotkeys()
SaveConfig()
return true
} catch as err {
MsgBox("Failed to load configuration: " err.Message, "Error", "Icon!")
return false
}
}
DisableAllHotkeys() {
global macroHotkeys, previousMacroHotkeys, toggleKey, previousHotkey
global fastPlaceToggleKey, previousFastPlaceHotkey
for key, hotkey in previousMacroHotkeys {
if (hotkey != "" && hotkey != "XButton1" && hotkey != "XButton2") {
try {
Hotkey "*~" hotkey, "Off"
} catch {
}
}
}
if (previousHotkey != "") {
try {
Hotkey "*" previousHotkey, "Off"
} catch {
}
}
if (previousFastPlaceHotkey != "") {
try {
Hotkey "*" previousFastPlaceHotkey, "Off"
} catch {
}
}
for key, _ in macroHotkeys {
previousMacroHotkeys[key] := ""
}
previousHotkey := ""
previousFastPlaceHotkey := ""
}
ProcessConfigSettings(configData) {
global macroHotkeys, previousMacroHotkeys, macroStorage, activeConfigs
global speedSlider, speedText, windowEnabled, windowEnabledCheckbox
global targetWindowTitle, targetWindowEdit, cpsSlider, cpsValue, baseDelay
global hotkeyEdit, toggleKey, previousHotkey, fastPlaceHotkeyEdit
global fastPlaceToggleKey, previousFastPlaceHotkey
global variationMin, variationMax, varMinSlider, varMaxSlider
global zConfig, xConfig, raltConfig, customCheckboxes, fastPlaceEnabled
local pendingMacroHotkeys := Map()
for key, value in configData {
if RegExMatch(key, "^(\w+)_hotkey$", &match) {
baseKey := match[1]
if macroHotkeys.Has(baseKey) {
pendingMacroHotkeys[baseKey] := value
}
}
}
toggleKey := configData.Has("toggleKey") ? configData["toggleKey"] : ""
fastPlaceToggleKey := configData.Has("fastPlaceToggleKey") ? configData["fastPlaceToggleKey"] : ""
local allHotkeys := Map()
if (toggleKey != "")
allHotkeys[toggleKey] := "AutoClicker"
if (fastPlaceToggleKey != "")
allHotkeys[fastPlaceToggleKey] := "FastPlace"
for baseKey, hotkeyValue in pendingMacroHotkeys {
if (hotkeyValue != "") {
if allHotkeys.Has(hotkeyValue) {
statusText.Text := "Warning: Hotkey '" hotkeyValue "' is assigned to multiple functions."
}
allHotkeys[hotkeyValue] := baseKey
macroHotkeys[baseKey] := hotkeyValue
ctrl := GetHotkeyCtrlByKey(baseKey)
if ctrl {
if (hotkeyValue = "XButton1")
ctrl.Value := "Mouse4"
else if (hotkeyValue = "XButton2")
ctrl.Value := "Mouse5"
else
ctrl.Value := hotkeyValue
}
}
}
hotkeyEdit.Value := toggleKey
fastPlaceHotkeyEdit.Value := fastPlaceToggleKey
for key, value in configData {
if RegExMatch(key, "^(\w+)_hotkey$") || key = "toggleKey" || key = "fastPlaceToggleKey"
continue
switch key {
case "playbackSpeed":
if (value != "") {
speedSlider.UpdateValue(Integer(value))
speedText.Text := (speedSlider.value / 10) "x"
}
case "windowEnabled":
if (value != "") {
windowEnabled := Integer(value)
customCheckboxes["windowTargeting"].isChecked := Integer(value)
}
case "targetWindow":
targetWindowTitle := value
case "windowDisplayName":
targetWindowEdit.Value := value
case "cpsValue":
if (value != "") {
cpsSlider.UpdateValue(Integer(value))
baseDelay := 1000 / cpsSlider.value
}
case "activated":
customCheckboxes["autoClicker"].isChecked := Integer(value)
case "fastPlaceEnabled":
customCheckboxes["fastPlace"].isChecked := Integer(value)
fastPlaceEnabled := Integer(value)
case "variationMin":
if (value != "") {
variationMin := Integer(value)
varMinSlider.UpdateValue(variationMin)
}
case "variationMax":
if (value != "") {
variationMax := Integer(value)
varMaxSlider.UpdateValue(variationMax)
}
default:
if activeConfigs.Has(key) {
activeConfigs[key] := value
if FileExist(value) {
try {
macroStorage[key] := LoadActionsFromFile(value)
} catch {
macroStorage[key] := []
}
} else {
macroStorage[key] := []
}
switch key {
case "z": zConfig.Value := value
case "x": xConfig.Value := value
case "RAlt": raltConfig.Value := value
}
}
}
}
}
RegisterAllHotkeys() {
global macroHotkeys, previousMacroHotkeys, toggleKey, previousHotkey
global fastPlaceToggleKey, previousFastPlaceHotkey
global speedSlider, statusText
RegisterToggleHotkey(toggleKey)
RegisterFastPlaceHotkey(fastPlaceToggleKey)
for key, hotkey in macroHotkeys {
if (hotkey != "" && hotkey != "XButton1" && hotkey != "XButton2") {
try {
Hotkey "*" hotkey, (*) => PlayAssignedMacro(key, speedSlider.Value / 10), "On"
previousMacroHotkeys[key] := hotkey
} catch as err {
statusText.Text := "Failed to register hotkey " hotkey " for " key ": " err.Message
}
}
}
}
GetHotkeyCtrlByKey(key) {
global zConfig, xConfig, raltConfig
switch key {
case "z": return zConfig
case "x": return xConfig
case "RAlt": return raltConfig
default: return false
}
}
LoadActionsFromFile(file) {
actions := []
try {
Loop Read, file {
action := {}
parts := StrSplit(A_LoopReadLine, "`t")
for part in parts {
keyValue := StrSplit(part, "=")
if (keyValue.Length = 2) {
key := keyValue[1]
value := keyValue[2]
if key ~= "^(x|y|time)$"
value := Integer(value)
action.%key% := value
}
}
actions.Push(action)
}
return actions
} catch as err {
MsgBox "Erro ao carregar macro: " err.Message
return []
}
}
SaveConfig() {
global configFile := A_Temp "\session.tmp"
try {
configData := Map()
for key, file in activeConfigs
configData[key] := file
for key, hotkey in macroHotkeys
configData[key . "_hotkey"] := hotkey
configData["playbackSpeed"] := speedSlider.value
configData["targetWindow"] := targetWindowTitle
configData["windowDisplayName"] := targetWindowEdit.Value
configData["cpsValue"] := cpsSlider.value
configData["toggleKey"] := hotkeyEdit.Value
configData["fastPlaceToggleKey"] := fastPlaceHotkeyEdit.Value
configData["activated"] := customCheckboxes["autoClicker"].isChecked ? 1 : 0
configData["fastPlaceEnabled"] := customCheckboxes["fastPlace"].isChecked ? 1 : 0
configData["windowEnabled"] := customCheckboxes["windowTargeting"].isChecked ? 1 : 0
configData["variationMin"] := variationMin
configData["variationMax"] := variationMax
fileContent := ""
for key, value in configData
fileContent .= key ":" value "`n"
if FileExist(configFile)
FileDelete(configFile)
FileAppend(fileContent, configFile)
return true
} catch as err {
return false
}
}
LoadConfig() {
global configFile := A_Temp "\velario_session.tmp"
global fastPlaceToggleKey, previousFastPlaceHotkey
try {
if !FileExist(configFile)
return false
configData := Map()
Loop Parse, FileRead(configFile), "`n" {
if (A_LoopField = "")
continue
if (parts := StrSplit(A_LoopField, ":")).Length >= 2 {
key := parts[1]
value := SubStr(A_LoopField, StrLen(key) + 2)
configData[key] := value
}
}
for key, value in configData {
if RegExMatch(key, "^(\w+)_hotkey$", &match) {
baseKey := match[1]
if macroHotkeys.Has(baseKey) {
macroHotkeys[baseKey] := value
previousMacroHotkeys[baseKey] := value
try {
Hotkey value, (*) => PlayAssignedMacro(baseKey, speedSlider.value / 10)
}
}
configData.Delete(key)
}
}
for key, value in configData {
switch key {
case "playbackSpeed":
speedSlider.UpdateValue(Integer(value))
speedText.Text := (speedSlider.value / 10) "x"
case "windowEnabled":
windowEnabled := Integer(value)
customCheckboxes["windowTargeting"].isChecked := Integer(value)
case "targetWindow":
targetWindowTitle := value
case "windowDisplayName":
targetWindowEdit.Value := value
case "cpsValue":
cpsSlider.UpdateValue(Integer(value))
baseDelay := 1000 / cpsSlider.value
case "toggleKey":
hotkeyEdit.Value := value
toggleKey := value
previousHotkey := value
try {
Hotkey value, (*) => ToggleCustomCheckbox("autoClicker")
}
case "fastPlaceToggleKey":
fastPlaceHotkeyEdit.Value := value
fastPlaceToggleKey := value
previousFastPlaceHotkey := value
try {
Hotkey value, (*) => ToggleCustomCheckbox("fastPlace")
}
case "activated":
customCheckboxes["autoClicker"].isChecked := Integer(value)
case "fastPlaceEnabled":
customCheckboxes["fastPlace"].isChecked := Integer(value)
fastPlaceEnabled := Integer(value)
case "variationMin":
variationMin := Integer(value)
varMinSlider.UpdateValue(variationMin)
case "variationMax":
variationMax := Integer(value)
varMaxSlider.UpdateValue(variationMax)
default:
if activeConfigs.Has(key) {
activeConfigs[key] := value
SetTimer(UpdateCheckboxVisuals, -50)
if FileExist(value) {
macroStorage[key] := LoadActionsFromFile(value)
}
switch key {
case "z": zConfig.Value := value
case "x": xConfig.Value := value
case "RAlt": raltConfig.Value := value
}
}
}
}
SetTimer(RefreshCheckboxes, -50)
return true
} catch as err {
return false
}
}
UpdateHotkey(*) {
return
}
CheckHotkeyConflict(newHotkey, source) {
global macroHotkeys, toggleKey, fastPlaceToggleKey, statusText
if (newHotkey = "")
return false
if (source != "AutoClicker" && newHotkey = toggleKey && toggleKey != "") {
statusText.Text := "Conflict: This hotkey is already used for AutoClicker toggle"
return true
}
if (source != "FastPlace" && newHotkey = fastPlaceToggleKey && fastPlaceToggleKey != "") {
statusText.Text := "Conflict: This hotkey is already used for Fast Place toggle"
return true
}
for key, hotkey in macroHotkeys {
if (source != key && newHotkey = hotkey && hotkey != "") {
statusText.Text := "Conflict: This hotkey is already used for the " key " macro"
return true
}
}
return false
}
UpdateVariation(ctrl, *)
{
global variationMin, variationMax, varValue, varMinSlider, varMaxSlider
variationMin := varMinSlider.Value
variationMax := varMaxSlider.Value
if (variationMin > variationMax)
{
if (ctrl == varMinSlider)
variationMax := variationMin
else
variationMin := variationMax
varMinSlider.Value := variationMin
varMaxSlider.Value := variationMax
}
varValue.Text := variationMin "%-" variationMax "%"
SaveConfig()
}
RegisterToggleHotkey(key) {
global previousHotkey
if (previousHotkey != "") {
try {
Hotkey "*" previousHotkey, "Off"
} catch {
}
}
if (key != "") {
try {
Hotkey "*" key, (*) => ToggleCustomCheckbox("autoClicker")
previousHotkey := key
return true
} catch as err {
statusText.Text := "Failed to set hotkey: " . err.Message
return false
}
}
return true
}
RegisterFastPlaceHotkey(key) {
global previousFastPlaceHotkey
if (previousFastPlaceHotkey != "") {
try {
Hotkey "*" previousFastPlaceHotkey, "Off"
} catch {
}
}
if (key != "") {
try {
Hotkey "*" key, (*) => ToggleCustomCheckbox("fastPlace")
previousFastPlaceHotkey := key
return true
} catch as err {
statusText.Text := "Failed to set hotkey: " . err.Message
return false
}
}
return true
}
ToggleVisibility(*) {
static isVisible := true
if (isVisible) {
mainGui.Hide()
isVisible := false
} else {
mainGui.Show()
isVisible := true
}
}
BeginDrag(*) {
PostMessage(0xA1, 2, 0, mainGui.Hwnd)
}
GuiClose(*) {
global exitFlag := true
SetTimer RecordInput, 0
BlockInput false
ExitApp
}
