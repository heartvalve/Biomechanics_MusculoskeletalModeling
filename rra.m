classdef rra < OpenSim.rraSuper
    % RRA - A class to store Residual Reduction Algorithm results from OpenSim.
    %
    %
    
    % Created by Megan Schroeder
    % Last Modified 2014-01-13
    
    
    %% Properties
    % Properties for the rra class
    
    properties
        Residuals     % Residuals (updated by simulation class)
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
