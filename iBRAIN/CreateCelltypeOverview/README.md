# CreateCelltypeOverview (iBRAIN module)

|||
|---|---|
| Module name: | CreateCelltypeOverview |
| Contributors: | Prisca Liberali <prisca.liberali@uzh.ch>, Victoria Green victoria.green@uzh.ch |
| Entry point: | Gather_CellTypeData_iBRAIN2.m |
| Additional major working functions: |  |

## BRAIN_BRUTUS reference

`/iBRAIN/core/modules/create_celltype_overview.sh`

## Summary

iBRAIN "create cell type overview" does:  
- calls Gather_CellTypeData_iBRAIN2.m 
- creates Measurements_Nuclei_CellType_Overview.mat containing summary of types of cells present (any SVM present in the project) in each well in BASICDATA_CellType;  
- cell types described include all those derived from population context measurements, SVMs and infection, in both absolute numbers and index;  
- also gives number of out of focus images per well and some average per well values e.g. LCD.  
	

## Completion FLAGs

- ./BATCH/CreateCellTypeOverview_*.results  
- ./BATCH/Measurements_Nuclei_CellType_Overview.mat  

## Dependencies
Resubmitted on completion of new SVMs.  

## Code and function calls

```
Gather_CellTypeData_iBRAIN2('${BATCHDIR}');
```

# TODO

- Check again if TraditionalPostClusterInfectionScoring_with_SVM.m is a dependency.
