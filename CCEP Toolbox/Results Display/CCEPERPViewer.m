function CCEPERPViewer(varargin)
%CCEPERPViewer - load in a processed results file which is in the
%CCEPRepository and then look at the averaged ERPs


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
CCEPERPFig = findobj('Tag','CCEPERPFig');
CCEPGUIMainFig = findobj('Tag','CCEPGUIMainFig');
StimSelectFig = findobj('Tag','StimSelectFig');
CCEPGUIParams = CCEPGUIMainFig.UserData; 
if isempty(CCEPERPFig)
    CCEPERPFig = figure('name','CCEPERPFig','Tag','CCEPERPFig','units','normalized', 'outerposition',[0 0 1 1]);
else
    figure(CCEPERPFig.Number);
end

%Load in key details from the studies that are selected in the
%StimSelectFig
TempRepos = StimSelectFig.UserData.TempRepository;
CCEPERPFig.UserData.CCEPRepository = TempRepos;
CCEPERPFig.UserData.ImportData = [];

%Get a list of the patients to select
FileList = unique({TempRepos.DataFile});

%Select the repos relevant to the patients which are used and only use them
Ind = strcmp({TempRepos.DataFile},FileList{1});
TempRepos = TempRepos(Ind);
[DataStruct] = CCEPDataStructCreate('name', TempRepos(1).Name, 'data',TempRepos(1).DataFile, 'annotations',TempRepos(1).AnnotFile, 'Electrode',TempRepos(1).ElectrodeFile);
CCEPERPFig.UserData.DataStruct = DataStruct;
CCEPERPFig.UserData.TempRepository = TempRepos;

%Allocate the strings to put in the temp repository list
for a = 1:length(TempRepos)
TempStr{a} = sprintf('%s %s (%s) at %2.1gmA and %2.1gHz ',TempRepos(a).Name,TempRepos(a).Label,TempRepos(a).Anatomical,TempRepos(a).Level,TempRepos(a).Frequency);
end
CCEPERPFig.UserData.PulseTrainString = TempStr;

%Create the list for the channel information to plot the ERPs relevant to
%the File and Reference chosen
TempStr = {1,length(DataStruct.Uni)};
for a = 1:length(DataStruct.Uni)
    TempStr{a} = sprintf('%s (%s)',DataStruct.Uni(a).Label,DataStruct.Uni(a).Anatomical);
end
TempChannelList= TempStr;



%For the rigth hand side menu section
PosX =0.75; PosY = 0.95; XLength = 0.25; YLength = 0.04;
MenuHeadingText = uicontrol('Style', 'text','String', 'Parameters for ERP plotting','Units', 'normalized','Position', [PosX, PosY, XLength, 0.05],'HorizontalAlignment','Center','FontSize',20);


%File name to search
PosX =0.75; PosY = 0.88; XLength = 0.12; YLength = 0.06; TempTag = 'FileMenu';
FileMenu = uicontrol('Style', 'popupmenu','String', FileList,'Units', 'normalized','Position', [PosX+XLength, PosY, XLength, YLength],'HorizontalAlignment','Left','Tag',TempTag,'Value',1,'FontSize',15,'Callback', @CCEPERPFileMenu);
FileMenuText = uicontrol('Style', 'text','String', 'Patient Name to choose','Units', 'normalized','Position', [PosX, PosY, XLength, YLength],'HorizontalAlignment','Center','FontSize',17);


%For the referencing arrangement button
PosX =0.75; PosY = 0.81; XLength = 0.12; YLength = 0.06; TempTag = 'ReferenceButton';
ReferenceButton = uicontrol('Style', 'togglebutton','String', 'Unipolar','Units', 'normalized','Position', [PosX+XLength, PosY, XLength, YLength],'HorizontalAlignment','Left','Tag',TempTag,'Value',1,'FontSize',15,'Callback', @CCEPERPReference);
ReferenceButtonText = uicontrol('Style', 'text','String', 'Referencing arrangement','Units', 'normalized','Position', [PosX, PosY, XLength, YLength],'HorizontalAlignment','Center','FontSize',17);


%For the pulse train selection list
PosX =0.75; PosY = 0.75; XLength = 0.25; YLength = 0.05; TempTag = 'PulseTrainSelectList'; 
PulseTrainListText = uicontrol('Style', 'text','String', 'Pulse trains to average','Units', 'normalized','Position', [PosX, PosY, XLength, YLength],'HorizontalAlignment','Center','FontSize',17);
PosX =0.75; PosY = PosY - 0.24; XLength = 0.25; YLength = 0.25; TempTag = 'PulseTrainSelectList';
PulseTrainList = uicontrol('Style', 'listbox','String', CCEPERPFig.UserData.PulseTrainString','Units', 'normalized','Position', [PosX, PosY, XLength, YLength],'background','white','Tag', TempTag,'Value', 1,'Max',2,'Min',0,'FontSize',15,'HorizontalAlignment','Center');

%For the ERPs to plot
PosX =0.75; PosY = 0.45; XLength = 0.25; YLength = 0.05; TempTag = 'PlotChannelList';
PlotChannelListText = uicontrol('Style', 'text','String', 'Select the electrodes to plot (Max 12)','Units', 'normalized','Position', [PosX, PosY, XLength, YLength],'HorizontalAlignment','Center','FontSize',17);
PosX =0.75; PosY = PosY - 0.28; XLength = 0.25; YLength = 0.3; TempTag = 'PlotChannelList';
PlotChannelList = uicontrol('Style', 'listbox','String',TempChannelList' ,'Units', 'normalized','Position', [PosX, PosY, XLength, YLength],'background','white','Tag', TempTag,'Value', [],'Max',2,'Min',0,'FontSize',15,'HorizontalAlignment','Center');

%Create a compile the button to initiate the ERP Plots
PosX =0.78; PosY = 0.10; XLength = 0.2; YLength = 0.04; TempTag = 'ProcessERPPlot';
ElectrodeTypeButton = uicontrol('Style', 'pushbutton','String', 'Process and plot ERPs','Units', 'normalized','Position', [PosX, PosY, XLength, YLength],'HorizontalAlignment','Left','Tag',TempTag,'FontSize',17,'Value',1,'Callback', @CCEPProcessERPPlot);

%Create a compile the button to initiate the ERP Plots
PosX =0.78; PosY = 0.03; XLength = 0.2; YLength = 0.04; TempTag = 'RankingViewer';
TableShowButton = uicontrol('Style', 'pushbutton','String', 'Create Ranking Table','Units', 'normalized','Position', [PosX, PosY, XLength, YLength],'HorizontalAlignment','Left','Tag',TempTag,'FontSize',17,'Value',1,'Callback', @CCEPERPRankingViewer);
