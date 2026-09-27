# Design assets

`Blender/daybreak-chamfered-block.blend` is the editable source for the chamfered block numerals. It contains a clock composition and the full digit set with a colon.

This folder appears in Xcode's project navigator but is not a member of the app target. Export runtime models (such as USDZ for RealityKit) into the app's resources when integrating the numerals.

Blender files are tracked with Git LFS through the repository's `.gitattributes`. Install Git LFS and run `git lfs install` when setting up a new checkout. Add, commit, and push Blender files with the usual Git commands; include `.gitattributes` in the initial asset commit.
