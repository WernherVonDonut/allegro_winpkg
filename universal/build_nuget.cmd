setlocal
set root=%cd%

rem echo ***** 32-bit MSVC 2013 Build *****
rem set toolchain=-T v120_xp
rem set generator=-G "Visual Studio 12 2013"
rem set buildroot=%root%\nupkg\v120\win32
rem call :build_all
rem 
rem echo ***** 64-bit MSVC 2013 Build *****
rem set toolchain=-T v120_xp
rem set generator=-G "Visual Studio 12 2013 Win64"
rem set buildroot=%root%\nupkg\v120\x64
rem call :build_all

echo ***** 32-bit MSVC 2015 Build *****
set toolchain=-T v140_xp
set generator=-G "Visual Studio 14 2015"
set buildroot=%root%\nupkg\v140\win32
call :build_all

echo ***** 64-bit MSVC 2015 Build *****
set toolchain=-T v140_xp
set generator=-G "Visual Studio 14 2015 Win64"
set buildroot=%root%\nupkg\v140\x64
call :build_all

echo ***** 32-bit MSVC 2017 Build *****
set toolchain=-T v141_xp
set generator=-G "Visual Studio 15 2017"
set buildroot=%root%\nupkg\v141\win32
call :build_all

echo ***** 64-bit MSVC 2017 Build *****
set toolchain=-T v141_xp
set generator=-G "Visual Studio 15 2017 Win64"
set buildroot=%root%\nupkg\v141\x64
call :build_all

rem ***** Make NUGET Package *****
cd %root%
nuget pack Allegro.nuspec
nuget pack AllegroDeps.nuspec

endlocal
goto :EOF

:build_all
rem Build Allegro and the dependencies
rem **** Static dependencies **** 
set shared=no
call :makedeps
rem **** Static Monolith Allegro ****
set monolith=yes
set shared=no
set build_type=RelWithDebInfo
set static_runtime=yes
call :allegro
rem **** Dynamic Allegro ****
set monolith=no
set shared=yes
set build_type=RelWithDebInfo
set static_runtime=yes
call :allegro
rem **** Debug Allegro ****
set monolith=no
set shared=yes
set build_type=Debug
set static_runtime=no
call :allegro

goto :EOF

:allegro
rem Build Allegro
mkdir "%buildroot%\allegro"
echo ***** Building Allegro shared=%shared% *****
set args=%generator% %toolchain% -DCMAKE_PREFIX_PATH="%buildroot%\deps" -DCMAKE_INSTALL_PREFIX="%buildroot%"
set args=%args% -DWANT_MONOLITH=%monolith% -DSHARED=%shared% -DWANT_STATIC_RUNTIME=%static_runtime% -DCMAKE_BUILD_TYPE=%build_type%
set args=%args% -DWANT_EXAMPLES=off -DWANT_TESTS=off -DWANT_DEMO=off -DWANT_ACODEC_DYNAMIC_LOAD=off -DFLAC_STATIC=on -DFREETYPE_ZLIB=on -DFREETYPE_PNG=on
cd %buildroot%\allegro
cmake  %args% "%root%\allegro" || goto :error
cmake --build . --target INSTALL --config %build_type% || goto :error

goto :EOF

:makedeps

rem Build all the dependencies
set args=%generator% %toolchain% -DCMAKE_PREFIX_PATH="%buildroot%\deps" -DCMAKE_INSTALL_PREFIX="%buildroot%\deps"

call :makedep zlib-1.2.11
call :makedep physfs-2.0.3 "-DPHYSFS_BUILD_TEST=no"
call :makedep dumb-0.9.3
call :makedep libpng-1.6.30
call :makedep freetype-2.8 "-DWITH_HarfBuzz=OFF" "-DWITH_BZip2=OFF"
call :makedep libjpeg-turbo-1.5.2 "-DWITH_TURBOJPEG=false" "-DENABLE_SHARED=false"
call :makedep libogg-1.3.2
call :makedep libvorbis-1.3.5
call :makedep libtheora-1.1.1
call :makedep flac-1.3.2
call :makedep opus-1.2.1
call :makedep opusfile-0.8
goto :EOF

:makedep
set dep_name=%1
shift
echo ***** Building Dependency %dep_name% *****
mkdir "%buildroot%\%dep_name%"
cd %buildroot%\%dep_name%
cmake  %args% %* "%root%\%dep_name%"  || goto :error
cmake --build . --target INSTALL --config RelWithDebInfo  || goto :error
goto :EOF

:error
@echo Failed with error #%errorlevel%.
exit /b %errorlevel%
