function CCEPReposGUI(varargin)
%StimReposGUI - use this script to load the stim labrary and start the UI
%to look at what patients were stimmmed where and plot the results
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


%Load in the CCEPMainFig parameters to keep everything current

CCEPGUIMainFig = findobj('Tag','CCEPGUIMainFig');
if ~isempty(CCEPGUIMainFig)
    CCEPGUIParams = CCEPGUIMainFig.UserData;
    CCEPReposFileName = CCEPGUIParams.CurrentRepository;
    CCEPPath = CCEPGUIParams.CurrentPath;
    try
    load(CCEPReposFileName);
    catch
       error('Currently no CCEP stim repository is located in the "Stimulation Repository" - create one using the stimulation respoitory menu') 
    end
else
    warning('The GUI has been closed - restarting the main GUI from the beginning');
    CCEPGUIInit;
end

%Check that a previous instance of the list viewer is not present, if it
%is, simply swap to that window. Otherwise open a new one.
StimSelectFig = findobj('Tag','StimSelectFig');
if isempty(StimSelectFig)
    StimSelectFig = figure('Name','StimSelectFig','Tag','StimSelectFig','Units','Normalized','Position',[0 0 1 1]);
else
    figure(StimSelectFig.Number);
    return;
end


%Create a list based on each of the available fields
%Get the Unique Stim sites for each criteria
CompiledAnatomical = {};
CompiledTemplateAnatomical = {};
CompiledFreq = [];
CompiledLabel = {};
CompiledLevel = [];
CompiledStimAnatomical = {};
CompiledStimTemplateAnatomical = {};

for f = 1:length(CCEPRepository)
    if ~isempty(CCEPRepository(f).Electrode)
        %For the regular anatomical response names
        TempAnatomical = arrayfun(@(x) {x.Anatomical}, CCEPRepository(f).Electrode.Uni);
        TempAnatomical = unique(TempAnatomical);
        CompiledAnatomical(end+1:end+length(TempAnatomical)) = TempAnatomical;
        
        %For the template anatomical response names
        TempTemplateAnatomical = arrayfun(@(x) {x.TemplateAnatomical}, CCEPRepository(f).Electrode.Uni);
        TempTemplateAnatomical = unique(TempTemplateAnatomical);
        CompiledTemplateAnatomical(end+1:end+length(TempTemplateAnatomical)) = TempTemplateAnatomical;
    end
    
        if ~isempty(CCEPRepository(f).Repos)
        %Grab all of the frequencies
        NonZero = ~arrayfun(@(x) isempty([x.Frequency]), CCEPRepository(f).Repos); 
        TempFreq = arrayfun(@(x) [x.Frequency], CCEPRepository(f).Repos(NonZero));
        TempFreq = unique(TempFreq);
        CompiledFreq(end+1:end+length(TempFreq)) = TempFreq;
        
        %Grab all of the levels
        TempLevel = arrayfun(@(x) [x.Level], CCEPRepository(f).Repos);
        TempLevel = unique(TempLevel);
        CompiledLevel(end+1:end+length(TempLevel)) = TempLevel;
        
        %Find the names in the list of the bipolar data and get the
        %unipolar labels
        TempLabel = unique(arrayfun(@(x) {x.Label}, CCEPRepository(f).Repos));
        Counter = 1;
        NewAnatomical = {};
        NewTemplateAnatomical = {};
        for t = 1:length(TempLabel)
            c = find(strcmp({CCEPRepository(f).Electrode.Bi.Label},TempLabel{t}));
            u = CCEPRepository(f).Electrode.Bi(c).UnipolarContacts;
            CCEPRepository(f).Electrode.Bi(c).UnipolarContacts;
            NewAnatomical(end+1:end+length(u)) = {CCEPRepository(f).Electrode.Uni(u(1)).Anatomical, CCEPRepository(f).Electrode.Uni(u(2)).Anatomical};
            NewTemplateAnatomical(end+1:end+length(u)) = {CCEPRepository(f).Electrode.Uni(u(1)).TemplateAnatomical, CCEPRepository(f).Electrode.Uni(u(2)).TemplateAnatomical};
        end
        CompiledLabel(end+1:end+length(TempLabel)) = TempLabel;
        CompiledStimAnatomical(end+1:end+length(NewAnatomical)) = NewAnatomical;
        CompiledStimTemplateAnatomical(end+1:end+length(NewTemplateAnatomical)) = NewTemplateAnatomical;
        end
end

%Get the unique patient lists
List.Names = sort_nat(unique({CCEPRepository.Patient}));
List.Anatomical = sort_nat(unique(CompiledAnatomical));
List.TemplateAnatomical = sort_nat(unique(CompiledTemplateAnatomical));
List.StimAnatomical = sort_nat(unique(CompiledStimAnatomical));
List.StimTemplateAnatomical = sort_nat(unique(CompiledStimTemplateAnatomical));
List.Freq = sort(unique(CompiledFreq));
List.Level = sort(unique(CompiledLevel));
List.Label = sort_nat(unique(CompiledLabel));



%*******Create List Menu's for the essential items ********
%In order from left to right, the List Boxes will go:
%**Stim
%Patients -
%Labels -
%Level -
%Frequency -
%Anatomical -
%TemplateAnatomical -
%Stim Anatomical -
%Stim TemplateAnatomical -

%Create list for the Patient Names
PosX =0.01; PosY = 0.8; XLength = 0.08; YLength = 0.15; TempTag = 'NameList';
NameList = uicontrol('Style', 'list','String', List.Names,'Units', 'normalized','Position', [PosX, PosY, XLength, YLength],'background','white','Tag', TempTag,'Value', 1:length(List.Names),'Max',2,'Min',0,'Callback',@CCEPListFinderReposGUI);
LabelText = uicontrol('Style', 'text','String', 'Patient Names','Units', 'normalized','Position', [PosX, PosY+0.005+YLength, XLength, 0.02],'HorizontalAlignment','Left');

%Create list for the Stim Frequencies
PosX =0.01; PosY = 0.65; XLength = 0.08; YLength = 0.12; TempTag = 'FreqList';
LevelList = uicontrol('Style', 'list','String', {List.Freq},'Units', 'normalized','Position', [PosX, PosY, XLength, YLength],'background','white','Tag', TempTag,'Value', 1:length(List.Freq),'Max',2,'Min',0,'Callback',@CCEPListFinderReposGUI);
LabelText = uicontrol('Style', 'text','String', 'Stim Frequencies (Hz)','Units', 'normalized','Position', [PosX, PosY+0.005+YLength, XLength, 0.02],'HorizontalAlignment','Left');

%Create list for the Stim Levels
PosX =0.01; PosY = 0.5; XLength = 0.08; YLength = 0.12; TempTag = 'LevelList';
LevelList = uicontrol('Style', 'list','String', {List.Level},'Units', 'normalized','Position', [PosX, PosY, XLength, YLength],'background','white','Tag', TempTag,'Value', 1:length(List.Level),'Max',2,'Min',0,'Callback',@CCEPListFinderReposGUI);
LabelText = uicontrol('Style', 'text','String', 'Stim Levels (mA)','Units', 'normalized','Position', [PosX, PosY+0.005+YLength, XLength, 0.02],'HorizontalAlignment','Left');

%Label List
PosX =0.01; PosY = 0.27; XLength = 0.08; YLength = 0.19; TempTag = 'StimLabelList';
StimLabels = uicontrol('Style', 'list','String', List.Label,'Units', 'normalized','Position', [PosX, PosY, XLength, YLength],'background','white','Tag', TempTag,'Value', 1:length(List.Label),'Max',2,'Min',0,'Callback',@CCEPListFinderReposGUI);
LabelText = uicontrol('Style', 'text','String', 'Stim Site Labels','Units', 'normalized','Position', [PosX, PosY+0.005+YLength, XLength, 0.02],'HorizontalAlignment','Left');

%Create list for the Response labels
PosX =0.1; PosY = 0.5; XLength = 0.14; YLength = 0.45; TempTag = 'AnatomicalList';
Anatomical = uicontrol('Style', 'list','String', List.Anatomical,'Units', 'normalized','Position', [PosX, PosY, XLength, YLength],'background','white','Tag', TempTag,'Value', 1:length(List.Anatomical),'Max',2,'Min',0,'Callback',@CCEPListFinderReposGUI);
AnatomicalText = uicontrol('Style', 'text','String', 'Anatomical Response Sites','Units', 'normalized','Position', [PosX, PosY+0.005+YLength, XLength, 0.02],'HorizontalAlignment','Left');

%Create list for the Response template labels
PosX =0.25; PosY = 0.5; XLength = 0.14; YLength = 0.45; TempTag = 'TemplateAnatomicalList';
TemplateAnatomical = uicontrol('Style', 'list','String', List.TemplateAnatomical,'Units', 'normalized','Position', [PosX, PosY, XLength, YLength],'background','white','Tag', TempTag,'Value', 1:length(List.TemplateAnatomical),'Max',2,'Min',0,'Callback',@CCEPListFinderReposGUI);
StimAnatomicalText = uicontrol('Style', 'text','String', 'Anatomical Template Response Sites','Units','normalized','Position', [PosX, PosY+0.005+YLength, XLength, 0.02],'HorizontalAlignment','Left');

%Create list for the stim Anatomical Box
PosX =0.1; PosY = 0.01; XLength = 0.14; YLength = 0.45; TempTag = 'StimAnatomicalList';
StimAnatomical = uicontrol('Style', 'list','String', List.StimAnatomical,'Units', 'normalized','Position', [PosX, PosY, XLength, YLength],'background','white','Tag', TempTag,'Value', 1:length(List.StimAnatomical),'Max',2,'Min',0,'Callback',@CCEPListFinderReposGUI);
StimTemplateAnatomicalText = uicontrol('Style', 'text','String', 'Stim Anatomical Sites','Units','normalized','Position', [PosX, PosY+0.005+YLength, XLength, 0.02],'HorizontalAlignment','Left');

%Create list for the stim Anatomical template labels
PosX =0.25; PosY = 0.01; XLength = 0.14; YLength = 0.45; TempTag = 'StimTemplateAnatomicalList';
StimTemplateAnatomical = uicontrol('Style', 'list','String', List.StimTemplateAnatomical,'Units', 'normalized','Position', [PosX, PosY, XLength, YLength],'background','white','Tag', TempTag,'Value', 1:length(List.StimTemplateAnatomical),'Max',2,'Min',0,'Callback',@CCEPListFinderReposGUI);
LabelText = uicontrol('Style', 'text','String', 'Stim Template Anatomical','Units', 'normalized','Position', [PosX, PosY+0.005+YLength, XLength, 0.02],'HorizontalAlignment','Left');

%Show how many individual patients were present in each stim
%Plot the contacts of the selected electrodes
PosX =0.01; PosY = 0.22; XLength = 0.08; YLength = 0.04;
ShowNumPatients = uicontrol('Style', 'text','String', 'Num Patients: ','Units', 'normalized','Position', [PosX, PosY, XLength, YLength],'Tag','NumPatientsText');

%Show the number of indidual stim sites in the 
PosX =0.01; PosY = 0.18; XLength = 0.08; YLength = 0.04;
ShowIndividualStimSites = uicontrol('Style', 'text','String', 'Num Stim Sites: ','Units', 'normalized','Position', [PosX, PosY, XLength, YLength],'Tag','NumStimSitesText');

%Plot the contacts of the selected electrodes
PosX =0.005; PosY = 0.13; XLength = 0.085; YLength = 0.04;
ShowSelectedElectrodesButton = uicontrol('Style', 'pushbutton','String', 'Plot Electrodes','Units', 'normalized','Position', [PosX, PosY, XLength, YLength],'Callback',@CCEPSelectedReposElectrodeSetPlot);

%Plot the Stim Sites of the selected GUI
PosX =0.005; PosY = 0.09; XLength = 0.085; YLength = 0.04;
SelectedElectrodeButton = uicontrol('Style', 'pushbutton','String', 'Plot Stim Sites','Units', 'normalized','Position', [PosX, PosY, XLength, YLength],'Callback',@CCEPSelectedReposElectrodePlot);

%Plot the Stim Sites of the selected GUI
PosX =0.005; PosY = 0.05; XLength = 0.085; YLength = 0.04;
CompileAnatomicalButton = uicontrol('Style', 'pushbutton','String', 'Connectivity study','Units', 'normalized','Position', [PosX, PosY, XLength, YLength],'Callback',@CCEPCompileAnatomicalPipeline);

%Plot the Stim Sites of the selected GUI
PosX =0.005; PosY = 0.01; XLength = 0.085; YLength = 0.04;
ResultsViewButton = uicontrol('Style', 'pushbutton','String', 'View ERPs & Ranks','Units', 'normalized','Position', [PosX, PosY, XLength, YLength],'Callback',@CCEPERPViewer);

%Make the font a little bigger
AllUIControl = findall(StimSelectFig,'Type','UIControl');
for a = 1:length(AllUIControl)
    AllUIControl(a).FontSize = 12;
end

%Pop the data onto a figure
StimSelectFig = gcf;
StimSelectFig.UserData.List = List;
StimSelectFig.UserData.CCEPRepository = CCEPRepository;
CCEPListFinderReposGUI;
