classdef controlGroup < OpenSim.group
    % CONTROLGROUP - A class to store all control subjects.
    %
    %
    
    % Created by Megan Schroeder
    % Last Modified 2013-09-06
    
    
    %% Properties
    % Properties for the controlGroup class
    
    properties
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
            
            % Create instance of class from superclass
            obj = obj@OpenSim.group();
        end
    end
    
end
