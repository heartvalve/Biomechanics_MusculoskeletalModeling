classdef kin < handle
    % KIN - A class to store knee kinematics and kinetics from experiments
    %
    %   Everything is reported based on the Grood & Suntay joint coordinate
    %   system. Includes knee joint angles, and forces and moments
    %   calculated from inverse dynamics equations.
    %
    %   Conventions:
    %     RX, MX: Flexion(+) / Extension(-)
    %     RY, MY: Adduction(+) / Abduction(-)
    %     RZ, MZ: External(+) / Internal(-)
    %     FX:     Lateral(+) / Medial(-)
    %     FY:     Anterior(+) / Posterior(-)
    %     FZ:     Up(+) / Down(-)
    %
    
    % Created by Megan Schroeder
    % Last Modified 2014-03-19
    
    
    %% Properties
    % Properties for the kin class
    
    properties (SetAccess = private)
        FrameTime
        Data
    end
    properties (SetAccess = public)
        Norm            % Normalized to % of cycle (added in 'simulation' class)
    end
    
    
    %% Methods
    % Methods for the kin class
    
    methods
        function obj = kin(subID,simName)
            % KIN - Construct instance of class
            % 
            
            % KIN path 
            kinPath = [OpenSim.getSubjectDir(subID),subID,'_',simName,'_Knee.mot'];
            % Import the file
            kinimport = importdata(kinPath,'\t',7);
            % Column headers
            kinnames = kinimport.colheaders(2:end);
            % Time
            timedata = kinimport.data(:,1);
            obj.FrameTime = timedata;
            % Data
            kindataset = dataset({kinimport.data(:,2:end),kinnames{:}});
            obj.Data = kindataset;
        end
    end
    
end
