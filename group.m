classdef group < handle
    % GROUP - A class to store all subjects (and simulations) for a specific population group
    %
    %
    
    % Created by Megan Schroeder
    % Last Modified 2014-03-28
    
    
    %% Properties
    % Properties for the group class
    
    properties (SetAccess = private)
        Cycles      % Individual subject cycles
        Summary     % Summary of subjects
        Statistics  % Paired t-test statistics results (involved vs. uninvolved leg)
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
            % Subject properties
            subjects = allProps(strncmp(allProps,'x',1));
            % Preallocate and do a parallel loop
            tempData = cell(length(subjects),1);
            parfor j = 1:length(subjects)
                % Subject class
                subjectClass = str2func(['OpenSim.',subjects{j}]);
                % Create subject object
                tempData{j} = subjectClass();                    
            end
            % Assign subjects as properties
            for i = 1:length(subjects)
                obj.(subjects{i}) = tempData{i};
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
                        cstruct.(cycleNames{k}).Forces = obj.(subjects{j}).Cycles.Forces{k};
                        % Subject average forces
                        cstruct.(cycleNames{k}).AvgForces = obj.(subjects{j}).Summary.Mean.Forces{k};
                        % Simulation / type name
                        cstruct.(cycleNames{k}).Simulations = arrayfun(@(x) char(strcat(obj.(subjects{j}).SubID,'_',x)), ...
                                                              obj.(subjects{j}).Cycles.Simulations{k},'UniformOutput',false);
                        % Weights (based on number of simulations)
                        cstruct.(cycleNames{k}).Weights = repmat(5/length(obj.(subjects{j}).Cycles.Simulations{k}),length(obj.(subjects{j}).Cycles.Simulations{k}),1);
                        % Subjects
                        cstruct.(cycleNames{k}).Subjects = {obj.(subjects{j}).SubID};
                        % Residuals
                        cstruct.(cycleNames{k}).Residuals = obj.(subjects{j}).Summary.Mean.Residuals{k};
                        % Reserves
                        cstruct.(cycleNames{k}).Reserves = obj.(subjects{j}).Summary.Mean.Reserves{k};
                        % Position Errors
                        cstruct.(cycleNames{k}).PosErrors = obj.(subjects{j}).Summary.Mean.PosErrors{k};
                    % If field exists, append new to existing
                    else
                        % Muscle forces
                        oldM = cstruct.(cycleNames{k}).Forces;
                        newM = obj.(subjects{j}).Cycles.Forces{k};
                        mNames = newM.Properties.VarNames;
                        for m = 1:length(mNames)
                            newM.(mNames{m}) = [oldM.(mNames{m}) newM.(mNames{m})];
                        end
                        cstruct.(cycleNames{k}).Forces = newM;
                        % Subject average forces
                        oldM = cstruct.(cycleNames{k}).AvgForces;
                        newM = obj.(subjects{j}).Summary.Mean.Forces{k};
                        mNames = newM.Properties.VarNames;
                        for m = 1:length(mNames)
                            newM.(mNames{m}) = [oldM.(mNames{m}) newM.(mNames{m})];
                        end
                        cstruct.(cycleNames{k}).AvgForces = newM;
                        % Simulation / type names
                        oldNames = cstruct.(cycleNames{k}).Simulations;
                        newNames = arrayfun(@(x) char(strcat(obj.(subjects{j}).SubID,'_',x)), ...
                                   obj.(subjects{j}).Cycles.Simulations{k},'UniformOutput',false);
                        cstruct.(cycleNames{k}).Simulations = [oldNames; newNames];
                        % Weights
                        oldWeights = cstruct.(cycleNames{k}).Weights;
                        newWeights = repmat(5/length(obj.(subjects{j}).Cycles.Simulations{k}),length(obj.(subjects{j}).Cycles.Simulations{k}),1);
                        cstruct.(cycleNames{k}).Weights = [oldWeights; newWeights];
                        % Subjects
                        oldNames = cstruct.(cycleNames{k}).Subjects;
                        newName = {obj.(subjects{j}).SubID};
                        cstruct.(cycleNames{k}).Subjects = [oldNames; newName];
                        % Residuals
                        oldR = cstruct.(cycleNames{k}).Residuals;
                        newR = obj.(subjects{j}).Summary.Mean.Residuals{k};
                        rProps = newR.Properties.VarNames;
                        for m = 1:length(rProps)
                            newR.(rProps{m}) = [oldR.(rProps{m}) newR.(rProps{m})];
                        end
                        cstruct.(cycleNames{k}).Residuals = newR;
                        % Reserves
                        oldR = cstruct.(cycleNames{k}).Reserves;
                        newR = obj.(subjects{j}).Summary.Mean.Reserves{k};
                        rProps = newR.Properties.VarNames;
                        for m = 1:length(rProps)
                            newR.(rProps{m}) = [oldR.(rProps{m}) newR.(rProps{m})];
                        end
                        cstruct.(cycleNames{k}).Reserves = newR;                        
                        % PosErrors
                        oldP = cstruct.(cycleNames{k}).PosErrors;
                        newP = obj.(subjects{j}).Summary.Mean.PosErrors{k};
                        pProps = newP.Properties.VarNames;
                        for m = 1:length(pProps)
                            newP.(pProps{m}) = [oldP.(pProps{m}) newP.(pProps{m})];
                        end
                        cstruct.(cycleNames{k}).PosErrors = newP;  
                    end
                end
            end
            % Convert structure to dataset
            varnames = {'Simulations','Weights','Forces','Subjects','AvgForces','Residuals','Reserves','PosErrors'};
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
            varnames = {'Forces','AvgForces','Residuals','Reserves','PosErrors'};
            obsnames = get(cdataset,'ObsNames');
            resObsNames = {'Mean_RRA','Mean_CMC','RMS_RRA','RMS_CMC','Max_RRA','Max_CMC'};
            genObsNames = {'Mean','RMS','Max'};
            % Averages and standard deviations
            adata = cell(length(obsnames),length(varnames));
            sdata = cell(length(obsnames),length(varnames));
            adataset = dataset({adata,varnames{:}});
            sdataset = dataset({sdata,varnames{:}});
            % Calculate
            for i = 1:length(obsnames)
                adataset{i,'Forces'} = OpenSim.getDatasetMean(obsnames{i},cdataset{i,'Forces'},2,cdataset{i,'Weights'});
                sdataset{i,'Forces'} = OpenSim.getDatasetStdDev(obsnames{i},cdataset{i,'Forces'},cdataset{i,'Weights'});
                adataset{i,'AvgForces'} = OpenSim.getDatasetMean(obsnames{i},cdataset{i,'AvgForces'},2);
                sdataset{i,'AvgForces'} = OpenSim.getDatasetStdDev(obsnames{i},cdataset{i,'AvgForces'});
                adataset{i,'Residuals'} = set(OpenSim.getDatasetMean(obsnames{i},cdataset{i,'Residuals'},2),'ObsNames',resObsNames);
                sdataset{i,'Residuals'} = set(OpenSim.getDatasetStdDev(obsnames{i},cdataset{i,'Residuals'}),'ObsNames',resObsNames);
                adataset{i,'Reserves'} = set(OpenSim.getDatasetMean(obsnames{i},cdataset{i,'Reserves'},2),'ObsNames',genObsNames);
                sdataset{i,'Reserves'} = set(OpenSim.getDatasetStdDev(obsnames{i},cdataset{i,'Reserves'}),'ObsNames',genObsNames);
                adataset{i,'PosErrors'} = set(OpenSim.getDatasetMean(obsnames{i},cdataset{i,'PosErrors'},2),'ObsNames',genObsNames);
                sdataset{i,'PosErrors'} = set(OpenSim.getDatasetStdDev(obsnames{i},cdataset{i,'PosErrors'}),'ObsNames',genObsNames);
            end
            adataset = set(adataset,'ObsNames',obsnames);
            sdataset = set(sdataset,'ObsNames',obsnames);
            % Add to struct
            sumStruct.Mean = adataset;
            sumStruct.StdDev = sdataset;
            % Assign property
            obj.Summary = sumStruct;
            % -------------------------------------------------------------
            %       Statistics
            % -------------------------------------------------------------          
            cycleTypes = {'Walk','SD2F','SD2S'};
            varnames = {'Forces'};
            hdata = cell(length(cycleTypes),length(varnames));
            hdataset = dataset({hdata,varnames{:}});
            for i = 1:length(cycleTypes)
                % Subject Average Forces
                hdataset{i,'Forces'} = XrunPairedTTest(cdataset{['A_',cycleTypes{i}],'AvgForces'},cdataset{['U_',cycleTypes{i}],'AvgForces'},'Forces');                               
            end
            % Add to struct
            hdataset = set(hdataset,'ObsNames',cycleTypes);
            % Assign Property
            obj.Statistics = hdataset;
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
            p.addOptional('Cycle',defaultCycle,checkCycle);
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
            % Legend
            if strcmp(p.Results.Muscle,'All')
                OpenSim.createLegend(fig_handle,axes_handles(1));
            end
            % -------------------------------------------------------------
            %   Subfunction
            % -------------------------------------------------------------
            function XplotMuscleForces(obj,Cycle,Muscle)
                % XPLOTMUSCLEFORCES - Worker function to plot muscle forces for a specific cycle and muscle
                %
               
                ColorA = [1 0 0.6];
                ColorU = [0 0.5 1];
                % Plot
                % X vector
                x = (0:100)';
                % Mean
                % Plot uninvolved leg (or left leg for controls)
                h = plot(x,obj.Summary.Mean{['U_',Cycle],'Forces'}.(Muscle),'Color',ColorU,'LineWidth',3); hold on;
                if strcmp(obj.GroupID,'Control')
                    set(h,'DisplayName','Left');
                else
                    set(h,'DisplayName','Uninvolved');
                end
                % Plot ACLR leg (or right leg for controls)
                h = plot(x,obj.Summary.Mean{['A_',Cycle],'Forces'}.(Muscle),'Color',ColorA,'LineWidth',3);
                if strcmp(obj.GroupID,'Control')
                    set(h,'DisplayName','Right');
                else
                    set(h,'DisplayName','ACLR');
                end
                % Standard Deviation
                plusSDU = obj.Summary.Mean{['U_',Cycle],'Forces'}.(Muscle)+obj.Summary.StdDev{['U_',Cycle],'Forces'}.(Muscle);
                minusSDU = obj.Summary.Mean{['U_',Cycle],'Forces'}.(Muscle)-obj.Summary.StdDev{['U_',Cycle],'Forces'}.(Muscle);
                xx = [x' fliplr(x')];
                yy = [plusSDU' fliplr(minusSDU')];
                hFill = fill(xx,yy,ColorU); 
                set(hFill,'EdgeColor','none');
                alpha(0.25);
                plusSDA = obj.Summary.Mean{['A_',Cycle],'Forces'}.(Muscle)+obj.Summary.StdDev{['A_',Cycle],'Forces'}.(Muscle);
                minusSDA = obj.Summary.Mean{['A_',Cycle],'Forces'}.(Muscle)-obj.Summary.StdDev{['A_',Cycle],'Forces'}.(Muscle);
                xx = [x' fliplr(x')];
                yy = [plusSDA' fliplr(minusSDA')];
                hFill = fill(xx,yy,ColorA);
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
                ylabel('Force (N/Fmax)');
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
                set(fig_handle,'Name',['Group Muscle Forces (',p.Results.Muscle,') for ',p.Results.Cycle],'Visible','on');
                [axes_handles,mNames] = OpenSim.getAxesAndMuscles(simObj,p.Results.Muscle);
            else
                axes_handles = p.Results.axes_handles;
                [~,mNames] = OpenSim.getAxesAndMuscles(simObj,p.Results.Muscle);
            end
            % Plot
            figure(fig_handle);
            for j = 1:length(mNames)
                set(fig_handle,'CurrentAxes',axes_handles(j));
                Xtroubleshoot(obj,p.Results.Cycle,mNames{j});
            end
            % Legend
            if strcmp(p.Results.Muscle,'All')
                OpenSim.createLegend(fig_handle,axes_handles(1));
            end
            % -------------------------------------------------------------
            %   Subfunction
            % -------------------------------------------------------------
            function Xtroubleshoot(obj,Cycle,Muscle)
                % XTROUBLESHOOTMUSCLEFORCES - Worker function to plot muscle forces (mean and individual traces) for a leg-specific cycle and muscle
                %
               
                % Percent cycle
                x = (0:100)';
                % Mean
                h = plot(x,obj.Summary.Mean{Cycle,'Forces'}.(Muscle),'Color',[0.15,0.15,0.15],'LineWidth',3); hold on;
                set(h,'DisplayName','Mean');
                % Individual subjects
                % Colors
                subColors = colormap(hsv(length(obj.Cycles{Cycle,'Subjects'})));
                colors = zeros(length(obj.Cycles{Cycle,'Simulations'}),3);
                subs = obj.Cycles{Cycle,'Subjects'};
                sims = obj.Cycles{Cycle,'Simulations'};
                for i = 1:length(subs)
                    cLogical = strncmp(subs{i},sims,12);
                    colors(cLogical,:) = ones(sum(cLogical),1)*subColors(i,:);                    
                end                
                % Individual Subjects
                for i = 1:length(obj.Cycles{Cycle,'Simulations'})
                    h = plot(x,obj.Cycles{Cycle,'Forces'}.(Muscle)(:,i),'Color',colors(i,:),'LineWidth',1);
                    set(h,'DisplayName',regexprep(obj.Cycles{Cycle,'Simulations'}{i},'_','-'));
                end
                % Axes properties
                set(gca,'box','off');
                % Set axes limits
                xlim([0 100]);
                ydefault = get(gca,'YLim');
                ylim([0 ydefault(2)]);
                % Labels
                title(upper(Muscle),'FontWeight','bold');
                xlabel({'% Cycle',''});
                ylabel('Force (N/Fmax)');
            end            
        end
    end
    
end


%% Subfunctions
% Subfunctions called from the main class definition

function dsH = XrunPairedTTest(dSet1,dSet2,varType)
    % XRUNPAIREDTTEST
    %
    
    dsnames = dSet1.Properties.VarNames;
    newdata = NaN(size(dSet1));
    for j = 1:length(dsnames)
        newdata(:,j) = (ttest(dSet1.(dsnames{j})',dSet2.(dsnames{j})'))';
        % Eliminate areas where forces are small
        if strcmp(varType,'Forces')
            newdata((((nanmean(dSet1.(dsnames{j}),2) < 0.025) & (nanmean(dSet2.(dsnames{j}),2) < 0.025)) | ...
                      (abs(nanmean(dSet1.(dsnames{j}),2)-nanmean(dSet2.(dsnames{j}),2)) < 0.01)),j) = 0;
        end
    end
    % Return
    dsH = dataset({newdata,dsnames{:}});
end
