classdef simulation < handle
    % SIMULATION - A class to store an OpenSim modeling simulation.
    %
    %
    
    % Created by Megan Schroeder
    % Last Modified 2013-09-05
    
    
    %% Properties
    % Properties for the simulation class
    
    properties (SetAccess = private)        
        subID           % Subject ID
        simName         % Simulation name
        model           % Generic model
        muscles         % Muscle names
        leg             % Cycle leg
        trc             % Marker data - input to simulation
        grf             % Ground Reaction Force data - input to simulation
        ik              % Inverse Kinematics solution
        id              % Inverse Dynamics solution
        rra             % Residual Reduction Algorithm solution
        cmc             % Computed Muscle Control solution
        muscleForces    % Muscle forces (summarized from CMC)
    end
    properties (Hidden = true, SetAccess = private)
        subDir          % Directory where files are stored
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
            % Interpolate muscle forces over normalized time window
            xi = linspace(obj.grf.cycleTime(1),obj.grf.cycleTime(2),101);
            iForces = zeros(101,length(obj.muscles));
            for i = 1:length(obj.muscles)
                try
                    iForces(:,i) = interp1(obj.cmc.actuation.force.time, obj.cmc.actuation.force.([obj.muscles{i},'_',obj.leg]), xi, 'spline');
                catch err
                    iForces = nan(101,length(obj.muscles));
                    break
                end
            end
            mForces = dataset({iForces,obj.muscles{:}});
            obj.muscleForces = mForces;
        end
        % *****************************************************************
        %       Plotting Methods
        % *****************************************************************
        function plotResiduals(obj,fig_handle,axes_handles)
            % PLOTRESIDUALS
            %
            
            % Defaults & error checking
            if nargin ~= 3
                fig_handle = figure('Name','Residuals','NumberTitle','off');
                axes_handles = zeros(1,6);
                for k = 1:6
                    axes_handles(k) = subplot(3,2,k);
                end
            end
            % Residuals
            rNames = {'FX','MX','FY','MY','FZ','MZ'};
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
                % Focus on cycle region
                temp = abs(obj.rra.actuation.force.time-obj.grf.cycleTime(1));
                [~,iStart] = min(temp);
                temp = abs(obj.rra.actuation.force.time-obj.grf.cycleTime(2));
                [~,iStop] = min(temp);
                % Average
                plot([obj.rra.actuation.force.time(iStart) obj.rra.actuation.force.time(iStop)],...
                     [mean(obj.rra.actuation.force.(residual)(iStart:iStop)) mean(obj.rra.actuation.force.(residual)(iStart:iStop))],...
                     'Color','r','LineWidth',2);
                % RMS
% %                 plot([obj.rra.actuation.force.time(iStart) obj.rra.actuation.force.time(iStop)],...
% %                      [rms(obj.rra.actuation.force.(residual)(iStart:iStop)) rms(obj.rra.actuation.force.(residual)(iStart:iStop))],...
% %                      'Color','g','LineWidth',2);
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
            % Shortcut references to input arguments
            fig_handle = p.Results.fig_handle;
            if ~isempty(p.UsingDefaults)                
                set(fig_handle,'Name',['Muscle Forces - ',p.Results.muscle],'Visible','on');
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
            if strcmp(p.Results.muscle,'All')
                set(fig_handle,'CurrentAxes',subplot(3,4,11:12));
                set(gca,'Visible','off');
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
        %       Export for Abaqus
        % *****************************************************************
% %         function exportAbaqus(obj)
% %             % EXPORTABAQUS
% %             %
% %                        
% %             
% %         end
    end
    
end

