function FilePathMenu(Event, Source)


% Copyright 2020 QIMR Berghofer Medical Research Institute
% Author: David Prime
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <https://www.gnu.org/licenses/>.


%If a figure already exists, close it and start afresh
Temp = findobj('Tag','FilePathFig');
if ~isempty(Temp)
    close(Temp);
end
    
    CCEPGUIMainFig = findobj('Tag','CCEPGUIMainFig');
    if ~isempty(CCEPGUIMainFig)
        CCEPGUIParams = CCEPGUIMainFig.UserData;
    else
        error('The GUI has been closed - restarting the main GUI for the beginning');
    end
    
    
    %Initialise the figure
    FilePathFig = figure('name','FilePathFig','Tag','FilePathFig',...
        'units','pixels', 'position',[500 200 500 400],...
        'outerposition',[500 200 500 400]);
    
    
    %Initialise the buttons for callbacks and the text
    uicontrol('tag','CCEPGUIText','style','text',...
        'Units','Normalized','Position',[0.01 0.90 0.99 0.10],...
        'String','CCEP GUI Folder and Path Menu','FontSize',20);
    
    uicontrol('tag', 'TempPathFolderAdd','style', 'pushbutton',...
        'Units', 'Normalized','Position',[0.01 0.7 0.99 0.1],...
        'String', sprintf('Add a folder to the Matlab path\nfor this session only'),...
        'FontSize', 15, 'callback', @FilePathMenuCallBack);
    
    uicontrol('tag', 'CCEPPathFolderAdd','style', 'pushbutton',...
        'Units', 'Normalized','Position',[0.01 0.5 0.99 0.1],...
        'String', 'Add many folders to the CCEP GUI Path',...
        'FontSize', 15, 'callback', @FilePathMenuCallBack);
    
    uicontrol('tag', 'CCEPPathFolderRemove','style', 'pushbutton',...
        'Units', 'Normalized','Position',[0.01 0.3 0.99 0.1],...
        'String', 'Remove folders from the CCEP GUI Path',...
        'FontSize', 15, 'callback', @FilePathMenuCallBack);
end

function FilePathMenuCallBack(Source, Event)

%Load in the CCEPMainFig parameters to keep everything current
CCEPGUIMainFig = findobj('Tag','CCEPGUIMainFig');
if ~isempty(CCEPGUIMainFig)
    CCEPGUIParams = CCEPGUIMainFig.UserData;
else
    error('The GUI has been closed - restarting the main GUI for the beginning');
end

%Initialise a counter to keep track of how many folders are changed
FolderSelectedCounter = 0;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Temporarily add the selected folders to the Matlab path %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Add the selected downstream folders to the Matlab path for this session
if strcmp(Source.Tag,'TempPathFolderAdd')
    NewPath = uigetdir(CCEPGUIParams.StartFolder,'Select a folder to add all downstream folders temporarily to the Matlab path');
    if NewPath == 0
        return;
    end
    addpath(genpath(NewPath));
    
    Expression = ';';
    NewFolders = regexp(genpath(NewPath),Expression,'split');
    
    %If there is no record of the downstream folders from the one selected,
    %add the folder to the CCEPGUIPath (to be included in the path upon
    %load)
    if iscell(NewFolders)
        for a = 1:(length(NewFolders)-1)
            if CCEPGUIParams.Verbosity == 1
                fprintf('Added %s to the Path\n',NewFolders{a});
            end
        end
    elseif ischar(NewFolders)
        if CCEPGUIParams.Verbosity == 1
            fprintf('Added %s to the Path\n',NewFolders);
        end
    end
    fprintf('Finished temporary path add\n\n');
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%     Add the folders to the CCEPGUIParamsStruct    %%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %Generate a path of all of the downstream folders selected and add them to
    %the current Matlab working path, as well as the CCEPGUIParams Current Path
elseif strcmp(Source.Tag,'CCEPPathFolderAdd')
    
    %Start in the main folder to begin again, then add the downstream
    %folders from those selected to the current Matlab path
    NewPath = uigetdir(CCEPGUIParams.StartFolder);
    if NewPath == 0
        return;
    end
    addpath(genpath(NewPath));
    
    
    %Get all of the names of the new folders to compare against the old
    %folders in the directory
    Expression = ';';
    NewFolders = regexp(genpath(NewPath),Expression,'split');
    CurrentFolders = CCEPGUIParams.CurrentPath;
    
    %If there is no record of the downstream folders from the one selected,
    %add the folder to the CCEPGUIPath (to be included in the path upon
    %load)
    if iscell(NewFolders)
        for a = 1:(length(NewFolders)-1)
            if ~contains(CurrentFolders, NewFolders{a})
                CurrentFolders = sprintf('%s%s;',CurrentFolders,NewFolders{a});
                FolderSelectedCounter = FolderSelectedCounter +1;
                if CCEPGUIParams.Verbosity == 1
                    fprintf('Added %s to the CCEPGUIParams.CurrentPath\n',NewFolders{a});
                end
            end
        end
    elseif ischar(NewFolders)
        if ~contains(CurrentFolders, NewFolders)
            CurrentFolders = sprintf('%s%s;',CurrentFolders,NewFolders);
            FolderSelectedCounter = FolderSelectedCounter +1;
            if CCEPGUIParams.Verbosity == 1
                fprintf('Added %s to the CCEPGUIParams.CurrentPath\n',NewFolders);
            end
        end
    end
    
    %State how many, if any folders added to the path
    if FolderSelectedCounter>=1
        fprintf('%i new folders added to the path\n',FolderSelectedCounter);
    else
        fprintf('No new folders added to the path\n');
    end
    
    %Then write this to the current path in the CCEPGUIMainFig and tell the
    %user
    CCEPGUIParams.CurrentPath = CurrentFolders;
    CCEPGUIMainFig.UserData = CCEPGUIParams;
    if CCEPGUIParams.Verbosity < 3
        fprintf('Saving the updated CCEPGUIParams Current Path...\n');
        save(CCEPGUIParams.ParameterFile,'CCEPGUIParams','-v6');
        fprintf('Files added to path successfully\n\n');
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%    Remove the foldes from CCEPGUIParamsStruct     %%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %Dynamically replace the folders which were selected with blank spaces, so
    %that they are effectively removed from the CCEPGUIParams Current Path
elseif strcmp(Source.Tag,'CCEPPathFolderRemove')
    %Start in the main folder to begin again
    NewPath = uigetdir(CCEPGUIParams.StartFolder);
    if NewPath == 0
        return;
    end
    
    %Get all of the names of the new folders to compare against the old
    %folders in the directory
    Expression = ';';
    NewFolders = regexp(genpath(NewPath),Expression,'split');
    CurrentFolders = CCEPGUIParams.CurrentPath;
    
    %Remove the the folder in the CCEPGUIPath from the current path in the
    %Init File, as well as the current Matlab Path
    if iscell(NewFolders)
        for a = (length(NewFolders)-1):-1:1 %Move backwards through the folder structure so you don't replace the parent folder first
            if contains(CurrentFolders, NewFolders{a})
                FolderSelectedCounter = FolderSelectedCounter +1;
                %Replace the folder text in the current path with a blank space (effectively deleting it from the path)
                CurrentFolders = strrep(CurrentFolders,sprintf('%s',NewFolders{a}),'');
                rmpath(NewFolders{a});
                if CCEPGUIParams.Verbosity == 1
                    fprintf('Removed %s from the CCEPGUIParams.CurrentPath\n',NewFolders{a});
                end
            end
        end
    elseif ischar(NewFolders)
        if contains(CurrentFolders, NewFolders)
            FolderSelectedCounter = FolderSelectedCounter +1;
            %Replace the folder text in the current path with a blank space (effectively deleting it from the path)
            CurrentFolders = strrep(CurrentFolders,sprintf('%s',NewFolders),'');
            rmpath(NewFolders);
            if CCEPGUIParams.Verbosity == 1
                fprintf('Removed %s from the CCEPGUIParams.CurrentPath\n',NewFolders);
            end
        end
    end
    
    %State how many, if any folders were removed from the path
    if FolderSelectedCounter>=1
        fprintf('%i folders removed from the path\n',FolderSelectedCounter);
    else
        fprintf('No new folders removed from the path\n');
    end
    
    %Then write this to the current path in the CCEPGUIMainFig and tell the
    %user
    CCEPGUIParams.CurrentPath = CurrentFolders;
    CCEPGUIMainFig.UserData = CCEPGUIParams;
    if CCEPGUIParams.Verbosity < 3
        fprintf('Saving the updated CCEPGUIParams Current Path...\n');
        save(CCEPGUIParams.ParameterFile,'CCEPGUIParams','-v6');
        fprintf('Files removed from the path successfully\n\n');
    end
end
end