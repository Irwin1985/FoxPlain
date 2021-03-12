try
	=removeproperty(_screen, "cPath")
catch
endtry
=addproperty(_screen, "cPath", justpath(sys(16)))

try
	=removeproperty(_screen, "aProjects")
catch
endtry
=addproperty(_screen, "aProjects[1]")

try
	=removeproperty(_screen, "nProjects")
catch
endtry
=addproperty(_screen, "nProjects", 0)

set path to (_screen.cPath) additive

set procedure to "fox_plain_msgbox" additive
set procedure to 'foxbin2prg' additive

define bar 2 of _msm_view prompt "\-"
define bar 3 of _msm_view prompt "New Project"
define bar 4 of _msm_view prompt "Open Project"
define bar 5 of _msm_view prompt "\-"
define bar 6 of _msm_view prompt "About FoxPlain"

on selection bar 3 of _msm_view do fox_plain_new_project
on selection bar 4 of _msm_view do fox_plain_open_project
on selection bar 6 of _msm_view messagebox("wxMenu v1.2.5" + chr(13) + chr(10) + ;
	"Author: <Irwin Rodriguez> rodriguez.irwin@gmail.com" + chr(13) + chr(10) + ;
	"Revision: 2020.08.15 16:18" + chr(13) + chr(10), 64, "About wxMenu")

&& ======================================================================== &&
&& Procedure fox_plain_new_project
&& ======================================================================== &&
procedure fox_plain_new_project
	lcFile = putfile("Enter Project", "Ribbon1.rpx", "RPX")
	if !empty(lcFile)
		set default to justpath(lcFile)
		create table (justfname(lcFile)) (idmenu i autoinc, mprfile c(100), layout i, order i, execute L, descrip c(100), imgfolder c(200))
		use in(select(juststem(lcFile)))
		=OpenProject(lcFile)
	endif
endproc
&& ======================================================================== &&
&& Procedure fox_plain_open_project
&& ======================================================================== &&
procedure fox_plain_open_project
	lcFile = getfile("RPX", "Nombre", "Ok")
	if file(lcFile)
		if !ExiProject(lcFile)
			* Add Project to list.
			_screen.nProjects = _screen.nProjects + 1
			dimension _screen.aProjects(_screen.nProjects)
			_screen.aProjects[_Screen.nProjects] = lcFile
			* Check Project Structure
			use (lcFile) alias MyProj exclusive in 0
			if empty(field("MPRFILE"))
				alter table MyProj add column mprfile c(100)
			endif
			if empty(field("DESCRIP"))
				alter table MyProj add column descrip c(100)
			endif
			if empty(field("LAYOUT"))
				alter table MyProj add column layout i
			endif
			if empty(field("ORDER"))
				alter table MyProj add column order i
			endif
			if empty(field("EXECUTE"))
				alter table MyProj add column execute L
			endif
			if empty(field("IMGFOLDER"))
				alter table MyProj add column imgfolder c(200)
			endif

			use in (select("MyProj"))

			=OpenProject(lcFile)
		endif
	endif
endproc
&& ======================================================================== &&
&& OpenProject
&& ======================================================================== &&
procedure OpenProject
	lparameters tcProject as string
	do form wxProjectManager with tcProject
endproc
&& ======================================================================== &&
&& Function ExiProject
&& ======================================================================== &&
function ExiProject (tcProject as string) as Boolean
	local llFound as Boolean
	for i = 1 to alen(_screen.aProjects, 1)
		if type("_Screen.aProjects[i]") = "C" and lower(_screen.aProjects[i]) == lower(tcProject)
			llFound = .t.
			exit
		endif
	endfor
	return llFound
endfunc
