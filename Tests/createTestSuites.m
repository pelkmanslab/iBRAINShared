%
% [Owen Feehan]. Creates a list of test-suites for testing the library
% contents
%
function suites = createTestSuites()
    import matlab.unittest.TestSuite

    % Dummy example tests
    suiteExampleTest   = TestSuite.fromClass(?ExampleTest);

    % All tests in the main library folder
    suiteMainFolder = matlab.unittest.TestSuite.fromFolder('../');

    % Combine tests
    suites = [suiteExampleTest, suiteMainFolder]
end