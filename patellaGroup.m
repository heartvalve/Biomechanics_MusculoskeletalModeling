classdef patellaGroup < OpenSim.group
    % PATELLAGROUP - A class to store all patella tendon subjects.
    %
    %
    
    % Created by Megan Schroeder
    % Last Modified 2013-09-06
    
    
    %% Properties
    % Properties for the patellaGroup class
    
    properties
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
            
            % Create instance of class from superclass
            obj = obj@OpenSim.group();
        end
    end
    
end
