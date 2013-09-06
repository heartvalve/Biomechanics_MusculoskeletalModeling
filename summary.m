classdef summary < handle
    % SUMMARY - A class to store all OpenSim data.
    %
    %
    
    % Created by Megan Schroeder
    % Last Modified 2013-09-05
    
    
    %% Properties
    % Properties for the summary class
    
    properties (SetAccess = private)
        Control
        HamstringACL
        PatellaACL
    end
    
    
    %% Methods
    % Methods for the summary class
    
    methods
        function obj = summary()
            % SUMMARY - Construct instance of class
            %
            
            % Time
            tic;
            % Add groups as properties
            obj.Control = OpenSim.controlGroup();
            obj.HamstringACL = OpenSim.hamstringGroup();
            obj.PatellaACL = OpenSim.patellaGroup();
            % Elapsed time
            eTime = toc;
            disp(['Elapsed summary processing time is ',num2str(floor(eTime/60)),' minutes and ',num2str(round(mod(eTime,60))),' seconds.']);
        end
    end
    
end
