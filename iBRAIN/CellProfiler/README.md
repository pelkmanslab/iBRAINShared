# CellProfiler (iBRAIN module)

|||
|---|---|
| Module name: | CellProfiler |
| Contributors: | Yauhen Yakimovich <yauhen.yakimovich@uzh.ch>, Berend Snijder <berend.snijder@imls.uzh.ch>, Mathieu Fréchin <mathieu.frechin@uzh.ch> |
| Entry point(s): | PreCluster.m, CPCluster.m, RundDataFusion.m |
| Additional major working functions: | stage_one.sh, submitbatchjobs.sh |


## iBRAIN_BRUTUS reference 

 ./iBRAIN/core/modules/stage_one.sh

## Summary iBRAIN "stage one" and file dependencies:
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

####Progession FLAGs

project/PreCluster.submitted, or project/PreCluster.resubmitted, to flag that PreCluster.m has been started

project/SubmitBatchJobs.submitted, or project/SubmitBatchJobs.resubmitted to flag that CPCluster.m has been started

project/DataFusion.submitted, or project/DataFusion.resubmitted to flag that RunDataFusion.m has been started

project/DataFusionCheckAndCleanup.submitted, or project/DataFusionCheckAndCleanup.resubmitted to flag that RunDataFusion.m is checking the correctness of the fusion.

If a step fails, the typical behaviour is to try once more, and output a .resubmitted flag, there is no more than a second trial.



####Completion FLAGs

project/iBRAIN_Stage_1.completed

## Inputs

####PreCluster.m

-three inputs:

1.The cellprofiler pipeline saved by the user as /project/PreCluster_*.mat

2.The input path to the image folder (/TIFF in iBRAIN_BRUTUS)

3.The output path (/BATCH)

####CPCluster.m

-two inputs:

1.The fist one is the batch data saved as /BATCH/Batch_data.mat

2.The second one is the actual cluster job /BATCH/BATCH_*.mat

####RunDataFusion.m

-two inputs:

1.The first one is the path to the output file folder (/BATCH usually)

2.The second one is optional, it is the name of the measurement you want to fuse the actual CPCluster *_OUT.mat files together, not used in general. If not given, RunDataFusion.m extract the name of the measurements from the output folder and fuses the *_OUT.mat files accordingly.

## Outputs

####PreCluster.m

The CP pipeline is evaluated on the first image set, it is a test. If everything goes fine, CPCluster starts, if an error occurs, it is reported by PreCluster, and iBRAIN_BRUTUS stops. 

####CPCluster.m

Save in the output folder (/BATCH usually) a *_OUT.mat that will need to be fused with the other jobs outputs.

####RundDataFusion.m

Save in the output folder (/BATCH usually) a Measurement*.mat file that regroups all the *_OUT.mat files produced by CPCluster.mat

##TODO

When are used `checkmeasurementsfile.m` and `checkmeasurementsfile2.m` ?
