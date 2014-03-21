classdef x20121008AHRM < OpenSim.subject
    % X20121008AHRM - A class to store all simulations for subject 20121008AHRM
    %
    %

    % Created by Megan Schroeder
    % Last Modified 2014-03-20


    %% Properties
    % Properties for the x20121008AHRM class

    properties
%         A_Walk_01       % Residuals
        A_Walk_02
        A_Walk_03
        A_Walk_04
        A_Walk_05
%         U_Walk_01       % Residuals
        U_Walk_02
%         U_Walk_03       % Residuals
        U_Walk_04
        U_Walk_05
%         A_SD2F_01       % Residuals
%         A_SD2F_02       % Residuals
%         A_SD2F_03       % Residuals
        A_SD2F_04
        A_SD2F_05
%         U_SD2F_01       % Residuals
        U_SD2F_02
%         U_SD2F_03       % Residuals
%         U_SD2F_04       % Residuals
        U_SD2F_05
        A_SD2S_01
%         A_SD2S_02       % CMC
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
    % Methods for the x20121008AHRM class

    methods
        function obj = x20121008AHRM()
            % X20121008AHRM - Construct instance of class
            %

            % Create instance of class from superclass
            obj = obj@OpenSim.subject('20121008AHRM');
        end
    end


end
