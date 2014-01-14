classdef id < handle
    % ID - A class to store Inverse Dynamics results from OpenSim.
    %
    %
    
    % Created by Megan Schroeder
    % Last Modified 2014-01-13
    
    
    %% Properties
    % Properties for the id class
    
    properties (SetAccess = private)
        Time
        Data
    end
    
    
    %% Methods
    % Methods for the id class
    
    methods
        function obj = id(subID,simName)
            % ID - Construct instance of class
            %
            
            % ID path
            idPath = [OpenSim.getSubjectDir(subID),subID,'_',simName,'_ID.sto'];
            % Import the file
            idimport = importdata(idPath,'\t',7);
            % Column headers
            names = idimport.colheaders(2:end);
            % Time
            obj.Time = idimport.data(:,1);
            % Data
            obj.Data = dataset({idimport.data(:,2:end),names{:}});
        end        
    end
    
end
