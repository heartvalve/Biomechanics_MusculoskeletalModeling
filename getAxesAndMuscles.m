function [axes_handles,mNames] = getAxesAndMuscles(simulationObj,muscle)
    % GETAXESANDMUSCLES - A function to get the appropriate axes handles and corresponding muscle names for a plot.
    %
    %
    
    % Created by Megan Schroeder
    % Last Modified 2014-01-13
    
    
    %% Main
    % Main function definition
    
    if strcmp(muscle,'All')
        mNames = simulationObj.Muscles;
        axes_handles = zeros(1,10);
        for k = 1:10
            axes_handles(k) = subplot(3,4,k);
        end
    elseif strcmp(muscle,'Quads')
        mNames = simulationObj.Muscles(1:4);
        axes_handles = zeros(1,4);
        for k = 1:4
            axes_handles(k) = subplot(2,2,k);
        end
    elseif strcmp(muscle,'Hamstrings')
        mNames = simulationObj.Muscles(5:8);
        axes_handles = zeros(1,4);
        for k = 1:4
            axes_handles(k) = subplot(2,2,k);
        end
    elseif strcmp(muscle,'Gastrocs')
        mNames = simulationObj.Muscles(9:10);
        axes_handles = zeros(1,2);
        for k = 1:2
            axes_handles(k) = subplot(1,2,k);
        end
    else
        mNames = {muscle};
        axes_handles = gca;
    end
end
