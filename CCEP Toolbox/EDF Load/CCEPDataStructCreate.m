function [DataStruct] = CCEPDataStructCreate(varargin)
%[DataStruct] = CCEPDataStructCreate('name|patient', PatientName, 'data',DataFileName, 'annotations',AnnotFileName,'Channel|Label',SelectedOriginalLabels, 'Electrode',ElectrodeFile)
%This function takes in an EDF file and patient name and gets all of the
%UNIPOLAR information for the signals
%Allocates the info to 4 structures: Info, Sig,Ref and Stim
%Info = Name PatientName
%Info = SamplingFreq
%Info = DataFileName
%Info = AnnotFileName
%
%SigStruct = Label ('TP''1') full relevant label
%SigStruct = Electrode ('TP''') Just the stringpart of the electrode label
%SigStruct = Contact (1) The contact of the electrode label
%SigStruct = OriginalLabel ('POL TP''1') Original Label as it appeared in
%the EDF header
%SigStruct = AnatomicalLabel ('Lat SFG') anatomical label as it appeared in the anatomical map of the spreadsheet
%SigStruct = CoOrd [x,y,z] patient space or MNI coOrd recorded in electrodearray
%
%RefStruct = Label ('CZ') full relevant label
%RefStruct = OriginalLabel ('EEG-Ref CZ') full relevant label from EDF header
%
%StimStruct = Label ('Stim') Label
%StimStruct = OriginalLabel ('POL DC09') full relevant label from EDF header


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


%Import the CCEP GUI Init parameters for the toolbox
load(which('Current CCEP GUI Init Parameters.mat'));

if nargin == 1 %Check if just the filename is handed to the function
    DataFile = varargin{1};
    if ~ischar(DataFile)
        error('DataFileName is not a valid type');
    end
else
    %*******Parse inputs to function
    for i = 1:2:length(varargin) %Go through every 2nd value of the name-value pair argument
        InputStr = varargin{i}; %Pop the inputs into a string to get the information out
        if ~isempty(regexpi(InputStr,'name')) || ~isempty(regexpi(InputStr,'pat')) %Find the name of name of the patient
            PatientName = varargin{i+1};
            
        elseif ~isempty(regexpi(InputStr,'data'))  %Find the name of the EDF file (only read in channel info though)
            DataFile = which(varargin{i+1}); %Find the file
            
        elseif ~isempty(regexpi(InputStr,'annot'))  %Find the name of the EDF file (only read in channel info though)
            if ischar(varargin{i+1})||iscell(varargin{i+1})
                AnnotFile = which(varargin{i+1}); %Find the file
                Annotations = [];
            elseif isstruct(varargin{i+1})
                AnnotFile = '';
                Annotations = varargin{i+1};
            end
            
        elseif ~isempty(regexpi(InputStr,'chan')) || ~isempty(regexpi(InputStr,'label')) %Find the channel labels (if specific ones are given)
            Labels = varargin{i+1};
            if ~iscell(Labels) %If it's a struct, make it a cell
                NewLabels = {Labels};
                clearvars Labels
                Labels = NewLabels;
            end
            
        elseif ~isempty(regexpi(InputStr,'elec' )) %Find the electrodes file and read from that if given
            ElectrodeFile = varargin{i+1};
        end
    end
end

%Check to see if the DataFile and PatientName are given, if they aren't
%present, throw an error and return to the caller function
if ~exist('DataFile','var')
    error('No FileName given to function');
    return;
end
if ~exist('PatientName','var')
    error('No PatientName given to function');
    return;
end

%Give the annotations file a blank name if it is not present, indicating
%that the annotations on the EDF file are valid
if ~exist('AnnotFile','var')
    
    %Look to see if there is a file created with the AnnotEditor
    [P,N,E] = fileparts(which(DataFile));
    TempName = which(sprintf('%s Annotations.mat',N));
    
    %If there is an altered annotations file, load that in
    if ~isempty(TempName)
        AnnotFile = TempName;
        load(AnnotFile);
    else
        AnnotFile = '';
    end

elseif isempty(AnnotFile)
    
    %Look to see if there is a file created with the AnnotEditor
    [P,N,E] = fileparts(which(DataFile));
    TempName = which(sprintf('%s Annotations.mat',N));
    
    %If there is an altered annotations file, load that in
    if ~isempty(TempName)
        AnnotFile = TempName;
        load(AnnotFile);
    else
        AnnotFile = '';
    end
end

%Import the electrode file, if none is given, look for it based on the
%patient name
if exist('ElectrodeFile','var')
    load(which(ElectrodeFile)); %Load the electrode file if it exists
else
    %If it is not given, then try to load it based on the patient name
    TempElectrodeFile = sprintf('%s Electrodes.mat',PatientName);
    if ~isempty(which(TempElectrodeFile))
        ElectrodeFile = ShortFileName(which(TempElectrodeFile));
        load(which(TempElectrodeFile)); 
    else
        %If no electrode file was found using the automatic routine, then ask the user to enter a file
        [TempElectrodeFile, P] = uigetfile('*.mat','Get the electrode file corresponding to the patient you are using');
        addpath(P);
        load(which(TempElectrodeFile));
    end
    ElectrodeFile = TempElectrodeFile;
end

%***********Import the EDF filedata
if exist('DataFile','var')
    [SigInfo, ChannelInfo] = EDF_Read(DataFile); %Load header and info if all info is given
    
elseif exist('DataFile','var') && exist('Labels','var')
    [SigInfo, ChannelInfo] = EDF_Read(DataFile, Labels); %Do this if specific labels are given
end

%********Get the File Info from the EDF File
Info.Name = PatientName;
Info.DataFile = DataFile;
Info.AnnotFile = AnnotFile;
Info.ArtefactFile = '';
if exist('ElectrodeFile','var')
    Info.ElectrodeFile = ElectrodeFile;
else
    Info.ElectrodeFile = '';
end
Info.Name = PatientName;
% [Info.PatientNumber, ~,~] = PatientName2Number(PatientName);
Info.DataFile = DataFile;
Info.AnnotFile = AnnotFile;
Info.ArtefactFile = '';
Info.StartTime = SigInfo.Starttime;       %Recording starttime
Info.RecordDate = SigInfo.Startdate;      %Recording date of file creation
Info.Duration = SigInfo.Duration * SigInfo.NumRecords;  %Duration in seconds

Info.SamplingFreq = SigInfo.SamplingFrequency;    %Allocate the sampling freq

%*********Begin teh channel data read in and manipulation
TempLabel = {ChannelInfo.Label}; %Allocate labels to a cell a

%************Get the good channels relevant to CCEPs and exclude the useless ones
if exist('ElectrodeArray','var') %*****If electrode labels are given, look through them by using a template
    %*****If the electrode array is handed to the function, use the template
    %labels from that to find the correct labels from the file given
        
    Counter = 1;
    for h = 1:length(ElectrodeArray)
        for e = 1:ElectrodeArray(h).NumContacts
            TemplateLabels{Counter} = sprintf('%s%1.0f',ElectrodeArray(h).ElectrodeName,e);
            ElectrodeLabels{Counter} = sprintf('%s',ElectrodeArray(h).ElectrodeName);
            ContactNumbers(Counter) = e;
            if isfield(ElectrodeArray, 'ROI')
                TemplateAnatomical{Counter} = ElectrodeArray(h).ROI(e).Label;
                TemplateProb(Counter) = ElectrodeArray(h).ROI(e).Prob;
            else
                TemplateAnatomical{Counter} = '';
                TemplateProb(Counter) = [];
            end
            Counter = Counter + 1;
        end
    end
    SigCounter = 1;
    RefCounter = 1;
    DoneLabels = {};
    
    %Include this code to check which labels are being found by the function
    for i = 1:length(TempLabel)
        Check(i).TempLabel = TempLabel{i};
        Check(i).Valid = ~isempty(regexpi(char(TempLabel{i}),'(\w*('')?\d+)')) && ... %Match strings with letters proceeded by numbers with or without an apostrophe
            isempty(regexpi(char(TempLabel{i}),CCEPGUIParams.BadLabels)); %Ignore labels when they contain DC/EEG/ECG/SP/$
        if Check(i).Valid == 1
            Check(i).Label =  regexpi(char(upper(TempLabel{i})),'(\w*('')?\d+)','match');
            FoundInd = find(strcmpi(TemplateLabels,Check(i).Label));
            if ~isempty(FoundInd)
                Check(i).ElecTemplate = TemplateLabels{FoundInd};
            end
        else
            Check(i).Label = '-';
            Check(i).ElecTemplate = '-';
        end
        
        if ~isempty(regexpi(char(TempLabel{i}),'(\w*('')?\d+)')) && ... %Match strings with letters proceeded by numbers with or without an apostrophe
                isempty(regexpi(char(TempLabel{i}),CCEPGUIParams.BadLabels)) %Ignore labels when they contain DC/EEG/ECG/SP/$
            
            %Get the current label and check that it has not already been
            %found, nad then record it's information
            CurrentLabel = regexpi(char(TempLabel{i}),'(\w*('')?\d+)','match');
            y = find(strcmpi(TemplateLabels,CurrentLabel));
            if ~isempty(y)
                if ~isempty(DoneLabels)
                    if sum(strcmp(TemplateLabels{y},DoneLabels))==0 %Check if the label has been found before
                        SigLabels(SigCounter).Label = TemplateLabels{y};
                        SigLabels(SigCounter).Electrode = ElectrodeLabels{y};
                        SigLabels(SigCounter).Contact = ContactNumbers(y);
                        SigLabels(SigCounter).OriginalLabel = char(TempLabel{i});
                        SigLabels(SigCounter).TemplateAnatomical = TemplateAnatomical{y};
                        SigLabels(SigCounter).TemplateProb = TemplateProb(y);
                        DoneLabels{SigCounter} = TemplateLabels{y};
                        SigCounter = SigCounter + 1;
                    end
                else
                    SigLabels(SigCounter).Label = TemplateLabels{y};
                    SigLabels(SigCounter).Electrode = ElectrodeLabels{y};
                    SigLabels(SigCounter).Contact = ContactNumbers(y);
                    SigLabels(SigCounter).OriginalLabel = char(TempLabel{i});
                    SigLabels(SigCounter).TemplateAnatomical = TemplateAnatomical{y};
                    SigLabels(SigCounter).TemplateProb = TemplateProb(y);
                    DoneLabels{SigCounter} = TemplateLabels{y};
                    SigCounter = SigCounter + 1;
                end
            end
            
        elseif ~isempty(regexpi(char(TempLabel{i}),'[fcp]z')) %Find the CZ and PZ contacts
            RefStruct(RefCounter).Name = char(regexpi(char(TempLabel{i}),'[fcp]z','match')); %Get the relevant label
            RefStruct(RefCounter).OriginalLabel = char(TempLabel{i});
            RefCounter = RefCounter + 1;
        elseif ~isempty(regexpi(char(TempLabel{i}),CCEPGUIParams.DefaultStimLabel))  %Get the default stim channel label (should be consistent)
            StimStruct.Label = char(regexpi(char(TempLabel{i}),CCEPGUIParams.DefaultStimLabel,'match')); %Get the stim label
            StimStruct.OriginalLabel = char(TempLabel{i}); %Get the stim label
        end
    end
    
else %********If no electrode labels are given, just look through them the old way
    SigCounter = 1;
    RefCounter = 1;
    for i = 1:length(TempLabel)
        if ~isempty(regexpi(char(TempLabel{i}),'(\w*('')?\d+)')) && ... %Match strings with letters proceeded by numbers with or without an apostrophe
            isempty(regexpi(char(TempLabel{i}),CCEPGUIParams.BadLabels)) %Ignore labels when they contain DC/EEG/ECG/SP/$
            SigLabels(SigCounter).Label = char(regexpi(char(TempLabel{i}),'(\w*('')?\d+)','match')); %Get the full label
            SigLabels(SigCounter).Electrode = SigLabels(SigCounter).Label((isstrprop(SigLabels(SigCounter).Label,'alpha')| isstrprop(SigLabels(SigCounter).Label,'punct'))); %Find the last electrode name; %Get the contact Number
            SigLabels(SigCounter).Contact = str2num(char((regexpi(char(SigLabels(SigCounter).Label),'(\d+)','match')))); %Get the contact Number
            SigLabels(SigCounter).OriginalLabel = char(TempLabel{i});
            SigCounter = SigCounter + 1;
        elseif ~isempty(regexpi(char(TempLabel{i}),'[fcp]z')) %Find the CZ and PZ contacts
            RefStruct(RefCounter).Name = char(regexpi(char(TempLabel{i}),'[fcp]z','match')); %Get the relevant label
            RefStruct(RefCounter).OriginalLabel = char(TempLabel{i});
            RefCounter = RefCounter + 1;
        elseif ~isempty(regexpi(char(TempLabel{i}),CCEPGUIParams.DefaultStimLabel))  %Get DCO9
            StimStruct.Label = char(regexpi(char(TempLabel{i}),CCEPGUIParams.DefaultStimLabel,'match')); %Get the stim label
            StimStruct.OriginalLabel = char(TempLabel{i}); %Get the stim label
        end
    end
end


%********Read in the anatomical labels for the patient
try %Work fine if the anatomical map is loaded into the structure
    [TempAnatomicalLabels] = CCEPMapImport(PatientName,{SigLabels.Label});
    for u = 1:length({SigLabels.Label})
        SigLabels(u).Anatomical = TempAnatomicalLabels{u}; %Assign to a structure
    end
    %Do this if the Map is not yet loaded
catch 
    fprintf('Anatomical Map for %s Not found\n',PatientName);
    for u = 1:length({SigLabels.Label})
        SigLabels(u).Anatomical = 'Unknown'; %Assign to a structure
    end
end

%********Reorganise the labels for signal and reference
[~,NewInds] = sort_nat({SigLabels.Label});
UniqueElectrodes = unique({SigLabels.Electrode}); %Get the names of unique electrodes
for j = 1:length(NewInds)
    TempInd = NewInds(j); %Make vars a bit more legible
    SigStruct(j).Label = SigLabels(TempInd).Label; %Allocate the data in alphabetical order
    SigStruct(j).Electrode = SigLabels(TempInd).Electrode; %Allocate the string component of a channel name
    SigStruct(j).Contact = SigLabels(TempInd).Contact; %Allocate the data in alphabetical order
    SigStruct(j).Anatomical = SigLabels(TempInd).Anatomical; %Allocate the string component of a channel name
    SigStruct(j).OriginalLabel = SigLabels(TempInd).OriginalLabel; %Allocate the data in alphabetical order
    SigStruct(j).Type = 'Unipolar'; %Assign the type of referencing to the structure
    if isfield(SigLabels, {'TemplateAnatomical'})
        SigStruct(j).TemplateAnatomical = SigLabels(TempInd).TemplateAnatomical;
    end
end

%********Read in the electrode co-ords for the patient
[TempCoOrds,TissueProb,MNICoOrds] = CCEPCoOrdRead(ElectrodeArray, SigStruct); %Work fine if the CoOrds are already loaded

for u = 1:length(TempCoOrds)
    SigStruct(u).CoOrds = TempCoOrds(u,:); %Assign to the structure
    SigStruct(u).TissueProb = TissueProb(u,:);
    SigStruct(u).MNICoOrds = MNICoOrds(u,:);
end

%******Allocate to outgoing file information
DataStruct.Info = Info;
if ~exist('StimStruct','var')
    DataStruct.Ref = [];
else
    DataStruct.Ref= RefStruct;
end


if ~exist('StimStruct','var')
    DataStruct.Stim= [];
else
    DataStruct.Stim= StimStruct;
end
DataStruct.Uni= SigStruct;

%Convert the unipolar to bipolar information
BipolarStruct = BipolarDataConversionFunction(DataStruct,'Info'); %Read in only the channel info intially
DataStruct.Bi= BipolarStruct;



