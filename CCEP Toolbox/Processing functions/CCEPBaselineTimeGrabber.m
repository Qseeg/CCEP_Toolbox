function BaselineTimes = CCEPBaselineTimeGrabber(varargin)
%BaselineTimes = CCEPBaselineTimeGrabber('Info',DataFile,'Stim',StimAnnot,'Annotations',Annotations,'Signal|EDF|Import',Sig,'NumBaseLines',NumBaselines,'SamplingFreq',SamplingFreq,'Window',WindowLength);

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


%*******Parse inputs to function
for i = 1:2:length(varargin) %Go through every 2nd value of the name-value pair argument
    InputStr = varargin{i}; %Pop the inputs into a string to get the information out
    if ~isempty(regexpi(InputStr,'Data')) || ~isempty(regexpi(InputStr,'Info')) %Find the name of name of the patient
        DataStruct = varargin{i+1};
    elseif ~isempty(regexpi(InputStr,'Stim'))  %Find the name of the EDF file (only read in channel info though)
        StimAnnot = varargin{i+1}; %Find the structure
    elseif ~isempty(regexpi(InputStr,'Annot'))  %Find the name of the EDF file (only read in channel info though)
        Annot = varargin{i+1}; %Find the structure
    elseif ~isempty(regexpi(InputStr,'import')) || ~isempty(regexpi(InputStr,'edf'))||~isempty(regexpi(InputStr,'sign'))
        ImportData = varargin{i+1}; %Find the structure
    elseif ~isempty(regexpi(InputStr,'num'))  %Get in the number of baselines (if given)
        NumBaseLines= varargin{i+1}; %Get in the number of baselines
    elseif ~isempty(regexpi(InputStr,'freq'))  %Get in the sampling Freq if given
        SamplingFreq= varargin{i+1}; %Get in the sampling Freq if given
    elseif ~isempty(regexpi(InputStr,'window'))  %Get in the sampling Freq if given
        WindowLength= varargin{i+1}; %Get in the sampling Freq if given
    end
end

%Throw an error if no importdata is given to determine the length of the
%file
if ~exist('ImportData','var')
    error('No ImportData given to the Baseline times setting function');
end
%Also error if no annotations are given, if they are given, change the
%format slightly if 'Times; is a fieldname
if ~exist('Annot','var')
    error('No Annotations were given to the Baseline times setting function');
elseif exist('Annot','var') && isfield(Annot, 'Times')
    for t = 1:length(Annot)
    Annot(t).Time = Annot(t).Times;
    end
    Annot = rmfield(Annot, 'Times');
end
%Default to 1000Hz
if ~exist('SamplingFreq','var')
    SamplingFreq = 1000;
end
%Default to 10 baseline sections
if ~exist('NumBaseLines','var')
    NumBaseLines = 200;
end
if ~exist('StimAnnot','var')
    StimAnnot = [];
end
%Set the length of the baseline window returned
if ~exist('WindowLength','var')
    WindowLength = 0.2*SamplingFreq; %2 x 100ms is the default window size
elseif WindowLength<50
    WindowLength = WindowLength*SamplingFreq; %If the windowlength is below 50, multiply it by the sampling frequency, since it is probably too low
    warning('Windowlength Multiplied by sampling frequency');
end


%Load a channel from the EDF file to find the length of the file
DataLength = length(ImportData(1).Data);

%Make a mask to set which times are valid
DataMask = true(DataLength,1);
for f = 1:length(StimAnnot)
    DataMask(StimAnnot(f).TimeWindow(1):StimAnnot(f).TimeWindow(2)) = false;
end

%Put the mask 10s either side of any annotation or at the start and end if
%the annotations are there
N = 10; %Num seconds either side of annot
for g = 1:length(Annot)
    if Annot(g).Time <= (N*SamplingFreq)
        DataMask(1:(Annot(g).Time + (N*SamplingFreq))) = false;
    elseif Annot(g).Time >= (length(DataMask) - (N*SamplingFreq))
        DataMask((Annot(g).Time - (N*SamplingFreq)): length(DataMask)) = false;
    else
        DataMask((Annot(g).Time - (1*SamplingFreq)): (Annot(g).Time + (1*SamplingFreq))) = false;
    end
end

%Check for annotations that correspond to seizure events:
%Look for an 'EEG | Onset | SZ | END' and record in a structure what time
%the Annotatation appears. This will be used to exclude baseline times
%around when a SZ has occurred
Mask = false(5,length(Annot));
[~,Mask(1,:)] = StrFindCell(upper({Annot.Comment}), 'ONSET');
[~,Mask(2,:)] = StrFindCell(upper({Annot.Comment}), 'EEG');
[~,Mask(3,:)] = StrFindCell(upper({Annot.Comment}), 'SZ');
[~,Mask(4,:)] = StrFindCell(upper({Annot.Comment}), 'SEIZURE');
[~,Mask(5,:)] = StrFindCell(upper({Annot.Comment}), 'END');
[TempInd] = find(Mask(1,:)|Mask(2,:)|Mask(3,:)|Mask(4,:)|Mask(5,:));

%Go through and make a separate structure for these annotations
SZAnnot = [];
for w = 1:length(TempInd)
    SZAnnot(w).Time = Annot(TempInd(w)).Time;
    SZAnnot(w).Comment = Annot(TempInd(w)).Comment;
    
    if SZAnnot(w).Time < (10 * SamplingFreq)
        warning('SZ in the first 10 seconds of File');
    end
end
M = 600; %Num seconds either side of annot (10 mins)
if ~isempty(SZAnnot)
    for g = 1:length(SZAnnot)
        if SZAnnot(g).Time <= (M*SamplingFreq)
            DataMask(1:(SZAnnot(g).Time + (M*SamplingFreq)));
        elseif SZAnnot(g).Time >= (length(DataMask) - (M*SamplingFreq))
            DataMask((SZAnnot(g).Time - (M*SamplingFreq)): length(DataMask));
        else
            DataMask((SZAnnot(g).Time - (1*SamplingFreq)): (SZAnnot(g).Time + (1*SamplingFreq)));
        end
    end
end

%Find the random segments of baseline data away from stim times or away
%from artefacts
P = 1; %Number of seconds of baseline window
Counter = 1;
RejectionCounter = 1;
while Counter <= NumBaseLines %Keep counting until you have enough valid baselines
    Temp = randi([5*SamplingFreq,(length(DataMask) - ((P+5)*SamplingFreq))]);
    if sum(~DataMask(Temp:(Temp + WindowLength))) == 0
        BaselineTimes(Counter,:) = [Temp, (Temp + WindowLength)];
        Counter = Counter + 1;
        RejectionCounter = 1; %Reset the rejection counter if a piece of baseline is found
    else
        RejectionCounter = RejectionCounter + 1;
    end
    
    %If there are too many rejections, break the function since there has
    %been an error in trying to make the baseline times
    if RejectionCounter >= 100000
        error('Too many rejections occurred in %s',DataStruct.Info.DataFile);
    end
end
end