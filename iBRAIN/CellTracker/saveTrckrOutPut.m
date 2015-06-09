function saveTrckrOutPut(handles,TrackingMeasurementPrefixTrack)
    
    strObjectToTrack = handles.TrackingSettings.ObjectName;
    strSettingBaseName = handles.TrackingSettings.strSettingBaseName;
    strBatchPath = handles.strBatchPath;
    
    
    
    % [VZ] save the general tracking output handle
    

    
    handles.Measurements.(strObjectToTrack).('TrackingMeasurementPrefixTrack') = TrackingMeasurementPrefixTrack ;
    
    strMeasurementFileName = strcat('TrackOutputHandle_',strSettingBaseName);
    
  
    handles.OriginalTrackingSettings = handles.TrackingSettings;
    handles.OriginalstrSettingBaseName = strSettingBaseName;
    strWheretoSave = fullfile(strBatchPath, strMeasurementFileName);
    strWheretoSave = npc(strWheretoSave);
    save(strWheretoSave, 'handles','-v7.3')

    % save the measurements
    handles2 = struct();
    TrackingMeasurementPrefix = strcat('TrackObjects_',strSettingBaseName);
    handles2.Measurements.(strObjectToTrack).(TrackingMeasurementPrefix) = handles.Measurements.(strObjectToTrack).(TrackingMeasurementPrefix); 
    handles2.Measurements.(strObjectToTrack).(strcat(TrackingMeasurementPrefix,'Features')) = handles.Measurements.(strObjectToTrack).(strcat(TrackingMeasurementPrefix,'Features'));
    
    % [BS] Store handles as measurement file in strBatchPath
    strMeasurementFileName = sprintf('Measurements_%s_%s.mat',strObjectToTrack,TrackingMeasurementPrefix);
    strWheretoSave = fullfile(strBatchPath, strMeasurementFileName);
    strWheretoSave = npc(strWheretoSave);
    save(strWheretoSave, 'handles2','-v7.3')
    
    
    % save the MetaData
    handles2 = struct();
    TrackingMeasurementPrefix = strcat('TrackObjectsMetaData_',strSettingBaseName);
    handles2.Measurements.(strObjectToTrack).(TrackingMeasurementPrefix) = handles.Measurements.(strObjectToTrack).(TrackingMeasurementPrefix);
    handles2.Measurements.(strObjectToTrack).(strcat(TrackingMeasurementPrefix,'Features')) = handles.Measurements.(strObjectToTrack).(strcat(TrackingMeasurementPrefix,'Features'));
    
    % [BS] Store handles as measurement file in strBatchPath
    strMeasurementFileName = sprintf('Measurements_%s_%s.mat',strObjectToTrack,TrackingMeasurementPrefix);
    strWheretoSave = fullfile(strBatchPath, strMeasurementFileName);
    strWheretoSave = npc(strWheretoSave);
    save(strWheretoSave, 'handles2','-v7.3')
    
    % save the Image
    handles2 = struct();
    TrackingMeasurementPrefix = strcat('TrackObjects_',strSettingBaseName);
    handles2.Measurements.Image.(TrackingMeasurementPrefix) = handles.Measurements.Image.(TrackingMeasurementPrefix);
    handles2.Measurements.Image.(strcat(TrackingMeasurementPrefix,'Features')) = handles.Measurements.Image.(strcat(TrackingMeasurementPrefix,'Features'));
    
    % [BS] Store handles as measurement file in strBatchPath
    strMeasurementFileName = sprintf('Measurements_Image_%s.mat',TrackingMeasurementPrefix);
    strWheretoSave = fullfile(strBatchPath, strMeasurementFileName);
    strWheretoSave = npc(strWheretoSave);
    save(strWheretoSave, 'handles2','-v7.3')
    
    
    
 
    
   
end

