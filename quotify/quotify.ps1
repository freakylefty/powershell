PARAM ([string]$dir = [Environment]::GetFolderPath("Desktop"))
if (-Not((Test-Path $dir) -Eq $True)) {
	Write-Host Invalid output folder: $dir
	Exit
}

Function DeleteIfExists {
	[CmdletBinding()]
	PARAM ([Parameter(Mandatory=$true)][String]$file)
	
	if (Test-Path $file) {
		Remove-Item $file
	}
}


Function GetRandomElement {
	[CmdletBinding()]
	PARAM ([Parameter(Mandatory=$true)][Array]$array)

	if ($array.length -eq 1) {
		return $array;
	} else {
		return ($array | Sort-Object {Get-Random})[0]
	}
}


Function Shuffle {
	[CmdletBinding()]
	PARAM ([Parameter(Mandatory=$true)][Array]$array)

	return $array | Sort-Object {Get-Random}
}


Function DownloadImage {
	[CmdletBinding()]
	PARAM ([Parameter(Mandatory=$true)][String]$url)
	
	$web = New-Object Net.WebClient
	
	# Get temp directory and create subfolder if necessary
	$tmp = $env:temp
	$dir = $tmp + "\powershell\quotify"
	New-Item -ItemType Directory -Force -Path ($dir) >$null 2>&1

	# Download image
	$imageFile = $dir + "\image.jpg"
	$web.DownloadFile($url, $imageFile)

	return $imageFile
}


Function GetImageData {
	[CmdletBinding()]
	PARAM ([Parameter(Mandatory=$true)][Array]$sources)
	
	$source = GetRandomElement($sources)
	
	$web = New-Object Net.WebClient
	$response = $web.DownloadString("https://www.reddit.com/r/" + $source + ".json") | ConvertFrom-Json

	# Iterate through posts to find one we can download
	$data = $null
	$response.data.children = Shuffle -array $response.data.children
	for ($index = 0; $index -lt $response.data.children.length; $index++) {
		$curr = $response.data.children[$index].data
		if ($curr.url.toLower().EndsWith(".jpg") -Or $curr.url.toLower().EndsWith(".png")) {
			$data = $curr.url, $curr.author
			break;
		}
	}
	return $data
}


Function GetQuoteData {
	[CmdletBinding()]
	PARAM ([Parameter(Mandatory=$true)][Array]$sources)
	
	$source = GetRandomElement($sources)
	
	$web = New-Object Net.WebClient
	$response = $web.DownloadString("https://www.reddit.com/r/" + $source + ".json") | ConvertFrom-Json
	$quotes = $response.data.children;
	
	$quote = GetRandomElement($quotes).data
	return $quote.title, $quote.author
}


Function GetDestPath {
	$outFile = (Get-Date -format "yyyy-MM-dd HH-mm-ss") + ".png"
	$dest = [System.IO.Path]::GetFullPath((resolve-path $dir)) + "\" + $outFile
	return $dest
}

Function GetImageScale {
	[CmdletBinding()]
    PARAM (
        [Parameter(Mandatory=$true)][int] $srcWidth,
        [Parameter(Mandatory=$true)][int] $srcHeight,
        [Parameter(Mandatory=$true)][int] $destWidth,
        [Parameter(Mandatory=$true)][int] $destHeight
	)
	
	$scaleX = 1
	if ($srcWidth -gt $destWidth) {
		$scaleX = $srcWidth / $destWidth
	}
	$scaleY = 1
	if ($srcHeight -gt $destHeight) {
		$scaleY = $srcHeight / $destHeight
	}
	$scale = $scaleX
	if ($scaleY -gt $scale) {
		$scale = $scaleY;
	}
	
	return $scale
}


Function AddTextToImage {
    # Orignal code from http://www.ravichaganti.com/blog/?p=1012
    [CmdletBinding()]
    PARAM (
        [Parameter(Mandatory=$true)][String] $sourcePath,
        [Parameter(Mandatory=$true)][String] $destPath,
        [Parameter(Mandatory=$true)][String] $text,
        [Parameter(Mandatory=$true)][String] $imageAuthor,
        [Parameter(Mandatory=$true)][String] $quoteAuthor
    )
    [Reflection.Assembly]::LoadWithPartialName("System.Drawing") | Out-Null
    
    $srcImg = [System.Drawing.Image]::FromFile($sourcePath)
	
	$srcWidth = $srcImg.width
	$srcHeight = $srcImg.height
	
	$scale = GetImageScale -srcWidth $srcWidth -srcHeight $srcHeight -destWidth 1920 -destHeight 1280
	
	$destWidth = [int]($srcWidth / $scale)
	$destHeight = [int]($srcHeight / $scale)
    
    $bmpFile = new-object System.Drawing.Bitmap([int]($destWidth)),([int]($destHeight))

    $image = [System.Drawing.Graphics]::FromImage($bmpFile)
    $image.SmoothingMode = "AntiAlias"
     
    $destRect = New-Object Drawing.Rectangle 0, 0, $destWidth, $destHeight
    $srcRect = New-Object Drawing.Rectangle 0, 0, $srcImg.Width, $srcImg.Height

    $image.DrawImage($srcImg, $destRect, $srcRect, ([Drawing.GraphicsUnit]::Pixel))
	
	$y = 40
	$x = $destWidth / 2
	
	$charWidth = 30
	$lineHeight = 90
	$maxChars = [int]($destWidth / ($charWidth + 2))
 
    $lines = GetLines -text $text -maxChars $maxChars
	for ($index = 0; $index -lt $lines.length; $index ++) {
		$line = $lines[$index]
		TOAP -image $image -text $line -size 48 -align Center -x $x -y $y
		$y = $y + $lineHeight
	}
	
	TOAP -image $image -text ("u/" + $imageAuthor) -size 16 -align Near -x 10 -y ($destHeight - 60)
	TOAP -image $image -text ("u/" + $quoteAuthor) -size 16 -align Near -x 10 -y ($destHeight - 30)
	
    $bmpFile.save($destPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmpFile.Dispose()
    $srcImg.Dispose()
}

Function TOAP {
	[CmdletBinding()]
    PARAM (
        [Parameter(Mandatory=$true)][System.Drawing.Graphics] $image,
        [Parameter(Mandatory=$true)][String] $text,
        [Parameter(Mandatory=$true)][int] $size,
        [Parameter(Mandatory=$true)][System.Drawing.StringAlignment] $align,
        [Parameter(Mandatory=$true)][int] $x,
        [Parameter(Mandatory=$true)][int] $y
    )
	
	$black = New-Object Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 0, 0,0))
    $white = New-Object Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 255, 255,255))
	$font = new-object System.Drawing.Font("Impact", $size)
	$format = New-Object System.Drawing.StringFormat
	$format.Alignment = $align
	
	$image.DrawString($text, $font, $black, $x, $y, $format)
	$image.DrawString($text, $font, $white, $x - 2, $y - 2, $format)
}

Function GetLines {
    [CmdletBinding()]
    PARAM (
        [Parameter(Mandatory=$true)][String] $text,
        [Parameter(Mandatory=$true)][String] $maxChars
    )
	
	$lines = @()
	
	$words = $text -split " "
	$index = 0
	$line = ""
	while ($index -lt $words.length) {
		$line = $line + " " + $words[$index]
		if ($line.length -gt $maxChars) {
			$lines = $lines += $line
			$line = ""
		}
		$index = $index + 1
	}
	if (-Not($line -Eq "")) {
		$lines = $lines += $line
	}
	
	return $lines
}

#----------------------------------------------------------------------------

# Download data and get URL for top file
Write-Host "Getting image data"
$imgData = GetImageData -sources "SeaPorn", "SkyPorn", "WinterPorn", "JunglePorn", "earthporn", "waterporn", "cityporn", "Breathless"
if (-Not $imgData -Or $imgData -Eq $null) {
	# No valid images found, bail out
	Write-Host("No valid image found")
	Exit
}

Write-Host "Downloading image"
$imageFile = DownLoadImage -url $imgData[0]
if (-Not $imageFile) {
	# Could not download image, bail out
	Write-Host("Could not download image")
	Exit
}

# Get quote
Write-Host "Getting quote"
$quoteData = GetQuoteData -sources @("showerthoughts")
if (-Not $quoteData -Or $quoteData -Eq $null) {
	# Could not download quote, bail out
	Write-Host("Could not download quote")
}

# Write to image
Write-Host "Creating image"
$dest = GetDestPath
AddTextToImage -sourcePath $imageFile -destPath $dest -text $quoteData[0] -imageAuthor $imgData[1] -quoteAuthor $quoteData[1]
DeleteIfExists -file $imageFile