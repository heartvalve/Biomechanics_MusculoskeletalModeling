function createLegend(fig_handle,current_axes)
    % CREATELEGEND
    %
    %
    
    % Created by Megan Schroeder
    % Last Modified 2014-03-18
    
    
    %% Main
    % Main function definition
    
    set(fig_handle,'Units','normalized')
    lPos = [0.75 0.125 0.07 0.425];
    hLines = get(current_axes,'Children');
    checkLine = @(x) strcmp(get(x,'Type'),'line');
    hLines(~arrayfun(checkLine,hLines)) = [];
    nAnnotations = length(hLines);
    if nAnnotations <= 8
        hOutlineBoxAnnotation = annotation('rectangle');
        set(hOutlineBoxAnnotation,'Units','normalized');
        set(hOutlineBoxAnnotation,'Position',[lPos(1) lPos(2) lPos(3) 0.05+nAnnotations*0.025]);
        set(hOutlineBoxAnnotation,'FaceColor',[1 1 1]);
        set(hOutlineBoxAnnotation,'Tag','LegendAnnotation');
        hHeaderAnnotation = annotation('textbox');
        set(hHeaderAnnotation,'Units','normalized');
        set(hHeaderAnnotation,'Position',[lPos(1) lPos(2)+0.025+nAnnotations*0.025 lPos(3) 0.025]);
        set(hHeaderAnnotation,'HorizontalAlignment','center');
        set(hHeaderAnnotation,'String','Legend');
        set(hHeaderAnnotation,'FontWeight','bold');
        set(hHeaderAnnotation,'BackgroundColor',[0.39 0.47 0.64]);
        set(hHeaderAnnotation,'Color',[1 1 1]);
        set(hHeaderAnnotation,'EdgeColor',[0 0 0]);
        set(hHeaderAnnotation,'Tag','LegendAnnotation');
        Colors = zeros(nAnnotations,3);
        LineStyles = cell(nAnnotations,1);
        LineWidths = zeros(nAnnotations,1);
        DisplayNames = cell(nAnnotations,1);
        for i = 1:nAnnotations
            Colors(i,:) = get(hLines(i),'Color');
            LineStyles{i} = get(hLines(i),'LineStyle');
            LineWidths(i) = get(hLines(i),'LineWidth');
            DisplayNames{i} = get(hLines(i),'DisplayName');
        end
        Colors = flipud(Colors);
        LineStyles = flipud(LineStyles);
        LineWidths = flipud(LineWidths);
        DisplayNames = flipud(DisplayNames);
        hLineAnnotations = zeros(nAnnotations,1);
        for i = 1:nAnnotations
            hLineAnnotations(i) = annotation('line');
            set(hLineAnnotations(i),'Units','normalized');
            set(hLineAnnotations(i),'Position',[lPos(1)+0.05*lPos(3) lPos(2)+0.025+nAnnotations*0.025-i*0.025 lPos(3)*0.2 0]);
            set(hLineAnnotations(i),'Color',Colors(i,:));
            set(hLineAnnotations(i),'LineStyle',LineStyles{i});
            set(hLineAnnotations(i),'LineWidth',LineWidths(i));
            set(hLineAnnotations(i),'Tag','LegendAnnotation');
        end
        hLabelAnnotations = zeros(nAnnotations,1);
        for i = 1:nAnnotations
            hLabelAnnotations(i) = annotation('textbox');
            set(hLabelAnnotations(i),'Units','normalized');
            set(hLabelAnnotations(i),'Position',[lPos(1)+0.3*lPos(3) lPos(2)+0.0125+nAnnotations*0.025-i*0.025 lPos(3)*0.65 0.025]);
            set(hLabelAnnotations(i),'HorizontalAlignment','left');
            set(hLabelAnnotations(i),'VerticalAlignment','middle');
            set(hLabelAnnotations(i),'FontSize',8);
            set(hLabelAnnotations(i),'String',DisplayNames{i});
            set(hLabelAnnotations(i),'BackgroundColor','none');
            set(hLabelAnnotations(i),'EdgeColor','none');
            set(hLabelAnnotations(i),'Tag','LegendAnnotation');
        end
    %%%%%%%    
    else
        lPos = [0.525 0.05 0.42 0.425];
        hOutlineBoxAnnotation = annotation('rectangle');
        set(hOutlineBoxAnnotation,'Units','normalized');
        set(hOutlineBoxAnnotation,'Position',[lPos(1) lPos(2) lPos(3) 0.05+10*0.025]);
        set(hOutlineBoxAnnotation,'FaceColor',[1 1 1]);
        set(hOutlineBoxAnnotation,'Tag','LegendAnnotation');
        hHeaderAnnotation = annotation('textbox');
        set(hHeaderAnnotation,'Units','normalized');
        set(hHeaderAnnotation,'Position',[lPos(1) lPos(2)+0.025+10*0.025 lPos(3) 0.025]);
        set(hHeaderAnnotation,'HorizontalAlignment','center');
        set(hHeaderAnnotation,'String','Legend');
        set(hHeaderAnnotation,'FontWeight','bold');
        set(hHeaderAnnotation,'BackgroundColor',[0.39 0.47 0.64]);
        set(hHeaderAnnotation,'Color',[1 1 1]);
        set(hHeaderAnnotation,'EdgeColor',[0 0 0]);
        set(hHeaderAnnotation,'Tag','LegendAnnotation');
        Colors = zeros(nAnnotations,3);
        LineStyles = cell(nAnnotations,1);
        LineWidths = zeros(nAnnotations,1);
        DisplayNames = cell(nAnnotations,1);
        for i = 1:nAnnotations
            Colors(i,:) = get(hLines(i),'Color');
            LineStyles{i} = get(hLines(i),'LineStyle');
            LineWidths(i) = get(hLines(i),'LineWidth');
            DisplayNames{i} = get(hLines(i),'DisplayName');
        end
        Colors = flipud(Colors);
        LineStyles = flipud(LineStyles);
        LineWidths = flipud(LineWidths);
        DisplayNames = flipud(DisplayNames);
        hLineAnnotations = zeros(nAnnotations,1);
        for i = 1:nAnnotations
            hLineAnnotations(i) = annotation('line');
            set(hLineAnnotations(i),'Units','normalized');
            if i <= 10
                set(hLineAnnotations(i),'Position',[lPos(1)+0.025*lPos(3) lPos(2)+0.025+10*0.025-i*0.025 lPos(3)*0.2/4 0]);
            elseif i <= 20
                set(hLineAnnotations(i),'Position',[lPos(1)+(1/3+0.025)*lPos(3) lPos(2)+0.025+10*0.025-(i-10)*0.025 lPos(3)*0.2/4 0]);
            else
                set(hLineAnnotations(i),'Position',[lPos(1)+(2/3+0.025)*lPos(3) lPos(2)+0.025+10*0.025-(i-20)*0.025 lPos(3)*0.2/4 0]);
            end
            set(hLineAnnotations(i),'Color',Colors(i,:));
            set(hLineAnnotations(i),'LineStyle',LineStyles{i});
            set(hLineAnnotations(i),'LineWidth',LineWidths(i));
            set(hLineAnnotations(i),'Tag','LegendAnnotation');
        end
        hLabelAnnotations = zeros(nAnnotations,1);
        for i = 1:nAnnotations
            hLabelAnnotations(i) = annotation('textbox');
            set(hLabelAnnotations(i),'Units','normalized');
            if i <= 10 
                set(hLabelAnnotations(i),'Position',[lPos(1)+0.1*lPos(3) lPos(2)+0.0125+10*0.025-i*0.025 lPos(3)*0.65/4 0.025]);
            elseif i <= 20
                set(hLabelAnnotations(i),'Position',[lPos(1)+(1/3+0.1)*lPos(3) lPos(2)+0.0125+10*0.025-(i-10)*0.025 lPos(3)*0.65/4 0.025]);
            else
                set(hLabelAnnotations(i),'Position',[lPos(1)+(2/3+0.1)*lPos(3) lPos(2)+0.0125+10*0.025-(i-20)*0.025 lPos(3)*0.65/4 0.025]);
            end
            set(hLabelAnnotations(i),'HorizontalAlignment','left');
            set(hLabelAnnotations(i),'VerticalAlignment','middle');
            set(hLabelAnnotations(i),'FontSize',8);
            set(hLabelAnnotations(i),'String',DisplayNames{i});
            set(hLabelAnnotations(i),'BackgroundColor','none');
            set(hLabelAnnotations(i),'EdgeColor','none');
            set(hLabelAnnotations(i),'Tag','LegendAnnotation');
        end        
    end
        
end
