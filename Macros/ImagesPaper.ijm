// ============================================================================
// Create an RGB maximum-intensity projection of the active multichannel stack.
// ============================================================================
// IMPORTANT: Fill in USER PARAMETERS and check channel assignments before running.
// Empty strings and -1 values deliberately prevent use of unchecked settings.
// Original values below are examples, not validated defaults for another dataset.
// Input: the active ImageJ/Fiji stack.
// Figure preparation only. RGB conversion and scale bars alter the exported image.
// Verify spatial calibration before adding a scale bar.

// USER PARAMETERS
backgroundSubtract = -1; // EDIT: Constant intensity subtracted from the entire stack (not rolling background). Original example: 15.
medianRadius = -1; // EDIT: Median filter radius in pixels. Original example: 1.
scaleBarWidth = -1; // EDIT: Scale bar width in calibrated image units. Original example: 200.
scaleBarHeight = -1; // EDIT: Scale bar height in calibrated image units. Original example: 200.
scaleBarThickness = -1; // EDIT: Scale bar thickness in pixels. Original example: 12.
scaleBarFont = -1; // EDIT: Scale bar font size. Original example: 32.

// CONFIGURATION CHECK
if (backgroundSubtract < 0 ||
    medianRadius < 0 ||
    scaleBarWidth < 0 ||
    scaleBarHeight < 0 ||
    scaleBarThickness < 0 ||
    scaleBarFont < 0)
    exit("Fill in and review all USER PARAMETERS before running this macro.");

// PROCESSING - original operation order retained
outputFolder = getDirectory("Select the output folder:");
outputFilename = getString("Enter the output TIFF filename", "figure.tif");
if (outputFilename == "") exit("No output filename entered.");
outputPath = outputFolder + outputFilename;

// Subtract a fixed background intensity; this changes pixel values.
run("Subtract...", "value=" + backgroundSubtract + " stack");

// Reduce local noise with the configured median filter.
run("Median...", "radius=" + medianRadius + " stack");

// Collapse the Z stack by retaining the maximum intensity at each XY position.
run("Z Project...", "projection=[Max Intensity]");

Property.set("CompositeProjection", "Sum");
Stack.setDisplayMode("composite");
run("Stack to RGB");

run("Scale Bar...", "width=" + scaleBarWidth + " height=" + scaleBarHeight +
    " thickness=" + scaleBarThickness + " font=" + scaleBarFont + " bold");

saveAs("Tiff", outputPath);