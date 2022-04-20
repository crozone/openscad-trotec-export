// Alignment test scad for render script.
//
// Validates that the cut and engrave paths remain aligned,
// even after they are combined into a single SVG.

// Export script overrides EXPORT_LAYER
//
// 1: Cut layer
// 2: Engrave layer
EXPORT_LAYER = 0;

if(EXPORT_LAYER != 0) {
    echo(str("EXPORT_LAYER enabled, set to ", EXPORT_LAYER));
}

$fn = $preview ? 32 : 128;

module cutouts() {
    translate([20, 30])
    circle(d = 5);

    translate([30, 10])
    scale([3, 1])
    circle(d = 5);
}

module part() {
    difference() {
        translate([-10, -20])
        square([80, 70]);

        cutouts();
    }
}

module engrave() {
    cutouts();
}

if(EXPORT_LAYER == 1) {
    echo("Cut only mode");
    part();
}
else if(EXPORT_LAYER == 2) {
    echo("Engrave only mode");
    engrave();
}
else {
    // Normal mode
    part();
    %engrave();
}
