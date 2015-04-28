import matlab.unittest.TestRunner
import matlab.unittest.plugins.TAPPlugin
import matlab.unittest.plugins.ToFile

%
% Script to execute matlab tests
%
% See:
% http://ch.mathworks.com/help/matlab/ref/matlab.unittest.plugins.tapplugin-class.html
%
% Expects to be run from the Scripts/ directory
%

% PARAMETERS START

% TAP file to output
outFilePathRelative = '../testsOutput.tap';

% Top-level folder containing all possible matlab tests
topLevelMatlabFolder = '../';
% PARAMETERS END


% Check that we are in right directory
[upperPath, deepestFolder, ignoreThisStr] = fileparts(pwd());
if (strcmp(deepestFolder,'Scripts')==0)
   error('Not in Scripts/ directory');
end


% All tests from the main library folder (recursively)
suites = matlab.unittest.TestSuite.fromFolder(topLevelMatlabFolder, 'IncludingSubfolders', true);


% NOTE: It is critically important that an absolute file path is passed to
%   TAPPlugin.producingOriginalFormat as otherwise test entries become
%   missing in the output TAP file
outFileResolved = fullfile(pwd(),outFilePathRelative);

% We delete the existing tapFile as TAPPlugin.producingOriginalFormat
%   appends to any existing files, and we need it to be only a s
%    single test case for Jenkins.
delete(outFileResolved);
plugin = TAPPlugin.producingOriginalFormat(ToFile(outFileResolved));

runner = TestRunner.withTextOutput;
runner.addPlugin(plugin)

%pluginLogging = matlab.unittest.plugins.LoggingPlugin.withVerbosity(3);
%runner.addPlugin(pluginLogging)

result = runner.run(suites);

% Display TAP file
disp(fileread(outFileResolved))