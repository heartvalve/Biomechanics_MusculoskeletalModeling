classdef controlGroup < OpenSim.group
    % CONTROLGROUP - A class to store all control subjects.
    %
    %
    
    % Created by Megan Schroeder
    % Last Modified 2014-03-21
    
    
    %% Properties
    % Properties for the controlGroup class
    
    properties
        x20121204CONF
        x20121205CONF
        x20121205CONM
        x20121206CONF
        x20130221CONF
        x20130401CONM
    end
    properties (SetAccess = private, Hidden = true)
        AvgCycles
        AvgSummary
    end
    
    
    %% Methods
    % Methods for the controlGroup class
    
    methods
        function obj = controlGroup()
            % CONTROLGROUP - Construct instance of class
            %
            
            % Create instance of class from superclass
            obj = obj@OpenSim.group();
            % Add group ID
            obj.GroupID = 'Control';
            % -------------------------------------------------------------
            %       Average Summary
            % -------------------------------------------------------------
            % Set up struct
            sumStruct = struct();
            varnames = {'Simulations','Weights','Forces','Subjects','AvgForces','Residuals','Reserves','PosErrors'};
            uniqueCycles = {'Walk','SD2F','SD2S'};  
            % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            %       Cycle Aggregates            
            % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            cdata = cell(length(uniqueCycles),length(varnames));
            cdataset = dataset({cdata,varnames{:}});
            for i = 1:length(uniqueCycles)
                % Simulations
                cdataset{i,'Simulations'} = [obj.Cycles{['A_',uniqueCycles{i}],'Simulations'}; obj.Cycles{['U_',uniqueCycles{i}],'Simulations'}];                
                % Muscle Forces
                innerVarNames = obj.Cycles{['A_',uniqueCycles{i}],'Forces'}.Properties.VarNames;
                fdata = cell(length(obj.Cycles{['A_',uniqueCycles{i}],'Forces'}),length(innerVarNames));
                cdataset{i,'Forces'} = dataset({fdata,innerVarNames{:}});
                for k = 1:length(innerVarNames)
                    cdataset{i,'Forces'}.(innerVarNames{k}) = [obj.Cycles{['A_',uniqueCycles{i}],'Forces'}.(innerVarNames{k}) obj.Cycles{['U_',uniqueCycles{i}],'Forces'}.(innerVarNames{k})];
                end  
                % Weights
                cdataset{i,'Weights'} = [obj.Cycles{['A_',uniqueCycles{i}],'Weights'}; obj.Cycles{['U_',uniqueCycles{i}],'Weights'}];
                % Subject average forces
                innerVarNames = obj.Cycles{['A_',uniqueCycles{i}],'AvgForces'}.Properties.VarNames;
                fdata = cell(length(obj.Cycles{['A_',uniqueCycles{i}],'AvgForces'}),length(innerVarNames));
                cdataset{i,'AvgForces'} = dataset({fdata,innerVarNames{:}});
                for k = 1:length(innerVarNames)
                    cdataset{i,'AvgForces'}.(innerVarNames{k}) = [obj.Cycles{['A_',uniqueCycles{i}],'AvgForces'}.(innerVarNames{k}) obj.Cycles{['U_',uniqueCycles{i}],'AvgForces'}.(innerVarNames{k})];
                end 
                % Subjects
                cdataset{i,'Subjects'} = [obj.Cycles{['A_',uniqueCycles{i}],'Subjects'}; obj.Cycles{['U_',uniqueCycles{i}],'Subjects'}];
                % Residuals
                innerVarNames = obj.Cycles{['A_',uniqueCycles{i}],'Residuals'}.Properties.VarNames;
                fdata = cell(length(obj.Cycles{['A_',uniqueCycles{i}],'Residuals'}),length(innerVarNames));
                cdataset{i,'Residuals'} = dataset({fdata,innerVarNames{:}});
                for k = 1:length(innerVarNames)
                    cdataset{i,'Residuals'}.(innerVarNames{k}) = [obj.Cycles{['A_',uniqueCycles{i}],'Residuals'}.(innerVarNames{k}) obj.Cycles{['U_',uniqueCycles{i}],'Residuals'}.(innerVarNames{k})];
                end
                % Reserves
                innerVarNames = obj.Cycles{['A_',uniqueCycles{i}],'Reserves'}.Properties.VarNames;
                fdata = cell(length(obj.Cycles{['A_',uniqueCycles{i}],'Reserves'}),length(innerVarNames));
                cdataset{i,'Reserves'} = dataset({fdata,innerVarNames{:}});
                for k = 1:length(innerVarNames)
                    cdataset{i,'Reserves'}.(innerVarNames{k}) = [obj.Cycles{['A_',uniqueCycles{i}],'Reserves'}.(innerVarNames{k}) obj.Cycles{['U_',uniqueCycles{i}],'Reserves'}.(innerVarNames{k})];
                end
                % Position Errors
                innerVarNames = obj.Cycles{['A_',uniqueCycles{i}],'PosErrors'}.Properties.VarNames;
                fdata = cell(length(obj.Cycles{['A_',uniqueCycles{i}],'PosErrors'}),length(innerVarNames));
                cdataset{i,'PosErrors'} = dataset({fdata,innerVarNames{:}});
                for k = 1:length(innerVarNames)
                    cdataset{i,'PosErrors'}.(innerVarNames{k}) = [obj.Cycles{['A_',uniqueCycles{i}],'PosErrors'}.(innerVarNames{k}) obj.Cycles{['U_',uniqueCycles{i}],'PosErrors'}.(innerVarNames{k})];
                end
            end
            cdataset = set(cdataset,'ObsNames',uniqueCycles);
            % Assign Property
            obj.AvgCycles = cdataset;
            % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            %       Averages & Standard Deviations
            % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  
            varnames = {'Forces','AvgForces','Residuals','Reserves','PosErrors'};
            resObsNames = {'Mean_RRA','Mean_CMC','RMS_RRA','RMS_CMC','Max_RRA','Max_CMC'};
            genObsNames = {'Mean','RMS','Max'};
            adata = cell(length(uniqueCycles),length(varnames));
            sdata = cell(length(uniqueCycles),length(varnames));            
            adataset = dataset({adata,varnames{:}});
            sdataset = dataset({sdata,varnames{:}});
            % Calculate averages
            for i = 1:length(uniqueCycles)
                % Muscle Forces
                adataset{i,'Forces'} = OpenSim.getDatasetMean(uniqueCycles{i},cdataset{i,'Forces'},2,cdataset{i,'Weights'});
                sdataset{i,'Forces'} = OpenSim.getDatasetStdDev(uniqueCycles{i},cdataset{i,'Forces'},cdataset{i,'Weights'});
                % Subject average forces
                adataset{i,'AvgForces'} = OpenSim.getDatasetMean(uniqueCycles{i},cdataset{i,'AvgForces'},2);
                sdataset{i,'AvgForces'} = OpenSim.getDatasetStdDev(uniqueCycles{i},cdataset{i,'AvgForces'});
                % Residuals
                adataset{i,'Residuals'} = set(OpenSim.getDatasetMean(uniqueCycles{i},cdataset{i,'Residuals'},2),'ObsNames',resObsNames);
                sdataset{i,'Residuals'} = set(OpenSim.getDatasetStdDev(uniqueCycles{i},cdataset{i,'Residuals'}),'ObsNames',resObsNames);
                % Reserves
                adataset{i,'Reserves'} = set(OpenSim.getDatasetMean(uniqueCycles{i},cdataset{i,'Reserves'},2),'ObsNames',genObsNames);
                sdataset{i,'Reserves'} = set(OpenSim.getDatasetStdDev(uniqueCycles{i},cdataset{i,'Reserves'}),'ObsNames',genObsNames);
                % Position Errors
                adataset{i,'PosErrors'} = set(OpenSim.getDatasetMean(uniqueCycles{i},cdataset{i,'PosErrors'},2),'ObsNames',genObsNames);
                sdataset{i,'PosErrors'} = set(OpenSim.getDatasetStdDev(uniqueCycles{i},cdataset{i,'PosErrors'}),'ObsNames',genObsNames);
            end
            adataset = set(adataset,'ObsNames',uniqueCycles);
            sdataset = set(sdataset,'ObsNames',uniqueCycles);
            % Add to struct
            sumStruct.Mean = adataset;
            sumStruct.StdDev = sdataset;
            % Assign Property
            obj.AvgSummary = sumStruct;
        end
    end
    
end
