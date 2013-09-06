classdef rraSuper < handle
    % RRASUPER - A superclass to store RRA / CMC results from OpenSim.
    %
    %
    
    % Created by Megan Schroeder
    % Last Modified 2013-09-05
    
    
    %% Properties
    % Properties for the rraSuper class
    
    properties (SetAccess = private)
        actuation       % ... force, speed, power
        controls        % ... sto, xml (same info - more time points in sto)
        kinematics      % ... q (Coordinates), u (Speeds), dudt (Accelerations)
        positionError   % ... has one fewer row than all other data
        states
    end
    
    
    %% Methods
    % Methods for the rraSuper class
    
    methods
        % *****************************************************************
        %       Constructor Method
        % *****************************************************************
        function obj = rraSuper(rraPath)
            % RRASUPER - Construct instance of class
            %
            
            try
                % Actuators
                obj.actuation.force = readData([rraPath,'_Actuation_force.sto'],23);
                obj.actuation.speed = readData([rraPath,'_Actuation_speed.sto'],23);
                obj.actuation.power = readData([rraPath,'_Actuation_power.sto'],23);
                % Controls
                obj.controls = readData([rraPath,'_controls.sto'],7);                
                % Kinematics
                obj.kinematics.coordinate = readData([rraPath,'_Kinematics_q.sto'],11);
                obj.kinematics.speed = readData([rraPath,'_Kinematics_u.sto'],11);
                obj.kinematics.acceleration = readData([rraPath,'_Kinematics_dudt.sto'],11);             
                % Position Error
                obj.positionError = readData([rraPath,'_pErr.sto'],7);
                % States
                obj.states = readData([rraPath,'_states.sto'],7);
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
                data = dataset({dataimport.data,names{:}});
            end
        end
    end
    
end
