classdef simulation < handle
    % SIMULATION - A class to store an OpenSim modeling simulation.
    %
    %
    
    % Created by Megan Schroeder
    % Last Modified 2014-03-28
    
    
    %% Properties
    % Properties for the simulation class
    
    properties (SetAccess = private)        
        SubID               % Subject ID
        SimName             % Simulation name
        EMG                 % EMG data from experiment (for comparison)
        KIN                 % Knee kinetics from Cortex (for comparison)
        TRC                 % Marker data - input to simulation
        GRF                 % Ground Reaction Force data - input to simulation
        IK                  % Inverse Kinematics solution
        ID                  % Inverse Dynamics solution
        RRA                 % Residual Reduction Algorithm solution
        CMC                 % Computed Muscle Control solution
        MuscleForces        % Muscle forces (summarized from CMC)
        Residuals           % Residuals (summarized from RRA & CMC)
        Reserves            % Reserves (summarized from CMC)
        PosErrors           % Position Errors (summarized from CMC)
    end
    properties (Hidden = true, SetAccess = private)
        SubDir              % Directory where files are stored
        Model               % Generic model
        Muscles             % Muscle names
        Leg                 % Cycle leg
        WeightN             % Weight of subject in Newtons
        Height              % Height of subject in meters
        ScaleFactor         % Sum of masses for subject / sum of masses for generic model
    end
    properties (Hidden = true)
        NormMuscleForces    % Normalized muscle forces
    end
    
    
    %% Methods
    % Methods for the simulation class
    
    methods
        % *****************************************************************
        %       Constructor Method
        % *****************************************************************
        function obj = simulation(subID,simName)
            % SIMULATION - Construct instance of class
            %
            
            % Subject ID
            obj.SubID = subID;
            % Simulation name (without subject ID)
            obj.SimName = simName;
            % Subject directory
            obj.SubDir = OpenSim.getSubjectDir(subID);
            % Generic model name from Setup Scale XML
            modelNameFile = dir(fullfile(obj.SubDir,'*Setup_Scale.xml'));
            domNode = xmlread([obj.SubDir,modelNameFile.name]);
            modelFullPath = char(domNode.getElementsByTagName('model_file').item(0).getFirstChild.getData);
            [~,modelFile,~] = fileparts(modelFullPath);
            obj.Model = modelFile;
            % Muscle names
            if strcmp(obj.Model,'gait2392')
                obj.Muscles = {'vas_med','vas_lat','vas_int','rect_fem','semimem',...
                               'semiten','bifemlh','bifemsh','med_gas','lat_gas'};
            else
                obj.Muscles = {'vasmed','vaslat','vasint','recfem','semimem',...
                               'semiten','bflh','bfsh','gasmed','gaslat'};
            end
            % Cycle leg
            simLeg = simName(1);
            if strcmp(obj.SubID(11),'N') || strcmp(obj.SubID(11),'R')
                if strcmp(simLeg,'A')
                    obj.Leg = 'R';
                else
                     obj.Leg = 'L';
                end
            elseif strcmp(obj.SubID(11),'L')
                if strcmp(simLeg,'A')
                     obj.Leg = 'L';
                else
                     obj.Leg = 'R';
                end
            end
            % EMG
            obj.EMG = OpenSim.emg(subID,simName);
            % KIN
            obj.KIN = OpenSim.kin(subID,simName);
            % TRC
            obj.TRC = OpenSim.trc(subID,simName);
            % GRF
            obj.GRF = OpenSim.grf(subID,simName);
            % IK
            obj.IK = OpenSim.ik(subID,simName);
            % ID
            obj.ID = OpenSim.id(subID,simName);
            % RRA
            obj.RRA = OpenSim.rra(subID,simName);
            % CMC
            obj.CMC = OpenSim.cmc(subID,simName);            
            % -------------------------------------------------------------
            % Total mass of model used (subject specific)
            modelFile = [obj.SubDir,filesep,obj.SubID,'_',obj.SimName,'.osim'];
            domNode = xmlread(modelFile);
            massNodeList = domNode.getElementsByTagName('mass');
            subMass = 0;
            for i = 1:massNodeList.getLength                
                subMass = subMass + str2double(char(massNodeList.item(i-1).getFirstChild.getData));               
            end
            obj.WeightN = subMass*9.81;
            % Total mass of generic model
            genMass = 75.337;
            obj.ScaleFactor = subMass/genMass;
            % ----------------------
            % Height of subject
            xmlFile = [obj.SubDir,filesep,obj.SubID,'__PersonalInformation.xml'];
            domNode = xmlread(xmlFile);
            hNodeList = domNode.getElementsByTagName('height');
            height = str2double(char(hNodeList.item(0).getFirstChild.getData));
            % Convert mm to meters
            obj.Height = height/1000;
            % --------------------------
            % Muscle forces
            % Calculate Nyquist frequency
            nyquist = 0.5*1000;                
            % Design a 4th order 15 Hz cutoff low pass Butterworth filter
            order = 4;
            cutoff = 15;
            [b, a] = butter(order, cutoff/nyquist);
            % Interpolate muscle forces over normalized time window
            xi = (linspace(obj.GRF.CycleTime(1),obj.GRF.CycleTime(2),111))';
            xi = xi(5:105);
            iForces = zeros(101,length(obj.Muscles));
            for i = 1:length(obj.Muscles)
                try
                    % Filter
                    filtForce = filtfilt(b, a, obj.CMC.Actuation.Force.([obj.Muscles{i},'_',lower(obj.Leg)]));
                    % Interpolate
                    iForces(:,i) = interp1(obj.CMC.Actuation.Force.time,filtForce,xi,'nearest',NaN);
%                     iForces(:,i) = interp1(obj.CMC.Actuation.Force.time,obj.CMC.Actuation.Force.([obj.Muscles{i},'_',lower(obj.Leg)]),xi,'spline',NaN);
                    % Force positive
                    iForces(iForces(:,i)<0.01,i) = 0.01;
                catch err
                    iForces = NaN(101,length(obj.Muscles));
                    break
                end
            end
            mForces = dataset({iForces,obj.Muscles{:}});
            % For SD2F trials that are incomplete, remove last 5 data points
            if any(isnan(mForces.(obj.Muscles{1})))
                if any(~isnan(mForces.(obj.Muscles{1})))
                    firstNaN = find(isnan(mForces.(obj.Muscles{1})),1,'first');
                    if firstNaN ~= 1
                        mForces((firstNaN-5):(firstNaN-1),:) = dataset({NaN(5,length(obj.Muscles)),obj.Muscles{:}});
                    end
                end
            end
            obj.MuscleForces = mForces;
            % --------------------------
            % Interpolate EMG over normalized time window (SHIFTED -- but not enough, only 33 milliseconds to beginning of data)
            emgMuscles = obj.EMG.Data.Properties.VarNames;
            emgLegMuscles = cell(1,length(emgMuscles)/2);
            iEMG = zeros(101,length(emgMuscles)/2);
            xiTime = xi(end)-xi(1);
            % ~~~~~~~
            % PATCH
            if strcmp(obj.SubID,'20121110AHRM') && regexp(obj.SimName,'A_Walk')
                
            end
            % ~~~~~~~
            xiEMG = (linspace(obj.EMG.SampleTime(1),(obj.EMG.SampleTime(1)+xiTime),101))';
            j = 1;
            for i = 1:length(emgMuscles)
                if strncmp(emgMuscles{i},obj.Leg,1)
                    emgLegMuscles{j} = emgMuscles{i}(2:end);
                    iEMG(:,j) = interp1(obj.EMG.SampleTime,obj.EMG.Data.(emgMuscles{i}),xiEMG,'spline');
                    % Normalize to max during window
                    iEMG(:,j) = iEMG(:,j)/max(iEMG(:,j));
                    j = j+1;
                end
            end
            mEMG = dataset({iEMG,emgLegMuscles{:}});
            obj.EMG.Norm = mEMG;
            % --------------------------
            % Interpolate knee kinetics over normalized time window
            kinProps = obj.KIN.Data.Properties.VarNames;
            iKin = nan(101,length(kinProps));
            for i = 1:length(kinProps)
                if any(isnan(obj.KIN.Data.(kinProps{i})))
                    nanInd = isnan(obj.KIN.Data.(kinProps{i}));
                    if sum(nanInd) <= 8                        
                        iKin(:,i) = interp1(obj.KIN.FrameTime(~nanInd),obj.KIN.Data.(kinProps{i})(~nanInd),xi,'spline','extrap');
                    else
                        iKin(:,i) = interp1(obj.KIN.FrameTime(~nanInd),obj.KIN.Data.(kinProps{i})(~nanInd),xi,'spline',NaN);
                    end
                else                    
                    iKin(:,i) = interp1(obj.KIN.FrameTime,obj.KIN.Data.(kinProps{i}),xi,'spline');
                end
            end
            kKIN = dataset({iKin,kinProps{:}});
            obj.KIN.Norm = kKIN;
            % --------------------------
            % Kinematics from OpenSim
            leg = lower(obj.Leg);
            kinProps = {'lumbar_extension','lumbar_bending','lumbar_rotation',...
                        'pelvis_tx','pelvis_ty','pelvis_tz',...
                        'pelvis_tilt','pelvis_list','pelvis_rotation',...
                        ['hip_flexion_',leg],['hip_adduction_',leg],['hip_rotation_',leg],...
                        ['knee_angle_',leg],['ankle_angle_',leg]};
            kinNames = {'lumbar_extension','lumbar_bending','lumbar_rotation',...
                        'pelvis_tx','pelvis_ty','pelvis_tz',...            
                        'pelvis_tilt','pelvis_list','pelvis_rotation',...
                        'hip_flexion','hip_adduction','hip_rotation',...
                        'knee_flexion','ankle_plantar'};
            % Design IK filter
            nyquist = 0.5*round(1/(obj.IK.Time(2)-obj.IK.Time(1)));                
            % Design a 4th order 6 Hz cutoff low pass Butterworth filter
            order = 4;
            cutoff = 6;
            [b, a] = butter(order, cutoff/nyquist);
            % Filter and interpolate IK kinematics over normalized time window
            iIK = nan(101,length(kinProps));
            for i = 1:length(kinProps)                
                filtIK = filtfilt(b, a, obj.IK.Data.(kinProps{i}));
                iIK(:,i) = interp1(obj.IK.Time,filtIK,xi,'spline',NaN);            
            end
            dsIK = dataset({iIK,kinNames{:}});
            obj.IK.Norm = dsIK;
            % --------------------------
            % Interpolate RRA & CMC kinematics over normalized time window            
            iRRA = nan(101,length(kinProps));
            iCMC = nan(101,length(kinProps));
%             nyquist = 0.5*1000;
%             [b, a] = butter(order, cutoff/nyquist);
            for i = 1:length(kinProps)
                iRRA(:,i) = interp1(obj.RRA.Kinematics.Coordinate.time,obj.RRA.Kinematics.Coordinate.(kinProps{i}),xi,'spline',NaN);
%                 filtCMC = filtfilt(b, a, obj.CMC.Kinematics.Coordinate.(kinProps{i}));
%                 iCMC(:,i) = interp1(obj.CMC.Kinematics.Coordinate.time,filtCMC,xi,'spline',NaN);  
                iCMC(:,i) = interp1(obj.CMC.Kinematics.Coordinate.time,obj.CMC.Kinematics.Coordinate.(kinProps{i}),xi,'spline',NaN);
            end
            dsRRA = dataset({iRRA,kinNames{:}});
            dsCMC = dataset({iCMC,kinNames{:}});
            obj.RRA.NormKinematics = dsRRA;
            obj.CMC.NormKinematics = dsCMC;
            % --------------------------
            % Interpolate RRA torques & CMC reserves over normalized time window
            cmcProps = obj.CMC.Actuation.Force.Properties.VarNames;
            cellMatch = regexp(cmcProps,'_reserve');
            logMatch = false(size(cellMatch));
            for k = 1:length(cellMatch)
                if ~isempty(cellMatch{k})
                    logMatch(k) = true;
                else
                    logMatch(k) = false;
                end
            end
            cmcProps(~logMatch) = [];            
            resProps = cellfun(@(x) x(1:end-8), cmcProps, 'UniformOutput', false);
            iRRA = nan(101,length(resProps));
            iCMC = nan(101,length(resProps));
            for i = 1:length(cmcProps)
                iRRA(:,i) = interp1(obj.RRA.Actuation.Force.time,obj.RRA.Actuation.Force.(cmcProps{i}),xi,'spline',NaN);
                iCMC(:,i) = interp1(obj.CMC.Actuation.Force.time,obj.CMC.Actuation.Force.(cmcProps{i}),xi,'spline',NaN);                
            end
            dsRRA = dataset({iRRA,resProps{:}});
            dsCMC = dataset({iCMC,resProps{:}});
            obj.RRA.NormTorques = dsRRA;
            obj.CMC.NormReserves = dsCMC;
            % --------------------------
            % Interpolate RRA residuals & CMC residuals over normalized time window
            resProps = {'FX','FY','FZ','MX','MY','MZ'};
            iRRA = nan(101,length(resProps));
            iCMC = nan(101,length(resProps));
            for i = 1:length(resProps)
                iRRA(:,i) = interp1(obj.RRA.Actuation.Force.time,obj.RRA.Actuation.Force.(resProps{i}),xi,'spline',NaN);
                iCMC(:,i) = interp1(obj.CMC.Actuation.Force.time,obj.CMC.Actuation.Force.(resProps{i}),xi,'spline',NaN);                
            end
            dsRRA = dataset({iRRA,resProps{:}});
            dsCMC = dataset({iCMC,resProps{:}});
            obj.RRA.NormResiduals = dsRRA;
            obj.CMC.NormResiduals = dsCMC;
            % --------------------------
            % Interpolate CMC activations over normalized time window
            cmcProps = obj.CMC.States.Properties.VarNames;
            regex = ['(vasmed|vaslat|recfem|semiten|bflh|gasmed|gaslat)_',lower(obj.Leg),'_activation'];
            cellMatch = regexp(cmcProps,regex);
            logMatch = false(size(cellMatch));
            for k = 1:length(cellMatch)
                if ~isempty(cellMatch{k})
                    logMatch(k) = true;
                else
                    logMatch(k) = false;
                end
            end
            cmcProps(~logMatch) = [];            
            actProps = cellfun(@(x) x(1:end-13), cmcProps, 'UniformOutput', false);
            iCMC = nan(101,length(actProps));
            for i = 1:length(cmcProps)
                states = obj.CMC.States.(cmcProps{i});
                states(states == 0.02) = 0;
                iCMC(:,i) = interp1(obj.CMC.States.time,states,xi,'nearest',NaN);                
            end
            dsCMC = dataset({iCMC,actProps{:}});
            obj.CMC.NormActivations = dsCMC;
            % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            % Summarize over cycle region -- ignore first 5% and last 5%
            % b/c of GRF threshold; use Raw data
            % --------------------------
            % RRA Residuals 
            perCycle = 0.05*(obj.GRF.CycleTime(2)-obj.GRF.CycleTime(1));
            [~,iStart] = min(abs(obj.RRA.Actuation.Force.time-(obj.GRF.CycleTime(1)+perCycle)));
            [~,iStop] = min(abs(obj.RRA.Actuation.Force.time-(obj.GRF.CycleTime(2)-perCycle)));
            residualNames = {'FX','FY','FZ','MX','MY','MZ'};
            meanRMSmaxData = zeros(6,6);
            for i = 1:6
                meanRMSmaxData(1,i) = mean(obj.RRA.Actuation.Force.(residualNames{i})(iStart:iStop));
                meanRMSmaxData(3,i) = rms(obj.RRA.Actuation.Force.(residualNames{i})(iStart:iStop));
                meanRMSmaxData(5,i) = max(abs(obj.RRA.Actuation.Force.(residualNames{i})(iStart:iStop)));
            end
            % --------------------------
            % CMC Residuals
            [~,iStart] = min(abs(obj.CMC.Actuation.Force.time-(obj.GRF.CycleTime(1)+perCycle)));
            [~,iStop] = min(abs(obj.CMC.Actuation.Force.time-(obj.GRF.CycleTime(2)-perCycle)));
            for i = 1:6
                meanRMSmaxData(2,i) = mean(obj.CMC.Actuation.Force.(residualNames{i})(iStart:iStop));
                meanRMSmaxData(4,i) = rms(obj.CMC.Actuation.Force.(residualNames{i})(iStart:iStop));
                meanRMSmaxData(6,i) = max(abs(obj.CMC.Actuation.Force.(residualNames{i})(iStart:iStop)));
            end
            rDataset = dataset({meanRMSmaxData,residualNames{:}});
            rDataset = set(rDataset,'ObsNames',{'Mean_RRA','Mean_CMC','RMS_RRA','RMS_CMC','Max_RRA','Max_CMC'});
            obj.Residuals = rDataset;
            % --------------------------
            % CMC Reserves
            resProps = {'lumbar_extension','lumbar_bending','lumbar_rotation',...
                        ['hip_flexion_',leg],['hip_adduction_',leg],['hip_rotation_',leg],...
                        ['knee_angle_',leg],['ankle_angle_',leg]};
            resProps = cellfun(@(x) [x,'_reserve'], resProps, 'UniformOutput',false);
            resNames = {'lumbar_extension','lumbar_bending','lumbar_rotation',...
                        'hip_flexion','hip_adduction','hip_rotation',...
                        'knee_flexion','ankle_plantar'};
            meanRMSmaxData = zeros(3,length(resProps));
            for i = 1:length(resProps)
                meanRMSmaxData(1,i) = mean(obj.CMC.Actuation.Force.(resProps{i})(iStart:iStop));
                meanRMSmaxData(2,i) = rms(obj.CMC.Actuation.Force.(resProps{i})(iStart:iStop));
                meanRMSmaxData(3,i) = max(abs(obj.CMC.Actuation.Force.(resProps{i})(iStart:iStop)));                
            end
            rDataset = dataset({meanRMSmaxData,resNames{:}});
            rDataset = set(rDataset,'ObsNames',{'Mean','RMS','Max'});
            obj.Reserves = rDataset;
            % --------------------------
            % CMC Position Errors
            [~,iStart] = min(abs(obj.CMC.PositionError.time-(obj.GRF.CycleTime(1)+perCycle)));
            [~,iStop] = min(abs(obj.CMC.PositionError.time-(obj.GRF.CycleTime(2)-perCycle)));
            meanRMSmaxData = zeros(3,length(kinProps));
            for i = 1:length(kinProps)
                meanRMSmaxData(1,i) = mean(obj.CMC.PositionError.(kinProps{i})(iStart:iStop));
                meanRMSmaxData(2,i) = rms(obj.CMC.PositionError.(kinProps{i})(iStart:iStop));
                meanRMSmaxData(3,i) = max(abs(obj.CMC.PositionError.(kinProps{i})(iStart:iStop)));                
            end
            eDataset = dataset({meanRMSmaxData,kinNames{:}});
            eDataset = set(eDataset,'ObsNames',{'Mean','RMS','Max'});
            obj.PosErrors = eDataset;
            % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            % Set up normalized muscle forces (to be added on subject construction)
            nForces = zeros(101,length(obj.Muscles));
            obj.NormMuscleForces = dataset({nForces,obj.Muscles{:}});
        end
        % *****************************************************************
        %       Plotting Methods
        % *****************************************************************
        function plotMuscleForces(obj,varargin)
            % PLOTMUSCLEFORCES
            %
            
            % Parse inputs
            p = inputParser;
            checkObj = @(x) isa(x,'OpenSim.simulation');            
            validMuscles = [obj.Muscles,{'All','Quads','Hamstrings','Gastrocs'}];
            defaultMuscle = 'All';
            checkMuscle = @(x) any(validatestring(x,validMuscles));
            defaultFigHandle = figure('NumberTitle','off','Visible','off');
            defaultAxesHandles = axes('Parent',defaultFigHandle);
            p.addRequired('obj',checkObj);
            p.addOptional('Muscle',defaultMuscle,checkMuscle);
            p.addOptional('fig_handle',defaultFigHandle);
            p.addOptional('axes_handles',defaultAxesHandles);
            p.parse(obj,varargin{:});
            % Shortcut references to input arguments (and updates)
            fig_handle = p.Results.fig_handle;
            if ~isempty(p.UsingDefaults)                
                set(fig_handle,'Name',['Muscle Forces - ',p.Results.Muscle]);
                [axes_handles,mNames] = OpenSim.getAxesAndMuscles(obj,p.Results.Muscle);
            else
                axes_handles = p.Results.axes_handles;
                [~,mNames] = OpenSim.getAxesAndMuscles(obj,p.Results.Muscle);
            end
            % Plot
            figure(fig_handle);
            for j = 1:length(mNames)
                set(fig_handle,'CurrentAxes',axes_handles(j));
                XplotMuscleForces(obj,mNames{j});
            end
            % -------------------------------------------------------------
            %   Subfunction
            % -------------------------------------------------------------
            function XplotMuscleForces(obj,Muscle)
                % XPLOTMUSCLEFORCES
                %
               
                % Plot
                plot((0:100)',obj.MuscleForces.(Muscle),'Color',[0.75 0 0.25],'LineWidth',2); hold on;
                % Axes properties
                set(gca,'box','off');
                % Set axes limits
                xlim([0 100]);
                % Labels
                title(upper(Muscle),'FontWeight','bold');
                xlabel({'% Cycle',''});
                ylabel('Muscle Force (N)');
            end
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function plotRawFiltForces(obj,varargin)
            % PLOTRAWFILTFORCES
            %
            
            p = inputParser;
            checkObj = @(x) isa(x,'OpenSim.simulation');            
            validMuscles = [obj.Muscles,{'All','Quads','Hamstrings','Gastrocs'}];
            defaultMuscle = 'All';
            checkMuscle = @(x) any(validatestring(x,validMuscles));
            defaultFigHandle = figure('NumberTitle','off','Visible','off');
            defaultAxesHandles = axes('Parent',defaultFigHandle);
            p.addRequired('obj',checkObj);
            p.addOptional('Muscle',defaultMuscle,checkMuscle);
            p.addOptional('fig_handle',defaultFigHandle);
            p.addOptional('axes_handles',defaultAxesHandles);
            p.parse(obj,varargin{:});
            % Shortcut references to input arguments (and updates)
            fig_handle = p.Results.fig_handle;
            if ~isempty(p.UsingDefaults)                
                set(fig_handle,'Name',[obj.SubID,'_',obj.SimName,' - Raw vs. Filtered - ',p.Results.Muscle]);
                [axes_handles,mNames] = OpenSim.getAxesAndMuscles(obj,p.Results.Muscle);
            else
                axes_handles = p.Results.axes_handles;
                [~,mNames] = OpenSim.getAxesAndMuscles(obj,p.Results.Muscle);
            end
            % Plot
            figure(fig_handle);
            for j = 1:length(mNames)
                set(fig_handle,'CurrentAxes',axes_handles(j));
                XplotRawFiltForces(obj,mNames{j});
            end
            % -------------------------------------------------------------
            %   Subfunction
            % -------------------------------------------------------------
            function XplotRawFiltForces(obj,Muscle)
                % XPLOTRAWFILTFORCES
                %
               
                % Plot
                plot((0:100)',obj.MuscleForces.(Muscle),'Color',[0.75 0 0.25],'LineWidth',2); hold on;
                simPercentCycle = (obj.CMC.Actuation.Force.time-obj.GRF.CycleTime(1))/ ...
                                  (obj.GRF.CycleTime(2)-obj.GRF.CycleTime(1))*100;
%                 ind = (simPercentCycle > 0 | simPercentCycle < 100);
%                 plot(simPercentCycle(ind),obj.CMC.Actuation.Force.([Muscle,'_',lower(obj.Leg)])(ind),'c--','LineWidth',1.5);
                plot(simPercentCycle,obj.CMC.Actuation.Force.([Muscle,'_',lower(obj.Leg)]),'c--','LineWidth',1.5);
                % Axes properties
                set(gca,'box','off');
                % Set axes limits
                xlim([-1 101]);
                % Labels
                title(upper(Muscle),'FontWeight','bold');
                xlabel({'% Cycle',''});
                ylabel('Muscle Force (N)');
            end
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function plotKinematics(obj,varargin)
            % PLOTKINEMATICS
            %
            
            p = inputParser;
            checkObj = @(x) isa(x,'OpenSim.simulation');
            defaultFigHandle = figure('NumberTitle','off','Visible','off');
            defaultAxesHandles = axes('Parent',defaultFigHandle);
            p.addRequired('obj',checkObj);
            p.addOptional('fig_handle',defaultFigHandle);
            p.addOptional('axes_handles',defaultAxesHandles);
            p.parse(obj,varargin{:});
            % Shortcut references to input arguments (and updates)
            fig_handle = p.Results.fig_handle;
            if ~isempty(p.UsingDefaults)                
                set(fig_handle,'Name',[obj.SubID,'_',obj.SimName,' - IK, RRA, CMC Kinematics']);
                axes_handles = zeros(1,11);
                for k = 1:11
                    axes_handles(k) = subplot(4,3,k);
                end
            else
                axes_handles = p.Results.axes_handles;
            end
            kinNames = obj.IK.Norm.Properties.VarNames;
            kinNames = [kinNames(1:3) kinNames(7:end)];
            % Plot
            figure(fig_handle);
            for j = 1:length(kinNames)
                set(fig_handle,'CurrentAxes',axes_handles(j));
                XplotKinematics(obj,kinNames{j});
            end
            % -------------------------------------------------------------
            %   Subfunction
            % -------------------------------------------------------------
            function XplotKinematics(obj,Kin)
                % XPLOTKINEMATICS
                %
               
                % Plot IK
                plot((0:100)',obj.IK.Norm.(Kin),'Color',[0.15 0.15 0.15],'LineWidth',3); hold on;
                % Plot RRA
                plot((0:100)',obj.RRA.NormKinematics.(Kin),'Color',[27,158,119]/255,'LineWidth',3,'LineStyle','--');
                % Plot CMC
                plot((0:100)',obj.CMC.NormKinematics.(Kin),'Color',[117,112,179]/255,'LineWidth',3,'LineStyle',':');
                % Axes properties
                set(gca,'box','off');
                % Set axes limits
                xlim([0 100]);
                if strcmp(Kin,'lumbar_extension')
                    ylim([-5 10]);
                elseif strcmp(Kin,'pelvis_tilt')
                    ylim([-15 0]);
                end
                % Labels
                spaceInd = regexp(Kin,'_');
                kinName = [upper(Kin(1)),Kin(2:spaceInd-1),' ',upper(Kin(spaceInd+1)),Kin(spaceInd+2:end)];
                if strcmp(kinName,'Ankle Plantar')
                    kinName = 'Ankle Plantarflexion';
                elseif strcmp(kinName,'Pelvis Tx')
                    kinName = 'Pelvis Ant-Post';
                elseif strcmp(kinName,'Pelvis Ty')
                    kinName = 'Pelvis Vertical';
                elseif strcmp(kinName,'Pelvis Tz')
                    kinName = 'Pelvis Med-Lat';                    
                end
                title(kinName,'FontWeight','bold');
                if strcmp(Kin,'knee_flexion') || strcmp(Kin,'ankle_plantar') || strcmp(Kin,'hip_rotation')
                    xlabel('% Stance');
                end
                if strcmp(Kin,'pelvis_tx')
                    ylabel('Position (m)');
                elseif strcmp(Kin,'lumbar_extension') || strcmp(Kin,'pelvis_tx') || ...
                       strcmp(Kin,'pelvis_tilt') || strcmp(Kin,'hip_flexion') || strcmp(Kin,'knee_flexion')
                    ylabel('Angle (deg)');
                end
            end
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function plotTorques(obj,varargin)
            % PLOTTORQUES
            %
            
            p = inputParser;
            checkObj = @(x) isa(x,'OpenSim.simulation');
            defaultFigHandle = figure('NumberTitle','off','Visible','off');
            defaultAxesHandles = axes('Parent',defaultFigHandle);
            p.addRequired('obj',checkObj);
            p.addOptional('fig_handle',defaultFigHandle);
            p.addOptional('axes_handles',defaultAxesHandles);
            p.parse(obj,varargin{:});
            % Shortcut references to input arguments (and updates)
            fig_handle = p.Results.fig_handle;
            if ~isempty(p.UsingDefaults)                
                set(fig_handle,'Name',[obj.SubID,'_',obj.SimName,' - RRA Torques vs CMC Reserves']);
                axes_handles = zeros(1,8);
                for k = 1:8
                    axes_handles(k) = subplot(3,3,k);
                end
            else
                axes_handles = p.Results.axes_handles;
            end
            leg = lower(obj.Leg);
            torNames = {'lumbar_extension','lumbar_bending','lumbar_rotation',...
                        ['hip_flexion_',leg],['hip_adduction_',leg],['hip_rotation_',leg],...
                        ['knee_angle_',leg],['ankle_angle_',leg]};
            % Plot
            figure(fig_handle);
            for j = 1:length(torNames)
                set(fig_handle,'CurrentAxes',axes_handles(j));
                XplotTorques(obj,torNames{j});
            end
            % -------------------------------------------------------------
            %   Subfunction
            % -------------------------------------------------------------
            function XplotTorques(obj,Tor)
                % XPLOTTORQUES
                %
                
                % Percent cycle
                x = (0:100)';               
                % Plot RRA
                plot(x,(obj.RRA.NormTorques.(Tor)/(obj.WeightN*obj.Height)*100),'Color',[27,158,119]/255,'LineWidth',3,'LineStyle','--'); hold on;
                % Plot CMC Muscles
                plot(x,((obj.RRA.NormTorques.(Tor)-obj.CMC.NormReserves.(Tor))/(obj.WeightN*obj.Height)*100),'Color',[117,112,179]/255,'LineWidth',3,'LineStyle',':');
                % Axes properties
                set(gca,'box','off');
                % Set axes limits
                xlim([0 100]);
                % Labels
                spaceInd = regexp(Tor,'_');
                if length(spaceInd) == 2
                    torName = [upper(Tor(1)),Tor(2:spaceInd(1)-1),' ',upper(Tor(spaceInd(1)+1)),Tor(spaceInd(1)+2:spaceInd(2)-1)];
                elseif length(spaceInd) == 1
                    torName = [upper(Tor(1)),Tor(2:spaceInd-1),' ',upper(Tor(spaceInd+1)),Tor(spaceInd+2:end)];
                end
                if strcmp(torName,'Knee Angle')
                    torName = 'Knee Flexion';
                elseif strcmp(torName,'Ankle Angle')
                    torName = 'Ankle Plantarflexion';
                end
                title(torName,'FontWeight','bold');
                if strcmp(Tor(1:end-2),'knee_angle') || strcmp(Tor(1:end-2),'ankle_angle') || strcmp(Tor(1:end-2),'hip_rotation')
                    xlabel('% Stance');
                end
                if strcmp(Tor,'lumbar_extension') || strcmp(Tor(1:end-2),'hip_flexion') || strcmp(Tor(1:end-2),'knee_angle')
                    ylabel('Torque (% BW*H)');
                end
            end
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function plotResiduals(obj,varargin)
            % PLOTRESIDUALS
            %
            
            % Parse inputs
            p = inputParser;
            checkObj = @(x) isa(x,'OpenSim.simulation');
            defaultFigHandle = figure('NumberTitle','off','Visible','off');
            defaultAxesHandles = axes('Parent',defaultFigHandle);
            p.addRequired('obj',checkObj);
            p.addOptional('fig_handle',defaultFigHandle);
            p.addOptional('axes_handles',defaultAxesHandles);
            p.parse(obj,varargin{:});
            % Residuals
            rNames = {'FY','FX','FZ','MY','MX','MZ'};
            % Shortcut references to input arguments
            fig_handle = p.Results.fig_handle;
            if ~isempty(p.UsingDefaults)          
                set(fig_handle,'Name',[obj.SubID,'_',obj.SimName,' - CMC Residuals']);
                axes_handles = zeros(1,6);
                for k = 1:6
                    axes_handles(k) = subplot(2,3,k);
                end
            else
                axes_handles = p.Results.axes_handles;
            end
            % Plot
            figure(fig_handle);
            for j = 1:6
                set(fig_handle,'CurrentAxes',axes_handles(j));
                XplotResiduals(obj,rNames{j});
            end
            % -------------------------------------------------------------
            %   Subfunction
            % -------------------------------------------------------------
            function XplotResiduals(obj,Residual)
                % XPLOTRESIDUALS
                %
                
                % Plot
                x = (0:100)';
                % Plot CMC
                if strncmp(Residual,'F',1)
                    plot(x,(obj.CMC.NormResiduals.(Residual)/obj.WeightN*100),'Color',[0.3 0.3 0.3],'LineWidth',3); hold on;
                    fprintf(['RMS Residual for ',Residual,' is ',num2str(obj.Residuals{'RMS_CMC',Residual}/obj.WeightN*100,'%8.2f'),'\n']);
                else
                    plot(x,(obj.CMC.NormResiduals.(Residual)/(obj.WeightN*obj.Height)*100),'Color',[0.3 0.3 0.3],'LineWidth',3); hold on;
                    fprintf(['RMS Residual for ',Residual,' is ',num2str(obj.Residuals{'RMS_CMC',Residual}/(obj.WeightN*obj.Height)*100,'%8.2f'),'\n']);
                end
%                 % Average
%                 plot([0 100],[obj.Residuals{'Mean_CMC',Residual} obj.Residuals{'Mean_CMC',Residual}],...
%                      'Color',[0.15 0.15 0.15],'LineWidth',1.5,'LineStyle',':');
%                 % RMS
%                 plot([0 100],[obj.Residuals{'RMS_CMC',Residual} obj.Residuals{'RMS_CMC',Residual}],...
%                      'Color',[0.15 0.15 0.15],'LineWidth',1.5,'LineStyle','--');
                
                % Horizontal line at zero
                curYLim = get(gca,'yLim');
                if curYLim(1) ~= 0 && curYLim(2) ~= 0
                    plot([0 100],[0 0],'Color',[0.5 0.5 0.5],'LineWidth',0.5);                
                end
                % Reverse children order
                set(gca,'Children',flipud(get(gca,'Children')));
                % Axes properties
                set(gca,'box','off');
                % Set axes limits
                xlim([0 100]);
                % Labels
                if strcmp(Residual,'FX')
                    title('Anterior/Posterior','FontWeight','bold');                      
                elseif strcmp(Residual,'FY')
                    title('Vertical','FontWeight','bold'); 
                    ylabel('Force (% BW)');
                elseif strcmp(Residual,'FZ')
                    title('Medial/Lateral','FontWeight','bold');   
                elseif strcmp(Residual,'MX')
                    title('Frontal Plane','FontWeight','bold');                     
                elseif strcmp(Residual,'MY')
                    title('Transverse Plane','FontWeight','bold');
                    ylabel('Torque (% BW*H)');
                elseif strcmp(Residual,'MZ')
                    title('Sagittal Plane','FontWeight','bold');   
                end                
                if strncmp(Residual,'M',1)
                    xlabel('% Cycle');
                end
            end
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function plotEMGvsCMC(obj,varargin)
            % PLOTEMGvsCMC
            %
            
            % Parse inputs
            p = inputParser;
            checkObj = @(x) isa(x,'OpenSim.simulation');
            defaultFigHandle = figure('NumberTitle','off','Visible','off');
            defaultAxesHandles = axes('Parent',defaultFigHandle);
            p.addRequired('obj',checkObj);
            p.addOptional('fig_handle',defaultFigHandle);
            p.addOptional('axes_handles',defaultAxesHandles);
            p.parse(obj,varargin{:});
            % EMG Names
            emgNames = {'VastusMedialis','VastusLateralis','Rectus',...
                        'MedialHam','LateralHam',...
                        'MedialGast','LateralGast'};
            % CMC Names
            cmcNames = {'vasmed','vaslat','recfem',...
                        'semiten','bflh',...
                        'gasmed','gaslat'};
            % Shortcut references to input arguments
            fig_handle = p.Results.fig_handle;
            if ~isempty(p.UsingDefaults)          
                set(fig_handle,'Name',[obj.SubID,'_',obj.SimName,' - EMG vs CMC']);
                axes_handles = zeros(1,7);
                for k = 1:5
                    axes_handles(k) = subplot(3,3,k);
                end
                axes_handles(6) = subplot(3,3,7);
                axes_handles(7) = subplot(3,3,8);
            else
                axes_handles = p.Results.axes_handles;
            end
            % Plot
            figure(fig_handle);
            for j = 1:7
                set(fig_handle,'CurrentAxes',axes_handles(j));
                XplotEMGvsCMC(obj,emgNames{j},cmcNames{j});
            end
            % -------------------------------------------------------------
            %   Subfunction
            % -------------------------------------------------------------
            function XplotEMGvsCMC(obj,emgName,cmcName)
                % XPLOTEMGVSCMC
                %
                
                % Plot
                x = (0:100)';
                % Plot CMC
                plot(x,obj.CMC.NormActivations.(cmcName),'Color',[0.3 0.3 0.3],'LineWidth',3); hold on;
                % Plot EMG
                plot(x,obj.EMG.Norm.(emgName)*max(obj.CMC.NormActivations.(cmcName)),'Color',[0.7 0.7 0.7],'LineWidth',3,'LineStyle','--');                               
                % Axes properties
                set(gca,'box','off');
                % Set axes limits
                xlim([0 100]);
                curYlim = get(gca,'YLim');
                newYmax = curYlim(2)+0.05*(curYlim(2)-curYlim(1));
                if newYmax > 1
                    newYmax = 1.05;
                elseif newYmax < 0.2
                    newYmax = 0.2;
                end
                set(gca,'YLim',[0 newYmax]);
                % Labels
                if strcmp(cmcName,'vasmed') || strcmp(cmcName,'semiten') || strcmp(cmcName,'gasmed')
                    ylabel('Norm Activity');
                end
                if strcmp(cmcName,'gasmed') || strcmp(cmcName,'gaslat') || strcmp(cmcName,'recfem')
                    xlabel('% Cycle');
                end
                if strcmp(cmcName,'vasmed')
                    title('Vastus Medialis','FontWeight','bold');
                elseif strcmp(cmcName,'vaslat')
                    title('Vastus Lateralis','FontWeight','bold');
                elseif strcmp(cmcName,'recfem')
                    title('Rectus Femoris','FontWeight','bold');
                elseif strcmp(cmcName,'semiten')
                    title('Semitendinosus','FontWeight','bold');                    
                elseif strcmp(cmcName,'bflh')
                    title('Biceps Femoris','FontWeight','bold');
                elseif strcmp(cmcName,'gasmed')
                    title('Medial Gastrocnemius','FontWeight','bold');    
                elseif strcmp(cmcName,'gaslat')
                    title('Lateral Gastrocnemius','FontWeight','bold');        
                end
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
            checkObj = @(x) isa(x,'OpenSim.simulation');
            p.addRequired('obj',checkObj);
            p.parse(obj);
            % Specify export folder path
            wpath = regexp(obj.SubDir,'Northwestern-RIC','split');
%             ABQdir = [wpath{1},'Northwestern-RIC',filesep,'Modeling',filesep,'Abaqus',...
%                          filesep,'Subjects',filesep,obj.SubID,filesep];
            ABQdir = [wpath{1},'Northwestern-RIC',filesep,'SVN',filesep,'Working',...
                      filesep,'FiniteElement',filesep,'Subjects',filesep,obj.SubID,filesep];
            % Create the folder if not already there
            if ~isdir(ABQdir)
                mkdir(ABQdir(1:end-1));
                export = true;
            else
                % Check if the file exists
                if ~exist([ABQdir,obj.SubID,'_',obj.SimName,'.inp'],'file')
                    export = true;
                else
                    choice = questdlg(['Would you like to overwrite the existing file for ',obj.SubID,'_',obj.SimName,'?'],'Overwrite','Yes','No','No');
                    if strcmp(choice,'Yes')
                        export = true;
                    else
                        disp(['Skipping export for ',obj.SubID,'_',obj.SimName]);
                        export = false;
                    end                    
                end
            end
            if export
                % Open file
                fid = fopen([ABQdir,obj.SubID,'_',obj.SimName,'_TEMP.inp'],'w');
                % Write common elements
                fprintf(fid,['*Heading\n',...
                             obj.SubID,'_',obj.SimName,'\n',...
                            '*Preprint, echo=NO, model=NO, history=NO, contact=NO\n',...
                            '**\n',...
                            '*Parameter\n',...
                            'time_step = 0.02\n',...
                            '**\n',...
                            '*Include, input=../../GenericFiles/Parts.inp\n',...
                            '*Include, input=../../GenericFiles/Assembly__Instances.inp\n',...
                            '*Include, input=../../GenericFiles/Assembly__Connectors.inp\n',...
                            '*Include, input=../../GenericFiles/Assembly__Constraints.inp\n',...                            
                            '*Include, input=../../GenericFiles/Model.inp\n',...
                            '**\n',...
                            '** AMPLITUDES\n',...
                            '**\n']);
                % Write amplitudes
%                 % -----------------------
% % %                 % Local Coordinate System
% % %                 % Flexion
% % %                 time_step = 0.02;
% % %                 time = (time_step:(time_step/20):6*time_step)';
% % %                 fprintf(fid,'*Amplitude, name=FLEXION, time=TOTAL TIME, definition=SMOOTH STEP\n0., 0., ');
% % %                 flexion = -1*(pi/180)*double(obj.KneeKin(:,1));
% % %                 timeflex = reshape([time'; flexion'],1,[]);
% % %                 fprintf(fid,'%6.6f, ',timeflex(1:6));
% % %                 fprintf(fid,'\n');
% % %                 iAmp = (7:8:202)';
% % %                 for n = 1:(length(iAmp)-1)
% % %                     fprintf(fid,'%6.6f, ',timeflex(iAmp(n):(iAmp(n)+7)));
% % %                     fprintf(fid,'\n');                            
% % %                 end
% % %                 lastLine = sprintf('%6.6f, ',timeflex(iAmp(end):202));
% % %                 lastLine = [lastLine(1:end-2),'\n'];
% % %                 fprintf(fid,lastLine);
% % %                 % Adduction - not accurate b/c need to use floating axis
% % %                 fprintf(fid,'*Amplitude, name=ADDUCTION, time=TOTAL TIME, definition=SMOOTH STEP\n0., 0., ');
% % %                 adduction = -1*(pi/180)*double(obj.KneeKin(:,2));
% % %                 timeAdd = reshape([time'; adduction'],1,[]);
% % %                 fprintf(fid,'%6.6f, ',timeAdd(1:6));
% % %                 fprintf(fid,'\n');
% % %                 iAmp = (7:8:202)';
% % %                 for n = 1:(length(iAmp)-1)
% % %                     fprintf(fid,'%6.6f, ',timeAdd(iAmp(n):(iAmp(n)+7)));
% % %                     fprintf(fid,'\n');
% % %                 end
% % %                 lastLine = sprintf('%6.6f, ',timeAdd(iAmp(end):202));
% % %                 lastLine = [lastLine(1:end-2),'\n'];
% % %                 fprintf(fid,lastLine);
% % %                 % External rotation
% % %                 fprintf(fid,'*Amplitude, name=EXTERNAL, time=TOTAL TIME, definition=SMOOTH STEP\n0., 0., ');
% % %                 external = -1*(pi/180)*double(obj.KneeKin(:,3));
% % %                 timeExt = reshape([time'; external'],1,[]);
% % %                 fprintf(fid,'%6.6f, ',timeExt(1:6));
% % %                 fprintf(fid,'\n');
% % %                 iAmp = (7:8:202)';
% % %                 for n = 1:(length(iAmp)-1)
% % %                     fprintf(fid,'%6.6f, ',timeExt(iAmp(n):(iAmp(n)+7)));
% % %                     fprintf(fid,'\n');                            
% % %                 end
% % %                 lastLine = sprintf('%6.6f, ',timeExt(iAmp(end):202));
% % %                 lastLine = [lastLine(1:end-2),'\n'];
% % %                 fprintf(fid,lastLine);
                % -----------------------
                % Boundary conditions
% %                 % Global - Flexion only
% %                 time_step = 0.02;
% %                 time = (time_step:(time_step/20):6*time_step)';
% %                 femur_eX = [0.0664602840401836,0.291756293626927,0.954180955466193]; 
% %                 flexion = -1*(pi/180)*double(obj.KneeKin(:,1));
% %                 for m = 1:3
% %                     fprintf(fid,['*Amplitude, name=FLEXION_UR',num2str(m),', time=TOTAL TIME, definition=SMOOTH STEP\n0., 0., ']);
% %                     flexionGlobal = flexion*femur_eX(m);
% %                     timeFG = reshape([time'; flexionGlobal'],1,[]);
% %                     fprintf(fid,'%6.6f, ',timeFG(1:6));
% %                     fprintf(fid,'\n');
% %                     iAmp = (7:8:202)';
% %                     for n = 1:(length(iAmp)-1)
% %                         fprintf(fid,'%6.6f, ',timeFG(iAmp(n):(iAmp(n)+7)));
% %                         fprintf(fid,'\n');                            
% %                     end
% %                     lastLine = sprintf('%6.6f, ',timeFG(iAmp(end):202));
% %                     lastLine = [lastLine(1:end-2),'\n'];
% %                     fprintf(fid,lastLine);                    
% %                 end
% % %                 % Global -- Flexion, Adduction, External
% % %                 time_step = 0.02;
% % %                 time = (time_step:(time_step/20):6*time_step)';
% % %                 rotations_inGlobal = evalin('base','rotations_inGlobal');
% % %                 for m = 1:3
% % %                     fprintf(fid,['*Amplitude, name=TIBIA_UR',num2str(m),', time=TOTAL TIME, definition=SMOOTH STEP\n0., 0., ']);                    
% % %                     timeUR = reshape([time'; reshape(rotations_inGlobal(m,1,:),1,101)],1,[]);
% % %                     fprintf(fid,'%6.6f, ',timeUR(1:6));
% % %                     fprintf(fid,'\n');
% % %                     iAmp = (7:8:202)';
% % %                     for n = 1:(length(iAmp)-1)
% % %                         fprintf(fid,'%6.6f, ',timeUR(iAmp(n):(iAmp(n)+7)));
% % %                         fprintf(fid,'\n');                            
% % %                     end
% % %                     lastLine = sprintf('%6.6f, ',timeUR(iAmp(end):202));
% % %                     lastLine = [lastLine(1:end-2),'\n'];
% % %                     fprintf(fid,lastLine);                    
% % %                 end
%                 ------------------
%                 for i = 1:length(obj.Muscles)
%                     mName = obj.Muscles{i};
%                     if strncmp(mName,'vas',3)
%                         ampNames = {['VASTUS',upper(mName(4:end))]};
%                     elseif strcmp(mName,'recfem')
%                         ampNames = {'RECTUSFEM'};
%                     elseif strncmp(mName,'bf',2)
%                         ampNames = {['BICEPSFEMORIS',upper(obj.Muscles{i}(3:4))]};
%                     elseif strcmp(mName,'semimem')
%                         ampNames = {'SEMIMEMBRANOSUS_WRAP','SEMIMEMBRANOSUS'};
%                     elseif strcmp(mName,'semiten')
%                         ampNames = {'SEMITENDINOSUS_WRAP','SEMITENDINOSUS'};
%                     elseif strncmp(mName,'gas',3)
%                         angles = {'0-5','5-10','10-15','15-20','20-25','25-30','30-35','35-40','40-45','45-50'};
%                         ampNames = cell(1,length(angles)+1);
%                         for j = 1:length(angles)
%                             ampNames{j} = [upper(mName(4)),'GASTROCNEMIUS_WRAP_',angles{j}];
%                         end
%                         ampNames{end} = [upper(mName(4)),'GASTROCNEMIUS'];
%                     end
%                     for k = 1:length(ampNames)
%                         fprintf(fid,['*Amplitude, name=',ampNames{k},', time=TOTAL TIME, definition=USER, properties=102\n',...
%                                      '<time_step>, ']);
%                         fprintf(fid,'%2.2f, ',obj.MuscleForces.(mName)(1:7));
%                         fprintf(fid,'\n');
%                         iAmp = (8:8:101)';
%                         for m = 1:(length(iAmp)-1)
%                             fprintf(fid,'%2.2f, ',obj.MuscleForces.(mName)(iAmp(m):(iAmp(m)+7)));
%                             fprintf(fid,'\n');                            
%                         end
%                         lastLine = sprintf('%2.2f, ',obj.MuscleForces.(mName)(iAmp(end):101));
%                         lastLine = [lastLine(1:end-2),'\n'];
%                         fprintf(fid,lastLine);
%                     end
%                 end
%                 % Ground reaction force and moment amplitudes
%                 grfNames = {'KNEEJC_F','KNEEJC_M'};
%                 dofs = {'X','Y','Z'};
%                 for k = 1:2
%                     for m = 1:3
%                         fprintf(fid,['*Amplitude, name=',grfNames{k},dofs{m},', time=TOTAL TIME, definition=USER, properties=304\n',...
%                                      '<time_step>, ']);
%                         % Forces, in Newtons
%                         if k == 1
%                             concatGRF = reshape(double(obj.KneeKin(:,(3*(k+1)-2):3*(k+1)))',1,[]);
%                         % Moments, in Newton-millimeters
%                         elseif k == 2
%                             concatGRF = 1000*reshape(double(obj.KneeKin(:,(3*(k+1)-2):3*(k+1)))',1,[]);    
%                         end
%                         fprintf(fid,'%2.2f, ',concatGRF(1:7));
%                         fprintf(fid,'\n');
%                         iAmp = (8:8:303)';
%                         for n = 1:(length(iAmp)-1)
%                             fprintf(fid,'%2.2f, ',concatGRF(iAmp(n):(iAmp(n)+7)));
%                             fprintf(fid,'\n');                            
%                         end
%                         lastLine = sprintf('%2.2f, ',concatGRF(iAmp(end):303));
%                         lastLine = [lastLine(1:end-2),'\n'];
%                         fprintf(fid,lastLine);
%                     end
%                 end
                % Final common elements
                fprintf(fid,['**\n',...
                             '*Include, input=../../GenericFiles/History.inp\n']);                
                % Close file
                fclose(fid);                
            end
        end
    end
    
end

