@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion
REM ============================================================
REM Практическая работа 8. ЧАСТЬ 2: Аудит компьютера
REM ============================================================

set "REPORT_FILE=%~dp0pc_report.txt"
set "APPS_LIST=%TEMP%\apps_list.txt"

if exist "%REPORT_FILE%" del "%REPORT_FILE%"
if exist "%APPS_LIST%" del "%APPS_LIST%"

for /f "tokens=1-4 delims=/ " %%a in ('date /t') do set "CUR_DATE=%%a.%%b.%%c"
for /f "tokens=1-2 delims=: " %%a in ('time /t') do set "CUR_TIME=%%a:%%b"
call :log "============================================================"
call :log "Диагностика и аудит компьютера"
call :log "Дата: %CUR_DATE% Время: %CUR_TIME%"
call :log "============================================================"
call :log ""

REM --- 1. Операционная система ---
call :log "Операционная система:"
set "OS_INFO="
for /f "tokens=*" %%a in ('powershell -NoProfile -Command "(Get-CimInstance Win32_OperatingSystem).Caption" 2^>nul') do set "OS_INFO=%%a"
if not defined OS_INFO call :log "Не удалось получить данные об ОС." & goto :skip_os
call :log "Название: !OS_INFO!"
:skip_os
call :log ""

REM --- 2. Процессор ---
call :log "Процессор:"
set "CPU_INFO="
for /f "tokens=*" %%a in ('powershell -NoProfile -Command "(Get-CimInstance Win32_Processor).Name -replace '\(','[' -replace '\)',']'" 2^>nul') do set "CPU_INFO=%%a"
if not defined CPU_INFO call :log "Не удалось получить данные о процессоре." & goto :skip_cpu
call :log "!CPU_INFO!"
:skip_cpu
call :log ""

REM --- 3. Оперативная память ---
call :log "Оперативная память:"
set "RAM_INFO="
for /f "tokens=*" %%a in ('powershell -NoProfile -Command "$os = Get-CimInstance Win32_OperatingSystem; $t = [math]::Round($os.TotalVisibleMemorySize/1048576, 1); $f = [math]::Round($os.FreePhysicalMemory/1048576, 1); Write-Host ('Всего: ' + $t + ' ГБ, Свободно: ' + $f + ' ГБ')" 2^>nul') do set "RAM_INFO=%%a"
if not defined RAM_INFO call :log "Не удалось получить данные об оперативной памяти." & goto :skip_ram
call :log "!RAM_INFO!"
:skip_ram
call :log ""

REM --- 4. Диск C ---
call :log "Диск C:"
set "DISK_INFO="
for /f "tokens=*" %%a in ('powershell -NoProfile -Command "$d = Get-CimInstance Win32_LogicalDisk -Filter 'DeviceID=''C:'''; $t = [math]::Round($d.Size/1073741824, 1); $f = [math]::Round($d.FreeSpace/1073741824, 1); Write-Host ('Всего: ' + $t + ' ГБ, Свободно: ' + $f + ' ГБ')" 2^>nul') do set "DISK_INFO=%%a"
if not defined DISK_INFO call :log "Не удалось получить данные о диске C." & goto :skip_disk
call :log "!DISK_INFO!"
:skip_disk
call :log ""

REM --- 5. Сбор списка установленных программ ---
call :log "Сбор списка установленных программ (это может занять время)..."
for /f "tokens=2,*" %%a in ('reg query "HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall" /s /v DisplayName 2^>nul ^| findstr /i "DisplayName"') do (
    echo %%b>> "%APPS_LIST%"
)
for /f "tokens=2,*" %%a in ('reg query "HKLM\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" /s /v DisplayName 2^>nul ^| findstr /i "DisplayName"') do (
    echo %%b>> "%APPS_LIST%"
)

if not exist "%APPS_LIST%" call :log "Не удалось получить список программ." & goto :skip_apps
sort "%APPS_LIST%" /O "%APPS_LIST%"
call :log "Установленные программы сохранены в отчете."
:skip_apps
call :log ""

REM --- 6. Анализ: Базовое офисное ПО ---
call :log "============================================================"
call :log "РЕКОМЕНДАЦИИ: Отсутствующее базовое ПО"
call :log "============================================================"
set "MISSING_COUNT=0"
call :check_software "Офисный пакет" "Office LibreOffice OpenOffice МойОфис"
call :check_software "Браузер" "Chrome Firefox Edge Яндекс"
call :check_software "Чтение PDF" "Acrobat Foxit SumatraPDF"
call :check_software "Архиватор" "7-Zip WinRAR WinZip"
call :check_software "Антивирус" "Defender Kaspersky ESET Dr.Web"
if !MISSING_COUNT!==0 call :log "Все базовые категории ПО присутствуют."
call :log ""

REM --- 7. Анализ: Излишнее ПО ---
call :log "============================================================"
call :log "РЕКОМЕНДАЦИИ: Излишнее или потенциально нежелательное ПО"
call :log "Внимание: это рекомендация к проверке, а не к удалению!"
call :log "============================================================"
set "EXTRA_FOUND=0"
call :check_extra "Игровое ПО" "Steam Epic GOG Origin Ubisoft Battle.net Riot game gaming"
call :check_extra "Торрент-клиенты" "torrent uTorrent BitTorrent qBittorrent Vuze"
call :check_extra "Мессенджеры" "Discord Telegram WhatsApp Viber Skype"
call :check_extra "Развлечения и оформление" "Wallpaper Engine OBS Soundpad"
if !EXTRA_FOUND!==0 call :log "Излишнего ПО из черного списка не обнаружено."
call :log ""

REM --- Итоги ---
call :log "============================================================"
call :log "Работа завершена."
call :log "Отчёт сохранён по пути: %REPORT_FILE%"
call :log "============================================================"

if exist "%APPS_LIST%" del "%APPS_LIST%"

echo.
echo ==========================================
echo Скрипт завершен. Нажмите любую клавишу для выхода.
echo ==========================================
pause
exit /b

:log
if "%~1"=="" (
    echo.
    echo.>> "%REPORT_FILE%"
    exit /b
)
echo %~1
echo %~1>> "%REPORT_FILE%"
exit /b

:check_software
set "FOUND_NAME="
if not exist "%APPS_LIST%" goto :no_found_soft
for %%w in (%~2) do (
    for /f "tokens=*" %%a in ('type "%APPS_LIST%" ^| findstr /i "%%w"') do (
        if not defined FOUND_NAME set "FOUND_NAME=%%a"
    )
)
if not defined FOUND_NAME goto :no_found_soft
call :log "[OK] %~1: !FOUND_NAME!"
exit /b
:no_found_soft
call :log "[!] Не обнаружен(а) %~1. Рекомендуется установить."
set /a MISSING_COUNT+=1
exit /b

:check_extra
set "EXTRA_LIST="
if not exist "%APPS_LIST%" goto :no_found_extra
for %%w in (%~2) do (
    for /f "tokens=*" %%a in ('type "%APPS_LIST%" ^| findstr /i "%%w"') do (
        echo %%a | findstr /i /v "!EXTRA_LIST!" >nul
        if !errorlevel! equ 0 set "EXTRA_LIST=!EXTRA_LIST! %%a;"
    )
)
if not defined EXTRA_LIST goto :no_found_extra
call :log "[?] %~1 (подлежит проверке):"
call :log "    !EXTRA_LIST!"
set /a EXTRA_FOUND+=1
exit /b
:no_found_extra
call :log "[-] %~1: не обнаружено."
exit /b