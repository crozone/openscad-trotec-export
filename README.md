# openscad-trotec-export
Powershell script for exporting 2D OpenSCAD models to a Trotec laser compatible PDF.

## Preface

Creating Trotec compatible PDFs from OpenSCAD usually requires a tedious manual export process. A "cut" and an "engrave" SVG need to be exported from OpenSCAD, then imported into software such as Inkscape, where the paths can be manually aligned, have their stroke and fill adjusted to match the required colour and thickness needed by the Trotec software, and then finally saved as PDF.

This script automates this process. It takes a .scad file and exports both a combined .SVG and .PDF which can be used with Trotec laser software immediately.

### Trotec compatible PDFs

To be compatible with Trotec software defaults, the script uses the following parameters for the cut and engrave paths:

* **Cut paths:** Red, 100% opacity (RGBA #FF0000FF), with 0.01mm thickness stroke. No infill.

* **Engrave paths:** No stroke. Black infill, 100% opacity (RGBA #000000FF).

Other colours can be configured in the Trotec software to indicate different cut/engrave settings, however these are currently not supported by this script.
It should be simple to modify the script to add additional layers with additional output settings as required.

## Dependencies

* Powershell (Only tested on Powershell 5.1 for Windows, but [Powershell Core](https://github.com/PowerShell/PowerShell) should work on Linux and MacOS)
* OpenSCAD (.scad -> .svg)
* Inkscape (.svg -> .pdf)


The script will search for OpenSCAD and Inkscape using a list of pre-defined install locations. Common paths for Windows, Linux, and MacOS are included. If your OpenSCAD or Inkscape is installed in an unusual location, set the `OPENSCAD_LOCATION` and/or `INKSCAPE_LOCATION` environment variables to the paths of the application executables.

For example:

```PowerShell
$Env:OPENSCAD_LOCATION = "C:\OpenSCAD\openscad.exe"
$Env:INKSCAPE_LOCATION = "C:\Inkscape\bin\inkscape.exe"
```

## Usage

`openscad_export_for_trotec.ps1 <input_scad_path>`

## Example

`./openscad_export_for_trotec.ps1 ./examples/basic/basic.scad`

`basic_trotec.svg` and `basic_trotec.pdf` will be created in the same directory as `basic.scad`.

## Making your .scad files compatible

The script sets the constant `EXPORT_LAYER` depending on whether the "cut" layer or the "engrave" layer are to be exported:

* Cut: `EXPORT_LAYER=1`
* Engrave: `EXPORT_LAYER=2`

Your .scad file should include the line `EXPORT_LAYER = 0;` in the top-most scope. This will then be overridden during export. Your .scad can then be set up to output the approprate geometry based on the value of `EXPORT_LAYER`.

For example:

```OpenSCAD
EXPORT_LAYER = 0;

module part() {
    // Cut geometry goes here
}

module engrave() {
    // Engrave geometry goes here
}

if(EXPORT_LAYER == 1) {
    // Cut layer
    part();
}
else if(EXPORT_LAYER == 2) {
    // Engrave layer
    engrave();
}
else {
    // Normal mode / preview
    part();
    %engrave();
}
```

See [examples](examples/) for examples.

## Script steps
The steps the script takes are:

1. Export input .scad to SVG data with `EXPORT_LAYER=1` to generate cut geometry.
This is piped into an internal variable and there is no intermediate SVG file.
2. Export input .scad to SVG data with `EXPORT_LAYER=2` to generate engrave geometry.
This is piped into an internal variable and there is no intermediate SVG file.
3. Modify the attributes of the cut and engrave SVGs to set path stroke and fill, as well as document title.
All SVG manipulation is handled internally by Powershell's .NET XML libraries.
4. Combine the cut and engrave SVGs by inserting the engrave path into the cut SVG.
5. Save combined SVG data to file (`_trotec.svg`).
6. Call Inkscape to convert SVG to PDF (`_trotec.svg`) -> (`_trotec.pdf`).
