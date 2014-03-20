classdef cmc < OpenSim.rraSuper
    % CMC - A class to store Computed Muscle Control results from OpenSim.
    %
    %
    
    % Created by Megan Schroeder
    % Last Modified 2014-03-19
    
    
    %% Properties
    % Properties for the cmc class
    
    properties (SetAccess = public)
        NormKinematics  % Normalized to % of cycle (added in 'simulation' class)
        NormReserves    % Reserve actators, normalized to % of cycle (added in 'simulation' class)
    end
    
    
    %% Methods
    % Methods for the cmc class
    
    methods
        % *****************************************************************
        %       Constructor Method
        % *****************************************************************
        function obj = cmc(subID,simName)
            % CMC - Construct instance of class
            %
         
            % CMC path
            cmcPath = [OpenSim.getSubjectDir(subID),subID,'_',simName,'_CMC'];
            % Create instance of class from superclass
            obj = obj@OpenSim.rraSuper(cmcPath);            
        end        
    end
    
end
