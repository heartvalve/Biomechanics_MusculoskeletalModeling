classdef summary < handle
    % SUMMARY - A class to store all OpenSim data.
    %
    %
    
    % Created by Megan Schroeder
    % Last Modified 2014-03-24
    
    
    %% Properties
    % Properties for the summary class
    
    properties (SetAccess = private)
        Control             % Control group        
        HamstringACL        % Hamstring tendon ACL-R
        PatellaACL          % Patella tendon ACL-R
    end
    properties (SetAccess = public)
        Statistics          % Group comparison statistics
        Tables              % Residuals, Reserves, Position Errors
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
            disp('Please wait while the program runs -- it may take a few minutes.');
            % Add groups as properties
            obj.Control = OpenSim.controlGroup();
            obj.HamstringACL = OpenSim.hamstringGroup();
            obj.PatellaACL = OpenSim.patellaGroup();
            % --------------------
            obj.Statistics = OpenSim.getSummaryStatistics(obj);
            obj.Tables = OpenSim.getSummaryTables(obj);
            % --------------------
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
            validCycles = {'A_Walk','A_SD2F','A_SD2S'};
            defaultCycle = 'A_Walk';
            checkCycle = @(x) any(validatestring(x,validCycles));
            defaultFigHandle = figure('NumberTitle','off','Visible','off');
            defaultAxesHandles = axes('Parent',defaultFigHandle);
            p.addRequired('obj',checkObj);            
            p.addOptional('Cycle',defaultCycle,checkCycle)
            p.addOptional('fig_handle',defaultFigHandle);
            p.addOptional('axes_handles',defaultAxesHandles);
            p.parse(obj,varargin{:});
            % Shortcut references to input arguments
            fig_handle = p.Results.fig_handle;
            if ~isempty(p.UsingDefaults)          
                set(fig_handle,'Name',['Muscle Forces Task ',p.Results.Cycle(3:end)],'Visible','on');
                axes_handles = zeros(1,9);
                for k = 1:9
                    axes_handles(k) = subplot(3,3,k);
                end
            else
                axes_handles = p.Results.axes_handles;                
            end
            % Muscle names
            mNames = {'vasmed','vaslat','vasint',...
                      'semimem','semiten','bflh',...
                      'recfem','gasmed','gaslat'};                      
            % Plot
            figure(fig_handle);
            for j = 1:length(mNames)
                set(fig_handle,'CurrentAxes',axes_handles(j));
                XplotMuscleForces(obj,p.Results.Cycle,mNames{j});
            end
%             % Update y limits and plot statistics
%             for j = 1:length(mNames)
%                 set(fig_handle,'CurrentAxes',axes_handles(j));
%                 yLim = get(gca,'YLim');
%                 yTick = get(gca,'YTick');
%                 yNewMax = yLim(2)+0.9*(yTick(2)-yTick(1));
%                 yNewMin = yLim(1)-0.5*(yTick(2)-yTick(1));
%                 set(gca,'YLim',[yNewMin,yNewMax]);                    
%                 XplotStatisticsMF(obj,[yLim(2) yNewMax],'Forces',p.Results.Cycle,mNames{j});
%                 XlabelRegions([yNewMin yLim(1)]);                
%             end
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
                plot(x,obj.Control.Summary.Mean{Cycle,'Forces'}.(Muscle),'Color',[0.15 0.15 0.15],'LineWidth',3); hold on;
                plot(x,obj.HamstringACL.Summary.Mean{Cycle,'Forces'}.(Muscle),'Color','m','LineWidth',3,'LineStyle','--');
                plot(x,obj.PatellaACL.Summary.Mean{Cycle,'Forces'}.(Muscle),'Color',[0 0.5 1],'LineWidth',3,'LineStyle',':');
                % Standard Deviation
                plusSDC = obj.Control.Summary.Mean{Cycle,'Forces'}.(Muscle)+obj.Control.Summary.StdDev{Cycle,'Forces'}.(Muscle);
                minusSDC = obj.Control.Summary.Mean{Cycle,'Forces'}.(Muscle)-obj.Control.Summary.StdDev{Cycle,'Forces'}.(Muscle);
                minusSDC(minusSDC < 0.001) = 0.001;
                plusSDH = obj.HamstringACL.Summary.Mean{Cycle,'Forces'}.(Muscle)+obj.HamstringACL.Summary.StdDev{Cycle,'Forces'}.(Muscle);
                minusSDH = obj.HamstringACL.Summary.Mean{Cycle,'Forces'}.(Muscle)-obj.HamstringACL.Summary.StdDev{Cycle,'Forces'}.(Muscle);
                minusSDH(minusSDH < 0.001) = 0.001;
                plusSDP = obj.PatellaACL.Summary.Mean{Cycle,'Forces'}.(Muscle)+obj.PatellaACL.Summary.StdDev{Cycle,'Forces'}.(Muscle);
                minusSDP = obj.PatellaACL.Summary.Mean{Cycle,'Forces'}.(Muscle)-obj.PatellaACL.Summary.StdDev{Cycle,'Forces'}.(Muscle);
                minusSDP(minusSDP < 0.001) = 0.001;
                % Standard Deviation Lines
                plot(x,plusSDC,'Color',[0.15 0.15 0.15]);
                plot(x,minusSDC,'Color',[0.15 0.15 0.15]);
                plot(x,plusSDH,'m--');
                plot(x,minusSDH,'m--');
                plot(x,plusSDP,'Color',[0 0.5 1],'LineStyle',':');
                plot(x,minusSDH,'Color',[0 0.5 1],'LineStyle',':');                
                % Standard Deviation Fill
                xx = [x' fliplr(x')];
                yyC = [plusSDC' fliplr(minusSDC')];
                hFill = fill(xx,yyC,[0.15 0.15 0.15]); 
                set(hFill,'EdgeColor','none');
                alpha(0.25);
                yyH = [plusSDH' fliplr(minusSDH')];
                hFill = fill(xx,yyH,[1 0 1]);
                set(hFill,'EdgeColor','none');
                alpha(0.25);               
                yyP = [plusSDP' fliplr(minusSDP')];
                % hFill = fill(xx,yyP,[0 1 1]);  % cyan
                hFill = fill(xx,yyP,[0 0.5 1]);
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
                if strcmp(Muscle,'vasmed')
                    mLabel = 'Vastus Medialis';
                elseif strcmp(Muscle,'vaslat')
                    mLabel = 'Vastus Lateralis';
                elseif strcmp(Muscle,'vasint')
                    mLabel = 'Vastus Intermedius';
                elseif strcmp(Muscle,'recfem')
                    mLabel = 'Rectus Femoris';
                elseif strcmp(Muscle,'semimem')
                    mLabel = 'Semimembranosus';
                elseif strcmp(Muscle,'semiten')
                    mLabel = 'Semitendinosus';
                elseif strcmp(Muscle,'bflh')
                    mLabel = 'Biceps Femoris';
                elseif strcmp(Muscle,'gasmed')
                    mLabel = 'Medial Gastrocnemius';
                elseif strcmp(Muscle,'gaslat')
                    mLabel = 'Lateral Gastrocnemius';
                end
                title(mLabel,'FontWeight','bold');
                if strcmp(Muscle,'recfem') || strcmp(Muscle,'gasmed') || strcmp(Muscle,'gaslat')
                    xlabel('% Stance');
                end
                if strcmp(Muscle,'vasmed') || strcmp(Muscle,'semimem') || strcmp(Muscle,'recfem')
                    ylabel('Force (N/Fmax)');
                end
            end            
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function plotSummaryForces(obj,varargin)
            % PLOTSUMMARYFORCES
            %
            
            % Parse inputs
            p = inputParser;
            checkObj = @(x) isa(x,'OpenSim.summary');            
            validMuscles = {'Quads','Hams','Gast'};
            defaultMuscle = 'Quads';
            checkMuscle = @(x) any(validatestring(x,validMuscles));
            validCycles = {'Walk','SD2F','SD2S'};
            defaultCycle = 'Walk';
            checkCycle = @(x) any(validatestring(x,validCycles));
            defaultFigHandle = figure('NumberTitle','off','Visible','off');
            defaultAxesHandles = axes('Parent',defaultFigHandle);
            p.addRequired('obj',checkObj);            
            p.addOptional('Muscle',defaultMuscle,checkMuscle);
            p.addOptional('Cycle',defaultCycle,checkCycle);
            p.addOptional('fig_handle',defaultFigHandle);
            p.addOptional('axes_handles',defaultAxesHandles);
            p.parse(obj,varargin{:});
            % Muscles
            if strcmp(p.Results.Muscle,'Quads')
%                 numMuscles = 4;
%                 muscleNames = {'vasmed','vaslat','vasint','recfem'};
                numMuscles = 3;
                muscleNames = {'vasmed','vaslat','recfem'};
            elseif strcmp(p.Results.Muscle,'Hams')
%                 numMuscles = 4;
%                 muscleNames = {'semimem','semiten','bflh','bfsh'};
                numMuscles = 3;
                muscleNames = {'semimem','semiten','bflh'};
            elseif strcmp(p.Results.Muscle,'Gast')
                numMuscles = 2;
                muscleNames = {'gasmed','gaslat'};
            end
            % Shortcut references to input arguments
            fig_handle = p.Results.fig_handle;
            if ~isempty(p.UsingDefaults)  
                set(fig_handle,'Name',['Muscle Forces Group ',p.Results.Muscle,' ',p.Results.Cycle],'Visible','on');                
                axes_handles = zeros(1,numMuscles*2);
                for k = 1:numMuscles*2
                    axes_handles(k) = subplot(2,numMuscles,k);
                end
            else
                axes_handles = p.Results.axes_handles;
            end
            % Plot
            figure(fig_handle);
            typeNames = {'Patella','Hamstring'};
            for k = 1:2
                for j = 1:numMuscles
                    set(fig_handle,'CurrentAxes',axes_handles(numMuscles*(k-1)+j));
                    XplotSummaryForces(obj,p.Results.Cycle,muscleNames{j},typeNames{k});
                end
            end
            % Update y limits and plot statistics
            for j = 1:numMuscles
                set(fig_handle,'CurrentAxes',axes_handles(numMuscles*(k-1)+j));
                yLim = get(gca,'YLim');
                yTick = get(gca,'YTick');
                yNewMax = yLim(2)+0.9*(yTick(2)-yTick(1));
                yNewMin = yLim(1)-0.5*(yTick(2)-yTick(1));
                for k = 1:2
                    set(fig_handle,'CurrentAxes',axes_handles(numMuscles*(k-1)+j));
                    set(gca,'YLim',[yNewMin,yNewMax]);
                    XplotStatistics(obj,[yLim(2) yNewMax],typeNames{k},'Forces',p.Results.Cycle,muscleNames{j});
                    XlabelRegions([yNewMin yLim(1)]);
                end
            end
            % -------------------------------------------------------------
            %   Subfunction
            % -------------------------------------------------------------
            function XplotSummaryForces(obj,Cycle,Muscle,Graft)
                % XPLOTSUMMARYFORCES
                %

                % Colors
                if strcmp(Graft,'Hamstring')
                    ColorA = [237 17 100]/255;
                    ColorU = [47 180 74]/255;
                elseif strcmp(Graft,'Patella')
                    ColorA = [228 70 37]/255;
                    ColorU = [34 189 189]/255;
                end
                ColorC = [0.15 0.15 0.15];
                % X vector
                x = (0:100)';
                % Plot                    
                plot(x,obj.([Graft,'ACL']).Summary.Mean{['U_',Cycle],'Forces'}.(Muscle),'Color',ColorU,'LineWidth',3,'LineStyle',':'); hold on;
                plot(x,obj.([Graft,'ACL']).Summary.Mean{['A_',Cycle],'Forces'}.(Muscle),'Color',ColorA,'LineWidth',3,'LineStyle','--');
                plot(x,obj.Control.AvgSummary.Mean{Cycle,'Forces'}.(Muscle),'Color',ColorC,'LineWidth',3);                
                % Reverse children order (so mean is on top and shaded region is in back)
                set(gca,'Children',flipud(get(gca,'Children')));
                % Axes properties
                set(gca,'Box','off');
                % Set axes limits
                xlim([0 100]);
                ydefault = get(gca,'YLim');
                ylim([0 ydefault(2)]);
                if strcmp(Muscle,'vasmed')
                    mLabel = 'Vastus Medialis';
%                     ylim([0 0.35]);
                elseif strcmp(Muscle,'vaslat')
                    mLabel = 'Vastus Lateralis';
%                     ylim([0 0.45]);
                elseif strcmp(Muscle,'recfem')
                    mLabel = 'Rectus Femoris';
%                     ylim([0 0.9]);
                elseif strcmp(Muscle,'semimem')
                    mLabel = 'Semimembranosus';
%                     ylim([0 0.4]);
                elseif strcmp(Muscle,'semiten')
                    mLabel = 'Semitendinosus';
%                     ylim([0 0.35]);
                elseif strcmp(Muscle,'bflh')
                    mLabel = 'Biceps Femoris';
%                     ylim([0 0.35]);
                elseif strcmp(Muscle,'gasmed')
                    mLabel = 'Medial Gastroc';
%                     ylim([0 0.8]);
                elseif strcmp(Muscle,'gaslat')
                    mLabel = 'Lateral Gastroc';
                    if strcmp(Cycle,'Walk')
                        ylim([0 0.55]);
                    elseif strcmp(Cycle,'SD2S')
                        ylim([0 0.25]);
                    end
                end
                % Labels
                if strcmp(Graft,'Hamstring')
                    xlabel('% Stance');
                end               
                if strcmp(Muscle,'vasmed') || strcmp(Muscle,'semimem') || strcmp(Muscle,'gasmed')
                    ylabel('Force (N/Fmax)');
                end
                % Title
                if strcmp(Graft,'Patella')
                    title(mLabel,'FontWeight','bold');
                end
            end            
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function plotGraftForces(obj,varargin)
            % PLOTGRAFTFORCES
            %
            
            % Parse inputs
            p = inputParser;
            checkObj = @(x) isa(x,'OpenSim.summary');            
            validMuscles = {'vasmed','vaslat','vasint','recfem',...
                            'semimem','semiten','bflh','bfsh',...
                            'gasmed','gaslat'};
            defaultMuscle = 'vasmed';
            checkMuscle = @(x) any(validatestring(x,validMuscles));
            defaultFigHandle = figure('NumberTitle','off','Visible','off');
            defaultAxesHandles = axes('Parent',defaultFigHandle);
            p.addRequired('obj',checkObj);
            p.addOptional('Muscle',defaultMuscle,checkMuscle);
            p.addOptional('fig_handle',defaultFigHandle);
            p.addOptional('axes_handles',defaultAxesHandles);
            p.parse(obj,varargin{:});
            % Shortcut references to input arguments
            fig_handle = p.Results.fig_handle;
            if ~isempty(p.UsingDefaults)
                if strcmp(p.Results.Muscle,'vasmed')
                    mName = 'Vastus Medialis';
                elseif strcmp(p.Results.Muscle,'vaslat')
                    mName = 'Vastus Lateralis';
                elseif strcmp(p.Results.Muscle,'vasint')
                    mName = 'Vastus Intermedius';
                elseif strcmp(p.Results.Muscle,'recfem')
                    mName = 'Rectus Femoris';
                elseif strcmp(p.Results.Muscle,'semimem')
                    mName = 'Semimembranosus';
                elseif strcmp(p.Results.Muscle,'semiten')
                    mName = 'Semitendinosus';
                elseif strcmp(p.Results.Muscle,'bflh')
                    mName = 'Biceps Fem LH';
                elseif strcmp(p.Results.Muscle,'bfsh')
                    mName = 'Biceps Fem SH';
                elseif strcmp(p.Results.Muscle,'gasmed')
                    mName = 'Medial Gastroc';
                elseif strcmp(p.Results.Muscle,'gaslat')
                    mName = 'Lateral Gastroc';
                end                                
                set(fig_handle,'Name',['Muscle Forces Avg ',mName],'Visible','on');
                axes_handles = zeros(1,2*3);
                for k = 1:2*3
                    axes_handles(k) = subplot(2,3,k);
                end
            else
                axes_handles = p.Results.axes_handles;
            end
            % Plot
            figure(fig_handle);
            typeNames = {'Patella','Hamstring'};
            cycleNames = {'Walk','SD2F','SD2S'};
            for k = 1:3
                for j = 1:2
                    set(fig_handle,'CurrentAxes',axes_handles(3*(j-1)+k));
                    XplotGraftForces(obj,cycleNames{k},typeNames{j},p.Results.Muscle);
                end
            end
            % Update y limits and plot statistics
            for j = 1:2
                set(fig_handle,'CurrentAxes',axes_handles(3*(j-1)+1));
                yLim = get(gca,'YLim');
                yTick = get(gca,'YTick');
                yNewMax = yLim(2)+0.9*(yTick(2)-yTick(1));
                yNewMin = yLim(1)-0.5*(yTick(2)-yTick(1));
                for k = 1:3
                    set(fig_handle,'CurrentAxes',axes_handles(3*(j-1)+k));
                    set(gca,'YLim',[yNewMin,yNewMax]);                    
                    XplotStatistics(obj,[yLim(2) yNewMax],typeNames{j},'Forces',cycleNames{k},p.Results.Muscle);
                    XlabelRegions([yNewMin yLim(1)]);
                end
            end
            % -------------------------------------------------------------
            %   Subfunction
            % -------------------------------------------------------------
            function XplotGraftForces(obj,Cycle,Type,Muscle)
                % XPLOTSUMMARYFORCES
                %

                % Colors
                ColorHA = [237 17 100]/255;
                ColorHU = [47 180 74]/255;
                ColorPA = [228 70 37]/255;
                ColorPU = [34 189 189]/255;
                ColorC = [0.15 0.15 0.15];
                % X vector
                x = (0:100)';
                % Plot
                if strcmp(Type,'Hamstring')
                    plot(x,obj.HamstringACL.Summary.Mean{['U_',Cycle],'AvgForces'}.(Muscle),'Color',ColorHU,'LineWidth',3,'LineStyle',':'); hold on;
                    plot(x,obj.HamstringACL.Summary.Mean{['A_',Cycle],'AvgForces'}.(Muscle),'Color',ColorHA,'LineWidth',3,'LineStyle','--');
                    plot(x,obj.Control.AvgSummary.Mean{Cycle,'AvgForces'}.(Muscle),'Color',ColorC,'LineWidth',3);
                elseif strcmp(Type,'Patella')
                    plot(x,obj.PatellaACL.Summary.Mean{['U_',Cycle],'AvgForces'}.(Muscle),'Color',ColorPU,'LineWidth',3,'LineStyle',':'); hold on;
                    plot(x,obj.PatellaACL.Summary.Mean{['A_',Cycle],'AvgForces'}.(Muscle),'Color',ColorPA,'LineWidth',3,'LineStyle','--');
                    plot(x,obj.Control.AvgSummary.Mean{Cycle,'AvgForces'}.(Muscle),'Color',ColorC,'LineWidth',3);                
                end
                % Reverse children order (so mean is on top and shaded region is in back)
                set(gca,'Children',flipud(get(gca,'Children')));
                % Axes properties
                set(gca,'Box','off');
                % Set axes limits
                xlim([0 100]);
                ydefault = get(gca,'YLim');
                ylim([0 ydefault(2)]);
                if strcmp(Muscle,'vasmed')
                    mLabel = 'Vastus Medialis';
                    ylim([0 0.35]);
                elseif strcmp(Muscle,'vaslat')
                    mLabel = 'Vastus Lateralis';
                    ylim([0 0.45]);
                elseif strcmp(Muscle,'vasint')
                    mLabel = 'Vastus Int';
                    ylim([0 0.35]);
                elseif strcmp(Muscle,'recfem')
                    mLabel = 'Rectus Fem';
                    ylim([0 0.9]);
                elseif strcmp(Muscle,'semimem')
                    mLabel = 'Semimem';
                    ylim([0 0.4]);
                elseif strcmp(Muscle,'semiten')
                    mLabel = 'Semiten';
                    ylim([0 0.7]);
                elseif strcmp(Muscle,'bflh')
                    mLabel = 'Biceps Fem LH';
                    ylim([0 0.35]);
                elseif strcmp(Muscle,'bfsh')
                    mLabel = 'Biceps Fem SH';
                    ylim([0 0.45]);
                elseif strcmp(Muscle,'gasmed')
                    mLabel = 'Medial Gastroc';
                    ylim([0 0.8]);
                elseif strcmp(Muscle,'gaslat')
                    mLabel = 'Lateral Gastroc';
                    ylim([0 0.55]);
                end
                % Labels
                if strcmp(Type,'Hamstring')
                    xlabel('% Stance');
                end               
                if strcmp(Cycle,'Walk')
                    ylabel({['\bf',mLabel],'\rmForce (N/Fmax)'});
                end
                % Title
                if strcmp(Type,'Patella')
                    if strcmp(Cycle,'Walk')
                        title('Walk','FontWeight','bold');
                    elseif strcmp(Cycle,'SD2F');
                        title('Stair Descent (To Floor)','FontWeight','bold');
                    elseif strcmp(Cycle,'SD2S');
                        title('Stair Descent (To Step)','FontWeight','bold');
                    end
                end
            end            
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function troubleshoot(obj,varargin)
            % TROUBLESHOOT
            %
            
            % Parse inputs
            p = inputParser;
            checkObj = @(x) isa(x,'OpenSim.summary');            
            validMuscles = {'vasmed','vaslat','vasint','recfem',...
                            'semimem','semiten','bflh','bfsh',...
                            'gasmed','gaslat'};
            defaultMuscle = 'vasmed';
            checkMuscle = @(x) any(validatestring(x,validMuscles));
            defaultFigHandle = figure('NumberTitle','off','Visible','off');
            defaultAxesHandles = axes('Parent',defaultFigHandle);
            p.addRequired('obj',checkObj);
            p.addOptional('Muscle',defaultMuscle,checkMuscle);
            p.addOptional('fig_handle',defaultFigHandle);
            p.addOptional('axes_handles',defaultAxesHandles);
            p.parse(obj,varargin{:});
            % Shortcut references to input arguments
            fig_handle = p.Results.fig_handle;
            if ~isempty(p.UsingDefaults)
                if strcmp(p.Results.Muscle,'vasmed')
                    mName = 'Vastus Medialis';
                elseif strcmp(p.Results.Muscle,'vaslat')
                    mName = 'Vastus Lateralis';
                elseif strcmp(p.Results.Muscle,'vasint')
                    mName = 'Vastus Intermedius';
                elseif strcmp(p.Results.Muscle,'recfem')
                    mName = 'Rectus Femoris';
                elseif strcmp(p.Results.Muscle,'semimem')
                    mName = 'Semimembranosus';
                elseif strcmp(p.Results.Muscle,'semiten')
                    mName = 'Semitendinosus';
                elseif strcmp(p.Results.Muscle,'bflh')
                    mName = 'Biceps Fem LH';
                elseif strcmp(p.Results.Muscle,'bfsh')
                    mName = 'Biceps Fem SH';
                elseif strcmp(p.Results.Muscle,'gasmed')
                    mName = 'Medial Gastroc';
                elseif strcmp(p.Results.Muscle,'gaslat')
                    mName = 'Lateral Gastroc';
                end                                
                set(fig_handle,'Name',['Muscle Forces Avg ',mName],'Visible','on');
                axes_handles = zeros(1,2*3);
                for k = 1:2*3
                    axes_handles(k) = subplot(2,3,k);
                end
            else
                axes_handles = p.Results.axes_handles;
            end
            % Plot
            figure(fig_handle);
            typeNames = {'Patella','Hamstring'};
            cycleNames = {'Walk','SD2F','SD2S'};
            for k = 1:3
                for j = 1:2
                    set(fig_handle,'CurrentAxes',axes_handles(3*(j-1)+k));
                    Xtroubleshoot(obj,cycleNames{k},typeNames{j},p.Results.Muscle);
                end
            end
            % Update y limits and plot statistics
            for j = 1:2
                set(fig_handle,'CurrentAxes',axes_handles(3*(j-1)+1));
                yLim = get(gca,'YLim');
                yTick = get(gca,'YTick');
                yNewMax = yLim(2)+0.9*(yTick(2)-yTick(1));
                yNewMin = yLim(1)-0.5*(yTick(2)-yTick(1));
                for k = 1:3
                    set(fig_handle,'CurrentAxes',axes_handles(3*(j-1)+k));
                    set(gca,'YLim',[yNewMin,yNewMax]);                    
                    XplotStatistics(obj,[yLim(2) yNewMax],typeNames{j},'Forces',cycleNames{k},p.Results.Muscle);
                    XlabelRegions([yNewMin yLim(1)]);
                end
            end
            % -------------------------------------------------------------
            %   Subfunction
            % -------------------------------------------------------------
            function Xtroubleshoot(obj,Cycle,Type,Muscle)
                % XTROUBLESHOOT
                %

                % Colors
                ColorHA = [237 17 100]/255;
                ColorHU = [47 180 74]/255;
                ColorPA = [228 70 37]/255;
                ColorPU = [34 189 189]/255;
                ColorC = [0.15 0.15 0.15];
                % X vector
                x = (0:100)';
                % Plot
                if strcmp(Type,'Hamstring')
                    plot(x,obj.HamstringACL.Cycles{['U_',Cycle],'AvgForces'}.(Muscle),'Color',ColorHU,'LineWidth',1,'LineStyle',':'); hold on;
                    plot(x,obj.HamstringACL.Cycles{['A_',Cycle],'AvgForces'}.(Muscle),'Color',ColorHA,'LineWidth',1,'LineStyle','--');
                    plot(x,obj.Control.AvgCycles{Cycle,'AvgForces'}.(Muscle),'Color',ColorC,'LineWidth',1);
                elseif strcmp(Type,'Patella')
                    plot(x,obj.PatellaACL.Cycles{['U_',Cycle],'AvgForces'}.(Muscle),'Color',ColorPU,'LineWidth',1,'LineStyle',':'); hold on;
                    plot(x,obj.PatellaACL.Cycles{['A_',Cycle],'AvgForces'}.(Muscle),'Color',ColorPA,'LineWidth',1,'LineStyle','--');
                    plot(x,obj.Control.AvgCycles{Cycle,'AvgForces'}.(Muscle),'Color',ColorC,'LineWidth',1);                
                end
                % Reverse children order (so mean is on top and shaded region is in back)
                set(gca,'Children',flipud(get(gca,'Children')));
                % Axes properties
                set(gca,'Box','off');
                % Set axes limits
                xlim([0 100]);
                ydefault = get(gca,'YLim');
                ylim([0 ydefault(2)]);
                if strcmp(Muscle,'vasmed')
                    mLabel = 'Vastus Medialis';
                    ylim([0 80]);
                elseif strcmp(Muscle,'vaslat')
                    mLabel = 'Vastus Lateralis';
                    ylim([0 200]);
                elseif strcmp(Muscle,'vasint')
                    mLabel = 'Vastus Int';
                    ylim([0 60]);
                elseif strcmp(Muscle,'recfem')
                    mLabel = 'Rectus Fem';
                    ylim([0 200]);
                elseif strcmp(Muscle,'semimem')
                    mLabel = 'Semimem';
                    ylim([0 100]);
                elseif strcmp(Muscle,'semiten')
                    mLabel = 'Semiten';
                    ylim([0 50]);
                elseif strcmp(Muscle,'bflh')
                    mLabel = 'Biceps Fem LH';
                    ylim([0 40]);
                elseif strcmp(Muscle,'bfsh')
                    mLabel = 'Biceps Fem SH';
                    ylim([0 30]);
                elseif strcmp(Muscle,'gasmed')
                    mLabel = 'Medial Gastroc';
                    ylim([0 200]);
                elseif strcmp(Muscle,'gaslat')
                    mLabel = 'Lateral Gastroc';
                    ylim([0 70]);
                end
                % Labels
                if strcmp(Type,'Hamstring')
                    xlabel('% Stance');
                end               
                if strcmp(Cycle,'Walk')
                    ylabel({['\bf',mLabel],'\rmForce (N/F_max)'});
                end
                % Title
                if strcmp(Type,'Patella')
                    if strcmp(Cycle,'Walk')
                        title('Walk','FontWeight','bold');
                    elseif strcmp(Cycle,'SD2F');
                        title('Stair Descent (To Floor)','FontWeight','bold');
                    elseif strcmp(Cycle,'SD2S');
                        title('Stair Descent (To Step)','FontWeight','bold');
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


%% Subfunctions
% Subfunctions called from the main class definition

function [labelX,labelpoints] = XgetStatLabels(endX,endpoints,yvalues)
    % XGETSTATLABELS
    %

    % Get rid of NaNs
    endpoints(isnan(endX)) = [];
    endX(isnan(endX)) = [];
    % Preallocate
    labelX = NaN(size(endX));   
    labelpoints = yvalues*ones(size(endX));
    % Add values    
    if ~isempty(endX)
        % Midpoints of pairs
        if ~isempty(endX)
            midX = endX(1:end-1)+diff(endX)/2;
            midX = midX(1:2:end);
            labelX(strcmp('L',endpoints)) = midX;
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function XlabelRegions(yPos)
    % XLABELREGIONS

    % Plot region dividers as vertical lines    
    text(23,yPos(1),'I','Color',[0 0 0],'HorizontalAlignment','center','VerticalAlignment','baseline','Tag','RegionDiv');
    text(50,yPos(1),'I','Color',[0 0 0],'HorizontalAlignment','center','VerticalAlignment','baseline','Tag','RegionDiv');
    text(77,yPos(1),'I','Color',[0 0 0],'HorizontalAlignment','center','VerticalAlignment','baseline','Tag','RegionDiv');
    % Label regions
    labelPos = yPos(1)+0.25*(yPos(2)-yPos(1));
    text(11.5,labelPos,'LR','Color',[0 0 0],'HorizontalAlignment','center','VerticalAlignment','baseline','Tag','RegionLabel');
    text(36.5,labelPos,'MS','Color',[0 0 0],'HorizontalAlignment','center','VerticalAlignment','baseline','Tag','RegionLabel');
    text(63.5,labelPos,'TS','Color',[0 0 0],'HorizontalAlignment','center','VerticalAlignment','baseline','Tag','RegionLabel');
    text(88.5,labelPos,'PS','Color',[0 0 0],'HorizontalAlignment','center','VerticalAlignment','baseline','Tag','RegionLabel');
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function XplotStatistics(obj,yPos,Type,varType,Cycle,varargin)
    % XPLOTSTATISTICS
    %

    % Colors
%     Color1 = [1 0 0.6];
%     Color2 = [0 0.5 1];
    Color3 = [0.4 0.2 0.6];
    % Plot Type    
    if strcmp(Type,'Patella')
        Color1 = [228 70 37]/255;
        Color2 = [34 189 189]/255;
        stats = [obj.Statistics.CtoP{['A_',Cycle],varType}.(varargin{1}), ...
                 obj.Statistics.CtoP{['U_',Cycle],varType}.(varargin{1}), ...
                 obj.Statistics.AtoU_P{Cycle,varType}.(varargin{1})];
    elseif strcmp(Type,'Hamstring') 
        Color1 = [237 17 100]/255;
        Color2 = [47 180 74]/255;
        stats = [obj.Statistics.CtoH{['A_',Cycle],varType}.(varargin{1}), ...
                 obj.Statistics.CtoH{['U_',Cycle],varType}.(varargin{1}), ...
                 obj.Statistics.AtoU_H{Cycle,varType}.(varargin{1})];       
    end    
    % Prepare line positions
    yvalues = yPos(1)+(yPos(2)-yPos(1))*[0.7 0.4 0.1];
    % Significant results are when 'stats' = 1
    sig = stats;
    sig(sig == 0) = NaN;
    for i = 1:3
        sig(sig(:,i) == 1,i) = yvalues(i);
    end    
    % Find endpoints of lines
    endpoints = cell(size(stats));
    endlines = NaN(size(stats));
    for i = 1:3
        diffV = diff([0; stats(:,i); 0]);
        transitions = find(diffV);
        for j = 1:length(transitions)
            if diffV(transitions(j)) == 1
                endpoints{transitions(j),i} = 'L';
                endlines(transitions(j),i) = yvalues(i);
            elseif diffV(transitions(j)) == -1
                if ~isempty(endpoints{transitions(j)-1,i})
                    % Get rid of single points...
                    sig(transitions(j)-1,i) = NaN;
                    stats(transitions(j)-1,i) = 0;
                    endpoints{transitions(j)-1,i} = 'delete';
                    endlines(transitions(j)-1,i) = NaN;
                else
                    endpoints{transitions(j)-1,i} = 'R';
                    endlines(transitions(j)-1,i) = yvalues(i);
                end
            end
        end
        clear diffV transitions
        % Determine if regions are larger than a threshold
        diffV = diff([0; stats(:,i); 0]);
        transitions = find(diffV);
        diffT = diff(transitions);
        pairDiff = diffT(1:2:end);
        for j = 1:length(pairDiff)
            if pairDiff(j) < 4
                % Left
                endpoints{transitions(j*2-1),i} = 'delete';
                endlines(transitions(j*2-1),i) = NaN;
                % Right
                endpoints{transitions(j*2)-1,i} = 'delete';
                endlines(transitions(j*2)-1,i) = NaN;
                % In between
                sig(transitions(j*2-1):transitions(j*2)-1,i) = NaN;
            end
        end
    end
    % Add labels over regions of significance
    endX = repmat(linspace(0,100,length(stats))',1,3);
    for i = 1:3
        endX(isnan(endlines(:,i)),i) = NaN;
    end
    [labelX1,labelpoints1] = XgetStatLabels(endX(:,1),endpoints(:,1),yvalues(1));
    [labelX2,labelpoints2] = XgetStatLabels(endX(:,2),endpoints(:,2),yvalues(2));
    [labelX3,labelpoints3] = XgetStatLabels(endX(:,3),endpoints(:,3),yvalues(3));
    % Plot
    text(labelX1,labelpoints1,'*','Color',Color1,'FontSize',16,'HorizontalAlignment','center','VerticalAlignment','baseline','Tag','SignificanceLabel1');
    text(labelX2,labelpoints2,'+','Color',Color2,'FontSize',12,'HorizontalAlignment','center','VerticalAlignment','baseline','Tag','SignificanceLabel2');
    text(labelX3,labelpoints3,'\^','Color',Color3,'FontSize',14,'HorizontalAlignment','center','VerticalAlignment','baseline','Tag','SignificanceLabel3');
    % Plot endpoints as vertical lines    
    text(endX(:,1),endlines(:,1),'I','Color',Color1,'FontSize',14,'HorizontalAlignment','center','Tag','SignificanceEnd');
    text(endX(:,2),endlines(:,2),'I','Color',Color2,'FontSize',14,'HorizontalAlignment','center','Tag','SignificanceEnd');
    text(endX(:,3),endlines(:,3),'I','Color',Color3,'FontSize',14,'HorizontalAlignment','center','Tag','SignificanceEnd');    
    % Plot horizontal line
    line(linspace(0,100,length(sig))',sig(:,1),'Color',Color1,'Tag','SignificanceLine');
    line(linspace(0,100,length(sig))',sig(:,2),'Color',Color2,'Tag','SignificanceLine');
    line(linspace(0,100,length(sig))',sig(:,3),'Color',Color3,'Tag','SignificanceLine');
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function XplotStatisticsMF(obj,yPos,varType,Cycle,varargin)
    % XPLOTSTATISTICS
    %

    % Colors
    ColorH = [1 0 1];
    ColorP = [0 0.5 1];    
    if nargin == 5
        stats = [obj.Statistics.CtoH{Cycle,varType}.(varargin{1}), ...
                 obj.Statistics.CtoP{Cycle,varType}.(varargin{1})];
    elseif nargin == 6
        stats = [obj.Statistics.CtoH{Cycle,varType}.(varargin{1}).(varargin{2}), ...
                 obj.Statistics.CtoP{Cycle,varType}.(varargin{1}).(varargin{2})];
    end
    % Prepare line positions
    yvalues = yPos(1)+(yPos(2)-yPos(1))*[0.6 0.3];
    % Significant results are when 'stats' = 1
    sig = stats;
    sig(sig == 0) = NaN;
    for i = 1:2
        sig(sig(:,i) == 1,i) = yvalues(i);
    end    
    % Find endpoints of lines
    endpoints = cell(size(stats));
    endlines = NaN(size(stats));
    for i = 1:2
        diffV = diff([0; stats(:,i); 0]);
        transitions = find(diffV);
        for j = 1:length(transitions)
            if diffV(transitions(j)) == 1
                endpoints{transitions(j),i} = 'L';
                endlines(transitions(j),i) = yvalues(i);
            elseif diffV(transitions(j)) == -1
                if ~isempty(endpoints{transitions(j)-1,i})
                    % Get rid of single points...
                    sig(transitions(j)-1,i) = NaN;
                    stats(transitions(j)-1,i) = 0;
                    endpoints{transitions(j)-1,i} = 'delete';
                    endlines(transitions(j)-1,i) = NaN;
                else
                    endpoints{transitions(j)-1,i} = 'R';
                    endlines(transitions(j)-1,i) = yvalues(i);
                end
            end
        end
        clear diffV transitions
        % Determine if regions are larger than a threshold
        diffV = diff([0; stats(:,i); 0]);
        transitions = find(diffV);
        diffT = diff(transitions);
        pairDiff = diffT(1:2:end);
        for j = 1:length(pairDiff)
            if pairDiff(j) < 4
                % Left
                endpoints{transitions(j*2-1),i} = 'delete';
                endlines(transitions(j*2-1),i) = NaN;
                % Right
                endpoints{transitions(j*2)-1,i} = 'delete';
                endlines(transitions(j*2)-1,i) = NaN;
                % In between
                sig(transitions(j*2-1):transitions(j*2)-1,i) = NaN;
            end
        end
    end
    % Add labels over regions of significance
    endX = repmat(linspace(0,100,length(stats))',1,2);
    for i = 1:2
        endX(isnan(endlines(:,i)),i) = NaN;
    end
    [labelX1,labelpoints1] = XgetStatLabels(endX(:,1),endpoints(:,1),yvalues(1));
    [labelX2,labelpoints2] = XgetStatLabels(endX(:,2),endpoints(:,2),yvalues(2));
    % Plot
    text(labelX1,labelpoints1,'*','Color',ColorH,'FontSize',16,'HorizontalAlignment','center','VerticalAlignment','baseline','Tag','SignificanceLabel1');
    text(labelX2,labelpoints2,'+','Color',ColorP,'FontSize',12,'HorizontalAlignment','center','VerticalAlignment','baseline','Tag','SignificanceLabel2');
    % Plot endpoints as vertical lines    
    text(endX(:,1),endlines(:,1),'I','Color',ColorH,'FontSize',14,'HorizontalAlignment','center','Tag','SignificanceEnd');
    text(endX(:,2),endlines(:,2),'I','Color',ColorP,'FontSize',14,'HorizontalAlignment','center','Tag','SignificanceEnd');   
    % Plot horizontal line
    line(linspace(0,100,length(sig))',sig(:,1),'Color',ColorH,'Tag','SignificanceLine');
    line(linspace(0,100,length(sig))',sig(:,2),'Color',ColorP,'Tag','SignificanceLine');
end
