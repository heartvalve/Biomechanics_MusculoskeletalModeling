function tables = getSummaryTables(obj)
    % GETSUMMARYTABLES
    %
    %
    
    % Created by Megan Schroeder
    % Last Modified 2014-03-21
    
    
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
            rvData(i,j) = {[num2str(meanData,'%8.3f'),' (',num2str(sdData,'%8.3f'),')']};
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
    % ~~~~~~~~~~~~~~~~~~~~~~~~~
    % Return
    tables = struct();
    tables.Residuals = rdDataset;
    tables.Reserves = rvDataset;
    tables.PosErrors = pDataset;

end
