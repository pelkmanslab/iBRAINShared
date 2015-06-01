function matImageSegmentation = loadSegmentation(strImagePath,strImageFileName)

strAlignCyclesPath = strrep(strImagePath,'SEGMENTATION','ALIGNCYCLES');

if isdir(strAlignCyclesPath)

    persistent shift;

    if isempty(shift)
        % check whether json package is installed
        if ~exist('loadjson')
            % Please install JSONlab package from
            % http://www.mathworks.com/matlabcentral/fileexchange/33381
            error('unable to load settings file, ''loadjson'' not on path')
        end
        % load descriptor variable from json file
        shift = loadjson(fullfile(strAlignCyclesPath,'shiftDescriptor.json'));
    end

    %%% change directory and filename according to shift descriptor
    strSegmentationPath = [strrep(strImagePath, [filesep,'BATCH'], filesep), shift.SegmentationDirectory];
    strSegmentationFileNameTrunk = shift.SegmentationFileNameTrunk;
    strSegmentationFileName = regexprep(strImageFileName,'.+(_\w{1}\d{2}_)',sprintf('%s$1',strSegmentationFileNameTrunk));

    %%% load original segmentation image
    matOrigImage = double(imread(fullfile(strSegmentationPath,strSegmentationFileName{1,:})));

    %%% get index of current image
    strLookup = regexprep(strImageFileName,'A\d{2}Z\d{2}C\d{2}_Segmented.*.(png|tif?)','A\\d{2}Z\\d{2}C\\d{2}.(png|tif?)');
    index = find(cell2mat(regexp(cellstr(shift.fileName),strLookup)));

    %%% align segmentation image according to shift descriptor
    if abs(shift.yShift(site))>shift.maxShift || abs(shift.xShift(site))>shift.maxShift % don't shift images if shift values are very high (reflects empty images)
        matImageSegmentation = matOrigImage(1+shift.lowerOverlap : end-shift.upperOverlap, 1+shift.rightOverlap : end-shift.leftOverlap);
    else
        matImageSegmentation = matOrigImage(1+shift.lowerOverlap-shift.yShift(index) : end-(shift.upperOverlap+shift.yShift(index)), 1+shift.rightOverlap-shift.xShift(index) : end-(shift.leftOverlap+shift.xShift(index)));
    end

else

    matImageSegmentation = double(imread(fullfile(strImagePath,strImageFileName{1,:})));

end

end
