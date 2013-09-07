classdef subject < handle
    % SUBJECT - A class to store all modeling simulations for a subject.
    %
    %
    
    % Created by Megan Schroeder
    % Last Modified 2013-09-06
    
    
    %% Properties
    % Properties for the subject class
    
    properties (SetAccess = private)
        subID           % Subject ID
        maxIsometric    % Maximum isometric muscle force
    end
    properties (Hidden = true, SetAccess = private)
        subDir          % Directory where files are stored
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
            simNames = allProps(1:end-2);
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
            % Isometric muscle forces            
            muscles = obj.(simNames{1}).muscles;
            muscleLegs = cell(size(muscles));
            for i = 1:length(muscles)
                muscleLegs{i} = [muscles{i},'_r'];
            end
            maxForces = cell(1,length(muscles));
            maxForces = dataset({maxForces,muscles{:}});
            % Parse xml
            modelFile = [obj.subDir,filesep,obj.subID,'.osim'];
            domNode = xmlread(modelFile);            
            maxIsoNodeList = domNode.getElementsByTagName('max_isometric_force');
            for i = 1:maxIsoNodeList.getLength
                if any(strcmp(maxIsoNodeList.item(i-1).getParentNode.getAttribute('name'),muscleLegs))
                    musc = char(maxIsoNodeList.item(i-1).getParentNode.getAttribute('name'));
                    maxForces.(musc(1:end-2)) = str2double(char(maxIsoNodeList.item(i-1).getFirstChild.getData));
                end
            end
            obj.maxIsometric = maxForces;
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
            subProps = properties(obj);
            simObj = obj.(subProps{1});
            validMuscles = [simObj.muscles,{'All','Quads','Hamstrings','Gastrocs'}];
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
            % -------------------------------------------------------------
            %   Subfunction
            % -------------------------------------------------------------
            function XplotMuscleForces(obj,cycle,muscle)
                % XPLOTMUSCLEFORCES
                %
               
                % Plot uninvolved leg (or left leg for controls)
                plot((0:100)',obj.(['U_',cycle,'_RepGRF']).muscleForces.(muscle),'Color',[0.4 0.2 0.6],'LineWidth',2,'LineStyle','-'); hold on;
                plot((0:100)',obj.(['U_',cycle,'_RepKIN']).muscleForces.(muscle),'Color',[0.4 0.2 0.6],'LineWidth',2,'LineStyle','--');
                % Plot ACLR leg (or right leg for controls)
                plot((0:100)',obj.(['A_',cycle,'_RepGRF']).muscleForces.(muscle),'Color',[0 0.65 0.3],'LineWidth',2,'LineStyle','-');
                plot((0:100)',obj.(['A_',cycle,'_RepKIN']).muscleForces.(muscle),'Color',[0 0.65 0.3],'LineWidth',2,'LineStyle','--');
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
