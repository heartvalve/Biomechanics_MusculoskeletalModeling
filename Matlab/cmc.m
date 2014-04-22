classdef cmc < OpenSim.rraSuper
    % CMC - A class to store Computed Muscle Control results from OpenSim.
    %
    %
    
    % Created by Megan Schroeder
    % Last Modified 2014-03-27
    
    
    %% Properties
    % Properties for the cmc class
    
    properties (SetAccess = public)
        NormKinematics  % Kinematics, normalized to % of cycle (added in 'simulation' class)
        NormReserves    % Reserve actators, normalized to % of cycle (added in 'simulation' class)
        NormResiduals   % Residual actuators, normalized to % of cycle (added in 'simulation' class)
        NormActivations % CMC muscle activations, normalized to % of cycle (added in 'simulation' class)
    end
    
    
    %% Methods
    % Methods for the cmc class
    
    methods
        % *****************************************************************
        %       Constructor Method
        % *****************************************************************
        function obj = cmc(subID,simName,readCMCstate)
            % CMC - Construct instance of class
            %
         
            % CMC path
            cmcPath = [OpenSim.getSubjectDir(subID),subID,'_',simName,'_CMC'];
            % Create instance of class from superclass
            obj = obj@OpenSim.rraSuper(cmcPath,readCMCstate);            
        end        
    end
    
end
