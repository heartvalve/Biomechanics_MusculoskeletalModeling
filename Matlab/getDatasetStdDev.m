function dsStdDev = getDatasetStdDev(cycleName,dSet,varargin)
    % GETDATASETSTDDEV
    %
    %
    
    % Created by Megan Schroeder
    % Last Modified 2014-03-18
    
    
    %% Main
    % Main function definition
    
    if nargin == 2
        dsnames = dSet.Properties.VarNames;
        newdata = zeros(size(dSet));
        for i = 1:length(dsnames)
            newdata(:,i) = nanstd(dSet.(dsnames{i}),0,2);
        end    
        % Interpolate around data endpoint (Stair Descent to Floor - only for torques)
        if ~isempty(regexp(cycleName,'2F','ONCE')) && size(dSet,2) == 10
            % First column only
            newdataWithNaNs = std(dSet.(dsnames{1}),0,2);
            % First NaN index
            nanFirst = find(isnan(newdataWithNaNs),1,'first');
            % Make sure that there was at least 1 trial with data
            if isempty(find(isnan(newdata(:,1)),1,'first'))
                newdata(nanFirst:nanFirst+5,:) = NaN;
                nanInd = isnan(newdata(:,1));
                x = (0:100)';
                for i = 1:length(dsnames)
                    newdata(nanInd,i) = interp1(x(~nanInd),newdata(~nanInd,i),x(nanInd),'linear');
                end
            else
                newdata = zeros(size(dSet));
                for i = 1:length(dsnames)
                    newdata(:,i) = std(dSet.(dsnames{i}),0,2);
                end
            end
        % Stair descent to step - only subject 20130207APRM
        elseif ~isempty(regexp(cycleName,'2S','ONCE')) && size(dSet,2) == 10
            % Subject 20130207APRM doesn't have data at the beginning for any trials
            if all(isnan(newdata(1,:)))
                newdata = zeros(size(dSet));
                for i = 1:length(dsnames)
                    newdata(:,i) = std(dSet.(dsnames{i}),0,2);
                end
            % Patella tendon group b/c of subject 20130207APRM - interpolate around data start point
            elseif any(isnan(dSet.(dsnames{1})(1,:)))
                % First column only
                newdataWithNaNs = std(dSet.(dsnames{1}),0,2);
                % Last NaN index
                nanLast = find(isnan(newdataWithNaNs),1,'last');               
                newdata(nanLast-5:nanLast,:) = NaN;
                nanInd = isnan(newdata(:,1));
                x = (0:100)';
                for i = 1:length(dsnames)
                    newdata(nanInd,i) = interp1(x(~nanInd),newdata(~nanInd,i),x(nanInd),'spline');
                end    
            end
        end
    % Group    
    else
        dsnames = dSet.Properties.VarNames;
        weights = varargin{1};
        newdata = zeros(size(dSet));
        for i = 1:length(dsnames)
            newdata(:,i) = sqrt(nanvar(dSet.(dsnames{i}),weights',2));
        end
        if ~isempty(regexp(cycleName,'2F','ONCE'))
            % Interpolate around date end point
            if any(isnan(dSet.(dsnames{1})(end,:)))
                % First column only
                newdataWithNaNs = std(dSet.(dsnames{1}),0,2);
                % First NaN index
                nanFirst = find(isnan(newdataWithNaNs),1,'first');                
                newdata(nanFirst:nanFirst+5,:) = NaN;
                nanInd = isnan(newdata(:,1));
                x = (0:100)';
                for i = 1:length(dsnames)
                    newdata(nanInd,i) = interp1(x(~nanInd),newdata(~nanInd,i),x(nanInd),'spline');
                end
            end            
        elseif ~isempty(regexp(cycleName,'2S','ONCE'))        
            % Patella tendon group b/c of subject 20130207APRM - interpolate around data start point
            if any(isnan(dSet.(dsnames{1})(1,:)))
                % First column only
                newdataWithNaNs = std(dSet.(dsnames{1}),0,2);
                % Last NaN index
                nanLast = find(isnan(newdataWithNaNs),1,'last');               
                newdata(nanLast-5:nanLast,:) = NaN;
                nanInd = isnan(newdata(:,1));
                x = (0:100)';
                for i = 1:length(dsnames)
                    newdata(nanInd,i) = interp1(x(~nanInd),newdata(~nanInd,i),x(nanInd),'spline');
                end
            end
        end
    end
    dsStdDev = dataset({newdata,dsnames{:}});

end
