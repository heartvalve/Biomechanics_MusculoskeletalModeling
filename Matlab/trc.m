classdef trc < handle
    % TRC - A class to store marker data used in OpenSim.
    %
    %
    
    % Created by Megan Schroeder
    % Last Modified 2014-01-13
    
    
    %% Properties
    % Properties for the trc class
    
    properties (SetAccess = private)
        FrameNum
        FrameTime
        X
        Y
        Z
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
            obj.FrameNum = trcimport.data(:,1);
            % Time
            obj.FrameTime = trcimport.data(:,2);
            % Position
            obj.X = dataset({trcimport.data(:,3:3:end),markernames{:}});
            obj.Y = dataset({trcimport.data(:,4:3:end),markernames{:}});
            obj.Z = dataset({trcimport.data(:,5:3:end),markernames{:}});
        end    
    end
    
end
