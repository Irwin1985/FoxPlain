LPARAMETERS tcCaption, tnIcon, tcTitle, tcButtons, tcIconFile
* msgboxex.prg
* description: modifies the Captions of messagebox Buttons
* Parameters:
* tcCaption - the text that appears in the dialog box.
* tnIcon - the Icon sign
* tcTitle - the text that appears in the Title bar of the dialog box
* tcButtons - the Captions to be used in the Buttons using the comma "," delimiter
* use the "&" character to determine the hotkeys to be used - eg: "option&1,option&2,option&3"
* use a "\" to disable the Button
* tcIconFile - the Icon File to replace the default from messagebox()
* returns: the index number according to the option selected - eg. returns the value 3 if the 3rd Button was selected.
* sample:
* =MsgBoxEx("This is a common text", "!", "Window Title", "Option 1,Option 2,Option 3")

* Special thanks to:
* Herman Tan - Article: 'Centering VFP MessageBox in any Form'
* http://hermantan.blogspot.com/2008/07/centering-vfp-messagebox-in-any-form.html
* Craig boyd - Article: 'BindEvents on Steroids'
* http://www.sweetpotatosoftware.com/spsblog/2005/08/07/bindeventonsteroids.aspx

LOCAL loMsgB, lnReturn
loMsgB = CREATEOBJECT("xmbMsgBoxEx")
lnReturn = loMsgB.SendMessage(tcCaption, tnIcon, tcTitle, tcButtons, tcIconFile)
loMsgB = NULL
RETURN lnReturn

DEFINE CLASS xmbMsgBoxEx AS CUSTOM
  nButtonCnt = 0
  cButtons   = ""
  nbutttype  = 0
  cIconFile  = ""
  hIcon      = 0

  PROCEDURE SendMessage
    LPARAMETERS tcCaption, tnIcon, tcTitle, tcButtons, tcIconFile
    IF VARTYPE(tntimeout) = "C" AND (PCOUNT() = 4)
      tcButtons = tntimeout
      tntimeout = 0
    ENDIF

    PRIVATE pnButtonCnt, pcButtons, pnbutttype, pcIconFile, phIcon
    THIS.cIconFile = IIF(EMPTY(tcIconFile),"", tcIconFile)
    THIS.nButtonCnt = GETWORDCOUNT(tcButtons, ",")
    THIS.cButtons = tcButtons
    *!* stop 16
    *!* question 32
    *!* exclamation 48
    *!* info 64
    IF VARTYPE(tnIcon) = "C"
      tnIcon = UPPER(tnIcon)
      DO CASE
        CASE tnIcon = "X"
          tnIcon = 16
        CASE tnIcon = "?"
          tnIcon = 32
        CASE tnIcon = "!"
          tnIcon = 48
        CASE tnIcon = "I"
          tnIcon = 64
        OTHERWISE
          tnIcon = 0
      ENDCASE
    ENDIF

    * check if an Icon will be shown
    * if an Icon File was passed, we need to ensure that messagebox() will
    * show an Icon, that will be changed further.

    #DEFINE image_bitmap 0
    #DEFINE image_Icon 1
    #DEFINE lr_loadfromFile 0x0010
    #DEFINE lr_defaultsize 0x0040
    THIS.hIcon = 0
    IF NOT EMPTY(THIS.cIconFile) AND ;
        (NOT (BITTEST(tnIcon, 4) OR BITTEST(tnIcon, 5) OR BITTEST(tnIcon, 6)))
      tnIcon = tnIcon + 16
      THIS.hIcon = xmbLoadImage(0, FULLPATH(THIS.cIconFile), image_Icon,;
        0,0, lr_loadfromFile + lr_defaultsize)
    ENDIF

    * this messagebox will be modified before it is shown
    LOCAL lnoption, lnIndex
    DO CASE
      CASE THIS.nButtonCnt = 1
        THIS.nbutttype = 0 && ok
      CASE THIS.nButtonCnt = 2
        THIS.nbutttype = 4 && yes / no
      CASE THIS.nButtonCnt = 3
        THIS.nbutttype = 2 && abort / retry / ignore
      OTHERWISE
    ENDCASE

    BINDEVENT( 0, 0x06, THIS, 'WndProc' )
    lnoption = MESSAGEBOX(tcCaption, tnIcon + THIS.nbutttype, tcTitle)
    UNBINDEVENTS( 0, 0x06 )

    LOCAL lnOffset
    lnOffset = ICASE(THIS.nButtonCnt = 3, 2, THIS.nButtonCnt = 2, 5 , 0)
    lnIndex = lnoption - lnOffset

    IF THIS.hIcon <> 0
      =xmbdeleteobject(THIS.hIcon) && clear Icon handle
    ENDIF

    RETURN lnIndex

  ENDPROC

  * Windows event handler procedure
  * MSDN WindowProc callback function
  * http://msdn.microsoft.com/en-us/library/windows/desktop/ms633573(v=vs.85).aspx
  * http://hermantan.blogspot.com/2008/07/centering-vfp-messagebox-in-any-form.html
  * Here we will make all the modifications in the Windows dialog
  PROCEDURE WndProc( th_Wnd, tn_Msg, t_wParam, t_lParam )

    IF (tn_Msg == 0x06) AND (t_wParam == 0) AND (t_lParam <> 0)

      wParam = t_lParam

      #DEFINE dlg_ctrlid_Icon 0x0014
      #DEFINE stm_setIcon 0x0170
      #DEFINE stm_setimage 0x0172
      IF NOT EMPTY(THIS.hIcon)
        * changing the dialog Icon
        LOCAL lhIconwindow
        lhIconwindow = xmbGetDlgItem(wParam, dlg_ctrlid_Icon)
        IF lhIconwindow <> 0
          IF THIS.hIcon <> 0
            =xmbSendMessage(lhIconwindow, stm_setIcon, THIS.hIcon, 0)
          ENDIF
        ENDIF
      ENDIF

      * Set tansparency
      IF VARTYPE(_SCREEN.xmbMessageboxTransp) = "N"
        LOCAL lnTransp
        lnTransp = _SCREEN.xmbMessageboxTransp
        IF lnTransp > 30 AND lnTransp < 255 && values lower than 30 generate an almost invisible dialog!!!
          lnTransp = MIN(INT(lnTransp), 254)
          =xmbSetWindowLong( wParam, -20, ;
            BITOR( xmbGetWindowLong( wParam, -20 ), 0x80000 ))
          =xmbSetLayeredWindowAttributes( wParam, 0, lnTransp, 2 )
        ENDIF
      ENDIF

      * change Button attributes
      LOCAL N, lnOffset, lcCaption
      lnOffset = ICASE(THIS.nButtonCnt = 3, 2, THIS.nButtonCnt = 2, 5 , 0)
      LOCAL lnBtnhWnd
      FOR N = 1 TO THIS.nButtonCnt
        lcCaption = GETWORDNUM(THIS.cButtons, N, ",") + CHR(0)
        * disable current Button
        IF LEFT(lcCaption, 1) = "\"
          lcCaption = SUBSTR(lcCaption, 2) && get the rest of the string
          lnBtnhWnd = xmbGetDlgItem(wParam, lnOffset + N)
          =xmbEnableWindow(lnBtnhWnd, 0)
        ENDIF

        * change the Caption
        =xmbSetDlgItemtext(wParam, lnOffset + N, lcCaption)
      ENDFOR

    ENDIF

    LOCAL pOrgProc
    pOrgProc = xmbGetWindowLong( _VFP.HWND, -4 )
    = xmbCallWindowProc( pOrgProc, th_Wnd, tn_Msg, t_wParam, t_lParam )
  ENDPROC

ENDDEFINE

*********************************************************************
FUNCTION xmbSetDlgItemtext(hdlg, nidDlgItem, lpString)
*********************************************************************
  DECLARE INTEGER SetDlgItemText IN user32 AS xmbsetDlgItemtext ;
    LONG hdlg,;
    LONG nidDlgItem,;
    STRING lpString
  RETURN xmbSetDlgItemtext(hdlg, nidDlgItem, lpString)
ENDFUNC

*********************************************************************
FUNCTION xmbCallNextHookEx(hhook, ncode, wParam, LPARAM)
*********************************************************************
  DECLARE LONG callnexthookex IN user32 AS xmbcallnexthookex ;
    LONG hhook, LONG ncode, LONG wParam, LONG LPARAM
  RETURN xmbcallnexthookex(hhook, ncode, wParam, LPARAM)
ENDFUNC

*********************************************************************
FUNCTION xmbGetDlgItem(hdlg, nidDlgItem)
*********************************************************************
* hdlg [in] handle to the dialog box that contains the control.
* nidDlgItem [in] specifies the identifier of the control to be retrieved.
* http://msdn.microsoft.com/en-us/library/ms645481(vs.85).aspx
  DECLARE INTEGER GetDlgItem IN user32 AS xmbgetDlgItem ;
    LONG hdlg,;
    LONG nidDlgItem
  RETURN xmbGetDlgItem(hdlg, nidDlgItem)
ENDFUNC

*********************************************************************
FUNCTION xmbEnableWindow(HWND, fEnable)
*********************************************************************
  DECLARE INTEGER EnableWindow IN user32 AS xmbEnablewindow INTEGER HWND, INTEGER fEnable
  RETURN xmbEnableWindow(HWND, fEnable)
ENDFUNC

*********************************************************************
FUNCTION xmbSendMessage(hwindow, msg, wParam, LPARAM)
*********************************************************************
* http://msdn.microsoft.com/en-us/library/bb760780(vs.85).aspx
* http://www.news2news.com/vfp/?group=-1&function=312
  DECLARE INTEGER SendMessage IN user32 AS xmbsendmessage;
    INTEGER hwindow, INTEGER msg,;
    INTEGER wParam, INTEGER LPARAM
  RETURN xmbSendMessage(hwindow, msg, wParam, LPARAM)
ENDFUNC

*********************************************************************
FUNCTION xmbLoadImage(hinst, lpszname, utype, cxdesired, cydesired, fuload)
*********************************************************************
  DECLARE INTEGER LoadImage IN user32 AS xmbloadimage;
    INTEGER hinst,;
    STRING lpszname,;
    INTEGER utype,;
    INTEGER cxdesired,;
    INTEGER cydesired,;
    INTEGER fuload
  RETURN xmbLoadImage(hinst, lpszname, uType, cxdesired, cydesired, fuload)
ENDFUNC

*********************************************************************
FUNCTION xmbDeleteObject(hobject)
*********************************************************************
  DECLARE INTEGER DeleteObject IN gdi32 AS xmbdeleteobject INTEGER hobject
  RETURN xmbdeleteobject(hobject)
ENDFUNC

*********************************************************************
FUNCTION xmbCallWindowProc(lpPrevWndFunc, nhWnd, uMsg, wParam, LPARAM)
*********************************************************************
  DECLARE LONG CallWindowProc IN User32 ;
    AS xmbCallWindowProc ;
    LONG lpPrevWndFunc, LONG nhWnd, ;
    LONG uMsg, LONG wParam, LONG LPARAM
  RETURN xmbCallWindowProc(lpPrevWndFunc, nhWnd, uMsg, wParam, LPARAM)
ENDFUNC

*********************************************************************
FUNCTION xmbGetWindowLong(nhWnd, nIndex)
*********************************************************************
  DECLARE LONG GetWindowLong IN User32 ;
    AS xmbGetWindowLong ;
    LONG nhWnd, INTEGER nIndex
  RETURN xmbGetWindowLong(nhWnd, nIndex)
ENDFUNC

*********************************************************************
FUNCTION xmbSetWindowLong(nHWnd, nIndex, nNewVal)
*********************************************************************
  DECLARE INTEGER SetWindowLong IN Win32Api ;
    AS xmbSetWindowLong ;
    INTEGER nHWnd, INTEGER nIndex, INTEGER nNewVal
  RETURN xmbSetWindowLong(nHWnd, nIndex, nNewVal)
ENDFUNC

*********************************************************************
FUNCTION xmbSetLayeredWindowAttributes(nHWnd, cColorKey, nOpacity, nFlags)
*********************************************************************
  DECLARE INTEGER SetLayeredWindowAttributes IN Win32Api ;
    AS xmbSetLayeredWindowAttributes ;
    INTEGER nHWnd, STRING cColorKey, ;
    INTEGER nOpacity, INTEGER nFlags
  RETURN xmbSetLayeredWindowAttributes(nHWnd, cColorKey, nOpacity, nFlags)
ENDFUNC
*********************************************************************