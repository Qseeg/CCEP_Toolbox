function [DataStruct, StimAnnot, Files, ImportData] = CCEPIndividualDataImport(varargin)
%[Data, StimAnnot, Files, ImportData] = CCEPIndividualDataImport('Name', PatientName,'Data|EDF',DataFile,'Annot',AnnotFile,'Elec',ElectrodeFile)
%   Use this function to input the name of an EDF File and get back all of
%   the data that is required to use it with a functions developed.
%
%*/If no inputs are given - a file dialog box will be brought up and
%Data - The Unipolar and Bipolar and File info Struct
%ImportData - The Raw Import Data from from the DataFile
%StimAnnot - The StimAnnotations from the annot file and the StimData trace
%Files - The EDF, Annot and Electrode Files in Files.EDF/.Annot/.Elec
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
    AnnotFile = '';
elseif isempty(which(AnnotFile))
    AnnotFile = uigetfile({'*.mat';'*.txt'},'Find an annotations file (either a .txt or .mat');
    if isnumeric(AnnotFile)
        if AnnotFile == 0
            error(sprintf('No Annotations file was given for the EDF file %s',DataFile));
        end
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

%Get the electrode structure and the data structure
if exist('AnnotFileName','var')
    [DataStruct] = CCEPDataStructCreate('name', PatientName, 'data',DataFile, 'annotations',AnnotFile, 'Electrode',ElectrodeFile);
else
    [DataStruct] = CCEPDataStructCreate('name', PatientName, 'data',DataFile, 'Electrode',ElectrodeFile);
end

%Record the key file names in a structure
if nargout>=2
Files.Data = DataFile;
Files.EDF = DataFile;
Files.Annot = AnnotFile;
Files.Electrode = ElectrodeFile;
end

%Get the baseline times of pulses and the pulse times
fprintf('Getting the Stim Data for %s\n',ShortFileName(DataFile));

%Grab the pulse times of the stimulation
if nargout >= 3
    if ~exist('StimData','var')
        [~, ~,StimData] = EDF_Read(DataFile,{DataStruct.Stim(1).Label});
        if ~isempty(StimData)
            AllPulses = StimPulseFinder(StimData.Data);
            if ~exist('Annotations','var')
                Annotations = AnnotationGrabber(AnnotFile);
            end
            StimAnnot = StimAnnotConvert(Annotations,AllPulses,DataStruct.Info.SamplingFreq);
        else
            if ~exist('Annotations','var')
                Annotations = AnnotationGrabber(AnnotFile);
            end
            StimAnnot = StimAnnotConvert(Annotations,[],DataStruct.Info.SamplingFreq);
            %     StimAnnot = MissingStimPulseAcquire('EDF',DataFile,'Annot',AnnotFileName,'Elec',ElectrodeFile,'Data',ImportData,'Stim',StimAnnot,'InfoStruct',DataStruct,'Type','CCEP');
        end
    end
    clearvars StimData;
    
    for g = 1:length(StimAnnot)
        Temp = find(strcmp(StimAnnot(g).Label,{DataStruct.Bi.Label}));
        StimAnnot(g).CoOrds = DataStruct.Bi(Temp).CoOrds;
        StimAnnot(g).TissueProb = DataStruct.Bi(Temp).TissueProb;
        StimAnnot(g).Anatomical = DataStruct.Bi(Temp).Anatomical;
        StimAnnot(g).TemplateAnatomical = DataStruct.Bi(Temp).TemplateAnatomical;
    end
end


%Import the EDF filedata
if nargout == 4
    fprintf('Importing the EDF Data for %s\n',ShortFileName(DataFile));
    
    if exist('DataFile','var') && exist('Labels','var') && (~exist('AnnotFile','var'))
        [SigInfo, ChannelInfo, ImportData, Annotations] = EDF_Read(DataFile, Labels); %Do this if specific labels are given
    elseif exist('DataFile','var') && exist('Labels','var') && (exist('AnnotFile','var'))
        [SigInfo, ChannelInfo, ImportData] = EDF_Read(DataFile, Labels); %Do this if specific labels are given
    elseif exist('DataFile','var') && (exist('AnnotFile','var'))
        [SigInfo, ChannelInfo, ImportData] = EDF_Read(DataFile); %Do this if specific labels are given
    elseif exist('DataFile','var') && (~exist('AnnotFile','var'))
        [SigInfo, ChannelInfo, ImportData,Annotations] = EDF_Read(DataFile); %Do this if specific labels are given
    elseif exist('DataFile','var')
        [SigInfo, ChannelInfo] = EDF_Read(DataFile); %Load header and info if all info is given
    end
    
end