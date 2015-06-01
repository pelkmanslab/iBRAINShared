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
A user will use visual feedback to train a SVM classifier with [classify_gui](https://github.com/pelkmanslab/CellClassificationPelkmans/blob/master/ClientSide/ClassifyGui/classify_gui.m) <br>

iBrains [do_svm_classification.sh](https://github.com/pelkmanslab/iBRAIN_BRUTUS/blob/master/iBRAIN/core/modules/do_svm_classification.sh) will apply this classifier to all cells of a plate, if the classifier (and addtional metainformation) have been saved as SVM_.*mat by [classify_gui](https://github.com/pelkmanslab/CellClassificationPelkmans/blob/master/ClientSide/ClassifyGui/classify_gui.m)
<br>

After the classifications have been saved for all cells of a plate , [PlotBinaryClassificationResults.m](https://github.com/pelkmanslab/iBRAINShared/blob/master/iBRAIN/SVM/PlotBinaryClassificationResults.m) will save summary statistics on a per-well basis into the POSTANALYSIS folder. This includes pdfs reflecting the layout of the plate and excel-compatible csv tables.


## Completion flags
|||
|---|---|
|BATCH/SVMClassification_*.results | This flag reflects the command line output and is only present, if classification did not have an error. Importantly, it is <b> not used as a completion flag by [do_svm_classification.sh](https://github.com/pelkmanslab/iBRAIN_BRUTUS/blob/master/iBRAIN/core/modules/do_svm_classification.sh) </b>|
|BATCH/Measurements_SVM_.*.mat | Output of classification. Used as flag by [do_svm_classification.sh](https://github.com/pelkmanslab/iBRAIN_BRUTUS/blob/master/iBRAIN/core/modules/do_svm_classification.sh) |
|POSTANALYSIS/Measurements_SVM_.*_overview.pdf | Overview image of per-well classifcation. Used as FALLBACK-flag by [do_svm_classification.sh](https://github.com/pelkmanslab/iBRAIN_BRUTUS/blob/master/iBRAIN/core/modules/do_svm_classification.sh) |
|POSTANALYSIS/Measurements_SVM_.*_overview.csv | Overview table of per-well classifcation. Used as FALLBACK-FALLBACK-flag by [do_svm_classification.sh](https://github.com/pelkmanslab/iBRAIN_BRUTUS/blob/master/iBRAIN/core/modules/do_svm_classification.sh) |

## File dependencies
- CellProfiler measurements, including Image_ObjectCount (reformatted by Datafusion)
- Classification file created by classify_gui (standard output), saved as SVM_X.mat (where X is an arbitrary phrase, that does not start with a number)
- BATCH/Measurements_Mean_Std.mat (created by create_plate_normalization)
- /BASICDATA.mat for [classify_gui](https://github.com/pelkmanslab/CellClassificationPelkmans/blob/master/ClientSide/ClassifyGui/classify_gui.m)

## Inputs

###do_svm_classification.sh
- Classification file created by [classify_gui](https://github.com/pelkmanslab/CellClassificationPelkmans/blob/master/ClientSide/ClassifyGui/classify_gui.m), saved as /SVM_.*.mat 

###SVM_Classify_with_Probabilities_iBRAIN.m 
- Classification file created by [classify_gui](https://github.com/pelkmanslab/CellClassificationPelkmans/blob/master/ClientSide/ClassifyGui/classify_gui.m), saved under arbitrary name, that does not start with SVM_ followed by a number
- BATCH/Measurements_Mean_Std.mat
- BATCH/Measurements_Image_ObjectCount.mat containg counts for one group of objects, that has been called "Nuclei" in the original CellProfiler pipeline 


###PlotBinaryClassificationResults.m
- Output of SVM_Classify_with_Probabilities_iBRAIN (/BATCH/Measurements_X.mat , where X is name of output of classify_gui)
-  Classification into two (and not more) classes in classify_gui
-  One class has been named not_X or non_X in classify_gui, where X is the name of the other class

## Outputs

|||
|---|---|
|BATCH/SVMClassification_*.results | Command line output; currently provided by lsf|
|BATCH/Measurements_SVM_.*.mat | Single-cell classification. Created by SVM_Classify_with_Probabilities_iBrain.m |
|POSTANALYSIS/Measurements_SVM_.*_overview.pdf | Overview image of per-well classifcation. Created by PlotBinaryClassificationResults.m	|
|POSTANALYSIS/Measurements_SVM_.*_overview.csv | Overview table of per-well classifcation. Created by PlotBinaryClassificationResults.m |
