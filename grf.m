classdef grf < handle
    % GRF - A class to store ground reaction force data used in OpenSim.
    %
    %
    
    % Created by Megan Schroeder
    % Last Modified 2014-01-13
    
    
    %% Properties
    % Properties for the grf class
    
    properties (SetAccess = private)
        CycleFrames
        CycleSamples
        CycleTime
        SampleTime
        Data
    end
    
    
    %% Methods
    % Methods for the grf class
    
    methods
        function obj = grf(subID,simName)
            % GRF - Construct instance of class
            %
            
            % GRF path
            grfPath = [OpenSim.getSubjectDir(subID),subID,'_',simName,'_GRF.mot'];
            % Import the file
            motimport = importdata(grfPath,'\t',14);
            % Cycle frames
            cycleFrameLine = regexp(motimport.textdata{9,1},'\t','split');
            obj.CycleFrames = [str2double(cycleFrameLine{2}) str2double(cycleFrameLine{3})];
            % Cycle samples
            cycleSampleLine = regexp(motimport.textdata{10,1},'\t','split');
            obj.CycleSamples = [str2double(cycleSampleLine{2}) str2double(cycleSampleLine{3})];
            % Cycle time
            cycleTimeLine = regexp(motimport.textdata{11,1},'\t','split');
            obj.CycleTime = [str2double(cycleTimeLine{2}) str2double(cycleTimeLine{3})];
            % Column headers
            grfnames = upper(motimport.colheaders(2:end));
            grfnames = regexprep(grfnames,{'GROUND_FORCE([LR])_V([XYZ])','GROUND_FORCE([LR])_P([XYZ])','GROUND_TORQUE([LR])_([XYZ])'},{'$1F$2','$1C$2','$1M$2'});                
            % Time
            timedata = motimport.data(:,1);
            obj.SampleTime = timedata;
            % Data
            grfdataset = dataset({motimport.data(:,2:end),grfnames{:}});                
            % Replace zeros with NaN in COP (X and Z)
            cols = {'RCX','RCY','RCZ'};
            zeroind = grfdataset.RCX == 0;
            for i = 1:length(cols)
                grfdataset.(cols{i})(zeroind) = NaN;
            end
            cols = {'LCX','LCY','LCZ'};
            zeroind = grfdataset.LCX == 0;
            for i = 1:length(cols)
                grfdataset.(cols{i})(zeroind) = NaN;
            end
            obj.Data = grfdataset;            
        end        
    end
    
end
