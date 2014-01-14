classdef ik < handle
    % IK - A class to store Inverse Kinematics results from OpenSim.
    %
    %
    
    % Created by Megan Schroeder
    % Last Modified 2014-01-13
    
    
    %% Properties
    % Properties for the ik class
    
    properties (SetAccess = private)
        Time
        Data
    end
    
    
    %% Methods
    % Methods for the ik class
    
    methods
        function obj = ik(subID,simName)
            % IK - Construct instance of class
            %
            
            % IK path
            ikPath = [OpenSim.getSubjectDir(subID),subID,'_',simName,'_IK.mot'];
            % Import the file
            ikimport = importdata(ikPath,'\t',11);
            % Column headers
            names = ikimport.colheaders(2:end);
            % Time
            obj.Time = ikimport.data(:,1);
            % Data
            obj.Data = dataset({ikimport.data(:,2:end),names{:}});
        end        
    end
    
end
