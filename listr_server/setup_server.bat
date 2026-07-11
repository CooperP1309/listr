@echo off
setlocal EnableDelayedExpansion

:: --------------------------------------------------------------------
:: Windows cmd equivalent of setup_server.sh
:: --------------------------------------------------------------------

:: --- Require elevated (Administrator) shell, closest analog to EUID==0 ---
net session >nul 2>&1
if !errorlevel! neq 0 (
    echo Error: This script must be run as Administrator. 1>&2
    exit /b 1
)

:: --- Require mvn on PATH ---
where mvn >nul 2>&1
if !errorlevel! neq 0 (
    echo Error: Maven ^(mvn^) is not installed or not in PATH. 1>&2
    exit /b 1
)

:: --- Require docker on PATH ---
where docker >nul 2>&1
if !errorlevel! neq 0 (
    echo Error: Docker is not installed or not in PATH. 1>&2
    exit /b 1
)

cls
echo ---------Welcome to the LISTR Server Setup---------
echo.
echo.

:: --- JWT secret prompt (masked via PowerShell; loops until exactly 64 chars) ---
:jwt_loop
set "jwt_secret="
for /f "usebackq delims=" %%A in (`powershell -NoProfile -Command "$sec = Read-Host -AsSecureString 'Enter your JWT secret (must be 64 characters)'; $ptr=[Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec); [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)"`) do set "jwt_secret=%%A"
echo.

set "_s=!jwt_secret!"
set "_len=0"
:jwt_strlen
if not "!_s:~%_len%,1!"=="" (
    set /a _len+=1
    goto :jwt_strlen
)

if !_len! equ 64 goto :jwt_done
cls
echo ---------Welcome to the LISTR Server Setup---------
echo.
echo.
echo Error: Secret must be exactly 64 characters ^(you entered !_len!^) 1>&2
echo.
goto :jwt_loop
:jwt_done
echo.

:: --- DB password prompt + confirmation (masked via PowerShell) ---
:pwd_loop
set "db_password="
for /f "usebackq delims=" %%A in (`powershell -NoProfile -Command "$sec = Read-Host -AsSecureString 'Enter your database password'; $ptr=[Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec); [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)"`) do set "db_password=%%A"
echo.
set "db_password_confirm="
for /f "usebackq delims=" %%A in (`powershell -NoProfile -Command "$sec = Read-Host -AsSecureString 'Confirm your database password'; $ptr=[Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec); [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)"`) do set "db_password_confirm=%%A"
echo.

if "!db_password!"=="!db_password_confirm!" goto :pwd_done
cls
echo ---------Welcome to the LISTR Server Setup---------
echo.
echo.
echo Error: Passwords do not match, please try again. 1>&2
echo.
goto :pwd_loop
:pwd_done
echo.

:: --- Final confirmation before writing files ---
set /p "confirm=Are you sure you want to continue? (y/n): "
if /i "!confirm:~0,1!"=="y" (
    echo Proceeding...
) else if /i "!confirm:~0,1!"=="n" (
    echo Exiting...
    exit /b 1
) else (
    echo Invalid response
)
echo.

:: --- Write application.properties ---
if not exist "src\main\resources" mkdir "src\main\resources"

(
echo spring.application.name=listr
echo(
echo server.port=8005
echo(
echo # Database Configuration
echo spring.datasource.url=jdbc:mysql://localhost:3307/taskdb?serverTimezone=UTC^&allowPublicKeyRetrieval=true^&useSSL=false
echo spring.datasource.username=root
echo spring.datasource.password=!db_password!
echo(
echo ## Hibernate properties
echo spring.jpa.hibernate.ddl-auto=update
echo spring.jpa.open-in-view=false
echo(
echo # JWT Configuration
echo security.jwt.secret-key=!jwt_secret!
echo # 1h in millisecond
echo security.jwt.expiration-time=3600000
) > "src\main\resources\application.properties"

:: --- Optional MySQL Docker container deployment ---
echo A MySQL Docker container is about to be deployed on port 3307.
set /p "deploy_confirm=Would you like to proceed? (y/n): "
if /i "!deploy_confirm:~0,1!"=="y" (
    docker run -d -e MYSQL_ROOT_PASSWORD="!db_password!" -e MYSQL_DATABASE=taskdb --name mysqldb -p 3307:3306 mysql:8.0
) else if /i "!deploy_confirm:~0,1!"=="n" (
    echo Skipping MySQL deployment.
) else (
    echo Invalid response, skipping MySQL deployment.
)

cls
echo.
echo ---------Setup Complete---------
echo To start the server, run the following command:
echo.
echo mvn spring-boot:run

endlocal
