# CheckInputImage (iBRAIN module)

|||
|---|---|
| Module name: | CheckInputImage |
| Contributors: | Yauhen Yakimovich <yauhen.yakimovich@uzh.ch>, Berend Snijder <berend.snijder@imls.uzh.ch>, Mathieu Fréchin <mathieu.frechin@uzh.ch> |
| Entry point(s): | check_image_set.sh, check_image_set_nikon.sh, rename_nikon.sh, microscopetool.nikon.renameImages.mat |


## iBRAIN_BRUTUS reference 

 ./iBRAIN/core/modules/check_image_set.sh

## Summary iBRAIN "CheckInputImage"

#####check_image_set.sh
 - checks if there is a need for renaming nikon produced images, if yes stops and check_image_set_nikon.sh and rename_nikon.sh will do the job.
 - checks modification time of all image files are 30 min or older;  
 - moves microscope specific metadata files out of the TIFF directory and into a METADATA directory;  
 - reports progress as a data timeout;
 - creates BATCH and POSTANALYSIS folders if do not exist yet.

#####check_image_set_nikon.sh
 - checks if there is nikon produced images, if no, check_image_set.sh does the job; 
 - otherwise checks modification time of all image files are 30 min or older;
 - reports progress as a data timeout;
 - (then to go through the module, check_image_set.sh finishes the check, that can complete only once rename_nikon.sh has done his job)

#####rename_nikon.sh
 - checks if there is nikon produced images;
 - convert the *.stk files into *.tiff files using the microscopetool.nikon.renameImages() function and place them into /TIFF folder where they will be checked by check_image_set.sh


## File dependencies

##### all functions
Presence of TIFF folder in project folder
Renaming of NIKON images if NIKON directory present in project folder, this NIKON folder must contain *.stk and *.nd files.

##### rename_nikon.sh
presence of the ./NIKON/CheckNikonImageSet.complete

## Working functions
microscopetool.nikon.renameImages.mat

####Completion FLAGs

#####check_image_set.sh 

./BATCH/checkimageset.complete

./TIFF/CheckImageSet_*.complete

#####check_image_set_nikon.sh

./NIKON/CheckNikonImageSet.complete

## Inputs
#####check_image_set.sh

TIFF folder in project folder

#####check_image_set_nikon.sh

NIKON folder in project folder

#####rename_nikon.sh


## Outputs


