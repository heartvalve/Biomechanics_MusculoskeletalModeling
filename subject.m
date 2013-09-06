classdef subject < handle
    % SUBJECT - A class to store all modeling simulations for a subject.
    %
    %
    
    % Created by Megan Schroeder
    % Last Modified 2013-09-05
    
    
    %% Properties
    % Properties for the subject class
    
    properties (SetAccess = private)
        subID   % Subject ID        
    end
    properties (Hidden = true, SetAccess = private)
        subDir  % Directory where files are stored
    end
    
    
    %% Methods
    % Methods for the subject class
    
    methods
        % *****************************************************************
        %       Constructor Method
        % *****************************************************************
        function obj = subject(subID)
            % SUBJECT - Construct instance of class
            %
            
            % Subject ID
            obj.subID = subID;
            % Subject directory
            obj.subDir = OpenSim.getSubjectDir(subID);
            % Identify subclass properties (simulation names)
            allProps = properties(obj);
            simNames = allProps(1:end-1);
            % Preallocate and do a parallel loop
            tempData = cell(length(simNames),1);
            parfor i = 1:length(simNames)
                % Create simulation object
                tempData{i} = OpenSim.simulation(subID,simNames{i});                
            end
            % Assign properties
            for i = 1:length(simNames)
                obj.(simNames{i}) = tempData{i};
            end
        end
        % *****************************************************************
        %       Plotting Methods
        % *****************************************************************
        function plotMuscleForces(obj,varargin)
            % PLOTMUSCLEFORCES
            %
            
            % Parse inputs
            p = inputParser;
            checkObj = @(x) isa(x,'OpenSim.subject');            
            validCycles = {'Walk','SD2F','SD2S'};
            defaultCycle = 'Walk';
            checkCycle = @(x) any(validatestring(x,validCycles));
            validMuscles = [obj.A_Walk_RepGRF.muscles,{'All','Quads','Hamstrings','Gastrocs'}];
            defaultMuscle = 'All';
            checkMuscle = @(x) any(validatestring(x,validMuscles));
            defaultFigHandle = figure('NumberTitle','off','Visible','off');
            defaultAxesHandles = axes('Parent',defaultFigHandle);
            p.addRequired('obj',checkObj);            
            p.addOptional('cycle',defaultCycle,checkCycle)            
            p.addOptional('muscle',defaultMuscle,checkMuscle);
            p.addOptional('fig_handle',defaultFigHandle);
            p.addOptional('axes_handles',defaultAxesHandles);
            p.parse(obj,varargin{:});
            % Shortcut references to input arguments
            fig_handle = p.Results.fig_handle;
            simObj = obj.(['A_',p.Results.cycle,'_RepGRF']); % temporary variable
            if ~isempty(p.UsingDefaults)          
                set(fig_handle,'Name',['Muscle Forces - ',p.Results.muscle],'Visible','on');
                [axes_handles,mNames] = OpenSim.getAxesAndMuscles(simObj,p.Results.muscle);
            else
                axes_handles = p.Results.axes_handles;
                [~,mNames] = OpenSim.getAxesAndMuscles(simObj,p.Results.muscle);
            end
            % Plot
            figure(fig_handle);
            for j = 1:length(mNames)
                set(fig_handle,'CurrentAxes',axes_handles(j));
                XplotMuscleForces(obj,p.Results.cycle,mNames{j});
            end
            if strcmp(p.Results.muscle,'All')
                set(fig_handle,'CurrentAxes',subplot(3,4,11:12));
                set(gca,'Visible','off');
            end

            
% % %             % Defaults & error checking
% % %             if nargin == 1
% % %                 allCycles = {'Walk','SD2F','SD2S'};
% % %                 [s,~] = listdlg('PromptString','Please select a cycle to plot:', ...
% % %                                 'SelectionMode','single', ...
% % %                                 'ListString',allCycles, ...
% % %                                 'ListSize',[160 160]);
% % %                 cycle = allCycles{s};
% % %                 muscle = 'All';
% % %             elseif nargin == 2
% % %                 if ~max(strcmp(cycle,{'Walk','SD2F','SD2S'}))
% % %                     error('*** Argument must be a valid cycle name (Walk, SD2F, SD2S)');
% % %                 end
% % %                 muscle = 'All';
% % %             elseif nargin == 3
% % %                 if ~max(strcmp(cycle,{'Walk','SD2F','SD2S'}))
% % %                     error('*** Argument must be a valid cycle name (Walk, SD2F, SD2S)');
% % %                 end
% % %                 simObj = obj.(['A_',cycle,'_RepGRF']);
% % %                 if ~max(strcmp(muscle,simObj.muscles)) && ...
% % %                    ~max(strcmp(muscle,{'All','Quads','Hamstrings','Gastrocs'}))
% % %                     error('*** Argument must be a valid muscle name or group (All, Quads, Hamstrings, Gastrocs)');
% % %                 end
% % %             end
% % %             % Set up figure and axes handles; get individual muscle names
% % %             if nargin ~= 5
% % %                fig_handle = figure('Name',[cycle,' - Muscle Forces - ',muscle],'NumberTitle','off');
% % %                [axes_handles,mNames] = OpenSim.getAxesAndMuscles(obj,muscle);
% % %             else
% % %                 [~,mNames] = OpenSim.getAxesAndMuscles(obj,muscle);
% % %             end
            % -------------------------------------------------------------
            %   Subfunction
            % -------------------------------------------------------------
            function XplotMuscleForces(obj,cycle,muscle)
                % XPLOTMUSCLEFORCES
                %
               
                % Plot uninvolved leg (or left leg for controls)
                plot((0:100)',obj.(['U_',cycle,'_RepGRF']).muscleForces.(muscle),'Color','b','LineWidth',2,'LineStyle','-'); hold on;
                plot((0:100)',obj.(['U_',cycle,'_RepKIN']).muscleForces.(muscle),'Color','b','LineWidth',2,'LineStyle','--');
                % Plot ACLR leg (or right leg for controls)
                plot((0:100)',obj.(['A_',cycle,'_RepGRF']).muscleForces.(muscle),'Color','g','LineWidth',2,'LineStyle','-');
                plot((0:100)',obj.(['A_',cycle,'_RepKIN']).muscleForces.(muscle),'Color','g','LineWidth',2,'LineStyle','--');
                % Axes properties
                set(gca,'box','off');
                % Set axes limits
                xlim([0 100]);
                ydefault = get(gca,'YLim');
                ylim([0 ydefault(2)]);
                % Labels
                title(upper(muscle),'FontWeight','bold');
                xlabel({'% Cycle',''});
                ylabel('Muscle Force (N)');
            end
        end
    end
    
end
