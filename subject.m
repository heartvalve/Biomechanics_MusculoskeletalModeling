classdef subject < handle
    % SUBJECT - A class to store all modeling simulations for a subject.
    %
    %
    
    % Created by Megan Schroeder
    % Last Modified 2014-04-01
    
    
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
        ScaleFactor     % Mass of subject in kg (from personal information file) / Mass of generic model (75.337 kg)
    end
    
    
    %% Methods
    % Methods for the subject class
    
    methods
        % *****************************************************************
        %       Constructor Method
        % *****************************************************************
        function obj = subject(subID,varargin)
            % SUBJECT - Construct instance of class
            %
            
            % Check input (for reading CMC states)
            if nargin == 2
                readCMCstate = true;
            else
                readCMCstate = false;
            end
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
                tempData{i} = OpenSim.simulation(subID,simNames{i},readCMCstate);                
            end
            % Assign properties
            for i = 1:length(simNames)
                obj.(simNames{i}) = tempData{i};
            end
            % ---------------
            % Scale factor for subject
            xmlFile = [obj.SubDir,filesep,obj.SubID,'__PersonalInformation.xml'];
            domNode = xmlread(xmlFile);
            mNodeList = domNode.getElementsByTagName('mass');
            mass = str2double(char(mNodeList.item(0).getFirstChild.getData));
            obj.ScaleFactor = mass/75.337;
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
                    % Activations
                    if readCMCstate
                        cstruct.(cycleName).Activations = obj.(sims{i}).CMC.NormActivations;
                    end
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
                    % Experimental Knee
                    cstruct.(cycleName).ExpKnee = obj.(sims{i}).KIN.Norm;
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
                    if readCMCstate
                        % Activations
                        oldAct = cstruct.(cycleName).Activations;
                        newAct = obj.(sims{i}).CMC.NormActivations;
                        actprops = newAct.Properties.VarNames;
                        for m = 1:length(actprops)
                            newAct.(actprops{m}) = [oldAct.(actprops{m}) newAct.(actprops{m})];
                        end
                        cstruct.(cycleName).Activations = newAct;
                    end
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
                    % Experimental Knee
                    oldKnee = cstruct.(cycleName).ExpKnee;
                    newKnee = obj.(sims{i}).KIN.Norm;
                    kProps = newKnee.Properties.VarNames;
                    for m = 1:length(kProps)
                        newKnee.(kProps{m}) = [oldKnee.(kProps{m}) newKnee.(kProps{m})];
                    end
                    cstruct.(cycleName).ExpKnee = newKnee;
                end
            end
            % Convert structure to dataset
            nrows = length(fieldnames(cstruct));
            if readCMCstate
                varnames = {'Simulations','EMG','Activations','Forces','Residuals','Reserves','PosErrors','ExpKnee'};
            else
                varnames = {'Simulations','EMG','Forces','Residuals','Reserves','PosErrors','ExpKnee'};
            end
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
            if readCMCstate
                varnames = {'EMG','Activations','Forces','Residuals','Reserves','PosErrors','ExpKnee'};
            else
                varnames = {'EMG','Forces','Residuals','Reserves','PosErrors','ExpKnee'};
            end            
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
                if readCMCstate
                    % Activations
                    adataset{i,'Activations'} = OpenSim.getDatasetMean(obsnames{i},cdataset{i,'Activations'},2);
                    sdataset{i,'Activations'} = OpenSim.getDatasetStdDev(obsnames{i},cdataset{i,'Activations'});
                end
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
                % Experimental Knee
                adataset{i,'ExpKnee'} = OpenSim.getDatasetMean(obsnames{i},cdataset{i,'ExpKnee'},2);
                sdataset{i,'ExpKnee'} = OpenSim.getDatasetStdDev(obsnames{i},cdataset{i,'ExpKnee'});
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
        function plotEMGvsCMC(obj,varargin)
            % PLOTEMGVSCMC
            %
            
            % Parse inputs
            p = inputParser;
            checkObj = @(x) isa(x,'OpenSim.subject');
            validCycles = {'A_Walk','A_SD2S'};
            defaultCycle = 'A_Walk';
            checkCycle = @(x) any(validatestring(x,validCycles));
            defaultFigHandle = figure('NumberTitle','off','Visible','off');
            defaultAxesHandles = axes('Parent',defaultFigHandle);
            p.addRequired('obj',checkObj);            
            p.addOptional('Cycle',defaultCycle,checkCycle);
            p.addOptional('fig_handle',defaultFigHandle);
            p.addOptional('axes_handles',defaultAxesHandles);
            p.parse(obj,varargin{:});
            % Muscle names
            mNames = {'Quadriceps','Hamstring','Gastrocnemius'};
            % Shortcut references to input arguments
            fig_handle = p.Results.fig_handle;
            if ~isempty(p.UsingDefaults)          
                set(fig_handle,'Name',[obj.SubID,'_',p.Results.Cycle,' - EMG vs CMC']);
                axes_handles = zeros(1,3);
                for k = 1:3
                    axes_handles(k) = subplot(1,3,k);
                end
            else
                axes_handles = p.Results.axes_handles;
            end                       
            % Plot
            figure(fig_handle);
            for j = 1:length(mNames)
                set(fig_handle,'CurrentAxes',axes_handles(j));
                XplotEMGvsCMC(obj,p.Results.Cycle,mNames{j});
            end
            % -------------------------------------------------------------
            %   Subfunction
            % -------------------------------------------------------------
            function XplotEMGvsCMC(obj,Cycle,mName)
                % XPLOTEMGVSCMC
                %
               
                % Muscles
                if strcmp(mName,'Quadriceps')
                    cmcNames = {'vasmed','vaslat'};
                    emgNames = {'VastusMedialis','VastusLateralis'};                    
                elseif strcmp(mName,'Hamstring')
                    cmcNames = {'semiten','bflh'};       
                    emgNames = {'MedialHam','LateralHam'};                                 
                elseif strcmp(mName,'Gastrocnemius')
                    cmcNames = {'gasmed','gaslat'};
                    emgNames = {'MedialGast','LateralGast'};                    
                end
                % CMC activtiy
                cmcMeanAll = zeros(101,length(cmcNames));
                cmcSdAll = zeros(101,length(cmcNames));
                for m = 1:length(cmcNames)
                    cmcMeanAll(:,m) = obj.Summary.Mean{Cycle,'Activations'}.(cmcNames{m});
                    cmcSdAll(:,m) = obj.Summary.StdDev{Cycle,'Activations'}.(cmcNames{m});
                end
                cmcMean = mean(cmcMeanAll,2);
                cmcSD = mean(cmcSdAll,2);
% %                 sims = properties(obj);
% %                 cycleSims = sims(strncmp(sims,Cycle,length(Cycle)));                
% %                 cmcMeanAll = zeros(101,length(cmcNames));
% % %                 cmcSdAll = zeros(101,length(cmcNames));
% %                 for m = 1:length(cmcNames)
% %                     tempCMC = zeros(101,length(cycleSims));
% %                     for c = 1:length(cycleSims)
% %                         tempCMC(:,c) = obj.(cycleSims{c}).CMC.NormActivations.(cmcNames{m});
% %                     end
% %                     meanCMC = nanmean(tempCMC,2);
% % %                     sdCMC = nanstd(tempCMC,0,2);
% %                     cmcMeanAll(:,m) = meanCMC;
% % %                     cmcSdAll(:,m) = sdCMC;
% %                 end
% %                 cmcMean = nanmean(cmcMeanAll,2);
% %                 xi = (0:100)';
% %                 cmcMean = interp1(xi(~isnan(cmcMean)),cmcMean(~isnan(cmcMean)),xi,'spline');
% %                 cmcMean(cmcMean<0) = 0;
% % %                 cmcSD = nanmean(cmcSdAll,2);
                % EMG activity
                emgMeanAll = zeros(101,length(emgNames));
                emgSdAll = zeros(101,length(emgNames));
                for m = 1:length(emgNames)
                    emgMeanAll(:,m) = obj.Summary.Mean{Cycle,'EMG'}.(emgNames{m});
                    emgSdAll(:,m) = obj.Summary.StdDev{Cycle,'EMG'}.(emgNames{m});
                end
                emgMean = mean(emgMeanAll,2);
                emgSD = mean(emgSdAll,2);
                % ----------------------
                % Plot
                x = (0:100)';
                plot(x,cmcMean,'Color',[0.15 0.15 0.15],'LineWidth',3); hold on;                
                % Plot EMG (+/- Standard Deviation for cycle)
                plusSD = emgMean+emgSD;
                minusSD = emgMean-emgSD;
                minusSD(minusSD < 0) = 0;
                xx = [x' fliplr(x')];
                yy = [plusSD' fliplr(minusSD')];
                hFill = fill(xx,yy,[0.15 0.15 0.15]);
                set(hFill,'EdgeColor','none');
                alpha(0.25);              
                % Reverse children order (so mean is on top and shaded region is in back)
                set(gca,'Children',flipud(get(gca,'Children')));
                % Axes properties
                set(gca,'box','off');
                % Set axes limits
                xlim([0 100]);
                ylim([0 1.05]);
                % Labels
                title(mName,'FontWeight','bold');
                xlabel('% Stance');
                if strcmp(mName,'Quadriceps')
                    ylabel('Norm Activity');   
                end
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
        % *****************************************************************
        %       Export for Abaqus
        % *****************************************************************
        function exportAbaqus(obj)
            % EXPORTABAQUS
            %
            
            % Parse inputs
            p = inputParser;
            checkObj = @(x) isa(x,'OpenSim.subject');
            p.addRequired('obj',checkObj);
            p.parse(obj);
            % Specify export folder path
            wpath = regexp(obj.SubDir,'Northwestern-RIC','split');
            ABQdir = [wpath{1},'Northwestern-RIC',filesep,'Modeling',filesep,'Abaqus',...
                         filesep,'Subjects',filesep,obj.SubID,filesep];
%             ABQdir = [wpath{1},'Northwestern-RIC',filesep,'SVN',filesep,'Working',...
%                       filesep,'FiniteElement',filesep,'Subjects',filesep,obj.SubID,filesep];
            % Create the folder if not already there
            if ~isdir(ABQdir)
                mkdir(ABQdir(1:end-1));
                export = true;
            else
                % Check if the file exists
                if ~exist([ABQdir,obj.SubID,'_Walk.inp'],'file')
                    export = true;
                else
                    choice = questdlg(['Would you like to overwrite the existing files for ',obj.SubID,'?'],'Overwrite','Yes','No','No');
                    if strcmp(choice,'Yes')
                        export = true;
                    else
                        disp(['Skipping export for ',obj.SubID]);
                        export = false;
                    end                    
                end
            end
            if export
                cycleNames = {'Walk','SD2S'};
                for c = 1:2
                    % Open file
                    fid = fopen([ABQdir,obj.SubID,'_',cycleNames{c},'.inp'],'w');
                    % Write common elements
                    fprintf(fid,['*Heading\n',...
                                 obj.SubID,'_',cycleNames{c},'\n',...
                                '*Preprint, echo=NO, model=NO, history=NO, contact=NO\n',...
                                '**\n',...
                                '*Parameter\n',...
                                'time_step = 0.2\n',...
                                '**\n',...
                                '*Include, input=../../GenericFiles/Parts.inp\n',...
                                '*Include, input=../../GenericFiles/Assembly__Instances.inp\n',...
                                '*Include, input=../../GenericFiles/Assembly__Connectors.inp\n',...
                                '*Include, input=../../GenericFiles/Assembly__Constraints.inp\n',...
                                '*Include, input=../../GenericFiles/Model.inp\n',...
                                '**\n',...
                                '** MATERIALS\n',...
                                '**\n',...
                                '*Material, name=ACL\n',...
                                '*Density\n',...
                                '1e-09,\n',...
                                '*User Material, constants=8\n',...
                                '0.5, 0.01, 2.0, 12.4, 1., 0., 0., 1.\n',...
                                '**\n',...
                                '** AMPLITUDES\n',...
                                '**\n']);
                    % Write amplitudes
                    time_step = 0.2;
                    time = (time_step:(time_step/20):6*time_step)';                    
                    % -----------------------------------------------------
                    %   Boundary Conditions
                    % -----------------------------------------------------
                    % Flexion (local coordinate system)                    
                    fprintf(fid,'*Amplitude, name=FLEXION, time=TOTAL TIME, definition=SMOOTH STEP\n');
                    outFormat = '%4.2f, %9.6f, ';
                    fprintf(fid,outFormat,[0 0]);
                    flexion = -1*(pi/180)*double(obj.Summary.Mean{['A_',cycleNames{c}],'ExpKnee'}.RX);
                    timeflex = reshape([time'; flexion'],1,[]);
                    fprintf(fid,outFormat,timeflex(1:6));
                    fprintf(fid,'\n');
                    iAmp = (7:8:202)';
                    for n = 1:(length(iAmp)-1)
                        fprintf(fid,outFormat,timeflex(iAmp(n):(iAmp(n)+7)));
                        fprintf(fid,'\n');                            
                    end
                    lastLine = sprintf(outFormat,timeflex(iAmp(end):202));
                    lastLine = [lastLine(1:end-2),'\n'];
                    fprintf(fid,lastLine);
                    % -----------------------------------------------------
                    %   Loading Conditions
                    % -----------------------------------------------------
                    % Muscles
                    mNames = obj.Summary.Mean.Forces{1}.Properties.VarNames;
                    for i = 1:length(mNames)
                        mName = mNames{i};
                        if strncmp(mName,'vas',3)
                            ampNames = {['VASTUS',upper(mName(4:end))]};
                        elseif strcmp(mName,'recfem')
                            ampNames = {'RECTUSFEM'};
                        elseif strncmp(mName,'bf',2)
                            ampNames = {['BICEPSFEMORIS',upper(mName(3:4))]};
                        elseif strcmp(mName,'semimem')
                            ampNames = {'SEMIMEMBRANOSUS'};
                        elseif strcmp(mName,'semiten')
                            ampNames = {'SEMITENDINOSUS'};
                        elseif strncmp(mName,'gas',3)
                            ampNames = {[upper(mName(4)),'GASTROCNEMIUS']};
                        end
                        for k = 1:length(ampNames)
                            fprintf(fid,['*Amplitude, name=',ampNames{k},', time=TOTAL TIME, definition=SMOOTH STEP\n']);
                            outFormat = '%4.2f, %7.2f, ';
                            fprintf(fid,outFormat,[0 0]);
                            normMusAmp = obj.Summary.Mean{['A_',cycleNames{c}],'Forces'}.(mName);
                            musAmp = normMusAmp*obj.ScaleFactor*obj.MaxIsometric.(mName);
                            timeM = reshape([time'; musAmp'],1,[]);
                            fprintf(fid,outFormat,timeM(1:6));
                            fprintf(fid,'\n');
                            iAmp = (7:8:202)';
                            for n = 1:(length(iAmp)-1)
                                fprintf(fid,outFormat,timeM(iAmp(n):(iAmp(n)+7)));
                                fprintf(fid,'\n');                            
                            end
                            lastLine = sprintf(outFormat,timeM(iAmp(end):202));
                            lastLine = [lastLine(1:end-2),'\n'];
                            fprintf(fid,lastLine);
                        end
                    end
                    % Forces and moments at knee due to GRF (local coordinate system); use followers
                    % (disregard MX because flexion angle is prescribed)
                    % Experimental Sign Conventions:     Abaqus Model Sign Conventions:                    
                    %   FX: Lateral +                      FX: Lateral +
                    %   FY: Anterior +                     FY: Anterior + 
                    %   FZ: Up +                           FZ: Up +
                    %   MX: Flexion +          !~~~!       MX: Extension +
                    %   MY: Adduction +                    MY: Adduction +
                    %   MZ: External +         !~~~!       MZ: Internal +                      
                    grfNames = {'KNEEJC_FX','KNEEJC_FY','KNEEJC_FZ','KNEEJC_MX','KNEEJC_MY','KNEEJC_MZ'};
                    for k = 1:length(grfNames)
                        if ~strcmp(grfNames{k},'KNEEJC_MX')
                            fprintf(fid,['*Amplitude, name=',grfNames{k},', time=TOTAL TIME, definition=SMOOTH STEP\n']);
                            if regexp(grfNames{k},'KNEEJC_F[XYZ]')
                                outFormat = '%4.2f, %7.2f, ';
                            elseif regexp(grfNames{k},'KNEEJC_M[XYZ]')
                                outFormat = '%4.2f, %9.2f, ';
                            end
                            fprintf(fid,outFormat,[0 0]);
                            % Forces, in Newtons
                            if regexp(grfNames{k},'KNEEJC_F[XYZ]')
                                GRF = obj.Summary.Mean{['A_',cycleNames{c}],'ExpKnee'}.(['F',grfNames{k}(end)]);
                            % Moments, in Newton-millimeters
                            elseif regexp(grfNames{k},'KNEEJC_M[XYZ]')                       
                                GRF = 1000*obj.Summary.Mean{['A_',cycleNames{c}],'ExpKnee'}.(['M',grfNames{k}(end)]);                                   
                                if regexp(grfNames{k},'KNEEJC_M[XZ]')
                                    GRF = -1*GRF;
                                end
                            end
                            timeGRF = reshape([time'; GRF'],1,[]);
                            fprintf(fid,outFormat,timeGRF(1:6));
                            fprintf(fid,'\n');
                            iAmp = (7:8:202)';
                            for n = 1:(length(iAmp)-1)
                                fprintf(fid,outFormat,timeGRF(iAmp(n):(iAmp(n)+7)));
                                fprintf(fid,'\n');                            
                            end
                            lastLine = sprintf(outFormat,timeGRF(iAmp(end):202));
                            lastLine = [lastLine(1:end-2),'\n'];
                            fprintf(fid,lastLine);
                        end
                    end
                    % Final common elements
                    fprintf(fid,['**\n',...
                                 '*Include, input=../../GenericFiles/History.inp\n']);                
                    % Close file
                    fclose(fid); 
                end
            end            
        end
    end
    
end
