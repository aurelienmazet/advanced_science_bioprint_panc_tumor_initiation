// ============================================================================
// Create an RGB Live/Dead figure: DEAD in red and LIVE in green.
// ============================================================================
// IMPORTANT: Fill in USER PARAMETERS and check channel assignments before running.
// Empty strings and -1 values deliberately prevent use of unchecked settings.
// Original values below are examples, not validated defaults for another dataset.
// Input: the active ImageJ/Fiji stack.
// Figure preparation only. RGB conversion and scale bars alter the exported image.
// Verify spatial calibration before adding a scale bar.
// WARNING: original cleanup closes ALL open image windows; use a dedicated session.
// Empty duplicate title retained: Split Channels is expected to produce C1-, C2-, etc.
// Avoid existing windows with those names and verify channel availability.

// USER PARAMETERS
channelLIVE = -1; // EDIT: Input channel index (positive integer). Original example: 1.
channelDEAD = -1; // EDIT: Input channel index (positive integer). Original example: 2.

liveBackgroundSubtract = -1; // EDIT: Constant intensity subtracted from the entire stack. Original example: 18.
deadBackgroundSubtract = -1; // EDIT: Constant intensity subtracted from the entire stack. Original example: 5.

liveMedianRadius = -1; // EDIT: Median filter radius in pixels. Original example: 1.
deadMedianRadius = -1; // EDIT: Median filter radius in pixels. Original example: 1.

liveDisplayMin = -1; // EDIT: Display lower intensity limit. Original example: 0.
liveDisplayMax = -1; // EDIT: Display upper intensity limit. Original example: 259.
deadDisplayMin = -1; // EDIT: Display lower intensity limit. Original example: 0.
deadDisplayMax = -1; // EDIT: Display upper intensity limit. Original example: 268.
// Display limits use original image intensity units and may exceed 255.

scaleBarWidth = -1; // EDIT: Scale bar width in calibrated image units. Original example: 200.
scaleBarHeight = -1; // EDIT: Scale bar height in calibrated image units. Original example: 200.
scaleBarThickness = -1; // EDIT: Scale bar thickness in pixels. Original example: 12.
scaleBarFont = -1; // EDIT: Scale bar font size. Original example: 32.

// CONFIGURATION CHECK
if (channelLIVE < 1 || channelLIVE != floor(channelLIVE) ||
    channelDEAD < 1 || channelDEAD != floor(channelDEAD) ||
    liveBackgroundSubtract < 0 ||
    deadBackgroundSubtract < 0 ||
    liveMedianRadius < 0 ||
    deadMedianRadius < 0 ||
    liveDisplayMin < 0 ||
    liveDisplayMax < 0 ||
    liveDisplayMax <= liveDisplayMin ||
    deadDisplayMin < 0 ||
    deadDisplayMax < 0 ||
    deadDisplayMax <= deadDisplayMin ||
    scaleBarWidth < 0 ||
    scaleBarHeight < 0 ||
    scaleBarThickness < 0 ||
    scaleBarFont < 0)
    exit("Fill in and review all USER PARAMETERS before running this macro.");

if (channelLIVE == channelDEAD)
    exit("Assign a distinct input channel to each marker.");

// PROCESSING - original operation order retained
cond = getString("Enter the image condition", "");
time = getString("Enter the image timepoint", "");
outputFolder = getDirectory("Select the output folder:");
outputFilename = getString("Enter the output TIFF filename", time + "_" + cond + ".tif");
if (outputFilename == "") exit("No output filename entered.");
outputPath = outputFolder + outputFilename;

run("Duplicate...", "title=[] duplicate");
run("Split Channels");

// Process the LIVE channel.
selectImage("C" + channelLIVE + "-");

// Subtract a fixed background intensity; this changes pixel values.
run("Subtract...", "value=" + liveBackgroundSubtract + " stack");

// Reduce local noise with the configured median filter.
run("Median...", "radius=" + liveMedianRadius + " stack");

// Collapse the Z stack by retaining the maximum intensity at each XY position.
run("Z Project...", "projection=[Max Intensity]");

setMinAndMax(liveDisplayMin, liveDisplayMax);

// Apply the display mapping to the image, preserving the original command.
run("Apply LUT");
rename("LIVE");

// Process the DEAD channel.
selectImage("C" + channelDEAD + "-");
run("Subtract...", "value=" + deadBackgroundSubtract + " stack");
run("Median...", "radius=" + deadMedianRadius + " stack");
run("Z Project...", "projection=[Max Intensity]");
setMinAndMax(deadDisplayMin, deadDisplayMax);
run("Apply LUT");
rename("DEAD");

// Merge DEAD into red and LIVE into green.
run("Merge Channels...", "c1=DEAD c2=LIVE create keep");

run("Stack to RGB");
run("Scale Bar...", "width=" + scaleBarWidth + " height=" + scaleBarHeight +
    " thickness=" + scaleBarThickness + " font=" + scaleBarFont + " bold");

saveAs("Tiff", outputPath);

// Original cleanup: close all open image windows.
close("*");