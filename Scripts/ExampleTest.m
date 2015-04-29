classdef ExampleTest < matlab.unittest.TestCase
    methods(Test)
        function dummyTestOne(testCase)  % Test succeeds
            testCase.verifyEqual(5, 5, 'Testing 5==5')
        end
        function dummyTestTwo(testCase)  % Test passes
            testCase.verifyEqual(5, 5, 'Testing 5==5')
        end
        function dummyTestThree(testCase)
            % test code
        end
    end
end