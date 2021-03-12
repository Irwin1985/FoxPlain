Try
	=Removeproperty(_Screen, "cPath")
Catch
Endtry
=AddProperty(_Screen, "cPath", Justpath(Sys(16)))

Try
	=Removeproperty(_Screen, "aProjects")
Catch
Endtry
=AddProperty(_Screen, "aProjects[1]")

Try
	=Removeproperty(_Screen, "nProjects")
Catch
Endtry
=AddProperty(_Screen, "nProjects", 0)

Set Path To (_Screen.cPath) Additive

Set Procedure To "wxMsgBox" Additive
Set Procedure To "wxMisc" Additive
Set Procedure To "wxBuilder" Additive

Define Bar 2 Of _Msm_view Prompt "\-"
Define Bar 3 Of _Msm_view Prompt "New Ribbon Project"
Define Bar 4 Of _Msm_view Prompt "Open Ribbon Project"
Define Bar 5 Of _Msm_view Prompt "\-"
Define Bar 6 Of _Msm_view Prompt "About wxMenu"

On Selection Bar 3 Of _Msm_view Do wxNewProject
On Selection Bar 4 Of _Msm_view Do wxOpenProject
On Selection Bar 6 Of _Msm_view MessageBox("wxMenu v1.2.5" + Chr(13) + Chr(10) + ;
"Author: <Irwin Rodriguez> rodriguez.irwin@gmail.com" + Chr(13) + Chr(10) + ;
"Revision: 2020.08.15 16:18" + Chr(13) + Chr(10), 64, "About wxMenu")

&& ======================================================================== &&
&& Procedure wxNewProject
&& ======================================================================== &&
Procedure wxNewProject
	lcFile = Putfile("Enter Project", "Ribbon1.rpx", "RPX")
	If !Empty(lcFile)
		Set Default To Justpath(lcFile)
		Create Table (Justfname(lcFile)) (idmenu i Autoinc, mprfile c(100), layout i, Order i, execute L, Descrip c(100), imgfolder c(200))
		Use In(Select(Juststem(lcFile)))
		=OpenProject(lcFile)
	Endif
Endproc
&& ======================================================================== &&
&& Procedure wxOpenProject
&& ======================================================================== &&
Procedure wxOpenProject
	lcFile = Getfile("RPX", "Nombre", "Ok")
	If File(lcFile)
		If !ExiProject(lcFile)
			* Add Project to list.
			_Screen.nProjects = _Screen.nProjects + 1
			Dimension _Screen.aProjects(_Screen.nProjects)
			_Screen.aProjects[_Screen.nProjects] = lcFile
			* Check Project Structure
			Use (lcFile) Alias MyProj Exclusive In 0
			If Empty(Field("MPRFILE"))
				Alter Table MyProj Add Column mprfile c(100)
			Endif
			If Empty(Field("DESCRIP"))
				Alter Table MyProj Add Column Descrip c(100)
			Endif
			If Empty(Field("LAYOUT"))
				Alter Table MyProj Add Column layout i
			Endif
			If Empty(Field("ORDER"))
				Alter Table MyProj Add Column Order i
			Endif
			If Empty(Field("EXECUTE"))
				Alter Table MyProj Add Column execute l
			Endif
			If Empty(Field("IMGFOLDER"))
				Alter Table MyProj Add Column imgfolder c(200)
			Endif

			Use In (Select("MyProj"))

			=OpenProject(lcFile)
		EndIf
	Endif
Endproc
&& ======================================================================== &&
&& OpenProject
&& ======================================================================== &&
Procedure OpenProject
	Lparameters tcProject As String
	Do Form wxProjectManager With tcProject
EndProc
&& ======================================================================== &&
&& Function ExiProject
&& ======================================================================== &&
Function ExiProject (tcProject As String) As Boolean
	Local llFound As Boolean
	For i = 1 to Alen(_Screen.aProjects, 1)
		If Type("_Screen.aProjects[i]") = "C" and Lower(_Screen.aProjects[i]) == Lower(tcProject)
			llFound = .T.
			Exit
		EndIf
	EndFor
	Return llFound
EndFunc
