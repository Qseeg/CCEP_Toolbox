function CCEPReposMenu(varargin)
%Function to call the menu for creating and exploring the CCEP stimulation
%repository
%

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
Temp = findobj('Tag','StimReposMenuFig');
if ~isempty(Temp)
    close(Temp);
end
    
    CCEPGUIMainFig = findobj('Tag','CCEPGUIMainFig');
    if ~isempty(CCEPGUIMainFig)
        CCEPGUIParams = CCEPGUIMainFig.UserData;
    else
        warning('The GUI has been closed - restarting the main GUI for the beginning');
        CCEPGUIInit;
    end
    
    %Initialise the figure
    StimReposMenuFig = findobj('Tag','StimReposMenuFig');
    if isempty(StimReposMenuFig)
    StimReposMenuFig = figure('name','StimReposMenuFig','Tag','StimReposMenuFig',...
        'units','pixels', 'position',[500 200 500 400],...
        'outerposition',[500 200 500 400]);
    end
    
    %Initialise the buttons for callbacks and the text
    uicontrol('tag','CCEPGUIText','style','text',...
        'Units','Normalized','Position',[0.01 0.90 0.99 0.10],...
        'String','Stimulation repository selection interaction menu','FontSize',20);
    
    uicontrol('tag', 'StimReposCompile','style', 'pushbutton',...
        'Units', 'Normalized','Position',[0.01 0.7 0.99 0.1],...
        'String', sprintf('Compile a stimulation repository\nfrom folders on the CCEPGUI path'),...
        'FontSize', 15, 'callback', @CCEPRepositoryCompileUpdate);
    
    uicontrol('tag', 'StimReposAddIndividual','style', 'pushbutton',...
        'Units', 'Normalized','Position',[0.01 0.5 0.99 0.1],...
        'String', 'Add an individual results file',...
        'FontSize', 15, 'callback', @CCEPRepositoryUpdateIndividual);
    
    uicontrol('tag', 'CCEPPathFolderRemove','style', 'pushbutton',...
        'Units', 'Normalized','Position',[0.01 0.3 0.99 0.1],...
        'String', sprintf('View the current CCEP repository'),...
        'FontSize', 15, 'callback', @CCEPReposGUI);
