// ============================================================================
// Batch segmentation and projected-area measurements of four ADM markers.
// ============================================================================
// IMPORTANT: Fill in USER PARAMETERS and check channel assignments before running.
// Empty strings and -1 values deliberately prevent use of unchecked settings.
// Original values below are examples, not validated defaults for another dataset.
// Input: TIFF files in a selected folder and its subfolders.
// The requested output folder remains unused: measurements stay in ImageJ tables.
// Areas come from 2D Z projections, not volumes; units follow the image calibration.
// Analyze Particles retains "clear summarize" without an explicit size filter.
// No background subtraction or hole filling is active in this pipeline.
// Measurement titles share the configured prefix; source filenames are not added.
// WARNING: original cleanup closes ALL open image windows; use a dedicated session.
// Empty duplicate title retained: Split Channels is expected to produce C1-, C2-, etc.
// Avoid existing windows with those names and verify channel availability.

// USER PARAMETERS
var fileSuffix = ""; // EDIT: Case-sensitive filename suffix. Original example: ".tif".

var channelAmylase = -1; // EDIT: Input channel index (positive integer). Original example: 3.
var channelCK19 = -1; // EDIT: Input channel index (positive integer). Original example: 4.
var channelDAPI = -1; // EDIT: Input channel index (positive integer). Original example: 1.
var channelKi67 = -1; // EDIT: Input channel index (positive integer). Original example: 2.

var amylaseMedianRadius = -1; // EDIT: Median filter radius in pixels. Original example: 1.
var ck19MedianRadius = -1; // EDIT: Median filter radius in pixels. Original example: 1.
var dapiMedianRadius = -1; // EDIT: Median filter radius in pixels. Original example: 1.
var ki67MedianRadius = -1; // EDIT: Median filter radius in pixels. Original example: 1.

var amylaseThresholdMethod = ""; // EDIT: Original example: "Moments dark no-reset".
var ck19ThresholdMethod = ""; // EDIT: Original example: "Moments dark no-reset".
var dapiThresholdMethod = ""; // EDIT: Original example: "Default dark no-reset".
var ki67ThresholdMethod = ""; // EDIT: Original example: "Moments dark no-reset".
// Retain the original methods and options to reproduce the previous segmentation.

var measurementPrefix = ""; // EDIT: Sample/timepoint prefix. Original example: "KC_J14".

// Shared folder settings used by the processing functions.
var output = "", suffix = "";

// CONFIGURATION CHECK
if (fileSuffix == "" ||
    channelAmylase < 1 || channelAmylase != floor(channelAmylase) ||
    channelCK19 < 1 || channelCK19 != floor(channelCK19) ||
    channelDAPI < 1 || channelDAPI != floor(channelDAPI) ||
    channelKi67 < 1 || channelKi67 != floor(channelKi67) ||
    amylaseMedianRadius < 0 ||
    ck19MedianRadius < 0 ||
    dapiMedianRadius < 0 ||
    ki67MedianRadius < 0 ||
    amylaseThresholdMethod == "" ||
    ck19ThresholdMethod == "" ||
    dapiThresholdMethod == "" ||
    ki67ThresholdMethod == "" ||
    measurementPrefix == "")
    exit("Fill in and review all USER PARAMETERS before running this macro.");

if (channelAmylase == channelCK19 ||
    channelAmylase == channelDAPI ||
    channelAmylase == channelKi67 ||
    channelCK19 == channelDAPI ||
    channelCK19 == channelKi67 ||
    channelDAPI == channelKi67)
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

    title = getTitle();
    filename = title.replace(".tif", "");

    run("Duplicate...", "title=[] duplicate");
    run("Split Channels");

    // Process Amylase: median filter, maximum projection and threshold.
    selectImage("C" + channelAmylase + "-");
    run("Median...", "radius=" + amylaseMedianRadius + " stack");
    run("Z Project...", "projection=[Max Intensity]");
    setAutoThreshold(amylaseThresholdMethod);
    setOption("BlackBackground", true);
    run("Convert to Mask");

    // Measure the binary foreground using the original particle-analysis options.
    rename(measurementPrefix + "_Amylase");
    run("Analyze Particles...", "clear summarize");

    // Process CK19.
    selectImage("C" + channelCK19 + "-");
    run("Median...", "radius=" + ck19MedianRadius + " stack");
    run("Z Project...", "projection=[Max Intensity]");
    setAutoThreshold(ck19ThresholdMethod);
    setOption("BlackBackground", true);
    run("Convert to Mask");
    rename(measurementPrefix + "_CK19");
    run("Analyze Particles...", "clear summarize");

    // Process DAPI.
    selectImage("C" + channelDAPI + "-");
    run("Median...", "radius=" + dapiMedianRadius + " stack");
    run("Z Project...", "projection=[Max Intensity]");
    setAutoThreshold(dapiThresholdMethod);
    setOption("BlackBackground", true);
    run("Convert to Mask");
    rename(measurementPrefix + "_DAPI");
    run("Analyze Particles...", "clear summarize");

    // Process Ki67.
    selectImage("C" + channelKi67 + "-");
    run("Median...", "radius=" + ki67MedianRadius + " stack");
    run("Z Project...", "projection=[Max Intensity]");
    setAutoThreshold(ki67ThresholdMethod);
    setOption("BlackBackground", true);
    run("Convert to Mask");
    rename(measurementPrefix + "_Ki67");
    run("Analyze Particles...", "clear summarize");

    // Original cleanup: close all open image windows.
    close("*");
}