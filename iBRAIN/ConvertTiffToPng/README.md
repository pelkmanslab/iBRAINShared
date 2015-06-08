# ConvertTiffToPng (iBRAIN module)

|||
|---|---|
| Module name: | ConvertTiffToPng |
| Contributors: | Yauhen Yakimovich <yauhen.yakimovich@uzh.ch>, Berend Snijder <berend.snijder@imls.uzh.ch>, Mathieu Fréchin <mathieu.frechin@uzh.ch> |
| Entry point(s): | convert_tiff_to_png.sh |
| Additional major working functions: | batchpngconversion.sh |


## iBRAIN_BRUTUS reference 

 ./iBRAIN/core/modules/convert_tiff_to_png.sh

## Summary 
iBRAIN "convert tiff to png" does:
- groups all images into several batch files;
- for each batch file, called batch_png_convert_*;
- calls bin/batchpngconversion.sh multiple times;
- reports progress with bar.
- replaces transforms tifs into pngs


## Working functions
- batchpngconversion.sh 
- batchpngconversion.sh invokes imagemagick shell-command called 'convert'

## Dependencies

Requires a /TIFF folder and the presence of the ./TIFF/CheckImageSet_*.complete flag

####Completion FLAGs

/BATCH/ConvertAllTiff2Png.complete

## Inputs

/BATCH folder, /TIFF folder that contains *.tif files
/BATCH/ConvertAllTiff2Png.complete flag

## Outputs

creates a ./BATCH/ConvertAllTiff2Png_*.results
transforms the *.tif into *.png files

## TODO

pngconversion.sh, pngconversion2.sh and pngconversion_old.sh can be removed to my own view

