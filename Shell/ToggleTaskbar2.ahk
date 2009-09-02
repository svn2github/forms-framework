_("e2")
	n := Shell_ABNew(32)
	hGui := WinExist()

	Gui, %n%:Add, Button, gOnBtn 0x8000 x4 w50 y2, Start
	ht := Toolbar_Add(hGui, "OnToolbar", "FLAT LIST TOOLTIPS", "1L", "x60")  
	btns = 
		(LTrim
			cut, 
			copy,
			paste, 
			undo,
			redo,
		 )
	Toolbar_Insert(ht, btns)
	Toolbar_Autosize(ht)
return

OnToolbar(h,e,t,p,i){
	ifEqual, e, hot, return		
	msgbox %e%
}

OnBtn:
	Send ^{Esc}
return

Shell_ABNew(Dim=25, Edge="top", AutoHide=0, OnTop=1){
	static	AB_CALLBACK := 12345

	k := 1
	while (k) {	
		n := 100 - A_Index
		Gui %k%:+LastFoundExist
		k := WinExist()
	}
	
	Gui, %n%:+LastFound -Caption +ToolWindow
	GUi, %n%:Show
	hGui := WinExist()

	if AutoHide
		 r := Shell_ABsend("SETAUTOHIDEBAR", hGui, "", Edge)
	else r := Shell_ABsend("NEW", hGui, AB_CALLBACK)

	if OnTop
		WinSet, AlwaysOnTop, on

	if !r {	
		Gui, %n%:Destroy
		return 0
	} 

	Shell_ABSetPos(hGui, Edge, Dim)
	return n
}

Shell_ABSetPos(Hwnd, Edge="LEFT", Dim=20){
		static ABM_QUERYPOS=2, ABM_SETPOS=3, LEFT=0, TOP=1, RIGHT=2, BOTTOM=3

	VarSetCapacity(ABD,36,0), NumPut(36, ABD), NumPut(Hwnd, ABD, 4), NumPut(%Edge%, ABD, 12)

	if Edge = LEFT
		r1 := 0, r2 := 0, r3 := Dim, r4 := A_ScreenHeight
	else if Edge = RIGHT
		 r1 := A_ScreenWidth - Dim, r2 := 0, r3 := A_ScreenWidth, r4 := A_ScreenHeight
	else if Edge = Top
		 r1 := 0, r2 :=0, r3 := A_ScreenWidth, r4 := Dim
	else r1 := 0, r2 := A_ScreenWidth - Dim, r3 := A_ScreenWidth, r4 := A_ScreenWidth

	loop, 4                                          
		NumPut(r%A_Index%, ABD, 12+A_Index*4, "Int") 

	DllCall("Shell32.dll\SHAppBarMessage", "UInt", ABM_QUERYPOS, "UInt", &ABD)
	loop, 4
		r%A_Index% := NumGet(ABD, 12 + 4*A_Index, "Int")
                                               
	if Edge = LEFT
		 r3 := r1+Dim
	else if Edge = RIGHT
		 r1 := r3-Dim
	else if Edge = TOP
		 r4 := r2+Dim
	else r2 := r4-Dim
	loop, 4
		NumPut(r%A_Index%, ABD, 12+A_Index*4, "Int") 

	DllCall("Shell32.dll\SHAppBarMessage", "UInt", ABM_SETPOS, "UInt", &ABD)
	DllCall("MoveWindow", "uint", Hwnd, "int", r1, "int", r2, "int", r3-r1, "int", r4-r2, "uint", 1)
}



Shell_ABsend( ABMsg, ByRef Hwnd="", CallbackMessage="", Edge="", Rect="", LParam="" ){
	static ABM_NEW=0, ABM_REMOVE=1, ABM_QUERYPOS=2, ABM_SETPOS=3,ABM_GETSTATE=4, ABM_GETTASKBARPOS=5, ABM_ACTIVATE=6, ABM_GETAUTOHIDEBAR=7, ABM_SETAUTOHIDEBAR=8, ABM_WINDOWPOSCHANGED=9, ABM_SETSTATE=10
	static LEFT=0,TOP=1,RIGHT=2,BOTTOM=3, init

	if !init 
		init := VarSetCapacity(ABD,36,0), NumPut(36, ABD)
	
	IfEqual Hwnd, , SetEnv, Hwnd, % WinExist( "ahk_class Shell_TrayWnd" )
	NumPut(Hwnd, ABD, 4)

	CallbackMessage ? NumPut(CallbackMessage, ABD, 8) : 
	LParam ? NumPut(LParam, ABD, 32) : 
	Edge != "" ? NumPut(%Edge%, ABD, 12) : 
	if (Rect != "") {
		StringSplit, r, Rect, %A_Space%
		loop, 4
			NumPut(r%A_Index%, ABD, 12+A_Index*4, "Int")
	}
	msg := "ABM_" ABMsg
	r := DllCall("Shell32.dll\SHAppBarMessage", "UInt", %msg%, "UInt", &ABD),
	if ABMsg in QUERYPOS
		Hwnd := &ABD
	return r
}

/*	Function: SetTaskBar
			  Set state of the Taskbar.

	Parameters:
			State - "autohide", "ontop" or "all". You can also remove (-), add (+) or toggle (^) state. Omit to disable all states.
	
	Return:
			Current state.

	Examples:
			Shell_SetTaskBar()				;remove all states of TaskBar
			Shell_SetTaskBar("+autohide")	;add autohide state
			Shell_SetTaskBar("-autohide")	;remove autohide state
			Shell_SetTaskBar("ontop")		;set state to ontop
			Shell_SetTaskBar("^ontop")		;toggle ontop state
*/
Shell_SetTaskBar(State="", Hwnd=""){
	static ABM_SETSTATE=10, ABM_GETSTATE=4, AUTOHIDE=1, ONTOP=2, ALL=3
			
	VarSetCapacity(ABD,36,0), NumPut(36, ABD), NumPut(Hwnd, ABD, 4)                                                   
	c := SubStr(State, 1, 1)
	if (bToggle :=  c = "^") || (bDisable := c = "-") || (c = "+")
		State := SubStr(State, 2), 	curState := DllCall("Shell32.dll\SHAppBarMessage", "UInt", ABM_GETSTATE, "UInt", &ABD), b := 1

	ifEqual, State, ,SetEnv, State, 0
	else State := %State%

	sd := curState & ~State, sa := curState | State
	if (b)
		State := bToggle ? (curState & State ? sd : sa) : bDisable ? sd : sa 
	NumPut(State, ABD, 32), DllCall("Shell32.dll\SHAppBarMessage", "UInt", ABM_SETSTATE, "UInt", &ABD)
	return State
}

#include Toolbar.ahk