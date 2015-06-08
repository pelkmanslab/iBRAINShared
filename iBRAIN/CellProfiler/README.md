# CellProfiler (iBRAIN module)

|||
|---|---|
| Module name: | CellProfiler |
| Contributors: | Yauhen Yakimovich <yauhen.yakimovich@uzh.ch>, Berend Snijder <berend.snijder@imls.uzh.ch>, Mathieu Fréchin <mathieu.frechin@uzh.ch> |
| Entry point(s): | PreCluster.m, CPCluster.m, RundDataFusion.m |
| Additional major working functions: | stage_one.sh, submitbatchjobs.sh |


## iBRAIN_BRUTUS reference 

 ./iBRAIN/core/modules/stage_one.sh

## Summary iBRAIN "stage one" does:
- runs CellProfilerPelkmans pipelines on batched images on cluster, as defined by PreCluster_.mat settings file in project folder;
- performs BATCH clean-up;
- performs data fusion of CellProfiler measurements and clean-up;
- outputs fused measurement files to BATCH directory in project folder;
- outputs segmentations of objects (if saved in pipeline) to SEGMENTATION directory in project folder;
- can incorporate personalised code for CellProfiler pipeline if present in LIB directory in project folder;
- PreCluster_.mat settings file in plate folders override those in project folders;
- report progress with progress bar (but NOT ACCURATE!).

## Working functions

- `check_missing_images_in_folder()` - is independently called prior to PreCluster step.
- `submitbatchjobs.sh` - tricky one, lies in stage_one.sh and helps stage_one.sh to coordinates CPCluster behaviour.
- `SeparateMeasurementsFromHandles()`- is called in CPCluster during saving of the output

Completion FLAGs
./iBRAIN_Stage_1.completed

## Inputs

####PreCluster.m

-three inputs: 
-the cellprofiler pipeline saved by the user as /project/PreCluster_*.mat
-the input path to the image folder (/TIFF in iBRAIN_BRUTUS)
-the output path (/BATCH)

####CPCluster.m

-two inputs:
-the fist one is the batch data saved as /BATCH/Batch_data.mat
-the second one is the actual cluster job /BATCH/BATCH_*.mat

####RunDataFusion.m
-two inputs:
-the first one is the path to the output file folder (/BATCH usually)
-the second one is optional, it is the name of the measurement you want to fuse the actual CPCluster *_OUT.mat files together, not used in general. If not given, RunDataFusion.m extract the name of the measurements from the output folder and fuses the *_OUT.mat files accordingly.

## Outputs

####PreCluster.m

The CP pipeline is evaluated on the first image set, it is a test. If everything goes fine, CPCluster starts, if an error occurs, it is reported by PreCluster, and iBRAIN_BRUTUS stops. 

####CPCluster.m

Save in the output folder (/BATCH usually) a *_OUT.mat that will need to be fused with the other jobs outputs.

####RundDataFusion.m

Save in the output folder (/BATCH usually) a Measurement*.mat file that regroups all the *_OUT.mat files produced by CPCluster.mat
