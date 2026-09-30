# advanced\_science\_bioprint\_panc\_tumor\_initiation

Image and data analysis scripts associated with paper "Bioprinted Stiffness‑Tunable Pancreatic Microniches to Decode Early Tumor Initiation Mechanisms"

# Image processing scripts

This repository contains eight ImageJ/Fiji macros and one Python script for preparing microscopy figures, generating timepoint stacks, visualizing depth and measuring segmented image areas.

The scripts are configurable templates. Required user settings must be filled in before execution.

## Requirements

### ImageJ/Fiji

Use ImageJ/Fiji for the `.ijm` files.

Additional plugins are required for:

- `Timelapse_ImageStab_Maskgen_Combo_Surfac(1).ijm`: Image Stabilizer.
- `DepthCoding.ijm`: Temporal-Color Code.

Check that the required commands are available in your installation.

### Python

Use Python 3.10 or later for `stacker_timelapse_to_imagej(1).py`.

Install the required packages:

```bash
python -m pip install numpy pillow tifffile
```

Tkinter is used for the folder-selection dialog when available.

Run the script with:

```bash
python "stacker_timelapse_to_imagej(1).py"
```

## Configure before running

Each script contains a `USER PARAMETERS` section.

Replace the required placeholders:

- `-1` for numerical parameters.
- `""` for required text parameters.
- `None` for required Python settings.

Configuration checks stop processing when required settings remain unset.

Values provided in comments are examples from the original dataset. They are not validated defaults for other images.

Review the following before running:

- Input channel assignments.
- Acquisition timepoints and their order.
- Background correction and filtering settings.
- Threshold methods and intensity limits.
- Filename conventions and metadata field indices.
- Spatial calibration and scale-bar dimensions.
- Input folders and output filenames.

ImageJ channel indices start at **1**. Filename field indices used after splitting names on underscores start at **0**.

## Script overview

| File | Purpose | Main output |
| --- | --- | --- |
| `stacker_timelapse_to_imagej(1).py` | Group images by acquisition timepoint and assemble TIFF stacks | ImageJ-compatible TIFF stacks saved beside the source images |
| `Timelapse_ImageStab_Maskgen_Combo_Surfac(1).ijm` | Stabilize images, generate three timepoint masks and measure their spatial overlap | Particle-analysis summaries for individual masks and reference-mask intersections |
| `ImagesPaper.ijm` | Prepare a general RGB maximum-intensity projection | RGB TIFF figure with a scale bar |
| `ImagesPaper-3channels.ijm` | Prepare a three-channel OPN/CK19/DAPI figure | RGB TIFF figure with a scale bar |
| `ImagesPaper-4channels.ijm` | Prepare a four-channel Amylase/CK19/DAPI/Ki67 figure | RGB TIFF figure with a scale bar |
| `ImagesPaperLD.ijm` | Prepare a Live/Dead figure | RGB TIFF figure with DEAD in red and LIVE in green |
| `DepthCoding.ijm` | Measure a background region, prepare a projection and color-code a selected channel by depth | Maximum-intensity projection and depth-colored image windows |
| `MaxProj-SurfaceAnalysis-Channels_ADM.ijm` | Measure segmented projected areas of four ADM-related markers | Particle-analysis summaries for Amylase, CK19, DAPI and Ki67 |
| `MaxProj-SurfaceAnalysis-ChannelsLD.ijm` | Measure segmented projected areas of Live/Dead channels | Particle-analysis summaries for LIVE and DEAD |

## Individual workflows

### `stacker_timelapse_to_imagej(1).py`

Recursively visits the selected root folder and its subfolders.

Within each folder, it:

1. Finds TIFF files with accepted extensions.
2. Excludes filenames containing the configured substring.
3. Detects acquisition-timepoint tokens using the configured prefix.
4. Groups filenames that match after replacing the timepoint token.
5. Checks that all configured timepoints are present.
6. Reads images and harmonizes their dimensions and pixel types.
7. Stacks them in the order specified by `EXPECTED_TIMEPOINTS`.
8. Writes an ImageJ-compatible TIFF beside the source images.

The timepoint prefix is configurable, for example `D` or `J`.

If duplicate timepoints occur within a group, the first filename in sorted order is retained and the duplicate is reported.

Incomplete groups are skipped. Existing output files are not overwritten: a numerical suffix is added to the new output filename.

A summary reports created stacks and skipped files.

### `Timelapse_ImageStab_Maskgen_Combo_Surfac(1).ijm`

Recursively processes files matching the configured suffix.

For each file, it:

1. Extracts ROI and condition fields from the filename.
2. Duplicates the image.
3. Runs Image Stabilizer with the configured settings.
4. Splits the image into channels representing three acquisition timepoints.
5. Removes spatial calibration and converts the selected images to 8-bit.
6. Applies rolling-background subtraction and edge detection.
7. Applies a fixed intensity threshold, creates binary masks and fills holes.
8. Creates AND intersections between each later-timepoint mask and the reference mask.
9. Runs particle analysis on the two intersections and the three individual masks.

The three selected channels represent **timepoints**, not fluorescence markers.

The manual threshold overrides the numerical bounds produced by the preceding automatic-threshold command.

Areas are measured in square pixels after spatial calibration is removed.

AND intersections measure spatial mask overlap. They do not track individual objects or reconstruct a three-dimensional surface.

### `ImagesPaper.ijm`

Processes the active multichannel stack without selecting or reassigning individual marker channels.

It:

1. Subtracts a fixed background intensity.
2. Applies a median filter.
3. Generates a maximum-intensity Z projection.
4. Sets composite display options.
5. Converts the result to RGB.
6. Adds a scale bar.
7. Saves a TIFF to the selected output location.

This macro operates directly on the active image rather than first creating a duplicate.

### `ImagesPaper-3channels.ijm`

Processes three selected input channels.

The current marker assignments are:

- OPN → red.
- CK19 → green.
- DAPI → blue.

It duplicates the active stack, splits channels, generates a maximum-intensity projection for each selected channel, merges the projections, converts the result to RGB, adds a scale bar and saves a TIFF.

No background subtraction, median filtering or LUT application is active in this workflow.

The filename is generic, but marker names and output color assignments remain specific to OPN, CK19 and DAPI in the code.

### `ImagesPaper-4channels.ijm`

Processes four selected input channels:

- Amylase.
- CK19.
- DAPI.
- Ki67.

It duplicates the active stack, splits channels and applies a separately configured fixed-background subtraction to each selected channel.

Each channel is projected using maximum intensity. Configured display limits and `Apply LUT` are applied to Amylase and DAPI.

The projections are merged using the following output slots:

- `c1`: Amylase.
- `c2`: CK19.
- `c3`: DAPI.
- `c4`: Ki67.

The merged image is converted to RGB, a scale bar is added and a TIFF is saved.

No median filtering is active in this workflow.

The filename is generic, but marker names remain specific to Amylase, CK19, DAPI and Ki67 in the code.

### `ImagesPaperLD.ijm`

Processes LIVE and DEAD channels separately.

For each channel, it:

1. Subtracts a configured fixed background intensity.
2. Applies a median filter.
3. Generates a maximum-intensity Z projection.
4. Sets display limits and applies the LUT.

The projected channels are merged with DEAD in red and LIVE in green. The result is converted to RGB, given a scale bar and saved as a TIFF.

This is a figure-preparation macro. It does not calculate viability.

### `DepthCoding.ijm`

Uses the active image stack.

It:

1. Creates and measures a configured background ROI.
2. Subtracts a manually configured background intensity.
3. Applies a median filter.
4. Sets composite display options.
5. Creates a maximum-intensity Z projection.
6. Selects the source stack and splits its channels.
7. Applies Temporal-Color Code to a selected channel and slice range using the Fire LUT.
8. Adjusts the display limits of the expected `MAX_colored` window.
9. Adds a scale-bar overlay to the maximum-intensity projection.

The measured background ROI does **not** automatically supply its mean to the subtraction command. The subtraction value must be configured manually.

The ROI remains selected during processing, as in the original workflow. Check whether subsequent operations are restricted to that selection.

Depth coloring represents the configured Z-slice range. It is not a time-course analysis or a three-dimensional reconstruction.

Images remain open for inspection and manual saving. No automatic export is implemented.

### `MaxProj-SurfaceAnalysis-Channels_ADM.ijm`

Recursively processes files matching the configured suffix.

For each file, it duplicates the image, splits channels and processes Amylase, CK19, DAPI and Ki67 separately.

Each selected channel undergoes:

1. Median filtering.
2. Maximum-intensity Z projection.
3. Automatic thresholding.
4. Binary-mask conversion.
5. Particle analysis.

The original threshold-method examples are:

- Amylase: `Moments dark no-reset`.
- CK19: `Moments dark no-reset`.
- DAPI: `Default dark no-reset`.
- Ki67: `Moments dark no-reset`.

No background subtraction or hole filling is active.

Measurement titles use the configured sample/timepoint prefix followed by the marker name. Source filenames are not included in these titles.

### `MaxProj-SurfaceAnalysis-ChannelsLD.ijm`

Recursively processes files matching the configured suffix.

ROI, condition and timepoint information are extracted from configurable underscore-separated filename fields.

LIVE and DEAD undergo separate fixed-background subtraction, median filtering and maximum-intensity Z projection.

The original threshold-method examples are:

- LIVE: `Huang dark no-reset`.
- DEAD: `Intermodes dark no-reset`.

Hole filling is applied to the LIVE mask only.

Particle analysis is performed on each mask. Measurement titles include the configured prefix, timepoint, condition, ROI and LIVE/DEAD label.

This macro measures segmented projected areas. It does not directly calculate a viability percentage.

## Running the ImageJ macros

For single-image workflows, open the image stack and make it the active image before running the macro:

- `ImagesPaper.ijm`
- `ImagesPaper-3channels.ijm`
- `ImagesPaper-4channels.ijm`
- `ImagesPaperLD.ijm`
- `DepthCoding.ijm`

The three batch-analysis macros ask for an input folder and visit its subfolders:

- `Timelapse_ImageStab_Maskgen_Combo_Surfac(1).ijm`
- `MaxProj-SurfaceAnalysis-Channels_ADM.ijm`
- `MaxProj-SurfaceAnalysis-ChannelsLD.ijm`

Their output-folder prompt is retained but is currently unused. Results remain in ImageJ measurement tables and must be saved manually.

Macros containing `close("*")` close **all open image windows** after processing. Save unrelated work and use a dedicated ImageJ/Fiji session.

## Interpretation and limitations

### Figure preparation versus quantification

The `ImagesPaper` macros generate presentation images. RGB conversion, background subtraction and LUT application can change the exported pixel values.

Use a consistent, documented figure-preparation configuration when comparing conditions. Do not treat the exported RGB figures as unchanged quantitative source data.

### Area measurements

The two `MaxProj` macros measure segmented areas in two-dimensional maximum-intensity projections, not three-dimensional volumes.

Their measurement units follow the image calibration.

The timelapse macro removes spatial calibration and measures mask areas and intersections in square pixels.

Particle analysis retains the original `clear summarize` options. Measurement settings and applicable particle-analysis settings should be checked in ImageJ before analysis.

### Scale bars

Verify spatial calibration before adding scale bars.

Scale-bar width and height use the image's calibrated units; thickness and font settings are specified separately.

### Channel and window naming

Channel-splitting figure and analysis macros retain an empty duplicate title and expect window names such as `C1-`, `C2-` and `C3-`.

Check that the selected channels exist and avoid pre-existing windows with conflicting names.

`DepthCoding.ijm` expects the depth-coloring output window to be named `MAX_colored`.

### Python image handling

The Python script:

- Reads only the first TIFF page with Pillow.
- Converts unsupported image modes to 8-bit grayscale.
- Center-crops images of different dimensions to the smallest height and width.
- Harmonizes pixel types to uint8 or uint16.
- Does not propagate spatial calibration.

Center-cropping is not image registration. Signed or floating-point images may lose information during conversion.

The output is a TIFF page stack without an explicit channel/time axis assignment. Before using it with the timelapse macro, inspect and arrange its dimensions in ImageJ so that the three acquisition timepoints are accessible as the expected channels.

### Python folder selection

The original selection order is:

1. GUI folder picker, when Tkinter is available.
2. A valid folder supplied as a command-line argument.
3. The current working directory.

Cancelling the GUI activates the fallback rather than aborting. Errors when creating a GUI in a headless environment are not caught.

## Relationship between scripts

There are no exact duplicates.

The Python script assembles timepoint images into stacks. The timelapse macro stabilizes images and measures mask overlap. They have complementary roles, but their image-axis compatibility must be checked before they are used together.

The four `ImagesPaper` macros share figure-preparation steps but differ in active processing, marker assignments and display handling.

The two `MaxProj` macros share a batch-analysis structure but implement different segmentation workflows.

`DepthCoding.ijm` provides a separate depth-visualization workflow.

## Verification status

Earlier revisions underwent:

- Python syntax and configuration-stop checks.
- Synthetic TIFF regression tests, including mixed uint8/uint16 inputs and different image dimensions.
- Checks of incomplete groups, filename exclusion, output-name collisions and configurable timepoint prefixes.
- Static checks of ImageJ macro structure and processing-command sequences.

The final uploaded files were read to verify the filenames and workflows documented here.

These checks do not constitute execution of the final scripts on experimental datasets. Fiji/plugin behavior, image dimensions, calibration, display mapping and segmentation still require validation on representative images.

## Reference

ImageJ macro functions:

https://imagej.net/ij/source/functions.html