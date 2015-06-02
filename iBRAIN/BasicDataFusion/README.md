# BasicDataFusion (iBRAIN module)

|||
|---|---|
| Module name: | BasicDataFusion |
| Contributors: | Victoria Green victoria.green@uzh.ch, Berend Snijder <berend.snijder@imls.uzh.ch> |
| Entry point: | fuse_basic_data.m |
| Additional major working functions: | check_dg_plate_correlations.m |

## BRAIN_BRUTUS reference

/iBRAIN/core/modules/fuse_basic_data.sh

## Summary

iBRAIN "fuse basic data" does:
- adds cell type overview data to plate BASICDATA_*.mat files; 
- creates BASICDATA.mat file in project directory through fusion of all plate-wise BASICDATA_*.mat files;
- creates .pdf files in project directory with overviews of plate-wise correlations for infection and cell number;
- creates ADVANCEDATA2.mat file in project directory;
- ADVANCEDATA2 contains log2 relative infection index (log2RII) and cell number as BASICDATA, but reordered such that values are grouped per Entrez gene ID i.e. per oligo, per replicate;
- ADVANCEDATA2 also contains median values per gene (median of median) and a binary readout of whether gene is a hit i.e. log2RII >/< threshold.

##Completion FLAGs 

`./FuseBasicData_*.results`

##File Dependencies 

Resubmitted for each new `./BATCH/CreatePlateOverview_*.results`

##Inputs

`BATCH/BASICDATA_*.mat` files in each plate folder.

##Outputs

- BASICDATA.mat
- BASICDATA_PlateCorrelations.pdf
- ADVANCEDATA2.mat
- BASICDATA_*.csv


## TODO

- rename fuse_basic_data_v5 into fuse_basic_data
