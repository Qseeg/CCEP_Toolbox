function [DataStruct, ImportData] = CCEPFilterFunction(DataStruct, ImportData, DataRef)
%[DataStruct, ImportData] = CCEPFilterFunction(DataStruct, ImportData, DataRef)
%Take in the ImportData (in either bipolar or unipolar format) and use an
%FIR filter on the data. If accessible, use the parallel toolbox


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


CCEPGUIMainFig = findobj('Tag','CCEPGUIMainFig');
if isempty(CCEPGUIMainFig)
    SamplingFreq = DataStruct.Info.SamplingFreq;
    CCEPGUIParams.Notch = [48 52];
    CCEPGUIParams.HPF = 1;
    CCEPGUIParams.LPF = 0.3*SamplingFreq;
else
    CCEPGUIParams = CCEPGUIMainFig.UserData;    
end

%Input the default parameters
NumPoles = 500;
SamplingFreq = DataStruct.Info.SamplingFreq;
HPF = CCEPGUIParams.HPF; %Cut the data above 1Hz
LPF = CCEPGUIParams.LPF; %Cut the data before the 150 Hz noise harmnoic

%If there is no signal processing toolbox - then throw a warning saying
%that the data was not present
try
B1 = fir1(NumPoles,[HPF/(SamplingFreq/2), LPF/(SamplingFreq/2)]); %Bandpass from 1-(0.3*Fs)Hz
Notch = CCEPGUIParams.Notch./(SamplingFreq/2);
B2 = fir1(NumPoles,[Notch(1)/(SamplingFreq/2), Notch(2)/(SamplingFreq/2)],'stop'); %Bandpass from 1-(0.3*Fs)Hz
GrpDelay = NumPoles/2;
DataStruct.Info(1).Filtering = [HPF LPF; Notch(1), Notch(2)];
catch
    warning('Signal Processing toolbox not installed - no filtering applied');
    DataStruct.Info(1).Filtering = [0 0; 0 0];
    return;
end

%Give a flag to indicate if the data is monopolar or unipolar, give a 0
%for bipolar (do not notch filter) or a 1 for unipolar (do the notch
%filter)
if ~exist('DataRef','var')
    if sum(strcmp(ImportData(1).Label,{DataStruct.Uni.Label}))>0
        DataRef = 1;
    else
        DataRef = 0;
    end
elseif ischar(DataRef)
    if ~isempty(regexpi(DataRef,'uni'))
        DataRef = 1;
    elseif ~isempty(regexpi(DataRef,'bi'))
        DataRef = 0;
    end
elseif isempty(DataRef)
    if sum(strcmp(ImportData(1).Label,{DataStruct.Uni.Label}))>0
        DataRef = 1;
    else
        DataRef = 0;
    end
end

%Setup the parallel pool if not already done so
try
    fprintf('Setting up the Parallel Pool\n');
    ParallelPool = gcp;
    ChanInc = 4;
    fprintf('Parallel Pool Initialised\n');
catch
    fprintf('No parallel toobox found... this might take a while\n');
    ParallelPool = [];
    ChanInc = 4;
end

%Message to say that filtering has begun
if DataRef == 1
    fprintf('Beginning filtering unipolar data\n');
else
    fprintf('Beginning filtering bipolar data\n');
end

if ~isempty(ParallelPool)
    %Out of memory errors sometimes occur on large files, if the file
    %is too large, process the channels in blocks of (ChanInc)
    try
        parfor e = 1:length(ImportData)
            Temp = double(filter(B1,1,double(ImportData(e).Data))); %Filter with a BPF between HPF and LPF
            ImportData(e).Data(1:length(ImportData(e).Data)-(GrpDelay)) = Temp((GrpDelay+1):(end)); %Truncate and copy data
            
            %If the input data is unipolar
            if DataRef == 1
                Temp = double(filter(B2,1,double(ImportData(e).Data))); %Filter with the notch filter
                ImportData(e).Data(1:length(ImportData(e).Data)-(GrpDelay)) = Temp((GrpDelay+1):(end));
            end
        end
    catch
        %If there is an out of memory error, then filter the channels
        %in blocks of (ChanInc)
        FinishFlag = 0;
        StartChan = 1; %Init the channel counters
        if length(ImportData)>=ChanInc
            LastChan = ChanInc;
        else
            LastChan = length(ImportData);
        end
        while FinishFlag == 0 %Create a while loop to incrememnt the channels faster
            tic;
            parfor e = StartChan:LastChan
                Temp = double(filter(B1,1,double(ImportData(e).Data))); %Filter with a BPF between HPF and LPF
                ImportData(e).Data(1:length(ImportData(e).Data)-(GrpDelay)) = Temp((GrpDelay+1):(end)); %Truncate and copy data
                
                %If the input data is unipolar
                if DataRef == 1
                    Temp = double(filter(B2,1,double(ImportData(e).Data))); %Filter with the notch filter
                    ImportData(e).Data(1:length(ImportData(e).Data)-(GrpDelay)) = Temp((GrpDelay+1):(end));
                end
            end
            if LastChan >= length(ImportData)
                FinishFlag = 1; %Once the LastChan counter reaches the number of channels in the data, break the loop
            end
            Time = toc;
            ProjectedFinishTime(Time,StartChan,length(ImportData));
            StartChan = LastChan+1;
            if (LastChan + ChanInc) >= length(ImportData)
                LastChan = length(ImportData);
            else
                LastChan = LastChan + ChanInc;
            end
            
        end
    end
else
    for e = 1:length(ImportData)
        tic;
        Temp = double(filter(B1,1,double(ImportData(e).Data))); %Filter with a BPF between HPF and LPF
        ImportData(e).Data(1:length(ImportData(e).Data)-(GrpDelay)) = Temp((GrpDelay+1):(end)); %Truncate and copy data
        
        %If the input data is unipolar
        if DataRef == 1
            Temp = double(filter(B2,1,double(ImportData(e).Data))); %Filter with the notch filter
            ImportData(e).Data(1:length(ImportData(e).Data)-(GrpDelay)) = Temp((GrpDelay+1):(end));
        end
        Time = toc;
        ProjectedFinishTime(Time,e,length(ImportData));
    end
end
fprintf('Data filtering complete\n');