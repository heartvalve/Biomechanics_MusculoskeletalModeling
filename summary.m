classdef summary < handle
    % SUMMARY - A class to store all OpenSim data.
    %
    %
    
    % Created by Megan Schroeder
    % Last Modified 2013-09-19
    
    
    %% Properties
    % Properties for the summary class
    
    properties (SetAccess = private)
        control
        hamstringACL
        patellaACL
    end
    
    
    %% Methods
    % Methods for the summary class
    
    methods
        % *****************************************************************
        %       Constructor Method
        % *****************************************************************
        function obj = summary()
            % SUMMARY - Construct instance of class
            %
            
            % Time
            tic;
            % Add groups as properties
            obj.control = OpenSim.controlGroup();
            obj.hamstringACL = OpenSim.hamstringGroup();
            obj.patellaACL = OpenSim.patellaGroup();
            % Elapsed time
            eTime = toc;
            disp(['Elapsed summary processing time is ',num2str(floor(eTime/60)),' minutes and ',num2str(round(mod(eTime,60))),' seconds.']);
        end
        % *****************************************************************
        %       Plotting Methods
        % *****************************************************************
        function varargout = plotMuscleForces(obj,varargin)
            % PLOTMUSCLEFORCES - Compare between groups for a leg-specific cycle
            %
            
            % Parse inputs
            p = inputParser;
            checkObj = @(x) isa(x,'OpenSim.summary');
            validCycles = {'A_Walk','A_SD2F','A_SD2S','U_Walk','U_SD2F','U_SD2S'};
            defaultCycle = 'A_Walk';
            checkCycle = @(x) any(validatestring(x,validCycles));
            summaryProps = properties(obj);
            groupProps = properties(obj.(summaryProps{1}));
            subProps = properties(obj.(summaryProps{1}).(groupProps{1}));
            simObj = obj.(summaryProps{1}).(groupProps{1}).(subProps{1});
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
                set(fig_handle,'Name',['Summary Muscle Forces (',p.Results.muscle,') for ',p.Results.cycle],'Visible','on');
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
            % Legend
            lStruct = struct;
            axesH = get(axes_handles(1),'Children');
            lStruct.axesHandles = axesH(1:3);
            lStruct.names = {'Control'; 'Hamstring'; 'Patella'};
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
                % Plot all groups
                plot(x,obj.control.summary.mean{cycle,'muscleForces'}.(muscle),'Color','k','LineWidth',3); hold on;
                plot(x,obj.hamstringACL.summary.mean{cycle,'muscleForces'}.(muscle),'Color','c','LineWidth',3);
                plot(x,obj.patellaACL.summary.mean{cycle,'muscleForces'}.(muscle),'Color','m','LineWidth',3);
                % Standard Deviation
                plusSDC = obj.control.summary.mean{cycle,'muscleForces'}.(muscle)+obj.control.summary.stDev{cycle,'muscleForces'}.(muscle);
                minusSDC = obj.control.summary.mean{cycle,'muscleForces'}.(muscle)-obj.control.summary.stDev{cycle,'muscleForces'}.(muscle);
                xx = [x' fliplr(x')];
                yy = [plusSDC' fliplr(minusSDC')];
                hFill = fill(xx,yy,[0 0 0]); 
                set(hFill,'EdgeColor','none');
                alpha(0.25);
                plusSDH = obj.hamstringACL.summary.mean{cycle,'muscleForces'}.(muscle)+obj.hamstringACL.summary.stDev{cycle,'muscleForces'}.(muscle);
                minusSDH = obj.hamstringACL.summary.mean{cycle,'muscleForces'}.(muscle)-obj.hamstringACL.summary.stDev{cycle,'muscleForces'}.(muscle);
                xx = [x' fliplr(x')];
                yy = [plusSDH' fliplr(minusSDH')];
                hFill = fill(xx,yy,[0 1 1]);
                set(hFill,'EdgeColor','none');
                alpha(0.25);
                plusSDP = obj.patellaACL.summary.mean{cycle,'muscleForces'}.(muscle)+obj.patellaACL.summary.stDev{cycle,'muscleForces'}.(muscle);
                minusSDP = obj.patellaACL.summary.mean{cycle,'muscleForces'}.(muscle)-obj.patellaACL.summary.stDev{cycle,'muscleForces'}.(muscle);
                xx = [x' fliplr(x')];
                yy = [plusSDP' fliplr(minusSDP')];
                hFill = fill(xx,yy,[1 0 1]);
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
        % *****************************************************************
        %       Export for Abaqus
        % *****************************************************************
        function exportAbaqus(obj)
            % EXPORTABAQUS
            %

            % Parse inputs
            p = inputParser;
            checkObj = @(x) isa(x,'OpenSim.summary');
            p.addRequired('obj',checkObj);
            p.parse(obj);
            % Invoke the method for all of the simulations
            groups = properties(obj);
            checkGroups = @(x) isa(obj.(x{1}),'OpenSim.group');
            groups(~arrayfun(checkGroups,groups)) = [];
            for i = 1:length(groups)
                subjects = properties(obj.(groups{i}));
                checkSubjects = @(x) isa(obj.(groups{i}).(x{1}),'OpenSim.subject');
                subjects(~arrayfun(checkSubjects,subjects)) = [];
                for j = 1:length(subjects)
                    simulations = properties(obj.(groups{i}).(subjects{j}));
                    checkSimulations = @(x) isa(obj.(groups{i}).(subjects{j}).(x{1}),'OpenSim.simulation');
                    simulations(~arrayfun(checkSimulations,simulations)) = [];
                    for k = 1:length(simulations)
                        obj.(groups{i}).(subjects{j}).(simulations{k}).exportOpenSim();                    
                    end                    
                end
            end            
        end
    end
    
end
