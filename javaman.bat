@ECHO OFF

SETLOCAL ENABLEDELAYEDEXPANSION

SET /A debug=0

SET programPath="%~dp0"
SET listFileName="javalist.txt"
SET listFilePath="%programPath:"=%%listFileName:"=%"
SET javaFolderName="java"
SET javaFolderPath="%programPath:"=%%javaFolderName:"=%"
SET javaBinFolderName="bin"
SET javaBinFolderPath="%javaFolderPath:"=%\%javaBinFolderName:"=%"
SET javaExecName="java.exe"
SET javaExecPath="%javaBinFolderPath:"=%\%javaExecName:"=%"
SET javaExecNameWin="javaw.exe"
SET javaExecPathWin="%javaBinFolderPath:"=%\%javaExecNameWin:"=%"
SET setGlobalEnvVariables=

IF "%selfWrapped%"=="" (
	REM this is necessary so that we can use "exit" to terminate the batch file,
	REM and all subroutines, but not the original cmd.exe
	SET selfWrapped=true
	%ComSpec% /S /C ""%~0" %*"
	GOTO :EOF
)

CALL :checkPermissions
CALL :printVariables

IF /I "%1" EQU "/S" (
	CALL :loadJavaList
	CALL :setupJavaMan
) ELSE IF /I "%1" EQU "/A" (
	CALL :loadJavaList
	CALL :setAlias "%2"
	CALL :printStatus
) ELSE IF /I "%1" EQU "/L" (
	CALL :loadJavaList
	CALL :printJavaList
) ELSE (
	ECHO Java manager by bsv798@gmail.com
	ECHO Switches different versions of Java using environmental variables and directory junctions
	ECHO Usage:
	ECHO 	%0 /S - set up environment variables
	ECHO 	%0 /L - print entries from java list
	ECHO 	%0 /A [alias name or index] - print active alias or set new one
)

EXIT /B 0

:checkPermissions
	IF %debug% EQU 1 (
		ECHO Checking for administrative permissions
	)

	NET SESSION >NUL 2>&1

	SET /A isAdmin=0
	if %ERRORLEVEL% == 0 (
		SET /A isAdmin=1
	)

	IF %debug% EQU 1 (
		IF %isAdmin% EQU 1 (
			ECHO 	Administrative permissions are present

			ECHO:
		) else (
			ECHO 	Administrative permissions are absent

			ECHO:
		)
	)
EXIT /B 0

:printVariables
	IF %debug% EQU 1 (
		ECHO Variables:

		ECHO 	isAdmin=%isAdmin%
		ECHO 	programPath=%programPath%
		ECHO 	listFileName=%listFileName%
		ECHO 	listFilePath=%listFilePath%
		ECHO 	javaFolderName=%javaFolderName%
		ECHO 	javaFolderPath=%javaFolderPath%
		ECHO 	javaBinFolderName=%javaBinFolderName%
		ECHO 	javaBinFolderPath=%javaBinFolderPath%
		ECHO 	javaExecName=%javaExecName%
		ECHO 	javaExecPath=%javaExecPath%
		ECHO 	javaExecNameWin=%javaExecNameWin%
		ECHO 	javaExecPathWin=%javaExecPathWin%

		ECHO:
	)
EXIT /B 0

:loadJavaList
	IF %debug% EQU 1 (
		ECHO Loading java list from %listFilePath%:
	)

	IF NOT EXIST %listFilePath% (
		CALL :printErrorAndExit 1 "Java list file %listFilePath% does not exist. Please create one using format '[alias name] [path to java]'."
	)

	SET /A i=-1
	SET /A javaListLen=-1

	FOR /F "usebackq tokens=1,* delims=	 " %%j IN (%listFilePath%) DO (
		SET aliasLine=%%j
		SET pathLine=%%~fk
		IF "!pathLine:~-1!" EQU "\" SET pathLine=!pathLine:~0,-1!
		SET /A i=i+1
		SET javaList[!i!].alias=!aliasLine!
		SET javaList[!i!].path="!pathLine!"

		IF %debug% EQU 1 (
			ECHO 	javaList[!i!].alias=!aliasLine!
			ECHO 	javaList[!i!].path="!pathLine:"=!"
		)
	)

	SET /A javaListLen=i

	IF %debug% EQU 1 (
		SET /A i=i+1
		ECHO 	javaListLen=!i!

		ECHO:
	)
EXIT /B 0

:printJavaList
	IF %javaListLen% GEQ 0 (
		ECHO Java list entries:
		FOR /L %%i IN (0,1,%javaListLen%) DO (
			SET aliasLine=!javaList[%%i].alias:"=!
			SET pathLine=!javaList[%%i].path:"=!
			ECHO %%i	!aliasLine!	!pathLine!
		)
	) ELSE (
		ECHO Java list is empty
	)
EXIT /B 0

:setupJavaMan
	ECHO Setting up JavaMan

	IF %debug% EQU 1 (
		ECHO Cheching for wrong paths
	)
	SET /A foundWrongPath=0
	FOR /F "usebackq tokens=*" %%i IN (`WHERE %javaExecName% 2^>NUL`) DO (
		SET whereLine=%%~dpi
		IF "!whereLine:~-1!" EQU "\" SET whereLine=!whereLine:~0,-1!
		SET whereLineExe="!whereLine!\%javaExecName:"=%"
		SET whereLine="!whereLine!"

		IF /I %javaBinFolderPath% NEQ !whereLine! (
			SET /A foundWrongPath=foundWrongPath+1
			SET whereLineSystem=
			FOR /F "usebackq tokens=*" %%i IN (`ECHO !whereLineExe! ^| FINDSTR /I "%SystemRoot%"`) DO SET whereLineSystem=%%i

			IF "!whereLineSystem!" NEQ "" (
				ECHO Please remove !whereLineExe! by hand.
			) ELSE (
				ECHO Please remove !whereLine! from PATH by hand.
			)
		)
	)
	IF %foundWrongPath% GTR 0 (
		EXIT /B 1
	)

	IF %debug% EQU 1 (
		ECHO Updating JAVA_HOME
	)
	SETX JAVA_HOME %javaFolderPath% %setGlobalEnvVariables% >NUL
	CALL :printErrorAndExit %ERRORLEVEL% "Unable to set JAVA_HOME to %javaFolderPath%."

	IF %debug% EQU 1 (
		ECHO Updating PATH
	)
	SET /A foundInPath=0
	SET pathString=
	IF "%setGlobalEnvVariables%" NEQ "/M" (
		FOR /F "usebackq tokens=2,*" %%i IN (`REG QUERY "HKCU\Environment" /V PATH 2^>NUL`) DO SET pathString=%%j
	) ELSE (
		FOR /F "usebackq tokens=2,*" %%i IN (`REG QUERY "HKLM\System\CurrentControlSet\Control\Session Manager\Environment" /V PATH 2^>NUL`) DO SET pathString=%%j
	)
	CALL :printErrorAndExit %ERRORLEVEL% "Unable to read PATH."

	FOR %%i IN ("%pathString:;=";"%") DO (
		IF %debug% EQU 1 (
			ECHO 	Path env var entry=%%i
		)

		IF %foundInPath% EQU 0 (
			IF /I %%i EQU %javaBinFolderPath% (
				SET /A foundInPath=1
				GOTO :breakFor
			)
		)
	)
	:breakFor
	IF %foundInPath% EQU 0 (
		IF %debug% EQU 1 (
			ECHO Adding java folder to PATH
		)
		SETX PATH "%pathString%;%javaBinFolderPath:"=%" %setGlobalEnvVariables% >NUL
	)

	ECHO Done

	ECHO:
EXIT /B 0

:printStatus
	IF %debug% EQU 1 (
		ECHO Detrmining current alias
	)

	SET /A foundAlias=0
	FOR /L %%i IN (0,1,%javaListLen%) DO (
		SET aliasLine=!javaList[%%i].alias:"=!
		SET pathLine=!javaList[%%i].path:"=!
		SET pathString=
		FOR /F "usebackq tokens=3,*" %%i IN (`DIR %programPath% /AD ^| FINDSTR /C:"%javaFolderName:"=% [!pathLine!]"`) DO SET pathString=%%j

		IF %debug% EQU 1 (
			ECHO 	Scanning for alias "!aliasLine!" with path "!pathLine!".
		)

		IF /I "!pathString!" NEQ "" (
			SET /A foundAlias=1
			ECHO Using alias "!aliasLine!" with path "!pathLine!".
		)
	)
	IF %foundAlias% EQU 0 (
		ECHO Not using any alias.
	)

	IF %debug% EQU 1 (
		ECHO:
	)
EXIT /B 0

:setAlias
	IF %debug% EQU 1 (
		ECHO Setting alias for "%~1"
	)
	SET /A newIndex=%~1+0
	IF "%~1" NEQ "0" IF %newIndex% EQU 0 SET /A newIndex=-1
	IF %newIndex% GTR %javaListLen% SET /A newIndex=-1
	SET newAlias=%~1

	IF %newIndex% LSS 0 (
		FOR /L %%i IN (0,1,%javaListLen%) DO (
			SET aliasLine=!javaList[%%i].alias:"=!
			SET pathLine=!javaList[%%i].path:"=!
	
			IF "!aliasLine!" EQU "%newAlias%" (
				SET /A newIndex=%%i
			)
		)
	)

	IF %newIndex% GEQ 0 (
		SET newAlias=!javaList[%newIndex%].alias!
		SET newPath=!javaList[%newIndex%].path!
	)

	IF %debug% EQU 1 (
		ECHO 	newIndex=%newIndex%
		ECHO 	newAlias=%newAlias%
		ECHO 	newPath=%newPath%
	)

	IF DEFINED newPath (
		RMDIR %javaFolderPath% >NUL
		MKLINK /J %javaFolderPath% %newPath% >NUL

		SET explorerExecJavaCommand="%javaExecPathWin% -jar "^%%1" %%*"
		SET explorerExecJavaPath="HKCR\jarfile\shell\open\command"
		IF %isAdmin% EQU 1 (
			REG ADD !explorerExecJavaPath! /F /D !explorerExecJavaCommand! >NUL
		) ELSE (
			FOR /F "usebackq tokens=3,*" %%i IN (`REG QUERY !explorerExecJavaPath!`) DO SET explorerExecJavaCommandCurrent=%%j
			IF !explorerExecJavaCommand! NEQ "!explorerExecJavaCommandCurrent!" (
				ECHO Please set registry path !explorerExecJavaPath! default value to !explorerExecJavaCommand! if you want to enable execution of jar files from explorer.
			)
		)
	)

	IF %debug% EQU 1 (
		ECHO:
	)
EXIT /B 0

:printErrorAndExit
	SET errorCode=%~1
	SET errorMessage=%~2

	IF %errorCode% NEQ 0 (
		ECHO %errorMessage%
		ECHO Error code: %errorCode%

		GOTO :exit
	)
EXIT /B 0

:exit
EXIT %errorCode%
