// ============================================================================
// Create an RGB figure from Amylase, CK19, DAPI and Ki67 maximum projections.
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
channelAmylase = -1; // EDIT: Input channel index (positive integer). Original example: 3.
channelCK19 = -1; // EDIT: Input channel index (positive integer). Original example: 4.
channelDAPI = -1; // EDIT: Input channel index (positive integer). Original example: 1.
channelKi67 = -1; // EDIT: Input channel index (positive integer). Original example: 2.

amylaseBackgroundSubtract = -1; // EDIT: Constant intensity subtracted from the entire stack. Original example: 25.
ck19BackgroundSubtract = -1; // EDIT: Constant intensity subtracted from the entire stack. Original example: 25.
dapiBackgroundSubtract = -1; // EDIT: Constant intensity subtracted from the entire stack. Original example: 25.
ki67BackgroundSubtract = -1; // EDIT: Constant intensity subtracted from the entire stack. Original example: 25.

amylaseDisplayMin = -1; // EDIT: Display lower intensity limit. Original example: 0.
amylaseDisplayMax = -1; // EDIT: Display upper intensity limit. Original example: 230.
dapiDisplayMin = -1; // EDIT: Display lower intensity limit. Original example: 0.
dapiDisplayMax = -1; // EDIT: Display upper intensity limit. Original example: 233.

scaleBarWidth = -1; // EDIT: Scale bar width in calibrated image units. Original example: 200.
scaleBarHeight = -1; // EDIT: Scale bar height in calibrated image units. Original example: 200.
scaleBarThickness = -1; // EDIT: Scale bar thickness in pixels. Original example: 12.
scaleBarFont = -1; // EDIT: Scale bar font size. Original example: 32.

// CONFIGURATION CHECK
if (channelAmylase < 1 || channelAmylase != floor(channelAmylase) ||
    channelCK19 < 1 || channelCK19 != floor(channelCK19) ||
    channelDAPI < 1 || channelDAPI != floor(channelDAPI) ||
    channelKi67 < 1 || channelKi67 != floor(channelKi67) ||
    amylaseBackgroundSubtract < 0 ||
    ck19BackgroundSubtract < 0 ||
    dapiBackgroundSubtract < 0 ||
    ki67BackgroundSubtract < 0 ||
    amylaseDisplayMin < 0 ||
    amylaseDisplayMax < 0 ||
    amylaseDisplayMax <= amylaseDisplayMin ||
    dapiDisplayMin < 0 ||
    dapiDisplayMax < 0 ||
    dapiDisplayMax <= dapiDisplayMin ||
    scaleBarWidth < 0 ||
    scaleBarHeight < 0 ||
    scaleBarThickness < 0 ||
    scaleBarFont < 0)
    exit("Fill in and review all USER PARAMETERS before running this macro.");

if (channelAmylase == channelCK19 ||
    channelAmylase == channelDAPI ||
    channelAmylase == channelKi67 ||
    channelCK19 == channelDAPI ||
    channelCK19 == channelKi67 ||
    channelDAPI == channelKi67)
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

// Process Amylase.
selectImage("C" + channelAmylase + "-");

// Subtract a fixed background intensity; this changes pixel values.
run("Subtract...", "value=" + amylaseBackgroundSubtract + " stack");

// Collapse the Z stack by retaining the maximum intensity at each XY position.
run("Z Project...", "projection=[Max Intensity]");

setMinAndMax(amylaseDisplayMin, amylaseDisplayMax);

// Apply the display mapping to the image, preserving the original command.
run("Apply LUT");
rename("Amylase");

// Process CK19.
selectImage("C" + channelCK19 + "-");
run("Subtract...", "value=" + ck19BackgroundSubtract + " stack");
run("Z Project...", "projection=[Max Intensity]");
rename("CK19");

// Process DAPI.
selectImage("C" + channelDAPI + "-");
run("Subtract...", "value=" + dapiBackgroundSubtract + " stack");
run("Z Project...", "projection=[Max Intensity]");
setMinAndMax(dapiDisplayMin, dapiDisplayMax);
run("Apply LUT");
rename("DAPI");

// Process Ki67.
selectImage("C" + channelKi67 + "-");
run("Subtract...", "value=" + ki67BackgroundSubtract + " stack");
run("Z Project...", "projection=[Max Intensity]");
rename("Ki67");

// Assign processed markers to the original output color slots.
run("Merge Channels...", "c1=Amylase c2=CK19 c3=DAPI c4=Ki67 create keep");

run("Stack to RGB");
run("Scale Bar...", "width=" + scaleBarWidth + " height=" + scaleBarHeight +
    " thickness=" + scaleBarThickness + " font=" + scaleBarFont + " bold");

saveAs("Tiff", outputPath);

// Original cleanup: close all open image windows.
close("*");