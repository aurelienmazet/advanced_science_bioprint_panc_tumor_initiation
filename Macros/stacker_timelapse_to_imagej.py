#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Build ImageJ TIFF stacks from independent timepoint images in each folder.

IMPORTANT: Fill in USER PARAMETERS before running. Review filename tokens,
stack order and image handling. Requirements: Python 3.10+, numpy, Pillow,
tifffile; tkinter is optional. Install dependencies with:
    python -m pip install numpy pillow tifffile

Images are grouped within each folder after replacing the timepoint token.
Duplicate timepoints keep the first sorted filename; incomplete groups are skipped.
Outputs are saved beside their sources; existing outputs get a numeric suffix.

Processing behavior retained:
- Only the first TIFF page is loaded with Pillow.
- RGB/RGBA and unsupported modes become 8-bit grayscale.
- Different dimensions are center-cropped to the smallest height and width.
- Dtype harmonization targets uint8/uint16.
- Spatial calibration is not propagated.

Center-cropping is not registration. Dtype harmonization is not safe for
arbitrary signed or floating-point quantitative data.

The output is a stack of pages, with no explicit channel/time axis assignment.
Verify its dimensions in ImageJ before using macros expecting separate channels.

Author: Aurélien Mazet
"""

from __future__ import annotations

import os
import re
import sys
from typing import Dict, List, Tuple

import numpy as np
from PIL import Image
import tifffile as tiff

try:
    import tkinter as tk
    from tkinter import filedialog, messagebox
except Exception:
    tk = None


# --------------------------- USER PARAMETERS -------------------------------- #

# EDIT: Ordered numeric acquisition timepoints.
# Original example: (1, 7, 14).
EXPECTED_TIMEPOINTS: tuple[int, ...] | None = None

# EDIT: Filename token prefix.
# Original example: "D"; use "J" for J1/J7/J14.
TIMEPOINT_PREFIX = ""

# EDIT: Case-insensitive filename substring to exclude.
# Original example: "mask".
# Set to "" explicitly to disable exclusion.
EXCLUDED_NAME_SUBSTRING: str | None = None

# EDIT: Output suffix.
# Original example: "_stack.tif".
OUTPUT_SUFFIX = ""

# Review: accepted input extensions.
# These are format settings, not experiment values.
VALID_EXTS = {".tif", ".tiff"}


# ------------------------- CONFIGURATION CHECK ------------------------------- #

if (
    not EXPECTED_TIMEPOINTS
    or not TIMEPOINT_PREFIX
    or EXCLUDED_NAME_SUBSTRING is None
    or not OUTPUT_SUFFIX
):
    raise ValueError("Fill in USER PARAMETERS before running this script.")

if any(
    not isinstance(tp, int) or isinstance(tp, bool) or tp < 0
    for tp in EXPECTED_TIMEPOINTS
):
    raise ValueError("Timepoints must be non-negative integers.")

if len(set(EXPECTED_TIMEPOINTS)) != len(EXPECTED_TIMEPOINTS):
    raise ValueError("Timepoints must be distinct.")

# Preserve the original optional-separator and trailing-boundary matching behavior.
# There is no left boundary check: inspect actual filenames before batch processing.
_timepoint_options = "|".join(
    str(tp) for tp in sorted(EXPECTED_TIMEPOINTS, reverse=True)
)

TIMEPOINT_TOKEN_RE = re.compile(
    rf"([_\-]?{re.escape(TIMEPOINT_PREFIX)})"
    rf"({_timepoint_options})(?=\b|[_\-]|$)",
    re.IGNORECASE,
)


# ----------------------------- HELPERS --------------------------------------- #

def is_tiff(path: str) -> bool:
    """Check whether a filename has an accepted TIFF extension."""
    return os.path.splitext(path)[1].lower() in VALID_EXTS


def contains_mask(name: str) -> bool:
    """Check the configured exclusion substring; an empty string disables it."""
    return (
        bool(EXCLUDED_NAME_SUBSTRING)
        and EXCLUDED_NAME_SUBSTRING.lower() in name.lower()
    )


def extract_timepoint(name_noext: str) -> int | None:
    """Return a configured timepoint found in the filename, or None."""
    match = TIMEPOINT_TOKEN_RE.search(name_noext)
    if not match:
        return None
    return int(match.group(2))


def group_key(name_noext: str) -> str:
    """Replace the timepoint token with a placeholder for grouping.

    Examples with TIMEPOINT_PREFIX = "D":
        ROI-03_green_D1 -> ROI-03_green_D*
        ROI-03_green-D14 -> ROI-03_green-D*

    The remaining filename must match for images to belong to the same group.
    """
    return TIMEPOINT_TOKEN_RE.sub(r"\1*", name_noext)


def stem_without_time(name_noext: str) -> str:
    """Remove the timepoint token and clean separators for the output filename."""
    stem = TIMEPOINT_TOKEN_RE.sub("", name_noext)

    # Collapse repeated separators such as "__", "--" or "-_".
    stem = re.sub(r"([_\-]){2,}", r"\1", stem)

    # Remove separators and spaces left at the ends.
    return stem.strip("-_ ")


def read_image_as_array(path: str) -> np.ndarray:
    """Read the first TIFF page using the original Pillow handling.

    Standard grayscale modes retain their pixel array.
    Other modes, including RGB/RGBA, are converted to 8-bit grayscale.
    """
    with Image.open(path) as image:
        if image.mode in ("L", "I;16", "I;16B", "I;16L"):
            array = np.array(image)

            if array.dtype == np.uint16 or array.dtype == np.int32:
                return array

            if array.dtype == np.uint8:
                return array

            # Retain the original Pillow array for an unusual dtype.
            # No tifffile fallback read is performed.
        else:
            image = image.convert("L")

        return np.array(image)


def ensure_compatible_stack(
    images: List[np.ndarray],
) -> List[np.ndarray]:
    """Center-crop to the smallest dimensions and cast to uint8 or uint16.

    Intended for unsigned 8/16-bit images; arbitrary types may lose information.
    """
    if not images:
        return images

    # Prefer uint16 if any input array occupies more than 8 bits per pixel.
    max_dtype_bits = max(array.dtype.itemsize * 8 for array in images)
    target_dtype = np.uint16 if max_dtype_bits > 8 else np.uint8

    # Use the smallest height and width found in the group.
    min_h = min(array.shape[0] for array in images)
    min_w = min(array.shape[1] for array in images)

    fixed = []

    for array in images:
        adjusted = array

        # Preserve the original dtype-conversion behavior.
        if target_dtype == np.uint16 and adjusted.dtype != np.uint16:
            adjusted = adjusted.astype(np.uint16)

        elif target_dtype == np.uint8 and adjusted.dtype != np.uint8:
            if adjusted.max() > 255:
                adjusted = np.clip(adjusted, 0, 255).astype(np.uint8)
            else:
                adjusted = adjusted.astype(np.uint8)

        # Center-crop only when dimensions differ.
        if adjusted.shape[0] != min_h or adjusted.shape[1] != min_w:
            y0 = (adjusted.shape[0] - min_h) // 2
            x0 = (adjusted.shape[1] - min_w) // 2
            adjusted = adjusted[y0:y0 + min_h, x0:x0 + min_w]

        fixed.append(adjusted)

    return fixed


# ------------------------------ PROCESSING ----------------------------------- #

def process_folder(root_dir: str) -> None:
    """Visit subfolders, assemble complete groups and report skipped files."""
    created = 0
    skipped_incomplete: List[Tuple[str, List[str]]] = []
    skipped_other: List[Tuple[str, str]] = []

    for dirpath, dirnames, filenames in os.walk(root_dir):
        # Filter TIFFs using the configured exclusion substring.
        tiff_files = [
            filename
            for filename in filenames
            if is_tiff(filename) and not contains_mask(filename)
        ]

        if not tiff_files:
            continue

        # Group images within this folder by filename and timepoint.
        groups: Dict[str, Dict[int, str]] = {}

        for filename in sorted(tiff_files):
            name_noext, ext = os.path.splitext(filename)
            timepoint = extract_timepoint(name_noext)

            if timepoint not in EXPECTED_TIMEPOINTS:
                skipped_other.append(
                    (
                        os.path.join(dirpath, filename),
                        f"No valid {TIMEPOINT_PREFIX} timepoint token",
                    )
                )
                continue

            key = group_key(name_noext)
            groups.setdefault(key, {})

            # Keep the first sorted filename if a timepoint occurs twice.
            if timepoint in groups[key]:
                skipped_other.append(
                    (
                        os.path.join(dirpath, filename),
                        f"Duplicate timepoint {TIMEPOINT_PREFIX}{timepoint} "
                        f"for group '{key}'",
                    )
                )
                continue

            groups[key][timepoint] = os.path.join(dirpath, filename)

        # Build one stack for each complete group.
        for key, mapping in groups.items():
            missing = [
                timepoint
                for timepoint in EXPECTED_TIMEPOINTS
                if timepoint not in mapping
            ]

            if missing:
                skipped_incomplete.append(
                    (
                        dirpath,
                        [
                            f"{key} (missing {TIMEPOINT_PREFIX}{timepoint})"
                            for timepoint in missing
                        ],
                    )
                )
                continue

            # Use the first configured timepoint for output naming.
            reference_path = mapping[EXPECTED_TIMEPOINTS[0]]
            reference_name = os.path.splitext(
                os.path.basename(reference_path)
            )[0]
            reference_stem = stem_without_time(reference_name)

            out_name = f"{reference_stem}{OUTPUT_SUFFIX}"
            out_path = os.path.join(dirpath, out_name)

            # Avoid overwriting an existing output by adding a numeric suffix.
            suffix = 1

            while os.path.exists(out_path):
                output_stem, output_ext = os.path.splitext(OUTPUT_SUFFIX)
                out_name = (
                    f"{reference_stem}{output_stem}({suffix}){output_ext}"
                )
                out_path = os.path.join(dirpath, out_name)
                suffix += 1

            # Read and stack in the configured order.
            try:
                arrays = [
                    read_image_as_array(mapping[timepoint])
                    for timepoint in EXPECTED_TIMEPOINTS
                ]
                arrays = ensure_compatible_stack(arrays)
                stack = np.stack(arrays, axis=0)

                # Write an ImageJ-compatible TIFF page stack.
                tiff.imwrite(out_path, stack, imagej=True)

                sources = ", ".join(
                    os.path.basename(mapping[timepoint])
                    for timepoint in EXPECTED_TIMEPOINTS
                )
                print(f"[OK] Saved stack: {out_path}  (from {sources})")
                created += 1

            except Exception as error:
                skipped_other.append(
                    (out_path, f"Failed to write stack: {error}")
                )

    # Print the processing summary.
    print("\n===== SUMMARY =====")
    print(f"Stacks created: {created}")

    if skipped_incomplete:
        print("\nIncomplete groups (missing configured timepoints):")
        for folder, items in skipped_incomplete:
            for item in items:
                print(f"  - {folder}: {item}")

    if skipped_other:
        print("\nOther skipped files/reasons:")
        for path, reason in skipped_other:
            print(f"  - {path}: {reason}")


def pick_root_folder() -> str:
    """Select the root folder using the original GUI/CLI fallback order."""
    # Original order: GUI, then valid CLI directory, then working directory.
    # Cancelling the GUI does not abort; it activates the fallback.
    # A headless tkinter failure is not caught by the original folder picker.
    if tk is not None:
        root = tk.Tk()
        root.withdraw()
        root.update()

        folder = filedialog.askdirectory(
            title="Select the root folder to process"
        )
        root.destroy()

        if folder:
            return folder

    if len(sys.argv) > 1 and os.path.isdir(sys.argv[1]):
        return sys.argv[1]

    return os.getcwd()


if __name__ == "__main__":
    root_dir = pick_root_folder()

    if not root_dir:
        print("No folder selected.")
        sys.exit(1)

    print(f"Root folder: {root_dir}")
    process_folder(root_dir)
    print("Done.")