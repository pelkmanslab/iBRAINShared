# CreatePopulationContext (iBRAIN module)


|||
|---|---|
| Module name: | CreatePopulationContext |
| Contributors: | Gabriele Gut Gabriele.Gut@uzh.ch, Berend Snijder <berend.snijder@imls.uzh.ch> |
Entry point: 
getLocalCellDensityPerWell_auto.m, Detect_BorderCells.m
Additional major working functions:
none

## BRAIN_BRUTUS reference

`iBRAIN_BRUTUS/iBRAIN/core/modules/create_population_context_measurements.sh`

## Summary
iBRAIN " CreatePopulationContext " does: 
 - creates measurements of the population context of cells. 
 - two functions are at the core of this module (getLocalCellDensityPerWell_auto.m, Detect_BorderCells.m). 
 - getLocalCellDensityPerWell_auto.m measures whether cells have non neighbors (Measurements_Nuclei_SingleCell.mat), the density in which they grow (Measurements_Nuclei_LocalCellDensity.mat), their distance to the edge of a population (Measurements_Nuclei_DistanceToEdge.mat) and  whether a cell is actually at the border of a population (Measurements_Nuclei_Edge.mat). 
 - Detect_BorderCells.m measures whether a cell touches the border of an image (Measurements_Cells_BorderCells.mat). 

## Completion FLAGs

ProjectFolder /BATCH/ getLocalCellDensityPerWell_auto_*.results
/ProjectFolder/ GetLocalCellDensityPerWell_Auto.submitted

## File Dependencies
- `create_population_context_measurements.sh` only starts if “getLocalCellDensityPerWell_auto_*.results” is not present in the BATCH folder, else no dependencies at the bash code level 
- `Detect_BorderCells.m` expects Measurements_Image_ObjectCount.mat and Measurements_Image_FileNames.mat in the BATCH folder, a folder called “SEGMENTATION” in the ProjectFolder, objects from a segmentation pipeline called “Cells”.

## Inputs

Path to the BATCH folder of the analyzed project.

## Outputs

- Measurements_Cells_BorderCells.mat
- Measurements_Nuclei_SingleCell.mat
- Measurements_Nuclei_DistanceToEdge.mat
- Measurements_Nuclei_Edge.mat 
- Measurements_Nuclei_LocalCellDensity.mat
