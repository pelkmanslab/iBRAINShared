# SVM classification (iBRAIN module)

|||
|---|---|
| Module name: | do_svm_classification |
| Contributors: |  Thomas Stoeger <thomas.stoeger@imls.uzh.ch>|
| Entry point: | [SVM_Classify_with_Probabilities_iBrain.m](https://github.com/pelkmanslab/iBRAINShared/blob/master/iBRAIN/SVM/SVM_Classify_with_Probabilities_iBRAIN.m) |
|Additional major working function: | [PlotBinaryClassificationResults.m](https://github.com/pelkmanslab/iBRAINShared/blob/master/iBRAIN/SVM/PlotBinaryClassificationResults.m)|


## iBRAIN_BRUTUS reference
[/iBRAIN/core/modules/do_svm_classification.sh](https://github.com/pelkmanslab/iBRAIN_BRUTUS/blob/master/iBRAIN/core/modules/do_svm_classification.sh)

## Summary
<p>
A user will use visual feedback to train a SVM classifier with [classify_gui](https://github.com/pelkmanslab/CellClassificationPelkmans/blob/master/ClientSide/ClassifyGui/classify_gui.m) </p>

<p>
iBrains [do_svm_classification.sh](https://github.com/pelkmanslab/iBRAIN_BRUTUS/blob/master/iBRAIN/core/modules/do_svm_classification.sh) will apply this classifier to all cells of a plate, if the classifier (and addtional metainformation) have been saved as SVM_.*mat
</p>

<p>
After the classifications have been saved for all cells of a plate (following the convention /BATCH/Measurements_SVM.*.mat), [PlotBinaryClassificationResults.m](https://github.com/pelkmanslab/iBRAINShared/blob/master/iBRAIN/SVM/PlotBinaryClassificationResults.m) will save summary statistics on a per-well basis into the POSTANALYSIS folder. This includes pdfs reflecting the layout of the plate and excel-compatible csv tables.
</p>


## Completion flags
|||
|---|---|
|BATCH/SVMClassification_*.results | This flag reflects the command line output and is only present, if classification did not have an error. Importantly, it is not used as a completion flag by [do_svm_classification.sh](https://github.com/pelkmanslab/iBRAIN_BRUTUS/blob/master/iBRAIN/core/modules/do_svm_classification.sh) |
|BATCH/Measurements_SVM_.*.mat | Output of classification. Used as flag by [do_svm_classification.sh](https://github.com/pelkmanslab/iBRAIN_BRUTUS/blob/master/iBRAIN/core/modules/do_svm_classification.sh) |
|POSTANALYSIS/Measurements_SVM_.*_overview.pdf | Overview image of per-well classifcation. Used as FALLBACK-flag by [do_svm_classification.sh](https://github.com/pelkmanslab/iBRAIN_BRUTUS/blob/master/iBRAIN/core/modules/do_svm_classification.sh) |
|POSTANALYSIS/Measurements_SVM_.*_overview.csv | Overview table of per-well classifcation. Used as FALLBACK-FALLBACK-flag by [do_svm_classification.sh](https://github.com/pelkmanslab/iBRAIN_BRUTUS/blob/master/iBRAIN/core/modules/do_svm_classification.sh) |








**iBRAIN_UZH module**
iBRAINDemoProject/run_svm.br
_currently appears empty (Apr 13th)_

**Summary**
"do SVM classification" :  
	* runs SVM classifications on objects generated from images processed by CellProfiler pipelines, reformatted by DataFusion  
	* outputs classification results in .mat files in BATCH directory in project folder;  
	* outputs .csv and .pdf overviews of results per well.  

**Completion FLAGs**  
./BATCH/SVMClassification_*.results (standard output of lsf saved under this name, again via lsf)

**Dependencies**  

* Depended on https://github.com/pelkmanslab/CellClassificationPelkmans

* CellProfiler measurements, which have been reformatted/repackaged by DataFusion (note: no support for original CP measurements)
* File containing SVM model and definition of underlying data (features that should be used & their normalization). Such a file is usually created by classify_gui and saved as SVM_.*.mat
* For automated submission: Presence of SVM_*.mat files in project or plate folder
* For proper normalization: Measurements_Mean_Std.mat in /BATCH (**Attention: absence of those files will not result in an error message during classification!**)

**Code and function calls**
* SVM_Classify_with_Probabilities_iBRAIN(FullFilePathToSVMFile, PathToBatchFolder);
* After saving SVM Measurements into /BATCH, SVM_Classify_with_Probabilities_iBRAIN calls PlotBinaryClassificationResults (directly within MATLAB)


## 6.(b) Missing Functionality from iBRAIN(2011)

* **Fast reactivity**: SVMs did usually finish in approx. 40min and submitted to the 1h queue, which is usually free. Now most jobs of full plates require approx. 80min (usually we have more objects / less undersegmentation / image more cells in a typical normal experiment). -> These jobs will fail in the 1h queue and then become resubmitted to the 8h queue. Thus a user is forced to wait until all jobs, which are queued in iBrain, finish (which can be days if multiple CellProfiler pipelines are running). 
* **Correct submission statement on web-interface** (webpage of iBRAIN_BRUTUS lists same submission twice - while only one submission occurs)

## 6.(c) Requested Additional Functionality for iBRAIN_UZH
**Improve interactivity and reduce human waiting time**
* **Give CCP jobs higher priority than the bulk of the jobs** managed by iBrain (e.g. put on top of queue or better: separate high-priority queue for SVMs). In practice this **would save hours/days of completely unnecessary human waiting time** (if iBrain is busy with other projects, e.g.: CellProfiler jobs)
* **Parallelize classification**; e.g: request 8-core machines and replace the main for-loop in SVM_Classify_with_Probabilities_iBRAIN by a parfor-loop (after matlabpool open): This would reduce processing / human waiting time from 80min to 10min! (only 5-10min of trivial coding would be required)
* Report/keep logs (.results) if there is an error during classification on iBrain
