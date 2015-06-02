#PlateNormalization (iBRAIN module)

|||
|---|---|
| Module name: | PlateNormalization |
| Contributors: | Gabriele Gut Gabriele.Gut@uzh.ch, Berend Snijder <berend.snijder@imls.uzh.ch> |
| Entry point: | Measurements_mean_std_iBRAIN.m |
| Additional major working functions: | platenormalization.sh |

## BRAIN_BRUTUS reference

iBRAIN_BRUTUS/iBRAIN/core/modules/create_plate_normalization.sh

## Summary

iBRAIN "PlateNormalization" does: 

- creates “Measurements_Mean_Std.mat” files in plate BATCH folder; 
- Measurements_Mean_Std.mat file contains mean, median, std and mad of every feature measured (e.g. mean of the total green channel intensity in cells, mad of the texture feature 15 of the far red channel intensity in nuclei); 
- “Measurements_Mean_Std.mat” has the same data structure as any other PelkmansLab “Measurements_*.mat” file, however does not contain single-cell data in rows but only one value per measurements, which represents the mean, median, std or mad of all cells in this project.

## Completion FLAGs

`/ProjectFolder/BATCH/MeasurementsMeanStd_ results`
`/ProjectFolder/MeasurementsMeanStd.submitted`

## File Dependencies

- create_plate_normalization.sh calls platenormalization.sh, which then calls Measurements_mean_std_iBRAIN.m. 
- create_plate_normalization.sh has no clear dependencies, since bash code does not check for the present of any specific Measurement file. 
- However it does check whether MeasurementsMeanStd_ results is present in BATCH folder (Completion Flag) or whether jobs running Measurements_mean_std_iBRAIN.m are present on Brutus, and subsequently does not trigger platenormalization.sh. 
- Additionally there is a comment line in the bash code stating “IF ALL EXPECTED MEASUREMENTS ARE PRESENT SUBMIT MEASUREMENTS_MEAN_STD”. I interpret this comment, that platenormalization.sh will be called whenever there is a set of Measurement files present in the BATCH folder.
- If this assumption of mine is true, we have to conclude, that whenever we run a new Measurement pipeline, one has to retrigger PlateNormalization (delete the Completion FLAG).
 
## Inputs

No user input required, function should be triggered when Measurement files are present in the BATCH folder.

## Outputs
Measurements_Mean_Std.mat


