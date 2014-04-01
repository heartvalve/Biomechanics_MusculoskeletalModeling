function stats = getSummaryStatistics(obj,alpha)
    % GETSUMMARYSTATISTICS
    %
    %
    
    % Created by Megan Schroeder
    % Last Modified 2014-03-30

    
    %% Main
    % Main function definition
    
    if nargin == 1
        alpha = 0.05;
%         alpha = 0.15;
    end
    allCycles = get(obj.Control.Cycles,'ObsNames');
    varnames = {'Forces'};
    % Control vs. Hamstring group
    CtoHdata = cell(length(allCycles),length(varnames));
    CtoHdataset = dataset({CtoHdata,varnames{:}});
    % Control vs. Patella group
    CtoPdata = cell(length(allCycles),length(varnames));
    CtoPdataset = dataset({CtoPdata,varnames{:}});    
    % Set observation names
    CtoHdataset = set(CtoHdataset,'ObsNames',allCycles);
    CtoPdataset = set(CtoPdataset,'ObsNames',allCycles);
    % Unique cycles
    uniqueCycles =  unique(cellfun(@(x) x(3:end),allCycles,'UniformOutput',false));    
    % Loop
    for i = 1:length(uniqueCycles)
        % Muscle Forces
        [CtoH_A,CtoH_U] = XrunIndANOVA(obj,alpha,uniqueCycles{i},'Hamstring','AvgForces');
        CtoHdataset{['A_',uniqueCycles{i}],'Forces'} = CtoH_A;
        CtoHdataset{['U_',uniqueCycles{i}],'Forces'} = CtoH_U;
        [CtoP_A,CtoP_U] = XrunIndANOVA(obj,alpha,uniqueCycles{i},'Patella','AvgForces');
        CtoPdataset{['A_',uniqueCycles{i}],'Forces'} = CtoP_A;
        CtoPdataset{['U_',uniqueCycles{i}],'Forces'} = CtoP_U;     
    end  
    % Create structure
    stats = struct();
    stats.CtoH = CtoHdataset;
    stats.CtoP = CtoPdataset;
    % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% %     % Cycles irrespective of leg
% %     uniqueCycles =  unique(cellfun(@(x) x(3:end),allCycles,'UniformOutput',false));    
% %     % Control (combined) vs. ACLR (HT & PT combined)
% %     CtoAdata = cell(length(uniqueCycles),length(varnames));
% %     CtoAdataset = dataset({CtoAdata,varnames{:}});        
% %     % Control (combined) vs. Uninvolved (HT & PT combined)
% %     CtoUdata = cell(length(uniqueCycles),length(varnames));
% %     CtoUdataset = dataset({CtoUdata,varnames{:}});    
% %     % ACLR (HT & PT combined) vs. Uninvovled (HT & PT combined)
% %     AtoUdata = cell(length(uniqueCycles),length(varnames));
% %     AtoUdataset = dataset({AtoUdata,varnames{:}});
% %     % Loop
% %     for i = 1:length(uniqueCycles)
% %         % Muscle Forces
% %         [CtoAtemp, CtoUtemp, AtoUtemp] = XrunCombinedANOVA(obj,alpha,uniqueCycles{i},'Forces');
% %         CtoAdataset{i,'Forces'} = CtoAtemp;
% %         CtoUdataset{i,'Forces'} = CtoUtemp;
% %         AtoUdataset{i,'Forces'} = AtoUtemp;        
% %     end
% %     % Set observation names 
% %     CtoAdataset = set(CtoAdataset,'ObsNames',uniqueCycles);
% %     CtoUdataset = set(CtoUdataset,'ObsNames',uniqueCycles);
% %     AtoUdataset = set(AtoUdataset,'ObsNames',uniqueCycles);
% %     % Add to struct        
% %     stats.CtoA = CtoAdataset;
% %     stats.CtoU = CtoUdataset;
% %     stats.AtoU = AtoUdataset;
    % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    % Copy from group data
    stats.AtoU_H = obj.HamstringACL.Statistics;
    stats.AtoU_P = obj.PatellaACL.Statistics;    
            
end


%% Subfunction
% Subfunction called from main function definition

function [CtoG_A,CtoG_U] = XrunIndANOVA(obj,alpha,cycle,graft,varType)
    % XRUNINDANOVA
    %
    
    % Data 
    control = obj.Control.AvgCycles{cycle,varType};
    graft_A = obj.([graft,'ACL']).Cycles{['A_',cycle],varType};
    graft_U = obj.([graft,'ACL']).Cycles{['U_',cycle],varType};
    % Number of subjects
    numC = length(obj.Control.AvgCycles{cycle,'Subjects'});
    numG_A = length(obj.([graft,'ACL']).Cycles{['A_',cycle],'Subjects'});
    numG_U = length(obj.([graft,'ACL']).Cycles{['U_',cycle],'Subjects'});
    % Nominal variable
    groups = [repmat({'Control'},1,numC) repmat({'Graft_A'},1,numG_A) repmat({'Graft_U'},1,numG_U)];
    groups = nominal(groups);
    % Get variable names (muscles, forces, segments, joints, etc.)
    varNames = control.Properties.VarNames;
    % Initialize outcomes
    stats = cell(size(control,1),length(varNames));
    CtoG_Adata = NaN(size(control,1),length(varNames));
    CtoG_Udata = NaN(size(control,1),length(varNames));
    % Loop through the rows
    for i = 1:size(control,1)
        % Loop through the columns
        for j = 1:length(varNames)
            % Calculate statistics
            [~,~,stats{i,j}] = anova1([control.(varNames{j})(i,:), graft_A.(varNames{j})(i,:), ...
                                       graft_U.(varNames{j})(i,:)], groups, 'off');            
            multComp = multcompare(stats{i,j},'alpha',alpha,'display','off');
            % Fill in 'significance'
            % Multcompare returns group comparisons (first row: 1 vs. 2, 
            % second row, 1 vs. 3, third row, 1 vs. 4, etc.); group numbers given
            % by 'table' results of anova1:  gnames are in alphabetical
            % order, so {control, graft_A, graft_U}
            % Control vs. Graft_A
            CtoG_Adata(i,j) = XgetMC(multComp(1,:));
            % Control vs. Graft_U
            CtoG_Udata(i,j) = XgetMC(multComp(2,:)); 
            clear multComp            
        end
    end    
    % Eliminate areas where forces are small
    if strcmp(varType,'Forces') || strcmp(varType,'AvgForces')
        for j = 1:length(varNames)
            CtoG_Adata((((nanmean(control.(varNames{j}),2) < 0.021) & (nanmean(graft_A.(varNames{j}),2) < 0.021)) | ...
                         (abs(nanmean(control.(varNames{j}),2)-nanmean(graft_A.(varNames{j}),2)) < 0.005)),j) = 0;
            CtoG_Udata((((nanmean(control.(varNames{j}),2) < 0.021) & (nanmean(graft_U.(varNames{j}),2) < 0.021)) | ...
                         (abs(nanmean(control.(varNames{j}),2)-nanmean(graft_U.(varNames{j}),2)) < 0.005)),j) = 0;            
        end
    end
    % Datasets
    CtoG_A = dataset({CtoG_Adata,varNames{:}});
    CtoG_U = dataset({CtoG_Udata,varNames{:}});
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [CtoA,CtoU,AtoU] = XrunCombinedANOVA(obj,alpha,cycle,varType)
    % XRUNCOMBINEDANOVA
    %
    
    % Data        
    controlA = obj.Control.Cycles{['A_',cycle],varType};
    hamstringA = obj.HamstringACL.Cycles{['A_',cycle],varType};
    patellaA = obj.PatellaACL.Cycles{['A_',cycle],varType};
    controlU = obj.Control.Cycles{['U_',cycle],varType};
    hamstringU = obj.HamstringACL.Cycles{['U_',cycle],varType};
    patellaU = obj.PatellaACL.Cycles{['U_',cycle],varType};       
    % Get variable names (muscles, forces, segments, joints, etc.)
    varNames = controlA.Properties.VarNames;
    % Datasets
    cdata = cell(size(controlA));
    control = dataset({cdata,varNames{:}});
    aclr = dataset({cdata,varNames{:}});
    uninvolved = dataset({cdata,varNames{:}});
    % Loop
    for i = 1:length(varNames)
        control.(varNames{i}) = [controlA.(varNames{i}) controlU.(varNames{i})];
        aclr.(varNames{i}) = [hamstringA.(varNames{i}) patellaA.(varNames{i})];
        uninvolved.(varNames{i}) = [hamstringU.(varNames{i}) patellaU.(varNames{i})];
    end
    % Number of subjects
    numC = length(obj.Control.Cycles{['A_',cycle],'Subjects'})+length(obj.Control.Cycles{['U_',cycle],'Subjects'});
    numA = length(obj.HamstringACL.Cycles{['A_',cycle],'Subjects'})+length(obj.PatellaACL.Cycles{['A_',cycle],'Subjects'});
    numU = length(obj.HamstringACL.Cycles{['U_',cycle],'Subjects'})+length(obj.PatellaACL.Cycles{['U_',cycle],'Subjects'});
    % Nominal variable
    groups = [repmat({'Control'},1,numC) repmat({'ACLR'},1,numA) repmat({'Uninvolved'},1,numU)];
    groups = nominal(groups);
    % Get variable names (muscles, forces, segments, joints, etc.)
    varNames = control.Properties.VarNames;
    % Initialize outcomes
    stats = cell(size(control,1),length(varNames));
    CtoAdata = NaN(size(control,1),length(varNames));
    CtoUdata = NaN(size(control,1),length(varNames));
    AtoUdata = NaN(size(control,1),length(varNames));
    % Loop through the rows
    for i = 1:size(control,1)
        % Loop through the columns
        for j = 1:length(varNames)
            % Calculate statistics
            [~,~,stats{i,j}] = anova1([control.(varNames{j})(i,:), aclr.(varNames{j})(i,:), ...
                                       uninvolved.(varNames{j})(i,:)], groups, 'off');            
            multComp = multcompare(stats{i,j},'alpha',alpha,'display','off');
            % Fill in 'significance'
            % Multcompare returns group comparisons (first row: 1 vs. 2, 
            % second row, 1 vs. 3, third row, 2 vs. 3); group numbers given
            % by 'table' results of anova1:  gnames are in alphabetical
            % order, so {aclr, control, uninvolved}
            % ACLR vs. Control
            CtoAdata(i,j) = XgetMC(multComp(1,:)); 
            % ACLR vs. Uninvolved -- will be overwritten...
            AtoUdata(i,j) = XgetMC(multComp(2,:));
            % Control vs. Uninvolved
            CtoUdata(i,j) = XgetMC(multComp(3,:));
            clear multComp
        end
    end
    % Run Paired T-Test for ACLR vs. Uninvolved
    for j = 1:length(varNames)
        AtoUdata(:,j) = (ttest(aclr.(varNames{j})',uninvolved.(varNames{j})',alpha))';
        % Eliminate areas where forces are small
        if strcmp(varType,'Forces')
            AtoUdata((((nanmean(aclr.(varNames{j}),2) < 5) & (nanmean(uninvolved.(varNames{j}),2) < 5)) | ...
                       (abs(nanmean(aclr.(varNames{j}),2)-nanmean(uninvolved.(varNames{j}),2)) < 2)),j) = 0;
            CtoAdata((((nanmean(control.(varNames{j}),2) < 5) & (nanmean(aclr.(varNames{j}),2) < 5)) | ...
                       (abs(nanmean(control.(varNames{j}),2)-nanmean(aclr.(varNames{j}),2)) < 2)),j) = 0;
            CtoUdata((((nanmean(control.(varNames{j}),2) < 5) & (nanmean(uninvolved.(varNames{j}),2) < 5)) | ...
                       (abs(nanmean(control.(varNames{j}),2)-nanmean(uninvolved.(varNames{j}),2)) < 2)),j) = 0;
        end
    end    
    % Datasets
    CtoA = dataset({CtoAdata,varNames{:}});
    CtoU = dataset({CtoUdata,varNames{:}});
    AtoU = dataset({AtoUdata,varNames{:}});    
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function mcData = XgetMC(multCompRow)
    % XGETMC
    %
        
    if multCompRow(1,3) < 0 && multCompRow(1,5) > 0
        mcData = 0;
    else
        mcData = 1;
    end
end
