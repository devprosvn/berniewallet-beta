# Bernie Wallet Web Build Script for Windows
# This script builds the Flutter web application with the correct settings for GitHub Pages or custom domain

# Parameter to specify deployment target
param(
    [Parameter()]
    [ValidateSet("github", "custom")]
    [string]$DeploymentTarget = "github"
)

# Error handling - stop script on error
$ErrorActionPreference = "Stop"

# Function to check if a command exists
function Test-CommandExists {
    param ($command)
    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = 'stop'
    try {
        if (Get-Command $command) { return $true }
    }
    catch { return $false }
    finally { $ErrorActionPreference = $oldPreference }
}

# Verify Flutter is installed
if (-not (Test-CommandExists "flutter")) {
    Write-Host "Error: Flutter command not found. Please make sure Flutter is installed and in your PATH." -ForegroundColor Red
    exit 1
}

# Check flutter version
Write-Host "Using Flutter version:" -ForegroundColor Cyan
flutter --version

# Start build process
Write-Host "Building Bernie Wallet for web deployment..." -ForegroundColor Green
Write-Host "Target: $DeploymentTarget" -ForegroundColor Yellow

# Set base href based on deployment target
$baseHref = if ($DeploymentTarget -eq "github") { "/berniewallet/" } else { "/" }
Write-Host "Using base-href: $baseHref" -ForegroundColor Yellow

# Navigate to project root directory
$projectRoot = Get-Location
Write-Host "Project directory: $projectRoot" -ForegroundColor Cyan

try {
    # Clean the build directory
    Write-Host "Cleaning build directory..." -ForegroundColor Cyan
    flutter clean
    if ($LASTEXITCODE -ne 0) { throw "Flutter clean failed with exit code $LASTEXITCODE" }

    # Get dependencies
    Write-Host "Getting dependencies..." -ForegroundColor Cyan
    flutter pub get
    if ($LASTEXITCODE -ne 0) { throw "Flutter pub get failed with exit code $LASTEXITCODE" }

    # Build web version with the correct base href
    Write-Host "Building web application..." -ForegroundColor Cyan
    flutter build web --base-href $baseHref --release
    if ($LASTEXITCODE -ne 0) { throw "Flutter build web failed with exit code $LASTEXITCODE" }

    # Verify build output exists
    if (-not (Test-Path "build/web/index.html")) {
        throw "Build failed: index.html not found. The Flutter web build did not complete successfully."
    }

    # Create necessary files for GitHub Pages
    Write-Host "Creating additional files for GitHub Pages..." -ForegroundColor Green

    # Ensure .nojekyll exists (prevents Jekyll processing)
    New-Item -Path "build/web/.nojekyll" -ItemType File -Force | Out-Null
    Write-Host "Created .nojekyll file" -ForegroundColor Cyan

    # Create 404.html if it doesn't exist
    if (-not (Test-Path "build/web/404.html")) {
        if ($DeploymentTarget -eq "github") {
            $404Content = @"
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta http-equiv="refresh" content="0;URL='/berniewallet/'">
  <script>
    // GitHub Pages 404 Handling for Single Page Apps
    window.onload = function() {
      var segmentCount = 1; // We have 1 segment in our path: 'berniewallet'
      var location = window.location;
      var redirectPath = location.pathname.replace(/\/berniewallet\//, '/');
      var newPath = '/berniewallet/' + redirectPath.split('/').slice(segmentCount).join('/');
      
      // Preserve query parameters and hash if present
      if (location.search) newPath += location.search;
      if (location.hash) newPath += location.hash;
      
      // Redirect to the proper route while preserving the path
      window.location.href = newPath;
    }
  </script>
  <title>Bernie Wallet - Redirecting</title>
</head>
<body>
  <h1>Redirecting to Bernie Wallet...</h1>
  <p>If you are not redirected automatically, click <a href="/berniewallet/">here</a>.</p>
</body>
</html>
"@
        } else {
            $404Content = @"
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta http-equiv="refresh" content="0;URL='/'">
  <script>
    // Custom Domain 404 Handling for Single Page Apps
    window.onload = function() {
      var location = window.location;
      
      // Preserve query parameters and hash if present
      var newPath = '/' + (location.search || '') + (location.hash || '');
      
      // Redirect to the proper route
      window.location.href = newPath;
    }
  </script>
  <title>Bernie Wallet - Redirecting</title>
</head>
<body>
  <h1>Redirecting to Bernie Wallet...</h1>
  <p>If you are not redirected automatically, click <a href="/">here</a>.</p>
</body>
</html>
"@
        }
        Set-Content -Path "build/web/404.html" -Value $404Content
        Write-Host "Created 404.html file" -ForegroundColor Cyan
    }

    # Enhance index.html with loading indicator
    Write-Host "Enhancing index.html with loading indicator..." -ForegroundColor Cyan
    $indexPath = "build/web/index.html"
    $indexContent = Get-Content -Path $indexPath -Raw
    
    if (-not $indexContent.Contains("loading")) {
        $enhancedIndexContent = $indexContent -replace "<body>(\s*)<script", @"
<body>
  <!-- Loading indicator to show before Flutter is initialized -->
  <div id="loading" style="
    display: flex;
    justify-content: center;
    align-items: center;
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background-color: #FFFFFF;
  ">
    <img src="icons/Icon-192.png" alt="Loading Bernie Wallet" style="width: 80px; height: 80px;">
    <p style="margin-left: 16px; font-family: sans-serif;">Loading Bernie Wallet...</p>
  </div>

  <script>
    // Remove the loading indicator once Flutter is initialized
    window.addEventListener('flutter-first-frame', function() {
      const loadingIndicator = document.getElementById('loading');
      if (loadingIndicator) {
        loadingIndicator.remove();
      }
    });
  </script>
  <script
"@
        Set-Content -Path $indexPath -Value $enhancedIndexContent
        Write-Host "Enhanced index.html with loading indicator" -ForegroundColor Cyan
    }
    
    # Create or update CNAME file for custom domain if needed
    if ($DeploymentTarget -eq "custom") {
        $cnameContent = "berniewallet.devbernie.site"
        Set-Content -Path "build/web/CNAME" -Value $cnameContent
        Write-Host "Created CNAME file for custom domain" -ForegroundColor Cyan
    }

    # Copy the README if it doesn't exist or use a custom web README
    if (-not (Test-Path "build/web/README.md")) {
        if (Test-Path "README.md") {
            Copy-Item "README.md" -Destination "build/web/"
            Write-Host "Copied README.md to build/web/" -ForegroundColor Cyan
        } else {
            $webReadmeContent = @"
# Bernie Wallet - Web Demo

This is the web demo version of Bernie Wallet, an Algorand blockchain wallet application built with Flutter.

## Web Deployment Instructions

The live web demo is available at: [https://berniewallet.devbernie.site/](https://berniewallet.devbernie.site/)
"@
            Set-Content -Path "build/web/README.md" -Value $webReadmeContent
            Write-Host "Created web README.md" -ForegroundColor Cyan
        }
    }

    # List the contents of build/web to verify
    Write-Host "Contents of build/web directory:" -ForegroundColor Cyan
    Get-ChildItem -Path "build/web" | Select-Object Name, Length | Format-Table -AutoSize

    Write-Host "Build completed successfully!" -ForegroundColor Green
    Write-Host "The web build is available in the build/web directory" -ForegroundColor Cyan
    
    if ($DeploymentTarget -eq "github") {
        Write-Host "To deploy to GitHub Pages, copy the contents of build/web to your GitHub Pages repository" -ForegroundColor Cyan
    } else {
        Write-Host "To deploy to your custom domain, upload the contents of build/web to your web server" -ForegroundColor Cyan
    }
}
catch {
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host "Build failed! Please check the error messages above." -ForegroundColor Red
    exit 1
} 