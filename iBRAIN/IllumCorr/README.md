# IllumCorr (iBRAIN module)

|||
|---|---|
| Module name: | IllumCorr |
| Contributors: | Yauhen Yakimovich <yauhen.yakimovich@uzh.ch>, Berend Snijder <berend.snijder@imls.uzh.ch>, Thomas Stoeger <thomas.stoeger@imls.uzh.ch>, Nico Battich <nicolas.battich@imls.uzh.ch>, Mathieu Fréchin <mathieu.frechin@uzh.ch> |
| Entry point: | prepare_batch_measure_illcor_stats.m, batch_measure_illcor_stats.m |
| Additional major working functions: | platenormalization.sh |


## iBRAIN_BRUTUS reference 

/iBRAIN/core/modules/do_illumination_correcton.sh

Summary iBRAIN "illumination correction" does:
- creates batches for illumination correction by calling prepare_batch_measure_illcor_stats, this is done per channel (and per Zstck if needed);
- measures illumination correction statistics by calling batch_measure_illcor_stats for every batch file, or for list of images given in a settings file;
- Optionnal : If  project folder contains learn_illcor_per_site.mat the fuction returns a persite set of measurements
- stores illumination correction statistics in BATCH directory;
- creates .pdf files in POSTANALYSIS directory with visualisations of mean and std statistics per pixel calculated from dataset.

## Completion FLAGs
./BATCH/illuminationcorrection.complete


## Inputs

- `batch_measure_illcor_stats()` consumes `BATCH/batch_illcor_channel001_zstack000.mat` file, prepared by `prepare_batch_measure_illcor_stats()`
- If  project folder contains learn_illcor_per_site.mat, illumination correction goes per site:

the MAT-file should contain a structure like this:

strProjectRoot = '/share/nas/ethz-share4/Data/Users/Yauhen/iBrainProjects/site_stacks';

site_config = struct('num_of_sites', 4,'site_regexp', '.*F%03d.*');

save(fullfile(strProjectRoot, 'learn_illcor_per_site.mat'),'site_config');

## Outputs

- BATCH/Measurements_batch_illcor_channel*_zstack*.mat

