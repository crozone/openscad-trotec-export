# OpenSCAD export script for Trotec laser cutters.

# Workflow for Trotec laser cutters usually involves "printing" a PDF document using the Trotec driver, which then creates a job in the Trotec software.
# By default, the software expects:
#
# Cut paths: Red, 100% opacity (RGBA #FF0000FF), with 0.01mm thickness stroke. No infill.
# Engrave paths: Black, 100% opacity (RGBA #000000FF). Can be stroke, infill, bitmap image, etc. Engraving is always rasterized.
#
# This script exports a .scad file to both and SVG and PDF that meet the above criteria, so it can be printed immediately without post-processing.

# Input:
#
# OpenSCAD .scad file containing a cut and engrave layer. Cut vs Engrave geometry controlled via EXPORT_LAYER variable:
#
# EXPORT_LAYER=1 (cut)
# EXPORT_LAYER=2 (engrave)
# EXPORT_LAYER=0 (Unused, script never sets EXPORT_LAYER=0)
#
# Output:
#
# Combined SVG with both "cut" and "engrave" paths.
# * Cut path: Red, 100% opacity (RGBA #FF0000FF), with 0.01mm thickness stroke. No infill.
# * Engrave path: No stroke. Black, 100% opacity (RGBA #000000FF) infill.
#
# Combined PDF (Exported from Inkscape)
# * Equivalent to combined SVG.

# Script parameters
param ([Parameter(Mandatory)][string] $source_scad)

function Get-OpenscadPath {
    If ($Env:OPENSCAD_LOCATION) {
        return $Env:OPENSCAD_LOCATION
    }

    # Possible OpenSCAD install paths
    $openscad_windows_locations = @(
        "${Env:ProgramFiles}\OpenSCAD\openscad.exe",
        "${Env:ProgramFiles(x86)}\OpenSCAD\openscad.exe"
    )

    $openscad_linux_locations = @(
        "/usr/bin/openscad",
        "/usr/local/bin/openscad"
    )

    $openscad_macos_locations = @(
        "/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD"
    )

    $openscad_locations = If ($IsLinux) { $openscad_linux_locations }
        Else { If ($IsMacOS) { $openscad_macos_locations } Else { $openscad_windows_locations } }

    # Return the first path that exists
    Foreach ($this_path in $openscad_locations) {
        Write-Debug "Testing path $this_path"
        If (Test-Path -Path $this_path -PathType Leaf) {
            Write-Debug "Found $this_path"
            return $this_path
        }
    }

    throw "Could not find OpenSCAD install location"
}

function Get-InkscapePath {
    If ($Env:INKSCAPE_LOCATION) {
        return $Env:INKSCAPE_LOCATION
    }

    # Possible Inkscape install paths
    $inkscape_windows_locations = @(
        "${Env:ProgramFiles}\Inkscape\bin\inkscape.exe",
        "${Env:ProgramFiles(x86)}\Inkscape\bin\inkscape.exe"
    )

    $inkscape_linux_locations = @(
        "/usr/bin/inkscape",
        "/usr/local/bin/inkscape"
    )

    $inkscape_macos_locations = @(
        "/Applications/Inkscape.app/Contents/MacOS/inkscape"
    )

    $inkscape_locations = If ($IsLinux) { $inkscape_linux_locations }
        Else { If ($IsMacOS) { $inkscape_macos_locations } Else { $inkscape_windows_locations } }

    # Return the first path that exists
    Foreach ($this_path in $inkscape_locations) {
        Write-Debug "Testing path $this_path"
        If (Test-Path -Path $this_path -PathType Leaf) {
            Write-Debug "Found $this_path"
            return $this_path
        }
    }

    throw "Could not find Inkscape install location"
}

function Invoke-OpenScad {
    param (
        [Parameter(Mandatory)][string[]] $openscad_args,
        [Parameter(Mandatory)][string] $working_directory
    )

    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = "$openscad_exe"
    $pinfo.RedirectStandardOutput = $true
    $pinfo.UseShellExecute = $false
    $pinfo.Arguments = $openscad_args
    $pinfo.WorkingDirectory = $working_directory

    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $pinfo
    $p.Start() | Out-Null
    $result = $p.StandardOutput.ReadToEnd()
    $p.WaitForExit()

    return $result
}

function Get-RenderedSvg {
    param (
        [Parameter(Mandatory)][int] $layer,
        [Parameter(Mandatory)][string] $input_path,
        [Parameter(Mandatory)][string] $working_directory
    )

    $svg_export_args = @(
        "-D EXPORT_LAYER=$layer",
        "--export-format svg",
        "-o -",
        "`"$input_path`""
        )

    return Invoke-OpenScad $svg_export_args $working_directory
}

function Invoke-Inkscape {
    param (
        [Parameter(Mandatory)][string[]] $inkscape_args,
        [Parameter(Mandatory)][string] $working_directory
    )

    Start-Process `
        -FilePath "$inkscape_exe" `
        -ArgumentList $inkscape_args `
        -WorkingDirectory $working_directory `
        -Wait
}

function Invoke-RenderPdf {
    param (
        [Parameter(Mandatory)][string] $input_path,
        [Parameter(Mandatory)][string] $output_path,
        [Parameter(Mandatory)][string] $working_directory
    )

    $pdf_export_args = @(
        "--export-filename `"$output_path`"",
        '--export-type="pdf"',
        '--export-area-drawing',
        '--export-pdf-version=1.5',
        '--export-margin=1',
        "`"$input_path`""
        )

    Invoke-Inkscape $pdf_export_args $working_directory
}

Write-Output "*** OpenSCAD export for Trotec ***"

# Inkscape install path
$openscad_exe = Get-OpenscadPath
Write-Output "Using OpenSCAD path: $openscad_exe"

$inkscape_exe = Get-InkscapePath
Write-Output "Using Inkscape path: $inkscape_exe"

$resolved_source_path = $(Resolve-Path $source_scad).Path
$source_fileinfo = [System.IO.FileInfo]$resolved_source_path
$source_name = $source_fileinfo.BaseName
$source_directory = $source_fileinfo.DirectoryName
$export_directory = $source_directory

Write-Output "Using source file: $resolved_source_path"
Write-Output "Using source directory: $source_directory"
Write-Output "Using source name: $source_name"
Write-Output "Using export directory: $export_directory"

Write-Output ""

Write-Output "Creating export directory $export_directory ..."

New-Item -ItemType Directory -Force -Path "$export_directory" | Out-Null

# Render cut layer
Write-Output "Rendering cut layer 1 ..."
$cut_layer_svg_data = Get-RenderedSvg -layer 1 -input_path $resolved_source_path -working_directory $source_directory
Write-Output "Cut layer 1 rendered. (Result length: $($cut_layer_svg_data.Length))"

# Render engrave layer
Write-Output "Rendering engrave layer 2 ..."
$engrave_layer_svg_data = Get-RenderedSvg -layer 2 -input_path $resolved_source_path -working_directory $source_directory
Write-Output "Engrave layer 2 rendered. (Result length: $($engrave_layer_svg_data.Length))"

Write-Output "Rendering complete."

# Now we need to combine the cut SVG and engrave SVG.
Write-Output "Parsing SVG data ..."

$cut_svg_doc = $(Select-Xml -Content "$cut_layer_svg_data" -XPath "/").Node
$engrave_svg_doc = $(Select-Xml -Content "$engrave_layer_svg_data" -XPath "/").Node

# Get SVG nodes
$cut_svg_node = $cut_svg_doc["svg"]
$engrave_svg_node = $engrave_svg_doc["svg"]

Write-Output "Updating SVG parameters ..."

# Set document title
$cut_svg_node["title"].InnerText = $source_name

# Set cut path parameters
$cut_svg_path_node = $cut_svg_node["path"]

$cut_svg_path_node.SetAttribute("id", "cut_path")
$cut_svg_path_node.SetAttribute("stroke", "red")
$cut_svg_path_node.SetAttribute("stroke-width", "0.01")
$cut_svg_path_node.SetAttribute("fill", "none")

# Set engrave path parameters
$engrave_svg_path_node = $engrave_svg_node["path"]

$engrave_svg_path_node.SetAttribute("id", "engrave_path")
$engrave_svg_path_node.SetAttribute("stroke", "none")
$engrave_svg_path_node.RemoveAttribute("stroke-width")
$engrave_svg_path_node.SetAttribute("fill", "black")

# Add engrave path into cut SVG
# Need to import it into the cut document since it's from a different context
Write-Output "Combining SVGs ..."
$imported_engrave_path_node = $cut_svg_doc.ImportNode($engrave_svg_path_node, $true)
$cut_svg_node.AppendChild($imported_engrave_path_node) | Out-Null

# Export the modified document
$combined_svg_export_filename = "${source_name}_trotec.svg"
$combined_svg_export_path = Join-Path $export_directory $combined_svg_export_filename

Write-Output "Exporting combined SVG $combined_svg_export_path ..."
$cut_svg_doc.Save($combined_svg_export_path)

Write-Output "Converting SVG to PDF ..."
# Use Inkscape to convert the SVG to PDF
$export_pdf_filename = "${source_name}_trotec.pdf"
$export_pdf_path = Join-Path $export_directory $export_pdf_filename
Write-Output "Exporting PDF ${export_pdf_path} ..."
Invoke-RenderPdf -input_path $combined_svg_export_path -output_path $export_pdf_path -working_directory $source_directory

Write-Output "Done."
