classdef absmaxTest < matlab.unittest.TestCase
    methods(Test)
        function testAscendingSequence(testCase)  % Test fails
            s = -10:10;
            [resValue, resIndex] = absmax(s);
            testCase.verifyEqual(resValue, s(1), 'Testing resValue==s(1)');
            %testCase.verifyEqual(resIndex, 1, 'Testing resIndex==1');
        end
        
        function testDescendingSequence(testCase)  % Test fails
            s = 40:-1:-70;
            [resValue, resIndex] = absmax(s);
            testCase.verifyEqual(resValue, s(length(s)), 'Testing resValue==s(length(s))');
            %testCase.verifyEqual(resIndex, length(s), 'Testing resIndex==length(s)');
        end
    end
end