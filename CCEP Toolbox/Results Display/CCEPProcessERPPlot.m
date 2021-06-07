function CCEPProcessERPPlot(varargin)
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

%If a different datafile is needed, continue to load everything in
StimSelectFig = findobj('Tag','StimSelectFig');
PulseTrainSelectList = findobj(CCEPERPFig,'Tag','PulseTrainSelectList');
ReferenceButton = findobj(CCEPERPFig,'Tag','ReferenceButton');
PlotChannelList = findobj(CCEPERPFig,'Tag','PlotChannelList');
TempRepos = CCEPERPFig.UserData.TempRepository;


%Load in the data form the ERP File
DataStruct = CCEPERPFig.UserData.DataStruct;
ImportData = CCEPERPFig.UserData.ImportData;


%Find the channels selected, depending on the reference type, if no
%channels are selected, print a warning
if isempty(PlotChannelList.Value)
    warning('No ERP channels selected in the CCEPERPFig');
    return;
end


%Setup the parallel pool if not already done so
try
    fprintf('Setting up the Parallel Pool\n');
    ParallelPool = gcp;
    ChanInc = 4;
    fprintf('Parallel Pool Initialised\n');
catch
    fprintf('No parallel toobox found\n');
    ParallelPool = [];
    ChanInc = 4;
end

%Check if the Imported data is in bipolar or unipolar form, if it is in the
%incorrect form, erase it
if ~isempty(ImportData)
    if strcmp(ReferenceButton.String,'Unipolar')
        if ~isempty(strfind(ImportData(1).Label,'-')) %Check for a hyphen to see if there are 2 label names
            ImportData = [];
        end
    else
        if isempty(strfind(ImportData(1).Label,'-'))
            ImportData = [];
        end
    end
end

%Do the actual import and filtering of the data
if strcmp(ReferenceButton.String,'Unipolar')
    if isempty(ImportData)
        %Import the data for the New Labels
        [~,~,~, NewImportData] = CCEPEDFBatchDataImport('Patient',TempRepos(PulseTrainSelectList.Value(1)).Name,'DataFile',TempRepos(PulseTrainSelectList.Value(1)).DataFile,'Struct',DataStruct,'Electrodes',TempRepos(PulseTrainSelectList.Value(1)).ElectrodeFile,'Annot',TempRepos(PulseTrainSelectList.Value(1)).AnnotFile,'Labels',{DataStruct.Uni(PlotChannelList.Value).Label});
        [~, NewImportData] = CCEPFilterFunction(DataStruct,NewImportData,ReferenceButton.String);
        ImportData = NewImportData;
        clearvars NewImportData;
        CCEPERPFig.UserData.ImportData = ImportData;
        
    else
        
        %Check channels in the ImportData list ( so that you only add new
        %ones)
        CurrentLabel = {ImportData.Label};
        ChosenLabel = {DataStruct.Uni((PlotChannelList.Value)).Label};
        NewLabel = setdiff(ChosenLabel,CurrentLabel);
        KeepLabel = intersect(CurrentLabel,ChosenLabel);
        
        %Remove the labels which were deselected from the last compile
        [RemoveLabel,Ind] = setdiff(CurrentLabel,KeepLabel);
        Ind = Ind';
        CurrentMask = 1:length(ImportData);
        Mask = ~ismember(CurrentMask,Ind);
        ImportData = ImportData(Mask);
        
        %Import the data for the New Labels and append it to the current
        %data
        if ~isempty(NewLabel)
            [~,~,~, NewImportData] = CCEPEDFBatchDataImport('Patient',TempRepos(PulseTrainSelectList.Value(1)).Name,'DataFile',TempRepos(PulseTrainSelectList.Value(1)).DataFile,'Struct',DataStruct,'Electrodes',TempRepos(PulseTrainSelectList.Value(1)).ElectrodeFile,'Annot',TempRepos(PulseTrainSelectList.Value(1)).AnnotFile,'Labels',NewLabel);
            [~, NewImportData] = CCEPFilterFunction(DataStruct,NewImportData,ReferenceButton.String);
            ImportData(end+1: end+length(NewImportData)) = NewImportData;
        end
        
        %Allocate unipolar indexes to sort the data into order in the
        %datastruct and then save it onto th figure
        for a = 1:length(ImportData)
            ImportData(a).UnipolarInd = find(strcmp({DataStruct.Uni.Label},{ImportData(a).Label}));
        end
        [~,Ind] = sort([ImportData.UnipolarInd]);
        ImportData = ImportData(Ind);
        ImportData = rmfield(ImportData,'UnipolarInd');
        clearvars NewImportData;
        CCEPERPFig.UserData.ImportData = ImportData;
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %For the bipolar data
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%
else
    if isempty(ImportData)
        %Import the data for the New Labels
        
        %Get the unipolar labels of the datachannels
        LoadLabel = {};
        TempLabel = {DataStruct.Bi(PlotChannelList.Value).Label};
        for b = 1:length(TempLabel)
            Ind = find(strcmp({DataStruct.Bi.Label},TempLabel{b}));
            LoadLabel{end+1} = DataStruct.Uni(DataStruct.Bi(Ind).UnipolarContacts(1)).Label;
            LoadLabel{end+1} = DataStruct.Uni(DataStruct.Bi(Ind).UnipolarContacts(2)).Label;
        end
        LoadLabel = unique(LoadLabel);
        
        %Import the unipolar data and immmediately conver into bipolar
        [~,~,~, NewImportData] = CCEPEDFBatchDataImport('Patient',TempRepos(PulseTrainSelectList.Value(1)).Name,'DataFile',TempRepos(PulseTrainSelectList.Value(1)).DataFile,'Struct',DataStruct,'Electrodes',TempRepos(PulseTrainSelectList.Value(1)).ElectrodeFile,'Annot',TempRepos(PulseTrainSelectList.Value(1)).AnnotFile,'Labels',LoadLabel);
        NewImportData = CCEPBipoImportDataConvert(NewImportData,DataStruct);
        [~, NewImportData] = CCEPFilterFunction(DataStruct,NewImportData,ReferenceButton.String);
        ImportData = NewImportData;
        clearvars NewImportData;
        CCEPERPFig.UserData.ImportData = ImportData;
        
    else
        %Check channels in the ImportData list ( so that you only add new
        %ones)
        CurrentLabel = {ImportData.Label};
        ChosenLabel = {DataStruct.Bi((PlotChannelList.Value)).Label};
        NewLabel = setdiff(ChosenLabel,CurrentLabel);
        KeepLabel = intersect(CurrentLabel,ChosenLabel);
        
        %Remove the labels which were deselected from the last compile
        [RemoveLabel,Ind] = setdiff(CurrentLabel,KeepLabel);
        Ind = Ind';
        CurrentMask = 1:length(ImportData);
        Mask = ~ismember(CurrentMask,Ind);
        ImportData = ImportData(Mask);
        
        %Get the unipolar labels of the datachannels
        if ~isempty(NewLabel)
            LoadLabel = {};
            TempLabel = NewLabel;
            for b = 1:length(TempLabel)
                Ind = find(strcmp({DataStruct.Bi.Label},TempLabel{b}));
                LoadLabel{end+1} = DataStruct.Uni(DataStruct.Bi(Ind).UnipolarContacts(1)).Label;
                LoadLabel{end+1} = DataStruct.Uni(DataStruct.Bi(Ind).UnipolarContacts(2)).Label;
            end
            LoadLabel = unique(LoadLabel);
            
            %Import the data for the New Labels and append it to the current
            %data
            [~,~,~, NewImportData] = CCEPEDFBatchDataImport('Patient',TempRepos(PulseTrainSelectList.Value(1)).Name,'DataFile',TempRepos(PulseTrainSelectList.Value(1)).DataFile,'Struct',DataStruct,'Electrodes',TempRepos(PulseTrainSelectList.Value(1)).ElectrodeFile,'Annot',TempRepos(PulseTrainSelectList.Value(1)).AnnotFile,'Labels',LoadLabel);
            NewImportData = CCEPBipoImportDataConvert(NewImportData,DataStruct);
            [~, NewImportData] = CCEPFilterFunction(DataStruct,NewImportData,ReferenceButton.String);
            ImportData(end+1: end+length(NewImportData)) = NewImportData;
        end
        
        %Allocate unipolar indexes to sort the data into order in the
        %datastruct and then save it onto the figure
        for a = 1:length(ImportData)
            ImportData(a).BipolarInd = find(strcmp({DataStruct.Bi.Label},{ImportData(a).Label}));
        end
        [~,Ind] = sort([ImportData.BipolarInd]);
        ImportData = ImportData(Ind);
        ImportData = rmfield(ImportData,'BipolarInd');
        clearvars NewImportData;
        CCEPERPFig.UserData.ImportData = ImportData;
    end
end


%Plotting routine, first delete all axes, then replot them
TempAxes = findall(CCEPERPFig, 'Type','Axes');
delete(TempAxes);
PlotOffset = [0.01 0.75 0.01 1]; %[XOffset, XLength, YOffset, YLength]
switch length(ImportData)
    case 1
        [~,PlotHandles] = CCEPCustomSubplot('Figure',CCEPERPFig.Number,'NumX',1,'NumY',1,'PlotOffset',PlotOffset,'NumAxes',length(ImportData));
    case 2
        [~,PlotHandles] = CCEPCustomSubplot('Figure',CCEPERPFig.Number,'NumX',1,'NumY',2,'PlotOffset',PlotOffset,'NumAxes',length(ImportData));
    case 3
        [~,PlotHandles] = CCEPCustomSubplot('Figure',CCEPERPFig.Number,'NumX',2,'NumY',2,'PlotOffset',PlotOffset,'NumAxes',length(ImportData));
        %         delete(findobj('Tag','Custom Subplot 4'));
    case 4
        [~,PlotHandles] = CCEPCustomSubplot('Figure',CCEPERPFig.Number,'NumX',2,'NumY',2,'PlotOffset',PlotOffset,'NumAxes',length(ImportData));
    case 5
        [~,PlotHandles] = CCEPCustomSubplot('Figure',CCEPERPFig.Number,'NumX',2,'NumY',3,'PlotOffset',PlotOffset,'NumAxes',length(ImportData));
    case 6
        [~,PlotHandles] = CCEPCustomSubplot('Figure',CCEPERPFig.Number,'NumX',2,'NumY',3,'PlotOffset',PlotOffset,'NumAxes',length(ImportData));
    case 7
        [~,PlotHandles] = CCEPCustomSubplot('Figure',CCEPERPFig.Number,'NumX',3,'NumY',3,'PlotOffset',PlotOffset,'NumAxes',length(ImportData));
    case 8
        [~,PlotHandles] = CCEPCustomSubplot('Figure',CCEPERPFig.Number,'NumX',3,'NumY',3,'PlotOffset',PlotOffset,'NumAxes',length(ImportData));
    case 9
        [~,PlotHandles] = CCEPCustomSubplot('Figure',CCEPERPFig.Number,'NumX',3,'NumY',3,'PlotOffset',PlotOffset,'NumAxes',length(ImportData));
    case 10
        [~,PlotHandles] = CCEPCustomSubplot('Figure',CCEPERPFig.Number,'NumX',3,'NumY',4,'PlotOffset',PlotOffset,'NumAxes',length(ImportData));
    case 11
        [~,PlotHandles] = CCEPCustomSubplot('Figure',CCEPERPFig.Number,'NumX',3,'NumY',4,'PlotOffset',PlotOffset,'NumAxes',length(ImportData));
    case 12
        [~,PlotHandles] = CCEPCustomSubplot('Figure',CCEPERPFig.Number,'NumX',3,'NumY',4,'PlotOffset',PlotOffset,'NumAxes',length(ImportData));
    otherwise
        [~,PlotHandles] = CCEPCustomSubplot('Figure',CCEPERPFig.Number,'NumX',3,'NumY',4,'PlotOffset',PlotOffset,'NumAxes',length(ImportData));
end

%Now plot the data into the axes
for a = 1:length(PlotHandles)
    axes(PlotHandles(a));
    TempERP  = {};
    TimeInd = {};
    LegendStr = {};
    ReposInd = PulseTrainSelectList.Value;
    
    %Plot the mean ERP for each pulse train, superimposed on top of each
    %other
    for e = 1:length(ReposInd)
        %Get the ERP indexes in order to be able to plot them accurately in
        %time, as well as the origin index
        TimeInd{e} = TempRepos(ReposInd(e)).PlotERPIndexes;
        [~,Ind] = find(round(TimeInd{e}) == 0);
        Ind = (Ind-3):1:(Ind-1);
        %Get the zero-offset (amplitude) ERPs plotted in order to correctly average
        %them. Do this by subtracting the average amplitude of the 5 samples before
        %stim from each temp ERP
        for f = 1:size(TempRepos(ReposInd(e)).ERPDataInds,1)
            TempERP{e} = ImportData(a).Data(TempRepos(ReposInd(e)).ERPDataInds(f,:)) - mean(ImportData(a).Data(TempRepos(ReposInd(e)).ERPDataInds(f,Ind))); 
        end
        
        MeanERP{e} = mean(TempERP{e},1);
        plot(TimeInd{e}, MeanERP{e});
        LegendStr{e} = sprintf('%s (%s) at %2.1gmA',TempRepos(ReposInd(e)).Label,TempRepos(ReposInd(e)).Anatomical,TempRepos(ReposInd(e)).Level);
        hold on;
    end
    
    %Zoom on the data and indicate a line on the plot
    axis('tight');
    line([0 0], [PlotHandles(a).YLim(1), PlotHandles(a).YLim(2)], 'linestyle','-.','color','r','linewidth',1);
    line([PlotHandles(a).XLim(1), PlotHandles(a).XLim(2)], [0, 0], 'linestyle','-.','color','k','linewidth',0.1);
    legend(LegendStr);
    title(sprintf('%s', ImportData(a).Label));
    xlabel('Time (ms)');
    ylabel('Amplitude (\muV)');
end
linkaxes(PlotHandles,'xy');