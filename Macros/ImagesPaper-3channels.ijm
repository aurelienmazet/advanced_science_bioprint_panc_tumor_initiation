// ============================================================================
// Create an RGB figure: OPN in red, CK19 in green and DAPI in blue.
// ============================================================================
// IMPORTANT: Fill in USER PARAMETERS and check channel assignments before running.
// Empty strings and -1 values deliberately prevent use of unchecked settings.
// Original values below are examples, not validated defaults for another dataset.
// Input: the active ImageJ/Fiji stack.
// No background subtraction, median filtering or LUT application is active.
// Figure preparation only. RGB conversion and scale bars alter the exported image.
// Verify spatial calibration before adding a scale bar.
// WARNING: original cleanup closes ALL open image windows; use a dedicated session.
// Empty duplicate title retained: Split Channels is expected to produce C1-, C2-, etc.
// Avoid existing windows with those names and verify channel availability.

// USER PARAMETERS
channelOPN = -1; // EDIT: Input channel index (positive integer). Original example: 2.
channelCK19 = -1; // EDIT: Input channel index (positive integer). Original example: 3.
channelDAPI = -1; // EDIT: Input channel index (positive integer). Original example: 1.

scaleBarWidth = -1; // EDIT: Scale bar width in calibrated image units. Original example: 200.
scaleBarHeight = -1; // EDIT: Scale bar height in calibrated image units. Original example: 200.
scaleBarThickness = -1; // EDIT: Scale bar thickness in pixels. Original example: 12.
scaleBarFont = -1; // EDIT: Scale bar font size. Original example: 32.

// CONFIGURATION CHECK
if (channelOPN < 1 || channelOPN != floor(channelOPN) ||
    channelCK19 < 1 || channelCK19 != floor(channelCK19) ||
    channelDAPI < 1 || channelDAPI != floor(channelDAPI) ||
    scaleBarWidth < 0 ||
    scaleBarHeight < 0 ||
    scaleBarThickness < 0 ||
    scaleBarFont < 0)
    exit("Fill in and review all USER PARAMETERS before running this macro.");

if (channelOPN == channelCK19 ||
    channelOPN == channelDAPI ||
    channelCK19 == channelDAPI)
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

// Project the OPN channel.
selectImage("C" + channelOPN + "-");
run("Z Project...", "projection=[Max Intensity]");
rename("OPN");

// Project the CK19 channel.
selectImage("C" + channelCK19 + "-");
run("Z Project...", "projection=[Max Intensity]");
rename("CK19");

// Project the DAPI channel.
selectImage("C" + channelDAPI + "-");
run("Z Project...", "projection=[Max Intensity]");
rename("DAPI");

// Merge OPN into red, CK19 into green and DAPI into blue.
run("Merge Channels...", "c1=OPN c2=CK19 c3=DAPI create keep");

run("Stack to RGB");
run("Scale Bar...", "width=" + scaleBarWidth + " height=" + scaleBarHeight +
    " thickness=" + scaleBarThickness + " font=" + scaleBarFont + " bold");

saveAs("Tiff", outputPath);

// Original cleanup: close all open image windows.
close("*");