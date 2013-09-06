classdef hamstringGroup < OpenSim.group
    % HAMSTRINGGROUP - A class to store all hamstring tendon subjects.
    %
    %
    
    % Created by Megan Schroeder
    % Last Modified 2013-09-05
    
    
    %% Properties
    % Properties for the hamstringGroup class
    
    properties (SetAccess = private)
%         x20111130AHLM
%         x20120306AHRF
%         x20120313AHLM
%         x20120403AHLF
        x20120912AHRF
%         x20120922AHRM
        x20121008AHRM
        x20121108AHRM
        x20121110AHRM
        x20130401AHLM        
    end
    
    
    %% Methods
    % Methods for the hamstringGroup class
    
    methods
        function obj = hamstringGroup()
            % HAMSTRINGGROUP - Construct instance of class
            %
            
            % Add properties based on subject type
%             obj.x20111130AHLM = OpenSim.subjectPartial('20111130AHLM');
%             obj.x20120306AHRF = OpenSim.subjectPartial('20120306AHRF');
%             obj.x20120313AHLM = OpenSim.subjectPartial('20120313AHLM');
%             obj.x20120403AHLF = OpenSim.subjectPartial('20120403AHLF');
            obj.x20120912AHRF = OpenSim.subjectFull('20120912AHRF');
%             obj.x20120922AHRM = OpenSim.subjectFull('20120922AHRM');
            obj.x20121008AHRM = OpenSim.subjectFull('20121008AHRM');
            obj.x20121108AHRM = OpenSim.subjectFull('20121108AHRM');
            obj.x20121110AHRM = OpenSim.subjectFull('20121110AHRM');
            obj.x20130401AHLM = OpenSim.subjectFull('20130401AHLM');            
        end
    end
    
end
