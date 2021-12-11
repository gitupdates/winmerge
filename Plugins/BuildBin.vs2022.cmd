cd /d "%~dp0"

setlocal
for /f "usebackq tokens=*" %%i in (`"%programfiles(x86)%\microsoft visual studio\installer\vswhere.exe" -version [17.0^,18.0^) -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do (
  set InstallDir=%%i
)
if exist "%InstallDir%\Common7\Tools\vsdevcmd.bat" (
  call "%InstallDir%\Common7\Tools\vsdevcmd.bat
)

if "%1" == "" (
  call :BuildBin || goto :eof
  call :BuildBin ARM64 || goto :eof
  call :BuildBin x64 || goto :eof
) else (
  call :BuildBin %1 || goto :eof
)

pushd WinMerge32BitPluginProxy
MSBuild WinMerge32BitPluginProxy.vs2022.sln /t:Rebuild /p:Configuration="Release" /p:Platform="Win32" || goto :eof
popd

endlocal

goto :eof

:BuildBin
set PLATFORM=%1
if "%1" == "" (
  set PLATFORM_VS=Win32
) else (
  set PLATFORM_VS=%1
)
if "%PLATFORM_VS%" == "Win32" (
  set PLATFORM_DIR=
) else (
  set PLATFORM_DIR=%PLATFORM_VS%
)

pushd src_VCPP
MSBuild VCPPPlugins.vs2022.sln /t:Rebuild /p:Configuration="Release" /p:Platform="%PLATFORM_VS%" || goto :eof
popd

mkdir dlls\%PLATFORM_DIR% 2> NUL
for /d %%d in (src_VCPP\*) do (
  copy %%d\%PLATFORM_DIR%\Release\*.dll dlls\%PLATFORM_DIR%
)

if exist "%SIGNBAT_PATH%" (
  call "%SIGNBAT_PATH%" %~dp0dlls\%PLATFORM_DIR%\*.dll
)

goto :eof
