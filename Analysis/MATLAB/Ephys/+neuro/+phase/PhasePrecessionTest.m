classdef PhasePrecessionTest < matlab.unittest.TestCase
    
    properties (ClassSetupParameter)
        classSetupParameter1 = struct("scalar",1,"vector",[1 1]);
    end
    
    properties (TestParameter)
        testParameter1 = struct("scalar",1,"vector",[1 1]);
    end
    %PHASEPRECESSIONTEST Summary of this class goes here
    %   Detailed explanation goes here
    
    methods (Test)

        
        function control(testCase)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            
            
            
            testCase.assertTrue(true)
        end
        
        function test1(testCase)
            
        end
    end
    
    methods (TestMethodSetup)
        
        function methodSetup1(testCase)
            % Set up fresh state for each test. 
            
            % Tear down with testCase.addTeardown.
        end
        
    end
    
    methods (TestClassSetup)
        
        function classSetup1(testCase)
            % Set up shared state for all tests. 
            
            % Tear down with testCase.addTeardown.
        end
        
    end
end

