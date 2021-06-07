function CCEPImageSelectMenu(varargin)
%Use this function to look through the SPECT or CoOrd grab gui when you are
%using these features
 

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
Temp = findobj('Tag','ImageProcessMenuFig');
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
    StimReposMenuFig = findobj('Tag','ImageProcessMenuFig');
    if isempty(StimReposMenuFig)
    StimReposMenuFig = figure('name','ImageProcessMenuFig','Tag','ImageProcessMenuFig',...
        'units','pixels', 'position',[500 200 500 400],...
        'outerposition',[500 200 500 400]);
    end
    
    %Initialise the buttons for callbacks and the text
    uicontrol('tag','CCEPGUIText','style','text',...
        'Units','Normalized','Position',[0.01 0.85 0.99 0.15],...
        'String','Image processing menu','FontSize',20);
    
    uicontrol('tag', 'SPMCoOrdAcquire','style', 'pushbutton',...
        'Units', 'Normalized','Position',[0.01 0.6 0.99 0.1],...
        'String', sprintf('Acquire the electrode CoOrds'),...
        'FontSize', 15, 'callback', 'CCEPSPMCoOrdGUIInit');
    
    uicontrol('tag', 'SPMMRCTPreProcess','style', 'pushbutton',...
        'Units', 'Normalized','Position',[0.01 0.4 0.99 0.1],...
        'String', sprintf('Preprocess an MRI and CT'),...
        'FontSize', 15, 'callback', 'CCEPMRICTPreprocessingCurrentWorking');
