classdef group < handle
    % GROUP - A class to store all subjects (and simulations) for a specific population group.
    %
    %
    
    % Created by Megan Schroeder
    % Last Modified 2014-01-13
    
    
    %% Properties
    % Properties for the group class
    
    properties (SetAccess = private)
        Cycles      % Individual subject cycles
        Summary     % Summary of subjects
    end
    
    
    %% Methods
    % Methods for the group class
    
    methods
        % *****************************************************************
        %       Constructor Method
        % *****************************************************************
        function obj = group()
            % GROUP - Construct instance of class
            %
            
            % Properties of current group subclass
            allProps = properties(obj);
            if length(allProps) > 2
                subjects = allProps(1:end-2);
                % Assign subjects as properties
                for i = 1:length(subjects)
                    obj.(subjects{i}) = OpenSim.subject(subjects{i}(2:end));
                end
            else
                error('*** Cannot create instance of GROUP superclass directly.')
            end
            % -------------------------------------------------------------
            %       Cycles
            % -------------------------------------------------------------
%             cstruct = struct();
%             cycleNames = {'A_SD2F','A_SD2S','A_Walk','U_SD2F','U_SD2S','U_Walk'};
%             % Loop through subjects
%             for j = 1:length(subjects)
%                 % Loop through cycles
%                 for k = 1:length(cycleNames)
%                     % Loop through simulations based on that cycle
%                     for m = 1:5
%                         % Check if field exists (if not, create)
%                         if ~isfield(cstruct,cycleNames{k})
%                             cstruct.(cycleNames{k}) = struct();
%                             % Muscle forces (normalized)
%                             mNames = obj.(subjects{j}).MaxIsometric.Properties.VarNames;
%                             for p = 1:length(mNames)
%                                 cstruct.(cycleNames{k}).MuscleForces.(mNames{p}) = obj.(subjects{j}).([cycleNames{k},'_0',num2str(m)]).NormMuscleForces.(mNames{p});
%                             end
%                             % Subject / type name
%                             cstruct.(cycleNames{k}).Subjects = {[subjects{j}(2:end),'_',cycleTypes{m}]}; % %%%%%%%
%                         % If field exists, append new to existing
%                         else
%                             % Muscle forces
%                             oldM = cstruct.(cycleNames{k}).muscleForces;
%                             newM = obj.(subjects{j}).([cycleNames{k},'_',cycleTypes{m}]).normMuscleForces;
%                             mNames = newM.Properties.VarNames;
%                             for p = 1:length(mNames)
%                                 newM.(mNames{p}) = [oldM.(mNames{p}) newM.(mNames{p})];
%                             end
%                             cstruct.(cycleNames{k}).muscleForces = newM;
%                             % Subject / type names
%                             oldNames = cstruct.(cycleNames{k}).subjects;
%                             newName = {[subjects{j}(2:end),'_',cycleTypes{m}]};
%                             cstruct.(cycleNames{k}).subjects = [oldNames; newName];
%                         end
%                     end
%                 end
%             end
%             % Convert structure to dataset
%             varnames = {'subjects','muscleForces'};
%             obsnames = fieldnames(cstruct);
%             cdata = cell(length(obsnames),length(varnames));
%             cdataset = dataset({cdata,varnames{:}});
%             for i = 1:length(obsnames)
%                 for j = 1:length(varnames)
%                     cdataset{i,j} = cstruct.(obsnames{i}).(varnames{j});
%                 end
%             end
%             cdataset = set(cdataset,'ObsNames',obsnames);
%             % Assign property
%             obj.Cycles = cdataset;
%             % -------------------------------------------------------------
%             %       Summary
%             % -------------------------------------------------------------
%             % Set up struct
%             sumStruct = struct();
%             varnames = {'muscleForces'};
%             obsnames = get(cdataset,'ObsNames');
%             % Averages and standard deviations
%             adata = cell(length(obsnames),length(varnames));
%             sdata = cell(length(obsnames),length(varnames));
%             adataset = dataset({adata,varnames{:}});
%             sdataset = dataset({sdata,varnames{:}});
%             % Calculate
%             for i = 1:length(obsnames)
%                 adataset{i,'muscleForces'} = XgetDatasetMean(cdataset{i,'muscleForces'});
%                 sdataset{i,'muscleForces'} = XgetDatasetStdDev(cdataset{i,'muscleForces'});
%             end
%             adataset = set(adataset,'ObsNames',obsnames);
%             sdataset = set(sdataset,'ObsNames',obsnames);
%             % Add to struct
%             sumStruct.mean = adataset;
%             sumStruct.stDev = sdataset;
%             % Assign property
%             obj.Summary = sumStruct;
            % -------------------------------------------------------------
            %       Subfunctions
            % -------------------------------------------------------------
            function dsMean = XgetDatasetMean(dSet)
            % XGETDATASETMEAN
            %

            dsnames = dSet.Properties.VarNames;
            newdata = zeros(size(dSet));
            for n = 1:length(dsnames)    
                newdata(:,n) = nanmean(dSet.(dsnames{n}),2);
            end
            dsMean = dataset({newdata,dsnames{:}});
            end
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            function dsStdDev = XgetDatasetStdDev(dSet)
                % XGETDATASETSTDEV
                %

                dsnames = dSet.Properties.VarNames;
                newdata = zeros(size(dSet));
                for n = 1:length(dsnames)    
                    newdata(:,n) = nanstd(dSet.(dsnames{n}),0,2);        
                end
                dsStdDev = dataset({newdata,dsnames{:}});
            end            
        end
        % *****************************************************************
        %       Plotting Methods
        % *****************************************************************
        function varargout = plotMuscleForces(obj,varargin)
            % PLOTMUSCLEFORCES - Compare involved leg vs. uninvolved leg (group mean +/- standard deviation) for a given cycle
            %
            
            % Parse inputs
            p = inputParser;
            checkObj = @(x) isa(x,'OpenSim.group');
            validCycles = {'Walk','SD2F','SD2S'};
            defaultCycle = 'Walk';
            checkCycle = @(x) any(validatestring(x,validCycles));
            groupProps = properties(obj);
            subProps = properties(obj.(groupProps{1}));
            simObj = obj.(groupProps{1}).(subProps{1});
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
                set(fig_handle,'Name',['Group Muscle Forces (',p.Results.muscle,') for ',p.Results.cycle,' Cycle - Uninvovled vs. Involved'],'Visible','on');
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
            % Legend
            lStruct = struct;
            axesH = get(axes_handles(1),'Children');
            lStruct.axesHandles = axesH(1:2);
            if isa(obj,'OpenSim.controlGroup')
                lStruct.names = {'Left'; 'Right'};
            else
                lStruct.names = {'Uninvovled'; 'ACLR'};
            end
            % Return (to GUI)
            if nargout == 1
                varargout{1} = lStruct;
            end
            % -------------------------------------------------------------
            %   Subfunction
            % -------------------------------------------------------------
            function XplotMuscleForces(obj,cycle,muscle)
                % XPLOTMUSCLEFORCES - Worker function to plot muscle forces for a specific cycle and muscle
                %
               
                % Percent cycle
                x = (0:100)';
                % Mean
                % Plot uninvolved leg (or left leg for controls)
                plot(x,obj.summary.mean{['U_',cycle],'muscleForces'}.(muscle),'Color',[0.4 0.2 0.6],'LineWidth',3); hold on;                
                % Plot ACLR leg (or right leg for controls)
                plot(x,obj.summary.mean{['A_',cycle],'muscleForces'}.(muscle),'Color',[0 0.65 0.3],'LineWidth',3);
                % Standard Deviation
                plusSDU = obj.summary.mean{['U_',cycle],'muscleForces'}.(muscle)+obj.summary.stDev{['U_',cycle],'muscleForces'}.(muscle);
                minusSDU = obj.summary.mean{['U_',cycle],'muscleForces'}.(muscle)-obj.summary.stDev{['U_',cycle],'muscleForces'}.(muscle);
                xx = [x' fliplr(x')];
                yy = [plusSDU' fliplr(minusSDU')];
                hFill = fill(xx,yy,[0.4 0.2 0.6]); 
                set(hFill,'EdgeColor','none');
                alpha(0.25);
                plusSDA = obj.summary.mean{['A_',cycle],'muscleForces'}.(muscle)+obj.summary.stDev{['A_',cycle],'muscleForces'}.(muscle);
                minusSDA = obj.summary.mean{['A_',cycle],'muscleForces'}.(muscle)-obj.summary.stDev{['A_',cycle],'muscleForces'}.(muscle);
                xx = [x' fliplr(x')];
                yy = [plusSDA' fliplr(minusSDA')];
                hFill = fill(xx,yy,[0 0.65 0.3]);
                set(hFill,'EdgeColor','none');
                alpha(0.25);                
                % Reverse children order (so mean is on top and shaded region is in back)
                set(gca,'Children',flipud(get(gca,'Children')));
                % Axes properties
                set(gca,'box','off');
                % Set axes limits
                xlim([0 100]);
                ydefault = get(gca,'YLim');
                ylim([0 ydefault(2)]);
                % Labels
                title(upper(muscle),'FontWeight','bold');
                xlabel({'% Cycle',''});
                ylabel('% Max Isometric Force');
            end
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function varargout = troubleshootMuscleForces(obj,varargin)
            % TROUBLESHOOTMUSCLEFORCES - Compare individual subjects to the group mean for a leg-specific cycle
            %
            
            % Parse inputs
            p = inputParser;
            checkObj = @(x) isa(x,'OpenSim.group');
            validCycles = {'A_Walk','A_SD2F','A_SD2S','U_Walk','U_SD2F','U_SD2S'};
            defaultCycle = 'A_Walk';
            checkCycle = @(x) any(validatestring(x,validCycles));
            groupProps = properties(obj);
            subProps = properties(obj.(groupProps{1}));
            simObj = obj.(groupProps{1}).(subProps{1});
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
                set(fig_handle,'Name',['Group Muscle Forces (',p.Results.muscle,') for ',p.Results.cycle],'Visible','on');
                [axes_handles,mNames] = OpenSim.getAxesAndMuscles(simObj,p.Results.muscle);
            else
                axes_handles = p.Results.axes_handles;
                [~,mNames] = OpenSim.getAxesAndMuscles(simObj,p.Results.muscle);
            end
            % Plot
            figure(fig_handle);
            for j = 1:length(mNames)
                set(fig_handle,'CurrentAxes',axes_handles(j));
                XtroubleshootMuscleForces(obj,p.Results.cycle,mNames{j});
            end
            % Legend
            lStruct = struct;
            axesH = get(axes_handles(1),'Children');
            lStruct.axesHandles = axesH(1:end-1);
            lStruct.names = ['Mean'; obj.cycles{p.Results.cycle,'subjects'}];           
            % Return (to GUI)
            if nargout == 1
                varargout{1} = lStruct;
            end
            % -------------------------------------------------------------
            %   Subfunction
            % -------------------------------------------------------------
            function XtroubleshootMuscleForces(obj,cycle,muscle)
                % XTROUBLESHOOTMUSCLEFORCES - Worker function to plot muscle forces (mean and individual traces) for a leg-specific cycle and muscle
                %
               
                % Percent cycle
                x = (0:100)';
                % Mean
                plot(x,obj.summary.mean{cycle,'muscleForces'}.(muscle),'Color','k','LineWidth',3); hold on;                
                % Individual subjects
                numSubjects = length(obj.cycles{cycle,'subjects'});
                if numSubjects >= 8
                    set(gca,'ColorOrder',colormap(hsv(8)));
                else                        
                    set(gca,'ColorOrder',colormap(hsv(numSubjects)));
                end
                set(gca,'LineStyleOrder',{'-','--',':'});
                plot(x,obj.cycles{cycle,'muscleForces'}.(muscle),'LineWidth',1);
                % Standard Deviation
                plusSD = obj.summary.mean{cycle,'muscleForces'}.(muscle)+obj.summary.stDev{cycle,'muscleForces'}.(muscle);
                minusSD = obj.summary.mean{cycle,'muscleForces'}.(muscle)-obj.summary.stDev{cycle,'muscleForces'}.(muscle);
                % Plot as transparent shaded area
                xx = [x' fliplr(x')];
                yy = [plusSD' fliplr(minusSD')];
                hFill = fill(xx,yy,[0 0 0]); 
                set(hFill,'EdgeColor','none');
                alpha(0.125);
                % Reverse children order (so mean is on top and individual cycles are in back)
                set(gca,'Children',flipud(get(gca,'Children')));
                % Axes properties
                set(gca,'box','off');
                % Set axes limits
                xlim([0 100]);
                ydefault = get(gca,'YLim');
                ylim([0 ydefault(2)]);
                % Labels
                title(upper(muscle),'FontWeight','bold');
                xlabel({'% Cycle',''});
                ylabel('% Max Isometric Force');
            end            
        end
    end
    
end
