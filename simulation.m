classdef simulation < handle
    % SIMULATION - A class to store an OpenSim modeling simulation.
    %
    %
    
    % Created by Megan Schroeder
    % Last Modified 2013-11-08
    
    
    %% Properties
    % Properties for the simulation class
    
    properties (SetAccess = private)        
        subID               % Subject ID
        simName             % Simulation name
        model               % Generic model
        muscles             % Muscle names
        leg                 % Cycle leg
        trc                 % Marker data - input to simulation
        grf                 % Ground Reaction Force data - input to simulation
        ik                  % Inverse Kinematics solution
        id                  % Inverse Dynamics solution
        rra                 % Residual Reduction Algorithm solution
        cmc                 % Computed Muscle Control solution
        muscleForces        % Muscle forces (summarized from CMC)
    end
    properties (Hidden = true, SetAccess = private)
        subDir              % Directory where files are stored
    end
    properties (Hidden = true)
        normMuscleForces    % Normalized muscle forces
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
            obj.subID = subID;
            % Simulation name (without subject ID)
            obj.simName = simName;
            % Subject directory
            obj.subDir = OpenSim.getSubjectDir(subID);
            % Generic model name from Setup Scale XML
            modelNameFile = dir(fullfile(obj.subDir,'*Setup_Scale.xml'));
            domNode = xmlread([obj.subDir,modelNameFile.name]);
            modelFullPath = char(domNode.getElementsByTagName('model_file').item(0).getFirstChild.getData);
            [~,modelFile,~] = fileparts(modelFullPath);
            obj.model = modelFile;
            % Muscle names
            if strcmp(obj.model,'gait2392')
                obj.muscles = {'vas_med','vas_lat','vas_int','rect_fem','semimem',...
                               'semiten','bifemlh','bifemsh','med_gas','lat_gas'};
            else
                obj.muscles = {'vasmed','vaslat','vasint','recfem','semimem',...
                               'semiten','bflh','bfsh','gasmed','gaslat'};
            end
            % Cycle leg
            simLeg = simName(1);
            if strcmp(obj.subID(11),'N') || strcmp(obj.subID(11),'R')
                if strcmp(simLeg,'A')
                    obj.leg = 'r';
                else
                     obj.leg = 'l';
                end
            elseif strcmp(obj.subID(11),'L')
                if strcmp(simLeg,'A')
                     obj.leg = 'l';
                else
                     obj.leg = 'r';
                end
            end            
            % TRC
            obj.trc = OpenSim.trc(subID,simName);
            % GRF
            obj.grf = OpenSim.grf(subID,simName);
            % IK
            obj.ik = OpenSim.ik(subID,simName);
            % ID
            obj.id = OpenSim.id(subID,simName);
            % RRA
            obj.rra = OpenSim.rra(subID,simName);
            % CMC
            obj.cmc = OpenSim.cmc(subID,simName);
            % Residuals (focus on cycle region)
            [~,iStart] = min(abs(obj.rra.actuation.force.time-obj.grf.cycleTime(1)));
            [~,iStop] = min(abs(obj.rra.actuation.force.time-obj.grf.cycleTime(2)));
            residuals = {'FX','FY','FZ','MX','MY','MZ'};
            meanData = zeros(1,6);
            rmsData = zeros(1,6);            
            maxData = zeros(1,6);
            for i = 1:6
                meanData(i) = mean(obj.rra.actuation.force.(residuals{i})(iStart:iStop));
                rmsData(i) = rms(obj.rra.actuation.force.(residuals{i})(iStart:iStop));
                maxData(i) = max(abs(obj.rra.actuation.force.(residuals{i})(iStart:iStop)));
            end
            obj.rra.residuals.mean = dataset({meanData,residuals{:}});
            obj.rra.residuals.rms = dataset({rmsData,residuals{:}});
            obj.rra.residuals.max = dataset({maxData,residuals{:}});
            % Interpolate muscle forces over normalized time window
            xi = linspace(obj.grf.cycleTime(1),obj.grf.cycleTime(2),101);
            iForces = zeros(101,length(obj.muscles));
            for i = 1:length(obj.muscles)
                try
                    iForces(:,i) = interp1(obj.cmc.actuation.force.time, obj.cmc.actuation.force.([obj.muscles{i},'_',obj.leg]), xi, 'spline', NaN);
                catch err
                    iForces = nan(101,length(obj.muscles));
                    break
                end
            end
            mForces = dataset({iForces,obj.muscles{:}});
            obj.muscleForces = mForces;
            % Set up normalized muscle forces (to be added on subject construction)
            nForces = zeros(101,length(obj.muscles));
            obj.normMuscleForces = dataset({nForces,obj.muscles{:}});
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
            validMuscles = [obj.muscles,{'All','Quads','Hamstrings','Gastrocs'}];
            defaultMuscle = 'All';
            checkMuscle = @(x) any(validatestring(x,validMuscles));
            defaultFigHandle = figure('NumberTitle','off','Visible','off');
            defaultAxesHandles = axes('Parent',defaultFigHandle);
            p.addRequired('obj',checkObj);
            p.addOptional('muscle',defaultMuscle,checkMuscle);
            p.addOptional('fig_handle',defaultFigHandle);
            p.addOptional('axes_handles',defaultAxesHandles);
            p.parse(obj,varargin{:});
            % Shortcut references to input arguments (and updates)
            fig_handle = p.Results.fig_handle;
            if ~isempty(p.UsingDefaults)                
                set(fig_handle,'Name',['Muscle Forces - ',p.Results.muscle]);
                [axes_handles,mNames] = OpenSim.getAxesAndMuscles(obj,p.Results.muscle);
            else
                axes_handles = p.Results.axes_handles;
                [~,mNames] = OpenSim.getAxesAndMuscles(obj,p.Results.muscle);
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
            function XplotMuscleForces(obj,muscle)
                % XPLOTMUSCLEFORCES
                %
               
                % Plot
                plot((0:100)',obj.muscleForces.(muscle),'Color',[0.75 0 0.25],'LineWidth',2); hold on;
                % Axes properties
                set(gca,'box','off');
                % Set axes limits
                xlim([0 100]);
                % Labels
                title(upper(muscle),'FontWeight','bold');
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
            export(obj.muscleForces,'file',fullfile(obj.subDir,[obj.subID,'_',obj.simName,'_MuscleForces.data']));
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
            % Export ...
            
        end
    end
    
end

