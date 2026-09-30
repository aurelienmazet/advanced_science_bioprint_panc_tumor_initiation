// ============================================================================
// Measure a background ROI, correct a stack, project it and create depth coding.
// ============================================================================
// IMPORTANT: Fill in USER PARAMETERS and check channel assignments before running.
// Empty strings and -1 values deliberately prevent use of unchecked settings.
// Original values below are examples, not validated defaults for another dataset.
// Input: the active ImageJ/Fiji stack.
// Requires Temporal-Color Code. Its output window is assumed to be MAX_colored.
// The measured ROI mean is NOT read by the original code: subtraction stays manual.
// The background ROI remains selected during filtering/projection as in the original.
// Review ROI scope in Fiji; do not assume that processing covers the full image.
// Depth coloring uses Z slices; it is not a time-course analysis or 3D reconstruction.

// USER PARAMETERS
backgroundSubtract = -1; // EDIT: Constant intensity subtracted from the entire stack (not rolling background). Original example: 44.
medianRadius = -1; // EDIT: Median filter radius in pixels. Original example: 1.
displayMin = -1; // EDIT: Display lower intensity limit (original image intensity units). Original example: 0.
displayMax = -1; // EDIT: Display upper intensity limit (may exceed 255 for high-bit-depth inputs). Original example: 141.
scaleBarWidth = -1; // EDIT: Scale bar width in calibrated image units. Original example: 50.
scaleBarHeight = -1; // EDIT: Scale bar height in calibrated image units. Original example: 50.
scaleBarThickness = -1; // EDIT: Scale bar thickness in pixels. Original example: 6.
backgroundRoiX = -1; // EDIT: Background ROI X in pixels. Original example: 735.
backgroundRoiY = -1; // EDIT: Background ROI Y in pixels. Original example: 80.
backgroundRoiWidth = -1; // EDIT: Background ROI Width in pixels. Original example: 112.
backgroundRoiHeight = -1; // EDIT: Background ROI Height in pixels. Original example: 113.
depthChannel = -1; // EDIT: Channel used for depth coding (positive integer). Original example: 1.
depthStartSlice = -1; // EDIT: First slice for depth coding (one-based). Original example: 1.
depthEndSlice = -1; // EDIT: Last slice for depth coding (one-based). Original example: 42.

// CONFIGURATION CHECK
if (backgroundSubtract < 0 ||
    medianRadius < 0 ||
    displayMin < 0 ||
    displayMax < 0 ||
    displayMax <= displayMin ||
    scaleBarWidth < 0 ||
    scaleBarHeight < 0 ||
    scaleBarThickness < 0 ||
    backgroundRoiX < 0 ||
    backgroundRoiY < 0 ||
    backgroundRoiWidth < 0 ||
    backgroundRoiHeight < 0 ||
    depthChannel < 0 ||
    depthStartSlice < 0 ||
    depthEndSlice < 0 ||
    depthChannel < 1 || depthChannel != floor(depthChannel) ||
    depthStartSlice < 1 || depthEndSlice < depthStartSlice)
    exit("Fill in and review all USER PARAMETERS before running this macro.");
sourceTitle = getTitle();

// PROCESSING - original operation order retained
makeRectangle(backgroundRoiX, backgroundRoiY, backgroundRoiWidth, backgroundRoiHeight);
// Measure the selected background ROI using current ImageJ measurement settings.
run("Measure");
// Subtract a fixed background intensity; this changes pixel values.
run("Subtract...", "value=" + backgroundSubtract + " stack");
// Reduce local noise with the configured median filter.
run("Median...", "radius=" + medianRadius + " stack");
Property.set("CompositeProjection", "Sum");
Stack.setDisplayMode("composite");
// Collapse the Z stack by retaining the maximum intensity at each XY position.
run("Z Project...", "projection=[Max Intensity]");
selectImage(sourceTitle);
run("Split Channels");
selectImage("C" + depthChannel + "-" + sourceTitle);
// Color-code the configured slice range using the Fire LUT.
run("Temporal-Color Code", "lut=Fire start=" + depthStartSlice + " end=" + depthEndSlice + " create");
selectImage("MAX_colored");
setMinAndMax(displayMin, displayMax);
selectImage("MAX_" + sourceTitle);
run("Scale Bar...", "width=" + scaleBarWidth + " height=" + scaleBarHeight + " thickness=" + scaleBarThickness + " bold overlay");