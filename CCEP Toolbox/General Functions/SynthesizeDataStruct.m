function DataStruct = SynthesizeDataStruct(SignalHeader, EDFFileHeader, AnatomicalStruct, EEGSignal)
%DataStruct = SynthesizeDataStruct(SignalHeader, EDFFileHeader, AnatomicalStruct, EEGSignals)


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


%Check which channels are probably SEEG data channels
CheckValid = ~cellfun(@isempty, regexpi({SignalHeader.NewLabel},'(\w*('')?\d+)'));

%Find which channels are external to the brain (by their designators)
CheckExternal = ~cellfun(@isempty, regexpi({SignalHeader.NewLabel},'(DC|ECG|EKG|EMG|SP|[$]|[fcp]z|CO2)'));

%Find which channels are the extracranial reference channels (if
%appliable)
CheckRef = ~cellfun(@isempty, regexpi({SignalHeader.NewLabel},'([fcp]z)'));

%Find which channels are DC channels which are probably the syncpulse
%channels (if applicable)
CheckSyncPulse = ~cellfun(@isempty, regexpi({SignalHeader.NewLabel},'DC'));

% %Assign the properties to the SEEG channels to see which ones most probably
% %belong where
% for a = 1:length(SignalHeader)
%     SignalHeader(a).Valid = CheckValid(a);
%     SignalHeader(a).External = CheckExternal(a);
%     SignalHeader(a).Ref = CheckRef(a);
%     SignalHeader(a).SyncPulse = CheckSyncPulse(a); 
%     
%     %For a valid SEEG channel, find the anatomical label and write it to
%     %the matching electrode contact name, then use the same process to
%     %bring in the EEG data
%     if CheckValid(a) == true && CheckExternal(a)==false
%         Ind = find(strcmp({AnatomicalStruct.Electrode}, SignalHeader(a).NewLabel));
%         SignalHeader(a).Anatomical = AnatomicalStruct(Ind).Anatomical;
%         Ind = find(strcmp({EEGSignals.Label}, SignalHeader(a).NewLabel));
%         SignalHeader(a).Data= EEGSignals(Ind).EEG;
%     end
%     
%         if CheckSyncPulse(a)==true       
%         SignalHeader(a).Data= EEGSignals(Ind).EEG;
%         end
%     
%         if CheckRef(a)==true       
%         Ind = find(strcmp({EEGSignals.Label}, SignalHeader(a).NewLabel));
%         SignalHeader(a).Data= EEGSignals(Ind).EEG;
%     end
%     
% end

%If there are no CoOrds attached to the structure with the anatomical maps,
%add several of the fields that will probably be missing while you are
%testing the program out
if ~isfield(AnatomicalStruct,'CoOrd')
    for a = 1:length(AnatomicalStruct)
        Temp = [0 0 0];
        AnatomicalStruct(a).CoOrd = Temp;
        AnatomicalStruct(a).MNICoOrd = Temp;
        AnatomicalStruct(a).TemplateAnatomical = AnatomicalStruct(a).Anatomical;
    end
end
    

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%SEEG Data channels (with all CoOrd and anatomical info)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SEEGInd = find(CheckValid & ~CheckExternal);

%Pre-Alloc
SEEGChannel(length(SEEGInd)).Label = {};
SEEGChannel(length(SEEGInd)).OriginalLabel = {};
SEEGChannel(length(SEEGInd)).Electrode = {};
SEEGChannel(length(SEEGInd)).Contact = [];
SEEGChannel(length(SEEGInd)).Anatomical = {};
SEEGChannel(length(SEEGInd)).TemplateAnatomical = {};
SEEGChannel(length(SEEGInd)).CoOrd = [];
SEEGChannel(length(SEEGInd)).MNICoOrd = [];
SEEGChannel(length(SEEGInd)).Type = 'SEEG';
SEEGChannel(length(SEEGInd)).Reference = 'Unipolar';
SEEGChannel(length(SEEGInd)).Data = EEGSignal(1).EEG;

%Fill in the data for the valid signal channels
for a = 1:length(SEEGInd)
    SEEGChannel(a).Label = SignalHeader(SEEGInd(a)).NewLabel;
    SEEGChannel(a).OriginalLabel = SignalHeader(SEEGInd(a)).Label;
    Ind = find(strcmp({AnatomicalStruct.Label}, SignalHeader(SEEGInd(a)).NewLabel));
    SEEGChannel(a).Electrode = AnatomicalStruct(Ind).Electrode;
    SEEGChannel(a).Contact = AnatomicalStruct(Ind).Contact;
    SEEGChannel(a).Anatomical = AnatomicalStruct(Ind).Anatomical;
    SEEGChannel(a).TemplateAnatomical = AnatomicalStruct(Ind).TemplateAnatomical;
    SEEGChannel(a).CoOrd = AnatomicalStruct(Ind).CoOrd;
    SEEGChannel(a).MNICoOrd= AnatomicalStruct(Ind).MNICoOrd;
    SEEGChannel(a).Type = 'SEEG';
    SEEGChannel(a).Reference = 'Unipolar';
    Ind = find(strcmp({EEGSignal.Label}, SignalHeader(SEEGInd(a)).NewLabel));
    SEEGChannel(a).Data = EEGSignal(Ind).EEG;
end
[~,Reorder] = sort_nat({SEEGChannel.Label});
SEEGChannel = SEEGChannel(Reorder);




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%External reference channels
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
RefInd = find(CheckRef);

%Pre-Alloc
RefChannel(length(RefInd)).Label = {};
RefChannel(length(RefInd)).OriginalLabel = {};
RefChannel(length(RefInd)).Type = 'Ref';
RefChannel(length(RefInd)).Data = EEGSignal(1).EEG;

%Fill in the data for the Ref channels
for a = 1:length(RefInd)
    RefChannel(a).Label = SignalHeader(RefInd(a)).NewLabel;
    RefChannel(a).OriginalLabel = SignalHeader(RefInd(a)).Label;
    RefChannel(a).Type = 'Ref';
    Ind = find(strcmp({EEGSignal.Label}, SignalHeader(RefInd(a)).NewLabel));
    RefChannel(a).Data = EEGSignal(Ind).EEG;
end
[~,Reorder] = sort_nat({RefChannel.Label});
RefChannel = RefChannel(Reorder);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Sync pulse channels (stimulation timing)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
StimInd = find(CheckSyncPulse);

%Pre-Alloc
StimChannel(length(StimInd)).Label = {};
StimChannel(length(StimInd)).OriginalLabel = {};
StimChannel(length(StimInd)).Type = 'DC';
StimChannel(length(StimInd)).Data = EEGSignal(1).EEG;

%Fill in the data for the DC channels
for a = 1:length(StimInd)
    StimChannel(a).Label = SignalHeader(StimInd(a)).NewLabel;
    StimChannel(a).OriginalLabel = SignalHeader(StimInd(a)).Label;
    StimChannel(a).Type = 'DC';
    Ind = find(strcmp({EEGSignal.Label}, SignalHeader(StimInd(a)).NewLabel));
    StimChannel(a).Data = EEGSignal(Ind).EEG;
end
[~,Reorder] = sort_nat({StimChannel.Label});
StimChannel = StimChannel(Reorder);

%Convert the data into a single structure and erase the data as you go
DataStruct.Uni = SEEGChannel;
clearvars SEEGChannels;
DataStruct.Ref = RefChannel;
clearvars RefChannels;
DataStruct.Stim = StimChannel;
clearvars StimChannels;
clearvars EEGSignals;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Get the info from the EDF Files
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Give Dummy variables so that you can test the code out
if ~exist('PatientName','var')
    PatientName = 'Jim';
end
if ~exist('PatientNumber','var')
    PatientNumber = 1;
end

%Bring in the patient details from the file header and map
Info.Name = PatientName; %Will need to get this from the Parent Figure or something??
Info.PatientNumber = PatientNumber; %Same goes for this field
Info.DataFile = EDFFileHeader.FileName;  %EDFFileName
Info.StartTime = EDFFileHeader.Starttime;       %Recording starttime
Info.RecordDate = EDFFileHeader.Startdate;      %Recording date of file creation
Info.SamplingFrequency = EDFFileHeader.SamplingFrequency;   %Get the sampling frequency
DataStruct.Info = Info;
clearvars Info;

%If desired cpnvert into bipolar information
BipolarStruct = BipolarDataConversionFunctionToolbox(DataStruct,'Info'); %Read in only the channel info intially
DataStruct.Bi= BipolarStruct;



