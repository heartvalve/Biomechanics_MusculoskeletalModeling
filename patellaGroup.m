classdef patellaGroup < OpenSim.group
    % PATELLAGROUP - A class to store all patella tendon subjects.
    %
    %
    
    % Created by Megan Schroeder
    % Last Modified 2013-09-05
    
    
    %% Properties
    % Properties for the patellaGroup class
    
    properties (SetAccess = private)
%         x20110706APRF
%         x20111025APRM
        x20120919APLF
        x20120920APRM
        x20121204APRM 
%         x20130207APRM       
    end
    
    
    %% Methods
    % Methods for the patellaGroup class
    
    methods
        function obj = patellaGroup()
            % PATELLAGROUP - Construct instance of class
            %
            
            % Add properties based on subject type
%             obj.x20110706APRF = OpenSim.subjectPartial('20110706APRF');
%             obj.x20111025APRM = OpenSim.subjectPartial('20111025APRM');
            obj.x20120919APLF = OpenSim.subjectFull('20120919APLF');
            obj.x20120920APRM = OpenSim.subjectFull('20120920APRM');
            obj.x20121204APRM = OpenSim.subjectFull('20121204APRM');
%             obj.x20130207APRM = OpenSim.subjectFull('20130207APRM');
        end
    end
    
end
