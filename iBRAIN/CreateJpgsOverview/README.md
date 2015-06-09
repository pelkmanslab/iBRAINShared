# CreateJpgsOverview (iBRAIN module)


|||
|---|---|
| Module name: | CreateJpgsOverview |
| Contributors: | Yauhen Yakimovich <yauhen.yakimovich@uzh.ch>, Berend Snijder <berend.snijder@imls.uzh.ch> |
| Entry point: | create_jpgs.m |
| Additional major working functions: | none |

## BRAIN_BRUTUS reference

[iBRAIN_BRUTUS/iBRAIN/core/modules/create_jpgs.sh](https://github.com/pelkmanslab/iBRAIN_BRUTUS/blob/master/iBRAIN/core/modules/create_jpgs.sh)

## Summary
iBRAIN " CreateJpgsOverview " creates a stitched (joined) overview over each well in the plate and the whole plate as JPG files:, In particular, module:  
 - creates reduced sized multichannel .jpg image files per well in JPG directory in project folder;
- for up to 3 channel acquisition, creates one RGB image using channels 3,2,1;
- for 4 channel acquisition, creates two RGB images per well: as above and in addition using channels 4,2,1;
- creates plate overview .jpg image;
- runs parallel to illumination correction statistic calculations;
- reports progress with bar.
 
## Completion FLAGs

./BATCH/CreateJPGs*.results
./JPG/PlateOverview.jpg

## File Dependencies

Presence of flag ./BATCH/ConvertAllTiff2Png.complete

## Inputs

Image files inside TIFF folder.

## Outputs

Stitched overview images inside JPG folder

# TODO

- Replace `create_jpgs()` with the newer code from `create_well_microscope_image()`.
