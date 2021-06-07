function CCEPRepositoryUpdateIndividual(varargin)
%Call this function to add an individual data file to the stim repository 


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
    
    %Check if there is already a repository - if not, then create a blank
    %one
    try
    load(CCEPReposFileName);
    catch
        CCEPRepository = [];
    end
else
    warning('The GUI has been closed - restarting the main GUI from the beginning');
    CCEPGUIInit;
end


%Get the file that is to be added to the library
[ReposNewFile] = uigetfile('*.mat', 'Select the CCEP data file to add to the stim repository');
load(ReposNewFile); %Should import DataStruct and StimAnnot


%Get the names of the current addition patient and also which patients are
%already in the CCEP repos
TempName = DataStruct.Info.Name;
if isempty(CCEPRepository)||isempty(fieldnames(CCEPRepository))
    NameList = {};
else
    NameList = {CCEPRepository.Name};
end

%Indicate you are beginning
fprintf('Adding Results file: %s\n',ReposNewFile);

%Get all of the results to be imported into the same format as the
%repository tht is already there.
    
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
        
    %Correct the StimAnnot structure to include a bit more info
    for b = 1:length(StimAnnot)
        
        %Add some detail about the stimulation area to the code
        StimAnnot(b).Name = DataStruct.Info.Name; %If problem here, check the File in TempResultFile
        StimAnnot(b).Patient = DataStruct.Info.Name;
        if ~isfield(DataStruct.Info,'Filtering')
            StimAnnot(b).Filtering = [CCEPGUIParams.HPF,CCEPGUIParams.LPF; CCEPGUIParams.Notch(1),CCEPGUIParams.Notch(2)];
        else
            StimAnnot(b).Filtering = DataStruct.Info.Filtering;
        end
       
        %Add some detail about the stimulation area to the code
        TempInd = find(strcmp(StimAnnot(b).Label,{DataStruct.Bi.Label}));
        StimAnnot(b).Anatomical = DataStruct.Bi(TempInd).Anatomical;
        StimAnnot(b).TemplateAnatomical = DataStruct.Bi(TempInd).TemplateAnatomical;
        StimAnnot(b).CoOrds = DataStruct.Bi(TempInd).CoOrds;
        StimAnnot(b).TissueProb = DataStruct.Bi(TempInd).TissueProb;
        StimAnnot(b).MNICoOrds = DataStruct.Bi(TempInd).MNICoOrds;
        
        %Get the file names and add the information to the
        %repository
        StimAnnot(b).ResultFile = ShortFileName(which(ReposNewFile));
        StimAnnot(b).DataFile = ShortFileName(which(DataStruct.Info.DataFile));
        if isempty(DataStruct.Info.AnnotFile)
            StimAnnot(b).AnnotFile = [];
        else
            StimAnnot(b).AnnotFile = ShortFileName(which(DataStruct.Info.AnnotFile));
        end
        StimAnnot(b).ElectrodeFile = ShortFileName(which(DataStruct.Info.ElectrodeFile));
    end

%Check if the patient has already got a repository in the file, if the
%patient's repository is already present, concatenate the repositories, if
%not, then make a new one
% if ~isempty(fieldnames(CCEPRepository))
if sum(strcmp(TempName, NameList))== 0 
    
    TempRepository = StimAnnot;
    CCEPRepository(length(CCEPRepository)+1).Name = DataStruct.Info.Name;
    CCEPRepository(length(CCEPRepository)).Patient = DataStruct.Info.Name;
    CCEPRepository(length(CCEPRepository)).Repos = TempRepository;
    CCEPRepository(length(CCEPRepository)).Electrode = rmfield(DataStruct, {'Info','Stim','Ref'});  

else
    
    %If there was a repos for that patient name, then concatenate them and
    %leave the other data alone
    NameInd = find(strcmp(NameList, TempName));
    TempRepository = CCEPRepository(NameInd).Repos;
    TempRepository(end+1:end+length(StimAnnot)) = StimAnnot;
    CCEPRepository(NameInd).Repos = TempRepository;
end
% %If there are no fieldnames created, then 
% else
% end

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
