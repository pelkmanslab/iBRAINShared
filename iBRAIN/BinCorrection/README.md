# BinCorrection (iBRAIN module)

|||
|---|---|
| Module name: | BinCorrection |
| Contributors: | Prisca Liberali <prisca.liberali@uzh.ch>, Berend Snijder <berend.snijder@imls.uzh.ch> |
| Entry point: | runBinCorrection.m |
| Additional major working functions: |  |

## BRAIN_BRUTUS reference

`/iBRAIN/core/modules/do_bin_correction.sh`



## Summary

iBRAIN "do bin correction" does:
- performs quantile binning of data specified in BIN_.txt settings file in project directory; The feature in the text file is the measurement you want to correct for and the other are the measurement you want to use to create the quantile bins.
- creates Measurements_BIN_corrected_.mat files in BATCH folder of each plate in project directory; The output will have for every single cell the raw measurement, the expected measurement and the corrected measurement. 
- creates .pdf files with correction overview in POSTANALYSIS folder of each plate in project directory.

See the entry-point function for main documentation and the algorithm explanation.
Input
BIN_*.txt 
e.g. text file as getRawProbModelData2


Output
BATCH/ Measurements_BIN_*.mat


## Wrapper

- runBinCorrection.m

## Working function

- doBinCorrection.m

## Dependencies

- LoadStandardData.m
- getRawProbModelData2.m
- createMeasurement.m

Requires `BIN_*.txt` settings file in project directory.

## Completion FLAGs

`./BATCH/BINClassification_*.results`

## Code and function calls
Calls matlab function

`runBinCorrection('${BATCHDIR}','${BINSETTINGSFILE}','$(basename $BINOUTPUTFILE)');`
