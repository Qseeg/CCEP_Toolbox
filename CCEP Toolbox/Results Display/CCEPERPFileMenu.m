function CCEPERPFileMenu(varargin)
%CCEPERPFileMenu - works with CCEPERPViewer


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


%Get the figure and relevant uicontrols
CCEPERPFig = findobj('Tag','CCEPERPFig');
FileMenu = findobj(CCEPERPFig,'Tag','FileMenu');

%Check if the same patient has been called ,if different from the already 
%present DataFile, then load it in and redo the channels and other things, 
%otherwise, return
CurrentDataFile = CCEPERPFig.UserData.DataStruct.Info.DataFile;
if strcmp(FileMenu.String{FileMenu.Value}, CurrentDataFile)
    return;
end

%If a different datafile is needed, continue to load everything in
StimSelectFig = findobj('Tag','StimSelectFig');
PulseTrainSelectList = findobj(CCEPERPFig,'Tag','PulseTrainSelectList');
ReferenceButton = findobj(CCEPERPFig,'Tag','ReferenceButton');
PlotChannelList = findobj(CCEPERPFig,'Tag','PlotChannelList');
CCEPRankingTableFig = findobj('Tag','CCEPRankingTableFig');
TempRepos = CCEPERPFig.UserData.CCEPRepository;
CCEPERPFig.UserData.ImportData = [];

%Select the repos relevant to the patients which are used and only use them
Ind = strcmp({TempRepos.DataFile},FileMenu.String{FileMenu.Value});
TempRepos = TempRepos(Ind);
CCEPERPFig.UserData.TempRepository = TempRepos;

%Allocate the strings to put in the temp repository list
TempStr = {};
for a = 1:length(TempRepos)
    TempStr{a} = sprintf('%s %s (%s) at %2.1gmA and %2.1gHz',TempRepos(a).Name,TempRepos(a).Label,TempRepos(a).Anatomical,TempRepos(a).Level,TempRepos(a).Frequency);
end

%Allocate this to the CCEPERPFig and PulseTrainList
CCEPERPFig.UserData.PulseTrainString = TempStr;
PulseTrainSelectList.Value = 1;
PulseTrainSelectList.String = TempStr;

%Load in the data form the ERP File    
[DataStruct] = CCEPDataStructCreate('name', TempRepos(1).Name, 'data',TempRepos(1).DataFile, 'annotations',TempRepos(1).AnnotFile, 'Electrode',TempRepos(1).ElectrodeFile);
CCEPERPFig.UserData.DataStruct = DataStruct;

%If the ranking table is active, write the file into the figure
if ~isempty(CCEPRankingTableFig)
    CCEPRankingTableFig.UserData.TempRepository = TempRepos;
    load(TempRepos(1).ResultFile);
    CCEPRankingTableFig.UserData.StimAnnot = StimAnnot;
    %     close(CCEPRankingTableFig.Number);
end


%Create the list for the channel information to plot the ERPs relevant to
%the File and Reference chosen
if strcmp(ReferenceButton.String,'Unipolar')
    PlotChannelList.Value = [];
    TempStr = {};
    for a = 1:length(DataStruct.Uni)
        TempStr{a} = sprintf('%s (%s)',DataStruct.Uni(a).Label,DataStruct.Uni(a).Anatomical);
    end
    PlotChannelList.String = TempStr;
    
    %For the Bipolar case
else
    PlotChannelList.Value = [];
    TempStr = {};
    for a = 1:length(DataStruct.Bi)
        TempStr{a} = sprintf('%s (%s)',DataStruct.Bi(a).Label,DataStruct.Bi(a).Anatomical);
    end
    PlotChannelList.String = TempStr;
end