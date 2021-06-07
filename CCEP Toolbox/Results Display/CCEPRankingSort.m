function CCEPRankingSort(varargin)
%function CCEPRankingSort
%Sort the rankings of the ERPs which were list in the ERP ranking viewer


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


%Import the key table data from the
CCEPERPFig = findobj('Tag','CCEPERPFig');
CCEPRankingTableFig = findobj('Tag','CCEPRankingTableFig');
CCEPGUIMainFig = findobj('Tag','CCEPGUIMainFig');

%Get the figure and relevant uicontrols
FileMenu = findobj(CCEPERPFig,'Tag','FileMenu');
StimSelectFig = findobj('Tag','StimSelectFig');
ERPPulseTrainSelectList = findobj(CCEPERPFig,'Tag','PulseTrainSelectList');
PulseTrainSelectList = findobj(CCEPRankingTableFig,'Tag','PulseTrainSelectList');
ReferenceButton = findobj(CCEPERPFig,'Tag','ReferenceButton');
PlotChannelList = findobj(CCEPERPFig,'Tag','PlotChannelList');
RankingMenu = findobj(CCEPRankingTableFig,'Tag','RankingMenu');
AllPlots = findobj(CCEPERPFig,'Type','Axes');

%Pull in the temporary data and make it current with the CCEPERPFig
TempRepos = CCEPERPFig.UserData.TempRepository;
ResultFile = TempRepos(1).ResultFile;
CCEPGUIParams = CCEPGUIMainFig.UserData;
load(ResultFile); %Load in the ranking results file
CCEPRankingTableFig.UserData.StimAnnot = StimAnnot;
CCEPRankingTableFig.UserData.DataStruct = DataStruct;
NumPlots = length(AllPlots);

%Get the indexes of the StimAnnot that are in the TempRepos by comparing
%the stimwindow times
ReposWin = reshape([TempRepos.TimeWindow]', [2 length(TempRepos)])';
StimAnnotWin = reshape([StimAnnot.TimeWindow]', [2 length(StimAnnot)])';
Mask = true(1,length(StimAnnot));
[~,Ind] = setdiff(StimAnnotWin,ReposWin,'rows');
Mask(Ind) = false;
StimAnnot = StimAnnot(Mask);


%Create the list for the channel information to plot the ERPs relevant to
%the File and Reference chosen
PulseTrainVal = PulseTrainSelectList.Value;
if strcmp(ReferenceButton.String,'Unipolar')
    
    %Append all pulse train data into a tempstruct so that it can be
    %accurately ranked (unipolar cases)
    TempStruct = StimAnnot(PulseTrainVal(1)).Uni;
    for a = 2:length(PulseTrainVal)
        for b = 1:length(DataStruct.Uni)
            TempStruct(b).NumValidPulses(end+1) = StimAnnot(PulseTrainVal(a)).Uni(b).NumValidPulses;
            TempStruct(b).StimDist(end+1) = StimAnnot(PulseTrainVal(a)).Uni(b).StimDist;
            TempStruct(b).ZScore(end+1) = StimAnnot(PulseTrainVal(a)).Uni(b).ZScore;
            TempStruct(b).RMSMeanRank(end+1) = StimAnnot(PulseTrainVal(a)).Uni(b).RMSMeanRank;
            TempStruct(b).RMSMeanQV(end+1) = StimAnnot(PulseTrainVal(a)).Uni(b).RMSMeanQV;
            TempStruct(b).RMSMedianRank(end+1) = StimAnnot(PulseTrainVal(a)).Uni(b).RMSMedianRank;
            TempStruct(b).RMSMedianQV(end+1) = StimAnnot(PulseTrainVal(a)).Uni(b).RMSMedianQV;
        end
    end
    
    %Average the rank values for sorting and input into the table
    for b = 1:length(DataStruct.Uni)
        TempStruct(b).NumValidPulses = sum(TempStruct(b).NumValidPulses,'omitnan');
        TempStruct(b).StimDist = mean(TempStruct(b).StimDist,'omitnan');
        TempStruct(b).ZScore = mean(TempStruct(b).ZScore,'omitnan');
        TempStruct(b).RMSMeanRank= mean(TempStruct(b).RMSMeanRank,'omitnan');
        TempStruct(b).RMSMeanQV= mean(TempStruct(b).RMSMeanQV,'omitnan');
        TempStruct(b).RMSMedianRank= mean(TempStruct(b).RMSMedianRank,'omitnan');
        TempStruct(b).RMSMedianQV= mean(TempStruct(b).RMSMedianQV,'omitnan');
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %For the Bipolar case
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
else
    %Append all pulse train data into a tempstruct so that it can be
    %accurately ranked (unipolar cases)
    TempStruct = StimAnnot(PulseTrainVal(1)).Bi;
    for a = 2:length(PulseTrainVal)
        for b = 1:length(DataStruct.Bi)
            TempStruct(b).NumValidPulses(end+1) = StimAnnot(PulseTrainVal(a)).Bi(b).NumValidPulses;
            TempStruct(b).StimDist(end+1) = StimAnnot(PulseTrainVal(a)).Bi(b).StimDist;
            TempStruct(b).ZScore(end+1) = StimAnnot(PulseTrainVal(a)).Bi(b).ZScore;
            TempStruct(b).RMSMeanRank(end+1) = StimAnnot(PulseTrainVal(a)).Bi(b).RMSMeanRank;
            TempStruct(b).RMSMeanQV(end+1) = StimAnnot(PulseTrainVal(a)).Bi(b).RMSMeanQV;
            TempStruct(b).RMSMedianRank(end+1) = StimAnnot(PulseTrainVal(a)).Bi(b).RMSMedianRank;
            TempStruct(b).RMSMedianQV(end+1) = StimAnnot(PulseTrainVal(a)).Bi(b).RMSMedianQV;
        end
    end
    
    %Average the rank values for sorting and input into the table
    for b = 1:length(DataStruct.Bi)
        TempStruct(b).NumValidPulses = sum(TempStruct(b).NumValidPulses,'omitnan');
        TempStruct(b).StimDist = mean(TempStruct(b).StimDist,'omitnan');
        TempStruct(b).ZScore = mean(TempStruct(b).ZScore,'omitnan');
        TempStruct(b).RMSMeanRank= mean(TempStruct(b).RMSMeanRank,'omitnan');
        TempStruct(b).RMSMeanQV= mean(TempStruct(b).RMSMeanQV,'omitnan');
        TempStruct(b).RMSMedianRank= mean(TempStruct(b).RMSMedianRank,'omitnan');
        TempStruct(b).RMSMedianQV= mean(TempStruct(b).RMSMedianQV,'omitnan');
    end
end

%Sort the structure by whichever RankMenu String is selected
switch RankingMenu.String{RankingMenu.Value}
    case 'Z Score'
        [~,Ind] = sort([TempStruct.ZScore],'descend','MissingPlacement','last');
        TempStruct = TempStruct(Ind);
    case 'Mean Rank'
        [~,Ind] = sort([TempStruct.RMSMeanRank],'descend','MissingPlacement','last');
        TempStruct = TempStruct(Ind);
    case 'Median Rank'
        [~,Ind] = sort([TempStruct.RMSMedianRank],'descend','MissingPlacement','last');
        TempStruct = TempStruct(Ind);
    case 'Mean Quartile Value'
        [~,Ind] = sort([TempStruct.RMSMeanQV],'descend','MissingPlacement','last');
        TempStruct = TempStruct(Ind);
    case 'Median Quartile Value'
        [~,Ind] = sort([TempStruct.RMSMedianQV],'descend','MissingPlacement','last');
        TempStruct = TempStruct(Ind);
end

%Create the table from the data selected in the pulse train menu and then
%write it into a table for viewing
TableCounter = 1;
BColor = ones(length(TempStruct),3).*0.99;
for a = 1:length(TempStruct)
    
    %Plug in the Table Data
    TableData{TableCounter,1} = TempRepos(1).Name;
    TableData{TableCounter,2} = TempStruct(a).Label;
    TableData{TableCounter,3} = TempStruct(a).Anatomical;
    TableData{TableCounter,4} = TempStruct(a).TemplateAnatomical;
    TableData{TableCounter,5} = TempStruct(a).NumValidPulses;
    TableData{TableCounter,6} = TempStruct(a).StimDist;
    TableData{TableCounter,7} = TempStruct(a).ZScore;
    TableData{TableCounter,8} = TempStruct(a).RMSMeanRank;
    TableData{TableCounter,9} = TempStruct(a).RMSMedianRank;
    TableData{TableCounter,10} = TempStruct(a).RMSMeanQV;
    TableData{TableCounter,11} = TempStruct(a).RMSMedianQV;
    
    %If channels are selected, make the background of those in the table
    %yellow to indicate to the user that they are important
    if ~isempty(PlotChannelList.Value)
        GoodChan = PlotChannelList.Value(1:NumPlots);
        if strcmp(ReferenceButton.String,'Unipolar')
            if sum(strcmp({DataStruct.Uni(GoodChan).Label},TempStruct(a).Label))>0
                BColor(a,:) = [1 1 0]; %Make Yellow the chans that are chosen
            end
        else
            if sum(strcmp({DataStruct.Bi(GoodChan).Label},TempStruct(a).Label))>0
                BColor(a,:) = [1 1 0]; %Make Yellow the chans that are chosen
            end
        end
    end
    TableCounter = TableCounter + 1;
end

%Make the columns and plot the uitable
CWidth = {120, 100, 200, 220, 90, 90, 100, 100, 100, 100, 100, 90, 90, 90, 150};
TempTable = uitable('Units','Normalized','Position',[0.01 0.01 0.73 0.95],'Tag','StimTable', 'ColumnName',{'Name','Label','Anatomical','Template Anatomical','#Pulses','Avg Dist','Z Score','Mean Rank','Median Rank','Mean QV','Median QV'},'ColumnWidth',CWidth,'Data',TableData,'FontSize',12,'BackgroundColor',BColor);