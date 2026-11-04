@echo off
chcp 65001 >nul
REM ============================================================
REM Практическая работа: Диагностика клиентского компьютера
REM Студент: Харитонова
REM Дата: 04.11.2026
REM ============================================================

set "REPORT_FILE=%~dp0pc_report.txt"

REM --- Заголовок ---
echo Диагностика компьютера
echo ============================================================
echo.

REM --- 1. Сведения об операционной системе ---
echo Операционная система:
powershell -NoProfile -Command "Get-CimInstance Win32_OperatingSystem | ForEach-Object { 'Название: ' + $_.Caption; 'Версия: ' + $_.Version }"
echo.
REM --- 2. Сведения о процессоре ---
echo Процессор:
for /f "usebackq tokens=*" %%a in (`powershell -NoProfile -Command "(Get-CimInstance Win32_Processor).Name"`) do (
    echo %%a
)
echo.
REM --- 3. Сведения об оперативной памяти ---
echo Память:
for /f "usebackq tokens=*" %%a in (`powershell -NoProfile -Command "[int]((Get-CimInstance Win32_OperatingSystem).TotalVisibleMemorySize / 1048576)"`) do set "TOTAL_GB=%%a"
for /f "usebackq tokens=*" %%a in (`powershell -NoProfile -Command "[int]((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1048576)"`) do set "FREE_GB=%%a"
echo Всего памяти: %TOTAL_GB% ГБ
echo Свободно памяти: %FREE_GB% ГБ
echo.
REM --- 4. Свободное место на диске C ---
echo Диск C:
REM Используем Get-Volume (работает в новых Windows без wmic)
for /f "usebackq tokens=*" %%a in (`powershell -NoProfile -Command "[int]((Get-Volume -DriveLetter C).Size / 1073741824)"`) do set "DISK_TOTAL_GB=%%a"
for /f "usebackq tokens=*" %%a in (`powershell -NoProfile -Command "[int]((Get-Volume -DriveLetter C).SizeRemaining / 1073741824)"`) do set "DISK_FREE_GB=%%a"
echo Всего места: %DISK_TOTAL_GB% ГБ
echo Свободно места: %DISK_FREE_GB% ГБ
echo.
REM --- 5. Список установленных программ ---
echo Установленные программы:
echo Идёт поиск программ, это может занять несколько минут...

set "TEMP_PROGS=%~dp0temp_progs.txt"
type nul > "%TEMP_PROGS%"

for /f "tokens=2,*" %%a in ('reg query "HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall" /s /v DisplayName 2^>nul ^| findstr /i "DisplayName"') do (
    echo %%b >> "%TEMP_PROGS%"
)
for /f "tokens=2,*" %%a in ('reg query "HKLM\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" /s /v DisplayName 2^>nul ^| findstr /i "DisplayName"') do (
    echo %%b >> "%TEMP_PROGS%"
)

type "%TEMP_PROGS%"

echo.
echo ============================================================
echo Отчёт сохранён в файл: %REPORT_FILE%

REM ============================================================
REM ЗАПИСЬ ВСЕГО ОТЧЕТА В ФАЙЛ
REM ============================================================
(
echo Диагностика компьютера
echo ============================================================
echo.
echo Операционная система:
powershell -NoProfile -Command "Get-CimInstance Win32_OperatingSystem | ForEach-Object { 'Название: ' + $_.Caption; 'Версия: ' + $_.Version }"
echo.
echo Процессор:
powershell -NoProfile -Command "(Get-CimInstance Win32_Processor).Name"
echo.
echo Память:
echo Всего памяти: %TOTAL_GB% ГБ
echo Свободно памяти: %FREE_GB% ГБ
echo.
echo Диск C:
echo Всего места: %DISK_TOTAL_GB% ГБ
echo Свободно места: %DISK_FREE_GB% ГБ
echo.
echo Установленные программы:
type "%TEMP_PROGS%"
echo.
echo Отчёт сохранён
) > "%REPORT_FILE%"

del "%TEMP_PROGS%"
pause