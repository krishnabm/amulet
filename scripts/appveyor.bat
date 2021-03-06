call "%VS140COMNTOOLS%vsvars32.bat"
set PATH=C:\emscripten;C:\MinGW\bin;C:\MinGW\msys\1.0\bin;"C:\Program Files (x86)\Inno Setup 5";%PATH%

if "%APPVEYOR_REPO_TAG_NAME:~-15%" == "-distro-trigger" goto builddistro

curl -L -O https://s3.amazonaws.com/mozilla-games/emscripten/releases/emsdk-1.35.0-full-64bit.exe
emsdk-1.35.0-full-64bit.exe /S /D=C:\emscripten
call "C:\emscripten\emsdk_env.bat"
make TARGET=html.release LUAVM=lua51
if %errorlevel% neq 0 exit /b %errorlevel%
make TARGET=msvc32.release LUAVM=lua51 test
make TARGET=msvc32.release LUAVM=luajit test
if %errorlevel% neq 0 exit /b %errorlevel%
if defined APPVEYOR_REPO_TAG_NAME (node scripts\upload_builds.js %APPVEYOR_REPO_TAG_NAME%)
if %errorlevel% neq 0 exit /b %errorlevel%
goto end

:builddistro
set TAG=%APPVEYOR_REPO_TAG_NAME:~0,-15%
choco install -y InnoSetup
curl -L -O https://github.com/ianmaclarty/amulet/releases/download/%TAG%/builds-darwin.zip
curl -L -O https://github.com/ianmaclarty/amulet/releases/download/%TAG%/builds-win32.zip
curl -L -O https://github.com/ianmaclarty/amulet/releases/download/%TAG%/builds-linux.zip
unzip builds-darwin.zip
unzip builds-win32.zip
unzip builds-linux.zip
mkdir scripts\installer-payload
cp -r builds scripts/installer-payload/
cp -r builds/msvc32/luajit/release/bin/* scripts/installer-payload/
mv scripts/installer-payload/amulet.exe scripts/installer-payload/amulet-window.exe
mv scripts/installer-payload/amulet-console.exe scripts/installer-payload/amulet.exe
cp -r examples scripts/installer-payload/
cp scripts/icon.ico scripts/installer-payload/
cp scripts/amulet_env.bat scripts/installer-payload/
iscc /DVERSION=%TAG% /O. /Famulet-%TAG%-windows scripts\installer.iss
if %errorlevel% neq 0 exit /b %errorlevel%
mv scripts/installer-payload amulet-%TAG%
zip -r amulet-%TAG%-windows.zip amulet-%TAG%
node scripts\upload_distros.js %TAG% amulet-%TAG%-windows.exe amulet-%TAG%-windows.zip
if %errorlevel% neq 0 exit /b %errorlevel%

:end
