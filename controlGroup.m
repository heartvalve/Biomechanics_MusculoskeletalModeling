classdef controlGroup < OpenSim.group
    % CONTROLGROUP - A class to store all control subjects.
    %
    %
    
    % Created by Megan Schroeder
    % Last Modified 2014-01-20
    
    
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
            varnames = {'Subjects','Forces'};
            allCycles = get(obj.Cycles,'ObsNames');
            uniqueCycles = unique(cellfun(@(x) x(3:end),allCycles,'UniformOutput',false));  
            % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            %       Cycle Aggregates            
            % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            cdata = cell(length(uniqueCycles),length(varnames));
            cdataset = dataset({cdata,varnames{:}});
            for i = 1:length(uniqueCycles)
                % Subjects
                cdataset{i,'Subjects'} = [obj.Cycles{['A_',uniqueCycles{i}],'Subjects'}; obj.Cycles{['U_',uniqueCycles{i}],'Subjects'}];                
                % Muscle Forces
                innerVarNames = obj.Cycles{['A_',uniqueCycles{i}],'Forces'}.Properties.VarNames;
                fdata = cell(length(obj.Cycles{['A_',uniqueCycles{i}],'Forces'}),length(innerVarNames));
                cdataset{i,'Forces'} = dataset({fdata,innerVarNames{:}});
                for k = 1:length(innerVarNames)
                    cdataset{i,'Forces'}.(innerVarNames{k}) = [obj.Cycles{['A_',uniqueCycles{i}],'Forces'}.(innerVarNames{k}) obj.Cycles{['U_',uniqueCycles{i}],'Forces'}.(innerVarNames{k})];
                end                           
            end
            cdataset = set(cdataset,'ObsNames',uniqueCycles);
            % Assign Property
            obj.AvgCycles = cdataset;
            % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            %       Averages & Standard Deviations
            % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~            
            adata = cell(length(uniqueCycles),length(varnames)-1);
            sdata = cell(length(uniqueCycles),length(varnames)-1);            
            adataset = dataset({adata,varnames{2:end}});
            sdataset = dataset({sdata,varnames{2:end}});
            % Calculate averages
            for i = 1:length(uniqueCycles)
                % Muscle Forces
                adataset{i,'Forces'} = OpenSim.getDatasetMean(uniqueCycles{i},cdataset{i,'Forces'},2);
                sdataset{i,'Forces'} = OpenSim.getDatasetStdDev(uniqueCycles{i},cdataset{i,'Forces'});
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
