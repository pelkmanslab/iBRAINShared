# CheckInputImage (iBRAIN module)

|||
|---|---|
| Module name: | CheckInputImage |
| Contributors: | Yauhen Yakimovich <yauhen.yakimovich@uzh.ch>, Berend Snijder <berend.snijder@imls.uzh.ch>, Mathieu Fréchin <mathieu.frechin@uzh.ch> |
| Entry point(s): | check_image_set.sh, check_image_set_nikon.sh, rename_nikon.sh |


## iBRAIN_BRUTUS reference 

 ./iBRAIN/core/modules/check_image_set.sh

## Summary iBRAIN "CheckInputImage"

####check_image_set.sh
 - checks if there is a need for renaming nikon produced images; 
 - waits for Nikon image renaming. 
	- checks modification time of all image files are 30 min or older;  
	- moves microscope specific metadata files out of the TIFF directory and into a METADATA directory;  
	- reports progress as a data timeout;  


## File dependencies

Presence of TIFF folder in project folder
Renaming of NIKON images if NIKON directory present in project folder, this NIKON folder must contain *.stk and *.nd files.

## Working functions


####Progession FLAGs

####Completion FLAGs

#####check_image_set.sh 

./BATCH/checkimageset.complete

./TIFF/CheckImageSet_*.complete


## Inputs

## Outputs

##TODO

