classdef subjectPartial < OpenSim.subject
    % SUBJECTPARTIAL - Subject with partial dataset.
    %
    %
    
    % Created by Megan Schroeder
    % Last Modified 2013-09-05
    
    
    %% Properties
    % Properties for the subjectPartial class
    
    properties
        A_SD2F_RepGRF
        A_SD2F_RepKIN
        A_Walk_RepGRF
        A_Walk_RepKIN
        U_SD2F_RepGRF
        U_SD2F_RepKIN
        U_Walk_RepGRF
        U_Walk_RepKIN
    end
    
    
    %% Methods
    % Methods for the subject class
    
    methods
        function obj = subjectPartial(subID)
            % SUBJECTPARTIAL - Construct instance of class
            %
            
            % Create instance of class from superclass
            obj = obj@OpenSim.subject(subID);
        end
    end
    
end
