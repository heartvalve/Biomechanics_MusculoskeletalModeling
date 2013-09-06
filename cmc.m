classdef cmc < OpenSim.rraSuper
    % CMC - A class to store Computed Muscle Control results from OpenSim.
    %
    %
    
    % Created by Megan Schroeder
    % Last Modified 2013-09-05
    
    
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
