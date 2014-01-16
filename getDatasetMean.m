function dsMean = getDatasetMean(cycleName,dSet,dim)
    % GETDATASETMEAN
    %
    %
    
    % Created by Megan Schroeder
    % Last Modified 2014-01-14
    
    
    %% Main
    % Main function definition
    
    dsnames = dSet.Properties.VarNames;
    if dim == 1
        newdata = zeros(1,length(dsnames));
        for i = 1:length(dsnames)    
            newdata(:,i) = mean(dSet.(dsnames{i}));
        end
    elseif dim == 2
        newdata = zeros(size(dSet));
        for i = 1:length(dsnames)
            newdata(:,i) = nanmean(dSet.(dsnames{i}),2);
        end
        % Interpolate around data endpoint (Stair Descent to Floor - only for muscle forces)
        if ~isempty(regexp(cycleName,'ToFloor','ONCE')) && size(dSet,2) == 10
            % First column only
            newdataWithNaNs = mean(dSet.(dsnames{1}),2);
            % First NaN index
            nanFirst = find(isnan(newdataWithNaNs),1,'first');
            % Make sure that there was at least 1 trial with data
            if isempty(find(isnan(newdata(:,1)),1,'first'))
                newdata(nanFirst:nanFirst+5,:) = NaN;
                nanInd = isnan(newdata(:,1));
                x = (0:100)';
                for i = 1:length(dsnames)
                    newdata(nanInd,i) = interp1(x(~nanInd),newdata(~nanInd,i),x(nanInd),'spline');
                end
            end
        end
    end
    dsMean = dataset({newdata,dsnames{:}});
    
end
