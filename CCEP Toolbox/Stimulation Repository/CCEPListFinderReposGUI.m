
function CCEPListFinderReposGUI(varargin)
%List Finder Callback
%This function will simply find the handles generated by the CCEPDataGUI
%function and return which stim indexes are present from the criteria
%chosen

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


StimSelectFig = findobj('Tag','StimSelectFig');
NameList = findobj(StimSelectFig, 'Tag', 'NameList');
FreqList = findobj(StimSelectFig, 'Tag', 'FreqList');
LevelList = findobj(StimSelectFig, 'Tag', 'LevelList');
StimLabelList = findobj(StimSelectFig, 'Tag', 'StimLabelList');
StimAnatomicalList = findobj(StimSelectFig, 'Tag', 'StimAnatomicalList');
StimTemplateAnatomicalList = findobj(StimSelectFig, 'Tag', 'StimTemplateAnatomicalList');
AnatomicalList = findobj(StimSelectFig, 'Tag', 'AnatomicalList');
TemplateAnatomicalList = findobj(StimSelectFig, 'Tag', 'TemplateAnatomicalList');
NumStimSiteText = findobj(StimSelectFig, 'Tag', 'NumStimSitesText');
NumPatientsText = findobj(StimSelectFig, 'Tag', 'NumPatientsText');

List = StimSelectFig.UserData.List;
CCEPRepository = StimSelectFig.UserData.CCEPRepository;


%Initialise a map of true indexes of stimulation to include
for p = 1:length(CCEPRepository)
Chosen(p).Flag = true(length(CCEPRepository(p).Repos),1);
end


%Choose the patients who will be included and create the temp repos
for p = 1:length(CCEPRepository)
    if ~isempty(find(NameList.Value == p))
        Chosen(p).Flag = true(length(CCEPRepository(p).Repos),1);
    else
        Chosen(p).Flag = false(length(CCEPRepository(p).Repos),1);
    end
end

%Of the valid patients, find the patients who have the correct response
%sites (any of the ones chosen)
% for p = 1:length(CCEPRepository)
%     %Anatomical response sites check - make the patient empty if there is
%     %not the correct response site included in the electrodes
%     if sum([Chosen(p).Flag]) == length([Chosen(p).Flag])
%         if ~isempty(CCEPRepository(p).Electrode)
%             ValidSites = intersect(List.Anatomical(AnatomicalList.Value),{CCEPRepository(p).Electrode.Uni.Anatomical});
%             if isempty(ValidSites)
%                Chosen(p).Flag = false(length(CCEPRepository(p).Repos),1); 
%             end 
%         end
%     end
%     %Anatomical template check
%     if sum([Chosen(p).Flag]) == length([Chosen(p).Flag])
%         if ~isempty(CCEPRepository(p).Electrode)
%             ValidSites = intersect(List.TemplateAnatomical(TemplateAnatomicalList.Value),{CCEPRepository(p).Electrode.Uni.TemplateAnatomical});
%             if isempty(ValidSites)
%                 Chosen(p).Flag = false(length(CCEPRepository(p).Repos),1);
%             end
%         end
%     end
% end

%For the stim sites, check which of them are anatomical
TableCounter = 1;
StructFlag = 0;
for p = 1:length(CCEPRepository)
    %Anatomical template response labels check
    if sum([Chosen(p).Flag]) == length([Chosen(p).Flag])
        if ~isempty(CCEPRepository(p).Electrode)
            ValidSites = intersect(List.Anatomical(AnatomicalList.Value),{CCEPRepository(p).Electrode.Uni.Anatomical});
            if isempty(ValidSites)
               Chosen(p).Flag = false(length(CCEPRepository(p).Repos),1); 
            end 
        end
    end
    %Anatomical template check (response labels)
    if sum([Chosen(p).Flag]) == length([Chosen(p).Flag])
        if ~isempty(CCEPRepository(p).Electrode)
            ValidSites = intersect(List.TemplateAnatomical(TemplateAnatomicalList.Value),{CCEPRepository(p).Electrode.Uni.TemplateAnatomical});
            if isempty(ValidSites)
                Chosen(p).Flag = false(length(CCEPRepository(p).Repos),1);
            end
        end
    end 

    %Get the anatomical sites
    if sum([Chosen(p).Flag])>0
        if ~isempty(CCEPRepository(p).Repos)
            Inds = find(Chosen(p).Flag');
            for v = 1:length(Inds)
                %Look through the unipolar contacts from the stim site to
                %see if it is present in the selected names
                UniContacts = CCEPRepository(p).Electrode.Bi(find(strcmp({CCEPRepository(p).Electrode.Bi.Label},CCEPRepository(p).Repos(Inds(v)).Label))).UnipolarContacts;
                FoundInds1 = StrFindCell(List.StimAnatomical(StimAnatomicalList.Value),CCEPRepository(p).Electrode.Uni(UniContacts(1)).Anatomical);
                FoundInds2 = StrFindCell(List.StimAnatomical(StimAnatomicalList.Value),CCEPRepository(p).Electrode.Uni(UniContacts(2)).Anatomical);
                if ~isempty(FoundInds1) || ~isempty(FoundInds2)
                    Chosen(p).Flag(Inds(v)) = true;
                else
                    Chosen(p).Flag(Inds(v)) = false;
                end
            end
        end
    end
    
    %Get the template anatomical sites
    if sum([Chosen(p).Flag])>0
        if ~isempty(CCEPRepository(p).Repos)
            Inds = find(Chosen(p).Flag');
            for v = 1:length(Inds)
                %Look through the unipolar contacts from the stim site to
                %see if it is present in the selected names
                UniContacts = CCEPRepository(p).Electrode.Bi(find(strcmp({CCEPRepository(p).Electrode.Bi.Label},CCEPRepository(p).Repos(Inds(v)).Label))).UnipolarContacts;
                FoundInds1 = StrFindCell(List.StimTemplateAnatomical(StimTemplateAnatomicalList.Value),CCEPRepository(p).Electrode.Uni(UniContacts(1)).TemplateAnatomical);
                FoundInds2 = StrFindCell(List.StimTemplateAnatomical(StimTemplateAnatomicalList.Value),CCEPRepository(p).Electrode.Uni(UniContacts(2)).TemplateAnatomical);
                if ~isempty(FoundInds1) || ~isempty(FoundInds2)
                    Chosen(p).Flag(Inds(v)) = true;
                else
                    Chosen(p).Flag(Inds(v)) = false;
                end
            end
        end
    end
    
    %Get the Labels for each site
    if sum([Chosen(p).Flag])>0
        if ~isempty(CCEPRepository(p).Repos)
            Inds = find(Chosen(p).Flag');
            for v = 1:length(Inds)
                FoundInds = StrFindCell(List.Label(StimLabelList.Value),{CCEPRepository(p).Repos(Inds(v)).Label});
                if sum(FoundInds) == 0
                    Chosen(p).Flag(Inds(v)) = false;
                else
                    Chosen(p).Flag(Inds(v)) = true;
                end
            end
        end
    end

    %Get the stim levels
    if sum([Chosen(p).Flag])>0
        if ~isempty(CCEPRepository(p).Repos)
            Inds = find(Chosen(p).Flag');
            for v = 1:length(Inds)
%                 FoundInds = find((List.Level(LevelList.Value(~isnan(List.Level)))) == CCEPRepository(p).Repos(Inds(v)).Frequency);
                 FoundInds = find((List.Level(LevelList.Value)) == CCEPRepository(p).Repos(Inds(v)).Level);
                if isempty(FoundInds)
                    Chosen(p).Flag(Inds(v)) = false;
                end
            end
        end
    end
    
    %Get the freq info
    if sum([Chosen(p).Flag])>0
        if ~isempty(CCEPRepository(p).Repos)
            Inds = find(Chosen(p).Flag');
            for v = 1:length(Inds)
                if isempty(CCEPRepository(p).Repos(Inds(v)).Frequency)
                    CCEPRepository(p).Repos(Inds(v)).Frequency = 0.5; %Change it to default to 0.5Hz stim if not found
                else
                FoundInds = find((List.Freq(FreqList.Value)) == CCEPRepository(p).Repos(Inds(v)).Frequency);
                end
                if isempty(FoundInds)
                    Chosen(p).Flag(Inds(v)) = false;
                end
            end
        end
    end
    
    %Allocate the data to a structure of the table
    if sum([Chosen(p).Flag])>0
        if ~isempty(CCEPRepository(p).Repos)
            Inds = find(Chosen(p).Flag');
            %Create a copy of the chosen repository indexes to be used in a
            %another function to show ERPs and such
            if StructFlag == 0 
                TempRepository = CCEPRepository(p).Repos(Inds);
                StructFlag = 1;
            else
                TempRepository(end+1:(end+length(Inds))) = CCEPRepository(p).Repos(Inds);
            end
            for v = 1:length(Inds)
                %Temp Electrode structure - for plottinf the coOrds in real
                %time
                TempElectrode(p).Patient = CCEPRepository(p).Repos(Inds(v)).Patient;
                TempElectrode(p).CoOrds(v,:) = CCEPRepository(p).Repos(Inds(v)).CoOrds;
                TempElectrode(p).MNICoOrds(v,:) = CCEPRepository(p).Repos(Inds(v)).MNICoOrds;           
                
                %Plug in the Table Data
                TableData{TableCounter,1} = CCEPRepository(p).Repos(Inds(v)).Patient;
                TableData{TableCounter,2} = CCEPRepository(p).Repos(Inds(v)).Label;
                TableData{TableCounter,3} = CCEPRepository(p).Repos(Inds(v)).Level;
                TableData{TableCounter,4} = CCEPRepository(p).Repos(Inds(v)).Frequency;
                TableData{TableCounter,5} = length(CCEPRepository(p).Repos(Inds(v)).PulseTimes);
                TableData{TableCounter,6} = CCEPRepository(p).Repos(Inds(v)).Anatomical;
                TableData{TableCounter,7} = CCEPRepository(p).Repos(Inds(v)).TemplateAnatomical;
                TableData{TableCounter,8} = num2str(CCEPRepository(p).Repos(Inds(v)).TissueProb);
                TableData{TableCounter,9} = num2str(CCEPRepository(p).Repos(Inds(v)).MNICoOrds);
                TableCounter = TableCounter + 1;
            end
        end
    end
end

%Get only the valid patients from the temp electrodes variables and then
%get only the unique stim sites
if exist('TempElectrode','var')
    Inds = arrayfun(@(x) ~isempty(x.Patient), TempElectrode);
    TempElectrode = TempElectrode(Inds);
    ReposInds = find(Inds);
    for r = 1:length(TempElectrode)
        TempElectrode(r).AllCoOrds = TempElectrode(r).CoOrds;
        TempCoOrds = unique(TempElectrode(r).CoOrds,'rows');
        TempElectrode(r).CoOrds = TempCoOrds;
        TempElectrode(r).AllMNICoOrds = TempElectrode(r).MNICoOrds;
        TempCoOrds = unique(TempElectrode(r).MNICoOrds,'rows');
        TempElectrode(r).MNICoOrds = TempCoOrds;
        TempElectrode(r).CoOrdSet = reshape([CCEPRepository(ReposInds(r)).Electrode.Uni.CoOrds]', [3, length(CCEPRepository(ReposInds(r)).Electrode.Uni)])';
        TempElectrode(r).MNICoOrdSet = reshape([CCEPRepository(ReposInds(r)).Electrode.Uni.MNICoOrds]', [3, length(CCEPRepository(ReposInds(r)).Electrode.Uni)])';
    end
    StimSelectFig.UserData.ElectrodeStruct = TempElectrode;
end

%Pop the number of individual patients the other into a text field
NumPatientsText.String = sprintf('Number of Individual Patients: %i', length(StimSelectFig.UserData.ElectrodeStruct));
NumPatientsText.ForegroundColor = 'red';

%Plot a legend for each with the number of unique stim sites and Trains
NumStimSiteText.String = sprintf('Number of Individual Stim Sites: %i', sum(arrayfun(@(x) size(x.CoOrds ,1), StimSelectFig.UserData.ElectrodeStruct)));
NumStimSiteText.ForegroundColor = 'red';


%Create the UITable 
TempTable = findobj('Tag','StimTable');
if ~isempty(TempTable)
    delete(TempTable);
end

%Check how many data instances are required
CWidth = {120, 100, 70, 70, 70, 250, 250, 150,150};
if ~exist('TableData','var')
    TableData = {'No Data'};
    StimSelectFig.UserData.TempRepository = [];
    StimSelectFig.UserData.ElectrodeStruct = [];
else
    StimSelectFig.UserData.TempRepository = TempRepository;
    StimSelectFig.UserData.ElectrodeStruct = TempElectrode;
%     TableData = flipud(TableData);
end

%Make the temporary table
% TempTable = uitable('Units','Normalized','Position',[0.4 0.01 0.6 0.95],'Tag','StimTable', 'ColumnName',{'Patient','Label','Level','Frequency', 'Num Pulses','Anatomical','TemplateAnatomical'},'Data',TableData);
TempTable = uitable('Units','Normalized','Position',[0.4 0.01 0.6 0.95],'Tag','StimTable', 'ColumnName',{'Patient','Label','Level','Frequency', 'Num Pulses','Anatomical','TemplateAnatomical','Tissue Prob','MNI CoOrds'},'ColumnWidth',CWidth,'Data',TableData,'FontSize',12);

% TempTable = uitable('Units','Normalized','Position',[0.4 0.01 0.6 0.95],'Tag','StimTable');
% TempTable.Data = TableData(1,:);
% 'Data',TableData






















% Chosen.Names = 


%Chosen Patients
% for f = 1:length()
% Check(f).Inds
%Chosen Stim Sites

%Chosen Stim Sites













% 
% 
% DataFig = findobj('Tag','DataFig');
% if isfield(DataFig.UserData{1}, {'Location', 'Anatomical'})
%     CCEPRepository = DataFig.UserData{1};
% end
% 
% TempHandle = findobj('Tag','NameMenu');
% Chosen.Name = {}; %Allocate a blank cell to the field in order to be added into or to
% if ~isempty(TempHandle.Value)
%     for p = 1:length(TempHandle.Value)
%         TempInd = TempHandle.Value(p);
%         TempCell{p} = TempHandle.String{TempInd}; %Allocate the values to the patient field
%     end
%     Chosen.Name = TempCell;
% else
%     TempCell = {};
%     Chosen.Name = TempCell;
% end
% clearvars TempHandle TempInd TempCell;
% 
% TempHandle = findobj('Tag','StimLocationMenu');
% Chosen.StimLocation = {};
% if ~isempty(TempHandle.Value)
%     for p = 1:length(TempHandle.Value)
%         TempInd = TempHandle.Value(p);
%         TempCell{p} = TempHandle.String{TempInd};
%     end
%     Chosen.StimLocation = TempCell;
% else
%     TempCell = {};
%     Chosen.StimLocation = TempCell;    
% end
% clearvars TempHandle TempInd TempCell;
% 
% TempHandle = findobj('Tag','StimAnatomicalMenu');
% Chosen.StimAnatomical = {};
% if ~isempty(TempHandle.Value)
%     for p = 1:length(TempHandle.Value)
%         TempInd = TempHandle.Value(p);
%         TempCell{p} = TempHandle.String{TempInd};
%     end
%     Chosen.StimAnatomical = TempCell;
%     else
%     TempCell = {};
%     Chosen.StimAnatomical = TempCell;
% end
% clearvars TempHandle TempInd TempCell;
% 
% TempHandle = findobj('Tag','StimTemplateAnatomicalMenu');
% Chosen.StimTemplateAnatomicalMenu = {};
% if ~isempty(TempHandle.Value)
%     for p = 1:length(TempHandle.Value)
%         TempInd = TempHandle.Value(p);
%         TempCell{p} = TempHandle.String{TempInd};
%     end
%     Chosen.StimTemplateAnatomical = TempCell;
%     else
%     TempCell = {};
%     Chosen.StimTemplateAnatomical = TempCell;
% end
% clearvars TempHandle TempInd TempCell;
% 
% TempHandle = findobj('Tag','StimLevelMenu');
% Chosen.StimLevel = [];
% if ~isempty(TempHandle.Value)
%     for p = 1:length(TempHandle.Value)
%         TempInd = TempHandle.Value(p);
%         TempCell(p) = str2num(TempHandle.String{TempInd});
%     end
%     Chosen.StimLevel = TempCell;
%     else
%     TempCell = [];
%     Chosen.StimLevel = TempCell;
% end
% clearvars TempHandle TempInd TempCell;
% 
% TempHandle = findobj('Tag','StimFrequencyMenu');
% Chosen.StimFreq = [];
% if ~isempty(TempHandle.Value)
%     for p = 1:length(TempHandle.Value)
%         TempInd = TempHandle.Value(p);
%         TempCell(p) = str2num(TempHandle.String{TempInd});
%     end
%     Chosen.StimFreq = TempCell;
%     else
%     TempCell = [];
%     Chosen.StimFreq = TempCell;
% end
% clearvars TempHandle TempInd TempCell;
% 
% 
% TempHandle = findobj('Tag','ResponseTemplateAnatomicalMenu');
% Chosen.ResponseTemplateAnatomical = {};
% if ~isempty(TempHandle.Value)
%     for p = 1:length(TempHandle.Value)
%         TempInd = TempHandle.Value(p);
%         TempCell{p} = TempHandle.String{TempInd};
%     end
%     Chosen.ResponseTemplateAnatomical = TempCell;
%     else
%     TempCell = {};
%     Chosen.ResponseTemplateAnatomical = TempCell;
% end
% clearvars TempHandle TempInd TempCell;
% 
% TempHandle = findobj('Tag','ResponseAnatomicalMenu');
% Chosen.ResponseAnatomical = {};
% if ~isempty(TempHandle.Value)
%     for p = 1:length(TempHandle.Value)
%         TempInd = TempHandle.Value(p);
%         TempCell{p} = TempHandle.String{TempInd};
%     end
%     Chosen.ResponseAnatomical = TempCell;
%     else
%     TempCell = {};
%     Chosen.ResponseAnatomical = TempCell;
% end
% clearvars TempHandle TempInd TempCell;
% 
% 
% %Initialise the String concatenation
% if exist('CCEPRepository','var')
%    ConcatStr = sprintf('CCEPStimCriteriaFinder(''Repos'',CCEPRepository,'); %Pass the structure if loaded
% else
% ConcatStr = sprintf('CCEPStimCriteriaFinder(''Repos'',''Pretend'','); %Get the pretend repository if not
% end
% 
% if ~isempty(Chosen.Name)%Patient (Name)
% ConcatStr = sprintf('%s ''Name'', Chosen.Name,',ConcatStr);
% end
% if ~isempty(Chosen.StimLocation)%StimLocation
% ConcatStr = sprintf('%s ''StimLabel'', Chosen.StimLocation,',ConcatStr);
% end
% if ~isempty(Chosen.StimAnatomical)%StimAnatomical
% ConcatStr = sprintf('%s ''AnatomicalStim'', Chosen.StimAnatomical,',ConcatStr);
% end
% if ~isempty(Chosen.StimTemplateAnatomical)%StimTemplateAnatomical
% ConcatStr = sprintf('%s ''TemplateAnatomicalStim'', Chosen.StimTemplateAnatomical,',ConcatStr);
% end
% if ~isempty(Chosen.StimLevel)%StimLevels
% ConcatStr = sprintf('%s ''Stim Level'', Chosen.StimLevel,',ConcatStr);
% end
% if ~isempty(Chosen.StimFreq)%StimFrequency
% ConcatStr = sprintf('%s ''StimFreq'', Chosen.StimFreq,',ConcatStr);
% end
% if ~isempty(Chosen.ResponseAnatomical)%AnatomicalResponseSite
% ConcatStr = sprintf('%s ''Anatomical Response'', Chosen.ResponseAnatomical,',ConcatStr);
% end
% if ~isempty(Chosen.ResponseTemplateAnatomical)%ResponseTemplateAnatomical
% ConcatStr = sprintf('%s ''Anatomical Response'', Chosen.ResponseTemplateAnatomical,',ConcatStr);
% end
% 
% ConcatStr = sprintf('%s)',ConcatStr(1:(end-1))); %Append with a closed bracket
% 
% [FinalStimInds, ValidStim, ~] = eval(ConcatStr);
% 
% %Create the List of Stim Sites to show
% if ~isempty(FinalStimInds)
%     SelectionListString = {};
%     for r = 1:length(ValidStim)
%         SelectionListString{r} = sprintf('%s %s %2.0fmA %2.0fHz [%2.0f] in %s (%s)',ValidStim(r).Patient,ValidStim(r).Location,ValidStim(r).Level,ValidStim(r).Frequency, sum(ValidStim(r).ValidStims),ValidStim(r).Anatomical,ValidStim(r).TemplateAnatomical);
%     end
% else
%     SelectionListString = {''};
% end
% 
% %Allocate the tempdata to the selection list userdata and string fields
% TempHandle = findobj('Tag','SelectionListMenu');
% TempHandle.String = SelectionListString;
% TempHandle.Max = length(SelectionListString) + 1;
% TempHandle.Value = 1;
% TempHandle.UserData{1} = ValidStim; 
% TempHandle.UserData{2} = FinalStimInds;
% TempHandle.UserData{3} = ValidStim(TempHandle.Value);
% end