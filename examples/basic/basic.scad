// Basic example of SCAD compatible with render script.

// Export script overrides EXPORT_LAYER
//
// 1: Cut layer
// 2: Engrave layer
EXPORT_LAYER = 0;

if(EXPORT_LAYER != 0) {
    echo(str("EXPORT_LAYER enabled, set to ", EXPORT_LAYER));
}

module part() {
    square([50, 50]);
}

module engrave() {
    square([30, 30]);
}

if(EXPORT_LAYER == 1) {
    echo("Cut only mode")
    part();
}
else if(EXPORT_LAYER == 2) {
    echo("Engrave only mode")
    engrave();
}
else {
    // Normal mode
    part();
    %engrave();
}
