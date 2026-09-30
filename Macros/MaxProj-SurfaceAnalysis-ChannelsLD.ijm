// ============================================================================
// Batch segmentation and projected-area measurements of LIVE and DEAD channels.
// ============================================================================
// IMPORTANT: Fill in USER PARAMETERS and check channel assignments before running.
// Empty strings and -1 values deliberately prevent use of unchecked settings.
// Original values below are examples, not validated defaults for another dataset.
// Input: TIFF files in a selected folder and its subfolders.
// The requested output folder remains unused: measurements stay in ImageJ tables.
// Areas come from 2D Z projections, not volumes; units follow the image calibration.
// Analyze Particles retains "clear summarize" without an explicit size filter.
// Fill Holes is applied to LIVE only; DEAD is measured without hole filling.
// WARNING: original cleanup closes ALL open image windows; use a dedicated session.
// Empty duplicate title retained: Split Channels is expected to produce C1-, C2-, etc.
// Avoid existing windows with those names and verify channel availability.

// USER PARAMETERS
var fileSuffix = ""; // EDIT: Case-sensitive filename suffix. Original example: ".tif".

var channelLIVE = -1; // EDIT: Input channel index (positive integer). Original example: 1.
var channelDEAD = -1; // EDIT: Input channel index (positive integer). Original example: 2.

var roiFieldIndex = -1; // EDIT: Zero-based underscore-separated filename field. Original example: 10.
var conditionFieldIndex = -1; // EDIT: Zero-based underscore-separated filename field. Original example: 5.
var timeIndexFieldIndex = -1; // EDIT: Zero-based underscore-separated filename field. Original example: 4.

var liveBackgroundSubtract = -1; // EDIT: Constant intensity subtraction. Original example: 44.
var deadBackgroundSubtract = -1; // EDIT: Constant intensity subtraction. Original example: 6.

var liveMedianRadius = -1; // EDIT: Median filter radius in pixels. Original example: 1.
var deadMedianRadius = -1; // EDIT: Median filter radius in pixels. Original example: 1.

var liveDisplayMin = -1; // EDIT: Display lower intensity limit. Original example: 0.
var liveDisplayMax = -1; // EDIT: Display upper intensity limit. Original example: 341.
// Display limits use original image intensity units and may exceed 255.

var liveThresholdMethod = ""; // EDIT: Original example: "Huang dark no-reset".
var deadThresholdMethod = ""; // EDIT: Original example: "Intermodes dark no-reset".
// Retain the original methods and options to reproduce the previous segmentation.

var measurementPrefix = ""; // EDIT: Prefix for measurement titles. Original example: "WT".

// Shared folder settings used by the processing functions.
var output = "", suffix = "";

// CONFIGURATION CHECK
if (fileSuffix == "" ||
    channelLIVE < 1 || channelLIVE != floor(channelLIVE) ||
    channelDEAD < 1 || channelDEAD != floor(channelDEAD) ||
    roiFieldIndex < 0 || roiFieldIndex != floor(roiFieldIndex) ||
    conditionFieldIndex < 0 || conditionFieldIndex != floor(conditionFieldIndex) ||
    timeIndexFieldIndex < 0 || timeIndexFieldIndex != floor(timeIndexFieldIndex) ||
    liveBackgroundSubtract < 0 ||
    deadBackgroundSubtract < 0 ||
    liveMedianRadius < 0 ||
    deadMedianRadius < 0 ||
    liveDisplayMin < 0 ||
    liveDisplayMax < 0 ||
    liveDisplayMax <= liveDisplayMin ||
    liveThresholdMethod == "" ||
    deadThresholdMethod == "" ||
    measurementPrefix == "")
    exit("Fill in and review all USER PARAMETERS before running this macro.");

if (channelLIVE == channelDEAD)
    exit("Assign a distinct input channel to each marker.");

// FOLDER SELECTION
input = getDirectory("Select the input folder:");
output = getDirectory("Select the output folder (currently unused):");
suffix = fileSuffix;
processFolder(input);

// Visit folders recursively and process matching filenames.
function processFolder(input) {
    list = getFileList(input);
    list = Array.sort(list);

    for (i = 0; i < list.length; i++) {
        if (File.isDirectory(input + File.separator + list[i]))
            processFolder(input + File.separator + list[i]);

        if (endsWith(list[i], suffix))
            processFile(input, output, list[i]);
    }
}

// Process one file using the original operation order.
function processFile(input, output, file) {
    open(input + File.separator + file);

    // Extract the configured metadata fields from the filename.
    title = getTitle();
    filename = title.replace(".tif", "");
    parts = split(filename, "_");

    if (roiFieldIndex >= parts.length ||
        conditionFieldIndex >= parts.length ||
        timeIndexFieldIndex >= parts.length)
        exit("Filename does not contain the configured fields: " + file);

    roi = parts[roiFieldIndex];
    condition = parts[conditionFieldIndex];
    timeIndex = parts[timeIndexFieldIndex];

    rename(condition + "_" + roi + "_" + timeIndex);

    run("Duplicate...", "title=[] duplicate");
    run("Split Channels");

    // Process the LIVE channel.
    selectImage("C" + channelLIVE + "-");

    // Subtract a fixed background intensity; this changes pixel values.
    run("Subtract...", "value=" + liveBackgroundSubtract + " stack");

    // Reduce local noise.
    run("Median...", "radius=" + liveMedianRadius + " stack");

    // Generate a 2D maximum-intensity projection.
    run("Z Project...", "projection=[Max Intensity]");

    setMinAndMax(liveDisplayMin, liveDisplayMax);
    setAutoThreshold(liveThresholdMethod);
    setOption("BlackBackground", true);

    // Generate the binary mask and fill enclosed regions.
    run("Convert to Mask");
    run("Fill Holes");

    rename(measurementPrefix + "_" + timeIndex + "_" + condition + "_" + roi + "_LIVE");

    // Measure segmented regions using the original particle-analysis options.
    run("Analyze Particles...", "clear summarize");

    // Process the DEAD channel.
    selectImage("C" + channelDEAD + "-");
    run("Subtract...", "value=" + deadBackgroundSubtract + " stack");
    run("Median...", "radius=" + deadMedianRadius + " stack");
    run("Z Project...", "projection=[Max Intensity]");

    setAutoThreshold(deadThresholdMethod);
    setOption("BlackBackground", true);
    run("Convert to Mask");

    // No hole filling is applied to DEAD in the original workflow.
    rename(measurementPrefix + "_" + timeIndex + "_" + condition + "_" + roi + "_DEAD");
    run("Analyze Particles...", "clear summarize");

    // Original cleanup: close all open image windows.
    close("*");
}