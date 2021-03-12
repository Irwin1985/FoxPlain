&& ======================================================================== &&
&& Class Misc
&& ======================================================================== &&
Define Class Misc As Session
	DataSession  	= 2
	MenuIdentity 	= ""
	cMenuTableName = ""
	RIGHT_PANEL = "RightPanel"
	SHORT_CUT   = "Shortcut"
	cProjectFile = ""
	OutPut = ""
	lCopyDebugMenuTable = .F.
	DebugMenuTablePath = ""
	lCopyAllImages = .T.
&& ======================================================================== &&
&& Function Init
&& ======================================================================== &&
	Function Init
		Set Deleted On
		Set Exact on 
		Set Near off
		This.CreateCursors()
	Endfunc
&& ======================================================================== &&
&& Crea el cursor que contendrá la información del menú.
&& ======================================================================== &&
	Function CreateCursors As VOID
		Create Cursor qMenu ;
			(;
			nID 		i Autoinc	, 	;
			Key 		c(10)		, 	;
			Parent 		c(10)		, 	;
			UniqueID	c(10)		, 	;
			objName 	c(25)		, 	;
			level		c(25)		, 	;
			text		c(150)		, 	;
			PopUp 		c(25)		, 	;
			bar			i 			,	;
			Command		m			,	;
			HotKey		c(10)		,	;
			SkipFor		c(250)		,	;
			Picture		c(150)		,	;
			Tree		c(40)		,	;
			menu		c(25)		,	;
			type		c(10) 		,	;
			group		i 			,	;
			Tags		c(250)		, 	;
			Team 		c(25)		,	;
			isGroup		l 			,	;
			TeamID		i 				;
			)
		Index On UniqueID 	Tag UniqueID 	Additive
		Index On Type 		Tag Type 		Additive
		Index On isGroup 	Tag isGroup 	Additive
		Index On Group 		Tag Group 		Additive
		Index On Tree 		Tag Tree 		Additive
		Index On Parent 	Tag Parent 		Additive
		Index On Level 		Tag Level 		Additive

		Index On objName 	Tag objName 	Additive
		Index On Popup		Tag Popup 		Additive
		Index On Bar 		Tag Bar 		Additive

		Index On Team 		Tag Team 		Additive
		Index On TeamID 	Tag TeamID 		Additive

	Endfunc
&& ======================================================================== &&
&& Generate cMenu DBF table to include in final project.
&& ======================================================================== &&
	Function GenerateMenuTable As String
		Lparameters tcProjectFile As String
		Try
			Local 					  ;
				loEx 		As Exception, ;
				lcMenuFile 	As String	, ;
				lnTotalRows As Integer

			lcMenuFile  		= ""
			lnTotalRows 		= 0
			this.cProjectFile 	= tcProjectFile
			this.OutPut 		= Addbs(JustPath(tcProjectFile))
			Use (tcProjectFile) Alias Menus Shared In 0

			Select ;
				Layout, ;
				mprFile As Location, ;
				JustStem(mprFile) As Name, ;
				Descrip As FullDesc, ;
				ImgFolder ;
				From Menus ;
				Where ;
				execute ;
				Order By Order ;
				Into Cursor qProgMenu

			Use In (Select("Menus"))
			If Reccount("qProgMenu") = 0
				Wait "Error de compilación - proyecto vacío!" Window Nowait
			Endif

* Set path de todas las carpetas de imagenes
			Try
				Select Distinct ImgFolder From qProgMenu Into Array aImgList
				If Alen(aImgList, 1) > 0
					For Each lcImgDir In aImgList
						This.SetPathTo(Alltrim(lcImgDir))
					Endfor
				Endif
				Release aImgList
			Catch
			Endtry
* end.

			Select qProgMenu
			Scan
				This.MenuIdentity = This.SetMenuIdentity(qProgMenu.Layout)
				lcMenuFile = Alltrim(qProgMenu.Location)
				This.ParseMenu(lcMenuFile, iif(Empty(qProgMenu.FullDesc), Juststem(lcMenuFile), qProgMenu.FullDesc))
				lnTotalRows = Reccount("qMenu")
				Select qProgMenu
			Endscan
			If Used("qMenu")
				Select qMenu
				If File(This.cMenuTableName)
					Local lcTableName As String
					lcTableName = This.cMenuTableName
					Delete File &lcTableName
				Endif
				Select * From qMenu Into Table (This.cMenuTableName)

				* Debug Table
				If This.lCopyDebugMenuTable
					Select * From qMenu Into Table (This.DebugMenuTablePath) + "DebugMenu.dbf"
					Use in (Select("DebugMenu"))
				EndIf

				Use In (Select("cMenu"))
			Endif
		Catch To loEx
			Error loEx.Message
		Finally
			Store .Null. To loEx
			Release loEx
			Use In (Select("Menus"))
			Use In (Select("qMenu"))
			Use In (Select("qProgMenu"))
		EndTry
		This.PackageResources()
		Return This.cMenuTableName
	Endfunc
&& ======================================================================== &&
&& Function PackageResources
&& ======================================================================== &&
	Function PackageResources As Void
		Try
			Local loEx As Exception, lcOutputDir As String
			If !Empty(This.cMenuTableName) And !Empty(This.OutPut) And File("SnapRibbon.res")
				#Define IMAGE_RESOURCE	"img"
				#Define STYLE_RESOURCE	"res"
				Local ;
					lcResourcePath 		As String, ;
					lcImagePath 		As String, ;
					lcStylePath 		As String, ;
					lcFileDBFContent 	As Memo, ;
					lcFileDBF 			As String, ;
					lcFileFPT			As String, ;
					lcTemName			As String, ;
					lcFileSavePath		As String

				lcResourcePath 	= Addbs(JustPath(This.OutPut)) 	+ "Resource"
				lcImagePath		= Addbs(lcResourcePath) 		+ "Images\"
				lcStylePath		= Addbs(lcResourcePath) 		+ "Styles\"

				If Not Directory(lcResourcePath)
					MkDir &lcResourcePath
				Endif
				If Not Directory(lcImagePath)
					MkDir &lcImagePath
				Endif
				If Not Directory(lcStylePath)
					MkDir &lcStylePath
				Endif
				Text To lcFileDBFContent Noshow
MBQEFC0AAACIATUAAAAAAAAAAAAAAAAAAAAAAAIDAABDTkFNRQAAAAAAAEMBAAAALQAAAAAAAAAAAAAAAAAAAE1EQVRBAAAAAAAATS4AAAAEAAAAAAAAAAAAAAAAAAAAQ1RZUEUAAAAAAABDMgAAAAMAAAAAAAAAAAAAAAAAAAANAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgY3Jvc3Mtc2hpZWxkLWljb24ucG5nICAgICAgICAgICAgICAgICAgICAgICAgCAAAAElNRyBleGNsYW1hdGlvbi1zaGllbGQtaWNvbi5wbmcgICAgICAgICAgICAgICAgICAVAAAASU1HIGluZm9ybWF0aW9uLXNoaWVsZC1pY29uLnBuZyAgICAgICAgICAgICAgICAgICIAAABJTUcgUXVpY2tBY2Nlc3NFbXB0eUljb24ucG5nICAgICAgICAgICAgICAgICAgICAgLwAAAElNRyBSaWJib25NaW5pbWl6ZS5wbmcgICAgICAgICAgICAgICAgICAgICAgICAgICA5AAAASU1HIFNtYWxsSWNvbnMuYm1wICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgID4AAABJTUcgU3RhdHVzQmFyVmlld1N3aXRjaGVzLnBuZyAgICAgICAgICAgICAgICAgICAgvwAAAElNRyB0aWNrLXNoaWVsZC1pY29uLnBuZyAgICAgICAgICAgICAgICAgICAgICAgICDNAAAASU1HIEpldC5kbGwgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgINoAAABSRVMgSmV0LnRsYiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg4wAAAFJFUyBOZm92SnVmbnQyLmRsbCAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAAAQAAUkVTIE5mb3ZKdWZudDIudGxiICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIA8BAABSRVMgT2ZmaWNlMjAwNy5kbGwgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgSwEAAFJFUyBPZmZpY2UyMDA3LnJzbCAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBjWQAAUkVTIE9mZmljZTIwMTAuZGxsICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGuAAABSRVMgT2ZmaWNlMjAxMC5yc2wgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgu9gAAFJFUyBPZmZpY2UyMDEzLmRsbCAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICDbCwEAUkVTIE9mZmljZTIwMTNBY2Nlc3MucnNsICAgICAgICAgICAgICAgICAgICAgICAgIMPCAQBSRVMgT2ZmaWNlMjAxM0V4Y2VsbC5yc2wgICAgICAgICAgICAgICAgICAgICAgICAgFPQBAFJFUyBPZmZpY2UyMDEzT25lTm90ZS5yc2wgICAgICAgICAgICAgICAgICAgICAgICBlJQIAUkVTIE9mZmljZTIwMTNPdXRMb29rLnJzbCAgICAgICAgICAgICAgICAgICAgICAgILZWAgBSRVMgT2ZmaWNlMjAxM1Bvd2VyUG9pbnQucnNsICAgICAgICAgICAgICAgICAgICAgB4gCAFJFUyBPZmZpY2UyMDEzUHVibGlzaGVyLnJzbCAgICAgICAgICAgICAgICAgICAgICBYuQIAUkVTIE9mZmljZTIwMTNXb3JkLnJzbCAgICAgICAgICAgICAgICAgICAgICAgICAgIKnqAgBSRVMgT3p3Y3hhLmRsbCAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg+hsDAFJFUyBPendjeGEudGxiICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKHAMAUkVTIFJqc3pOeWpyeC5kbGwgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIFccAwBSRVMgUmpzek55anJ4LnRsYiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgZBwDAFJFUyBUaHB1VGx1Yi5kbGwgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICChHAMAUkVTIFRocHVUbHViLnRsYiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIKkcAwBSRVMgVHVidXZ0Q2JzLmRsbCAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg5xwDAFJFUyBUdWJ1dnRDYnMudGxiICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICDvHAMAUkVTIFViY3QuZGxsICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIEAdAwBSRVMgVWJjdC50bGIgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgTB0DAFJFUyBWaXN1YWxTdHVkaW8yMDEyLmRsbCAgICAgICAgICAgICAgICAgICAgICAgICB6HQMAUkVTIFZpc3VhbFN0dWRpbzIwMTUuZGxsICAgICAgICAgICAgICAgICAgICAgICAgIJoeAwBSRVMgVmlzdWFsU3R1ZGlvMjAxNUJsdWUucnNsICAgICAgICAgICAgICAgICAgICAg2iQDAFJFUyBWaXN1YWxTdHVkaW8yMDE1RGFyay5yc2wgICAgICAgICAgICAgICAgICAgICArVgMAUkVTIFZpc3VhbFN0dWRpbzIwMTVMaWdodC5yc2wgICAgICAgICAgICAgICAgICAgIHyHAwBSRVMgV2lobmxpZi5kbGwgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgzbgDAFJFUyBXaWhubGlmLnRsYiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICDjuAMAUkVTIFdpbmRvd3M3LmRsbCAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIEW5AwBSRVMgV2luZG93czcucnNsICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgtdgDAFJFUyBXbmdndHMuZGxsICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICDGCgQAUkVTIFduZ2d0cy50bGIgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgINoKBABSRVMa
				EndText
				lcTemName = Sys(2015)
				lcFileDBF = Addbs(GetEnv("TEMP")) + lcTemName + ".DBF"
				lcFileFPT = Addbs(GetEnv("TEMP")) + lcTemName + ".FPT"
				=StrToFile(StrConv(lcFileDBFContent, 14), lcFileDBF)
				=StrToFile(Strconv(FileToStr("SnapRibbon.res"), 14), lcFileFPT)
				If File(lcFileDBF) And File(lcFileFPT)
					Use (lcFileDBF) Alias cFiles Shared in 0
					Select cFiles
					Scan
						Wait "Generando Directorio de recursos, espere..." Window Nowait
						lcResourceName = Alltrim(cFiles.cName)
						lcFileSavePath = ""
						Do Case
						Case Lower(Alltrim(cFiles.cType)) == IMAGE_RESOURCE
							lcFileSavePath = lcImagePath + lcResourceName
						Case Lower(Alltrim(cFiles.cType)) == STYLE_RESOURCE
							lcFileSavePath = lcStylePath + lcResourceName
						EndCase
						If !Empty(lcFileSavePath)
							=StrToFile(cFiles.mData, lcFileSavePath)
						Endif
						Wait Clear
					EndScan
					Use In (Select("cFiles"))
					Delete File &lcFileDBF
					Delete File &lcFileFPT
					* Copy the SnapRibbon.dll into project folder.
					try
						lcSource = Addbs(Getenv("TEMP")) + "SnapRibbon.dll"
						If File(lcSource)
							lcTarget = Addbs(JustPath(This.OutPut)) + Justfname(lcSource)
							If File(lcSource) And !File(lcTarget)
								lcCommand = 'Copy File "' + lcSource + '" To "' + lcTarget + '"'
								&lcCommand
							Endif
						EndIf
					Catch
					endtry
					* end.
					If This.lCopyAllImages
						This.PackageMenuImages(lcImagePath)
					EndIf
				Else
					Wait "No se pudo crear el fichero de recursos" Window
				Endif
			Else
				Wait "PackageResources: Faltan requisitos!" Window
			Endif
		Catch To loEx
			Wait "ERROR: " 		+ Str(loEx.ErrorNo) + Chr(13) + ;
				"MENSAJE: " 	+ loEx.Message 		+ Chr(13) + ;
				"LINEA: " 		+ Str(loEx.Lineno) 	+ Chr(13) + ;
				"PROGRAMA: " 	+ loEx.Procedure Window
		Finally
			Store .Null. To loEx
			Release loEx
		Endtry		
	EndFunc
&& ======================================================================== &&
&& Function PackageMenuImages
&& ======================================================================== &&
	Protected Function PackageMenuImages As Void
		Lparameters tcImagePath As String
		Try
			Local ;
			loEx 				As Exception, ;
			lcSourcePicture 	As String, ;
			lcTargetPicture 	As String, ;
			lcCommand 			As String

			Use (This.cMenuTableName) Alias cMenu Shared In 0
			Select cMenu
			Scan
				Wait "Copiando imagenes, espere..." Window Nowait
				lcSourcePicture = Alltrim(cMenu.Picture)
				lcTargetPicture = tcImagePath + Justfname(lcSourcePicture)
				If File(lcSourcePicture) And !File(lcTargetPicture)
					lcCommand = 'Copy File "' + lcSourcePicture + '" To "' + lcTargetPicture + '"'
					&lcCommand
				Endif
				Replace Picture With lcTargetPicture in cMenu
				Wait Clear
			EndScan
		Catch To loEx
			Wait "ERROR: " 		+ Str(loEx.ErrorNo) + Chr(13) + ;
				"MENSAJE: " 	+ loEx.Message 		+ Chr(13) + ;
				"LINEA: " 		+ Str(loEx.Lineno) 	+ Chr(13) + ;
				"PROGRAMA: " 	+ loEx.Procedure Window
		Finally
			Use In(Select("cMenu"))
			Store .Null. To loEx
			Release loEx
		Endtry
	EndFunc
&& ======================================================================== &&
&& Function SetMenuIdentity
&& ======================================================================== &&
	Function SetMenuIdentity As String
		Lparameters tnIdentity As Integer
		#Define QUICK_ACCESS_ID	1
		#Define TAB_ID			2
		#Define LEFT_PANEL_ID	3
		#Define STATUS_BAR_ID	4
		#Define RIGHT_PANEL_ID	5
		#Define SHORT_CUT_ID	6
		Local lcType As String
		lcType = "Tab"
		Do Case
		Case tnIdentity == QUICK_ACCESS_ID
			lcType = "QuicAccess"
		Case tnIdentity == TAB_ID
			lcType = "Tab"
		Case tnIdentity == LEFT_PANEL_ID
			lcType = "LeftPanel"
		Case tnIdentity == STATUS_BAR_ID
			lcType = "StatusBar"
		Case tnIdentity == RIGHT_PANEL_ID
			lcType = "RightPanel"
			This.nRightPanelCounter = This.nRightPanelCounter + 1
		Case tnIdentity == SHORT_CUT_ID
			lcType = "Shortcut"
			This.nShortcutCounter = This.nShortcutCounter + 1
		Endcase
		Return lcType
	Endfunc
&& ======================================================================== &&
&& Function ParseMenu
&& ======================================================================== &&
	Function ParseMenu As Boolean
		Lparameters tcMenu As String, tcMenuDesc As String
		Try
			#Define _DEFINE_PAD			"DEFINE PAD" + Space(1)
			#Define _ON_PAD				"ON PAD" + Space(1)
			#Define _ON_SELECTION_PAD	"ON SELECTION PAD" + Space(1)
			#Define _ACTIVATE_POPUP		"ACTIVATE POPUP" + Space(1)
			#Define _DEFINE_BAR			"DEFINE BAR" + Space(1)
			#Define _ON_BAR				"ON BAR" + Space(1)
			#Define _ON_SELECTION_BAR	"ON SELECTION BAR" + Space(1)
			#Define _MESSAGE			"MESSAGE" + Space(1)
			#Define _DO					"DO" + Space(1)

			#Define _COMMENT			"*"
			#Define _BAR_LEN			2
			#Define _BAR_PROMPT			"\-"
			#Define _FILE_NOT_OPENED	"Error: no se pudo abrir el fichero."
			#Define _FILE_NOT_FOUND		"Archivo no encontrado"
			#Define _PARENT_KEY			"id_0"
			Local 								  ;
				loEx				As Exception, ;
				lbReturn 			As Boolean	, ;
				lnHandle 			As Integer	, ;
				lcLineContent 		As Memo	  	, ;
				lcUniqueID			As String	, ;
				lcGroupName			As String	, ;
				lnBarCounter		As Integer  , ;
				lnIDCounter 		As Integer  , ;
				lcMenu 				As String   , ;
				lnBeginID 			As Integer  , ;
				lnEndID				As Integer
			lbReturn     = .T.
			lnBarCounter = 0
			lnIDCounter  = 0
			If File(tcMenu)
				lnHandle = Fopen(tcMenu)
				If lnHandle > 0
					lcUniqueID	   = ""
					lcPreviousLine = ""
					lcGroupName	   = "no_group"
					lcMenu 		   = Upper(Alltrim(Evl(tcMenuDesc, Juststem(tcMenu))))
					Select qMenu
					Go Bottom
					lnBeginID	   = Evl(qMenu.nID, 1)
					lnEndID 	   = 0
					Do While Not Feof(lnHandle)
						lcLineContent = Fgets(lnHandle)

						If This.CheckPreviousLineAndLoop(@lcLineContent, @lcPreviousLine)
							Loop
						Endif

						If Left(Alltrim(lcLineContent), 1) == _COMMENT
							Loop
						Endif
						lnIDCounter = lnIDCounter + 1
						Do Case
						Case _DEFINE_PAD $ Upper(lcLineContent)
							Local ;
								lcObjName 	As String, ;
								lcLevel 	As String, ;
								lcPrompt 	As String, ;
								lcKey 		As String, ;
								lcHotKey 	As String, ;
								lcMessage	As String
							Append Blank In qMenu
							lnEndID = qMenu.nID
							With This
								lcObjName	= .ExtractPadAndOfFromLineContent(lcLineContent)
								lcLevel		= .ExtractOfAndPromptFromLineContent(lcLineContent)
								lcPrompt	= .ExtractDoubleQuotesFromLineContent(lcLineContent)
								lcKey		= "id_" + Alltrim(Str(qMenu.nID))
								lcHotKey	= .ExtractShortCutFromLineContent(lcLineContent)
								lcMessage	= .ExtractMessageFromLineContent(lcLineContent)
							Endwith

							Replace Key			With lcKey 				In qMenu
							Replace Parent		With _PARENT_KEY 		In qMenu
							Replace UniqueID	With lcUniqueID 		In qMenu
							Replace objName		With lcObjName 			In qMenu
							Replace Level		With lcLevel 			In qMenu
							Replace Text		With lcPrompt 			In qMenu
							Replace Popup		With "" 				In qMenu
							Replace Bar			With 0 					In qMenu
							Replace Command		With "" 				In qMenu
							Replace HotKey		With lcHotKey 			In qMenu
							Replace SkipFor		With "" 				In qMenu
							Replace Picture		With "" 				In qMenu
							Replace Tree		With ""					In qMenu
							Replace Menu		With Upper(lcMenu) 		In qMenu
							Replace Type		With This.MenuIdentity	In qMenu
							If This.MenuIdentity == This.RIGHT_PANEL
								Replace Group With This.nRightPanelCounter In qMenu
							Endif
							If This.MenuIdentity == This.SHORT_CUT
								Replace Group With This.nShortcutCounter In qMenu
							Endif
							Replace Tags With lcMessage In qMenu

						Case _ON_PAD $ Upper(lcLineContent) And _ACTIVATE_POPUP $ Upper(lcLineContent)
							Local ;
								lcObjName 	As String, ;
								lcLevel 	As String, ;
								lcPopup 	As String

							With This
								lcObjName 	= .ExtractPadAndOfFromLineContent(lcLineContent)
								lcLevel		= .ExtractOfAndActivateFromLineContent(lcLineContent)
								lcPopup 	= .ExtractPopupFromLineContent(lcLineContent)
							Endwith

							Update qMenu ;
								set Popup = lcPopup ;
								Where ;
								nID >= lnBeginID And nID <= lnEndID 			     And ;
								Alltrim(Menu)  == Alltrim(lcMenu)    And ;
								Alltrim(Level) 	== Alltrim(lcLevel)   And ;
								Alltrim(objName) == Alltrim(lcObjName)
* begin new
						Case _ON_SELECTION_PAD $ Upper(lcLineContent)
							Local ;
								lcObjName 	As String, ;
								lcCommand 	As String, ;
								lcLevel		As String, ;
								lcUniqueID	As String, ;
								lcOnClick	As Memo

							Dimension aUniqueID(1) 	As String

							aUniqueID[1] = ""
							lcLevel 	 = "_MSYSMENU"

							With This
								lcObjName = .ExtractPadAndOfFromLineContent(lcLineContent)
								&&  IRODG 20200813
								lcCommand = .ExtractCommandFromLineContent(lcLineContent)
								&&  IRODG 20200813
							Endwith

							Select UniqueID	;
								From qMenu ;
								Where ;
								Alltrim(objName) == Alltrim(lcObjName) And ;
								Alltrim(Level) == Alltrim(lcLevel) ;
								Into Array aUniqueID

							lcUniqueID 	= Evl(aUniqueID[1], "")
							lcOnClick 	= Iif(Alltrim(GetWordNum(lcCommand, 1, "|")) = "COMMAND", Alltrim(GetWordNum(lcCommand, 2, "|")), "DO " + lcCommand)
*!*								Select qMenu
*!*								Browse title "lnBeginID=>" + Alltrim(Str(lnBeginID)) + ", lnEndID=> " + Alltrim(Str(lnEndID)) + ;
*!*								", lcMenu=> " + lcMenu + ", lcObjName=> " + lcObjName + ", lcLevel=> " + lcLevel
			
							Update qMenu ;
								set Command = lcOnClick ;
								where ;
								nID >= lnBeginID And nID <= lnEndID 			And ;
								Alltrim(Menu) == Alltrim(lcMenu) 	And ;
								Alltrim(objName) == Alltrim(lcObjName) And ;
								Alltrim(Level) == Alltrim(lcLevel)

* end new
						Case _DEFINE_BAR $ Upper(lcLineContent)
							Local ;
								lnBarNumber As Integer, ;
								lcPopup 	As String, ;
								lcPrompt 	As String, ;
								lcKey 		As String, ;
								lcParent 	As String, ;
								lcLevel 	As String, ;
								lcHotKey 	As String, ;
								lcSkipFor 	As String, ;
								lcPicture 	As String, ;
								lcTree		As String, ;
								lcMessage	As String
							Dimension aParent(2) As String

							lcPrompt = This.ExtractDoubleQuotesFromLineContent(lcLineContent)

							Append Blank In qMenu
							lnEndID = qMenu.nID
							With This
								lnBarNumber = Val(.ExtractBarNumberFromLineContent(lcLineContent))
								lcPopup		= .ExtractOfAndPromptFromLineContent(lcLineContent)
								lcKey		= "id_" + Alltrim(Str(qMenu.nID))
								lcParent	= ""
								aParent(1)  = ""
								aParent(2)  = ""
								lcHotKey	= .ExtractShortCutFromLineContent(lcLineContent)
								lcSkipFor 	= .ExtractSkipForFromLineContent(lcLineContent)
								lcPicture 	= Fullpath(.ExtractPictureFromLineContent(lcLineContent))
								lcMessage	= .ExtractMessageFromLineContent(lcLineContent)
							Endwith

							Select ;
								Key, ;
								Popup ;
								From qMenu ;
								Where ;
								nID >= lnBeginID And nID <= lnEndID 			    And ;
								Alltrim(Menu)  == Alltrim(lcMenu)    	And ;
								Upper(Alltrim(Popup)) == Upper(Alltrim(lcPopup)) 		;
								Into Array aParent

							lcParent = aParent[1]
							lcLevel  = aParent[2]
							lcTree	 = This.GetTree(lcParent)

							Replace Key			With lcKey 				In qMenu
							Replace Parent		With lcParent 			In qMenu
							Replace UniqueID	With lcUniqueID 		In qMenu
							Replace objName		With "" 				In qMenu
							Replace Level		With lcLevel 			In qMenu
							Replace Text		With lcPrompt 			In qMenu
							Replace Popup		With "" 				In qMenu
							Replace Bar			With lnBarNumber 		In qMenu
							Replace Command		With "" 				In qMenu
							Replace HotKey		With lcHotKey 			In qMenu
							Replace SkipFor		With lcSkipFor 			In qMenu
							Replace Picture		With lcPicture 			In qMenu
							Replace Tree		With lcTree				In qMenu
							Replace Menu		With lcMenu 			In qMenu
							Replace Type		With This.MenuIdentity	In qMenu
							If This.MenuIdentity == This.RIGHT_PANEL
								Replace Group With This.nRightPanelCounter In qMenu
							Endif
							If This.MenuIdentity == This.SHORT_CUT
								Replace Group With This.nShortcutCounter In qMenu
							Endif
							Replace Tags 	With lcMessage 		In qMenu
							Replace Team 	With lcGroupName	In qMenu
							Replace TeamID 	With 0				In qMenu
* Group / Team
							If Len(lcPrompt) == _BAR_LEN And lcPrompt == _BAR_PROMPT
								Local lbBarIsButton As Boolean
								lbBarIsButton = (Getwordcount(lcTree, ",") = 1)
								If lbBarIsButton
									Local lcTeam As String, lnTeamID As Integer
									lcTeam = Strextract(lcMessage, "<group>", "</group>")
									If !Empty(lcTeam)
										Replace Team 	With lcTeam			In qMenu
										Replace isGroup With .T. 			In qMenu
										Replace TeamID 	With qMenu.nID		In qMenu

										lnTeamID = qMenu.nID
										Update qMenu ;
											Set Team 	= lcTeam,  ;
											TeamID 	= lnTeamID ;
											where ;
											GetWordCount(Tree, ",") = 1							And ;
											nID >= lnBeginID And nID <= lnEndID 			    And ;
											Alltrim(Menu) == Alltrim(lcMenu) 		And ;
											Upper(Alltrim(Team)) == Upper(Alltrim(lcGroupName)) And !isGroup
									Else
										Select qMenu
										Delete
									Endif
								Else
									Select qMenu
									Delete
								Endif
							Endif
						Case _ON_BAR $ Upper(lcLineContent) And _ACTIVATE_POPUP $ Upper(lcLineContent)
							Local ;
								lnBarNumber As Integer, ;
								lcParent 	As String, ;
								lcPopup 	As String

							With This
								lnBarNumber = Val(.ExtractBarNumberFromLineContent(lcLineContent))
								lcParent	= .ExtractOfAndActivateFromLineContent(lcLineContent)
								lcPopup 	= .ExtractPopupFromLineContent(lcLineContent)
							Endwith

							Update qMenu ;
								Set Popup = lcPopup ;
								Where ;
								nID >= lnBeginID And nID <= lnEndID 			And ;
								Alltrim(Menu) == Alltrim(lcMenu) 	And ;
								Bar = lnBarNumber 								And ;
								Upper(Alltrim(Level)) == Upper(Alltrim(lcParent))

						Case _ON_SELECTION_BAR $ Upper(lcLineContent)
							Local ;
								lnBarNumber As Integer, ;
								lcParent 	As String, ;
								lcCommand 	As String

							With This
								lnBarNumber = Val(.ExtractBarNumberFromLineContent(lcLineContent))
								lcParent	= .ExtractOfAndDoFromLineContent(lcLineContent)
								lcCommand 	= .ExtractCommandFromLineContent(lcLineContent)
							Endwith

							lcOnClick = Iif(Alltrim(GetWordNum(lcCommand, 1, "|")) = "COMMAND", Alltrim(GetWordNum(lcCommand, 2, "|")), "DO " + lcCommand)

*!*								Browse title "lnBeginID=>" + Alltrim(Str(lnBeginID)) + ", lnEndID=> " + Alltrim(Str(lnEndID)) + ;
*!*								", lcMenu=> " + lcMenu + ", lnBarNumber=> " + Alltrim(Str(lnBarNumber)) + ", lcLevel=> " + lcParent

							Update qMenu ;
								set Command = lcOnClick ;
								where ;
								nID >= lnBeginID And nID <= lnEndID 			And ;
								Alltrim(Menu) == Alltrim(lcMenu) 	And ;
								Bar = lnBarNumber 								And ;
								Alltrim(Level) == Alltrim(lcParent)

						Endcase
					Enddo
					This.UpdateNoGroupItems(lnBarCounter, lcMenu, lcGroupName, lnBeginID, lnEndID)
				Else
					Wait _FILE_NOT_OPENED Window Nowait
					lbReturn = .F.
				Endif
			Else
				Wait _FILE_NOT_FOUND + ": " + tcMenu Window Nowait
				lbReturn = .F.
			Endif
		Catch To loEx
			This.ShowMessageError(loEx, .T.)
		Finally
			=Fclose(lnHandle)
		Endtry
		Return lbReturn
	Endfunc
&& ======================================================================== &&
&& Evalúa la línea actual del fichero y la concatena en caso
&& de tener el caracter terminal (;)
&& ======================================================================== &&
	Function CheckPreviousLineAndLoop(tcLineContent As Memo, tcPreviousLine As Memo) As Boolean
		#Define _SEMICOLON	";"
		Local lbReturn As Boolean
		lbReturn = .F.
		If Right(Alltrim(tcLineContent), 1) == _SEMICOLON
			If Empty(tcPreviousLine)
				tcPreviousLine = This.ExtractSemicolonFromLineContent(tcLineContent)
			Else
				tcPreviousLine = tcPreviousLine + Space(1) + This.ExtractSemicolonFromLineContent(tcLineContent)
			Endif
			lbReturn = .T.
		Else
			If Not Empty(tcPreviousLine)
				tcLineContent  = tcPreviousLine + Space(1) + tcLineContent
				tcPreviousLine = ""
			Endif
		Endif
		Return lbReturn
	Endfunc
&& ======================================================================== &&
&& Devuelve la misma cadena pero sin el último caracter.
&& ======================================================================== &&
	Function ExtractSemicolonFromLineContent(tcLineContent As String) As String
		Return Substr(Alltrim(tcLineContent), 1, Len(Alltrim(tcLineContent)) - 1)
	Endfunc
&& ======================================================================== &&
&& Extrae el contenido entre PAD Y OF
&& ======================================================================== &&
	Function ExtractPadAndOfFromLineContent(tcLineContent As String) As String
		#Define _Pad 	"PAD" + Space(1)
		#ifnDef _OF
			#Define _OF "OF" + Space(1)
		#endif
		Return Alltrim(Upper(Strextract(tcLineContent, _Pad, _OF)))
	Endfunc
&& ======================================================================== &&
&& Extrae el contenido entre OF Y PROMPT
&& ======================================================================== &&
	Function ExtractOfAndPromptFromLineContent(tcLineContent As String) As String
		#ifnDef _OF
			#Define _OF "OF" + Space(1)
		#endif
		#Define _PROMPT "PROMPT" + Space(1)
		Return Alltrim(Upper(Strextract(tcLineContent, _OF, _PROMPT)))
	Endfunc
&& ======================================================================== &&
&& Extrae el contenido entre COMILLAS DOBLES (Solo la primera concurrencia)
&& ======================================================================== &&
	Function ExtractDoubleQuotesFromLineContent(tcLineContent As String) As String
		#Define _DOUBLE_QUOTE 	Chr(34)
		Return Strextract(tcLineContent, _DOUBLE_QUOTE, _DOUBLE_QUOTE, 1)
	Endfunc
&& ======================================================================== &&
&& Extrae el shortcut desde el contenido de la liea actual.
&& ======================================================================== &&
	Function ExtractShortCutFromLineContent(tcLineContent As String) As String
		#Define _KEY	"KEY" + Space(1)
		#Define _COLON	","
		Return Strextract(tcLineContent, _KEY, _COLON, 1)
	Endfunc
&& ======================================================================== &&
&& Extrae el contenido entre OF Y ACTIVATE
&& ======================================================================== &&
	Function ExtractOfAndActivateFromLineContent(tcLineContent As String) As String
*!*			#ifnDef _OF
*!*				#Define _OF "OF" + Space(1)
*!*			#endif
*!*			#Define _ACTIVATE "ACTIVATE" + Space(1)
*!*			Return Alltrim(Upper(Strextract(tcLineContent, _OF, _ACTIVATE)))
		Return Alltrim(Upper(GetWordNum(tcLineContent, 5, Space(1))))
	Endfunc
&& ======================================================================== &&
&& Extrae el submenú de la linea actual. (PopUp)
&& ======================================================================== &&
	Function ExtractPopupFromLineContent(tcLineContent As String) As String
		#Define _POPUP	"POPUP" + Space(1)
		Return Alltrim(Upper(Strextract(tcLineContent + _POPUP, _POPUP, _POPUP, 1)))
	Endfunc
&& ======================================================================== &&
&& Extrae el número de barra de la linea actual.
&& ======================================================================== &&
	Function ExtractBarNumberFromLineContent(tcLineContent As String) As Integer
		#Define _BAR	"BAR" + Space(1)
		#ifnDef _OF
			#Define _OF "OF" + Space(1)
		#endif
		Return Alltrim(Strextract(tcLineContent, _BAR, _OF))
	Endfunc
&& ======================================================================== &&
&& Extrae el SKIP FOR de la linea actual.
&& ======================================================================== &&
	Function ExtractSkipForFromLineContent(tcLineContent As String) As String
		#Define _FOR "FOR" + Space(1)

		#ifnDef _PICTURE
			#Define _PICTURE "PICTURE" + Space(1)
		#endif

		#ifnDef _CLOSE_TAG
			#Define _CLOSE_TAG "CLOSE_TAG"
		#endif
		#ifnDef _MESSAGE
			#Define _MESSAGE "MESSAGE" + Space(1)
		#endif

		Local lcSkipFor As String
		lcSkipFor = ""
		Do Case
		Case _PICTURE $ Upper(tcLineContent)
			lcSkipFor = Alltrim(Strextract(tcLineContent, _FOR, _PICTURE))
		Case _MESSAGE $ Upper(tcLineContent)
			lcSkipFor = Alltrim(Strextract(tcLineContent, _FOR, _MESSAGE))
		Otherwise
			lcSkipFor = Alltrim(Strextract(tcLineContent + _CLOSE_TAG, _FOR, _CLOSE_TAG))
		Endcase
		Return lcSkipFor
	Endfunc
&& ======================================================================== &&
&& Extrae el PICTURE de la linea actual.
&& ======================================================================== &&
	Function ExtractPictureFromLineContent(tcLineContent As String) As String
		#ifnDef _PICTURE
			#Define _PICTURE "PICTURE" + Space(1)
		#endif
		#ifnDef _CLOSE_TAG
			#Define _CLOSE_TAG "CLOSE_TAG"
		#endif
		#ifnDef _MESSAGE
			#Define _MESSAGE "MESSAGE" + Space(1)
		#endif
		Local lcPicture As String
		lcPicture = ""
		If _PICTURE $ Upper(tcLineContent)
			If _MESSAGE $ Upper(tcLineContent)
				lcPicture = Strtran(Alltrim(Strextract(tcLineContent, _PICTURE, _MESSAGE)), '"')
			Else
				lcPicture = Strtran(Alltrim(Strextract(tcLineContent + _CLOSE_TAG, _PICTURE, _CLOSE_TAG)), '"')
			Endif
		Endif
		Return lcPicture
	Endfunc
&& ======================================================================== &&
&& Extrae el tag MESSAGE de la linea actual.
&& ======================================================================== &&
	Function ExtractMessageFromLineContent(tcLineContent As String) As String
		#ifnDef _MESSAGE
			#Define _MESSAGE "MESSAGE" + Space(1)
		#endif
		#ifnDef _CLOSE_TAG
			#Define _CLOSE_TAG "CLOSE_TAG"
		#endif
		Local lcMessage As String
		lcMessage = ""
		If _MESSAGE $ Upper(tcLineContent)
			lcMessage = Alltrim(Strextract(tcLineContent + _CLOSE_TAG, _MESSAGE, _CLOSE_TAG))
		Endif
		Return lcMessage
	Endfunc
&& ======================================================================== &&
&& Extrae el contenido entre OF Y DO
&& ======================================================================== &&
	Function ExtractOfAndDoFromLineContent(tcLineContent As String) As String
*!*			#ifnDef _OF
*!*				#Define _OF "OF" + Space(1)
*!*			#endif
*!*			#ifnDef _DO
*!*				#Define _DO "DO" + Space(1)
*!*			#endif
*!*			Return Alltrim(Upper(Strextract(tcLineContent, _OF, _DO)))
		Return Alltrim(Upper(GetWordNum(tcLineContent, 6, Space(1))))
	Endfunc
&& ======================================================================== &&
&& Extrae desde el Tag proporcionado hasta EOF.
&& ======================================================================== &&
	Function ExtractContentFromTag(tcLineContent As String, tcTag As String) As String
		#ifnDef _CLOSE_TAG
			#Define _CLOSE_TAG "CLOSE_TAG"
		#endif
		Return Alltrim(Upper(Strextract(tcLineContent + _CLOSE_TAG, tcTag, _CLOSE_TAG)))
	Endfunc
&& ======================================================================== &&
&& Extrae el contenido entre DO e IN (Command / Do ProcedureName)
&& ======================================================================== &&
	Function ExtractCommandFromLineContent(tcLineContent As String) As String
		#ifnDef _DO
			#Define _DO "DO" + Space(1)
		#endif
		#Define _IN "IN" + Space(1)
		Local lcContent As String
		lcContent = ""
		If !'IN LOCFILE("' $ tcLineContent && ES COMMAND
			lcContent = "COMMAND | " + Alltrim(Substr(tcLineContent, At(Space(1), tcLineContent, 6)))
		Else && ES PROCEDURE
			lcContent = Alltrim(Strextract(tcLineContent, _DO, _IN))
		EndIf
		Return lcContent
	Endfunc
&& ======================================================================== &&
&& Obtiene el árbol genealógico de la barra actual.
&& ======================================================================== &&
	Function GetTree As String
		Lparameters tcParent As String
		#Define _CONTINUE	.T.
		Local nLoopCounter 	 As Integer, lcTree As String
		Dimension aTree(1) 	 As String
		Dimension aParent(2) As String
		nLoopCounter = 0
		lcTree		 = ""
		Do While _CONTINUE
			aParent[1] = ""
			aParent[2] = ""
			Select Alltrim(Str(nID)), Parent From qMenu Where Upper(Alltrim(Key)) == Upper(Alltrim(tcParent)) Into Array aParent
			If Alltrim(aParent[2]) == "id_0"
				nLoopCounter = nLoopCounter + 1
				Dimension aTree(nLoopCounter) As String
				aTree[nLoopCounter] = Alltrim(aParent[1])
				Exit
			Else
				nLoopCounter = nLoopCounter + 1
				Dimension aTree(nLoopCounter) As String
				aTree[nLoopCounter] = Alltrim(aParent[1])
				tcParent = aParent[2]
			Endif
		Enddo
* Ordenar el array
		For i = Alen(aTree) To 1 Step -1
			If Empty(lcTree)
				lcTree = aTree(i)
			Else
				lcTree = lcTree + "," + aTree(i)
			Endif
		Endfor
		Return lcTree
	Endfunc
&& ======================================================================== &&
&& Function UpdateNoGroupItems
&& ======================================================================== &&
	Function UpdateNoGroupItems As VOID
		Lparameters ;
			tnBarNumber 	As Integer	, ;
			tcMenu 			As String	, ;
			tcTeam 			As String	, ;
			tnBeginID 		As Integer	, ;
			tnEndID 		As Integer


		Local lcTeam As String, lcKey As String, lnTeamID As Integer, lcParent As String

		Select Distinct Getwordnum(Tree, 1, ",") As idTab From qMenu ;
			where ;
			GetWordCount(Tree, ",") = 1						And ;
			nID >= tnBeginID And nID <= tnEndID 			And ;
			Alltrim(Menu) == Alltrim(tcMenu) 	And ;
			Upper(Alltrim(Team)) == Upper(Alltrim(tcTeam)) Into Cursor qNoGroup

		If Reccount("qNoGroup") > 0
			Select qNoGroup
			Scan
				tnBarNumber = tnBarNumber + 1
				lcTeam = "Grupo " + Proper(tcMenu) + " # " + Alltrim(Str(tnBarNumber))
				Append Blank In qMenu
				lcKey    = "id_" + Alltrim(Str(qMenu.nID))
				lcParent = "id_" + Alltrim(qNoGroup.idTab)
				lnTeamID = qMenu.nID
				Replace Key		 	With lcKey 			In qMenu
				Replace Parent	 	With lcParent 		In qMenu
				Replace UniqueID 	With Sys(2015) 		In qMenu
				Replace objName		With "" 			In qMenu
				Replace Text		With lcTeam 		In qMenu
				Replace Popup		With "" 			In qMenu
				Replace Bar			With tnBarNumber 	In qMenu
				Replace Command		With "" 			In qMenu
				Replace HotKey		With "" 			In qMenu
				Replace SkipFor		With "" 			In qMenu
				Replace Picture		With "" 			In qMenu
				Replace Tree 		With qNoGroup.idTab In qMenu
				Replace Menu		With Upper(tcMenu) 	In qMenu
				Replace Type		With ""				In qMenu
				Replace Group 		With 0 				In qMenu
				Replace Tags 		With "" 			In qMenu
				Replace Team 		With lcTeam 		In qMenu
				Replace TeamID 		With lnTeamID		In qMenu
				Replace isGroup 	With .T. 			In qMenu

				Update qMenu ;
					set Team = lcTeam, ;
					TeamID = lnTeamID ;
					where ;
					GetWordCount(Tree, ",") = 1									 And ;
					!isGroup 													 And ;
					nID >= tnBeginID And nID <= tnEndID 						 And ;
					Alltrim(Menu) == Alltrim(tcMenu) 				 And ;
					Alltrim(Getwordnum(Tree, 1, ",")) == Alltrim(qNoGroup.idTab) And ;
					Upper(Alltrim(Team)) == Upper(Alltrim(tcTeam))
				Select qNoGroup
			Endscan
		Endif
		Use In (Select("qNoGroup"))
		Return
	Endfunc
&& ======================================================================== &&
&& SetPathTo
&& ======================================================================== &&
	Function SetPathTo As VOID
		Lparameters tcPath As String
		Local aFolders(1)

		This.GetDirTree(tcPath, @aFolders)
		For Each lcFolder In aFolders
			lcMacro = "Set Path To '" + lcFolder + "' Additive"
			&lcMacro
		Endfor
		Release aFolders
	Endfunc
&& ======================================================================== &&
&& GetDirTree
&& ======================================================================== &&
	Function GetDirTree As VOID
		Lparameters tcDir, aryParam
		lcCurDrive  = Justdrive(Fullpath(Curdir()))
		lcCurDir 	= Curdir()
		This.Recurse(tcDir, @aryParam)
		Try
			Chdir &lcCurDrive.&lcCurDir.
		Catch
		Endtry
	Endfunc
&& ======================================================================== &&
&& Function Recursive
&& ======================================================================== &&
	Hidden Function Recurse As VOID
		Lparameters pcDir, aryParam
		Local lnPtr, lnFileCount, laFileList, lcDir, lcFile

		Chdir (pcDir)
		nLen  = Alen(aryParam)
		If !Empty(aryParam(nLen))
			Dimension aryParam(nLen + 1)
			nLen = nLen + 1
		Endif
		aryParam(nLen) = Fullpath(Curdir())

		Dimension laFileList[1]

*--- Read the chosen directory.
		lnFileCount = Adir(laFileList, '*.*', 'D')
		For lnPtr = 1 To lnFileCount
			If 'D' $ laFileList[lnPtr, 5]
*--- Get directory name.
				lcDir = laFileList[lnPtr, 1]
*--- Ignore current and parent directory pointers.
				If lcDir != '.' And lcDir != '..'
*--- Call this routine again.
					This.Recurse(lcDir, @aryParam)
				Endif
			Endif
		Endfor
*--- Move back to parent directory.
		Chdir ..
	Endfunc
&& ======================================================================== &&
&& GetDirEx
&& ======================================================================== &&
	Function GetDirEx
		Lparameters cDialogTitle, cStartingFolder, nBrowseFlags
		If Type('cDialogTitle') # 'C'
			cDialogTitle = 'Please select a folder:'
		Endif
		If Type('cStartingFolder') # 'C'
			cStartingFolder = ''
		Endif
		If Type('nBrowseFlags') # 'N'
			nBrowseFlags = 32 + 16 + 1
		Endif
		Local oBrowseObject, cPathToReturn, oShellObj
		oShellObj 	  = Createobj('Shell.Application')
		cPathToReturn = ''
		oBrowseObject = oShellObj.BrowseForFolder(0, cDialogTitle, nBrowseFlags, cStartingFolder)
		If Type('oBrowseObject') = 'O' And ! Isnull(oBrowseObject)
			For Each Item In oBrowseObject.ParentFolder.Items
				If Item.Name == oBrowseObject.Title
					cPathToReturn = Item.Path
					Exit
				Endif
			Endfor
		Endif
		Store .Null. To oShellObj, oShellObj
		Release oShellObj, oShellObj
		Return cPathToReturn
	Endfunc
&& ======================================================================== &&
&& Function ShowMessageError
&& ======================================================================== &&
	Function ShowMessageError As VOID
		Lparameters toException As Exception, tbWait As Boolean
		Local lcMsg As Memo
		TEXT to lcMsg noshow pretext 7 textmerge
	 		ERROR:	<<Str(toException.ErrorNo)>>
			MENSAJE:	<<toException.Message>>
			LINEA:	<<Str(toException.Lineno)>>
			PROGRAMA:	<<toException.Procedure>>
		ENDTEXT
		If tbWait
			Wait lcMsg Window
		Else
			Wait lcMsg Window Nowait
		Endif
	Endfunc
Enddefine