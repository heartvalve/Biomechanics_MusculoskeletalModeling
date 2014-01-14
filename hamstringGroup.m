classdef hamstringGroup < OpenSim.group
    % HAMSTRINGGROUP - A class to store all hamstring tendon subjects.
    %
    %
    
    % Created by Megan Schroeder
    % Last Modified 2014-01-13
    
    
    %% Properties
    % Properties for the hamstringGroup class
    
    properties
        x20120912AHRF
        x20120922AHRM
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
            
            % Create instance of class from superclass
            obj = obj@OpenSim.group();
        end
    end
    
end
