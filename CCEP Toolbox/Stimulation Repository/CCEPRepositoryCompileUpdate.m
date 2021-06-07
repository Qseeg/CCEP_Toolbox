function CCEPRepositoryCompileUpdate(varargin)
%Generate the stim repository from all of the EDF files that you have on the CCEPGUI path


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


%Load in all EDF Files, by searching through the EDF files you have

%And also loading any annotations.txt that correspond to .EDF
%files if any exist.

%Load in the CCEPMainFig parameters to keep everything current
CCEPGUIMainFig = findobj('Tag','CCEPGUIMainFig');
if ~isempty(CCEPGUIMainFig)
    CCEPGUIParams = CCEPGUIMainFig.UserData;
    CCEPReposFileName = CCEPGUIParams.CurrentRepository;
    CCEPPath = CCEPGUIParams.CurrentPath;
else
    warning('The GUI has been closed - restarting the main GUI from the beginning');
    CCEPGUIInit;
end

%Get the full paths of all the individual folders, so that you can cycle
%through them one by one
Expression = ';';
CurrentFolder = regexp(CCEPPath,Expression,'split');
CurrentFolder = CurrentFolder(1:end-1);

%Look through each folder and grab the EDF files that correspond to valid
%CCEPs files
ResultFile = {};
ResultPath = {};

%Save the working directory currently so that you can come back to it
OriginalDir = pwd;
if iscell(CurrentFolder)
    for a = 1:length(CurrentFolder)
        %Check if there is an EDF file in the current folder
        TempDir = dir(CurrentFolder{a});
        for b = 3:length(TempDir)
            [~,N,E] = fileparts(TempDir(b).name);
            
            %File must be a .edf file which contains "CCEP" somewhere in the name
            if strcmp(E,'.mat') && contains(upper(N),'CCEP') && (contains(upper(N),'RESULT')|| contains(upper(N),'VALUE')) &~ contains(upper(N),'BASELINE')
                ResultFile{end+1} = TempDir(b).name;
                [P,N,E] = fileparts(which(fullfile(TempDir(b).name)));
                ResultPath{end+1} = P;
                
            end
        end
    end
end

%Do a first-parse of which unique names that exist in the files
for a = 1:length(ResultFile)
    load(ResultFile{a},'DataStruct');
    if a == 1
        NameList = {};
    end
    TempName = DataStruct.Info.Name;
    
    if sum(strcmp(TempName, NameList)) == 0
        NameList{end+1}  = TempName;
    end
end

%Now sort the names and allocate which files will belong to each
%patient
if ~isempty(ResultFile)
    [NameList, Inds] = sort_nat(NameList);
    ResultFile = ResultFile(Inds);
    UniqueName = unique(NameList);
else
    error('No results files found on the CCEPGUI path - add more files to the path');
end

%Indicate you are beginning
fprintf('Creating repository from %i Results files with %i patients\n\n',length(ResultFile), length(NameList));

%Perfrom the loading and add some extra data to the function
for a = 1:length(ResultFile)
    
    %Get the name of the patient who had stimulation performed and check if
    %you should concatenate the repository files
    if a == 1
        PastName = 'Start';
        CurrentName = NameList{1};
        NameCount = 1;
    else
        PastName = CurrentName;
        CurrentName = NameList{a};
        if ~strcmp(PastName, CurrentName)
            NameCount = NameCount+1;
        end
    end
    
    %Get the temporary results file data
    TempResultFile = ResultFile{a};
    load(TempResultFile); %Should load in "DataStruct and StimAnnot"
    
    %If there is data attached to the file, then erase it for the
    %repository save
    if ~isempty(StimAnnot)
        if isfield(StimAnnot,'Uni')
            StimAnnot = rmfield(StimAnnot,'Uni');
        end
        if isfield(StimAnnot,'Bi')
            StimAnnot = rmfield(StimAnnot,'Bi');
        end
        if isfield(StimAnnot,'ParamSummary')
            StimAnnot = rmfield(StimAnnot,'ParamSummary');
        end
    end
    
    %Bring in the electrode file to reformat the electrode structure
    load(which(ShortFileName(DataStruct.Info.ElectrodeFile))); %Will bring in the electrode array for the structure
    for c = 1:length(ElectrodeArray)
        ElectrodeArray(c).Patient = DataStruct.Info.Name;
        ElectrodeArray(c).Name = DataStruct.Info.Name;
    end
    
    
    %Correct the StimAnnot structure to include a bit more info
    for b = 1:length(StimAnnot)
        
        %Add some detail about the stimulation area to the code
        StimAnnot(b).Name = DataStruct.Info.Name; %If problem here, check the File in TempResultFile
        StimAnnot(b).Patient = DataStruct.Info.Name;
        StimAnnot(b).Filtering = DataStruct.Info.Filtering;
        
        %Add some detail about the stimulation area to the code
        TempInd = find(strcmp(StimAnnot(b).Label,{DataStruct.Bi.Label}));
        StimAnnot(b).Anatomical = DataStruct.Bi(TempInd).Anatomical;
        StimAnnot(b).TemplateAnatomical = DataStruct.Bi(TempInd).TemplateAnatomical;
        StimAnnot(b).CoOrds = DataStruct.Bi(TempInd).CoOrds;
        StimAnnot(b).TissueProb = DataStruct.Bi(TempInd).TissueProb;
        StimAnnot(b).MNICoOrds = DataStruct.Bi(TempInd).MNICoOrds;
        
        
        %Get the file names and add the information to the
        %repository
        StimAnnot(b).ResultFile = ShortFileName(which(ResultFile{a}));
        StimAnnot(b).DataFile = ShortFileName(which(DataStruct.Info.DataFile));
        if ~isempty(DataStruct.Info.AnnotFile)
            StimAnnot(b).AnnotFile = ShortFileName(which(DataStruct.Info.AnnotFile));
        else
            StimAnnot(b).AnnotFile = '';
        end
        StimAnnot(b).ElectrodeFile = ShortFileName(which(DataStruct.Info.ElectrodeFile));
    end
    
    
    %Add the stim sites and conditions to the list
    %If the previous patient name is NOT the current one, create a new entry for the stim repositories. the
    %repositories and save it back in
    if ~isempty(StimAnnot) && ~strcmp(CurrentName,PastName)
        TempRepository = StimAnnot;
        CCEPRepository(NameCount).Name = DataStruct.Info.Name;
        CCEPRepository(NameCount).Patient = DataStruct.Info.Name;
        CCEPRepository(NameCount).Repos = TempRepository;
        CCEPRepository(NameCount).Electrode = rmfield(DataStruct, {'Info','Stim','Ref'});
        %         CCEPRepository(NameCount).Electrode.Raw = ElectrodeArray;
        
        %If the previous patient name is the current one, concatenate the
        %repositories and save it back in
    elseif ~isempty(StimAnnot) && strcmp(CurrentName,PastName)
        TempRepository = CCEPRepository(NameCount).Repos;
        TempRepository(end+1:end+length(StimAnnot)) = StimAnnot;
        CCEPRepository(NameCount).Repos = TempRepository;
    end
    
    fprintf('Finished Patient %i of %i\n',a, length(ResultFile));
end

%Look through each patient's repository and check for duplicates and remove
%them
for a = 1:length(CCEPRepository)
    TempRepository = CCEPRepository(a).Repos;
    
    %Concatenate the times and their respective stimulation
    %co-ordinates to check to see if any of the structure rows are
    %duplicates
    TempTimes = reshape([TempRepository.TimeWindow]', 2, length(TempRepository))';
    TempCoOrds = reshape([TempRepository.CoOrds]', 3, length(TempRepository))';
    TempCombine = [TempTimes TempCoOrds];
    
    [UniqueRows,~,Temp] = unique(TempCombine, 'rows','first');
    NumObs = accumarray(Temp,1);
    FlagInds = find(NumObs > 1);
    
    
    %Remove the duplicate rows
    TempRepository(FlagInds) = [];
    
    %Then resave the unique structure rows into the repository
    CCEPRepository(a).Repos = TempRepository;
    
end

%Sort the CCEP respository by patient's names to give it a semblance of
%order
[~,Ind] = sort_nat({CCEPRepository.Name});
CCEPRepository = CCEPRepository(Ind);

%Save the CCEP stimulation repository
fprintf('Saving CCEPRepository.....');
save(CCEPReposFileName,'CCEPRepository','-v6'); %If an error occurs here, you have alot of data! Just change the save switch to -v7.3
fprintf('Done\n\n');
cd(OriginalDir);