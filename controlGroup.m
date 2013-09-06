classdef controlGroup < OpenSim.group
    % CONTROLGROUP - A class to store all control subjects.
    %
    %
    
    % Created by Megan Schroeder
    % Last Modified 2013-09-05
    
    
    %% Properties
    % Properties for the controlGroup class
    
    properties (SetAccess = private)
%         x20110622CONM 
%         x20110927CONM
%         x20120306CONF
        x20121204CONF
        x20121205CONF
        x20121205CONM
        x20121206CONF
        x20130221CONF
        x20130401CONM
    end
    
    
    %% Methods
    % Methods for the controlGroup class
    
    methods
        function obj = controlGroup()
            % CONTROLGROUP - Construct instance of class
            %
            
            % Add properties based on subject type
%             obj.x20110622CONM = OpenSim.subjectPartial('20110622CONM');
%             obj.x20110927CONM = OpenSim.subjectPartial('20110927CONM');
%             obj.x20120306CONF = OpenSim.subjectPartial('20120306CONF');
            obj.x20121204CONF = OpenSim.subjectFull('20121204CONF');
            obj.x20121205CONF = OpenSim.subjectFull('20121205CONF');
            obj.x20121205CONM = OpenSim.subjectFull('20121205CONM');
            obj.x20121206CONF = OpenSim.subjectFull('20121206CONF');
            obj.x20130221CONF = OpenSim.subjectFull('20130221CONF');
            obj.x20130401CONM = OpenSim.subjectFull('20130401CONM');           
        end
    end
    
end
