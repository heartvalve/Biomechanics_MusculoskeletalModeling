classdef simulation < handle
    % SIMULATION - A class to store an OpenSim modeling simulation.
    %
    %
    
    % Created by Megan Schroeder
    % Last Modified 2014-02-21
    
    
    %% Properties
    % Properties for the simulation class
    
    properties (SetAccess = private)        
        SubID               % Subject ID
        SimName             % Simulation name
        Model               % Generic model
        Muscles             % Muscle names
        Leg                 % Cycle leg
        EMG                 % EMG data from experiment (for comparison)
        KIN                 % Knee kinetics (from Cortex, for comparison)
        TRC                 % Marker data - input to simulation
        GRF                 % Ground Reaction Force data - input to simulation
        IK                  % Inverse Kinematics solution
        ID                  % Inverse Dynamics solution
        RRA                 % Residual Reduction Algorithm solution
        CMC                 % Computed Muscle Control solution
        MuscleForces        % Muscle forces (summarized from CMC)
        Residuals           % Residuals
        MuscleEMG           % Muscle EMG (summarized from EMG)
        KneeKin             % Knee kinematics and kinetics (summarized from KIN)
    end
    properties (Hidden = true, SetAccess = private)
        SubDir              % Directory where files are stored
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
            % Interpolate muscle forces over normalized time window
            xi = (linspace(obj.GRF.CycleTime(1),obj.GRF.CycleTime(2),101))';
            iForces = zeros(101,length(obj.Muscles));
            for i = 1:length(obj.Muscles)
                try
                    iForces(:,i) = interp1(obj.CMC.Actuation.Force.time,obj.CMC.Actuation.Force.([obj.Muscles{i},'_',lower(obj.Leg)]),xi,'spline',NaN);
                catch err
                    iForces = NaN(101,length(obj.Muscles));
                    break
                end
            end
            mForces = dataset({iForces,obj.Muscles{:}});
            % Check muscle forces for large discontinuities prior to NaN's
            if any(isnan(mForces.(obj.Muscles{1})))
                if any(~isnan(mForces.(obj.Muscles{1})))
                    firstNaN = find(isnan(mForces.(obj.Muscles{1})),1,'first');
                    if firstNaN ~= 1
                        for i = 1:length(obj.Muscles)
                            if abs(mForces.(obj.Muscles{i})(firstNaN-1)-mForces.(obj.Muscles{i})(firstNaN-2)) > ...
                               20*abs(mForces.(obj.Muscles{i})(firstNaN-2)-mForces.(obj.Muscles{i})(firstNaN-3))
                                mForces((firstNaN-1),:) = dataset({NaN(1,length(obj.Muscles)),obj.Muscles{:}});
                                break
                            end
                        end
                    end
                end
            end
            obj.MuscleForces = mForces;            
            % Interpolate EMG over normalized time window
            emgMuscles = obj.EMG.Data.Properties.VarNames;
            emgLegMuscles = cell(1,length(emgMuscles)/2);
            iEMG = zeros(101,length(emgMuscles)/2);
            j = 1;
            for i = 1:length(emgMuscles)
                if strncmp(emgMuscles{i},obj.Leg,1)
                    emgLegMuscles{j} = emgMuscles{i}(2:end);
                    iEMG(:,j) = interp1(obj.EMG.SampleTime,obj.EMG.Data.(emgMuscles{i}),xi,'spline');
                    j = j+1;
                end
            end
            mEMG = dataset({iEMG,emgLegMuscles{:}});
            obj.MuscleEMG = mEMG;
            % Interpolate Knee kinetics over normalized time window
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
            obj.KneeKin = kKIN;
            % RRA Residuals (focus on cycle region)
            [~,iStart] = min(abs(obj.RRA.Actuation.Force.time-obj.GRF.CycleTime(1)));
            [~,iStop] = min(abs(obj.RRA.Actuation.Force.time-obj.GRF.CycleTime(2)));
            residualNames = {'FX','FY','FZ','MX','MY','MZ'};
            meanRMSmaxData = zeros(6,6);
            for i = 1:6
                meanRMSmaxData(1,i) = mean(obj.RRA.Actuation.Force.(residualNames{i})(iStart:iStop));
                meanRMSmaxData(3,i) = rms(obj.RRA.Actuation.Force.(residualNames{i})(iStart:iStop));
                meanRMSmaxData(5,i) = max(abs(obj.RRA.Actuation.Force.(residualNames{i})(iStart:iStop)));
            end            
            % CMC Residuals
            [~,iStart] = min(abs(obj.CMC.Actuation.Force.time-obj.GRF.CycleTime(1)));
            [~,iStop] = min(abs(obj.CMC.Actuation.Force.time-obj.GRF.CycleTime(2)));
            for i = 1:6
                meanRMSmaxData(2,i) = mean(obj.CMC.Actuation.Force.(residualNames{i})(iStart:iStop));
                meanRMSmaxData(4,i) = rms(obj.CMC.Actuation.Force.(residualNames{i})(iStart:iStop));
                meanRMSmaxData(6,i) = max(abs(obj.CMC.Actuation.Force.(residualNames{i})(iStart:iStop)));
            end
            rDataset = dataset({meanRMSmaxData,residualNames{:}});
            rDataset = set(rDataset,'ObsNames',{'Mean_RRA','Mean_CMC','RMS_RRA','RMS_CMC','Max_RRA','Max_CMC'});
            obj.Residuals = rDataset;
            % ---------------------------
            % Set up normalized muscle forces (to be added on subject construction)
            nForces = zeros(101,length(obj.Muscles));
            obj.NormMuscleForces = dataset({nForces,obj.Muscles{:}});
        end
        % *****************************************************************
        %       Plotting Methods
        % *****************************************************************
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
            rNames = {'FX','MX','FY','MY','FZ','MZ'};
            % Shortcut references to input arguments
            fig_handle = p.Results.fig_handle;
            if ~isempty(p.UsingDefaults)          
                set(fig_handle,'Name','Residuals','Visible','on');
                axes_handles = zeros(1,6);
                for k = 1:6
                    axes_handles(k) = subplot(3,2,k);
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
            function XplotResiduals(obj,residual)
                % XPLOTRESIDUALS
                %
                
                % Plot                
                plot(obj.rra.actuation.force.time,obj.rra.actuation.force.(residual),'Color','b','LineWidth',2); hold on;
                % Average
                plot(obj.grf.cycleTime,[obj.rra.residuals.mean.(residual) obj.rra.residuals.mean.(residual)],...
                    'Color','r','LineWidth',1,'LineStyle',':');
                % RMS
                plot(obj.grf.cycleTime,[obj.rra.residuals.rms.(residual) obj.rra.residuals.rms.(residual)],...
                    'Color','r','LineWidth',1,'LineStyle','-');
                % Horizontal line at zero
                plot(obj.grf.cycleTime,[0 0],'Color',[0.5 0.5 0.5],'LineWidth',0.5);                
                % Axes properties
                set(gca,'box','off');
                % Set axes limits
                xlim(obj.grf.cycleTime);
                % Labels
                title(residual,'FontWeight','bold');
                xlabel({'Time (s)',''});
                ylabel('Magnitude (N)');
            end
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
        % *****************************************************************
        %       Export Muscle Forces
        % *****************************************************************
        function exportMuscleForces(obj)
            % EXPORTMUSCLEFORCES
            %
            
            % Parse inputs
            p = inputParser;
            checkObj = @(x) isa(x,'OpenSim.simulation');
            p.addRequired('obj',checkObj);
            p.parse(obj);
            % Export dataset object
            export(obj.MuscleForces,'file',fullfile(obj.SubDir,[obj.SubID,'_',obj.SimName,'_MuscleForces.data']));
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
            ABQdir = [wpath{1},'Northwestern-RIC',filesep,'Modeling',filesep,'Abaqus',...
                         filesep,'Subjects',filesep,obj.SubID,filesep];
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
                fid = fopen([ABQdir,obj.SubID,'_',obj.SimName,'.inp'],'w');
                % Write common elements
                fprintf(fid,['*Heading\n',...
                             obj.SubID,'_',obj.SimName,'\n',...
                            '*Preprint, echo=NO, model=NO, history=NO, contact=NO\n',...
                            '**\n',...
                            '*Parameter\n',...
                            'time_step = 0.2\n',...
                            '**\n',...
                            '*Include, input=../../GenericFiles/Parts.inp\n',...
                            '*Include, input=../../GenericFiles/Assembly__Instances_Surfaces.inp\n',...
                            '*Include, input=../../GenericFiles/Assembly__Connectors.inp\n',...
                            '*Include, input=../../GenericFiles/Assembly__Constraints.inp\n',...                            
                            '*Include, input=../../GenericFiles/Model.inp\n',...
                            '**\n',...
                            '** AMPLITUDES\n',...
                            '**\n']);
                % Write amplitudes
                for i = 1:length(obj.Muscles)
                    mName = obj.Muscles{i};
                    if strncmp(mName,'vas',3)
                        ampNames = {['VASTUS',upper(mName(4:end))]};
                    elseif strcmp(mName,'recfem')
                        ampNames = {'RECTUSFEM'};
                    elseif strncmp(mName,'bf',2)
                        ampNames = {['BICEPSFEMORIS',upper(obj.Muscles{i}(3:4))]};
                    elseif strcmp(mName,'semimem')
                        ampNames = {'SEMIMEMBRANOSUS_WRAP','SEMIMEMBRANOSUS'};
                    elseif strcmp(mName,'semiten')
                        ampNames = {'SEMITENDINOSUS_WRAP','SEMITENDINOSUS'};
                    elseif strncmp(mName,'gas',3)
                        angles = {'0-5','5-10','10-15','15-20','20-25','25-30','30-35','35-40','40-45','45-50'};
                        ampNames = cell(1,length(angles)+1);
                        for j = 1:length(angles)
                            ampNames{j} = [upper(mName(4)),'GASTROCNEMIUS_WRAP_',angles{j}];
                        end
                        ampNames{end} = [upper(mName(4)),'GASTROCNEMIUS'];
                    end
                    for k = 1:length(ampNames)
                        fprintf(fid,['*Amplitude, name=',ampNames{k},', time=TOTAL TIME, definition=USER, properties=102\n',...
                                     '<time_step>, ']);
                        fprintf(fid,'%2.2f, ',obj.MuscleForces.(mName)(1:7));
                        fprintf(fid,'\n');
                        iAmp = (8:8:101)';
                        for m = 1:(length(iAmp)-1)
                            fprintf(fid,'%2.2f, ',obj.MuscleForces.(mName)(iAmp(m):(iAmp(m)+7)));
                            fprintf(fid,'\n');                            
                        end
                        lastLine = sprintf('%2.2f, ',obj.MuscleForces.(mName)(iAmp(end):101));
                        lastLine = [lastLine(1:end-2),'\n'];
                        fprintf(fid,lastLine);
                    end
                end
                % Ground reaction force and moment amplitudes
                grfNames = {'KNEEJC_F','KNEEJC_M'};
                dofs = {'X','Y','Z'};
                for k = 1:2
                    for m = 1:3
                        fprintf(fid,['*Amplitude, name=',grfNames{k},dofs{m},', time=TOTAL TIME, definition=USER, properties=304\n',...
                                     '<time_step>, ']);
                        % Forces, in Newtons
                        if k == 1
                            concatGRF = reshape(double(obj.KneeKin(:,(3*(k+1)-2):3*(k+1)))',1,[]);
                        % Moments, in Newton-millimeters
                        elseif k == 2
                            concatGRF = 1000*reshape(double(obj.KneeKin(:,(3*(k+1)-2):3*(k+1)))',1,[]);    
                        end
                        fprintf(fid,'%2.2f, ',concatGRF(1:7));
                        fprintf(fid,'\n');
                        iAmp = (8:8:303)';
                        for n = 1:(length(iAmp)-1)
                            fprintf(fid,'%2.2f, ',concatGRF(iAmp(n):(iAmp(n)+7)));
                            fprintf(fid,'\n');                            
                        end
                        lastLine = sprintf('%2.2f, ',concatGRF(iAmp(end):303));
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

