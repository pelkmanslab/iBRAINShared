# CreateOutOfFocusMeasurement (iBRAIN module)

|||
|---|---|
|Module name:|CreateOutOfFocusMeasurement|
| Contributors: | Gabriele Gut Gabriele.Gut@uzh.ch, Berend Snijder <berend.snijder@imls.uzh.ch> |
| Entry point: | check_outoffocus.m
| Additional major working functions: | checkoutoffocus.sh |

## BRAIN_BRUTUS reference
iBRAIN_BRUTUS/iBRAIN/core/modules/create_out_of_focus_measurement.sh

## Summary
iBRAIN " CreateOutOfFocusMeasurement " does: 
- Identifies images in data sets which are out of focus, this identification is based on the granularity measurement of an image. The identification is done one channel (e.g. blue), and can be used to exclude whole sites from your data set.  Importantly both channel name and the granularity threshold values are hard coded in to check_outoffocus.m. I strongly advice to rewrite this function more generally and user independent (e.g. cluster images based on the granularity and set generate an out of focus measurement independently from user input) before implementing it on the new IBrain version.

## Completion FLAGs

ProjectFolder /BATCH/ CheckOutOfFocus_*.results
/ProjectFolder/CheckOutOfFocus.submitted

## File Dependencies
- create_out_of_focus_measurement.sh expects Measurements_*BlueSpectrum.mat to be present in the BATCH folder. Additionally create_out_of_focus_measurement.sh will only trigger checkoutoffocus.sh if “CheckOutOfFocus_*.results”  and “*Measurements_*OutOfFocus.mat” are not present in the BATCH folder, else no dependencies at the bash code level 
- At the MatLab level check_outoffocus.m expects a Measurements file called either “Measurements_Image_RescaledBlueSpectrum.mat” or “Measurements_Image_OrigBlueSpectrum.mat” in the BATCH folder.  Additionaly the BATCH folder has to contain the following Measurements files: Measurements_Image_ObjectCount.mat and Measurements_Image_FileNames.mat. 
- “Nuclei”, “Cells” or “OrigNuclei” have to be used as object names for measuring  “Measurements_Image_RescaledBlueSpectrum.mat” or “Measurements_Image_OrigBlueSpectrum.mat”.

## Inputs
Path to the BATCH folder of the analyzed project.

## Outputs
- Measurements_Image_OutOfFocus.mat
