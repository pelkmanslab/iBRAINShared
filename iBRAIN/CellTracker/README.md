# CellTracker (iBRAIN module)

|||
|---|---|
| Module name: | CellTracker |
| Contributors: |  Nicolas Battich <nicolas.battich@uzh.ch>, Mathieu Frechin <mathieu.frechin@uzh.ch>|
| Entry point: | [iBrainTrackerV1.m](https://github.com/pelkmanslab/iBRAINShared/blob/tracker/iBRAIN/CellTracker/iBrainTrackerV1.m) |

See the entry-point function for main documentation and the algorithm explanation.

## Input


```
SetTracker_*.txt
```

e.g.

```
structTrackingSettings.TrackingMethod = 'Distance';
structTrackingSettings.ObjectName = 'Nuclei';
structTrackingSettings.PixelRadius = 15;
structTrackingSettings.OverlapFactorC = 0.25;
structTrackingSettings.OverlapFactorP = 0.25;
structTrackingSettings.WavelengthID = '_w1';
structTrackingSettings.CreateFrames = 'Yes';
structTrackingSettings.TailTime = 1;
```

## Output


```
BATCH/Measurements_Nuclei_TrackObjects*.mat
```
