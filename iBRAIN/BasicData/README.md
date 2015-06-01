# BasicData (iBRAIN module)

|||
|---|---|
| Module name: | BasicData |
| Contributors: | Victoria Green victoria.green@uzh.ch |
| Entry point: | generate_basic_data.m |
| Additional major working functions: | |

## BRAIN_BRUTUS reference

`/iBRAIN/core/modules/create_plate_overview.sh`

## Summary

iBRAIN "create plate overview" does: 
- creates BASICDATA.mat files in plate BATCH folder; 
- BASICDATA contains mean results per well, as well as log2 and z-scored results for infection scoring and cell number, and gene information if provided; 
- creates .csv file of BASICDATA in POSTANALYSIS directory;
 - creates .pdf file of BASICDATA with visualisations for summarising out of focus images, infection index, cell number and plate effects.

## Completion FLAGs 

`./BATCH/CreatePlateOverview_*.results`

## File Dependencies 

Completion of out of focus measurement and infection scoring, unless not to be done. Presence of necessary measurements i.e. completion of CellProfiler PIPE.
If gene information is to be incorporated:
- Plate layouts must be added to MasterData.mat.
- Plate folders must be named correctly i.e. `*_CP[#1]-[#2][x][y]`, where #1 is a 3-digit MasterData plate number, #2 indicates the round of preparation of the source dilution plates, x is a character to indicate the set of source dilution plates, and y is a character to indicate the set of cell plates e.g. For `*_CP392-1ad`, the plate layout is given by plate **392** in **MasterData.mat**, and this cell plate is part of replicate set 'd' that was prepared from dilution plate `DP392-1A`.

##Inputs

No text files required - automatic generation of outputs by iBRAIN.
For gene information, updated `PelkmansLibrary/matlab/GeneLookup/LookUpGeneData/MasterData.mat`

## Outputs

- BATCH/BASICDATA_*.mat
- POSTANALYSIS/*_plate_overview.csv
- POSTANALYSIS/*_plate_overview.pdf



