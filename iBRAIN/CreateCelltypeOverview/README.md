**BRAIN_BRUTUS reference**
/iBRAIN/core/modules/create_celltype_overview.sh

**iBRAIN_UZH module**

**Summary**
iBRAIN "create cell type overview" does:  
	- calls TraditionalPostClusterInfectionScoring_with_SVM;  
	- creates Measurements_Nuclei_CellType_Overview.mat containing summary of types of cells present in each well;  
	- cell types described include all those derived from population context measurements, SVMs and infection, in both absolute numbers and index;  
	- also gives number of out of focus images per well and some average per well values e.g. LCD.  

**Completion FLAGs**  
./BATCH/CreateCellTypeOverview_*.results  
./BATCH/Measurements_Nuclei_CellType_Overview.mat  

**Dependencies**  
Resubmitted on completion of new SVMs.  

**Code and function calls**

```
Gather_CellTypeData_iBRAIN2('${BATCHDIR}');
```
