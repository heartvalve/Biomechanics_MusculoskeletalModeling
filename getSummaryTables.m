function tables = getSummaryTables(obj)
    % GETSUMMARYTABLES
    %
    %
    
    % Created by Megan Schroeder
    % Last Modified 2014-03-25
    
    
    %% Main
    % Main function definition
    
    varNames = {'Walk_Control','Walk_PatellaACL','Walk_HamstringACL',...
                  'SD2S_Control','SD2S_PatellaACL','SD2S_HamstringACL'};
    % Residuals
    rdObsNames = obj.Control.AvgSummary.Mean.Residuals{1}.Properties.VarNames;    
    rdData = cell(length(rdObsNames),length(varNames));
    for i = 1:length(rdObsNames)
        for j = 1:length(varNames)
            cycle = varNames{j}(1:strfind(varNames{j},'_')-1);
            group = varNames{j}(strfind(varNames{j},'_')+1:end);
            if strcmp(group,'Control')
                meanData = obj.(group).AvgSummary.Mean{cycle,'Residuals'}{'RMS_CMC',rdObsNames{i}};
                sdData = obj.(group).AvgSummary.StdDev{cycle,'Residuals'}{'RMS_CMC',rdObsNames{i}};
            else
                meanData = obj.(group).Summary.Mean{['A_',cycle],'Residuals'}{'RMS_CMC',rdObsNames{i}};
                sdData = obj.(group).Summary.StdDev{['A_',cycle],'Residuals'}{'RMS_CMC',rdObsNames{i}};             
            end
            rdData(i,j) = {[num2str(meanData,'%8.1f'),' (',num2str(sdData,'%8.1f'),')']};
        end
    end
    rdDataset = set(dataset({rdData,varNames{:}}),'ObsNames',rdObsNames);
    % -------------------------
    % Reserves
    rvObsNames = obj.Control.AvgSummary.Mean.Reserves{1}.Properties.VarNames;
    rvData = cell(length(rvObsNames),length(varNames));
    for i = 1:length(rvObsNames)
        for j = 1:length(varNames)
            cycle = varNames{j}(1:strfind(varNames{j},'_')-1);
            group = varNames{j}(strfind(varNames{j},'_')+1:end);
            if strcmp(group,'Control')
                meanData = obj.(group).AvgSummary.Mean{cycle,'Reserves'}{'RMS',rvObsNames{i}};
                sdData = obj.(group).AvgSummary.StdDev{cycle,'Reserves'}{'RMS',rvObsNames{i}};
            else
                meanData = obj.(group).Summary.Mean{['A_',cycle],'Reserves'}{'RMS',rvObsNames{i}};
                sdData = obj.(group).Summary.StdDev{['A_',cycle],'Reserves'}{'RMS',rvObsNames{i}};             
            end
            if meanData < 0.01
                meanFormat = '%8.3f';
            else
                meanFormat = '%8.2f';
            end
            if sdData < 0.01
                sdFormat = '%8.3f';
            else
                sdFormat = '%8.2f';
            end
            rvData(i,j) = {[num2str(meanData,meanFormat),' (',num2str(sdData,sdFormat),')']};
        end
    end
    rvDataset = set(dataset({rvData,varNames{:}}),'ObsNames',rvObsNames);
    % -------------------------
    % Position Errors
    pObsNames = obj.Control.AvgSummary.Mean.PosErrors{1}.Properties.VarNames;
    pData = cell(length(pObsNames),length(varNames));
    for i = 1:length(pObsNames)
        for j = 1:length(varNames)
            cycle = varNames{j}(1:strfind(varNames{j},'_')-1);
            group = varNames{j}(strfind(varNames{j},'_')+1:end);
            if strcmp(group,'Control')
                meanData = obj.(group).AvgSummary.Mean{cycle,'PosErrors'}{'RMS',pObsNames{i}};
                sdData = obj.(group).AvgSummary.StdDev{cycle,'PosErrors'}{'RMS',pObsNames{i}};
            else
                meanData = obj.(group).Summary.Mean{['A_',cycle],'PosErrors'}{'RMS',pObsNames{i}};
                sdData = obj.(group).Summary.StdDev{['A_',cycle],'PosErrors'}{'RMS',pObsNames{i}};             
            end
            % Convert from meters to centimeters for translations
            if regexp(pObsNames{i},'pelvis_t[xyz]')
                meanData = meanData*100;
                sdData = sdData*100;
            end
            pData(i,j) = {[num2str(meanData,'%8.1f'),' (',num2str(sdData,'%8.1f'),')']};
        end
    end
    pDataset = set(dataset({pData,varNames{:}}),'ObsNames',pObsNames);
    % -------------------------
    % Trial Variability    
    tvObsNames = obj.Control.AvgSummary.Mean.AvgForces{1}.Properties.VarNames;
    tvData = cell(length(tvObsNames),length(varNames));
    for i = 1:length(tvObsNames)
        for j = 1:length(varNames)
            cycle = varNames{j}(1:strfind(varNames{j},'_')-1);
            group = varNames{j}(strfind(varNames{j},'_')+1:end);
            subjects = properties(obj.(group));
            checkSubjects = @(x) isa(obj.(group).(x{1}),'OpenSim.subject');
            subjects(~arrayfun(checkSubjects,subjects)) = [];
            meanSDforSubject = zeros(length(subjects),1);
            for k = 1:length(subjects)
                meanSDforSubject(k) = nanmean(obj.(group).(subjects{k}).Summary.StdDev{['A_',cycle],'Forces'}.(tvObsNames{i}));
            end
            meanData = mean(meanSDforSubject);
%             sdData = std(meanSDforSubject);
%             tvData(i,j) = {[num2str(meanData,'%8.3f'),' (',num2str(sdData,'%8.3f'),')']};
            tvData(i,j) = {num2str(meanData,'%8.3f')};
        end
    end
    tvDataset = set(dataset({tvData,varNames{:}}),'ObsNames',tvObsNames);
    % -------------------------
    % Subject Variability
    sObsNames = obj.Control.AvgSummary.Mean.AvgForces{1}.Properties.VarNames;
    sData = cell(length(sObsNames),length(varNames));
    for i = 1:length(sObsNames)
        for j = 1:length(varNames)
            cycle = varNames{j}(1:strfind(varNames{j},'_')-1);
            group = varNames{j}(strfind(varNames{j},'_')+1:end);           
            if strcmp(group,'Control')
                meanData = nanmean(obj.(group).AvgSummary.StdDev{cycle,'AvgForces'}.(tvObsNames{i}));
            else
                meanData = nanmean(obj.(group).Summary.StdDev{['A_',cycle],'AvgForces'}.(tvObsNames{i})); 
            end            
            sData(i,j) = {num2str(meanData,'%8.3f')};
        end
    end
    sDataset = set(dataset({sData,varNames{:}}),'ObsNames',sObsNames);
    % ~~~~~~~~~~~~~~~~~~~~~~~~~
    % Return
    tables = struct();
    tables.Residuals = rdDataset;
    tables.Reserves = rvDataset;
    tables.PosErrors = pDataset;
    tables.TrialVariability = tvDataset;
    tables.SubjectVariability = sDataset;

end
