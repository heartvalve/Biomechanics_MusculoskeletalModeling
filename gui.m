function gui(dataSummary)
    % GUI
    %
    %
    
    % Created by Megan Schroeder
    % Last Modified 2013-09-17
    
    
    %% Input
    %
    if nargin == 0
        try
            dataSummary = evalin('base','data');
        catch
            hMsg = msgbox('Please wait a few minutes while data is being loaded into the main workspace.','Variable Creation');           
            evalin('base','clear all');
            assignin('base','data',OpenSim.summary);
            dataSummary = evalin('base','data');
            delete(hMsg);
        end
    end
    
    %% Initialization
    %
    close('all','force');
    set(0,'Units','pixels');
    scrnsize = get(0,'ScreenSize');
    hFigure = figure('Position',[scrnsize(1)+0.01*scrnsize(3) scrnsize(2)+0.05*scrnsize(4) scrnsize(3)*0.98 scrnsize(4)*0.92], ...
                     'Name','OpenSim Display GUI', ...
                     'NumberTitle','off', ...
                     'Toolbar','none', ...
                     'MenuBar','none', ...
                     'DockControls','off', ...
                     'Units','normalized', ...
                     'Visible','off');
    clear scrnsize
    %%%
    choicesSummaryMethodList = methods(dataSummary);
    tempLogical = strncmp('plot',choicesSummaryMethodList,4);
    choicesSummaryMethodList(~tempLogical) = [];
    clear tempLogical
    choicesSummaryMethodList = [{''}; choicesSummaryMethodList];
    choicesSummaryCycleList = get(dataSummary.control.cycles,'ObsNames');
    choicesSummaryCycleList = [{''}; choicesSummaryCycleList];
    choicesGroupList = properties(dataSummary);   
    choicesGroupList = [{''}; choicesGroupList];
    
    %% Menus
    %
    hSummaryMenuPanel = uipanel('Parent',hFigure, ...
                                'Units','normalized', ...
                                'Position',[0.8 0.8 0.1 0.18], ...
                                'BorderType','none', ...
                                'BackgroundColor',get(hFigure,'color'));
    hSummaryMethodHeader = uicontrol('Parent',hSummaryMenuPanel, ...
                                     'Style','text', ...
                                     'Units','normalized', ...
                                     'Position',[0 0.9 0.75 0.125], ...
                                     'String','Summary Method', ...
                                     'FontWeight','bold', ...
                                     'HorizontalAlignment','left', ...
                                     'BackgroundColor',get(hFigure,'color'));
    hSummaryMethodList = uicontrol('Parent',hSummaryMenuPanel, ...
                                   'Style','popupmenu', ...
                                   'Units','normalized', ...
                                   'Position',[0 0.8 0.75 0.125], ...
                                   'String',choicesSummaryMethodList, ...
                                   'Callback',{@hSummaryMethodList_Callback});
    hSummaryCycleHeader = uicontrol('Parent',hSummaryMenuPanel, ...
                                    'Style','text', ...
                                    'Units','normalized', ...
                                    'Position',[0 0.65 0.75 0.125], ...
                                    'String','Cycle', ...
                                    'FontWeight','bold', ...
                                    'HorizontalAlignment','left', ...    
                                    'BackgroundColor',get(hFigure,'color'));
    hSummaryCycleList = uicontrol('Parent',hSummaryMenuPanel, ...
                                  'Style','popupmenu', ...
                                  'Units','normalized', ...
                                  'Position',[0 0.55 0.75 0.125], ...
                                  'String',choicesSummaryCycleList);
    hSummarySpecifierHeader = uicontrol('Parent',hSummaryMenuPanel, ...
                                        'Style','text', ...
                                        'Units','normalized', ...
                                        'Position',[0 0.4 0.75 0.125], ...
                                        'String','Specifier', ...
                                        'FontWeight','bold', ...
                                        'HorizontalAlignment','left', ...
                                        'BackgroundColor',get(hFigure,'color'));
    hSummarySpecifierList = uicontrol('Parent',hSummaryMenuPanel, ...
                                      'Style','popupmenu', ...
                                      'Units','normalized', ...
                                      'Position',[0 0.3 0.75 0.125], ...
                                      'String',{''});
    hSummaryUpdateButton = uicontrol('Parent',hSummaryMenuPanel, ...
                                     'Style','pushbutton', ...
                                     'Units','normalized', ...
                                     'Position',[0 0.075 0.75 0.125], ...
                                     'String','<  Plot Summary  >', ...
                                     'FontWeight','bold', ...    
                                     'BackgroundColor',[1 0.4 0.6], ...
                                     'ForegroundColor',[1 1 1], ...
                                     'Callback',{@hSummaryUpdateButton_Callback});
    %%%
    hGroupMenuPanel = uipanel('Parent',hFigure, ...
                              'Units','normalized', ...
                              'Position',[0.8 0.54 0.1 0.24], ...
                              'BorderType','none', ...
                              'BackgroundColor',get(hFigure,'color'));
    hGroupHeader = uicontrol('Parent',hGroupMenuPanel, ...
                             'Style','text', ...
                             'Units','normalized', ...
                             'Position',[0 0.95 0.75 0.1], ...
                             'String','Group', ...
                             'FontWeight','bold', ...
                             'HorizontalAlignment','left', ...
                             'BackgroundColor',get(hFigure,'color'));
    hGroupList = uicontrol('Parent',hGroupMenuPanel, ...
                           'Style','popupmenu', ...
                           'Units','normalized', ...
                           'Position',[0 0.875 0.75 0.1], ...
                           'String',choicesGroupList, ...
                           'Callback',{@hGroupList_Callback});
    hGroupMethodHeader = uicontrol('Parent',hGroupMenuPanel, ...
                                   'Style','text', ...
                                   'Units','normalized', ...
                                   'Position',[0 0.75 0.75 0.1], ...
                                   'String','Group Method', ...
                                   'FontWeight','bold', ...
                                   'HorizontalAlignment','left', ...
                                   'BackgroundColor',get(hFigure,'color'));
    hGroupMethodList = uicontrol('Parent',hGroupMenuPanel, ...
                                 'Style','popupmenu', ...
                                 'Units','normalized', ...
                                 'Position',[0 0.675 0.75 0.1], ...
                                 'String',{''}, ...
                                 'Callback',{@hGroupMethodList_Callback});
    hGroupCycleHeader = uicontrol('Parent',hGroupMenuPanel, ...
                                  'Style','text', ...
                                  'Units','normalized', ...
                                  'Position',[0 0.55 0.75 0.1], ...
                                  'String','Cycle', ...
                                  'FontWeight','bold', ...
                                  'HorizontalAlignment','left', ...    
                                  'BackgroundColor',get(hFigure,'color'));
    hGroupCycleList = uicontrol('Parent',hGroupMenuPanel, ...
                                'Style','popupmenu', ...
                                'Units','normalized', ...
                                'Position',[0 0.475 0.75 0.1], ...
                                'String',{''});    
    hGroupSpecifierHeader = uicontrol('Parent',hGroupMenuPanel, ...
                                      'Style','text', ...
                                      'Units','normalized', ...
                                      'Position',[0 0.35 0.75 0.1], ...
                                      'String','Specifier', ...
                                      'FontWeight','bold', ...
                                      'HorizontalAlignment','left', ...
                                      'BackgroundColor',get(hFigure,'color'));
    hGroupSpecifierList = uicontrol('Parent',hGroupMenuPanel, ...
                                    'Style','popupmenu', ...
                                    'Units','normalized', ...
                                    'Position',[0 0.275 0.75 0.1], ...
                                    'String',{''});
    hGroupUpdateButton = uicontrol('Parent',hGroupMenuPanel, ...
                                   'Style','pushbutton', ...
                                   'Units','normalized', ...
                                   'Position',[0 0.1 0.75 0.1], ...
                                   'String','<  Plot Group  >', ...
                                   'FontWeight','bold', ...    
                                   'BackgroundColor',[0.2 0.6 1], ...
                                   'ForegroundColor',[1 1 1], ...
                                   'Callback',{@hGroupUpdateButton_Callback});
    %%%
    hSubjectMenuPanel = uipanel('Parent',hFigure, ...
                                'Units','normalized', ...
                                'Position',[0.8 0.28 0.1 0.24], ...
                                'BorderType','none', ...
                                'BackgroundColor',get(hFigure,'color'));
    hSubjectHeader = uicontrol('Parent',hSubjectMenuPanel, ...
                               'Style','text', ...
                               'Units','normalized', ...
                               'Position',[0 0.95 0.75 0.1], ...
                               'String','Subject', ...
                               'FontWeight','bold', ...
                               'HorizontalAlignment','left', ...
                               'BackgroundColor',get(hFigure,'color'));
    hSubjectList = uicontrol('Parent',hSubjectMenuPanel, ...
                             'Style','popupmenu', ...
                             'Units','normalized', ...
                             'Position',[0 0.875 0.75 0.1], ...
                             'String',{''}, ...
                             'Callback',{@hSubjectList_Callback});    
    hSubjectMethodHeader = uicontrol('Parent',hSubjectMenuPanel, ...
                                     'Style','text', ...
                                     'Units','normalized', ...
                                     'Position',[0 0.75 0.75 0.1], ...
                                     'String','Subject Method', ...
                                     'FontWeight','bold', ...
                                     'HorizontalAlignment','left', ...    
                                     'BackgroundColor',get(hFigure,'color'));
    hSubjectMethodList = uicontrol('Parent',hSubjectMenuPanel, ...
                                   'Style','popupmenu', ...
                                   'Units','normalized', ...
                                   'Position',[0 0.675 0.75 0.1], ...
                                   'String',{''}, ...
                                   'Callback',{@hSubjectMethodList_Callback});
    hSubjectCycleHeader = uicontrol('Parent',hSubjectMenuPanel, ...
                                    'Style','text', ...
                                    'Units','normalized', ...
                                    'Position',[0 0.55 0.75 0.1], ...
                                    'String','Cycle', ...
                                    'FontWeight','bold', ...
                                    'HorizontalAlignment','left', ...    
                                    'BackgroundColor',get(hFigure,'color'));
    hSubjectCycleList = uicontrol('Parent',hSubjectMenuPanel, ...
                                  'Style','popupmenu', ...
                                  'Units','normalized', ...
                                  'Position',[0 0.475 0.75 0.1], ...
                                  'String',{''});    
    hSubjectSpecifierHeader = uicontrol('Parent',hSubjectMenuPanel, ...
                                        'Style','text', ...
                                        'Units','normalized', ...
                                        'Position',[0 0.35 0.75 0.1], ...
                                        'String','Specifier', ...
                                        'FontWeight','bold', ...
                                        'HorizontalAlignment','left', ...    
                                        'BackgroundColor',get(hFigure,'color'));
    hSubjectSpecifierList = uicontrol('Parent',hSubjectMenuPanel, ...
                                      'Style','popupmenu', ...
                                      'Units','normalized', ...
                                      'Position',[0 0.275 0.75 0.1], ...
                                      'String',{''});    
    hSubjectUpdateButton = uicontrol('Parent',hSubjectMenuPanel, ...
                                     'Style','pushbutton', ...
                                     'Units','normalized', ...
                                     'Position',[0 0.1 0.75 0.1], ...
                                     'String','<  Plot Subject  >', ...
                                     'FontWeight','bold', ...    
                                     'BackgroundColor',[0.6 0.4 1], ...
                                     'ForegroundColor',[1 1 1], ...
                                     'Callback',{@hSubjectUpdateButton_Callback});
    %%%
    hSimulationMenuPanel = uipanel('Parent',hFigure, ...
                                   'Units','normalized', ...
                                   'Position',[0.8 0.02 0.1 0.24], ...
                                   'BorderType','none', ...
                                   'BackgroundColor',get(hFigure,'color'));
    hSimulationHeader = uicontrol('Parent',hSimulationMenuPanel, ...
                                  'Style','text', ...
                                  'Units','normalized', ...
                                  'Position',[0 0.95 0.75 0.1], ...
                                  'String','Simulation', ...
                                  'FontWeight','bold', ...
                                  'HorizontalAlignment','left', ...
                                  'BackgroundColor',get(hFigure,'color'));
    hSimulationList = uicontrol('Parent',hSimulationMenuPanel, ...
                                'Style','popupmenu', ...
                                'Units','normalized', ...
                                'Position',[0 0.875 0.75 0.1], ...
                                'String',{''}, ...
                                'Callback',{@hSimulationList_Callback});    
    hSimulationMethodHeader = uicontrol('Parent',hSimulationMenuPanel, ...
                                        'Style','text', ...
                                        'Units','normalized', ...
                                        'Position',[0 0.75 0.75 0.1], ...
                                        'String','Simulation Method', ...
                                        'FontWeight','bold', ...
                                        'HorizontalAlignment','left', ...    
                                        'BackgroundColor',get(hFigure,'color'));
    hSimulationMethodList = uicontrol('Parent',hSimulationMenuPanel, ...
                                      'Style','popupmenu', ...
                                      'Units','normalized', ...
                                      'Position',[0 0.675 0.75 0.1], ...
                                      'String',{''}, ...
                                      'Callback',{@hSimulationMethodList_Callback});
    hSimulationCycleHeader = uicontrol('Parent',hSimulationMenuPanel, ...
                                       'Style','text', ...
                                       'Units','normalized', ...
                                       'Position',[0 0.55 0.75 0.1], ...
                                       'String','Cycle', ...
                                       'FontWeight','bold', ...
                                       'HorizontalAlignment','left', ...    
                                       'BackgroundColor',get(hFigure,'color'));
    hSimulationCycleList = uicontrol('Parent',hSimulationMenuPanel, ...
                                     'Style','popupmenu', ...
                                     'Units','normalized', ...
                                     'Position',[0 0.475 0.75 0.1], ...
                                     'String',{''});
    hSimulationSpecifierHeader = uicontrol('Parent',hSimulationMenuPanel, ...
                                           'Style','text', ...
                                           'Units','normalized', ...
                                           'Position',[0 0.35 0.75 0.1], ...
                                           'String','Specifier', ...
                                           'FontWeight','bold', ...
                                           'HorizontalAlignment','left', ...    
                                           'BackgroundColor',get(hFigure,'color'));
    hSimulationSpecifierList = uicontrol('Parent',hSimulationMenuPanel, ...
                                         'Style','popupmenu', ...
                                         'Units','normalized', ...
                                         'Position',[0 0.275 0.75 0.1], ...
                                         'String',{''});                          
    hSimulationUpdateButton = uicontrol('Parent',hSimulationMenuPanel, ...
                                        'Style','pushbutton', ...
                                        'Units','normalized', ...
                                        'Position',[0 0.1 0.75 0.1], ...
                                        'String','<  Plot Simulation  >', ...
                                        'FontWeight','bold', ...    
                                        'BackgroundColor',[0 0.6 0.6], ...
                                        'ForegroundColor',[1 1 1], ...
                                        'Callback',{@hSimulationUpdateButton_Callback});
    
    %% Information
    %
    hPanelHeader = uicontrol('Parent',hFigure, ...
                             'Style','text', ...
                             'Units','normalized', ...
                             'Position',[0.025 0.955 0.75 0.0325], ...
                             'String',{''}, ...
                             'FontName','Times New Roman', ...
                             'FontSize',20, ...
                             'FontWeight','bold', ...
                             'HorizontalAlignment','center', ...    
                             'BackgroundColor',[0.39 0.47 0.64], ...
                             'ForegroundColor',[1 1 1]);
    
    %% Toolbar
    %
    hPanel_Toolbar = uipanel('Parent',hFigure, ...
                             'Units','normalized', ...
                             'Position',[0.00625 0.025 0.015 .925], ...
                             'BackgroundColor',get(hFigure,'color'), ...
                             'BorderType','none', ...
                             'Visible','off');                         
    SaveIcon = imread(fullfile(matlabroot,'toolbox','matlab','icons','file_save.png'),'BackgroundColor',get(hFigure,'color'));
    hToolbarSaveButton = uicontrol('Parent',hPanel_Toolbar, ...
                                   'Style','pushbutton', ...
                                   'Units','normalized', ...
                                   'Position',[0 0.94 1 0.0325], ...
                                   'CData',im2double(SaveIcon), ...
                                   'BackgroundColor',get(hFigure,'color'), ...
                                   'TooltipString','Save As AI', ...
                                   'Callback',{@hToolbarSaveButton_Callback});
    ZoomIcon = imread(fullfile(matlabroot,'toolbox','matlab','icons','tool_zoom_in.png'),'BackgroundColor',get(hFigure,'color'));
    hToolbarZoomButton = uicontrol('Parent',hPanel_Toolbar, ...
                                   'Style','togglebutton', ...
                                   'Units','normalized', ...
                                   'Position',[0 0.9 1 0.0325], ...
                                   'CData',im2double(ZoomIcon), ...
                                   'BackgroundColor',get(hFigure,'color'), ...
                                   'TooltipString','Zoom In', ...
                                   'Callback',{@hToolbarZoomButton_Callback});
    PanIcon = imread(fullfile(matlabroot,'toolbox','matlab','icons','tool_hand.png'),'BackgroundColor',get(hFigure,'color'));
    hToolbarPanButton = uicontrol('Parent',hPanel_Toolbar, ...
                                  'Style','togglebutton', ...
                                  'Units','normalized', ...
                                  'Position',[0 0.86 1 0.0325], ...
                                  'CData',im2double(PanIcon), ...
                                  'BackgroundColor',get(hFigure,'color'), ...
                                  'TooltipString','Pan', ...
                                  'Callback',{@hToolbarPanButton_Callback});                               
    RotateIcon = imread(fullfile(matlabroot,'toolbox','matlab','icons','tool_rotate_3d.png'),'BackgroundColor',get(hFigure,'color'));
    hToolbarRotateButton = uicontrol('Parent',hPanel_Toolbar, ...
                                     'Style','togglebutton', ...
                                     'Units','normalized', ...
                                     'Position',[0 0.82 1 0.0325], ...
                                     'CData',im2double(RotateIcon), ...
                                     'BackgroundColor',get(hFigure,'color'), ...
                                     'TooltipString','Rotate 3D', ...
                                     'Callback',{@hToolbarRotateButton_Callback});   

    %% Axes
    %
    hPanel_1x1 = uipanel('Parent',hFigure, ...
                         'Units','normalized', ...
                         'Position',[0.025 0.025 0.75 0.925], ...
                         'BorderType','none', ...
                         'Visible','off');
    hPanel_1x2 = uipanel('Parent',hFigure, ...
                         'Units','normalized', ...
                         'Position',[0.025 0.025 0.75 0.925], ...
                         'BorderType','none', ...
                         'Visible','off');
    hPanel_2x2 = uipanel('Parent',hFigure, ...
                         'Units','normalized', ...
                         'Position',[0.025 0.025 0.75 0.925], ...
                         'BorderType','none', ...
                         'Visible','off');
    hPanel_3x1 = uipanel('Parent',hFigure, ...
                         'Units','normalized', ...
                         'Position',[0.025 0.025 0.75 0.925], ...
                         'BorderType','none', ...
                         'Visible','off');
    hPanel_3x2 = uipanel('Parent',hFigure, ...
                         'Units','normalized', ...
                         'Position',[0.025 0.025 0.75 0.925], ...
                         'BorderType','none', ...
                         'Visible','off');
    hPanel_3x3 = uipanel('Parent',hFigure, ...
                         'Units','normalized', ...
                         'Position',[0.025 0.025 0.75 0.925], ...
                         'BorderType','none', ...
                         'Visible','off');
    hPanel_3x4 = uipanel('Parent',hFigure, ...
                         'Units','normalized', ...
                         'Position',[0.025 0.025 0.75 0.925], ...
                         'BorderType','none', ...
                         'Visible','off');
    hPanels_All = [hPanel_1x1, hPanel_1x2, hPanel_2x2, hPanel_3x1, hPanel_3x2, hPanel_3x3, hPanel_3x4, hPanel_Toolbar];
    %%%
    hAxes_1x1 = axes('Parent',hPanel_1x1, ...
                     'Units','normalized', ...
                     'OuterPosition',[0 0 1 1]);
    hAxes_1x2_1 = axes('Parent',hPanel_1x2, ...
                       'Units','normalized', ...
                       'OuterPosition',[0 0 0.5 1]);
    hAxes_1x2_2 = axes('Parent',hPanel_1x2, ...
                       'Units','normalized', ...
                       'OuterPosition',[0.5 0 0.5 1]);
    hAxes_2x2_1 = axes('Parent',hPanel_2x2, ...
                       'Units','normalized', ...
                       'OuterPosition',[0 0.5 0.5 0.5]);
    hAxes_2x2_2 = axes('Parent',hPanel_2x2, ...
                       'Units','normalized', ...
                       'OuterPosition',[0.5 0.5 0.5 0.5]);
    hAxes_2x2_3 = axes('Parent',hPanel_2x2, ...
                       'Units','normalized', ...
                       'OuterPosition',[0 0 0.5 0.5]);
    hAxes_2x2_4 = axes('Parent',hPanel_2x2, ...
                       'Units','normalized', ...
                       'OuterPosition',[0.5 0 0.5 0.5]);   
    hAxes_3x1_1 = axes('Parent',hPanel_3x1, ...
                       'Units','normalized', ...
                       'OuterPosition',[0 0.67 1 0.33]);
    hAxes_3x1_2 = axes('Parent',hPanel_3x1, ...
                       'Units','normalized', ...
                       'OuterPosition',[0 0.33 1 0.33]);
    hAxes_3x1_3 = axes('Parent',hPanel_3x1, ...
                       'Units','normalized', ...
                       'OuterPosition',[0 0 1 0.33]);               
    hAxes_3x2_1 = axes('Parent',hPanel_3x2, ...
                       'Units','normalized', ...
                       'OuterPosition',[0 0.67 0.5 0.33]);
    hAxes_3x2_2 = axes('Parent',hPanel_3x2, ...
                       'Units','normalized', ...
                       'OuterPosition',[0.5 0.67 0.5 0.33]);
    hAxes_3x2_3 = axes('Parent',hPanel_3x2, ...
                       'Units','normalized', ...
                       'OuterPosition',[0 0.33 0.5 0.33]);
    hAxes_3x2_4 = axes('Parent',hPanel_3x2, ...
                       'Units','normalized', ...
                       'OuterPosition',[0.5 0.33 0.5 0.33]);
    hAxes_3x2_5 = axes('Parent',hPanel_3x2, ...
                       'Units','normalized', ...
                       'OuterPosition',[0 0 0.5 0.33]);
    hAxes_3x2_6 = axes('Parent',hPanel_3x2, ...
                       'Units','normalized', ...
                       'OuterPosition',[0.5 0 0.5 0.33]);
    hAxes_3x3_1 = axes('Parent',hPanel_3x3, ...
                       'Units','normalized', ...
                       'OuterPosition',[0 0.67 0.33 0.33]);
    hAxes_3x3_2 = axes('Parent',hPanel_3x3, ...
                       'Units','normalized', ...
                       'OuterPosition',[0.33 0.67 0.33 0.33]);
    hAxes_3x3_3 = axes('Parent',hPanel_3x3, ...
                       'Units','normalized', ...
                       'OuterPosition',[0.67 0.67 0.33 0.33]);
    hAxes_3x3_4 = axes('Parent',hPanel_3x3, ...
                       'Units','normalized', ...
                       'OuterPosition',[0 0.33 0.33 0.33]);
    hAxes_3x3_5 = axes('Parent',hPanel_3x3, ...
                       'Units','normalized', ...
                       'OuterPosition',[0.33 0.33 0.33 0.33]);
    hAxes_3x3_6 = axes('Parent',hPanel_3x3, ...
                       'Units','normalized', ...
                       'OuterPosition',[0.67 0.33 0.33 0.33]);
    hAxes_3x3_7 = axes('Parent',hPanel_3x3, ...
                       'Units','normalized', ...
                       'OuterPosition',[0 0 0.33 0.33]);
    hAxes_3x3_8 = axes('Parent',hPanel_3x3, ...
                       'Units','normalized', ...
                       'OuterPosition',[0.33 0 0.33 0.33]);
    hAxes_3x3_9 = axes('Parent',hPanel_3x3, ...
                       'Units','normalized', ...
                       'OuterPosition',[0.67 0 0.33 0.33]);
    hAxes_3x4_1 = axes('Parent',hPanel_3x4, ...
                       'Units','normalized', ...
                       'OuterPosition',[0 0.67 0.25 0.33]);
    hAxes_3x4_2 = axes('Parent',hPanel_3x4, ...
                       'Units','normalized', ...
                       'OuterPosition',[0.25 0.67 0.25 0.33]);
    hAxes_3x4_3 = axes('Parent',hPanel_3x4, ...
                       'Units','normalized', ...
                       'OuterPosition',[0.5 0.67 0.25 0.33]);
    hAxes_3x4_4 = axes('Parent',hPanel_3x4, ...
                       'Units','normalized', ...
                       'OuterPosition',[0.75 0.67 0.25 0.33]);
    hAxes_3x4_5 = axes('Parent',hPanel_3x4, ...
                       'Units','normalized', ...
                       'OuterPosition',[0 0.33 0.25 0.33]);
    hAxes_3x4_6 = axes('Parent',hPanel_3x4, ...
                       'Units','normalized', ...
                       'OuterPosition',[0.25 0.33 0.25 0.33]);
    hAxes_3x4_7 = axes('Parent',hPanel_3x4, ...
                       'Units','normalized', ...
                       'OuterPosition',[0.5 0.33 0.25 0.33]);
    hAxes_3x4_8 = axes('Parent',hPanel_3x4, ...
                       'Units','normalized', ...
                       'OuterPosition',[0.75 0.33 0.25 0.33]);
    hAxes_3x4_9 = axes('Parent',hPanel_3x4, ...
                       'Units','normalized', ...
                       'OuterPosition',[0 0 0.25 0.33]);
    hAxes_3x4_10 = axes('Parent',hPanel_3x4, ...
                        'Units','normalized', ...
                        'OuterPosition',[0.25 0 0.25 0.33]);
    hAxes_1x2 = [hAxes_1x2_1, hAxes_1x2_2];
    hAxes_2x2 = [hAxes_2x2_1, hAxes_2x2_2, hAxes_2x2_3, hAxes_2x2_4];
    hAxes_3x1 = [hAxes_3x1_1, hAxes_3x1_2, hAxes_3x1_3];
    hAxes_3x2 = [hAxes_3x2_1, hAxes_3x2_2, hAxes_3x2_3, hAxes_3x2_4, ...
                 hAxes_3x2_5, hAxes_3x2_6];
    hAxes_3x3 = [hAxes_3x3_1, hAxes_3x3_2, hAxes_3x3_3, ...
                 hAxes_3x3_4, hAxes_3x3_5, hAxes_3x3_6, ...
                 hAxes_3x3_7, hAxes_3x3_8, hAxes_3x3_9];
    hAxes_3x4 = [hAxes_3x4_1, hAxes_3x4_2, hAxes_3x4_3, hAxes_3x4_4, ...
                 hAxes_3x4_5, hAxes_3x4_6, hAxes_3x4_7, hAxes_3x4_8, ...
                 hAxes_3x4_9, hAxes_3x4_10];
    hAxes_All = [hAxes_1x1, hAxes_1x2, hAxes_2x2, hAxes_3x1, hAxes_3x2, hAxes_3x3, hAxes_3x4];
    set(hAxes_All,'NextPlot','replace');    
    
    %% Callbacks
    %
    function hSummaryMethodList_Callback(hSummaryMethodList,eventdata)
        deleteLegend;
        indexSummaryMethodList = get(hSummaryMethodList,'Value');
        choicesSummaryMethodList = get(hSummaryMethodList,'String');
        if indexSummaryMethodList == 1
            set(hSummaryCycleList,'Value',1);
            set(hSummarySpecifierList,'Value',1);
        else
            SummaryMethod = choicesSummaryMethodList{indexSummaryMethodList};
            switch SummaryMethod
                case 'plotMuscleForces'
                    choicesSummarySpecifierList = {''; 'All'; 'Quads'; ...
                                                   'Hamstrings'; 'Gastrocs'; ...
                                                   'vasmed'; 'vaslat'; ...
                                                   'vasint'; 'recfem'; ...
                                                   'semimem'; 'semiten'; ...
                                                   'bflh'; 'bfsh'; ...
                                                   'gasmed'; 'gaslat'};
            end
            if get(hSummaryCycleList,'Value') == 1
                set(hSummaryCycleList,'Value',2);
            end
            set(hSummarySpecifierList,'String',choicesSummarySpecifierList);
            set(hSummarySpecifierList,'Value',2);
        end
        set(hGroupList,'Value',1);
        set(hGroupMethodList,'Value',1);
        set(hGroupCycleList,'Value',1);
        set(hGroupSpecifierList,'Value',1);        
        set(hSubjectList,'Value',1);
        set(hSubjectMethodList,'Value',1);
        set(hSubjectCycleList,'Value',1);
        set(hSubjectSpecifierList,'Value',1);
        set(hSimulationList,'Value',1);
        set(hSimulationMethodList,'Value',1);
        set(hSimulationCycleList,'Value',1);
        set(hSimulationSpecifierList,'Value',1);
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function hSummaryUpdateButton_Callback(hObject,eventdata)
        set(hFigure,'RendererMode','auto');
        deleteLegend;
        set(hPanels_All,'Visible','off');
        set(hAxes_All,'NextPlot','replace');
        indexSummaryMethodList = get(hSummaryMethodList,'Value');
        choicesSummaryMethodList = get(hSummaryMethodList,'String');
        SummaryMethod = choicesSummaryMethodList{indexSummaryMethodList};
        indexSummaryCycleList = get(hSummaryCycleList,'Value');
        choicesSummaryCycleList = get(hSummaryCycleList,'String');
        SummaryCycle = choicesSummaryCycleList{indexSummaryCycleList};
        indexSummarySpecifierList = get(hSummarySpecifierList,'Value');
        choicesSummarySpecifierList = get(hSummarySpecifierList,'String');
        SummarySpecifier = choicesSummarySpecifierList{indexSummarySpecifierList};
        if strcmp(SummaryMethod,'') || strcmp(SummaryCycle,'') || strcmp(SummarySpecifier,'')
            msgbox('Please select a Summary Method, Cycle, and Specifier','Update Selections','warn');
        else
            SummaryRef = dataSummary;
            switch SummaryMethod
                case 'plotMuscleForces'
                    set(hPanelHeader,'String',['Summary_',SummaryCycle,':  Muscle Forces - ',SummarySpecifier]);
                    switch SummarySpecifier
                        case 'All'
                            legendStruct = SummaryRef.plotMuscleForces(SummaryCycle,SummarySpecifier,hFigure,hAxes_3x4);
                            set(hPanel_3x4,'Visible','on');                       
                        case {'Quads','Hamstrings'}
                            legendStruct = SummaryRef.plotMuscleForces(SummaryCycle,SummarySpecifier,hFigure,hAxes_2x2);
                            set(hPanel_2x2,'Visible','on');                                                
                        case 'Gastrocs'
                            legendStruct = SummaryRef.plotMuscleForces(SummaryCycle,SummarySpecifier,hFigure,hAxes_1x2);
                            set(hPanel_2x2,'Visible','on');
                        otherwise
                            legendStruct = SummaryRef.plotMuscleForces(SummaryCycle,SummarySpecifier,hFigure,hAxes_1x1);
                            set(hPanel_1x1,'Visible','on');
                    end                              
            end
        end
        createLegend(legendStruct);
        set(hPanel_Toolbar,'Visible','on');            
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function hGroupList_Callback(hGroupList,eventdata)
        deleteLegend;
        set(hInfoPanels_All,'Visible','on');
        indexGroupList = get(hGroupList,'Value');
        choicesGroupList = get(hGroupList,'String');
        if indexGroupList == 1
            set(hGroupInfoTable1,'Visible','off');
            set(hGroupInfoTable2f,'String',{''}, ...
                                  'Visible','off');
            set(hGroupInfoTable2m,'String',{''}, ...
                                  'Visible','off');
        else
            Group = choicesGroupList{indexGroupList};
            GroupRef = dataSummary.(Group);
            set(hGroupInfoTable1,'Visible','on');
            if GroupRef.GroupInfo{'NumSubjects','Female'} > 0
                set(hGroupInfoTable2f,'String',[{''},{'Female'},{''}, ...
                                                {num2str(GroupRef.GroupInfo{'NumSubjects','Female'})},{''}, ...
                                                {[num2str(floor(GroupRef.GroupInfo{'AvgHeight','Female'}/(2.54*12)),'%i'),'''', ...
                                                  num2str(round(rem(GroupRef.GroupInfo{'AvgHeight','Female'}/2.54,12)),'%i'),'"']},{''}, ...
                                                {[num2str(round(GroupRef.GroupInfo{'AvgWeight','Female'}*2.20462),'%i'),' lbs']}], ...
                                      'Visible','on');
            else
                set(hGroupInfoTable2f,'String',[{''},{'Female'},{''}, ...
                                                {num2str(GroupRef.GroupInfo{'NumSubjects','Female'})},{''}], ...
                                      'Visible','on');
            end
            if GroupRef.GroupInfo{'NumSubjects','Male'} > 0
                set(hGroupInfoTable2m,'String',[{''},{'Male'},{''}, ...
                                                {num2str(GroupRef.GroupInfo{'NumSubjects','Male'})},{''}, ...
                                                {[num2str(floor(GroupRef.GroupInfo{'AvgHeight','Male'}/(2.54*12)),'%i'),'''', ...
                                                  num2str(round(rem(GroupRef.GroupInfo{'AvgHeight','Male'}/2.54,12)),'%i'),'"']},{''}, ...
                                                {[num2str(round(GroupRef.GroupInfo{'AvgWeight','Male'}*2.20462),'%i'),' lbs']}], ...
                                      'Visible','on');
            else
                set(hGroupInfoTable2m,'String',[{''},{'Male'},{''}, ...
                                                {num2str(GroupRef.GroupInfo{'NumSubjects','Male'})},{''}], ...
                                      'Visible','on');
            end
            choicesGroupMethodList = methods(GroupRef);
            tempLogical = strncmp('plot',choicesGroupMethodList,4);
            choicesGroupMethodList(~tempLogical) = [];
            clear tempLogical
            choicesGroupMethodList = [{''}; choicesGroupMethodList];
            set(hGroupMethodList,'String',choicesGroupMethodList);
            choicesGroupCycleList = [{''}; get(GroupRef.Cycles,'ObsNames')];
            set(hGroupCycleList,'String',choicesGroupCycleList);
            choicesSubjectList = properties(GroupRef);
            tempLogical = strcmp('GroupInfo',choicesSubjectList);
            choicesSubjectList(tempLogical) = [];
            tempLogical = strcmp('Cycles',choicesSubjectList);
            choicesSubjectList(tempLogical) = [];
            tempLogical = strcmp('Summary',choicesSubjectList);
            choicesSubjectList(tempLogical) = [];
            clear tempLogical
            choicesSubjectList = [{''}; choicesSubjectList];
            set(hSubjectList,'String',choicesSubjectList);            
        end
        set(hSummaryMethodList,'Value',1);
        set(hSummaryCycleList,'Value',1);
        set(hSummarySpecifierList,'Value',1);
        set(hGroupMethodList,'Value',1);
        set(hGroupCycleList,'Value',1);
        set(hGroupSpecifierList,'Value',1);
        set(hSubjectList,'Value',1);
        set(hSubjectInfoTable1,'Visible','off');
        set(hSubjectInfoTable2,'String',{''}, ...
                               'Visible','off');
        set(hSubjectMethodList,'Value',1);
        set(hSubjectCycleList,'Value',1);
        set(hSubjectRadioButtons,'SelectedObject',[]);
        set(hSubjectSpecifierList,'Value',1);
        set(hSimulationList,'Value',1);
        set(hSimulationInfoTable1,'Visible','off');
        set(hSimulationInfoTable2,'String',{''}, ...
                             'Visible','off');
        set(hSimulationMethodList,'Value',1);
        set(hSimulationCycleList,'Value',1);
        set(hSimulationSpecifierList,'Value',1);
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function hGroupMethodList_Callback(hGroupMethodList,eventdata)
        deleteLegend;
        set(hInfoPanels_All,'Visible','on');
        if get(hGroupList,'Value') == 1
            set(hGroupMethodList,'Value',1);
            msgbox('Please select a Group before selecting a Method.',...
                   'Group Selection Missing','warn');
        else
            indexGroupList = get(hGroupList,'Value');
            choicesGroupList = get(hGroupList,'String');
            Group = choicesGroupList{indexGroupList};
            GroupRef = dataSummary.(Group);
            indexGroupMethodList = get(hGroupMethodList,'Value');
            choicesGroupMethodList = get(hGroupMethodList,'String');
            if indexGroupMethodList == 1
                set(hGroupCycleList,'Value',1);
                set(hGroupSpecifierList,'Value',1);
            else
                GroupMethod = choicesGroupMethodList{indexGroupMethodList};
                switch GroupMethod
                    case {'plotGroupEMG','plotGroupSideToSideEMG'}
                        choicesGroupSpecifierList = [{''}; {'All'}; {'Glutes'}; {'Quads'}; ...
                                                     {'Hamstrings'}; {'Gastrocs'}; ...
                                                     {'IGluteMed'}; {'CGluteMed'}; ...
                                                     {'IVastusMedialis'}; {'CVastusMedialis'}; ...
                                                     {'IVastusLateralis'}; {'CVastusLateralis'}; ...
                                                     {'IRectus'}; {'CRectus'}; ...
                                                     {'IMedialHam'}; {'CMedialHam'}; ...
                                                     {'ILateralHam'}; {'CLateralHam'}; ...
                                                     {'IMedialGast'}; {'CMedialGast'}; ...
                                                     {'ILateralGast'}; {'CLateralGast'}];
                    case {'plotGroupGRF','plotGroupSideToSideGRF'}
                        choicesGroupSpecifierList = [{''}; {'All'}; ...
                                                     {'Forces'}; {'Moments'}; {'Coordinates'}; ...
                                                     {'FX'}; {'FY'}; {'FZ'}; ...
                                                     {'CX'}; {'CY'}; {'MZ'}];
                    case {'plotGroupKinematics','plotGroupSideToSideKinematics'}
                        choicesGroupSpecifierList = [{''}; {'Knee'}; {'Hip'}; {'Ankle'}];
                end
                switch GroupMethod
                    case {'plotGroupSideToSideEMG','plotGroupSideToSideGRF','plotGroupSideToSideKinematics'}
                        choicesGroupCycleList = get(GroupRef.Cycles,'ObsNames');
                        for i = 1:length(choicesGroupCycleList)
                            choicesGroupCycleList{i} = choicesGroupCycleList{i}(3:end);
                        end
                        choicesGroupCycleList = [{''}; unique(choicesGroupCycleList)];
                        set(hGroupCycleList,'String',choicesGroupCycleList);
                        set(hGroupCycleList,'Value',1);
                    otherwise
                        choicesGroupCycleList = [{''}; get(GroupRef.Cycles,'ObsNames')];
                        set(hGroupCycleList,'String',choicesGroupCycleList);
                        set(hGroupCycleList,'Value',1);
                end
                set(hGroupCycleList,'Value',2);
                set(hGroupSpecifierList,'String',choicesGroupSpecifierList);
                set(hGroupSpecifierList,'Value',2);
            end
            set(hSummaryMethodList,'Value',1);
            set(hSummaryCycleList,'Value',1);
            set(hSummarySpecifierList,'Value',1);
            set(hSubjectList,'Value',1);
            set(hSubjectInfoTable1,'Visible','off');
            set(hSubjectInfoTable2,'String',{''}, ...
                                   'Visible','off');
            set(hSubjectMethodList,'Value',1);
            set(hSubjectCycleList,'Value',1);
            set(hSubjectRadioButtons,'SelectedObject',[]);
            set(hSubjectSpecifierList,'Value',1);
            set(hSimulationList,'Value',1);
            set(hSimulationInfoTable1,'Visible','off');
            set(hSimulationInfoTable2,'String',{''}, ...
                                 'Visible','off');
            set(hSimulationMethodList,'Value',1);
            set(hSimulationCycleList,'Value',1);
            set(hSimulationSpecifierList,'Value',1);
        end
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    function hGroupUpdateButton_Callback(hObject,eventdata)
        set(hFigure,'RendererMode','auto');
        deleteLegend;
        set(hInfoPanels_All,'Visible','on');
        set(hPanels_All,'Visible','off');
        set(hAxes_All,'NextPlot','replace');
        indexGroupList = get(hGroupList,'Value');
        choicesGroupList = get(hGroupList,'String');
        Group = choicesGroupList{indexGroupList};
        indexGroupMethodList = get(hGroupMethodList,'Value');
        choicesGroupMethodList = get(hGroupMethodList,'String');
        GroupMethod = choicesGroupMethodList{indexGroupMethodList};
        indexGroupCycleList = get(hGroupCycleList,'Value');
        choicesGroupCycleList = get(hGroupCycleList,'String');
        GroupCycle = choicesGroupCycleList{indexGroupCycleList};
        indexGroupSpecifierList = get(hGroupSpecifierList,'Value');
        choicesGroupSpecifierList = get(hGroupSpecifierList,'String');
        GroupSpecifier = choicesGroupSpecifierList{indexGroupSpecifierList};
        if strcmp(Group,'') || strcmp(GroupMethod,'') || strcmp(GroupCycle,'') || strcmp(GroupSpecifier,'')
            msgbox('Please select a Group, Group Method, Cycle, and Specifier','Update Selections','warn');
        else
            GroupRef = dataSummary.(Group);
            switch GroupMethod
                case 'plotGroupEMG'
                    set(hPanelHeader,'String',[Group,'_',GroupCycle,':  Normalized EMG - ',GroupSpecifier]);
                    switch GroupSpecifier
                        case 'All'
                            legendStruct = GroupRef.plotGroupEMG(GroupCycle,GroupSpecifier,hFigure,hAxes_4x4);
                            set(hPanel_4x4,'Visible','on');    
                        case 'Glutes'
                            legendStruct = GroupRef.plotGroupEMG(GroupCycle,GroupSpecifier,hFigure,hAxes_1x2);
                            set(hPanel_1x2,'Visible','on');
                        case 'Quads'
                            legendStruct = GroupRef.plotGroupEMG(GroupCycle,GroupSpecifier,hFigure,hAxes_3x2);
                            set(hPanel_3x2,'Visible','on');
                        case 'Hamstrings'
                            legendStruct = GroupRef.plotGroupEMG(GroupCycle,GroupSpecifier,hFigure,hAxes_2x2);
                            set(hPanel_2x2,'Visible','on');                            
                        case 'Gastrocs'
                            legendStruct = GroupRef.plotGroupEMG(GroupCycle,GroupSpecifier,hFigure,hAxes_2x2);
                            set(hPanel_2x2,'Visible','on');
                        otherwise
                            legendStruct = GroupRef.plotGroupEMG(GroupCycle,GroupSpecifier,hFigure,hAxes_1x1);
                            set(hPanel_1x1,'Visible','on');
                    end              
                case 'plotGroupGRF'
                    set(hPanelHeader,'String',[Group,'_',GroupCycle,':  Equivalent GRF - ',GroupSpecifier]);
                    switch GroupSpecifier
                        case 'All'
                            legendStruct = GroupRef.plotGroupGRF(GroupCycle,GroupSpecifier,hFigure,hAxes_3x2);
                            set(hPanel_3x2,'Visible','on');
                        case {'Forces','Moments','Coordinates'}
                            legendStruct = GroupRef.plotGroupGRF(GroupCycle,GroupSpecifier,hFigure,hAxes_3x1);
                            set(hPanel_3x1,'Visible','on');
                        otherwise
                            legendStruct = GroupRef.plotGroupGRF(GroupCycle,GroupSpecifier,hFigure,hAxes_1x1);
                            set(hPanel_1x1,'Visible','on');                    
                    end                                 
                case 'plotGroupKinematics'
                    set(hPanelHeader,'String',[Group,'_',GroupCycle,':  Joint Kinematics - ',GroupSpecifier]);
                    legendStruct = GroupRef.plotGroupKinematics(GroupCycle,GroupSpecifier,hFigure,hAxes_3x2);
                    set(hPanel_3x2,'Visible','on');
                case 'plotGroupSideToSideEMG'
                    set(hPanelHeader,'String',[Group,'_',GroupCycle,':  Normalized EMG - ',GroupSpecifier]);
                    switch GroupSpecifier
                        case 'All'
                            legendStruct = GroupRef.plotGroupSideToSideEMG(GroupCycle,GroupSpecifier,hFigure,hAxes_4x4);
                            set(hPanel_4x4,'Visible','on');    
                        case 'Glutes'
                            legendStruct = GroupRef.plotGroupSideToSideEMG(GroupCycle,GroupSpecifier,hFigure,hAxes_1x2);
                            set(hPanel_1x2,'Visible','on');
                        case 'Quads'
                            legendStruct = GroupRef.plotGroupSideToSideEMG(GroupCycle,GroupSpecifier,hFigure,hAxes_3x2);
                            set(hPanel_3x2,'Visible','on');
                        case 'Hamstrings'
                            legendStruct = GroupRef.plotGroupSideToSideEMG(GroupCycle,GroupSpecifier,hFigure,hAxes_2x2);
                            set(hPanel_2x2,'Visible','on');                            
                        case 'Gastrocs'
                            legendStruct = GroupRef.plotGroupSideToSideEMG(GroupCycle,GroupSpecifier,hFigure,hAxes_2x2);
                            set(hPanel_2x2,'Visible','on');
                        otherwise
                            legendStruct = GroupRef.plotGroupSideToSideEMG(GroupCycle,GroupSpecifier,hFigure,hAxes_1x1);
                            set(hPanel_1x1,'Visible','on');
                    end              
                case 'plotGroupSideToSideGRF'
                    set(hPanelHeader,'String',[Group,'_',GroupCycle,':  Equivalent GRF - ',GroupSpecifier]);
                    switch GroupSpecifier
                        case 'All'
                            legendStruct = GroupRef.plotGroupSideToSideGRF(GroupCycle,GroupSpecifier,hFigure,hAxes_3x2);
                            set(hPanel_3x2,'Visible','on');
                        case {'Forces','Moments','Coordinates'}
                            legendStruct = GroupRef.plotGroupSideToSideGRF(GroupCycle,GroupSpecifier,hFigure,hAxes_3x1);
                            set(hPanel_3x1,'Visible','on');
                        otherwise
                            legendStruct = GroupRef.plotGroupSideToSideGRF(GroupCycle,GroupSpecifier,hFigure,hAxes_1x1);
                            set(hPanel_1x1,'Visible','on');                    
                    end                                 
                case 'plotGroupSideToSideKinematics'
                    set(hPanelHeader,'String',[Group,'_',GroupCycle,':  Joint Kinematics - ',GroupSpecifier]);
                    legendStruct = GroupRef.plotGroupSideToSideKinematics(GroupCycle,GroupSpecifier,hFigure,hAxes_3x2);
                    set(hPanel_3x2,'Visible','on');                    
            end
        end
        createLegend(legendStruct);
        set(hSubjectInfoPanel,'Visible','off');
        set(hGroupInfoPanel,'Visible','off');
        set(hPanel_Toolbar,'Visible','on');
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function hSubjectList_Callback(hSubjectList,eventdata)
        deleteLegend;
        set(hInfoPanels_All,'Visible','on');
        if get(hGroupList,'Value') == 1
            set(hSubjectList,'Value',1);
            msgbox('Please select a Group before selecting a Subject.',...
                   'Group Selection Missing','warn');
        else
            indexSubjectList = get(hSubjectList,'Value');
            choicesSubjectList = get(hSubjectList,'String');
            if indexSubjectList == 1
                set(hSubjectInfoTable1,'Visible','off');
                set(hSubjectInfoTable2,'String',{''}, ...
                                       'Visible','off');
            else
                Subject = choicesSubjectList{indexSubjectList};
                indexGroupList = get(hGroupList,'Value');
                choicesGroupList = get(hGroupList,'String');
                Group = choicesGroupList{indexGroupList};
                SubjectRef = dataSummary.(Group).(Subject);
                set(hSubjectInfoTable1,'Visible','on');
                set(hSubjectInfoTable2,'String',[{''},{SubjectRef.PersInfo.ID},{''}, ...
                                                 {SubjectRef.PersInfo.Group},{''}, ...
                                                 {SubjectRef.PersInfo.Side},{''}, ...
                                                 {SubjectRef.PersInfo.Gender},{''}, ...
                                                 {[num2str(floor(SubjectRef.PersInfo.Height/(2.54*12)),'%i'),'''', ...
                                                   num2str(round(rem(SubjectRef.PersInfo.Height/2.54,12)),'%i'),'"']},{''}, ...
                                                 {[num2str(round(SubjectRef.PersInfo.Weight*2.20462),'%i'),' lbs']}], ...
                                       'Visible','on');
                choicesSubjectMethodList = methods(SubjectRef);
                tempLogical = strncmp('plot',choicesSubjectMethodList,4);
                choicesSubjectMethodList(~tempLogical) = [];
                clear tempLogical
                choicesSubjectMethodList = [{''}; choicesSubjectMethodList];
                set(hSubjectMethodList,'String',choicesSubjectMethodList);
                choicesSubjectCycleList = [{''}; get(SubjectRef.Cycles,'ObsNames')];
                set(hSubjectCycleList,'String',choicesSubjectCycleList);
                choicesSimulationList = properties(SubjectRef);
                tempLogical = strcmp('SysInfo',choicesSimulationList);
                choicesSimulationList(tempLogical) = [];
                tempLogical = strcmp('PersInfo',choicesSimulationList);
                choicesSimulationList(tempLogical) = [];
                tempLogical = strcmp('Cycles',choicesSimulationList);
                choicesSimulationList(tempLogical) = [];
                tempLogical = strcmp('Summary',choicesSimulationList);
                choicesSimulationList(tempLogical) = [];
                clear tempLogical
                choicesSimulationList = [{''}; choicesSimulationList];            
                set(hSimulationList,'String',choicesSimulationList);            
            end
            set(hSummaryMethodList,'Value',1);
            set(hSummaryCycleList,'Value',1);
            set(hSummarySpecifierList,'Value',1);
            set(hGroupInfoTable1,'Visible','off');
            set(hGroupInfoTable2f,'String',{''}, ...
                                  'Visible','off');
            set(hGroupInfoTable2m,'String',{''}, ...
                                  'Visible','off');
            set(hGroupMethodList,'Value',1);
            set(hGroupCycleList,'Value',1);
            set(hGroupSpecifierList,'Value',1);
            set(hSubjectMethodList,'Value',1);
            set(hSubjectCycleList,'Value',1);
            set(hSubjectSpecifierList,'Value',1);
            set(hSimulationList,'Value',1);
            set(hSimulationInfoTable1,'Visible','off');
            set(hSimulationInfoTable2,'String',{''}, ...
                                 'Visible','off');
            set(hSimulationMethodList,'Value',1);
            set(hSimulationCycleList,'Value',1);
            set(hSimulationSpecifierList,'Value',1);
        end
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function hSubjectMethodList_Callback(hSubjectMethodList,eventdata)
        deleteLegend;
        set(hInfoPanels_All,'Visible','on');
        if get(hGroupList,'Value') == 1 || get(hSubjectList,'Value') == 1
            set(hSubjectMethodList,'Value',1);
            msgbox('Please select both a Group and a Subject before selecting a Method.',...
                   'Group and/or Subject Selection Missing','warn');
        else
            indexGroupList = get(hGroupList,'Value');
            choicesGroupList = get(hGroupList,'String');
            Group = choicesGroupList{indexGroupList};
            indexSubjectList = get(hSubjectList,'Value');
            choicesSubjectList = get(hSubjectList,'String');
            Subject = choicesSubjectList{indexSubjectList};
            SubjectRef = dataSummary.(Group).(Subject);
            indexSubjectMethodList = get(hSubjectMethodList,'Value');
            choicesSubjectMethodList = get(hSubjectMethodList,'String');
            if indexSubjectMethodList == 1
                set(hSubjectCycleList,'Value',1);
                set(hSubjectSpecifierList,'Value',1);
            else
                SubjectMethod = choicesSubjectMethodList{indexSubjectMethodList};
                switch SubjectMethod
                    case {'plotSubjectEMG','plotSubjectSideToSideEMG'}
                        choicesSubjectSpecifierList = [{''}; {'All'}; {'Glutes'}; {'Quads'}; ...
                                                       {'Hamstrings'}; {'Gastrocs'}; ...
                                                       {'IGluteMed'}; {'CGluteMed'}; ...
                                                       {'IVastusMedialis'}; {'CVastusMedialis'}; ...
                                                       {'IVastusLateralis'}; {'CVastusLateralis'}; ...
                                                       {'IRectus'}; {'CRectus'}; ...
                                                       {'IMedialHam'}; {'CMedialHam'}; ...
                                                       {'ILateralHam'}; {'CLateralHam'}; ...
                                                       {'IMedialGast'}; {'CMedialGast'}; ...
                                                       {'ILateralGast'}; {'CLateralGast'}];
                    case {'plotSubjectGRF','plotSubjectSideToSideGRF'}
                        choicesSubjectSpecifierList = [{''}; {'All'}; ...
                                                       {'Forces'}; {'Moments'}; {'Coordinates'}; ...
                                                       {'FX'}; {'FY'}; {'FZ'}; ...
                                                       {'CX'}; {'CY'}; {'MZ'}];
                    case {'plotSubjectKinematics','plotSubjectSideToSideKinematics'}
                        choicesSubjectSpecifierList = [{''}; {'Knee'}; {'Hip'}; {'Ankle'}];
                end
                switch SubjectMethod
                    case {'plotSubjectSideToSideEMG','plotSubjectSideToSideGRF','plotSubjectSideToSideKinematics'}
                        choicesSubjectCycleList = get(SubjectRef.Cycles,'ObsNames');
                        for i = 1:length(choicesSubjectCycleList)
                            choicesSubjectCycleList{i} = choicesSubjectCycleList{i}(3:end);
                        end
                        choicesSubjectCycleList = [{''}; unique(choicesSubjectCycleList)];
                        set(hSubjectCycleList,'String',choicesSubjectCycleList);
                        set(hSubjectCycleList,'Value',1);
                    otherwise
                        choicesSubjectCycleList = [{''}; get(SubjectRef.Cycles,'ObsNames')];
                        set(hSubjectCycleList,'String',choicesSubjectCycleList);
                        set(hSubjectCycleList,'Value',1);
                end
                set(hSubjectCycleList,'Value',2);
                set(hSubjectSpecifierList,'String',choicesSubjectSpecifierList);
                set(hSubjectSpecifierList,'Value',2);
            end
            set(hSummaryMethodList,'Value',1);
            set(hSummaryCycleList,'Value',1);
            set(hSummarySpecifierList,'Value',1);
            set(hGroupInfoTable1,'Visible','off');
            set(hGroupInfoTable2f,'String',{''}, ...
                                  'Visible','off');
            set(hGroupInfoTable2m,'String',{''}, ...
                                  'Visible','off');
            set(hGroupMethodList,'Value',1);
            set(hGroupCycleList,'Value',1);
            set(hGroupSpecifierList,'Value',1);
            set(hSimulationList,'Value',1);
            set(hSimulationInfoTable1,'Visible','off');
            set(hSimulationInfoTable2,'String',{''}, ...
                                 'Visible','off');
            set(hSimulationMethodList,'Value',1);
            set(hSimulationCycleList,'Value',1);
            set(hSimulationSpecifierList,'Value',1);
        end
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function hSubjectUpdateButton_Callback(hObject,eventdata)
        set(hFigure,'RendererMode','auto');
        deleteLegend;
        set(hInfoPanels_All,'Visible','on');
        set(hPanels_All,'Visible','off');
        set(hAxes_All,'NextPlot','replace');
        indexGroupList = get(hGroupList,'Value');
        choicesGroupList = get(hGroupList,'String');
        Group = choicesGroupList{indexGroupList};
        indexSubjectList = get(hSubjectList,'Value');
        choicesSubjectList = get(hSubjectList,'String');
        Subject = choicesSubjectList{indexSubjectList};
        SubjectID = dataSummary.(Group).(Subject).PersInfo.ID;
        indexSubjectMethodList = get(hSubjectMethodList,'Value');        
        choicesSubjectMethodList = get(hSubjectMethodList,'String');
        SubjectMethod = choicesSubjectMethodList{indexSubjectMethodList};
        indexSubjectCycleList = get(hSubjectCycleList,'Value');
        choicesSubjectCycleList = get(hSubjectCycleList,'String');
        SubjectCycle = choicesSubjectCycleList{indexSubjectCycleList};       
        indexSubjectSpecifierList = get(hSubjectSpecifierList,'Value');
        choicesSubjectSpecifierList = get(hSubjectSpecifierList,'String');
        SubjectSpecifier = choicesSubjectSpecifierList{indexSubjectSpecifierList};
        if strcmp(Subject,'') || strcmp(SubjectMethod,'') || strcmp(SubjectCycle,'') || strcmp(SubjectSpecifier,'')
            msgbox('Please select a Subject, Subject Method, Cycle, and Specifier','Update Selections','warn');
        else
            SubjectRef = dataSummary.(Group).(Subject);
            switch SubjectMethod
                case 'plotSubjectEMG'
                    set(hPanelHeader,'String',[SubjectID,'_',SubjectCycle,':  Normalized EMG - ',SubjectSpecifier]);
                    switch SubjectSpecifier
                        case 'All'
                            legendStruct = SubjectRef.plotSubjectEMG(SubjectCycle,SubjectSpecifier,hFigure,hAxes_4x4);
                            set(hPanel_4x4,'Visible','on');    
                        case 'Glutes'
                            legendStruct = SubjectRef.plotSubjectEMG(SubjectCycle,SubjectSpecifier,hFigure,hAxes_1x2);
                            set(hPanel_1x2,'Visible','on');
                        case 'Quads'
                            legendStruct = SubjectRef.plotSubjectEMG(SubjectCycle,SubjectSpecifier,hFigure,hAxes_3x2);
                            set(hPanel_3x2,'Visible','on');
                        case {'Hamstrings','Gastrocs'}
                            legendStruct = SubjectRef.plotSubjectEMG(SubjectCycle,SubjectSpecifier,hFigure,hAxes_2x2);
                            set(hPanel_2x2,'Visible','on');
                        otherwise
                            legendStruct = SubjectRef.plotSubjectEMG(SubjectCycle,SubjectSpecifier,hFigure,hAxes_1x1);
                            set(hPanel_1x1,'Visible','on');
                    end              
                case 'plotSubjectGRF'
                    set(hPanelHeader,'String',[SubjectID,'_',SubjectCycle,':  Equivalent GRF - ',SubjectSpecifier]);
                    switch SubjectSpecifier
                        case 'All'
                            legendStruct = SubjectRef.plotSubjectGRF(SubjectCycle,SubjectSpecifier,hFigure,hAxes_3x2);
                            set(hPanel_3x2,'Visible','on');
                        case {'Forces','Moments','Coordinates'}
                            legendStruct = SubjectRef.plotSubjectGRF(SubjectCycle,SubjectSpecifier,hFigure,hAxes_3x1);
                            set(hPanel_3x1,'Visible','on');
                        otherwise
                            legendStruct = SubjectRef.plotSubjectGRF(SubjectCycle,SubjectSpecifier,hFigure,hAxes_1x1);
                            set(hPanel_1x1,'Visible','on');                    
                    end                                 
                case 'plotSubjectKinematics'
                    set(hPanelHeader,'String',[SubjectID,'_',SubjectCycle,':  Joint Kinematics - ',SubjectSpecifier]);
                    legendStruct = SubjectRef.plotSubjectKinematics(SubjectCycle,SubjectSpecifier,hFigure,hAxes_3x2);
                    set(hPanel_3x2,'Visible','on');
                case 'plotSubjectSideToSideEMG'
                    set(hPanelHeader,'String',[SubjectID,'_',SubjectCycle,':  Normalized EMG - ',SubjectSpecifier]);                        
                    switch SubjectSpecifier
                        case 'All'
                            legendStruct = SubjectRef.plotSubjectSideToSideEMG(SubjectCycle,SubjectSpecifier,hFigure,hAxes_4x4);
                            set(hPanel_4x4,'Visible','on');
                        case 'Glutes'
                            legendStruct = SubjectRef.plotSubjectSideToSideEMG(SubjectCycle,SubjectSpecifier,hFigure,hAxes_1x2);
                            set(hPanel_1x2,'Visible','on');
                        case 'Quads'
                            legendStruct = SubjectRef.plotSubjectSideToSideEMG(SubjectCycle,SubjectSpecifier,hFigure,hAxes_3x2);
                            set(hPanel_3x2,'Visible','on');
                        case {'Hamstrings','Gastrocs'}
                            legendStruct = SubjectRef.plotSubjectSideToSideEMG(SubjectCycle,SubjectSpecifier,hFigure,hAxes_2x2);
                            set(hPanel_2x2,'Visible','on');
                        otherwise
                            legendStruct = SubjectRef.plotSubjectSideToSideEMG(SubjectCycle,SubjectSpecifier,hFigure,hAxes_1x1);
                            set(hPanel_1x1,'Visible','on');
                    end              
                case 'plotSubjectSideToSideGRF'
                    set(hPanelHeader,'String',[SubjectID,'_',SubjectCycle,':  Equivalent GRF - ',SubjectSpecifier]);
                    switch SubjectSpecifier
                        case 'All'
                            legendStruct = SubjectRef.plotSubjectSideToSideGRF(SubjectCycle,SubjectSpecifier,hFigure,hAxes_3x2);
                            set(hPanel_3x2,'Visible','on');
                        case {'Forces','Moments','Coordinates'}
                            legendStruct = SubjectRef.plotSubjectSideToSideGRF(SubjectCycle,SubjectSpecifier,hFigure,hAxes_3x1);
                            set(hPanel_3x1,'Visible','on');
                        otherwise
                            legendStruct = SubjectRef.plotSubjectSideToSideGRF(SubjectCycle,SubjectSpecifier,hFigure,hAxes_1x1);
                            set(hPanel_1x1,'Visible','on');                    
                    end                                 
                case 'plotSubjectSideToSideKinematics'
                    set(hPanelHeader,'String',[SubjectID,'_',SubjectCycle,':  Joint Kinematics - ',SubjectSpecifier]);
                    legendStruct = SubjectRef.plotSubjectSideToSideKinematics(SubjectCycle,SubjectSpecifier,hFigure,hAxes_3x2);
                    set(hPanel_3x2,'Visible','on');
            end
        end
        createLegend(legendStruct);
        set(hSubjectInfoPanel,'Visible','off');
        set(hGroupInfoPanel,'Visible','off');
        set(hPanel_Toolbar,'Visible','on');        
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function hSimulationList_Callback(hSimulationList,eventdata)
        deleteLegend;
        set(hInfoPanels_All,'Visible','on');
        if get(hGroupList,'Value') == 1 || get(hSubjectList,'Value') == 1
            set(hSimulationList,'Value',1);
            msgbox('Please select both a Group and a Subject before selecting a Simulation.',...
                   'Group and/or Subject Selection Missing','warn');
        else
            indexSimulationList = get(hSimulationList,'Value');
            choicesSimulationList = get(hSimulationList,'String');
            if indexSimulationList == 1
                set(hSimulationInfoTable1,'Visible','off');
                set(hSimulationInfoTable2,'String',{''}, ...
                                     'Visible','off');
            else
                Simulation = choicesSimulationList{indexSimulationList};            
                indexGroupList = get(hGroupList,'Value');
                choicesGroupList = get(hGroupList,'String');
                Group = choicesGroupList{indexGroupList};
                indexSubjectList = get(hSubjectList,'Value');        
                choicesSubjectList = get(hSubjectList,'String');
                Subject = choicesSubjectList{indexSubjectList};
                SimulationRef = dataSummary.(Group).(Subject).(Simulation);        
                set(hSimulationInfoTable1,'Visible','on');                
                set(hSimulationInfoTable2,'String',[{''}, ...
                                               {SimulationRef.SimulationType}], ...
                                     'Visible','on');
                choicesSimulationMethodList = methods(SimulationRef);
                tempLogical = strncmp('plot',choicesSimulationMethodList,4);
                choicesSimulationMethodList(~tempLogical) = [];                
                clear tempLogical
                choicesSimulationMethodList = [{''}; choicesSimulationMethodList];
                set(hSimulationMethodList,'String',choicesSimulationMethodList);
                if isprop(SimulationRef,'Cycles')
                    if max(size(get(SimulationRef.Cycles,'ObsNames')))
                        choicesSimulationCycleList = [{''}; get(SimulationRef.Cycles,'ObsNames')];
                    else
                        choicesSimulationCycleList = [{''}; {''}];
                    end
                else
                    choicesSimulationCycleList = [{''}; {''}];
                end
                set(hSimulationCycleList,'String',choicesSimulationCycleList);
            end
            set(hSummaryMethodList,'Value',1);
            set(hSummaryCycleList,'Value',1);
            set(hSummarySpecifierList,'Value',1);
            set(hGroupInfoTable1,'Visible','off');
            set(hGroupInfoTable2f,'String',{''}, ...
                                  'Visible','off');
            set(hGroupInfoTable2m,'String',{''}, ...
                                  'Visible','off');
            set(hGroupMethodList,'Value',1);
            set(hGroupCycleList,'Value',1);
            set(hGroupSpecifierList,'Value',1);
            set(hSubjectMethodList,'Value',1);
            set(hSubjectCycleList,'Value',1);
            set(hSubjectRadioButtons,'SelectedObject',[]);
            set(hSubjectSpecifierList,'Value',1);
            set(hSimulationMethodList,'Value',1);
            set(hSimulationCycleList,'Value',1);
            set(hSimulationSpecifierList,'Value',1);
        end
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function hSimulationMethodList_Callback(hSimulationMethodList,eventdata)
        deleteLegend;
        set(hInfoPanels_All,'Visible','on');
        if get(hGroupList,'Value') == 1 || get(hSubjectList,'Value') == 1 || get(hSimulationList,'Value') == 1
            set(hSimulationMethodList,'Value',1);
            msgbox('Please select a Group, Subject, and Simulation before selecting a Method.',...
                   'Group/Subject/Simulation Selection Missing','warn');
        else
            indexSimulationMethodList = get(hSimulationMethodList,'Value');
            choicesSimulationMethodList = get(hSimulationMethodList,'String');
            if indexSimulationMethodList == 1
                set(hSimulationCycleList,'Value',1);
                set(hSimulationSpecifierList,'Value',1);
            else
                SimulationMethod = choicesSimulationMethodList{indexSimulationMethodList};
                indexGroupList = get(hGroupList,'Value');
                choicesGroupList = get(hGroupList,'String');
                Group = choicesGroupList{indexGroupList};
                indexSubjectList = get(hSubjectList,'Value');
                choicesSubjectList = get(hSubjectList,'String');
                Subject = choicesSubjectList{indexSubjectList};
                indexSimulationList = get(hSimulationList,'Value');
                choicesSimulationList = get(hSimulationList,'String');
                Simulation = choicesSimulationList{indexSimulationList};
                SimulationRef = dataSummary.(Group).(Subject).(Simulation);                
                switch SimulationMethod
                    case {'plotSimulationEMG_RawFilt','plotSimulationEMG','plotMVC'}
                        choicesSimulationSpecifierList = [{''}; {'All'}; {'Glutes'}; {'Quads'}; ...
                                                     {'Hamstrings'}; {'Gastrocs'}; ...
                                                     SimulationRef.EMG.Raw.Properties.VarNames'];
                    case 'plotCycleEMG'
                        choicesSimulationSpecifierList = [{''}; {'All'}; {'Glutes'}; {'Quads'}; ...
                                                     {'Hamstrings'}; {'Gastrocs'}; ...
                                                     {'IGluteMed'}; {'CGluteMed'}; ...
                                                     {'IVastusMedialis'}; {'CVastusMedialis'}; ...
                                                     {'IVastusLateralis'}; {'CVastusLateralis'}; ...
                                                     {'IRectus'}; {'CRectus'}; ...
                                                     {'IMedialHam'}; {'CMedialHam'}; ...
                                                     {'ILateralHam'}; {'CLateralHam'}; ...
                                                     {'IMedialGast'}; {'CMedialGast'}; ...
                                                     {'ILateralGast'}; {'CLateralGast'}];
                    case 'plotSimulationGRF_RawFilt'
                        choicesSimulationSpecifierList = [{''}; {'All'}; {'Forces'}; {'Moments'}; ...
                                                     {'FX'}; {'FY'}; {'FZ'}; ...
                                                     {'MX'}; {'MY'}; {'MZ'}];
                    case {'plotSimulationGRF_Plate','plotSimulationGRF'}
                        choicesSimulationSpecifierList = [{''}; {'All'}; {'Forces'}; ...
                                                     {'Moments'}; {'Coordinates'}; ...
                                                     {'FX'}; {'FY'}; {'FZ'}; ...
                                                     {'MX'}; {'MY'}; {'MZ'}; ...
                                                     {'CX'}; {'CY'}; {'CZ'}];
                    case 'plotCycleGRF'
                        choicesSimulationSpecifierList = [{''}; {'All'}; {'Forces'}; ...
                                                     {'Moments'}; {'Coordinates'}; {'COP'}; ...
                                                     {'FX'}; {'FY'}; {'FZ'}; ...
                                                     {'MX'}; {'MY'}; {'MZ'}; ...
                                                     {'CX'}; {'CY'}; {'CZ'}];
                    case {'plotSimulationKinematics','plotCycleKinematics'}
                        choicesSimulationSpecifierList = [{''}; {'Knee'}; {'Hip'}; {'Ankle'}];
                    case 'plotSimulationTRC'
                        choicesSimulationSpecifierList = [{''}; SimulationRef.TRC.X.Properties.VarNames'];

                end
                if max(size(strfind(SimulationMethod,'Simulation'))) || max(size(strfind(SimulationMethod,'MVC')))
                    set(hSimulationCycleList,'Value',1);
                else
                    if get(hSimulationCycleList,'Value') == 1
                        set(hSimulationCycleList,'Value',2);
                    end
                end
                set(hSimulationSpecifierList,'String',choicesSimulationSpecifierList);
                set(hSimulationSpecifierList,'Value',2);
            end
            set(hSummaryMethodList,'Value',1);
            set(hSummaryCycleList,'Value',1);
            set(hSummarySpecifierList,'Value',1);            
            set(hGroupInfoTable1,'Visible','off');
            set(hGroupInfoTable2f,'String',{''}, ...
                                  'Visible','off');
            set(hGroupInfoTable2m,'String',{''}, ...
                                  'Visible','off');
            set(hGroupMethodList,'Value',1);
            set(hGroupCycleList,'Value',1);
            set(hGroupSpecifierList,'Value',1);
            set(hSubjectMethodList,'Value',1);
            set(hSubjectCycleList,'Value',1);
            set(hSubjectRadioButtons,'SelectedObject',[]);
            set(hSubjectSpecifierList,'Value',1);
        end
    end    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function hSimulationUpdateButton_Callback(hObject,eventdata)
        set(hFigure,'RendererMode','auto');
        deleteLegend;
        set(hInfoPanels_All,'Visible','on');
        set(hPanels_All,'Visible','off');
        set(hAxes_All,'NextPlot','replace');
        indexGroupList = get(hGroupList,'Value');
        choicesGroupList = get(hGroupList,'String');
        Group = choicesGroupList{indexGroupList};
        indexSubjectList = get(hSubjectList,'Value');
        choicesSubjectList = get(hSubjectList,'String');
        Subject = choicesSubjectList{indexSubjectList};
        SubjectID = dataSummary.(Group).(Subject).PersInfo.ID;
        indexSimulationList = get(hSimulationList,'Value');
        choicesSimulationList = get(hSimulationList,'String');
        Simulation = choicesSimulationList{indexSimulationList};
        indexSimulationMethodList = get(hSimulationMethodList,'Value');
        choicesSimulationMethodList = get(hSimulationMethodList,'String');
        SimulationMethod = choicesSimulationMethodList{indexSimulationMethodList};
        indexSimulationCycleList = get(hSimulationCycleList,'Value');
        choicesSimulationCycleList = get(hSimulationCycleList,'String');
        SimulationCycle = choicesSimulationCycleList{indexSimulationCycleList};
        indexSimulationSpecifierList = get(hSimulationSpecifierList,'Value');
        choicesSimulationSpecifierList = get(hSimulationSpecifierList,'String');
        SimulationSpecifier = choicesSimulationSpecifierList{indexSimulationSpecifierList};
        if strcmp(Simulation,'') || strcmp(SimulationMethod,'') || strcmp(SimulationSpecifier,'')
            msgbox('Please select a Simulation, Simulation Method, and Specifier','Update Selections','warn');
        elseif strncmp(SimulationMethod,'plotCycle',9) && strcmp(SimulationCycle,'')
            msgbox('Please select a Cycle in order to use that Method','Cycle Selection Missing','warn');
        else
            SimulationRef = dataSummary.(Group).(Subject).(Simulation);
            switch SimulationMethod
                case 'plotMVC'
                    set(hPanelHeader,'String',[SubjectID,'_',Simulation,':  Raw vs. Filtered EMG (with Max) - ',SimulationSpecifier]);
                    switch SimulationSpecifier
                        case 'All'
                            SimulationRef.plotMVC(SimulationSpecifier,hFigure,hAxes_4x4);
                            set(hPanel_4x4,'Visible','on');                            
                        case 'Glutes'
                            SimulationRef.plotMVC(SimulationSpecifier,hFigure,hAxes_1x2);
                            set(hPanel_1x2,'Visible','on');
                        case 'Quads'
                            SimulationRef.plotMVC(SimulationSpecifier,hFigure,hAxes_3x2);
                            set(hPanel_3x2,'Visible','on');
                        case {'Hamstrings','Gastrocs'}
                            SimulationRef.plotMVC(SimulationSpecifier,hFigure,hAxes_2x2);
                            set(hPanel_2x2,'Visible','on');
                        otherwise
                            SimulationRef.plotMVC(SimulationSpecifier,hFigure,hAxes_1x1);
                            set(hPanel_1x1,'Visible','on');
                    end
                case 'plotSimulationEMG_RawFilt'
                    set(hPanelHeader,'String',[SubjectID,'_',Simulation,':  Raw vs. Filtered EMG - ',SimulationSpecifier]);
                    switch SimulationSpecifier
                        case 'All'
                            SimulationRef.plotSimulationEMG_RawFilt(SimulationSpecifier,hFigure,hAxes_4x4);
                            set(hPanel_4x4,'Visible','on');                            
                        case 'Glutes'
                            SimulationRef.plotSimulationEMG_RawFilt(SimulationSpecifier,hFigure,hAxes_1x2);
                            set(hPanel_1x2,'Visible','on');
                        case 'Quads'
                            SimulationRef.plotSimulationEMG_RawFilt(SimulationSpecifier,hFigure,hAxes_3x2);
                            set(hPanel_3x2,'Visible','on');
                        case {'Hamstrings','Gastrocs'}
                            SimulationRef.plotSimulationEMG_RawFilt(SimulationSpecifier,hFigure,hAxes_2x2);
                            set(hPanel_2x2,'Visible','on');
                        otherwise
                            SimulationRef.plotSimulationEMG_RawFilt(SimulationSpecifier,hFigure,hAxes_1x1);
                            set(hPanel_1x1,'Visible','on');
                    end
                case 'plotSimulationEMG'
                    set(hPanelHeader,'String',[SubjectID,'_',Simulation,':  Normalized EMG - ',SimulationSpecifier]);
                    switch SimulationSpecifier
                        case 'All'
                            SimulationRef.plotSimulationEMG(SimulationSpecifier,hFigure,hAxes_4x4);
                            set(hPanel_4x4,'Visible','on');    
                        case 'Glutes'
                            SimulationRef.plotSimulationEMG(SimulationSpecifier,hFigure,hAxes_1x2);
                            set(hPanel_1x2,'Visible','on');
                        case 'Quads'
                            SimulationRef.plotSimulationEMG(SimulationSpecifier,hFigure,hAxes_3x2);
                            set(hPanel_3x2,'Visible','on');
                        case {'Hamstrings','Gastrocs'}
                            SimulationRef.plotSimulationEMG(SimulationSpecifier,hFigure,hAxes_2x2);
                            set(hPanel_2x2,'Visible','on');
                        otherwise
                            SimulationRef.plotSimulationEMG(SimulationSpecifier,hFigure,hAxes_1x1);
                            set(hPanel_1x1,'Visible','on');
                    end
                case 'plotSimulationGRF_RawFilt'
                    set(hPanelHeader,'String',[SubjectID,'_',Simulation,':  Raw vs. Filtered GRF - ',SimulationSpecifier]);
                    switch SimulationSpecifier
                        case 'All'
                            legendStruct = SimulationRef.plotSimulationGRF_RawFilt(SimulationSpecifier,hFigure,hAxes_3x2);
                            set(hPanel_3x2,'Visible','on');
                        case {'Forces','Moments'}
                            legendStruct = SimulationRef.plotSimulationGRF_RawFilt(SimulationSpecifier,hFigure,hAxes_3x1);
                            set(hPanel_3x1,'Visible','on');
                        otherwise
                            legendStruct = SimulationRef.plotSimulationGRF_RawFilt(SimulationSpecifier,hFigure,hAxes_1x1);
                            set(hPanel_1x1,'Visible','on');
                    end
                    createLegend(legendStruct);
                case 'plotSimulationGRF_Plate'
                    set(hPanelHeader,'String',[SubjectID,'_',Simulation,':  Equivalent GRF - ',SimulationSpecifier]);
                    switch SimulationSpecifier
                        case 'All'
                            legendStruct = SimulationRef.plotSimulationGRF_Plate(SimulationSpecifier,hFigure,hAxes_3x3);
                            set(hPanel_3x3,'Visible','on');
                        case {'Forces','Moments','Coordinates'}
                            legendStruct = SimulationRef.plotSimulationGRF_Plate(SimulationSpecifier,hFigure,hAxes_3x1);
                            set(hPanel_3x1,'Visible','on');
                        otherwise
                            legendStruct = SimulationRef.plotSimulationGRF_Plate(SimulationSpecifier,hFigure,hAxes_1x1);
                            set(hPanel_1x1,'Visible','on');
                    end
                    createLegend(legendStruct);    
                case 'plotSimulationGRF'
                    set(hPanelHeader,'String',[SubjectID,'_',Simulation,':  Equivalent GRF - ',SimulationSpecifier]);
                    switch SimulationSpecifier
                        case 'All'
                            legendStruct = SimulationRef.plotSimulationGRF(SimulationSpecifier,hFigure,hAxes_3x2);
                            set(hPanel_3x2,'Visible','on');
                        case {'Forces','Moments','Coordinates'}
                            legendStruct = SimulationRef.plotSimulationGRF(SimulationSpecifier,hFigure,hAxes_3x1);
                            set(hPanel_3x1,'Visible','on');
                        otherwise
                            legendStruct = SimulationRef.plotSimulationGRF(SimulationSpecifier,hFigure,hAxes_1x1);
                            set(hPanel_1x1,'Visible','on');
                    end
                    createLegend(legendStruct);
                case 'plotSimulationKinematics'
                    set(hPanelHeader,'String',[SubjectID,'_',Simulation,':  Joint Kinematics - ',SimulationSpecifier]);
                    legendStruct = SimulationRef.plotSimulationKinematics(SimulationSpecifier,hFigure,hAxes_3x1);
                    set(hPanel_3x1,'Visible','on');
                    createLegend(legendStruct);
                case 'plotSimulationTRC'
                    set(hPanelHeader,'String',[SubjectID,'_',Simulation,':  Marker Coordinates - ',SimulationSpecifier]);
                    SimulationRef.plotSimulationTRC(SimulationSpecifier,hFigure,hAxes_3x1);
                    set(hPanel_3x1,'Visible','on');
                case 'plotCycleEMG'
                    set(hPanelHeader,'String',[SubjectID,'_',Simulation,'_',SimulationCycle,':  Normalized EMG - ',SimulationSpecifier]);
                    switch SimulationSpecifier
                        case 'All'
                            SimulationRef.plotCycleEMG(SimulationCycle,SimulationSpecifier,hFigure,hAxes_4x4);
                            set(hPanel_4x4,'Visible','on');    
                        case 'Glutes'
                            SimulationRef.plotCycleEMG(SimulationCycle,SimulationSpecifier,hFigure,hAxes_1x2);
                            set(hPanel_1x2,'Visible','on');
                        case 'Quads'
                            SimulationRef.plotCycleEMG(SimulationCycle,SimulationSpecifier,hFigure,hAxes_3x2);
                            set(hPanel_3x2,'Visible','on');
                        case {'Hamstrings','Gastrocs'}
                            SimulationRef.plotCycleEMG(SimulationCycle,SimulationSpecifier,hFigure,hAxes_2x2);
                            set(hPanel_2x2,'Visible','on');
                        otherwise
                            SimulationRef.plotCycleEMG(SimulationCycle,SimulationSpecifier,hFigure,hAxes_1x1);
                            set(hPanel_1x1,'Visible','on');
                    end                    
                case 'plotCycleGRF'
                    set(hPanelHeader,'String',[SubjectID,'_',Simulation,'_',SimulationCycle,':  Filtered GRF - ',SimulationSpecifier]);
                    switch SimulationSpecifier
                        case 'All'
                            legendStruct = SimulationRef.plotCycleGRF(SimulationCycle,SimulationSpecifier,hFigure,hAxes_3x3);
                            set(hPanel_3x3,'Visible','on');
                        case {'Forces','Moments','Coordinates'}
                            legendStruct = SimulationRef.plotCycleGRF(SimulationCycle,SimulationSpecifier,hFigure,hAxes_3x1);
                            set(hPanel_3x1,'Visible','on');
                        otherwise
                            legendStruct = SimulationRef.plotCycleGRF(SimulationCycle,SimulationSpecifier,hFigure,hAxes_1x1);
                            set(hPanel_1x1,'Visible','on');
                    end 
                    createLegend(legendStruct);
                case 'plotCycleKinematics'
                    set(hPanelHeader,'String',[SubjectID,'_',Simulation,'_',SimulationCycle,':  Joint Kinematics - ',SimulationSpecifier]);
                    legendStruct = SimulationRef.plotCycleKinematics(SimulationCycle,SimulationSpecifier,hFigure,hAxes_3x1);
                    set(hPanel_3x1,'Visible','on');
                    createLegend(legendStruct);
            end
            if max(size(strfind(SimulationMethod,'Simulation'))) || max(size(strfind(SimulationMethod,'MVC')))
            	set(hSimulationCycleList,'Value',1);
            end
        end
        set(hPanel_Toolbar,'Visible','on');
    end    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function hToolbarSaveButton_Callback(hObject,eventdata)
%         deleteLegend;
        filename = get(hPanelHeader,'String');
        filename = regexprep(filename,{':','-',' vs. ','\W'},{'__','_','',''});
        orient = questdlg('What is the desired orientation of the figure?', ...
                          'Orientation','portrait','landscape','portrait');
        numAxes = inputdlg({'Number of rows:','Number of columns'}, ...
                           'Number of Plots',1,{'1','1'});
        r = str2num(numAxes{1});
        c = str2num(numAxes{2});
        hOrigPanels = get(hFigure,'Children');
        for i = length(hOrigPanels):-1:1
            if strcmp(get(hOrigPanels(i),'Visible'),'off')
                hOrigPanels(i) = [];
            end
        end
        for i = 1:length(hOrigPanels)
            hOrigAxes = get(hOrigPanels(i),'Children');
            for j = length(hOrigAxes):-1:1
                if ~strcmp(get(hOrigAxes(j),'Type'),'axes')
                    hOrigAxes(j) = [];
                end
            end
            if ~isempty(hOrigAxes)
                hOrigPanel = hOrigPanels(i);
                break;
            end
        end
        hOrigAxes = get(hOrigPanel,'Children');
        if strcmp(orient,'portrait')
            w = 6.25; h = 8;
        elseif strcmp(orient,'landscape')
            w = 8.75; h = 5.75;
        end
        topMargin = 0.375;
        bottomMargin = 0.5;
        leftMargin = 0.5;
        rightMargin = 0.125;
        rowMargin = 0.125;
        columnMargin = 0.25;
        boxRatio = 1.618/1;
        boxWidth = floor((w-c*leftMargin-c*rightMargin-(c-1)*columnMargin)/c*8)/8;
        boxHeight = boxWidth/boxRatio;
        totalHeight = r*boxHeight+r*topMargin+r*bottomMargin+(r-1)*rowMargin;
        if totalHeight > h
            tempHeight = (h-r*topMargin-r*bottomMargin-(r-1)*rowMargin)/r;
            boxWidth = floor(tempHeight*boxRatio*8)/8;
            boxHeight = boxWidth/boxRatio;
        end
        hNewFigure = figure;
        set(hNewFigure,'Units','inches', ...
                   'Position',[1 1 8.75 8.75]);
        hNewAxes = zeros(size(hOrigAxes));
        ctr = 1;
        for i = 1:r
            for j = c:-1:1 
                hNewAxes(ctr) = axes;
                left = j*leftMargin+(j-1)*boxWidth+(j-1)*rightMargin+(j-1)*columnMargin;
                bottom = i*bottomMargin+(i-1)*boxHeight+(i-1)*topMargin+(i-1)*rowMargin;
                set(hNewAxes(ctr),'Units','inches', ...
                                 'Position',[left bottom boxWidth boxHeight]);        
                ctr = ctr+1;
            end
        end
        for i = 1:length(hOrigAxes)
            hAxesChildren = get(hOrigAxes(i),'Children');
            set(hNewFigure,'CurrentAxes',hNewAxes(i));
            hold on;
            hChildren = zeros(size(hAxesChildren));
            for j = length(hAxesChildren):-1:1
                xdata = get(hAxesChildren(j),'XData');
                ydata  = get(hAxesChildren(j),'YData');
                if strcmp(get(hAxesChildren(j),'Type'),'line')
                    lcolor = get(hAxesChildren(j),'Color');
                    lstyle = get(hAxesChildren(j),'LineStyle');
                    lwidth = get(hAxesChildren(j),'LineWidth');
                    set(hNewFigure,'CurrentAxes',hNewAxes(i));
                    hChildren(j) = line(xdata,ydata,'Color',lcolor,'LineStyle',lstyle,'LineWidth',lwidth);
                    clear xdata ydata lcolor lstyle lwidth
                elseif strcmp(get(hAxesChildren(j),'Type'),'patch')
                    pcolor = get(hAxesChildren(j),'FaceColor');
                    ptrans = get(hAxesChildren(j),'FaceAlpha');
                    set(hNewFigure,'CurrentAxes',hNewAxes(i));
                    hChildren(j) = fill(xdata,ydata,pcolor);
                    set(hChildren(j),'EdgeColor','none');
                    alpha(hChildren(j),ptrans);
                    clear xdata ydata pcolor ptrans
                end
            end
            set(hNewAxes(i),'box','off');
            set(hNewAxes(i),'XLim',get(hOrigAxes(i),'XLim'), ...
                            'YLim',get(hOrigAxes(i),'YLim'), ...
                            'FontName','Times New Roman', ...
                            'FontSize',10);
            set(get(hNewAxes(i),'XLabel'),'String',get(get(hOrigAxes(i),'XLabel'),'String'), ...
                                          'FontName','Times New Roman', ...
                                          'FontSize',12);
            set(get(hNewAxes(i),'YLabel'),'String',get(get(hOrigAxes(i),'YLabel'),'String'), ...
                                          'FontName','Times New Roman', ...
                                          'FontSize',12); 
            set(get(hNewAxes(i),'Title'),'String',get(get(hOrigAxes(i),'Title'),'String'), ...
                                         'FontName','Times New Roman', ...
                                         'FontWeight','bold', ...
                                         'FontSize',12);    
        end
        set(hNewFigure,'PaperPositionMode','auto');
        set(hNewFigure,'Renderer','painters');
        warning('off','MATLAB:print:Illustrator:DeprecatedDevice');
        print(hNewFigure,'-dill',[filename,'.ai']);
        set(hNewFigure,'RendererMode','auto');
        hSaveNote = msgbox(['The file ',filename,'.ai has been saved to the current directory.'],'Save Confirmation');
        uiwait(hSaveNote);
        close(hNewFigure);
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function hToolbarZoomButton_Callback(hToolbarZoomButton,eventdata)
        state = get(hToolbarZoomButton,'Value');
        if state == get(hToolbarZoomButton,'Max')
            zoom on;
        elseif state == get(hToolbarZoomButton,'Min')
            zoom off;
        end
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function hToolbarPanButton_Callback(hToolbarPanButton,eventdata)
        state = get(hToolbarPanButton,'Value');
        if state == get(hToolbarPanButton,'Max')
            pan on;
        elseif state == get(hToolbarPanButton,'Min')
            pan off;
        end
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function hToolbarRotateButton_Callback(hToolbarRotateButton,eventdata)
        state = get(hToolbarRotateButton,'Value');
        if state == get(hToolbarRotateButton,'Max')
            rotate3d on;
        elseif state == get(hToolbarRotateButton,'Min')
            rotate3d off;
        end
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function createLegend(legendStruct)
        lPos = [0.9 0.025 0.085 0.425];  %[0.8875 0.025 0.1 0.425]
        hLines = legendStruct.axesHandles;
        nAnnotations = length(hLines);
        hOutlineBoxAnnotation = annotation('rectangle');
        set(hOutlineBoxAnnotation,'Units','normalized');
        set(hOutlineBoxAnnotation,'Position',[lPos(1) lPos(2) lPos(3) 0.05+nAnnotations*0.025]);   %[lPos(1) lPos(2)+lPos(4)-0.05-nAnnotations*0.025 lPos(3) 0.05+nAnnotations*0.025]);
        set(hOutlineBoxAnnotation,'FaceColor',[1 1 1]);
        set(hOutlineBoxAnnotation,'Tag','LegendAnnotation');
        hHeaderAnnotation = annotation('textbox');
        set(hHeaderAnnotation,'Units','normalized');
        set(hHeaderAnnotation,'Position',[lPos(1) lPos(2)+0.025+nAnnotations*0.025 lPos(3) 0.025]);   %[lPos(1) lPos(2)+lPos(4)-0.025 lPos(3) 0.025]);
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
        for i = 1:nAnnotations
            Colors(i,:) = get(hLines(i),'Color');
            LineStyles{i} = get(hLines(i),'LineStyle');
            LineWidths(i) = get(hLines(i),'LineWidth');
        end        
        hLineAnnotations = zeros(nAnnotations,1);
        for i = 1:nAnnotations
            hLineAnnotations(i) = annotation('line');
            set(hLineAnnotations(i),'Units','normalized');
            set(hLineAnnotations(i),'Position',[lPos(1)+0.05*lPos(3) lPos(2)+0.025+nAnnotations*0.025-i*0.025 lPos(3)*0.2 0]);   %[lPos(1)+0.05*lPos(3) lPos(2)+lPos(4)-0.025-i*0.025 lPos(3)*0.2 0]);
            set(hLineAnnotations(i),'Color',Colors(i,:));
            set(hLineAnnotations(i),'LineStyle',LineStyles{i});
            set(hLineAnnotations(i),'LineWidth',LineWidths(i));
            set(hLineAnnotations(i),'Tag','LegendAnnotation');
        end
        hLabelAnnotations = zeros(nAnnotations,1);
        for i = 1:nAnnotations
            hLabelAnnotations(i) = annotation('textbox');
            set(hLabelAnnotations(i),'Units','normalized');
            set(hLabelAnnotations(i),'Position',[lPos(1)+0.3*lPos(3) lPos(2)+0.0125+nAnnotations*0.025-i*0.025 lPos(3)*0.65 0.025]);   %[lPos(1)+0.3*lPos(3) lPos(2)+lPos(4)-0.0375-i*0.025 lPos(3)*0.65 0.025]);
            set(hLabelAnnotations(i),'HorizontalAlignment','left');
            set(hLabelAnnotations(i),'VerticalAlignment','middle');
            set(hLabelAnnotations(i),'FontSize',8);
            set(hLabelAnnotations(i),'String',legendStruct.names{i});
            set(hLabelAnnotations(i),'BackgroundColor','none');
            set(hLabelAnnotations(i),'EdgeColor','none');
            set(hLabelAnnotations(i),'Tag','LegendAnnotation');
        end 
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function deleteLegend
        delete(findall(hFigure,'Tag','LegendAnnotation'));    
    end
    
    %% Display
    %
    set(hFigure,'Visible','on');
    
end
