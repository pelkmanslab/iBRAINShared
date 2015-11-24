# CreateIllcorJpgsOverview (iBRAIN module)


|||
|---|---|
| Module name: | CreateJpgsOverview |
| Contributors: | Yauhen Yakimovich <yauhen.yakimovich@uzh.ch>, Thomas Stoeger <thomas.stoeger@imls.uzh.ch>, Saadia Iftikhar <saadia.iftikhar@fmi.ch> |
| Entry point: | create_jpgs_illumination_corrected.m |
| Additional major working functions: | none |

## BRAIN_BRUTUS reference

[iBRAIN_BRUTUS/iBRAIN/core/modules/create_illcor_jpgs.sh](https://github.com/pelkmanslab/iBRAIN_BRUTUS/blob/master/iBRAIN/core/modules/create_illcor_jpgs.sh)

## Summary
iBRAIN " CreateIllcorJpgsOverview " module is otherwise similar to CreateJpgsOverview except that the actual stitching is taking place over  images that have been corrected (i.e. after illumination correction step is complete).
 
## Completion FLAGs

./BATCH/CreateIllcorJPGs*.results
./ILLCORJPG/PlateIllcorOverview.jpg

## File Dependencies

Presence of flag ./BATCH/ConvertAllTiff2Png.complete

## Inputs

Image files inside TIFF folder.

## Outputs

Stitched overview illumination corrected images inside ILLCORJPG folder

