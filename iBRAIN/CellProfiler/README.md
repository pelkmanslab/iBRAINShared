# CellProfiler (iBRAIN module)

|||
|---|---|
| Module name: | CellProfiler |
| Contributors: | Yauhen Yakimovich <yauhen.yakimovich@uzh.ch>, Berend Snijder <berend.snijder@imls.uzh.ch> |
| Entry point(s): | PreCluster.m, CPCluster.m, RundDataFusion.m |
| Additional major working functions: | stage_one.sh |


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

Completion FLAGs
./iBRAIN_Stage_1.completed

## Inputs

**TODO!**

## Outputs

**TODO!**

