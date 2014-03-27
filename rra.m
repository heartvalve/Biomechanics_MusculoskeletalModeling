classdef rra < OpenSim.rraSuper
    % RRA - A class to store Residual Reduction Algorithm results from OpenSim.
    %
    %
    
    % Created by Megan Schroeder
    % Last Modified 2014-03-26
    
    
    %% Properties
    % Properties for the rra class
    
    properties (SetAccess = public)
        NormKinematics  % Kinematics, normalized to % of cycle (added in 'simulation' class)
        NormTorques     % Reserve actators, normalized to % of cycle (added in 'simulation' class)
        NormResiduals   % Residual actuators, normalized to % of cycle (added in 'simulation' class)
    end
    
    
    %% Methods
    % Methods for the rra class
    
    methods
        % *****************************************************************
        %       Constructor Method
        % *****************************************************************
        function obj = rra(subID,simName)
            % RRA - Construct instance of class
            %
            
            % RRA path
            rraPath = [OpenSim.getSubjectDir(subID),subID,'_',simName,'_RRA'];
            % Create instance of class from superclass
            obj = obj@OpenSim.rraSuper(rraPath);
        end
    end
    
end
