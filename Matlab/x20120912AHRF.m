classdef x20120912AHRF < OpenSim.subject
    % X20120912AHRF - A class to store all simulations for subject 20120912AHRF
    %
    %

    % Created by Megan Schroeder
    % Last Modified 2014-03-20


    %% Properties
    % Properties for the x20120912AHRF class

    properties
        A_Walk_01
        A_Walk_02
        A_Walk_03
%         A_Walk_04       % CMC
        A_Walk_05
        U_Walk_01
        U_Walk_02
        U_Walk_03
        U_Walk_04
%         U_Walk_05       % CMC
        A_SD2F_01
%         A_SD2F_02
        A_SD2F_03
        A_SD2F_04
%         A_SD2F_05       % Residuals
        U_SD2F_01
        U_SD2F_02
%         U_SD2F_03       % Residuals
        U_SD2F_04
%         U_SD2F_05
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
    % Methods for the x20120912AHRF class

    methods
        function obj = x20120912AHRF()
            % X20120912AHRF - Construct instance of class
            %

            % Create instance of class from superclass
            obj = obj@OpenSim.subject('20120912AHRF');
        end
    end


end
