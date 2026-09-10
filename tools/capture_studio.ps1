param([Parameter(Mandatory=$true)][int]$StudioProcessId, [string]$OutputPath='build/studio-runtime.png')
Add-Type -AssemblyName System.Drawing
Add-Type @'
using System;
using System.Runtime.InteropServices;
public class StudioWindow {
    [StructLayout(LayoutKind.Sequential)] public struct Rect { public int Left; public int Top; public int Right; public int Bottom; }
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr handle, out Rect rect);
}
'@
$studioProcess = Get-Process -Id $StudioProcessId
if ($studioProcess.ProcessName -ne 'RobloxStudioBeta') { throw 'Target must be Roblox Studio.' }
$studioRect = New-Object StudioWindow+Rect
[StudioWindow]::GetWindowRect($studioProcess.MainWindowHandle, [ref]$studioRect) | Out-Null
$studioImage = New-Object System.Drawing.Bitmap(($studioRect.Right-$studioRect.Left),($studioRect.Bottom-$studioRect.Top))
$studioGraphics = [System.Drawing.Graphics]::FromImage($studioImage)
$studioGraphics.CopyFromScreen($studioRect.Left,$studioRect.Top,0,0,$studioImage.Size)
$studioImage.Save([System.IO.Path]::GetFullPath($OutputPath))
$studioGraphics.Dispose()
$studioImage.Dispose()
