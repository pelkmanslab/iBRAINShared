# SegmentationPerWell (iBRAIN module)

|||
|---|---|
|Module name:| SegmentationPerWell |
| Contributors: | Gabriele Gut Gabriele.Gut@uzh.ch, Berend Snijder <berend.snijder@imls.uzh.ch> |
| Entry point: | stitchSegmentationPerWell.m | 
| Additional major working functions:| none |

## BRAIN_BRUTUS reference

`iBRAIN_BRUTUS/iBRAIN/core/modules/stitch_segmentation_per_well.sh`

## Summary
iBRAIN " SegmentationPerWell " does: 

- Stitches segmentation images back to whole wells. 
- Generates unique identifiers for each object, stored as measurement. 
- This allows to color code the objects by any measurement value creates measurements. 
- stitchSegmentationPerWell.m stores the stitched segmentations in a newly generated folder called SEGMENTATION_WELL in the .png format. 

## Completion FLAGs

ProjectFolder /BATCH/ StitchSegmentationPerWell_ *.results
/ProjectFolder/ StitchSegmentationPerWell.submitted

## File Dependencies

- create_population_context_measurements.sh only starts if “StitchSegmentationPerWell_*.results” is not present in the BATCH folder, else no dependencies at the bash code level 
- At the MatLab level stitchSegmentationPerWell.m expects a SEGMENTATION folder in the ProjectFolder. That the site segmentations contain the string “_Segmented(.*)\.png”. That the BATCH folder contains following Measurements files: Measurements_Image_ObjectCount.mat and Measurements_Image_FileNames.mat.

## Inputs

Path to the BATCH folder of the analyzed project.

## Outputs
- Generates a SEGMENTATION_WELL folder
- Stitched  well segmentations in .png folder in the SEGMENTATION_WELL folder
