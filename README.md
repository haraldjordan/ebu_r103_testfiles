
The purpose of these files is to test if measuring equipment is correctly applying EBU R103 out of gamut measurement, especially if the Filter suggested in R103 is being applied correctly.
The Files 8b_2.mov and 10b_2.mov are uncompressed versions of images that trigger out of gamut errors when measured without filter (see Cite)
as defined in EBU R103 2020. 
It was verified that:
	1) without filter: the ffmpeg measured brng output matches 100% the one from professional QC software
	2) with convolution filter: the ffmpeg convolution filter in combination with brng measurement matches about 99.5% the result from professional qc software
	

Cite: Video Signal Filtering
		To remove transient over- and under-excursions of the signals, and to minimise the effect of high
		frequency noise on the colour gamut measurements, the use of appropriate filters in all measurement
		channels is recommended.
	  For interlaced and progressive signals a quarter band filter applied horizontally and a half band filter applied vertically is recommended.
		Horizontal Filter Coefficients: 1/16, 2/16, 3/16, 4/16, 3/16, 2/16, 1/16
		Vertical Filter Coefficients: 1/4, 1/2, 1/4 (Note: this is applied intra field2 for interlace signals).
		
GOOD 8bit files:
8b_2.mov: 1.04167% pixels out of gamut (without filter), 0% pixels out of gamut (with filter)

GOOD 10bit files:
10b_2.mov: 1.68046% pixels out of gamut (without filter), 10b_2.mov: BRNG=0.2432% pixels out of gamut (with filter)

GOOD: All encoded versions show slightly different values but still over 1% gamut errors when measured without filter

BAD 8bit files:


BAD 10bit files:
10b_bad.mov: 4.32292% pixels out of gamut (without filter), 1.04167% pixels out of gamut (with filter)

BAD: BEWARE, only the XAVC encoded variant still violates R103, prores and xdcam have less than 1% gamut errors after encoding



:: CONTENTS OF ORIGINAL CREATEANDANALYZE.BAT

setlocal

set BARWIDTH=300
set HEIGHT=1080
set DURATION_WHITE=1
set DURATION_BLACK=1
set FPS=25
set FRAMES=25
set CROP_WIDTH=1920
set CROP_HEIGHT=1080
set SCALE_DOWN_WIDTH=1918
set SCALE_UP_WIDTH=1920
set V_CODEC=rawvideo 
set OUTPUT=c:\temp\8b_2.mov

:: --- 8-BIT VALUES ---
set PIXFMT=yuv422p
set OUTPUT_PIXFMT=uyvy422
set LUM_WHITE=235
set LUM_BLACK=16
set CHROMA=128
set LIMITER_MIN=10
set LIMITER_MAX=245

:: --- 10-BIT VALUES ---
REM set PIXFMT=yuv422p10
REM set OUTPUT_PIXFMT=yuv422p10
REM set LUM_WHITE=940
REM set LUM_BLACK=64
REM set CHROMA=512
REM set LIMITER_MIN=20
REM set LIMITER_MAX=984




::UNCOMPRESSED - Generates many black/white bars, and applies a resize in order to trigger overshoots
ffmpeg -f lavfi -i "color=c=gray:s=%BARWIDTH%x%HEIGHT%:d=%DURATION_WHITE%:r=%FPS%,format=%PIXFMT%,geq=lum=%LUM_WHITE%:cb=%CHROMA%:cr=%CHROMA%,split[w1][w2];color=c=gray:s=%BARWIDTH%x%HEIGHT%:d=%DURATION_BLACK%:r=%FPS%,format=%PIXFMT%,geq=lum=%LUM_BLACK%:cb=%CHROMA%:cr=%CHROMA%,split[b1][b2];[w1][b1]hstack[p1];[w2][b2]hstack[p2];[p1][p2]hstack[p32];[p32]split[a][b];[a][b]hstack[p64];[p64]split[c][d];[c][d]hstack[p128];[p128]split[e][f];[e][f]hstack[p256];[p256]split[g][h];[g][h]hstack[p512];[p512]split[i][j];[i][j]hstack[p1024];[p1024]split[k][l];[k][l]hstack[bars];[bars]crop=%CROP_WIDTH%:%CROP_HEIGHT%,scale=%SCALE_DOWN_WIDTH%:%HEIGHT%:flags=spline,scale=%SCALE_UP_WIDTH%:%HEIGHT%:flags=spline,limiter=min=%LIMITER_MIN%:max=%LIMITER_MAX%,format=%OUTPUT_PIXFMT%" -frames:v %FRAMES% -c:v %V_CODEC% "%OUTPUT%" -y

::measure without EBU r103 convolution
ffmpeg -i %OUTPUT% -vf "signalstats=stat=brng,metadata=mode=print" -f null - 2>&1 |findstr BRNG 2>&1

::measure with EBU r103 convolution
ffmpeg -i %OUTPUT% -vf "convolution=0m='0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 2 3 4 3 2 1 2 4 6 8 6 4 2 1 2 3 4 3 2 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0':1m='0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 2 3 4 3 2 1 2 4 6 8 6 4 2 1 2 3 4 3 2 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0':2m='0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 2 3 4 3 2 1 2 4 6 8 6 4 2 1 2 3 4 3 2 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0':3m='0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 2 3 4 3 2 1 2 4 6 8 6 4 2 1 2 3 4 3 2 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0':0rdiv=0.015625:1rdiv=0.015625:2rdiv=0.015625:3rdiv=0.015625,signalstats=stat=brng,metadata=mode=print" -f null - 2>&1 | findstr BRNG

