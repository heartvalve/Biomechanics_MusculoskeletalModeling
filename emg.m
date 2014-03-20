classdef emg < handle
    % EMG - A class to store muscle activation data recorded from experiments
    %
    %
    
    % Created by Megan Schroeder
    % Last Modified 2014-03-19
    
    
    %% Properties
    % Properties for the emg class
    
    properties (SetAccess = private)
        SampleTime
        Data
    end
    properties (SetAccess = public)
        Norm            % Normalized to % of cycle (added in 'simulation' class)
    end
    
    
    %% Methods
    % Methods for the emg class
    
    methods
        function obj = emg(subID,simName)
            % EMG - Construct instance of class
            %
            
            % EMG path
            emgPath = [OpenSim.getSubjectDir(subID),subID,'_',simName,'_EMG.mot'];
            % Import the file
            motimport = importdata(emgPath,'\t',7);
            % Column headers
            emgnames = motimport.colheaders(2:end);
            % Time
            timedata = motimport.data(:,1);
            obj.SampleTime = timedata;
            % Data
            emgdataset = dataset({motimport.data(:,2:end),emgnames{:}});
            obj.Data = emgdataset;
        end
    end
    
end
            