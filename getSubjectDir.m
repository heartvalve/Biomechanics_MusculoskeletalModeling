function subDir = getSubjectDir(subID)
    % GETSUBJECTDIR - A function to get the OpenSim subject directory.
    %
    % 
    
    % Created by Megan Schroeder
    % Last Modified 2013-09-04

    
    %% Main
    % Main function definition
    
    % Subject directory
    wpath = regexp(pwd,'Northwestern-RIC','split');
    subDir = [wpath{1},'Northwestern-RIC',filesep,'Modeling',filesep,'OpenSim',...
              filesep,'Subjects',filesep,subID,filesep];
          
end
