@echo off
setlocal enabledelayedexpansion

:: --- SETTINGS ---
:: use BARWIDTH 300 to create a sample that has less than 1% with R103 filter but more than 1% without filter
:: use BARWIDTH 105 to create a sample that is just slightly above 1% with R103 filter 
set "BARWIDTH=300"
set "HEIGHT=1080"
set "FPS=25"
set "FRAMES=25"
set "V_CODEC=v210"
set "OUTPUT=c:\temp\8b_2.mov"

:: --- 8-BIT VALUES ---
set PIXFMT=yuv422p
set OUTPUT_PIXFMT=uyvy422
set LUM_WHITE=235
set LUM_BLACK=16
set CHROMA=128
set LIMITER_MIN=10
set LIMITER_MAX=245

REM REM :: 10-BIT VALUES
REM set "PIXFMT=yuv422p10"
REM set "OUTPUT_PIXFMT=yuv422p10"
REM set "LUM_WHITE=940"
REM set "LUM_BLACK=64"
REM set "CHROMA=512"
REM set "LIMITER_MIN=20"
REM set "LIMITER_MAX=984"

:: --- GENERATION ---
echo [1/3] Generating Uncompressed Test Signal to %OUTPUT%...
ffmpeg -f lavfi -i "color=c=gray:s=%BARWIDTH%x%HEIGHT%:d=2:r=%FPS%,format=%PIXFMT%,geq=lum=%LUM_WHITE%:cb=%CHROMA%:cr=%CHROMA%,split[w1][w2];color=c=gray:s=%BARWIDTH%x%HEIGHT%:d=2:r=%FPS%,format=%PIXFMT%,geq=lum=%LUM_BLACK%:cb=%CHROMA%:cr=%CHROMA%,split[b1][b2];[w1][b1]hstack[p1];[w2][b2]hstack[p2];[p1][p2]hstack[p32];[p32]split[a][b];[a][b]hstack[p64];[p64]split[c][d];[c][d]hstack[p128];[p128]split[e][f];[e][f]hstack[p256];[p256]split[g][h];[g][h]hstack[p512];[p512]split[i][j];[i][j]hstack[p1024];[p1024]split[k][l];[k][l]hstack[bars];[bars]crop=1920:1080,scale=1918:1080:flags=spline,scale=1920:1080:flags=spline,limiter=min=%LIMITER_MIN%:max=%LIMITER_MAX%,format=%OUTPUT_PIXFMT%" -frames:v %FRAMES% -c:v %V_CODEC% "%OUTPUT%" -y -loglevel error

echo.
:: --- ANALYSIS 1: RAW ---
echo [2/3] Analyzing RAW Signal (No Filter)...
set "VF_RAW=signalstats=stat=brng,metadata=mode=print"
call :AnalyzeSignal "%VF_RAW%"
set "RES_RAW=%ERRORLEVEL%"

echo.
:: --- ANALYSIS 2: EBU R103 ---
echo [3/3] Analyzing with EBU R103 Convolution Filter...
set "R103_KERNEL=0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 2 3 4 3 2 1 2 4 6 8 6 4 2 1 2 3 4 3 2 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0"
set "VF_R103=convolution='%R103_KERNEL%':'%R103_KERNEL%':'%R103_KERNEL%':'%R103_KERNEL%':0.015625:0.015625:0.015625:0.015625,signalstats=stat=brng,metadata=mode=print"
call :AnalyzeSignal "%VF_R103%"
set "RES_R103=%ERRORLEVEL%"

echo.
echo ---------------------------------------
echo Result for: %OUTPUT%
if %RES_RAW% NEQ 0 (echo RAW SIGNAL:      FAILED) else (echo RAW SIGNAL:      PASSED)
if %RES_R103% NEQ 0 (echo R103 FILTERED: FAILED) else (echo R103 FILTERED: PASSED)
echo ---------------------------------------

pause
exit /b


:: --- FUNCTION: ANALYZE SIGNAL ---
::executes ffmpeg with specified vf 
:AnalyzeSignal
set "FILTER=%~1"
ffmpeg -i "%OUTPUT%" -vf "%FILTER%" -f null - 2>&1 | powershell -command ^
    "$limit = 0.01;" ^
    "$violations = 0;" ^
    "$currentFrame = 0;" ^
    "$input | ForEach-Object {" ^
        "if ($_ -match 'BRNG=([\d.]+)') {" ^
            "$val = [float]$matches[1];" ^
            "if ($val -gt $limit) {" ^
                "$percent = [Math]::Round(($val * 100), 4);" ^
                "Write-Host ('  - Violation at Frame: ' + $currentFrame + ' (Value: ' + $percent + '%%)') -ForegroundColor Yellow;" ^
                "$violations++;" ^
            "}" ^
            "$currentFrame++;" ^
        "}" ^
    "};" ^
    "if ($violations -gt 0) {" ^
        "Write-Host ' ';" ^
        "Write-Host ('  TOTAL DETECTED: ' + $violations + ' illegal frames.') -ForegroundColor Red;" ^
        "exit 1;" ^
    "} else {" ^
        "Write-Host '  RESULT: No violations detected.' -ForegroundColor Green;" ^
        "exit 0;" ^
    "}"
exit /b %ERRORLEVEL%