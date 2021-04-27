classdef HMMModel
    %HMMMODEL Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Oscillation
    end
    
    methods
        function obj = HMMModel(osc)
            %HMMMODEL Construct an instance of this class
            %   Detailed explanation goes here
            obj.Oscillation=osc;
        end
        
        function outputArg = run(obj)
            %% Simple test of hmmDiscreteFitEm
            % We compare how well the true model can decode a sequence, compared to a
            % model learned via EM using the best permutation of the labels.
            %%
            %% Define the generating model
            
            % This file is from pmtk3.googlecode.com
            
            setSeed(0);
            nHidStates = 4;
            
            %% Learn the model using EM with random restarts
            nrestarts = 2;
            vals=obj.Oscillation.getValues;
            modelEM = hmmFit(vals, nHidStates, 'discrete', ...
                'convTol', 1e-5, 'nRandomRestarts', nrestarts, 'verbose', false);
            
            %% How different are the respective log probabilities?
            fprintf('emModel LL: %g\n', hmmLogprob(modelEM, observed));
            
            
            %% Decode using the EM model
            decodedFromEMviterbi = hmmMap(modelEM, observed);
            decodedFromEMmaxMarg = maxidx(hmmInferNodes(modelEM, observed), [], 1);
           
        end
    end
end

