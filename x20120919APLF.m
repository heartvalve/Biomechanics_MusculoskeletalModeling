classdef x20120919APLF < OpenSim.subject
    % X20120919APLF - A class to store all simulations for subject 20120919APLF
    %
    %

    % Created by Megan Schroeder
    % Last Modified 2014-03-20


    %% Properties
    % Properties for the x20120919APLF class

    properties
        A_Walk_01
        A_Walk_02
        A_Walk_03
        A_Walk_04
%         A_Walk_05
        U_Walk_01
        U_Walk_02
        U_Walk_03
        U_Walk_04
        U_Walk_05
%         A_SD2F_01
        A_SD2F_02
        A_SD2F_03
%         A_SD2F_04
%         A_SD2F_05       % Residuals
%         U_SD2F_01       % Residuals
%         U_SD2F_02
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
%         U_SD2S_05       % Residuals
    end


    %% Methods
    % Methods for the x20120919APLF class

    methods
        function obj = x20120919APLF()
            % X20120919APLF - Construct instance of class
            %

            % Create instance of class from superclass
            obj = obj@OpenSim.subject('20120919APLF');
        end
    end


end
