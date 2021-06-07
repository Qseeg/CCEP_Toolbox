function CCEPStimSafetyGUI(varargin)
%CCEPStimSafetyGUI
% Create a simple UI menu to check what CCEP parameters are able to be used
% safely. This is based on research from Gordon et al. (1990). This was 


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


%Check if Figure exists or must be created
CCEPStimSafetyFig = findobj('Tag','CCEPStimSafetyFig');
CCEPGUIMainFig = findobj('Tag','CCEPGUIMainFig');
CCEPGUIParams = CCEPGUIMainFig.UserData; 
if isempty(CCEPStimSafetyFig)
    CCEPStimSafetyFig = figure('name','CCEPStimSafetyFig','Tag','CCEPStimSafetyFig','units','normalized', 'outerposition',[0 0 1 1]);
    CCEPStimSafetyPlot;
else
    figure(CCEPStimSafetyFig.Number);
end

%Load in all of the studies which are present
CCEPStimSafetyTable = CCEPGUIParams.CCEPStimSafetyTable; 
load(which(CCEPStimSafetyTable));
CCEPStimSafetyFig.UserData = StudyDetails;

%For the electrode details section
PosX =0.79; PosY = 0.95; XLength = 0.2; YLength = 0.04;
ElectrodeText = uicontrol('Style', 'text','String', 'Electrode Details','Units', 'normalized','Position', [PosX, PosY, XLength, 0.05],'HorizontalAlignment','Center','FontSize',20);

%For the electrode type button
PosX =0.78; PosY = 0.90; XLength = 0.1; YLength = 0.04; TempTag = 'ElectrodeTypeButton';
ElectrodeTypeButton = uicontrol('Style', 'togglebutton','String', 'SEEG','Units', 'normalized','Position', [PosX+XLength, PosY, XLength, YLength],'HorizontalAlignment','Left','Tag',TempTag,'Value',1,'FontSize',15,'Callback', @CCEPSafetyElectrodeToggle);
ElectrodeTypeText = uicontrol('Style', 'text','String', 'Type','Units', 'normalized','Position', [PosX, PosY, XLength, YLength],'HorizontalAlignment','Center','FontSize',17);


%For the electrode diamteter text box
PosX =0.78; PosY = 0.85; XLength = 0.1; YLength = 0.04; TempTag = 'ElectrodeDiameter';
ElectrodeDiameter = uicontrol('Style', 'edit','String', '0.8','Units', 'normalized','Position', [PosX+XLength, PosY, XLength, YLength],'HorizontalAlignment','Left','Tag',TempTag,'FontSize',15);
ElectrodeDiameterText = uicontrol('Style', 'text','String', 'Diameter (mm)','Units', 'normalized','Position', [PosX, PosY, XLength, YLength],'HorizontalAlignment','Center','FontSize',17);

%For the electrode length text box
PosX =0.78; PosY = 0.80; XLength = 0.1; YLength = 0.04; TempTag = 'ElectrodeLength';
ElectrodeLength = uicontrol('Style', 'edit','String', '2','Units', 'normalized','Position', [PosX+XLength, PosY, XLength, YLength],'HorizontalAlignment','Left','Tag',TempTag,'FontSize',15);
ElectrodeLengthText = uicontrol('Style', 'text','String', 'Length (mm)','Units', 'normalized','Position', [PosX, PosY, XLength, YLength],'HorizontalAlignment','Center','Tag','ElectrodeLengthText','FontSize',17);


%For the Pulse parameters section
PosX =0.79; PosY = 0.70; XLength = 0.2; YLength = 0.04;
ElectrodeText = uicontrol('Style', 'text','String', 'Pulse Parameters','Units', 'normalized','Position', [PosX, PosY, XLength, 0.05],'HorizontalAlignment','Center','FontSize',20);

%For the stim frequency
PosX =0.78; PosY = 0.65; XLength = 0.1; YLength = 0.04; TempTag = 'StimFrequency';
ElectrodeTypeButton = uicontrol('Style', 'edit','String', '1','Units', 'normalized','Position', [PosX+XLength, PosY, XLength, YLength],'HorizontalAlignment','Left','Tag',TempTag,'FontSize',15);
ElectrodeTypeText = uicontrol('Style', 'text','String', 'Stim Freq (Hz)','Units', 'normalized','Position', [PosX, PosY, XLength, YLength],'HorizontalAlignment','Center','FontSize',17);


%For the stim current
PosX =0.78; PosY = 0.60; XLength = 0.1; YLength = 0.04; TempTag = 'MaxCurrent';
ElectrodeTypeButton = uicontrol('Style', 'edit','String', '1','Units', 'normalized','Position', [PosX+XLength, PosY, XLength, YLength],'HorizontalAlignment','Left','Tag',TempTag,'FontSize',15);
ElectrodeTypeText = uicontrol('Style', 'text','String', 'Max Current (mA)','Units', 'normalized','Position', [PosX, PosY, XLength, YLength],'HorizontalAlignment','Center','FontSize',17);

%For the pulse width
PosX =0.78; PosY = 0.55; XLength = 0.1; YLength = 0.04; TempTag = 'MaxPW';
ElectrodeTypeButton = uicontrol('Style', 'edit','String', '1','Units', 'normalized','Position', [PosX+XLength, PosY, XLength, YLength],'HorizontalAlignment','Left','Tag',TempTag,'FontSize',15);
ElectrodeTypeText = uicontrol('Style', 'text','String', 'Pulse Width (ms)','Units', 'normalized','Position', [PosX, PosY, XLength, YLength],'HorizontalAlignment','Center','FontSize',17);



%To compile the current density and plot the device
PosX =0.78; PosY = 0.49; XLength = 0.2; YLength = 0.04; TempTag = 'CompileEstimate';
ElectrodeTypeButton = uicontrol('Style', 'pushbutton','String', 'Compile current density estimates','Units', 'normalized','Position', [PosX, PosY, XLength, YLength],'HorizontalAlignment','Left','Tag',TempTag,'FontSize',17,'Value',1,'Callback', @CCEPSafetyEstimate);


%To compile the current density and plot the device
PosX =0.78; PosY = 0.44; XLength = 0.2; YLength = 0.04; TempTag = 'ChargeDensityText';
ElectrodeTypeButton = uicontrol('Style', 'text','String', 'Click compile to show current density','Units', 'normalized','Position', [PosX, PosY, XLength, YLength],'HorizontalAlignment','Center','Tag',TempTag,'FontSize',15,'ForeGroundColor','r');
% PosX =0.78; PosY = 0.37; XLength = 0.2; YLength = 0.08; TempTag = 'ChargeDensityRateText';
% ElectrodeTypeButton = uicontrol('Style', 'text','String', 'Click compile to show current density rate','Units', 'normalized','Position', [PosX, PosY, XLength, YLength],'HorizontalAlignment','Center','Tag',TempTag,'FontSize',15,'ForeGroundColor','b');


%For the study names to plot on the axes
PosX =0.78; PosY = 0.08; XLength = 0.2; YLength = 0.3; TempTag = 'StudyList';
TypeText = uicontrol('Style', 'listbox','String', {StudyDetails.Publication},'Units', 'normalized','Position', [PosX, PosY, XLength, YLength],'background','white','Tag', TempTag,'Value', 1:length(StudyDetails),'Max',2,'Min',0,'FontSize',15);
ElectrodeTypeText = uicontrol('Style', 'text','String', 'Studies to plot','Units', 'normalized','Position', [PosX, PosY+YLength, XLength, 0.05],'HorizontalAlignment','Center','FontSize',20);

%For the button to show the safety studies
PosX =0.78; PosY = 0.03; XLength = 0.2; YLength = 0.04; TempTag = 'ShowSafetyStudies';
ElectrodeTypeButton = uicontrol('Style', 'pushbutton','String', 'Show table of selected studies','Units', 'normalized','Position', [PosX, PosY, XLength, YLength],'HorizontalAlignment','Center','Tag',TempTag,'FontSize',17,'Value',1,'Callback', @CCEPStudyTableViewer);