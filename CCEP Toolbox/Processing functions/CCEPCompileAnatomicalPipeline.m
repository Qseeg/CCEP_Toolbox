function CCEPCompileAnatomicalPipeline(varargin)
%CCEPCompileAnatomicalPipeline
%Use this function to get the results in conjunction with the CCEPReposGUI
%function. 


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


%Load in the Main file GUI
CCEPGUIMainFig = findobj('Tag','CCEPGUIMainFig');
CCEPGUIParams = CCEPGUIMainFig.UserData;

%If the main Figure is gone, renew it and then return here
if isempty(CCEPGUIMainFig)
    CCEPGUIInit;
    CCEPCompileAnatomicalSites;
end

CCEPReposFileName = CCEPGUIParams.CurrentRepository;
CCEPPath = CCEPGUIParams.CurrentPath;
try
    load(CCEPReposFileName);
catch
    CCEPRepository = [];
end

%Import the handles from the CCEPReposGUI figure to check the key
%selections
StimSelectFig = findobj('Tag','StimSelectFig');
StimAnatomicalList = findobj(StimSelectFig,'Tag','StimAnatomicalList');
StimTemplateAnatomicalList = findobj(StimSelectFig,'Tag','StimTemplateAnatomicalList');
NameList = findobj(StimSelectFig,'Tag','NameList');
LevelList = findobj(StimSelectFig,'Tag','LevelList');
FreqList = findobj(StimSelectFig,'Tag','FreqList');

%Get the relevant stimulation frequencies
SelectedFreq = [];
for a = 1:length(FreqList.Value)
    SelectedFreq(a) = str2num(FreqList.String{FreqList.Value(a)});
end
SelectedLevel = [];
for a = 1:length(LevelList.Value)
    SelectedLevel(a) = str2num(LevelList.String{LevelList.Value(a)});
end


%If both lists have all selected - perfrom the analysis for the Stim Sites
%based on the "Stim Anatomical Sites" labels, as they are probably more
%specific
AnatomicalFlag = 0;
TemplateAnatomicalFlag = 0;
if (length(StimAnatomicalList.Value) == length(StimAnatomicalList.String)) && (length(StimTemplateAnatomicalList.Value) == length(StimTemplateAnatomicalList.String))
    Terms = StimAnatomicalList.String(StimAnatomicalList.Value);
    AnatomicalFlag = 1;
    
elseif (length(StimAnatomicalList.Value) < length(StimAnatomicalList.String)) && (length(StimTemplateAnatomicalList.Value) == length(StimTemplateAnatomicalList.String))
    Terms = StimAnatomicalList.String(StimAnatomicalList.Value);
    AnatomicalFlag = 1;
    
elseif (length(StimAnatomicalList.Value) == length(StimAnatomicalList.String)) && (length(StimTemplateAnatomicalList.Value) < length(StimTemplateAnatomicalList.String))
    Terms = StimAnatomicalList.String(StimAnatomicalList.Value);
    TemplateAnatomicalFlag = 1;
end
for w = 1:length(Terms)
    StimAnatomical(w).Site = Terms{w};
    StimAnatomical(w).Files = {};
    StimAnatomical(w).Patterns = Terms;
    StimAnatomical(w).SelectedFreq = SelectedFreq;
    StimAnatomical(w).SelectedLevel = SelectedLevel;
end


%Look through the list of selected patients in order to build a list of
%relevant files to check for anatomical connections
CompiledResultFile ={};
CompiledDataFile = {};
CompiledElectrodeFile = {};
CompiledName = {};
CompiledTempFile = {};
for a = 1:length(CCEPRepository)
    
    %Check if the Patient assessed is selected
    if sum(strcmp(NameList.String(NameList.Value),CCEPRepository(a).Name ))>0
        
        %Get all of the data and results files associated with that patient
        TempDataFile = unique({CCEPRepository(a).Repos.DataFile});
        for b = 1:length(TempDataFile)
            
            Inds = find(strcmp({CCEPRepository(a).Repos.DataFile}, TempDataFile{b}));
            CompiledDataFile{end+1} = CCEPRepository(a).Repos(Inds(1)).DataFile;
            CompiledElectrodeFile{end+1} = CCEPRepository(a).Repos(Inds(1)).ElectrodeFile;
            CompiledResultFile{end+1} = CCEPRepository(a).Repos(Inds(1)).ResultFile;
            CompiledName{end+1} = CCEPRepository(a).Repos(Inds(1)).Name;
            [P,N,E] = fileparts(which(TempDataFile{b}));
            CompiledTempFile{end+1} = sprintf('%s%s%s AnatomicalFileResults.mat',P,filesep,N);
            
        end
    end
end


%Import the selected datafiles and look through the stimulation sites to
%find the connectivity of those relevant
for e = 1:length(CompiledDataFile)
    
    %Load in a single patient from the stimulation repository
    DataFile = CompiledDataFile{e};
    ResultFile = CompiledResultFile{e};
    [P,N,E] = fileparts(which(DataFile));
    TempFileName = CompiledTempFile{e};
    PatientName = CompiledName{e};
    ElectrodeFile = CompiledElectrodeFile{e};
    load(ResultFile);
    DataStruct = HemisphericReLabel(DataStruct);
    
    %Go StimAnoot pulse train by pulse train to find if the label stimulate
    %(Label Field) corresponds to the anatomical sites searched for:
    FoundPatterns = zeros(length(StimAnnot),length(Terms));
    for r = 1:length(StimAnnot)
        TempLabel = StimAnnot(r).Label;
        Ind = find(strcmp(TempLabel, {DataStruct.Bi.Label}));
        
        
        %If the Anatomical Labels are being used
        if AnatomicalFlag == 1
            %Create the temporary label search for all of the indexes
            TempAnatomical = DataStruct.Bi(Ind).Anatomical;
            for y = 1:length(Terms)
                %Cut the text at the first bracket to get the primary label
                Expr = '\(|\ (';
                Tokens = regexp(TempAnatomical, Expr,'split');
                TempAnatomical = strtrim(Tokens{1});
                FoundPatterns(r,y) = ~isempty(regexp((TempAnatomical),Terms{y}))&& (sum(ismember(StimAnnot(r).Frequency,SelectedFreq))) && (sum(ismember(StimAnnot(r).Level,SelectedLevel)));
            end
            
            %If the Template Anatomical Labels are being used
        else
            %Create the temporary label search for all of the indexes
            TempAnatomical = DataStruct.Bi(Ind).TemplateAnatomical;
            for y = 1:length(Terms)
                %Cut the text at the first bracket to get the primary label
                Expr = '\(|\ (';
                Tokens = regexp(TempAnatomical, Expr,'split');
                TempAnatomical = strtrim(Tokens{1});
                FoundPatterns(r,y) = ~isempty(regexp((TempAnatomical),Terms{y}))&& (sum(ismember(StimAnnot(r).Frequency,SelectedFreq))) && (sum(ismember(StimAnnot(r).Level,SelectedLevel)));
            end
        end
        
        
        %Record the Anatomical site stimulated and which terms were found in the
        %actual anatomical label
        StimAnnot(r).Anatomical = TempAnatomical;
        StimAnnot(r).FoundPatterns = FoundPatterns(r,:);
        StimAnnot(r).Patterns = Terms;
        StimAnnot(r).File = TempDataFile;
        StimAnnot(r).OriginalFile = DataFile;
        StimAnnot(r).ResultFile = ResultFile;
        StimAnnot(r).ElectrodeFile = ElectrodeFile;
        
    end
    
    %Find only the valid indexes for the patterns found and use them
    StimAnnot = StimAnnot(sum(FoundPatterns,2)>0);
    save(TempFileName,'StimAnnot','DataStruct','-v6');
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %                                                                %
    %           End of individual file manipulation                  %
    %                                                                %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %Find which anatomical structures have been stimulated in the file under
    %analysis and record them in a structure
    TermInds = find(sum(FoundPatterns,1)>0);
    
    %For each of the term indexes record the relevant files
    for w = 1:length(TermInds)
        
        if sum(strcmp(TempFileName, StimAnatomical(TermInds(w)).Files))<1
            StimAnatomical(TermInds(w)).Files{end+1} = TempFileName; %Record this to a file
        end
    end
end

fprintf('\nCompleted Indexing Allocation\n');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                %
%   Compile the StimAnnot structures by stimulation site         %
%                                                                %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%For each stimulation label under analysis
for r = 1:length(StimAnatomical)
    fprintf('Getting Results for %s\n', StimAnatomical(1).Patterns{r});
    NumFiles = length(StimAnatomical(r).Files);
    CompiledStimAnnot = [];
    
    %Set a template to look for which actual stim sites are correct for
    %each location
    AnatomicalIndex = false(1,length(StimAnatomical));
    AnatomicalIndex(r) = true;
    
    %For each of the Stim Sites load all of the relevant files
    for s = 1:NumFiles
        TempFile = StimAnatomical(r).Files{s};
        load(TempFile);
        DataStruct = HemisphericReLabel(DataStruct);
        %Put the Name and the patient Number in the stim site recording
        for t = 1:length(StimAnnot)
            StimAnnot(t).PatientName = DataStruct.Info(1).Name;
            StimAnnot(t).File = TempFile;
            StimAnnot(t).OriginalFile = DataStruct.Info(1).DataFile;
            StimAnnot(t).UniData = DataStruct.Uni;
            StimAnnot(t).BiData = DataStruct.Bi;
        end
        if s==1
            CompiledStimAnnot = StimAnnot;
        else
            CompiledStimAnnot(end+1:end+length(StimAnnot)) = StimAnnot;
        end
    end
    if ~isempty(CompiledStimAnnot)
        %Find which indexes in the stim site correspond exactly to the site
        %under analysis and reallocate it
        IndMat = reshape([CompiledStimAnnot.FoundPatterns]', [length(CompiledStimAnnot(1).FoundPatterns), length(CompiledStimAnnot)])';
        Temp = [];
        for g = 1:size(IndMat,1)
            Temp(g) = sum(IndMat(g,:) & AnatomicalIndex)>0;
        end
        Inds = find(Temp);
        CompiledStimAnnot = CompiledStimAnnot(Inds);
        
        %Compile all of the stimulations in that particular structure into an
        %organised
        CompiledStimStruct(r).AnatomicalSite = StimAnnot(1).Patterns{r};
        CompiledStimStruct(r).PatientName = unique({CompiledStimAnnot.PatientName});
        CompiledStimStruct(r).StimAnnot = CompiledStimAnnot;
        CompiledStimStruct(r).SelectedFreq = StimAnatomical(r).SelectedFreq;
        CompiledStimStruct(r).SelectedLevel = StimAnatomical(r).SelectedLevel;
        
    else
        
        %Compile all of the stimulations in that particular structure into an
        %organised
        CompiledStimStruct(r).AnatomicalSite = StimAnatomical(r).Site;
        CompiledStimStruct(r).PatientName = {};
        CompiledStimStruct(r).StimAnnot = [];
        CompiledStimStruct(r).SelectedFreq = [];
        CompiledStimStruct(r).SelectedLevel = [];
        
    end
    
    %Then determine if it is left or right as the stim site by testing the
    %sign of the XCoOrd
    IndMat = (arrayfun(@(x) x.CoOrds(1)<=0, CompiledStimAnnot));
    LeftInds = find(IndMat);
    RightInds = find(~IndMat);
    
    %Record which were the stim annotations for the left insula stims
    for u = 1:length(LeftInds)
        LeftStruct(r).AnatomicalSite = StimAnnot(1).Patterns{r};
        LeftStruct(r).PatientName = unique({CompiledStimAnnot(LeftInds).PatientName});
        LeftStruct(r).StimAnnot = CompiledStimAnnot(LeftInds);
        LeftStruct(r).SelectedFreq = CompiledStimStruct(r).SelectedFreq;
        LeftStruct(r).SelectedLevel = CompiledStimStruct(r).SelectedLevel;
    end
    %Give the anatomical structure in case there are no stims associated
    %with it, to act as a placeholder
    if isempty(LeftInds)
        LeftStruct(r).AnatomicalSite = StimAnnot(1).Patterns{r};
    end
    
    %Do the same for all of the insula stims on the Right hand side
    for u = 1:length(RightInds)
        RightStruct(r).AnatomicalSite = StimAnnot(1).Patterns{r};
        RightStruct(r).PatientName = unique({CompiledStimAnnot(RightInds).PatientName});
        RightStruct(r).StimAnnot = CompiledStimAnnot(RightInds);
        RightStruct(r).SelectedFreq = CompiledStimStruct(r).SelectedFreq;
        RightStruct(r).SelectedLevel = CompiledStimStruct(r).SelectedLevel;
    end
    if isempty(RightInds)
        RightStruct(r).AnatomicalSite = StimAnnot(1).Patterns{r};
    end
end
fprintf('\nSaving File\n');
save('CompiledTempRMSResults.mat','CompiledStimStruct','LeftStruct','RightStruct','-v6');
fprintf('\nCompleted StimAnnot Compile\n');

fprintf('\nDeleting Temp Files\n\nAbout 20%% done\n');
for a = 1:length(CompiledTempFile)
    delete(CompiledTempFile{a});
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%  Anatomical site ranking steps
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Create the label bank by looking through all of the labels in the unipolar
%structure of all electrodes
fprintf('Importing Compiled StimAnatomical Results\n');
ResultsFile = which('CompiledTempRMSResults.mat'); %Nominate the default results file
if ~exist('CompiledStimStruct','var')
    load(ResultsFile);
end

fprintf('Checking labels and organising data\n');
LabelBank = {};
for a = 1:length(CompiledStimStruct)
    for b = 1:length(CompiledStimStruct(a).StimAnnot)
        
        TempLabel = {CompiledStimStruct(a).StimAnnot(b).UniData.Anatomical};
        
        for c = 1:length(TempLabel)
            %Get rid of dupplicate hemipheric labels and double spaces
            %which could throw labelling off
            TempLabel{c} = strrep(TempLabel{c}, '   ',' ');
            TempLabel{c} = strrep(TempLabel{c}, '  ',' ');
            TempLabel{c} = strrep(TempLabel{c}, 'Left Left','Left');
            TempLabel{c} = strrep(TempLabel{c}, 'Left Left Left','Left');
            TempLabel{c} = strrep(TempLabel{c}, 'Right Right','Right');
            TempLabel{c} = strrep(TempLabel{c}, 'Right Right Right','Right');
            
            CompiledStimStruct(a).StimAnnot(b).UniData(c).Anatomical = TempLabel{c};
            CompiledStimStruct(a).StimAnnot(b).Uni(c).Anatomical = TempLabel{c};
        end
        
        for d = 1:length(CompiledStimStruct(a).StimAnnot(b).BiData)
            UnipolarContacts = CompiledStimStruct(a).StimAnnot(b).BiData(d).UnipolarContacts;
            
            if strcmp(CompiledStimStruct(a).StimAnnot(b).UniData(UnipolarContacts(1)).Anatomical, CompiledStimStruct(a).StimAnnot(b).UniData(UnipolarContacts(2)).Anatomical)
                TempStr = CompiledStimStruct(a).StimAnnot(b).UniData(UnipolarContacts(1)).Anatomical;
            else
                TempStr = sprintf('%s-%s',CompiledStimStruct(a).StimAnnot(b).UniData(UnipolarContacts(1)).Anatomical, CompiledStimStruct(a).StimAnnot(b).UniData(UnipolarContacts(2)).Anatomical);
            end
            
            CompiledStimStruct(a).StimAnnot(b).BiData(d).Anatomical = TempStr;
            CompiledStimStruct(a).StimAnnot(b).Bi(d).Anatomical = TempStr;
            
        end
        
        LabelBank(end+1:end+length(TempLabel)) = TempLabel;
    end
    
end
LabelBank = unique(LabelBank)';


%Duplicate the correct structures into the left and the right areas
clearvars LeftStruct RightStruct;
for a = 1:length(CompiledStimStruct)
    %Start a fresh temporary list for each anatomical site structure
    LeftStimAnnot =  [];
    LeftName = {};
    LeftNumber = [];
    
    RightStimAnnot =  [];
    RightName = {};
    RightNumber = [];
    
    %Find all of the left and right stimulation sites from the altered and
    %now correct CompiledStimStruct
    for b = 1:length(CompiledStimStruct(a).StimAnnot)
        
        %Check for the left and the right nature in each of the stimulation
        %sites in the fields in the StimAnnot structure being analysed
        if CompiledStimStruct(a).StimAnnot(b).CoOrds(1)<=0 && ~isempty(strfind(CompiledStimStruct(a).StimAnnot(b).Anatomical,'Left'))
            
            %If there is no allocated fields yet in each of the indexes
            %then grab them
            if length(LeftStimAnnot) == 0
                LeftStimAnnot =  CompiledStimStruct(a).StimAnnot(b);
                LeftName{1} = CompiledStimStruct(a).StimAnnot(b).PatientName;
            else
                LeftStimAnnot(end+1) =  CompiledStimStruct(a).StimAnnot(b);
                LeftName{end+1} = CompiledStimStruct(a).StimAnnot(b).PatientName;
            end
        else
            if length(RightStimAnnot) == 0
                RightStimAnnot =  CompiledStimStruct(a).StimAnnot(b);
                RightName{1} = CompiledStimStruct(a).StimAnnot(b).PatientName;
            else
                RightStimAnnot(end+1) =  CompiledStimStruct(a).StimAnnot(b);
                RightName{end+1} = CompiledStimStruct(a).StimAnnot(b).PatientName;
            end
        end
    end
    
    LeftStruct(a).AnatomicalSite = CompiledStimStruct(a).AnatomicalSite;
    LeftStruct(a).PatientName = unique(LeftName);
    LeftStruct(a).StimAnnot = LeftStimAnnot;
    
    RightStruct(a).AnatomicalSite = CompiledStimStruct(a).AnatomicalSite;
    RightStruct(a).PatientName = unique(RightName);
    RightStruct(a).StimAnnot = RightStimAnnot;
    
end


%Now that all of the labels and things are done for this system load in
%the data. Loop over the code for each of the Z scores and the bipolar and
%create the results for each of the stimulated structures locations
fprintf('Compiling all results\n');
for a = 1:length(CompiledStimStruct)
    %Pre-allocate each of the fields
    for b = 1:length(LabelBank)
        FinalUni(b).Label = LabelBank{b};
        FinalUni(b).PatientName = {};
        FinalUni(b).PulseTrain = [];
        FinalUni(b).Level = [];
        FinalUni(b).StimDist = [];
        FinalUni(b).ZScore = [];
        FinalUni(b).MedianRank = [];
        FinalUni(b).MeanRank = [];
        FinalUni(b).MedianQV = [];
        FinalUni(b).MeanQV = [];
        
        
        FinalBi(b).Label = LabelBank{b};
        FinalBi(b).PatientName = {};
        FinalBi(b).PulseTrain = [];
        FinalBi(b).Level = [];
        FinalBi(b).StimDist = [];
        FinalBi(b).ZScore = [];
        FinalBi(b).MedianRank = [];
        FinalBi(b).MeanRank = [];
        FinalBi(b).MedianQV = [];
        FinalBi(b).MeanQV = [];
        
    end
    
    %For each stim annotation in each of the structures, look through
    %through all of the results and append the summary results into the
    %correct anatomical location (response site)
    for b = 1:length(CompiledStimStruct(a).StimAnnot)
        %Perform the results appending and correct response site finding
        %for each of the unipolar contacts
        for c = 1:length(CompiledStimStruct(a).StimAnnot(b).Uni)
            
            TempInd = find(strcmp(CompiledStimStruct(a).StimAnnot(b).Uni(c).Anatomical,LabelBank));
            FinalUni(TempInd).PatientName{end+1} = CompiledStimStruct(a).StimAnnot(b).PatientName;
            FinalUni(TempInd).Level(end+1) = CompiledStimStruct(a).StimAnnot(b).Level;
            %             FinalUni(TempInd).PulseTrain(end+1) = []; %Might need to get this into the compiled StimStruct
            FinalUni(TempInd).StimDist(end+1) = CompiledStimStruct(a).StimAnnot(b).Uni(c).StimDist;
            FinalUni(TempInd).ZScore(end+1) = CompiledStimStruct(a).StimAnnot(b).Uni(c).ZScore;
            FinalUni(TempInd).MedianRank(end+1) = CompiledStimStruct(a).StimAnnot(b).Uni(c).RMSMedianRank;
            FinalUni(TempInd).MeanRank(end+1) = CompiledStimStruct(a).StimAnnot(b).Uni(c).RMSMeanRank;
            FinalUni(TempInd).MedianQV(end+1) = CompiledStimStruct(a).StimAnnot(b).Uni(c).RMSMedianQV;
            FinalUni(TempInd).MeanQV(end+1) = CompiledStimStruct(a).StimAnnot(b).Uni(c).RMSMeanQV;
        end
        
        %Now get the results for each of the bipolar structures - finding
        %the correct anatomical structures by using the
        for c = 1:length(CompiledStimStruct(a).StimAnnot(b).Bi)
            
            %Go into each of the unipolar labels to identify which
            %anatomical structures are in each of the bipolar channels
            for d = 1:length(CompiledStimStruct(a).StimAnnot(b).BiData(c).UnipolarContacts)
                
                TempInd = find(strcmp(CompiledStimStruct(a).StimAnnot(b).Uni(CompiledStimStruct(a).StimAnnot(b).BiData(c).UnipolarContacts(d)).Anatomical,LabelBank));
                FinalBi(TempInd).PatientName{end+1} = CompiledStimStruct(a).StimAnnot(b).PatientName;
                FinalBi(TempInd).Level(end+1) = CompiledStimStruct(a).StimAnnot(b).Level;
                %                 FinalBi(TempInd).PulseTrain(end+1) = []; %Might need to get this into the compiled StimStruct
                FinalBi(TempInd).StimDist(end+1) = CompiledStimStruct(a).StimAnnot(b).Bi(c).StimDist;
                FinalBi(TempInd).ZScore(end+1) = CompiledStimStruct(a).StimAnnot(b).Bi(c).ZScore;
                FinalBi(TempInd).MedianRank(end+1) = CompiledStimStruct(a).StimAnnot(b).Bi(c).RMSMedianRank;
                FinalBi(TempInd).MeanRank(end+1) = CompiledStimStruct(a).StimAnnot(b).Bi(c).RMSMeanRank;
                FinalBi(TempInd).MedianQV(end+1) = CompiledStimStruct(a).StimAnnot(b).Bi(c).RMSMedianQV;
                FinalBi(TempInd).MeanQV(end+1) = CompiledStimStruct(a).StimAnnot(b).Bi(c).RMSMeanQV;
            end
        end
    end
    
    %Average the results of the ranking categories for both the unipolar
    %and bipolar data categories
    for b = 1:length(FinalUni)
        
        %Average the unipolar results of the actual Zscore and other
        %ranking data
        if ~isempty(FinalUni(b).PatientName) && ~(sum(~isfinite(FinalUni(b).MeanRank)) == length(FinalUni(b).MeanRank))
            
            FinalUni(b).AverageZScore = mean(FinalUni(b).ZScore, 'omitnan');
            FinalUni(b).AverageMedianRank = mean(FinalUni(b).MedianRank, 'omitnan');
            FinalUni(b).AverageMeanRank = mean(FinalUni(b).MeanRank, 'omitnan');
            FinalUni(b).AverageMedianQV = mean(FinalUni(b).MedianQV, 'omitnan');
            FinalUni(b).AverageMeanQV = mean(FinalUni(b).MeanQV, 'omitnan');
            
        else
            
            FinalUni(b).AverageZScore = -inf;
            FinalUni(b).AverageMedianRank = -inf;
            FinalUni(b).AverageMeanRank = -inf;
            FinalUni(b).AverageMedianQV = -inf;
            FinalUni(b).AverageMeanQV = -inf;
        end
        
        %Now average the bipolar results of the actual Zscore and other
        %ranking data
        if ~isempty(FinalBi(b).PatientName) && ~(sum(~isfinite(FinalBi(b).MeanRank)) == length(FinalBi(b).MeanRank))
            
            FinalBi(b).AverageZScore = mean(FinalBi(b).ZScore, 'omitnan');
            FinalBi(b).AverageMedianRank = mean(FinalBi(b).MedianRank, 'omitnan');
            FinalBi(b).AverageMeanRank = mean(FinalBi(b).MeanRank, 'omitnan');
            FinalBi(b).AverageMedianQV = mean(FinalBi(b).MedianQV, 'omitnan');
            FinalBi(b).AverageMeanQV = mean(FinalBi(b).MeanQV, 'omitnan');
            
        else
            
            FinalBi(b).AverageZScore = -inf;
            FinalBi(b).AverageMedianRank = -inf;
            FinalBi(b).AverageMeanRank = -inf;
            FinalBi(b).AverageMedianQV = -inf;
            FinalBi(b).AverageMeanQV = -inf;
        end
    end
    
    CompiledStimStruct(a).UniResults = FinalUni;
    CompiledStimStruct(a).BiResults = FinalBi;
end

fprintf('Compiling Hemispheric results\n');
%Create the results for each of the stimulated structures locations
for a = 1:length(LeftStruct)
    %Pre-allocate each of the fields
    for b = 1:length(LabelBank)
        FinalUni(b).Label = LabelBank{b};
        FinalUni(b).PatientName = {};
        FinalUni(b).PulseTrain = [];
        FinalUni(b).Level = [];
        FinalUni(b).StimDist = [];
        FinalUni(b).ZScore = [];
        FinalUni(b).MedianRank = [];
        FinalUni(b).MeanRank = [];
        FinalUni(b).MedianQV = [];
        FinalUni(b).MeanQV = [];
        
        
        FinalBi(b).Label = LabelBank{b};
        FinalBi(b).PatientName = {};
        FinalBi(b).PulseTrain = [];
        FinalBi(b).Level = [];
        FinalBi(b).StimDist = [];
        FinalBi(b).ZScore = [];
        FinalBi(b).MedianRank = [];
        FinalBi(b).MeanRank = [];
        FinalBi(b).MedianQV = [];
        FinalBi(b).MeanQV = [];
        
    end
    
    %For each stim annotation in each of the structures, look through
    %through all of the results and append the summary results into the
    %correct anatomical location (response site)
    for b = 1:length(LeftStruct(a).StimAnnot)
        %Perform the results appending and correct response site finding
        %for each of the unipolar contacts
        for c = 1:length(LeftStruct(a).StimAnnot(b).Uni)
            
            TempInd = find(strcmp(LeftStruct(a).StimAnnot(b).Uni(c).Anatomical,LabelBank));
            FinalUni(TempInd).PatientName{end+1} = LeftStruct(a).StimAnnot(b).PatientName;
            FinalUni(TempInd).Level(end+1) = LeftStruct(a).StimAnnot(b).Level;
            %             FinalUni(TempInd).PulseTrain(end+1) = []; %Might need to get this into the compiled StimStruct
            FinalUni(TempInd).StimDist(end+1) = LeftStruct(a).StimAnnot(b).Uni(c).StimDist;
            FinalUni(TempInd).ZScore(end+1) = LeftStruct(a).StimAnnot(b).Uni(c).ZScore;
            FinalUni(TempInd).MedianRank(end+1) = LeftStruct(a).StimAnnot(b).Uni(c).RMSMedianRank;
            FinalUni(TempInd).MeanRank(end+1) = LeftStruct(a).StimAnnot(b).Uni(c).RMSMeanRank;
            FinalUni(TempInd).MedianQV(end+1) = LeftStruct(a).StimAnnot(b).Uni(c).RMSMedianQV;
            FinalUni(TempInd).MeanQV(end+1) = LeftStruct(a).StimAnnot(b).Uni(c).RMSMeanQV;
        end
        
        %Now get the results for each of the bipolar structures - finding
        %the correct anatomical structures by using the
        for c = 1:length(LeftStruct(a).StimAnnot(b).Bi)
            
            %Go into each of the unipolar labels to identify which
            %anatomical structures are in each of the bipolar channels
            for d = 1:length(LeftStruct(a).StimAnnot(b).BiData(c).UnipolarContacts)
                
                TempInd = find(strcmp(LeftStruct(a).StimAnnot(b).Uni(LeftStruct(a).StimAnnot(b).BiData(c).UnipolarContacts(d)).Anatomical,LabelBank));
                FinalBi(TempInd).PatientName{end+1} = LeftStruct(a).StimAnnot(b).PatientName;
                FinalBi(TempInd).Level(end+1) = LeftStruct(a).StimAnnot(b).Level;
                %                 FinalBi(TempInd).PulseTrain(end+1) = []; %Might need to get this into the compiled StimStruct
                FinalBi(TempInd).StimDist(end+1) = LeftStruct(a).StimAnnot(b).Bi(c).StimDist;
                FinalBi(TempInd).ZScore(end+1) = LeftStruct(a).StimAnnot(b).Bi(c).ZScore;
                FinalBi(TempInd).MedianRank(end+1) = LeftStruct(a).StimAnnot(b).Bi(c).RMSMedianRank;
                FinalBi(TempInd).MeanRank(end+1) = LeftStruct(a).StimAnnot(b).Bi(c).RMSMeanRank;
                FinalBi(TempInd).MedianQV(end+1) = LeftStruct(a).StimAnnot(b).Bi(c).RMSMedianQV;
                FinalBi(TempInd).MeanQV(end+1) = LeftStruct(a).StimAnnot(b).Bi(c).RMSMeanQV;
            end
        end
    end
    
    %Average the results of the ranking categories for both the unipolar
    %and bipolar data categories
    for b = 1:length(FinalUni)
        
        %Average the unipolar results of the actual Zscore and other
        %ranking data
        if ~isempty(FinalUni(b).PatientName) && ~(sum(~isfinite(FinalUni(b).MeanRank)) == length(FinalUni(b).MeanRank))
            
            FinalUni(b).AverageZScore = mean(FinalUni(b).ZScore, 'omitnan');
            FinalUni(b).AverageMedianRank = mean(FinalUni(b).MedianRank, 'omitnan');
            FinalUni(b).AverageMeanRank = mean(FinalUni(b).MeanRank, 'omitnan');
            FinalUni(b).AverageMedianQV = mean(FinalUni(b).MedianQV, 'omitnan');
            FinalUni(b).AverageMeanQV = mean(FinalUni(b).MeanQV, 'omitnan');
            
        else
            
            FinalUni(b).AverageZScore = -inf;
            FinalUni(b).AverageMedianRank = -inf;
            FinalUni(b).AverageMeanRank = -inf;
            FinalUni(b).AverageMedianQV = -inf;
            FinalUni(b).AverageMeanQV = -inf;
        end
        
        %Now average the bipolar results of the actual Zscore and other
        %ranking data
        if ~isempty(FinalBi(b).PatientName) && ~(sum(~isfinite(FinalBi(b).MeanRank)) == length(FinalBi(b).MeanRank))
            
            FinalBi(b).AverageZScore = mean(FinalBi(b).ZScore, 'omitnan');
            FinalBi(b).AverageMedianRank = mean(FinalBi(b).MedianRank, 'omitnan');
            FinalBi(b).AverageMeanRank = mean(FinalBi(b).MeanRank, 'omitnan');
            FinalBi(b).AverageMedianQV = mean(FinalBi(b).MedianQV, 'omitnan');
            FinalBi(b).AverageMeanQV = mean(FinalBi(b).MeanQV, 'omitnan');
            
        else
            
            FinalBi(b).AverageZScore = -inf;
            FinalBi(b).AverageMedianRank = -inf;
            FinalBi(b).AverageMeanRank = -inf;
            FinalBi(b).AverageMedianQV = -inf;
            FinalBi(b).AverageMeanQV = -inf;
        end
    end
    
    LeftStruct(a).UniResults = FinalUni;
    LeftStruct(a).BiResults = FinalBi;
end


%Create the results for each of the stimulated structures locations
for a = 1:length(RightStruct)
    %Pre-allocate each of the fields
    for b = 1:length(LabelBank)
        FinalUni(b).Label = LabelBank{b};
        FinalUni(b).PatientName = {};
        FinalUni(b).PulseTrain = [];
        FinalUni(b).Level = [];
        FinalUni(b).StimDist = [];
        FinalUni(b).ZScore = [];
        FinalUni(b).MedianRank = [];
        FinalUni(b).MeanRank = [];
        FinalUni(b).MedianQV = [];
        FinalUni(b).MeanQV = [];
        
        
        FinalBi(b).Label = LabelBank{b};
        FinalBi(b).PatientName = {};
        FinalBi(b).PulseTrain = [];
        FinalBi(b).Level = [];
        FinalBi(b).StimDist = [];
        FinalBi(b).ZScore = [];
        FinalBi(b).MedianRank = [];
        FinalBi(b).MeanRank = [];
        FinalBi(b).MedianQV = [];
        FinalBi(b).MeanQV = [];
        
    end
    
    %For each stim annotation in each of the structures, look through
    %through all of the results and append the summary results into the
    %correct anatomical location (response site)
    for b = 1:length(RightStruct(a).StimAnnot)
        %Perform the results appending and correct response site finding
        %for each of the unipolar contacts
        for c = 1:length(RightStruct(a).StimAnnot(b).Uni)
            
            TempInd = find(strcmp(RightStruct(a).StimAnnot(b).Uni(c).Anatomical,LabelBank));
            FinalUni(TempInd).PatientName{end+1} = RightStruct(a).StimAnnot(b).PatientName;
            FinalUni(TempInd).Level(end+1) = RightStruct(a).StimAnnot(b).Level;
            %             FinalUni(TempInd).PulseTrain(end+1) = []; %Might need to get this into the compiled StimStruct
            FinalUni(TempInd).StimDist(end+1) = RightStruct(a).StimAnnot(b).Uni(c).StimDist;
            FinalUni(TempInd).ZScore(end+1) = RightStruct(a).StimAnnot(b).Uni(c).ZScore;
            FinalUni(TempInd).MedianRank(end+1) = RightStruct(a).StimAnnot(b).Uni(c).RMSMedianRank;
            FinalUni(TempInd).MeanRank(end+1) = RightStruct(a).StimAnnot(b).Uni(c).RMSMeanRank;
            FinalUni(TempInd).MedianQV(end+1) = RightStruct(a).StimAnnot(b).Uni(c).RMSMedianQV;
            FinalUni(TempInd).MeanQV(end+1) = RightStruct(a).StimAnnot(b).Uni(c).RMSMeanQV;
        end
        
        %Now get the results for each of the bipolar structures - finding
        %the correct anatomical structures by using the
        for c = 1:length(RightStruct(a).StimAnnot(b).Bi)
            
            %Go into each of the unipolar labels to identify which
            %anatomical structures are in each of the bipolar channels
            for d = 1:length(RightStruct(a).StimAnnot(b).BiData(c).UnipolarContacts)
                
                TempInd = find(strcmp(RightStruct(a).StimAnnot(b).Uni(RightStruct(a).StimAnnot(b).BiData(c).UnipolarContacts(d)).Anatomical,LabelBank));
                FinalBi(TempInd).PatientName{end+1} = RightStruct(a).StimAnnot(b).PatientName;
                FinalBi(TempInd).Level(end+1) = RightStruct(a).StimAnnot(b).Level;
                %                 FinalBi(TempInd).PulseTrain(end+1) = []; %Might need to get this into the compiled StimStruct
                FinalBi(TempInd).StimDist(end+1) = RightStruct(a).StimAnnot(b).Bi(c).StimDist;
                FinalBi(TempInd).ZScore(end+1) = RightStruct(a).StimAnnot(b).Bi(c).ZScore;
                FinalBi(TempInd).MedianRank(end+1) = RightStruct(a).StimAnnot(b).Bi(c).RMSMedianRank;
                FinalBi(TempInd).MeanRank(end+1) = RightStruct(a).StimAnnot(b).Bi(c).RMSMeanRank;
                FinalBi(TempInd).MedianQV(end+1) = RightStruct(a).StimAnnot(b).Bi(c).RMSMedianQV;
                FinalBi(TempInd).MeanQV(end+1) = RightStruct(a).StimAnnot(b).Bi(c).RMSMeanQV;
            end
        end
    end
    
    %Average the results of the ranking categories for both the unipolar
    %and bipolar data categories
    for b = 1:length(FinalUni)
        
        %Average the unipolar results of the actual Zscore and other
        %ranking data
        if ~isempty(FinalUni(b).PatientName) && ~(sum(~isfinite(FinalUni(b).MeanRank)) == length(FinalUni(b).MeanRank))
            
            FinalUni(b).AverageZScore = mean(FinalUni(b).ZScore, 'omitnan');
            FinalUni(b).AverageMedianRank = mean(FinalUni(b).MedianRank, 'omitnan');
            FinalUni(b).AverageMeanRank = mean(FinalUni(b).MeanRank, 'omitnan');
            FinalUni(b).AverageMedianQV = mean(FinalUni(b).MedianQV, 'omitnan');
            FinalUni(b).AverageMeanQV = mean(FinalUni(b).MeanQV, 'omitnan');
            
        else
            
            FinalUni(b).AverageZScore = -inf;
            FinalUni(b).AverageMedianRank = -inf;
            FinalUni(b).AverageMeanRank = -inf;
            FinalUni(b).AverageMedianQV = -inf;
            FinalUni(b).AverageMeanQV = -inf;
        end
        
        %Now average the bipolar results of the actual Zscore and other
        %ranking data
        if ~isempty(FinalBi(b).PatientName) && ~(sum(~isfinite(FinalBi(b).MeanRank)) == length(FinalBi(b).MeanRank))
            
            FinalBi(b).AverageZScore = mean(FinalBi(b).ZScore, 'omitnan');
            FinalBi(b).AverageMedianRank = mean(FinalBi(b).MedianRank, 'omitnan');
            FinalBi(b).AverageMeanRank = mean(FinalBi(b).MeanRank, 'omitnan');
            FinalBi(b).AverageMedianQV = mean(FinalBi(b).MedianQV, 'omitnan');
            FinalBi(b).AverageMeanQV = mean(FinalBi(b).MeanQV, 'omitnan');
            
        else
            
            FinalBi(b).AverageZScore = -inf;
            FinalBi(b).AverageMedianRank = -inf;
            FinalBi(b).AverageMeanRank = -inf;
            FinalBi(b).AverageMedianQV = -inf;
            FinalBi(b).AverageMeanQV = -inf;
        end
    end
    
    RightStruct(a).UniResults = FinalUni;
    RightStruct(a).BiResults = FinalBi;
end

%Save the results file to the same location as the previously loaded
%results
fprintf('Saving ranked results\n');
save(ResultsFile,'CompiledStimStruct','RightStruct','LeftStruct','-v6');
fprintf('Completed ranked results save\n');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%    Reciprocal connectivty ranking steps
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Load in the Main file GUI
CCEPGUIMainFig = findobj('Tag','CCEPGUIMainFig');
CCEPGUIParams = CCEPGUIMainFig.UserData;
CCEPReposFileName = CCEPGUIParams.CurrentRepository;
CCEPPath = CCEPGUIParams.CurrentPath;
try
    load(CCEPReposFileName);
catch
    CCEPRepository = [];
end

%Import the previously allocated results for the non-reciprocal areas- so
%that  you can get the exact same structure of results. Then blank out the
%results and get the reciprocal results
ResultsFile = which('CompiledTempRMSResults.mat'); %Nominate the default results file
load(ResultsFile);
LabelBank = {CompiledStimStruct(1).UniResults.Label};
fprintf('\nBeginning reciprocal results calculation\n\nAbout 50%% done\n')

%Get the valid label indexes
LeftStr = {};
RightStr = {};
[~, Mask1]  = StrFindCell({CompiledStimStruct.AnatomicalSite}, 'Left');
[~, Mask2]  = StrFindCell({CompiledStimStruct.AnatomicalSite}, 'Right');
[~, WMMask]  = StrFindCell({CompiledStimStruct.AnatomicalSite}, 'WM');

%Make masks to get the labels that are left and right, then compile them
Temp = Mask1 & ~WMMask;
LeftStr = {CompiledStimStruct(Temp).AnatomicalSite};
Temp = Mask2 & ~WMMask;
RightStr = {CompiledStimStruct(Temp).AnatomicalSite};
CompiledStr = LeftStr;
CompiledStr(end+1:end+length(RightStr)) = RightStr;


%Blank out all of the results of the previously allocated structure so that
%you can get the correct format of the resicprocal results (same as the
%outgoing results)
TempStruct = CompiledStimStruct(1).UniResults;
for a = 1:length(LabelBank)
    TempStruct(a).PatientName = {};
    TempStruct(a).PulseTrain = [];
    TempStruct(a).Level = [];
    TempStruct(a).StimDist = [];
    TempStruct(a).ZScore= [];
    TempStruct(a).MedianRank = [];
    TempStruct(a).MeanRank = [];
    TempStruct(a).MedianQV = [];
    TempStruct(a).MeanQV = [];
    TempStruct(a).AverageZScore = [];
    TempStruct(a).AverageMedianRank = [];
    TempStruct(a).AverageMeanRank = [];
    TempStruct(a).AverageMedianQV = [];
    TempStruct(a).AverageMeanQV = [];
    
end

%Allocate both the unipolar and bipolar structures - use a cell of each
for z = 1:length(CompiledStr)
    ReciprocalResults(z).Label = CompiledStr{z};
    ReciprocalResults(z).FinalUni = TempStruct;
    ReciprocalResults(z).FinalBi = TempStruct;
end

% clearvars CompiledStimStruct;
fprintf('Imported and created blank structure\n');


%Look up all of the files in the directory and pan through them
%Compile all of the individual results files for the CCEP respository
CompiledResultFile = {};
TempLoadFile = {};
for a = 1:length(CompiledStimStruct)
    if ~isempty(CompiledStimStruct(a).StimAnnot)
        TempFile = unique({CompiledStimStruct(a).StimAnnot.ResultFile});
        for b = 1:length(TempFile)
            CompiledResultFile{end+1} = TempFile{b};
        end
        %         if ~isempty(TempFile)
        %         CompiledResultFile(end:end+length(TempFile)) = TempFile;
        %         end
    end
end
CompiledResultFile = unique(CompiledResultFile);
for a = 1:length(CompiledResultFile)
    TempLoadFile{a} = which(CompiledResultFile{a});
end

for e = 1:length(TempLoadFile)
    
    %Load in the DataStruct and StimAnnot file from each of the RMS results
    %files from the entire dataset
    clearvars DataStruct StimAnnot;
    load(TempLoadFile{e});
    DataStruct = HemisphericReLabel(DataStruct);
    fprintf('Imported %s\n',CompiledResultFile{e}); %indicate that a file has been completed
    
    %Gather the StimAnnot structure and start importing the files to creat the
    %reciprocal results
    for a = 1:length(StimAnnot)
        
        %Check if the stimulation parameters are valid (frequency is selected, and the level is valid, and that there are enough pulses)
        if sum(ismember(StimAnnot(a).Frequency,unique([CompiledStimStruct.SelectedFreq]))>0) && (length(StimAnnot(a).PulseTimes)>CCEPGUIParams.MinPulses) && sum(ismember(StimAnnot(a).Level,unique([CompiledStimStruct.SelectedLevel]))>0)
            
            %If the pulse train is valid, fin what the name of that stimulation
            %site was (both labels in the anatomical demarcation)
            TempStr = StimAnnot(a).Anatomical;
            TempLabel = StimAnnot(a).Label;
            BipoInd = find(strcmp({DataStruct.Bi.Label}, StimAnnot(a).Label));
            UnipolarInds = DataStruct.Bi(BipoInd).UnipolarContacts;
            %If the stimulation was perfromed in the same structure, then
            %only do the first label so as not to inflate the results
            if strcmp(DataStruct.Uni(UnipolarInds(1)).Anatomical ,DataStruct.Uni(UnipolarInds(2)).Anatomical)
                UnipolarInds = UnipolarInds(1);
            end
            
            %For each of the unipolar labels (even if it is white matter)
            for b = 1:length(UnipolarInds)
                
                
                %Find the label in the overall final structure that this stim site corresponds to
                TargetInd = find(strcmp(LabelBank, DataStruct.Uni(UnipolarInds(b)).Anatomical));
                
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %%%%%
                %%%%%           Perform the results tabulation for the
                %%%%%           UNIPOLAR cases
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
                %Get the label that corresponds to the anatomical response site
                for z = 1:length(CompiledStr)
                    SourceInd = find(strcmp({DataStruct.Uni.Anatomical}, CompiledStr{z}));
                    
                    %If any matches are found - allocate them to the structure
                    if ~isempty(SourceInd)
                        for y = 1:length(SourceInd)
                            
                            ReciprocalResults(z).FinalUni(TargetInd).PatientName{end+1} = DataStruct.Info.Name;
                            %                       ReciprocalResults(z).FinalUni(TargetInd).PulseTrain(end+1) = [];
                            ReciprocalResults(z).FinalUni(TargetInd).Level(end+1) = StimAnnot(a).Level;
                            ReciprocalResults(z).FinalUni(TargetInd).StimDist(end+1) = StimAnnot(a).Uni(SourceInd(y)).StimDist;
                            ReciprocalResults(z).FinalUni(TargetInd).ZScore(end+1) = StimAnnot(a).Uni(SourceInd(y)).ZScore;
                            ReciprocalResults(z).FinalUni(TargetInd).MedianRank(end+1) = StimAnnot(a).Uni(SourceInd(y)).RMSMedianRank;
                            ReciprocalResults(z).FinalUni(TargetInd).MeanRank(end+1) = StimAnnot(a).Uni(SourceInd(y)).RMSMeanRank;
                            ReciprocalResults(z).FinalUni(TargetInd).MedianQV(end+1) = StimAnnot(a).Uni(SourceInd(y)).RMSMedianQV;
                            ReciprocalResults(z).FinalUni(TargetInd).MeanQV(end+1) = StimAnnot(a).Uni(SourceInd(y)).RMSMeanQV;
                            
                        end
                    end
                end
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %%%%%
                %%%%%           Perform the results tabulation for the
                %%%%%           BIPOLAR cases
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                for z = 1:length(CompiledStr)
                    
                    %Create a quick routine to check through to see if the
                    %CompiledStr labels are in any of the contact in the
                    SourceInd = zeros(1,length(DataStruct.Bi));
                    for h = 1:length(DataStruct.Bi)
                        if ~isempty(strfind(DataStruct.Bi(h).Anatomical, CompiledStr{z}))
                            SourceInd(h) = 1;
                        end
                    end
                    SourceInd = find(SourceInd);
                    
                    %If any matches are found - allocate them to the structure
                    if ~isempty(SourceInd)
                        for y = 1:length(SourceInd)
                            
                            ReciprocalResults(z).FinalBi(TargetInd).PatientName{end+1} = DataStruct.Info.Name;
                            %                       ReciprocalResults(z).FinalUni(TargetInd).PulseTrain(end+1) = [];
                            ReciprocalResults(z).FinalBi(TargetInd).Level(end+1) = StimAnnot(a).Level;
                            ReciprocalResults(z).FinalBi(TargetInd).StimDist(end+1) = StimAnnot(a).Bi(SourceInd(y)).StimDist;
                            ReciprocalResults(z).FinalBi(TargetInd).ZScore(end+1) = StimAnnot(a).Bi(SourceInd(y)).ZScore;
                            ReciprocalResults(z).FinalBi(TargetInd).MedianRank(end+1) = StimAnnot(a).Bi(SourceInd(y)).RMSMedianRank;
                            ReciprocalResults(z).FinalBi(TargetInd).MeanRank(end+1) = StimAnnot(a).Bi(SourceInd(y)).RMSMeanRank;
                            ReciprocalResults(z).FinalBi(TargetInd).MedianQV(end+1) = StimAnnot(a).Bi(SourceInd(y)).RMSMedianQV;
                            ReciprocalResults(z).FinalBi(TargetInd).MeanQV(end+1) = StimAnnot(a).Bi(SourceInd(y)).RMSMeanQV;
                            
                        end
                    end
                end
            end
        end
    end
    fprintf('Finished the allocation for %s\n',CompiledResultFile{e}); %indicate that a file has been completed
end

fprintf('Reorganising the results ranking\n');
%Average the results of the ranking categories for both the unipolar
%and bipolar data categories
for a = 1:length(ReciprocalResults)
    for b = 1:length(ReciprocalResults(1).FinalUni)
        
        %Average the unipolar results of the actual Zscore and other
        %ranking data
        if ~isempty(ReciprocalResults(a).FinalUni(b).PatientName) && ~(sum(~isfinite(ReciprocalResults(a).FinalUni(b).MeanRank)) == length(ReciprocalResults(a).FinalUni(b).MeanRank))
            
            ReciprocalResults(a).FinalUni(b).AverageZScore = mean(ReciprocalResults(a).FinalUni(b).ZScore, 'omitnan');
            ReciprocalResults(a).FinalUni(b).AverageMedianRank = mean(ReciprocalResults(a).FinalUni(b).MedianRank, 'omitnan');
            ReciprocalResults(a).FinalUni(b).AverageMeanRank = mean(ReciprocalResults(a).FinalUni(b).MeanRank, 'omitnan');
            ReciprocalResults(a).FinalUni(b).AverageMedianQV = mean(ReciprocalResults(a).FinalUni(b).MedianQV, 'omitnan');
            ReciprocalResults(a).FinalUni(b).AverageMeanQV = mean(ReciprocalResults(a).FinalUni(b).MeanQV, 'omitnan');
            
        else
            
            ReciprocalResults(a).FinalUni(b).AverageZScore = -inf;
            ReciprocalResults(a).FinalUni(b).AverageMedianRank = -inf;
            ReciprocalResults(a).FinalUni(b).AverageMeanRank = -inf;
            ReciprocalResults(a).FinalUni(b).AverageMedianQV = -inf;
            ReciprocalResults(a).FinalUni(b).AverageMeanQV = -inf;
        end
        
        %Now average the bipolar results of the actual Zscore and other
        %ranking data
        if ~isempty(ReciprocalResults(a).FinalBi(b).PatientName) && ~(sum(~isfinite(ReciprocalResults(a).FinalBi(b).MeanRank)) == length(ReciprocalResults(a).FinalBi(b).MeanRank))
            
            ReciprocalResults(a).FinalBi(b).AverageZScore = mean(ReciprocalResults(a).FinalBi(b).ZScore, 'omitnan');
            ReciprocalResults(a).FinalBi(b).AverageMedianRank = mean(ReciprocalResults(a).FinalBi(b).MedianRank, 'omitnan');
            ReciprocalResults(a).FinalBi(b).AverageMeanRank = mean(ReciprocalResults(a).FinalBi(b).MeanRank, 'omitnan');
            ReciprocalResults(a).FinalBi(b).AverageMedianQV = mean(ReciprocalResults(a).FinalBi(b).MedianQV, 'omitnan');
            ReciprocalResults(a).FinalBi(b).AverageMeanQV = mean(ReciprocalResults(a).FinalBi(b).MeanQV, 'omitnan');
            
        else
            
            ReciprocalResults(a).FinalBi(b).AverageZScore = -inf;
            ReciprocalResults(a).FinalBi(b).AverageMedianRank = -inf;
            ReciprocalResults(a).FinalBi(b).AverageMeanRank = -inf;
            ReciprocalResults(a).FinalBi(b).AverageMedianQV = -inf;
            ReciprocalResults(a).FinalBi(b).AverageMeanQV = -inf;
        end
    end
end

%Add the reciprocal results to compiled and hemispheric structures
for a = 1:length(CompiledStimStruct)
    CompiledStimStruct(a).ReciprocalUniResults = ReciprocalResults(a).FinalUni;
    CompiledStimStruct(a).ReciprocalBiResults = ReciprocalResults(a).FinalBi;
    LeftStruct(a).ReciprocalUniResults = ReciprocalResults(a).FinalUni;
    LeftStruct(a).ReciprocalBiResults = ReciprocalResults(a).FinalBi;
    RightStruct(a).ReciprocalUniResults = ReciprocalResults(a).FinalUni;
    RightStruct(a).ReciprocalBiResults = ReciprocalResults(a).FinalBi;
end

%Save the reciprocal results
fprintf('Saving the reciprocal ranked results\n');
fprintf('Saving ranked results\n');
save(ResultsFile,'CompiledStimStruct','RightStruct','LeftStruct','-v6');
fprintf('Completed reciprocal results save\n');



%Then exclude labels which are not valid and sort the results
%For the reciprocal results
ExcludeLabel = CCEPGUIParams.AnatomicalExclude;

%For the unipolar data, bump the labels which are bad sites down to the
%bottom rankings, also bump the stimsite down to the bottom ranking (since
%it will probably show very high connectivity
for a = 1:length(LeftStruct)
    StimLabel = RightStruct(a).AnatomicalSite;
    TempLabel = ExcludeLabel; TempLabel{end+1} = StimLabel;
    for b = 1:length(LeftStruct(a).BiResults)
        
        if ~isempty(StrFindCellPattern(LeftStruct(a).BiResults(b).Label, TempLabel,1))
            LeftStruct(a).BiResults(b).AverageZScore = -inf;
            LeftStruct(a).BiResults(b).AverageMedianRank = -inf;
            LeftStruct(a).BiResults(b).AverageMeanRank = -inf;
            LeftStruct(a).BiResults(b).AverageMedianQV = -inf;
            LeftStruct(a).BiResults(b).AverageMeanQV = -inf;
            
        end
    end
end
for a = 1:length(RightStruct)
    StimLabel = RightStruct(a).AnatomicalSite;
    TempLabel = ExcludeLabel; TempLabel{end+1} = StimLabel;
    for b = 1:length(RightStruct(a).BiResults)
        
        if ~isempty(StrFindCellPattern(RightStruct(a).BiResults(b).Label, TempLabel,1))
            
            RightStruct(a).BiResults(b).AverageZScore = -inf;
            RightStruct(a).BiResults(b).AverageMedianRank = -inf;
            RightStruct(a).BiResults(b).AverageMeanRank = -inf;
            RightStruct(a).BiResults(b).AverageMedianQV = -inf;
            RightStruct(a).BiResults(b).AverageMeanQV = -inf;
            
        end
    end
end


%For the reciprocal results
for a = 1:length(LeftStruct)
    StimLabel = RightStruct(a).AnatomicalSite;
    TempLabel = ExcludeLabel; TempLabel{end+1} = StimLabel;
    
    for b = 1:length(LeftStruct(a).ReciprocalBiResults)
        if ~isempty(StrFindCellPattern(LeftStruct(a).ReciprocalBiResults(b).Label, TempLabel,1))
            
            LeftStruct(a).ReciprocalBiResults(b).AverageZScore = -inf;
            LeftStruct(a).ReciprocalBiResults(b).AverageMedianRank = -inf;
            LeftStruct(a).ReciprocalBiResults(b).AverageMeanRank = -inf;
            LeftStruct(a).ReciprocalBiResults(b).AverageMedianQV = -inf;
            LeftStruct(a).ReciprocalBiResults(b).AverageMeanQV = -inf;
            
        end
    end
end

for a = 1:length(RightStruct)
    StimLabel = RightStruct(a).AnatomicalSite;
    TempLabel = ExcludeLabel; TempLabel{end+1} = StimLabel;
    
    for b = 1:length(RightStruct(a).ReciprocalBiResults)
        if ~isempty(StrFindCellPattern(LeftStruct(a).ReciprocalBiResults(b).Label, TempLabel,1))
            
            RightStruct(a).ReciprocalBiResults(b).AverageZScore = -inf;
            RightStruct(a).ReciprocalBiResults(b).AverageMedianRank = -inf;
            RightStruct(a).ReciprocalBiResults(b).AverageMeanRank = -inf;
            RightStruct(a).ReciprocalBiResults(b).AverageMedianQV = -inf;
            RightStruct(a).ReciprocalBiResults(b).AverageMeanQV = -inf;
            
        end
    end
end

%Sort the left structure
for a = 1:length(LeftStruct)
    [~,index] = sortrows([LeftStruct(a).ReciprocalUniResults.AverageMeanRank].'); LeftStruct(a).ReciprocalUniResults = LeftStruct(a).ReciprocalUniResults(index(end:-1:1)); clear index;
    [~,index] = sortrows([LeftStruct(a).ReciprocalBiResults.AverageMeanRank].'); LeftStruct(a).ReciprocalBiResults = LeftStruct(a).ReciprocalBiResults(index(end:-1:1)); clear index;
    [~,index] = sortrows([LeftStruct(a).UniResults.AverageMeanRank].'); LeftStruct(a).UniResults = LeftStruct(a).UniResults(index(end:-1:1)); clear index;
    [~,index] = sortrows([LeftStruct(a).BiResults.AverageMeanRank].'); LeftStruct(a).BiResults = LeftStruct(a).BiResults(index(end:-1:1)); clear index;
end

%Sort the right structure
for a = 1:length(RightStruct)
    [~,index] = sortrows([RightStruct(a).ReciprocalUniResults.AverageMeanRank].'); RightStruct(a).ReciprocalUniResults = RightStruct(a).ReciprocalUniResults(index(end:-1:1)); clear index;
    [~,index] = sortrows([RightStruct(a).ReciprocalBiResults.AverageMeanRank].'); RightStruct(a).ReciprocalBiResults = RightStruct(a).ReciprocalBiResults(index(end:-1:1)); clear index;
    [~,index] = sortrows([RightStruct(a).UniResults.AverageMeanRank].'); RightStruct(a).UniResults = RightStruct(a).UniResults(index(end:-1:1)); clear index;
    [~,index] = sortrows([RightStruct(a).BiResults.AverageMeanRank].'); RightStruct(a).BiResults = RightStruct(a).BiResults(index(end:-1:1)); clear index;
end

%Save the connectivity file for the last time
fprintf('Saving the sorted anatomical results\n');
save(ResultsFile,'RightStruct','LeftStruct','CompiledStimStruct','-v6')
fprintf('Completed final Save....\n\nabout 80%% done\n\nCreating ranking spreadsheets\n');


%Output the excel spreadsheets - first do the bipolar
InXLFile = 'Anatomical_Analysis_Afferent_Connectivity_Results(Bipolar_Ref).xlsx';
OutXLFile = 'Anatomical_Analysis_Efferent_Connectivity_Results(Bipolar_Ref).xlsx';

%***************************
%Do the projecting (efferent/outgoing) results
%***************************

LeftInds = find(~arrayfun(@(x) isempty(x.StimAnnot), LeftStruct));
LeftStimSite = {LeftStruct(LeftInds).AnatomicalSite};
for a = 1:length(LeftStimSite)
    Ind = LeftInds(a);
    
    %Set the headings for each of the columns
    xlwrite(OutXLFile,{'Anatomical Area','Average rank value (0-1)','Average QV (1-4)','Average Z score','Number of datapoints','Number of patients'},LeftStimSite{a},'A1:F1');
    
    StartRow = 2;
    CellRange = sprintf('A%i:A%i',StartRow,StartRow+(length(LeftStruct(Ind).BiResults)-1));
    
    %Write the sorted labels to the sheet
    xlwrite(OutXLFile,{LeftStruct(Ind).BiResults.Label}',LeftStimSite{a},CellRange);
    
    %Write the average rank/QV and Z scores and the number of results to the
    %site
    CellRange = sprintf('B%i:B%i',StartRow,StartRow+(length(LeftStruct(Ind).BiResults)-1));
    xlwrite(OutXLFile,[LeftStruct(Ind).BiResults.AverageMeanRank]',LeftStimSite{a},CellRange);
    CellRange = sprintf('C%i:C%i',StartRow,StartRow+(length(LeftStruct(Ind).BiResults)-1));
    xlwrite(OutXLFile,[LeftStruct(Ind).BiResults.AverageMeanQV]',LeftStimSite{a},CellRange);
    CellRange = sprintf('D%i:D%i',StartRow,StartRow+(length(LeftStruct(Ind).BiResults)-1));
    xlwrite(OutXLFile,[LeftStruct(Ind).BiResults.AverageZScore]',LeftStimSite{a},CellRange);
    CellRange = sprintf('E%i:E%i',StartRow,StartRow+(length(LeftStruct(Ind).BiResults)-1));
    xlwrite(OutXLFile,[arrayfun(@(x) length(x.Level), LeftStruct(Ind).BiResults)]' ,LeftStimSite{a},CellRange);
    CellRange = sprintf('F%i:F%i',StartRow,StartRow+(length(LeftStruct(Ind).BiResults)-1));
    xlwrite(OutXLFile,[arrayfun(@(x) length(unique(x.PatientName)), LeftStruct(Ind).BiResults)]' ,LeftStimSite{a},CellRange);
    
end


RightInds = find(~arrayfun(@(x) isempty(x.StimAnnot), RightStruct));
RightStimSite = {RightStruct(RightInds).AnatomicalSite};
for a = 1:length(RightStimSite)
    
    Ind = RightInds(a);
    
    %Set the headings for each of the columns
    xlwrite(OutXLFile,{'Anatomical Area','Average rank value (0-1)','Average QV (1-4)','Average Z score','Number of datapoints','Number of patients'},RightStimSite{a},'A1:F1');
    
    StartRow = 2;
    CellRange = sprintf('A%i:A%i',StartRow,StartRow+(length(RightStruct(Ind).BiResults)-1));
    
    %Write the sorted labels to the sheet
    xlwrite(OutXLFile,{RightStruct(Ind).BiResults.Label}',RightStimSite{a},CellRange);
    
    %Write the average rank/QV and Z scores and the number of results to the
    %site
    CellRange = sprintf('B%i:B%i',StartRow,StartRow+(length(RightStruct(Ind).BiResults)-1));
    xlwrite(OutXLFile,[RightStruct(Ind).BiResults.AverageMeanRank]',RightStimSite{a},CellRange);
    CellRange = sprintf('C%i:C%i',StartRow,StartRow+(length(RightStruct(Ind).BiResults)-1));
    xlwrite(OutXLFile,[RightStruct(Ind).BiResults.AverageMeanQV]',RightStimSite{a},CellRange);
    CellRange = sprintf('D%i:D%i',StartRow,StartRow+(length(RightStruct(Ind).BiResults)-1));
    xlwrite(OutXLFile,[RightStruct(Ind).BiResults.AverageZScore]',RightStimSite{a},CellRange);
    CellRange = sprintf('E%i:E%i',StartRow,StartRow+(length(RightStruct(Ind).BiResults)-1));
    xlwrite(OutXLFile,[arrayfun(@(x) length(x.Level), RightStruct(Ind).BiResults)]' ,RightStimSite{a},CellRange);
    CellRange = sprintf('F%i:F%i',StartRow,StartRow+(length(RightStruct(Ind).ReciprocalBiResults)-1));
    xlwrite(OutXLFile,[arrayfun(@(x) length(unique(x.PatientName)), RightStruct(Ind).BiResults)]' ,RightStimSite{a},CellRange);
    
end


%***************************
%Do the reciprocal (afferent/incoming) results
%***************************
LeftInds = find(~arrayfun(@(x) isempty(x.StimAnnot), LeftStruct));
LeftStimSite = {LeftStruct(LeftInds).AnatomicalSite};
for a = 1:length(LeftStimSite)
    
    Ind = LeftInds(a);
    
    %Set the headings for each of the columns
    xlwrite(InXLFile,{'Anatomical Area','Average rank value (0-1)','Average QV (1-4)','Average Z score','Number of datapoints','Number of patients'},LeftStimSite{a},'A1:F1');
    
    StartRow = 2;
    CellRange = sprintf('A%i:A%i',StartRow,StartRow+(length(LeftStruct(Ind).ReciprocalBiResults)-1));
    
    %Write the sorted labels to the sheet
    xlwrite(InXLFile,{LeftStruct(Ind).ReciprocalBiResults.Label}',LeftStimSite{a},CellRange);
    
    %Write the average rank/QV and Z scores and the number of results to the
    %site
    CellRange = sprintf('B%i:B%i',StartRow,StartRow+(length(LeftStruct(Ind).ReciprocalBiResults)-1));
    xlwrite(InXLFile,[LeftStruct(Ind).ReciprocalBiResults.AverageMeanRank]',LeftStimSite{a},CellRange);
    CellRange = sprintf('C%i:C%i',StartRow,StartRow+(length(LeftStruct(Ind).ReciprocalBiResults)-1));
    xlwrite(InXLFile,[LeftStruct(Ind).ReciprocalBiResults.AverageMeanQV]',LeftStimSite{a},CellRange);
    CellRange = sprintf('D%i:D%i',StartRow,StartRow+(length(LeftStruct(Ind).ReciprocalBiResults)-1));
    xlwrite(InXLFile,[LeftStruct(Ind).ReciprocalBiResults.AverageZScore]',LeftStimSite{a},CellRange);
    CellRange = sprintf('E%i:E%i',StartRow,StartRow+(length(LeftStruct(Ind).ReciprocalBiResults)-1));
    xlwrite(InXLFile,[arrayfun(@(x) length(x.Level), LeftStruct(Ind).ReciprocalBiResults)]' ,LeftStimSite{a},CellRange);
    CellRange = sprintf('F%i:F%i',StartRow,StartRow+(length(LeftStruct(Ind).ReciprocalBiResults)-1));
    xlwrite(InXLFile,[arrayfun(@(x) length(unique(x.PatientName)), LeftStruct(Ind).ReciprocalBiResults)]' ,LeftStimSite{a},CellRange);
    
end

RightInds = find(~arrayfun(@(x) isempty(x.StimAnnot), RightStruct));
RightStimSite = {RightStruct(RightInds).AnatomicalSite};
for a = 1:length(RightStimSite)
    
    Ind = RightInds(a);
    
    %Set the headings for each of the columns
    xlwrite(InXLFile,{'Anatomical Area','Average rank value (0-1)','Average QV (1-4)','Average Z score','Number of datapoints','Number of patients'},RightStimSite{a},'A1:F1');
    
    StartRow = 2;
    CellRange = sprintf('A%i:A%i',StartRow,StartRow+(length(RightStruct(Ind).ReciprocalBiResults)-1));
    
    %Write the sorted labels to the sheet
    xlwrite(InXLFile,{RightStruct(Ind).ReciprocalBiResults.Label}',RightStimSite{a},CellRange);
    
    %Write the average rank/QV and Z scores and the number of results to the
    %site
    CellRange = sprintf('B%i:B%i',StartRow,StartRow+(length(RightStruct(Ind).ReciprocalBiResults)-1));
    xlwrite(InXLFile,[RightStruct(Ind).ReciprocalBiResults.AverageMeanRank]',RightStimSite{a},CellRange);
    CellRange = sprintf('C%i:C%i',StartRow,StartRow+(length(RightStruct(Ind).ReciprocalBiResults)-1));
    xlwrite(InXLFile,[RightStruct(Ind).ReciprocalBiResults.AverageMeanQV]',RightStimSite{a},CellRange);
    CellRange = sprintf('D%i:D%i',StartRow,StartRow+(length(RightStruct(Ind).ReciprocalBiResults)-1));
    xlwrite(InXLFile,[RightStruct(Ind).ReciprocalBiResults.AverageZScore]',RightStimSite{a},CellRange);
    CellRange = sprintf('E%i:E%i',StartRow,StartRow+(length(RightStruct(Ind).ReciprocalBiResults)-1));
    xlwrite(InXLFile,[arrayfun(@(x) length(x.Level), RightStruct(Ind).ReciprocalBiResults)]' ,RightStimSite{a},CellRange);
    CellRange = sprintf('F%i:F%i',StartRow,StartRow+(length(RightStruct(Ind).ReciprocalBiResults)-1));
    xlwrite(InXLFile,[arrayfun(@(x) length(unique(x.PatientName)), RightStruct(Ind).ReciprocalBiResults)]' ,RightStimSite{a},CellRange);
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Then do the unipolar spreadsheets
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Output the excel spreadsheets - first do the bipolar
InXLFile = 'Anatomical_Analysis_Afferent_Connectivity_Results(Unipolar_Ref).xlsx';
OutXLFile = 'Anatomical_Analysis_Efferent_Connectivity_Results(Unipolar_Ref).xlsx';

%***************************
%Do the projecting (efferent/outgoing) results
%***************************

LeftInds = find(~arrayfun(@(x) isempty(x.StimAnnot), LeftStruct));
LeftStimSite = {LeftStruct(LeftInds).AnatomicalSite};
for a = 1:length(LeftStimSite)
    Ind = LeftInds(a);
    
    %Set the headings for each of the columns
    xlwrite(OutXLFile,{'Anatomical Area','Average rank value (0-1)','Average QV (1-4)','Average Z score','Number of datapoints','Number of patients'},LeftStimSite{a},'A1:F1');
    
    StartRow = 2;
    CellRange = sprintf('A%i:A%i',StartRow,StartRow+(length(LeftStruct(Ind).UniResults)-1));
    
    %Write the sorted labels to the sheet
    xlwrite(OutXLFile,{LeftStruct(Ind).UniResults.Label}',LeftStimSite{a},CellRange);
    
    %Write the average rank/QV and Z scores and the number of results to the
    %site
    CellRange = sprintf('B%i:B%i',StartRow,StartRow+(length(LeftStruct(Ind).UniResults)-1));
    xlwrite(OutXLFile,[LeftStruct(Ind).UniResults.AverageMeanRank]',LeftStimSite{a},CellRange);
    CellRange = sprintf('C%i:C%i',StartRow,StartRow+(length(LeftStruct(Ind).UniResults)-1));
    xlwrite(OutXLFile,[LeftStruct(Ind).UniResults.AverageMeanQV]',LeftStimSite{a},CellRange);
    CellRange = sprintf('D%i:D%i',StartRow,StartRow+(length(LeftStruct(Ind).UniResults)-1));
    xlwrite(OutXLFile,[LeftStruct(Ind).UniResults.AverageZScore]',LeftStimSite{a},CellRange);
    CellRange = sprintf('E%i:E%i',StartRow,StartRow+(length(LeftStruct(Ind).UniResults)-1));
    xlwrite(OutXLFile,[arrayfun(@(x) length(x.Level), LeftStruct(Ind).UniResults)]' ,LeftStimSite{a},CellRange);
    CellRange = sprintf('F%i:F%i',StartRow,StartRow+(length(LeftStruct(Ind).UniResults)-1));
    xlwrite(OutXLFile,[arrayfun(@(x) length(unique(x.PatientName)), LeftStruct(Ind).UniResults)]' ,LeftStimSite{a},CellRange);
    
end


RightInds = find(~arrayfun(@(x) isempty(x.StimAnnot), RightStruct));
RightStimSite = {RightStruct(RightInds).AnatomicalSite};
for a = 1:length(RightStimSite)
    
    Ind = RightInds(a);
    
    %Set the headings for each of the columns
    xlwrite(OutXLFile,{'Anatomical Area','Average rank value (0-1)','Average QV (1-4)','Average Z score','Number of datapoints','Number of patients'},RightStimSite{a},'A1:F1');
    
    StartRow = 2;
    CellRange = sprintf('A%i:A%i',StartRow,StartRow+(length(RightStruct(Ind).UniResults)-1));
    
    %Write the sorted labels to the sheet
    xlwrite(OutXLFile,{RightStruct(Ind).UniResults.Label}',RightStimSite{a},CellRange);
    
    %Write the average rank/QV and Z scores and the number of results to the
    %site
    CellRange = sprintf('B%i:B%i',StartRow,StartRow+(length(RightStruct(Ind).UniResults)-1));
    xlwrite(OutXLFile,[RightStruct(Ind).UniResults.AverageMeanRank]',RightStimSite{a},CellRange);
    CellRange = sprintf('C%i:C%i',StartRow,StartRow+(length(RightStruct(Ind).UniResults)-1));
    xlwrite(OutXLFile,[RightStruct(Ind).UniResults.AverageMeanQV]',RightStimSite{a},CellRange);
    CellRange = sprintf('D%i:D%i',StartRow,StartRow+(length(RightStruct(Ind).UniResults)-1));
    xlwrite(OutXLFile,[RightStruct(Ind).UniResults.AverageZScore]',RightStimSite{a},CellRange);
    CellRange = sprintf('E%i:E%i',StartRow,StartRow+(length(RightStruct(Ind).UniResults)-1));
    xlwrite(OutXLFile,[arrayfun(@(x) length(x.Level), RightStruct(Ind).UniResults)]' ,RightStimSite{a},CellRange);
    CellRange = sprintf('F%i:F%i',StartRow,StartRow+(length(RightStruct(Ind).ReciprocalUniResults)-1));
    xlwrite(OutXLFile,[arrayfun(@(x) length(unique(x.PatientName)), RightStruct(Ind).UniResults)]' ,RightStimSite{a},CellRange);
    
end


%***************************
%Do the reciprocal (afferent/incoming) results
%***************************
LeftInds = find(~arrayfun(@(x) isempty(x.StimAnnot), LeftStruct));
LeftStimSite = {LeftStruct(LeftInds).AnatomicalSite};
for a = 1:length(LeftStimSite)
    
    Ind = LeftInds(a);
    
    %Set the headings for each of the columns
    xlwrite(InXLFile,{'Anatomical Area','Average rank value (0-1)','Average QV (1-4)','Average Z score','Number of datapoints','Number of patients'},LeftStimSite{a},'A1:F1');
    
    StartRow = 2;
    CellRange = sprintf('A%i:A%i',StartRow,StartRow+(length(LeftStruct(Ind).ReciprocalUniResults)-1));
    
    %Write the sorted labels to the sheet
    xlwrite(InXLFile,{LeftStruct(Ind).ReciprocalUniResults.Label}',LeftStimSite{a},CellRange);
    
    %Write the average rank/QV and Z scores and the number of results to the
    %site
    CellRange = sprintf('B%i:B%i',StartRow,StartRow+(length(LeftStruct(Ind).ReciprocalUniResults)-1));
    xlwrite(InXLFile,[LeftStruct(Ind).ReciprocalUniResults.AverageMeanRank]',LeftStimSite{a},CellRange);
    CellRange = sprintf('C%i:C%i',StartRow,StartRow+(length(LeftStruct(Ind).ReciprocalUniResults)-1));
    xlwrite(InXLFile,[LeftStruct(Ind).ReciprocalUniResults.AverageMeanQV]',LeftStimSite{a},CellRange);
    CellRange = sprintf('D%i:D%i',StartRow,StartRow+(length(LeftStruct(Ind).ReciprocalUniResults)-1));
    xlwrite(InXLFile,[LeftStruct(Ind).ReciprocalUniResults.AverageZScore]',LeftStimSite{a},CellRange);
    CellRange = sprintf('E%i:E%i',StartRow,StartRow+(length(LeftStruct(Ind).ReciprocalUniResults)-1));
    xlwrite(InXLFile,[arrayfun(@(x) length(x.Level), LeftStruct(Ind).ReciprocalUniResults)]' ,LeftStimSite{a},CellRange);
    CellRange = sprintf('F%i:F%i',StartRow,StartRow+(length(LeftStruct(Ind).ReciprocalUniResults)-1));
    xlwrite(InXLFile,[arrayfun(@(x) length(unique(x.PatientName)), LeftStruct(Ind).ReciprocalUniResults)]' ,LeftStimSite{a},CellRange);
    
end

RightInds = find(~arrayfun(@(x) isempty(x.StimAnnot), RightStruct));
RightStimSite = {RightStruct(RightInds).AnatomicalSite};
for a = 1:length(RightStimSite)
    
    Ind = RightInds(a);
    
    %Set the headings for each of the columns
    xlwrite(InXLFile,{'Anatomical Area','Average rank value (0-1)','Average QV (1-4)','Average Z score','Number of datapoints','Number of patients'},RightStimSite{a},'A1:F1');
    
    StartRow = 2;
    CellRange = sprintf('A%i:A%i',StartRow,StartRow+(length(RightStruct(Ind).ReciprocalUniResults)-1));
    
    %Write the sorted labels to the sheet
    xlwrite(InXLFile,{RightStruct(Ind).ReciprocalUniResults.Label}',RightStimSite{a},CellRange);
    
    %Write the average rank/QV and Z scores and the number of results to the
    %site
    CellRange = sprintf('B%i:B%i',StartRow,StartRow+(length(RightStruct(Ind).ReciprocalUniResults)-1));
    xlwrite(InXLFile,[RightStruct(Ind).ReciprocalUniResults.AverageMeanRank]',RightStimSite{a},CellRange);
    CellRange = sprintf('C%i:C%i',StartRow,StartRow+(length(RightStruct(Ind).ReciprocalUniResults)-1));
    xlwrite(InXLFile,[RightStruct(Ind).ReciprocalUniResults.AverageMeanQV]',RightStimSite{a},CellRange);
    CellRange = sprintf('D%i:D%i',StartRow,StartRow+(length(RightStruct(Ind).ReciprocalUniResults)-1));
    xlwrite(InXLFile,[RightStruct(Ind).ReciprocalUniResults.AverageZScore]',RightStimSite{a},CellRange);
    CellRange = sprintf('E%i:E%i',StartRow,StartRow+(length(RightStruct(Ind).ReciprocalUniResults)-1));
    xlwrite(InXLFile,[arrayfun(@(x) length(x.Level), RightStruct(Ind).ReciprocalUniResults)]' ,RightStimSite{a},CellRange);
    CellRange = sprintf('F%i:F%i',StartRow,StartRow+(length(RightStruct(Ind).ReciprocalUniResults)-1));
    xlwrite(InXLFile,[arrayfun(@(x) length(unique(x.PatientName)), RightStruct(Ind).ReciprocalUniResults)]' ,RightStimSite{a},CellRange);
    
end

%Print the locations of the files and also state that the files are
%completed - warn the user that they will be overwritten
clc;
fprintf('Outgoing results saved to %s\n',OutXLFile);
fprintf('Outgoing results saved to %s\n',InXLFile);
InXLFile = 'Anatomical_Analysis_Afferent_Connectivity_Results(Bipolar_Ref).xlsx';
OutXLFile = 'Anatomical_Analysis_Efferent_Connectivity_Results(Bipolar_Ref).xlsx';
fprintf('Outgoing results saved to %s\n',OutXLFile);
fprintf('Outgoing results saved to %s\n',InXLFile);
fprintf('\nAnatomical ranking complete\n');
warning('Written .xlsx files from the anatomical analysis are outputted to the same spreadsheet files, please rename the incoming and outgoing results files to keep them, otherwise they will be overwritten');