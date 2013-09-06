classdef id < handle
    % ID - A class to store Inverse Dynamics results from OpenSim.
    %
    %
    
    % Created by Megan Schroeder
    % Last Modified 2013-09-05
    
    
    %% Properties
    % Properties for the id class
    
    properties (SetAccess = private)
        time
        data
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
            obj.time = idimport.data(:,1);
            % Data
            obj.data = dataset({idimport.data(:,2:end),names{:}});
        end        
    end
    
end
