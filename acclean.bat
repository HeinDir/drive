@ECHO OFF


REM Batch script to clean AccuRev external files
REM Volodymyr Morev

REM input parameters
rem echo %1
SET CLEAN_MODE=-x
IF /I "%1" EQU "/c" SET ONLY_COUNT=YES
IF /I "%2" EQU "/c" SET ONLY_COUNT=YES
IF /I "%1" EQU "/x" SET CLEAN_MODE=-x
IF /I "%2" EQU "/x" SET CLEAN_MODE=-x
IF /I "%1" EQU "/m" SET CLEAN_MODE=-m
IF /I "%2" EQU "/m" SET CLEAN_MODE=-m

SET MODE_MESSAGE=Mode:

IF /I "%ONLY_COUNT%" EQU "YES" (SET MODE_MESSAGE=%MODE_MESSAGE% Count all) ELSE (SET MODE_MESSAGE=%MODE_MESSAGE% Remove all)
IF /I "%CLEAN_MODE%" EQU "-x" (SET MODE_MESSAGE=%MODE_MESSAGE% externals)
IF /I "%CLEAN_MODE%" EQU "-m" (SET MODE_MESSAGE=%MODE_MESSAGE% modified)

ECHO %MODE_MESSAGE%

REM Set path format according to selected Mode
SET PATH_FORMAT=-fla
IF /I "%CLEAN_MODE%" EQU "-x" (SET PATH_FORMAT=-fla)
IF /I "%CLEAN_MODE%" EQU "-m" (SET PATH_FORMAT=-fl)


REM Generating date and time string for unique file name
REM See http://stackoverflow.com/q/1642677/1143274

FOR /f %%a IN ('WMIC OS GET LocalDateTime ^| FIND "."') DO SET DTS=%%a
SET DATE_TIME_STRING=%DTS:~0,4%-%DTS:~4,2%-%DTS:~6,2%_%DTS:~8,2%-%DTS:~10,2%-%DTS:~12,2%
SET TEMP_FILE=%TEMP%\ACCLEAN_%DATE_TIME_STRING%.tmp

REM Create temp file
IF exist "%TEMP_FILE%" GOTO :REPORT_ERROR "Temp file already exist!" ||  GOTO :ERROR

COPY NULL > "%TEMP_FILE%"
IF not exist "%TEMP_FILE%" GOTO :REPORT_ERROR "Temp file cannot be created!" || GOTO :ERROR
ECHO Temp file: %TEMP_FILE%

REM Get list of files from AccuRev
ACCUREV stat %CLEAN_MODE% %PATH_FORMAT% > "%TEMP_FILE%"

SET /A NUM_FILES=0
FOR /f "delims=" %%i IN (%TEMP_FILE%) DO SET /A NUM_FILES+=1
ECHO Files to process: %NUM_FILES%

IF /I "%ONLY_COUNT%" EQU "YES" GOTO :END

IF "%NUM_FILES%" equ "0" CALL :REPORT_ERROR "No files to process!" || GOTO :ERROR

rem subl %TEMP_FILE%

IF /I %CLEAN_MODE% EQU "-m" GOTO :MODIFIED

REM Sort AccuRev output
SORT /r "%TEMP_FILE%" /o "%TEMP_FILE%"

rem subl %TEMP_FILE%

REM Remove offending attributes
FOR /f "delims=" %%i IN (%TEMP_FILE%) DO  ATTRIB -r -s -h -a "%%i"

REM Remove files
FOR /f "delims=" %%i IN (%TEMP_FILE%) DO IF exist "%%i" ( ERASE /f /q "%%i" )

REM Remove directories
FOR /f "delims=" %%i IN (%TEMP_FILE%) DO  IF exist "%%i\" ( RMDIR /q "%%i" ) 

GOTO :FINISH

:MODIFIED

REM Use AccuRev Purge to remove modified
ACCUREV purge -l %TEMP_FILE%

:FINISH

REM Get list of lefovers from AccuRev
ACCUREV stat %CLEAN_MODE% %PATH_FORMAT% > "%TEMP_FILE%"

SET /A NUM_FILES=0
FOR /f "delims=" %%i IN (%TEMP_FILE%) DO SET /A NUM_FILES+=1
ECHO Files left: %NUM_FILES%


GOTO :END

:REPORT_ERROR
echo An error happened. Reason: %1
EXIT /b 1

:REMOVE_TEMP_FILE
IF exist "%TEMP_FILE%" ERASE /f /q "%TEMP_FILE%"
EXIT /b 0

:ERROR
CALL :REMOVE_TEMP_FILE
EXIT /b 1

:END
rem CALL :REMOVE_TEMP_FILE
EXIT /b 0
