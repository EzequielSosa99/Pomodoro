# Script para incrementar la versión y generar el .aab para Google Play Console
# Uso: .\build_release.ps1 [major|minor|patch]
# Por defecto incrementa el build number

param(
    [ValidateSet('major', 'minor', 'patch', 'build')]
    [string]$VersionType = 'build'
)

$pubspecPath = "pubspec.yaml"

# Leer el contenido del pubspec.yaml
$content = Get-Content $pubspecPath -Raw

# Extraer la versión actual usando regex
if ($content -match 'version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)') {
    $major = [int]$matches[1]
    $minor = [int]$matches[2]
    $patch = [int]$matches[3]
    $build = [int]$matches[4]

    Write-Host "Versión actual: $major.$minor.$patch+$build" -ForegroundColor Cyan

    # Incrementar según el tipo especificado
    switch ($VersionType) {
        'major' {
            $major++
            $minor = 0
            $patch = 0
            $build++
        }
        'minor' {
            $minor++
            $patch = 0
            $build++
        }
        'patch' {
            $patch++
            $build++
        }
        'build' {
            $build++
        }
    }

    $newVersion = "$major.$minor.$patch+$build"
    Write-Host "Nueva versión: $newVersion" -ForegroundColor Green

    # Actualizar el pubspec.yaml
    $content = $content -replace 'version:\s*\d+\.\d+\.\d+\+\d+', "version: $newVersion"
    $content | Set-Content $pubspecPath -NoNewline

    Write-Host "`nActualizando pubspec.yaml..." -ForegroundColor Yellow
    
    # Limpiar builds anteriores
    Write-Host "`nLimpiando builds anteriores..." -ForegroundColor Yellow
    if (Test-Path "build") {
        flutter clean
    }

    # Obtener dependencias
    Write-Host "`nObteniendo dependencias..." -ForegroundColor Yellow
    flutter pub get

    if ($LASTEXITCODE -ne 0) {
        Write-Host "`n❌ Error al obtener dependencias" -ForegroundColor Red
        exit 1
    }

    # Generar el bundle de Android (.aab)
    Write-Host "`n🚀 Generando Android App Bundle (.aab)..." -ForegroundColor Yellow
    
    # Usar short path para evitar problemas con espacios en el SDK path
    $env:ANDROID_SDK_ROOT = "D:\MSI~1\AppData\Local\Android\Sdk"
    flutter build appbundle --release 2>&1 | Out-Host

    # Verificar si el archivo .aab fue generado exitosamente
    $aabPath = "build\app\outputs\bundle\release\app-release.aab"
    if (Test-Path $aabPath) {
        Write-Host "`n✅ Build exitoso!" -ForegroundColor Green
        Write-Host "Versión: $newVersion" -ForegroundColor Green
        Write-Host "`n📦 Archivo generado en:" -ForegroundColor Cyan
        Write-Host $aabPath -ForegroundColor White
        
        # Mostrar tamaño del archivo
        $size = (Get-Item $aabPath).Length / 1MB
        Write-Host "`nTamaño del archivo: $([math]::Round($size, 2)) MB" -ForegroundColor Cyan

        Write-Host "`n📝 Próximos pasos:" -ForegroundColor Yellow
        Write-Host "1. Ve a Google Play Console" -ForegroundColor White
        Write-Host "2. Selecciona tu app" -ForegroundColor White
        Write-Host "3. Ve a 'Producción' o 'Pruebas'" -ForegroundColor White
        Write-Host "4. Crea una nueva versión y sube el .aab" -ForegroundColor White
    } else {
        Write-Host "`n❌ Error al generar el build" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "❌ No se pudo encontrar la versión en pubspec.yaml" -ForegroundColor Red
    exit 1
}
