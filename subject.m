classdef subject < handle
    % SUBJECT - A class to store all modeling simulations for a subject.
    %
    %
    
    % Created by Megan Schroeder
    % Last Modified 2014-03-20
    
    
    %% Properties
    % Properties for the subject class
    
    properties (SetAccess = protected)
        Cycles          % Cycles (individual trials)
        Summary         % Subject summary (mean, standard deviation)
    end
    properties (Hidden = true, SetAccess = protected)
        SubID           % Subject ID
        SubDir          % Directory where files are stored
        MaxIsometric    % Maximum isometric muscle forces
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
            obj.SubID = subID;
            % Subject directory
            obj.SubDir = OpenSim.getSubjectDir(subID);            
            % Identify simulation names
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
            % ---------------
            % Isometric muscle forces            
            muscles = obj.(simNames{1}).Muscles;
            muscleLegs = cell(size(muscles));
            for i = 1:length(muscles)
                muscleLegs{i} = [muscles{i},'_r'];
            end
            maxForces = cell(1,length(muscles));
            maxForces = dataset({maxForces,muscles{:}});
            % Parse xml
            modelFile = [obj.SubDir,filesep,obj.SubID,'.osim'];
            domNode = xmlread(modelFile);
            maxIsoNodeList = domNode.getElementsByTagName('max_isometric_force');
            for i = 1:maxIsoNodeList.getLength
                if any(strcmp(maxIsoNodeList.item(i-1).getParentNode.getAttribute('name'),muscleLegs))
                    musc = char(maxIsoNodeList.item(i-1).getParentNode.getAttribute('name'));
                    maxForces.(musc(1:end-2)) = str2double(char(maxIsoNodeList.item(i-1).getFirstChild.getData));
                end
            end
            obj.MaxIsometric = maxForces;            
            % ----------------------
            % Add normalized muscle forces property to individual simulations
            % Based on maximum isometric force & scale factor
            for i = 1:length(simNames)
                for j = 1:length(muscles)
                    obj.(simNames{i}).NormMuscleForces.(muscles{j}) = ...
                        obj.(simNames{i}).MuscleForces.(muscles{j})./(obj.MaxIsometric.(muscles{j}).*obj.(simNames{i}).ScaleFactor);
                end
            end
            % -------------------------------------------------------------
            %       Cycles
            % -------------------------------------------------------------
            sims = properties(obj);
            checkSim = @(x) isa(obj.(x{1}),'OpenSim.simulation');
            sims(~arrayfun(checkSim,sims)) = [];
            cstruct = struct();            
            % Loop through all simulations
            for i = 1:length(sims)
                cycleName = sims{i}(1:end-3);
                if ~isfield(cstruct,cycleName)
                    % Create field
                    cstruct.(cycleName) = struct();
                    % EMG
                    cstruct.(cycleName).EMG = obj.(sims{i}).EMG.Norm;
                    % Muscle Forces (normalized)
                    cstruct.(cycleName).Forces = obj.(sims{i}).NormMuscleForces;
                    % Residuals
                    cstruct.(cycleName).Residuals = obj.(sims{i}).Residuals;
                    % Reserves
                    cstruct.(cycleName).Reserves = obj.(sims{i}).Reserves;
                    % Position Errors
                    cstruct.(cycleName).PosErrors = obj.(sims{i}).PosErrors;
                    % Simulation Name
                    cstruct.(cycleName).Simulations = {sims{i}};
                % If the fieldname already exists, need to append existing to new
                else
                    % EMG
                    oldEMG = cstruct.(cycleName).EMG;
                    newEMG = obj.(sims{i}).EMG.Norm;
                    emgprops = newEMG.Properties.VarNames;
                    for m = 1:length(emgprops)
                        newEMG.(emgprops{m}) = [oldEMG.(emgprops{m}) newEMG.(emgprops{m})];
                    end
                    cstruct.(cycleName).EMG = newEMG;
                    % Muscle Forces
                    oldForces = cstruct.(cycleName).Forces;
                    newForces = obj.(sims{i}).NormMuscleForces;
                    forceprops = newForces.Properties.VarNames;
                    for m = 1:length(forceprops)
                        newForces.(forceprops{m}) = [oldForces.(forceprops{m}) newForces.(forceprops{m})];
                    end
                    cstruct.(cycleName).Forces = newForces;
                    % Residuals
                    oldResiduals = cstruct.(cycleName).Residuals;
                    newResiduals = obj.(sims{i}).Residuals;
                    resProps = newResiduals.Properties.VarNames;
                    for m = 1:length(resProps)
                        newResiduals.(resProps{m}) = [oldResiduals.(resProps{m}) newResiduals.(resProps{m})];
                    end
                    cstruct.(cycleName).Residuals = newResiduals;
                    % Reserves
                    oldReserves = cstruct.(cycleName).Reserves;
                    newReserves = obj.(sims{i}).Reserves;
                    resProps = newReserves.Properties.VarNames;
                    for m = 1:length(resProps)
                        newReserves.(resProps{m}) = [oldReserves.(resProps{m}) newReserves.(resProps{m})];
                    end
                    cstruct.(cycleName).Reserves = newReserves;
                    % Position Errors
                    oldPosErrors = cstruct.(cycleName).PosErrors;
                    newPosErrors = obj.(sims{i}).PosErrors;
                    posProps = newPosErrors.Properties.VarNames;
                    for m = 1:length(posProps)
                        newPosErrors.(posProps{m}) = [oldPosErrors.(posProps{m}) newPosErrors.(posProps{m})];
                    end
                    cstruct.(cycleName).PosErrors = newPosErrors;
                    % Simulation Name
                    oldNames = cstruct.(cycleName).Simulations;
                    cstruct.(cycleName).Simulations = [oldNames; {sims{i}}];
                end
            end
            % Convert structure to dataset
            nrows = length(fieldnames(cstruct));
            varnames = {'Simulations','EMG','Forces','Residuals','Reserves','PosErrors'};
            cdata = cell(nrows,length(varnames));
            cdataset = dataset({cdata,varnames{:}});
            obsnames = fieldnames(cstruct);
            for i = 1:length(obsnames)
                for j = 1:length(varnames)
                    cdataset{i,j} = cstruct.(obsnames{i}).(varnames{j});
                end
            end           
            cdataset = set(cdataset,'ObsNames',obsnames);
            % Assign Property
            obj.Cycles = cdataset;
            % -------------------------------------------------------------
            %       Averages & Standard Deviation
            % -------------------------------------------------------------
            % Set up struct
            sumStruct = struct();
            varnames = {'EMG','Forces','Residuals','Reserves','PosErrors'};
            obsnames = get(cdataset,'ObsNames');
            resObsNames = {'Mean_RRA','Mean_CMC','RMS_RRA','RMS_CMC','Max_RRA','Max_CMC'};
            genObsNames = {'Mean','RMS','Max'};
            nrows = size(cdataset,1);
            adata = cell(nrows,length(varnames));
            sdata = cell(nrows,length(varnames));
            adataset = dataset({adata,varnames{:}});
            sdataset = dataset({sdata,varnames{:}});
            % Calculate averages
            for i = 1:length(obsnames)
                % EMG
                adataset{i,'EMG'} = OpenSim.getDatasetMean(obsnames{i},cdataset{i,'EMG'},2);
                sdataset{i,'EMG'} = OpenSim.getDatasetStdDev(obsnames{i},cdataset{i,'EMG'});
                % Forces
                adataset{i,'Forces'} = OpenSim.getDatasetMean(obsnames{i},cdataset{i,'Forces'},2);
                sdataset{i,'Forces'} = OpenSim.getDatasetStdDev(obsnames{i},cdataset{i,'Forces'});
                % Residuals
                adataset{i,'Residuals'} = set(OpenSim.getDatasetMean(obsnames{i},cdataset{i,'Residuals'},2),'ObsNames',resObsNames);
                sdataset{i,'Residuals'} = set(OpenSim.getDatasetStdDev(obsnames{i},cdataset{i,'Residuals'}),'ObsNames',resObsNames);
                % Reserves
                adataset{i,'Reserves'} = set(OpenSim.getDatasetMean(obsnames{i},cdataset{i,'Reserves'},2),'ObsNames',genObsNames);
                sdataset{i,'Reserves'} = set(OpenSim.getDatasetStdDev(obsnames{i},cdataset{i,'Reserves'}),'ObsNames',genObsNames);
                % Position Errors
                adataset{i,'PosErrors'} = set(OpenSim.getDatasetMean(obsnames{i},cdataset{i,'PosErrors'},2),'ObsNames',genObsNames);
                sdataset{i,'PosErrors'} = set(OpenSim.getDatasetStdDev(obsnames{i},cdataset{i,'PosErrors'}),'ObsNames',genObsNames);
            end
            adataset = set(adataset,'ObsNames',obsnames);
            sdataset = set(sdataset,'ObsNames',obsnames);
            % Add to struct
            sumStruct.Mean = adataset;
            sumStruct.StdDev = sdataset;    
            % Assign Property
            obj.Summary = sumStruct;            
        end
        % *****************************************************************
        %       Plotting Methods
        % *****************************************************************
        function plotMuscleForces(obj,varargin)
            % PLOTMUSCLEFORCES - Compare involved leg vs. uninvolved leg for a given cycle
            %
            
            % Parse inputs
            p = inputParser;
            checkObj = @(x) isa(x,'OpenSim.subject');
            validCycles = {'Walk','SD2F','SD2S'};
            defaultCycle = 'Walk';
            checkCycle = @(x) any(validatestring(x,validCycles));
            subProps = properties(obj);
            simObj = obj.(subProps{1});
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
                set(fig_handle,'Name',['Subject Muscle Forces (',p.Results.Muscle,') for ',p.Results.Cycle,' Cycle - Uninvovled vs. Involved'],'Visible','on');
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
                h = plot(x,obj.Summary.Mean{['U_',Cycle],'Forces'}.(Muscle),'Color',ColorU,'LineWidth',3); hold on;
                if strcmp(obj.SubID(9:11),'CON')
                    set(h,'DisplayName','Left');
                else
                    set(h,'DisplayName','Uninvolved');
                end
                h = plot(x,obj.Summary.Mean{['A_',Cycle],'Forces'}.(Muscle),'Color',ColorA,'LineWidth',3);
                if strcmp(obj.SubID(9:11),'CON')
                    set(h,'DisplayName','Right');
                else
                    set(h,'DisplayName','ACLR');
                end
                % Standard Deviation
                plusSDU = obj.Summary.Mean{['U_',Cycle],'Forces'}.(Muscle)+obj.Summary.StdDev{['U_',Cycle],'Forces'}.(Muscle);
                minusSDU = obj.Summary.Mean{['U_',Cycle],'Forces'}.(Muscle)-obj.Summary.StdDev{['U_',Cycle],'Forces'}.(Muscle);
                xx = [x' fliplr(x')];
                yy = [plusSDU' fliplr(minusSDU')];
                xx(isnan(yy)) = []; 
                yy(isnan(yy)) = [];
                hFill = fill(xx,yy,ColorU);
                set(hFill,'EdgeColor','none');
                alpha(0.25);
                plusSDA = obj.Summary.Mean{['A_',Cycle],'Forces'}.(Muscle)+obj.Summary.StdDev{['A_',Cycle],'Forces'}.(Muscle);
                minusSDA = obj.Summary.Mean{['A_',Cycle],'Forces'}.(Muscle)-obj.Summary.StdDev{['A_',Cycle],'Forces'}.(Muscle);
                xx = [x' fliplr(x')];
                yy = [plusSDA' fliplr(minusSDA')];
                xx(isnan(yy)) = []; 
                yy(isnan(yy)) = [];
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
                ylabel('% Max Isometric Force');
            end
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function plotMuscleForcesEMG(obj,varargin)
            % PLOTMUSCLEFORCESEMG
            %
            
            % Parse inputs
            p = inputParser;
            checkObj = @(x) isa(x,'OpenSim.subject');            
            validCycles = {'A_Walk','A_SD2F','A_SD2S','U_Walk','U_SD2F','U_SD2S'};
            defaultCycle = 'A_Walk';
            checkCycle = @(x) any(validatestring(x,validCycles));
            subProps = properties(obj);
            simObj = obj.(subProps{1});
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
                set(fig_handle,'Name',['Muscle Forces and EMG (',p.Results.Muscle,') for ',p.Results.Cycle],'Visible','on');
                [axes_handles,mNames,emgNames] = OpenSim.getAxesAndMuscles(simObj,p.Results.Muscle);
            else
                axes_handles = p.Results.axes_handles;
                [~,mNames,emgNames] = OpenSim.getAxesAndMuscles(simObj,p.Results.Muscle);
            end
            % Plot
            figure(fig_handle);
            for j = 1:length(mNames)
                set(fig_handle,'CurrentAxes',axes_handles(j));
                XplotMuscleForcesEMG(obj,p.Results.Cycle,mNames{j},emgNames{j});
            end
            % Legend
            if strcmp(p.Results.Muscle,'All')
                OpenSim.createLegend(fig_handle,axes_handles(1));
            end
            % -------------------------------------------------------------
            %   Subfunction
            % -------------------------------------------------------------
            function XplotMuscleForcesEMG(obj,Cycle,Muscle,EMG)
                % XPLOTMUSCLEFORCESEMG - Worker function to plot muscle forces and EMG for a specific cycle and muscle
                %
               
                ColorEMG = [0.5 0.5 0.5];
                ColorForce = [0 0 0];
                % Plot
                % X vector
                x = (0:100)';
                % Mean Force
                if ~strcmp(EMG,'')
                    [ax,hF,hE] = plotyy(x,obj.Summary.Mean{Cycle,'Forces'}.(Muscle),...
                                        x,obj.Summary.Mean{Cycle,'EMG'}.(EMG)); hold on;
                    set(hF,'Color',ColorForce,'LineWidth',3,'DisplayName','Force');
                    set(hE,'Color',ColorEMG,'LineWidth',3,'LineStyle','--','DisplayName','EMG');
                else
                    h = plot(x,obj.Summary.Mean{Cycle,'Forces'}.(Muscle),'Color',ColorForce,'LineWidth',3); hold on;
                    set(h,'DisplayName','Force');
                end
%                 % Standard Deviation EMG
%                 if ~strcmp(EMG,'')
%                     plusSD = obj.Summary.Mean{Cycle,'EMG'}.(EMG)+obj.Summary.StdDev{Cycle,'EMG'}.(EMG);
%                     minusSD = obj.Summary.Mean{Cycle,'EMG'}.(EMG)-obj.Summary.StdDev{Cycle,'EMG'}.(EMG);
%                     xx = [x' fliplr(x')];
%                     yy = [plusSD' fliplr(minusSD')];
%                     hFill = fill(xx,yy,ColorEMG);
%                     set(hFill,'EdgeColor','none');
%                     alpha(0.25);                    
%                 end
%                 % Standard Deviation Force
%                 plusSD = obj.Summary.Mean{Cycle,'Forces'}.(Muscle)+obj.Summary.StdDev{Cycle,'Forces'}.(Muscle);
%                 minusSD = obj.Summary.Mean{Cycle,'Forces'}.(Muscle)-obj.Summary.StdDev{Cycle,'Forces'}.(Muscle);
%                 xx = [x' fliplr(x')];
%                 yy = [plusSD' fliplr(minusSD')];
%                 hFill = fill(xx,yy,ColorForce);
%                 set(hFill,'EdgeColor','none');
%                 alpha(0.25);                
%                 % Reverse children order (so mean is on top and shaded region is in back)
%                 set(gca,'Children',flipud(get(gca,'Children')));
                % Axes properties
                set(gca,'box','off');
                % Set axes limits
                xlim([0 100]);
                ydefault = get(gca,'YLim');
                ylim([0 ydefault(2)]);
                % Labels
                title(upper(Muscle),'FontWeight','bold');
                xlabel({'% Cycle',''});
                ylabel('% Max');
            end
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function troubleshoot(obj,varargin)
            % TROUBLESHOOT - Plot mean and individual simulations for a given cycle
            %
            
            % Parse inputs
            p = inputParser;
            checkObj = @(x) isa(x,'OpenSim.subject');            
            validCycles = {'A_Walk','A_SD2F','A_SD2S','U_Walk','U_SD2F','U_SD2S'};
            defaultCycle = 'A_Walk';
            checkCycle = @(x) any(validatestring(x,validCycles));
            subProps = properties(obj);
            simObj = obj.(subProps{1});
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
                set(fig_handle,'Name',['Muscle Forces (',p.Results.Muscle,') for ',p.Results.Cycle],'Visible','on');
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
                % XTROUBLESHOOT
                %

                % X vector
                x = (0:100)';                
                % Mean
                h = plot(x,obj.Summary.Mean{Cycle,'Forces'}.(Muscle),'Color',[0.15,0.15,0.15],'LineWidth',3); hold on;
                set(h,'DisplayName','Mean');
                % Colors
                colors = colormap(hsv(5));
                % Individual Simulations
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
                ylabel('% Max Isometric Force');
            end
        end
    end
    
end
