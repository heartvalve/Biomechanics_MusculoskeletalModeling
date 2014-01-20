classdef summary < handle
    % SUMMARY - A class to store all OpenSim data.
    %
    %
    
    % Created by Megan Schroeder
    % Last Modified 2014-01-13
    
    
    %% Properties
    % Properties for the summary class
    
    properties (SetAccess = private)
        Control
        HamstringACL
        PatellaACL
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
            obj.Control = OpenSim.controlGroup();
            obj.HamstringACL = OpenSim.hamstringGroup();
            obj.PatellaACL = OpenSim.patellaGroup();
            % Elapsed time
            eTime = toc;
            disp(['Elapsed summary processing time is ',num2str(floor(eTime/60)),' minutes and ',num2str(round(mod(eTime,60))),' seconds.']);
        end
        % *****************************************************************
        %       Plotting Methods
        % *****************************************************************
        function plotMuscleForces(obj,varargin)
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
            p.addOptional('Cycle',defaultCycle,checkCycle)            
            p.addOptional('Muscle',defaultMuscle,checkMuscle);
            p.addOptional('fig_handle',defaultFigHandle);
            p.addOptional('axes_handles',defaultAxesHandles);
            p.parse(obj,varargin{:});
            % Shortcut references to input arguments
            fig_handle = p.Results.fig_handle;
            if ~isempty(p.UsingDefaults)          
                set(fig_handle,'Name',['Summary Muscle Forces (',p.Results.Muscle,') for ',p.Results.Cycle],'Visible','on');
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
                % Plot all groups
                plot(x,obj.Control.Summary.Mean{Cycle,'Forces'}.(Muscle),'Color','k','LineWidth',3); hold on;
                plot(x,obj.HamstringACL.Summary.Mean{Cycle,'Forces'}.(Muscle),'Color','c','LineWidth',3);
                plot(x,obj.PatellaACL.Summary.Mean{Cycle,'Forces'}.(Muscle),'Color','m','LineWidth',3);
                % Standard Deviation
                plusSDC = obj.Control.Summary.Mean{Cycle,'Forces'}.(Muscle)+obj.Control.Summary.StdDev{Cycle,'Forces'}.(Muscle);
                minusSDC = obj.Control.Summary.Mean{Cycle,'Forces'}.(Muscle)-obj.Control.Summary.StdDev{Cycle,'Forces'}.(Muscle);
                xx = [x' fliplr(x')];
                yy = [plusSDC' fliplr(minusSDC')];
                hFill = fill(xx,yy,[0 0 0]); 
                set(hFill,'EdgeColor','none');
                alpha(0.25);
                plusSDH = obj.HamstringACL.Summary.Mean{Cycle,'Forces'}.(Muscle)+obj.HamstringACL.Summary.StdDev{Cycle,'Forces'}.(Muscle);
                minusSDH = obj.HamstringACL.Summary.Mean{Cycle,'Forces'}.(Muscle)-obj.HamstringACL.Summary.StdDev{Cycle,'Forces'}.(Muscle);
                xx = [x' fliplr(x')];
                yy = [plusSDH' fliplr(minusSDH')];
                hFill = fill(xx,yy,[0 1 1]);
                set(hFill,'EdgeColor','none');
                alpha(0.25);
                plusSDP = obj.PatellaACL.Summary.Mean{Cycle,'Forces'}.(Muscle)+obj.PatellaACL.Summary.StdDev{Cycle,'Forces'}.(Muscle);
                minusSDP = obj.PatellaACL.Summary.Mean{Cycle,'Forces'}.(Muscle)-obj.PatellaACL.Summary.StdDev{Cycle,'Forces'}.(Muscle);
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
                title(upper(Muscle),'FontWeight','bold');
                xlabel({'% Cycle',''});
                ylabel('% Max Isometric Force');
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
                        obj.(groups{i}).(subjects{j}).(simulations{k}).exportMuscleForces();                    
                    end                    
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
