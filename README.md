iBRAINShared
============

A library of shared (mostly MATLAB) code used by both [iBRAIN_BRUTUS](https://github.com/pelkmanslab/iBRAIN_BRUTUS) and [iBRAIN_UZH](https://github.com/pelkmanslab/iBRAIN_UZH).

It is a part of transition process from BRUTUS to UZH.  It contains most of the code of 
General/iBrainBasics folder.

It can be used alongside [CellProfilerPelkmans](https://github.com/pelkmanslab/CellProfilerPelkmans).

## How to install?

iBRAINShared is part of each [iBRAIN_UZH release](https://github.com/pelkmanslab/iBRAIN_UZH/releases) in *iBRAIN/tools/iBRAINShared/*

Please follow the instructions in the [iBRAIN_UZH User Guide](https://github.com/pelkmanslab/iBRAIN_UZH/blob/master/doc/USER_GUIDE.md)

## Documentation

* [Automatically generated API documentation](http://jenkins.pelkmanslab.org/job/iBRAINShared_Master/iBRAINShared_API_Documentation/) -  updated daily, primary reference material.
* [Core Module help](https://github.com/pelkmanslab/iBRAIN_BRUTUS/wiki/iBRAIN_BRUTUS-core-module-help). A subset of *core* modules

## List of iBRAIN_BRUTUS modules inside iBRAINShared

All of the following modules described here are code frozen. To keep track of these modules in the new iBRAIN_UZH version (i.e. in case such modules were selected for the newer version), their respective location is linked for convenience. 

Note that [iBRAIN folder](https://github.com/pelkmanslab/iBRAINShared/tree/master/iBRAIN) inside iBRAINShared repository contains modules that consists of MATLAB code only. Files of other (non-MATLAB) modules are located inside code of [iBRAIN_BRUTUS](https://github.com/pelkmanslab/iBRAIN_BRUTUS) repository.

> The list is organized as following: 
> iBRAIN_BRUTUS workflow step -> location of iBRAIN module in iBRAINShared -> location of the derived code/module in (new) IBRAIN_UZH

- check input images
 - *check_image_set* step is bash code in [check_image_set.sh](https://github.com/pelkmanslab/iBRAIN_BRUTUS/blob/master/iBRAIN/core/modules/check_image_set.sh) of iBRAIN_BRUTUS
 - *check_image_set_nikon* step is bash/python code in [check_image_set_nikon.sh](https://github.com/pelkmanslab/iBRAIN_BRUTUS/blob/master/iBRAIN/core/modules/check_image_set_nikon.sh) of iBRAIN_BRUTUS
 - *rename_nikon* step is bash/python code in [rename_nikon.sh](https://github.com/pelkmanslab/iBRAIN_BRUTUS/blob/master/iBRAIN/core/modules/rename_nikon.sh) of iBRAIN_BRUTUS
- illumination correction
 - *do_illumination_correction* step is located in [iBRAIN/IllumCorr](https://github.com/pelkmanslab/iBRAINShared/tree/master/iBRAIN/IllumCorr), became [+iBRAIN/+IllumCorr](https://github.com/pelkmanslab/iBRAIN_UZH/tree/master/iBRAIN/modules/matlab/+iBRAIN/+IllumCorr)
- convert tiff to png
 - *convert_tiff_to_png* step is bash code in [convert_tiff_to_png.sh](https://github.com/pelkmanslab/iBRAIN_BRUTUS/blob/master/iBRAIN/core/modules/convert_tiff_to_png.sh) of iBRAIN_BRUTUS
 - *create_mips* step is python/bash code in [create_mips.sh](https://github.com/pelkmanslab/iBRAIN_BRUTUS/blob/master/iBRAIN/core/modules/create_mips.sh) of iBRAIN_BRUTUS
- create jpgs
 - *create_jpgs* step is located in [iBRAIN/CreateJpgsOverview](https://github.com/pelkmanslab/iBRAINShared/tree/master/iBRAIN/CreateJpgsOverview)
- run CellProfiler PIPE
 - *stage_one* step is located in [iBRAIN/CellProfiler](https://github.com/pelkmanslab/iBRAINShared/tree/master/iBRAIN/CellProfiler)
- SVM classification
 - *do_svm_classification* step is located in [iBRAIN/CellClassification](https://github.com/pelkmanslab/iBRAINShared/tree/master/iBRAIN/CellClassification)
- post-analysis
 - *create_out_of_focus_measurement* step is located in [iBRAIN/CellClassification](https://github.com/pelkmanslab/iBRAINShared/tree/master/iBRAIN/CellClassification)
 - *create_plate_normalization* step is located in [iBRAIN/PlateNormalization](https://github.com/pelkmanslab/iBRAINShared/tree/master/iBRAIN/PlateNormalization)
 - *create_population_context_measurements* step is located in [iBRAIN/CreatePopulationContext](https://github.com/pelkmanslab/iBRAINShared/tree/master/iBRAIN/CreatePopulationContext)
 - *stitch_segmentation_per_well* step is located in [iBRAIN/SegmentationPerWell](https://github.com/pelkmanslab/iBRAINShared/tree/master/iBRAIN/SegmentationPerWell)
 - *create_plate_overview* step is located in [iBRAIN/BasicData](https://github.com/pelkmanslab/iBRAINShared/tree/master/iBRAIN/BasicData)
 - *fuse_basic_data* step is located in [iBRAIN/BasicDataFusion](https://github.com/pelkmanslab/iBRAINShared/tree/master/iBRAIN/BasicDataFusion)
 - *create_celltype_overview* step is located in [iBRAIN/CreateCelltypeOverview](https://github.com/pelkmanslab/iBRAINShared/tree/master/iBRAIN/CreateCelltypeOverview)
 - *do_bin_correction* step is located in [iBRAIN/BinCorrection](https://github.com/pelkmanslab/iBRAINShared/tree/master/iBRAIN/BinCorrection)
 - *do_cell_tracking* step is located in [iBRAIN/CellTracker](https://github.com/pelkmanslab/iBRAINShared/tree/master/iBRAIN/CellTracker)
