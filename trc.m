classdef trc < handle
    % TRC - A class to store marker data used in OpenSim.
    %
    %
    
    % Created by Megan Schroeder
    % Last Modified 2013-09-05
    
    
    %% Properties
    % Properties for the trc class
    
    properties (SetAccess = private)
        frameNum
        frameTime
        x
        y
        z
    end
    
    
    %% Methods
    % Methods for the trc class
    
    methods
        function obj = trc(subID,simName)
            % TRC - Construct instance of class
            %
            
            % TRC path
            trcPath = [OpenSim.getSubjectDir(subID),subID,'_',simName,'.trc'];
            % Import the file
            trcimport = importdata(trcPath,'\t',5);
            % Marker names
            line4 = regexp(trcimport.textdata{4,1},'\t','split');
            markernames = cell(1,round((size(line4,2)-2)/3));
            p = 1;
            for q = 3:3:(size(line4,2)-1)
                markernames{p} = regexprep(line4{q},{'\.','\W'},'');
                p = p+1;
            end
            % Frame numbers
            obj.frameNum = trcimport.data(:,1);
            % Time
            obj.frameTime = trcimport.data(:,2);
            % Position
            obj.x = dataset({trcimport.data(:,3:3:end),markernames{:}});
            obj.y = dataset({trcimport.data(:,4:3:end),markernames{:}});
            obj.z = dataset({trcimport.data(:,5:3:end),markernames{:}});
        end    
    end
    
end
