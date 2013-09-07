classdef group < handle
    % GROUP - A class to store all subjects (and simulations) for a specific population group.
    %
    %
    
    % Created by Megan Schroeder
    % Last Modified 2013-09-06
    
    
    %% Properties
    % Properties for the group class
    
    properties (SetAccess = private)
        cycles      % Individual subject cycles
        summary     % Summary of subjects
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
            
            % All subjects by type of simulation
            sPartial = {'x20110622CONM','x20110706APRF','x20110927CONM',...
                        'x20111025APRM','x20111130AHLM','x20120306AHRF',...
                        'x20120306CONF','x20120313AHLM','x20120403AHLF'};
            sFull = {'x20120912AHRF','x20120919APLF','x20120920APRM',...
                     'x20120922AHRM','x20121008AHRM','x20121108AHRM',...
                     'x20121110AHRM','x20121204APRM','x20121204CONF',...
                     'x20121205CONF','x20121205CONM','x20121206CONF',...                     
                     'x20130207APRM','x20130221CONF','x20130401AHLM',...
                     'x20130401CONM'};
            % Properties of current group subclass
            allProps = properties(obj);
            if length(allProps) > 2
                subjects = allProps(1:end-2);
                % Assign subjects as properties
                for i = 1:length(subjects)
                    if any(strcmp(subjects{i},sPartial))
                        obj.(subjects{i}) = OpenSim.subjectPartial(subjects{i}(2:end));
                    elseif any(strcmp(subjects{i},sFull))
                        obj.(subjects{i}) = OpenSim.subjectFull(subjects{i}(2:end));
                    end
                end
            else
                error('*** Cannot create instance of GROUP superclass directly.')
            end
            % -------------------------------------------------------------
            %       Cycles
            % -------------------------------------------------------------
            cstruct = struct();
%             cstruct = struct('A_SD2F',{},'A_SD2S',{},'A_Walk',{},...
%                              'U_SD2F',{},'U_SD2S',{},'U_Walk',{});
            cycleNames = {'A_SD2F','A_SD2S','A_Walk','U_SD2F','U_SD2S','U_Walk'};
            cycleTypes = {'RepGRF','RepKIN'};
            % Loop through subjects
            for j = 1:length(subjects)
                % Loop through cycles
                for k = 1:6
                    % Make sure the subject has the cycle
                    if any(strncmp(cycleNames{k},properties(obj.(subjects{j})),6))
                        % Loop through types of that cycle
                        for m = 1:2                        
                            % Check if field exists (if not, create)
                            if ~isfield(cstruct,cycleNames{k})
                                cstruct.(cycleNames{k}) = struct();
                                % Muscle forces
                                cstruct.(cycleNames{k}).muscleForces = obj.(subjects{j}).([cycleNames{k},'_',cycleTypes{m}]).muscleForces;
                                % Subject / type name
                                cstruct.(cycleNames{k}).subjects = {[subjects{j}(2:end),'_',cycleTypes{m}]};
                            % If field exists, append new to existing
                            else
                                % Muscle forces
                                oldM = cstruct.(cycleNames{k}).muscleForces;
                                newM = obj.(subjects{j}).([cycleNames{k},'_',cycleTypes{m}]).muscleForces;
                                mProps = newM.Properties.VarNames;
                                for p = 1:length(mProps)
                                    newM.(mProps{p}) = [oldM.(mProps{p}) newM.(mProps{p})];
                                end
                                cstruct.(cycleNames{k}).muscleForces = newM;
                                % Subject / type names
                                oldNames = cstruct.(cycleNames{k}).subjects;
                                newName = {[subjects{j}(2:end),'_',cycleTypes{m}]};
                                cstruct.(cycleNames{k}).subjects = [oldNames; newName];
                            end
                        end
                    end
                end
            end
            % Convert structure to dataset
            varnames = {'subjects','muscleForces'};
            obsnames = fieldnames(cstruct);
            cdata = cell(length(obsnames),length(varnames));
            cdataset = dataset({cdata,varnames{:}});
            for i = 1:length(obsnames)
                for j = 1:length(varnames)
                    cdataset{i,j} = cstruct.(obsnames{i}).(varnames{j});
                end
            end
            cdataset = set(cdataset,'ObsNames',obsnames);
            % Assign property
            obj.cycles = cdataset;
            % -------------------------------------------------------------
            %       Summary
            % -------------------------------------------------------------
            % Set up struct
            sumStruct = struct();
            varnames = {'muscleForces'};
            obsnames = get(cdataset,'ObsNames');
            % Averages and standard deviations
            adata = cell(length(obsnames),length(varnames));
            sdata = cell(length(obsnames),length(varnames));
            adataset = dataset({adata,varnames{:}});
            sdataset = dataset({sdata,varnames{:}});
            % Calculate
            for i = 1:length(obsnames)
                adataset{i,'muscleForces'} = XgetDatasetMean(cdataset{i,'muscleForces'});
                sdataset{i,'muscleForces'} = XgetDatasetStdDev(cdataset{i,'muscleForces'});
            end
            adataset = set(adataset,'ObsNames',obsnames);
            sdataset = set(sdataset,'ObsNames',obsnames);
            % Add to struct
            sumStruct.mean = adataset;
            sumStruct.stDev = sdataset;
            % Assign property
            obj.summary = sumStruct;
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
            % PLOTMUSCLEFORCES
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
                ylabel('Muscle Force (N)');
            end
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function varargout = troubleshootMuscleForces(obj,varargin)
            % TROUBLESHOOTMUSCLEFORCES
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
                XtroubleshootMuscleForces(obj,p.Results.cycle,mNames{j});
            end
            if strcmp(p.Results.muscle,'All')
                set(fig_handle,'CurrentAxes',subplot(3,4,11:12));
                set(gca,'Visible','off');
            end
            % Legend
            lStruct = struct;
            axesH = get(gca,'Children');
            lStruct.axesHandles = axesH(1:end-1);
%             lStruct.names = ['Mean'; GroupInst.Cycles{Cycle,'Subjects'}];           
            % Return (to GUI)
            if nargout == 1
                varargout{1} = lStruct;
            end
            % -------------------------------------------------------------
            %   Subfunction
            % -------------------------------------------------------------
            function XtroubleshootMuscleForces(obj,cycle,muscle)
                % XTROUBLESHOOTMUSCLEFORCES
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
                ylabel('Muscle Force (N)');
            end            
        end
    end
    
end
