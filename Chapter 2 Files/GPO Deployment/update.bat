@echo off
:: Credits: Credit to Ryan Watson (@gentlemanwatson) and Syspanda.com from which this script was adapted from.





(wmic computersystem get domain | findstr /v Domain | findstr /r /v "^$") > fqdn.txt
set /p FQDN=<fqdn.txt
echo %FQDN%

SET SYSMONDIR=C:\windows\sysmon
SET SYSMONBIN=Sysmon64.exe
SET SYSMONCONF=sysmon.xml
SET SIGCHECK=sigcheck64.exe


SET GLBSYSMONBIN=\\%FQDN%\sysvol\%FQDN%\Sysmon\%SYSMONBIN%
SET GLBSYSMONCONFIG=\\%FQDN%\sysvol\%FQDN%\Sysmon\%SYSMONCONF%
SET GLBSIGCHECK=\\%FQDN%\sysvol\%FQDN%\Sysmon\%SIGCHECK%


:: Is Sysmon running  
sc query "Sysmon64" | find "STATE" | find "RUNNING"
If "%ERRORLEVEL%" NEQ "0" (
:: No, lets try to start it
goto startsysmon
) ELSE (
:: Yes, Lets see if it needs updating
goto checkversion
)


:startsysmon
sc start Sysmon64
If "%ERRORLEVEL%" EQU "1060" (
:: Wont start, Lets install it
goto installsysmon
) ELSE (
:: Started, Lets see if it needs updating
goto checkversion
)


  
:installsysmon
IF Not EXIST %SYSMONDIR% (
mkdir %SYSMONDIR%
)
xcopy %GLBSYSMONBIN% %SYSMONDIR% /y
xcopy %GLBSYSMONCONFIG% %SYSMONDIR% /y
xcopy %GLBSIGCHECK% %SYSMONDIR% /y
chdir %SYSMONDIR%
%SYSMONBIN% -i %SYSMONCONFIG% -accepteula -h md5,sha256 -n -l
sc config Sysmon64 start= auto
goto :checkversion



:: Check if sysmon64.exe matches the hash of the central version 
:checkversion
chdir %SYSMONDIR%
IF EXIST *.txt DEL /F *.txt
(sigcheck64.exe -n -nobanner /accepteula Sysmon64.exe) > %SYSMONDIR%\runningver.txt
(sigcheck64.exe -n -nobanner /accepteula %GLBSYSMONBIN%) > %SYSMONDIR%\latestver.txt
set /p runningver=<%SYSMONDIR%\runningver.txt
set /p latestver=<%SYSMONDIR%\latestver.txt
echo Currently running sysmon : %runningver%
echo Latest sysmon is %latestver% located at %GLBSYSMONBIN%
If "%runningver%" NEQ "%latestver%" (
goto uninstallsysmon
) ELSE (
goto updateconfig
)

:updateconfig
chdir %SYSMONDIR%
IF EXIST *.txt DEL /F *.txt
(sigcheck64.exe -h -nobanner /accepteula sysmon.xml) > %SYSMONDIR%\runningconfver.txt
(sigcheck64.exe -h -nobanner /accepteula %GLBSYSMONCONFIG%) > %SYSMONDIR%\latestconfver.txt
set /p runningver=<%SYSMONDIR%\runningconfver.txt
set /p latestver=<%SYSMONDIR%\latestconfver.txt
If "%runningconfver%" NEQ "%latestconfver%" (
xcopy %GLBSYSMONCONFIG% %SYSMONCONFIG% /y
chdir %SYSMONDIR%
%SYSMONBIN% -c %SYSMONCONFIG%
EXIT /B 0

:uninstallsysmon
%SYSMONBIN% -u
goto installsysmon