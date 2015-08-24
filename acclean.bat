@ECHO OFF


REM Batch script to clean AccuRev external files
REM Volodymyr Morev

REM input parameters
rem echo %1
SET CLEAN_MODE=-x
IF /I "%1" EQU "/m" echo Implement cleaning of modified!
IF /I "%1" EQU "/a" echo Implement cleaning of all!
IF /I "%1" EQU "/x" SET CLEAN_MODE=-x

IF "%CLEAN_MODE%" EQU "-x" ECHO Mode: clean all externals
IF "%CLEAN_MODE%" EQU "-m" ECHO Mode: revert all modified

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
ACCUREV stat %CLEAN_MODE% -fla > "%TEMP_FILE%" 

SET /A NUM_FILES=0
FOR /f "delims=" %%i IN (%TEMP_FILE%) DO SET /A NUM_FILES+=1
ECHO Files to process: %NUM_FILES%

IF "%NUM_FILES%" equ "0" CALL :REPORT_ERROR "No files to process!" || GOTO :ERROR

rem subl %TEMP_FILE%

REM Sort AccuRev output
SORT /r "%TEMP_FILE%"

rem subl %TEMP_FILE%

REM Remove files
FOR /f "delims=" %%i IN (%TEMP_FILE%) DO IF exist "%%i" ( ERASE /f /q "%%i" )

REM Remove directories
FOR /f "delims=" %%i IN (%TEMP_FILE%) DO  IF exist "%%i\" ( RMDIR /q "%%i" ) 

REM Get list of lefovers from AccuRev
ACCUREV stat %CLEAN_MODE% -fla > "%TEMP_FILE%" 

SET /A NUM_FILES=0
FOR /f "delims=" %%i IN (%TEMP_FILE%) DO SET /A NUM_FILES+=1
ECHO Files to left: %NUM_FILES%


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
CALL :REMOVE_TEMP_FILE
EXIT /b 0
