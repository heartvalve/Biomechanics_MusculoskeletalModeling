function [axes_handles,mNames] = getAxesAndMuscles(simulationObj,muscle)
    % GETAXESANDMUSCLES - A function to get the appropriate axes handles and corresponding muscle names for a plot.
    %
    %
    
    % Created by Megan Schroeder
    % Last Modified 2013-09-05
    
    
    %% Main
    % Main function definition
    
    if strcmp(muscle,'All')
        mNames = simulationObj.muscles;
        axes_handles = zeros(1,12);
        for k = 1:12
            axes_handles(k) = subplot(3,4,k);
        end
    elseif strcmp(muscle,'Quads')
        mNames = simulationObj.muscles(1:4);
        axes_handles = zeros(1,4);
        for k = 1:4
            axes_handles(k) = subplot(2,2,k);
        end
    elseif strcmp(muscle,'Hamstrings')
        mNames = simulationObj.muscles(5:8);
        axes_handles = zeros(1,4);
        for k = 1:4
            axes_handles(k) = subplot(2,2,k);
        end
    elseif strcmp(muscle,'Gastrocs')
        mNames = simulationObj.muscles(9:10);
        axes_handles = zeros(1,2);
        for k = 1:2
            axes_handles(k) = subplot(1,2,k);
        end
    else
        mNames = {muscle};
        axes_handles = axes('Parent',fig_handle);
    end
end
