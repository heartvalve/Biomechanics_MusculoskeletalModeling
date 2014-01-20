classdef group < handle
    % GROUP - A class to store all subjects (and simulations) for a specific population group
    %
    %
    
    % Created by Megan Schroeder
    % Last Modified 2014-01-17
    
    
    %% Properties
    % Properties for the group class
    
    properties (SetAccess = private)
        Cycles      % Individual subject cycles
        Summary     % Summary of subjects
    end
    properties (Hidden = true, SetAccess = protected)
        GroupID     % Group type
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
                % Preallocate and do a parallel loop
                tempData = cell(length(subjects),1);
                parfor i = 1:length(subjects)
                    % Subject class
                    subjectClass = str2func(['OpenSim.',subjects{i}]);
                    % Create subject object
                    tempData{i} = subjectClass();                    
                end
                % Assign subjects as properties
                for i = 1:length(subjects)
                    obj.(subjects{i}) = tempData{i};
                end
            else
                error('*** Cannot create instance of GROUP superclass directly.')
            end
            % -------------------------------------------------------------
            %       Cycles
            % -------------------------------------------------------------
            cstruct = struct();
            % Loop through subjects
            for j = 1:length(subjects)
                cycleNames = get(obj.(subjects{i}).Cycles,'ObsNames');
                % Loop through cycles
                for k = 1:length(cycleNames)
                    % Check if field exists (if not, create)
                    if ~isfield(cstruct,cycleNames{k})
                        cstruct.(cycleNames{k}) = struct();
                        % Muscle forces
                        cstruct.(cycleNames{k}).Forces = obj.(subjects{j}).Summary.Mean.Forces{k};
                        % Subject / type name
                        cstruct.(cycleNames{k}).Subjects = subjects(j);
                    % If field exists, append new to existing
                    else
                        % Muscle forces
                        oldM = cstruct.(cycleNames{k}).Forces;
                        newM = obj.(subjects{j}).Summary.Mean.Forces{k};
                        mNames = newM.Properties.VarNames;
                        for m = 1:length(mNames)
                            newM.(mNames{m}) = [oldM.(mNames{m}) newM.(mNames{m})];
                        end
                        cstruct.(cycleNames{k}).muscleForces = newM;
                        % Subject / type names
                        oldNames = cstruct.(cycleNames{k}).Subjects;
                        newName = subjects(j);
                        cstruct.(cycleNames{k}).Subjects = [oldNames; newName];
                    end

                end
            end
            % Convert structure to dataset
            varnames = {'Subjects','Forces'};
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
            obj.Cycles = cdataset;
            % -------------------------------------------------------------
            %       Summary
            % -------------------------------------------------------------
            % Set up struct
            sumStruct = struct();
            varnames = {'Forces'};
            obsnames = get(cdataset,'ObsNames');
            % Averages and standard deviations
            adata = cell(length(obsnames),length(varnames));
            sdata = cell(length(obsnames),length(varnames));
            adataset = dataset({adata,varnames{:}});
            sdataset = dataset({sdata,varnames{:}});
            % Calculate
            for i = 1:length(obsnames)
                adataset{i,'Forces'} = OpenSim.getDatasetMean(obsnames{i},cdataset{i,'Forces'},2);
                sdataset{i,'Forces'} = OpenSim.getDatasetStdDev(obsnames{i},cdataset{i,'Forces'});
            end
            adataset = set(adataset,'ObsNames',obsnames);
            sdataset = set(sdataset,'ObsNames',obsnames);
            % Add to struct
            sumStruct.Mean = adataset;
            sumStruct.StdDev = sdataset;
            % Assign property
            obj.Summary = sumStruct;
        end
        % *****************************************************************
        %       Plotting Methods
        % *****************************************************************
        function plotMuscleForces(obj,varargin)
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
            validMuscles = [simObj.Muscles,{'All','Quads','Hamstrings','Gastrocs'}];
            defaultMuscle = 'All';
            checkMuscle = @(x) any(validatestring(x,validMuscles));
            defaultFigHandle = figure('NumberTitle','off','Visible','off');
            defaultAxesHandles = axes('Parent',defaultFigHandle);
            p.addRequired('obj',checkObj);            
            p.addOptional('Cycle',defaultCycle,checkCycle)            
            p.addOptional('Muscle',defaultMuscle,checkMuscle);
            p.addOptional('fig_handle',defaultFigHandle);
            p.addOptional('axes_handles',defaultAxesHandles);
            p.parse(obj,varargin{:});
            % Shortcut references to input arguments
            fig_handle = p.Results.fig_handle;
            if ~isempty(p.UsingDefaults)          
                set(fig_handle,'Name',['Group Muscle Forces (',p.Results.Muscle,') for ',p.Results.Cycle,' Cycle - Uninvovled vs. Involved'],'Visible','on');
                [axes_handles,mNames] = OpenSim.getAxesAndMuscles(simObj,p.Results.Muscle);
            else
                axes_handles = p.Results.axes_handles;
                [~,mNames] = OpenSim.getAxesAndMuscles(simObj,p.Results.Muscle);
            end
            % Plot
            figure(fig_handle);
            for j = 1:length(mNames)
                set(fig_handle,'CurrentAxes',axes_handles(j));
                XplotMuscleForces(obj,p.Results.Cycle,mNames{j});
            end           
            % -------------------------------------------------------------
            %   Subfunction
            % -------------------------------------------------------------
            function XplotMuscleForces(obj,Cycle,Muscle)
                % XPLOTMUSCLEFORCES - Worker function to plot muscle forces for a specific cycle and muscle
                %
               
                % Percent cycle
                x = (0:100)';
                % Mean
                % Plot uninvolved leg (or left leg for controls)
                plot(x,obj.Summary.Mean{['U_',Cycle],'Forces'}.(Muscle),'Color',[0.4 0.2 0.6],'LineWidth',3); hold on;                
                % Plot ACLR leg (or right leg for controls)
                plot(x,obj.Summary.Mean{['A_',Cycle],'Forces'}.(Muscle),'Color',[0 0.65 0.3],'LineWidth',3);
                % Standard Deviation
                plusSDU = obj.Summary.Mean{['U_',Cycle],'Forces'}.(Muscle)+obj.Summary.StdDev{['U_',Cycle],'Forces'}.(Muscle);
                minusSDU = obj.Summary.Mean{['U_',Cycle],'Forces'}.(Muscle)-obj.Summary.StdDev{['U_',Cycle],'Forces'}.(Muscle);
                xx = [x' fliplr(x')];
                yy = [plusSDU' fliplr(minusSDU')];
                hFill = fill(xx,yy,[0.4 0.2 0.6]); 
                set(hFill,'EdgeColor','none');
                alpha(0.25);
                plusSDA = obj.Summary.Mean{['A_',Cycle],'Forces'}.(Muscle)+obj.Summary.StdDev{['A_',Cycle],'Forces'}.(Muscle);
                minusSDA = obj.Summary.Mean{['A_',Cycle],'Forces'}.(Muscle)-obj.Summary.StdDev{['A_',Cycle],'Forces'}.(Muscle);
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
                title(upper(Muscle),'FontWeight','bold');
                xlabel({'% Cycle',''});
                ylabel('% Max Isometric Force');
            end
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function troubleshoot(obj,varargin)
            % TROUBLESHOOT - Compare individual subjects to the group mean for a leg-specific cycle
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
                Xtroubleshoot(obj,p.Results.cycle,mNames{j});
            end                   
            % -------------------------------------------------------------
            %   Subfunction
            % -------------------------------------------------------------
            function Xtroubleshoot(obj,cycle,muscle)
                % XTROUBLESHOOTMUSCLEFORCES - Worker function to plot muscle forces (mean and individual traces) for a leg-specific cycle and muscle
                %
               
                % Percent cycle
                x = (0:100)';
                % Mean
                plot(x,obj.Summary.Mean{cycle,'muscleForces'}.(muscle),'Color','k','LineWidth',3); hold on;                
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
                plusSD = obj.Summary.Mean{cycle,'muscleForces'}.(muscle)+obj.Summary.StdDev{cycle,'muscleForces'}.(muscle);
                minusSD = obj.Summary.Mean{cycle,'muscleForces'}.(muscle)-obj.Summary.StdDev{cycle,'muscleForces'}.(muscle);
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
