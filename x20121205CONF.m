classdef x20121205CONF < OpenSim.subject
    % X20121205CONF - A class to store all simulations for subject 20121205CONF
    %
    %

    % Created by Megan Schroeder
    % Last Modified 2014-01-15


    %% Properties
    % Properties for the x20121205CONF class

    properties
        A_Walk_01
        A_Walk_02
        A_Walk_03
        A_Walk_04
        A_Walk_05
        U_Walk_01
        U_Walk_02
        U_Walk_03
        U_Walk_04
        U_Walk_05
        A_SD2F_01
        A_SD2F_02
        A_SD2F_03
%         A_SD2F_04       % CMC
%         A_SD2F_05       % CMC
        U_SD2F_01
        U_SD2F_02
        U_SD2F_03
        U_SD2F_04
        U_SD2F_05
        A_SD2S_01
        A_SD2S_02
        A_SD2S_03
        A_SD2S_04
        A_SD2S_05
        U_SD2S_01
        U_SD2S_02
        U_SD2S_03
        U_SD2S_04
        U_SD2S_05
    end


    %% Methods
    % Methods for the x20121205CONF class

    methods
        function obj = x20121205CONF()
            % X20121205CONF - Construct instance of class
            %

            % Create instance of class from superclass
            obj = obj@OpenSim.subject('20121205CONF');
        end
    end


end
