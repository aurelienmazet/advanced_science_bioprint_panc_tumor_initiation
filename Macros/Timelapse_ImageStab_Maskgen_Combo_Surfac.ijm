// ============================================================================
// TIMEPOINT STABILIZATION, MASK GENERATION AND OVERLAP MEASUREMENTS
// ============================================================================
// IMPORTANT: Fill in and review USER PARAMETERS before running this macro.
// Check channel/timepoint assignments, filename layout and segmentation settings.
// Requires ImageJ/Fiji with the Image Stabilizer plugin installed.
// The three selected channels represent acquisition timepoints, not markers.
// Workflow: recursively open matching files, stabilize a duplicate, split channels,
// generate binary masks, measure later/reference intersections and individual masks.
// Measurements remain in ImageJ tables. This macro does NOT save files to disk.
// As in the original macro, all open image windows are closed after each file.
// Run in a dedicated session and save unrelated images before starting.
//
// Fill-in values use -1 or empty strings so the macro stops until configured.
// Original values are documented as examples, not validated recommendations.

// ============================================================================
// USER PARAMETERS - EDIT BEFORE RUNNING
// ============================================================================
fileSuffix = "";                  // Example: "stack.tif" (case-sensitive).
referenceChannel = -1;            // Example: 1 (original reference: J1).
secondChannel = -1;               // Example: 2 (original second timepoint: J7).
thirdChannel = -1;                // Example: 3 (original third timepoint: J14).
referenceLabel = "";              // Example: "J1"; used in measurement titles.
secondLabel = "";                 // Example: "J7".
thirdLabel = "";                  // Example: "J14".
roiFieldIndex = -1;               // Example: 0; underscore-separated filename field.
conditionFieldIndex = -1;         // Example: 1; field indices start at ZERO.
rollingRadius = -1;               // Example: 5; background radius in pixels.
thresholdMin = -1;                // Example: 90; lower threshold after 8-bit conversion.
thresholdMax = -1;                // Example: 255; upper threshold (0-255).

// Review these original algorithm settings; change only when appropriate.
stabilizerTransformation = "Translation";
stabilizerPyramidLevels = 1;
stabilizerUpdateCoefficient = 0.5;
stabilizerMaximumIterations = 200;
stabilizerErrorTolerance = 0.0000001;
autoThresholdMethod = "Shanbhag dark no-reset";
// The manual threshold below overrides the automatic threshold's numeric bounds.
particleOptions = "clear summarize";
// Retains the original options: no explicit size/circularity filter or stack option.
// Check ImageJ measurement settings and stack handling before using the results.

// ============================================================================
// CONFIGURATION CHECK AND FOLDER SELECTION
// ============================================================================
if (fileSuffix == "" || referenceLabel == "" || secondLabel == "" || thirdLabel == "")
    exit("Fill in the suffix and timepoint labels in USER PARAMETERS.");
if (referenceChannel < 1 || secondChannel < 1 || thirdChannel < 1 ||
    referenceChannel != floor(referenceChannel) || secondChannel != floor(secondChannel) || thirdChannel != floor(thirdChannel))
    exit("Set three positive integer channel numbers in USER PARAMETERS.");
if (referenceChannel == secondChannel || referenceChannel == thirdChannel || secondChannel == thirdChannel)
    exit("Choose three distinct timepoint channels.");
if (roiFieldIndex < 0 || conditionFieldIndex < 0 || roiFieldIndex != floor(roiFieldIndex) || conditionFieldIndex != floor(conditionFieldIndex))
    exit("Set non-negative integer filename field indices in USER PARAMETERS.");
if (rollingRadius < 0 || thresholdMin < 0 || thresholdMax > 255 || thresholdMax < thresholdMin)
    exit("Set a background radius and valid 8-bit threshold bounds in USER PARAMETERS.");
input = getDirectory("Select the input folder:");
// Kept from the original workflow; output is currently unused (no save commands).
output = getDirectory("Select the output folder (currently unused):");
suffix = fileSuffix;
processFolder(input);

// Visit folders recursively and process files whose names end with the suffix.
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

function processFile(input, output, file) {
    // Use the filename passed to this function rather than the caller's loop index.
    open(input + File.separator + file);
    title = getTitle();
    filename = title.replace(".tif", "");
    parts = split(filename, "_");
    if (roiFieldIndex >= parts.length || conditionFieldIndex >= parts.length)
        exit("Filename does not contain the configured fields: " + file);
    roi = parts[roiFieldIndex];
    condition = parts[conditionFieldIndex];
    rename(condition + "_" + roi);

    // Keep the source image and process a duplicate with the original empty title.
    // Split Channels therefore produces the window names C1-, C2-, C3-, etc.
    run("Duplicate...", "title=[] duplicate");
    run("Image Stabilizer", "transformation=" + stabilizerTransformation +
        " maximum_pyramid_levels=" + stabilizerPyramidLevels +
        " template_update_coefficient=" + stabilizerUpdateCoefficient +
        " maximum_iterations=" + stabilizerMaximumIterations +
        " error_tolerance=" + stabilizerErrorTolerance);
    run("Split Channels");

    // Segment the timepoint assigned to referenceChannel.
    selectImage("C" + referenceChannel + "-");
    // Remove spatial calibration: subsequent areas are expressed in square pixels.
    run("Set Scale...", "distance=0 known=0 unit=pixel");
    run("8-bit");
    // Remove smooth background, then emphasize boundaries before thresholding.
    run("Subtract Background...", "rolling=" + rollingRadius);
    run("Find Edges");
    setAutoThreshold(autoThresholdMethod);
    setThreshold(thresholdMin, thresholdMax, "raw");
    // Create white foreground on black background and fill enclosed regions.
    setOption("BlackBackground", true);
    run("Convert to Mask");
    run("Fill Holes");

    // Segment the timepoint assigned to secondChannel.
    selectImage("C" + secondChannel + "-");
    // Remove spatial calibration: subsequent areas are expressed in square pixels.
    run("Set Scale...", "distance=0 known=0 unit=pixel");
    run("8-bit");
    // Remove smooth background, then emphasize boundaries before thresholding.
    run("Subtract Background...", "rolling=" + rollingRadius);
    run("Find Edges");
    setAutoThreshold(autoThresholdMethod);
    setThreshold(thresholdMin, thresholdMax, "raw");
    // Create white foreground on black background and fill enclosed regions.
    setOption("BlackBackground", true);
    run("Convert to Mask");
    run("Fill Holes");

    // Segment the timepoint assigned to thirdChannel.
    selectImage("C" + thirdChannel + "-");
    // Remove spatial calibration: subsequent areas are expressed in square pixels.
    run("Set Scale...", "distance=0 known=0 unit=pixel");
    run("8-bit");
    // Remove smooth background, then emphasize boundaries before thresholding.
    run("Subtract Background...", "rolling=" + rollingRadius);
    run("Find Edges");
    setAutoThreshold(autoThresholdMethod);
    setThreshold(thresholdMin, thresholdMax, "raw");
    // Create white foreground on black background and fill enclosed regions.
    setOption("BlackBackground", true);
    run("Convert to Mask");
    run("Fill Holes");

    // AND retains only foreground pixels shared with the reference mask.
    // This is spatial overlap, not object tracking or a surface reconstruction.
    imageCalculator("AND create", "C" + thirdChannel + "-", "C" + referenceChannel + "-");
    selectImage("Result of C" + thirdChannel + "-");
    rename(condition + "_" + roi + "_" + thirdLabel + "and" + referenceLabel);
    run("Analyze Particles...", particleOptions);

    // AND retains only foreground pixels shared with the reference mask.
    // This is spatial overlap, not object tracking or a surface reconstruction.
    imageCalculator("AND create", "C" + secondChannel + "-", "C" + referenceChannel + "-");
    selectImage("Result of C" + secondChannel + "-");
    rename(condition + "_" + roi + "_" + secondLabel + "and" + referenceLabel);
    run("Analyze Particles...", particleOptions);

    // Measure the individual binary mask with the original particle options.
    selectImage("C" + referenceChannel + "-");
    rename(condition + "_" + roi + "_" + referenceLabel);
    run("Analyze Particles...", particleOptions);

    // Measure the individual binary mask with the original particle options.
    selectImage("C" + secondChannel + "-");
    rename(condition + "_" + roi + "_" + secondLabel);
    run("Analyze Particles...", particleOptions);

    // Measure the individual binary mask with the original particle options.
    selectImage("C" + thirdChannel + "-");
    rename(condition + "_" + roi + "_" + thirdLabel);
    run("Analyze Particles...", particleOptions);

    // Original cleanup behavior: closes ALL open image windows.
    close("*");
}
