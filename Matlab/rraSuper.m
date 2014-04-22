classdef rraSuper < handle
    % RRASUPER - A superclass to store RRA / CMC results from OpenSim.
    %
    %
    
    % Created by Megan Schroeder
    % Last Modified 2014-03-29
    
    
    %% Properties
    % Properties for the rraSuper class
    
    properties (SetAccess = private)
        Actuation       % ... force, speed, power
%         Controls        % ... sto, xml (same info - more time points in sto)
        Kinematics      % ... q (Coordinates), u (Speeds), dudt (Accelerations)
        PositionError   % ... has one fewer row than all other data
        States
    end
    
    
    %% Methods
    % Methods for the rraSuper class
    
    methods
        % *****************************************************************
        %       Constructor Method
        % *****************************************************************
        function obj = rraSuper(rraPath,readCMCstate)
            % RRASUPER - Construct instance of class
            %
            
            try
                % Actuators
                obj.Actuation.Force = readData([rraPath,'_Actuation_force.sto'],23);
%                 obj.Actuation.Speed = readData([rraPath,'_Actuation_speed.sto'],23);
%                 obj.Actuation.Power = readData([rraPath,'_Actuation_power.sto'],23);
                % Controls
%                 obj.Controls = readData([rraPath,'_controls.sto'],7);                
                % Kinematics
                obj.Kinematics.Coordinate = readData([rraPath,'_Kinematics_q.sto'],11);
%                 obj.Kinematics.Speed = readData([rraPath,'_Kinematics_u.sto'],11);
%                 obj.Kinematics.Acceleration = readData([rraPath,'_Kinematics_dudt.sto'],11);             
                % Position Error
                obj.PositionError = readData([rraPath,'_pErr.sto'],7);
                % States
                if readCMCstate
                    obj.States = readData([rraPath,'_states.sto'],7);
                else
                    obj.States = [];
                end
            catch err
                [~,name,~] = fileparts(rraPath);
                disp(['Problem with ',name]);
            end
            % -------------------------------------------------------------            
            %   Subfunction
            % -------------------------------------------------------------
            function data = readData(filePath,hLines)
                % READDATA - A function to read the OpenSim output files.
                %

                % Import the file
                dataimport = importdata(filePath,'\t',hLines);
                % Column headers
                names = dataimport.colheaders;
                names = regexprep(names,{'\.','\W'},'_');
                % Data
                if strfind(filePath,'_pErr.sto')
                    % Convert to degrees (columns 5 and beyond only -
                    % column 1 is time, 2-4 are translational positions)
                    newdata = dataimport.data;
                    newdata(:,5:end) = newdata(:,5:end).*180/pi;
                    data = dataset({newdata,names{:}});
                else
                    data = dataset({dataimport.data,names{:}});
                end
            end
        end
    end
    
end
