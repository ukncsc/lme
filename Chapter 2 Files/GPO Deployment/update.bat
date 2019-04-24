::@echo off
:: Credits: Credit to Ryan Watson (@gentlemanwatson) and Syspanda.com from which this script was adapted from.
:: Changed by @S0xbad1dea



::This doesn't work at the moment, because white spaces are put in the file. This corrupts the path for later usage
::(wmic computersystem get domain | findstr /v Domain | findstr /r /v "^$") > fqdn.txt
::set /p FQDN=<fqdn.txt
::echo %FQDN%

SET FQDN=<YOUR_DOMAIN>

::Change the SYSMONDIR if you want to,but it will also works on C:\Windows. If you put sysmon outside C:\Windows, it will copy itself there.
SET SYSMONDIR=C:\windows
SET SYSMONBIN=Sysmon64.exe
SET SYSMONCONF=sysmon.xml
SET SIGCHECK=sigcheck64.exe


SET GLBSYSMONBIN=\\%FQDN%\sysvol\%FQDN%\Sysmon\%SYSMONBIN%
SET GLBSYSMONCONFIG=\\%FQDN%\sysvol\%FQDN%\Sysmon\%SYSMONCONF%
SET GLBSIGCHECK=\\%FQDN%\sysvol\%FQDN%\Sysmon\%SIGCHECK%

IF Not EXIST %SYSMONDIR% (
mkdir %SYSMONDIR%
)
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
xcopy %GLBSYSMONBIN% %SYSMONDIR% /y
xcopy %GLBSYSMONCONFIG% %SYSMONDIR% /y
xcopy %GLBSIGCHECK% %SYSMONDIR% /y
chdir %SYSMONDIR%
%SYSMONBIN% -i %SYSMONCONF% -accepteula -h sha1,d5,sha256,imphash -n -l
sc config Sysmon64 start= auto
goto :checkversion



:: Check if sysmon64.exe matches the hash of the central version 
:checkversion
chdir %SYSMONDIR%
IF EXIST runningver.txt DEL /F runningver.txt
IF EXIST latestver.txt DEL /F latestver.txt
::Add additional check because of manual installed Sysmon. You can jump here if Sysmon was installed manually and running
IF NOT EXIST %SIGCHECK% (
xcopy %GLBSIGCHECK% %SYSMONDIR% /y)
(sigcheck64.exe -n -nobanner /accepteula %SYSMONBIN%) > %SYSMONDIR%\runningver.txt
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
IF EXIST runningconfver.txt DEL /F runningconfver.txt
IF EXIST latestconfver.txt DEL /F latestconfver.txt
if NOT EXIST %SIGCHECK% (
xcopy %GLBSIGCHECK% %SYSMONDIR% /y)
::Added -c for the comparison, enables us to compare hashes
(sigcheck64.exe -h -c -nobanner /accepteula %SYSMONCONF%) > %SYSMONDIR%\runningconfver.txt
(sigcheck64.exe -h -c -nobanner /accepteula %GLBSYSMONCONFIG%) > %SYSMONDIR%\latestconfver.txt
::Looks for the 11th token in the csv of sigcheck. This is the MD5 hash. 12th token is SHA1, 15th is SHA2
for /F "delims=, tokens=11" %%h in (runningconfver.txt) DO (set runningconfver=%%h)
for /F "delims=, tokens=11" %%h in (latestconfver.txt) DO (set latestconfver=%%h)
::The following commands are not usful because they are comparing only the first line, which includes the path of the checked file. And this is always not eqal.
::set /p runningconfver=<%SYSMONDIR%\runningconfver.txt
::set /p latestconfver=<%SYSMONDIR%\latestconfver.txt
If "%runningconfver%" NEQ "%latestconfver%" (
xcopy %GLBSYSMONCONFIG% %SYSMONDIR% /y
chdir %SYSMONDIR%
(%SYSMONBIN% -c %SYSMONCONF%)

)
EXIT /B 0

:uninstallsysmon
chdir %SYSMONDIR%
%SYSMONBIN% -u
goto installsysmon
