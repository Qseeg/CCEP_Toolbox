function CCEPProcessRMSBaseline(varargin)
% CCEPProcessRMSBaseline('Name',PatientName,'Number',PatientNumber,'DataFile|EDF',DataFile,'Annot',AnnotationsFile,'Elec',ElectrodeFile,'PulseTime',PulseTimeFile,'NumBase',NumberBaselines)
%Use this to create the Matlab files which will correlate all of the stim
%artefact Metrics which will be used to regress the different tissue types
%against the chosen metrics.

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


%Parse the inputs to the function
for i = 1:2:length(varargin)
    InputStr = varargin{i}; %Pop the inputs into a string to get the information out
    if ~isempty(regexpi(InputStr,'name')) %Find the name of name of the patient
        PatientName = varargin{i+1};
    elseif ~isempty(regexpi(InputStr,'dat')) || ~isempty(regexpi(InputStr,'edf'))  %Find the name of the EDF file (only read in channel info though)
        DataFile = varargin{i+1}; %Get the patient number if given
    elseif ~isempty(regexpi(InputStr,'annot'))  %Find the name of the EDF file (only read in channel info though)
        AnnotFile = which(varargin{i+1}); %Find the file
    elseif ~isempty(regexpi(InputStr,'elec' )) %Find the electrodes file and read from that if given
        ElectrodeFile = varargin{i+1};
    elseif ~isempty(regexpi(InputStr,'pul')) %Find the pulse times file if not given
        PulseTimeFile = varargin{i+1};
    elseif ~isempty(regexpi(InputStr,'num')) || ~isempty(regexpi(InputStr,'base'))%Find the pulse times file if not given
        NumBaselines = varargin{i+1};
    elseif ~isempty(regexpi(InputStr,'ref' )) %Check if a refernce is given to the function, if so then only use that particular data
        Reference = varargin{i+1};
        if ~isempty(regexpi(Reference,'Bi' ))
            Reference = 'Bi';
        elseif ~isempty(regexpi(Reference,'Uni' ))
            Reference = 'Uni';
        elseif ~isempty(regexpi(Reference,'All'))||~isempty(regexpi(Reference,'bot'))
            Reference = 'All';
        end
    end
end

%Default to only Computing bipolar data if no reference is passes to the
%function
if ~exist('Reference','var')
    Reference = 'Bi';
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
elseif isempty(AnnotFile)
    AnnotFile = '';
else
    AnnotFile = which(AnnotFile);
end

%Import the data and make the structure
[DataStruct, Files, StimAnnot] = CCEPEDFBatchDataImport('Patient',PatientName,'DataFile',DataFile,'Reference',Reference,'Electrodes',ElectrodeFile,'Annot',AnnotFile);
SamplingFreq = DataStruct.Info.SamplingFreq;
if ~isempty(StimAnnot)
Baseline = StimAnnot;
Baseline(2:end) = [];
    Baseline(1).Label = 'Baseline';
    BaselineTimes = BaselineTimeGrabber('EDF||File',EDFFile, 'Annotations',AnnotFile,'NumBaseLines',NumBaselines);
    Baseline(1).BaselineTimes = BaselineTimes;
    
else
    Baseline(1).Label = 'Baseline';
    BaselineTimes = BaselineTimeGrabber('EDF||File',EDFFile, 'Annotations',AnnotFile,'NumBaseLines',NumBaselines);
    Baseline(1).BaselineTimes = BaselineTimes;
    Baseline(1).PulseTimes = BaselineTimes;
    Baseline(1).Frequency = 0.5;
    Baseline(1).CoOrds = DataStruct.Uni(1).CoOrds;
    Baseline(1).MNICoOrds = DataStruct.Uni(1).MNICoOrds;
    Baseline(1).Name = DataStruct.Info.Name;
    Baseline(1).Patient = DataStruct.Info.Name;
    Baseline(1).Filtering = [1 0.3*SamplingFreq];
    Baseline(1).Anatomical = DataStruct.Uni(1).Anatomical;
    Baseline(1).TemplateAnatomical = DataStruct.Uni(1).TemplateAnatomical;
    
end


fprintf('Finished Importing Data\n');

%Make a file with an identical name to the EDF you are importing

[P,N,E] = fileparts(DataFile);
DistFileName = sprintf('%s%s%s RMS Values.mat',P,filesep,N);

%Get the electrode structure or file
if ~exist('SamplingFreq','var')
    SamplingFreq = 1000;
end


%*****DON'T WORRY ABOUT THIS SINCE YOU HAVE SWITCHED TO FIR FILTERING
% %Check if a saved file of the filtered data already exists and if so
% %load it instead of filtering the data
% if isempty(which(FilteredFileName))
%     [ImportData, DataStruct] = SubtractionFiltering(DataStruct, ImportData, StimAnnot);
% else
%     load(FilteredFileName);
% end
%
% %If the import data does not exist in filtered form, save the data so
% %you can look at ERPs quickly
% if isempty(which(FilteredFileName))
%     fprintf('Saving Data Since it does not exist yet\n');
%     save(FilteredFileName,'ImportData','DataStruct','-v7.3');
% end
% fprintf('Finished Filtering the Data\n');


%Check if there is an empty pulse train, if this is the case, clear it
Inds = find(arrayfun(@(x) isempty(x.PulseTimes), StimAnnot));
Inds = sort(Inds ,'descend');
for e = 1:length(Inds)
    StimAnnot(Inds(e)) = [];
end

%If there are not valid annotations found, abort processing this file
if isempty(StimAnnot)
   warning(sprintf('No valid annotations or times found for %s\nAborting processing of %s',DataFile,DataFile));
   return;
end

%Pre allocate the final structure
for p = 1:length(StimAnnot)
    %If the unipolar data is required
    if strcmp(Reference,'All') || strcmp(Reference,'Uni')
        %             StimAnnot(p).Uni = DataStruct.Uni;
        for q = 1:length(DataStruct.Uni)
            StimAnnot(p).Uni(q).Label = DataStruct.Uni(q).Label;
            StimAnnot(p).Uni(q).Anatomical = DataStruct.Uni(q).Anatomical;
            StimAnnot(p).Uni(q).TemplateAnatomical = DataStruct.Uni(q).TemplateAnatomical;
            StimAnnot(p).Uni(q).RMS = single(rand(size(StimAnnot(p).PulseTimes,1),1));
            StimAnnot(p).Uni(q).StDev = single(rand(size(StimAnnot(p).PulseTimes,1),1));
            %             StimAnnot(p).Uni(q).Kurtosis = single(rand(size(StimAnnot(p).PulseTimes,1),2));
            StimAnnot(p).Uni(q).ERP = [];
            StimAnnot(p).Uni(q).StimDist = single(rand(1));
        end
    end
    %If the bipolar data is required
    if strcmp(Reference,'All') || strcmp(Reference,'Bi')
        for k = 1:length(DataStruct.Bi)
            StimAnnot(p).Bi(k).Label = DataStruct.Bi(k).Label;
            StimAnnot(p).Bi(k).Anatomical = DataStruct.Bi(k).Anatomical;
            StimAnnot(p).Bi(k).TemplateAnatomical = DataStruct.Bi(k).TemplateAnatomical;
            StimAnnot(p).Bi(k).RMS = single(rand(size(StimAnnot(p).PulseTimes,1),1));
            StimAnnot(p).Bi(k).StDev= single(rand(size(StimAnnot(p).PulseTimes,1),1));
            %             StimAnnot(p).Bi(k).Kurtosis = single(rand(size(StimAnnot(p).PulseTimes,1),2));
            StimAnnot(p).Bi(k).ERP = [];
            StimAnnot(p).Bi(k).StimDist = single(rand(1));
        end
    end
end
fprintf('Finished Preallocation of Data Structure\n');


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


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%          Unipolar Data Distance Calculation      %%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if strcmp(Reference,'All') || strcmp(Reference,'Uni')
    
    fprintf('Computing Unipolar Data \n');
    clearvars ImportData;
    [~,~,~,ImportData] = CCEPEDFBatchDataImport('Patient',PatientName,'DataFile',DataFile,'Reference',Reference,'Electrodes',ElectrodeFile,'Annot',AnnotFile);
    
    %Filter the bipolar data
    HPF = 1; %Cut the data above 1Hz
    LPF = 0.3*SamplingFreq; %Cut the data before the 150 Hz noise harmnoic
    DataStruct.Info(1).Filtering = [HPF LPF];
    B1 = fir1(500,[HPF/(SamplingFreq/2), LPF/(SamplingFreq/2)]); %Bandpass from 1-(0.3*Fs)Hz
    
    fprintf('Beginning filtering unipolar data\n');
    if ~isempty(ParallelPool)
        %Out of memory errors sometimes occur on large files, if the file
        %is too large, process the channels in blocks of (ChanInc)
        try
            parfor e = 1:length(ImportData)
                ImportData(e).Data = double(filtfilt(B1,1,double(ImportData(e).Data))); %Filter with a BPF
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
                    ImportData(e).Data = double(filtfilt(B1,1,double(ImportData(e).Data))); %Filter with a BPF
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
            ImportData(e).Data = double(filtfilt(B1,1,double(ImportData(e).Data))); %Filter with a BPF
            Time = toc;
            ProjectedFinishTime(Time,e,length(ImportData));
        end
    end
    fprintf('\nCompleted filtering unipolar data, beginning processing\n');
    
    
    %Process the RMS distances
    for f = 1:length(StimAnnot)
        tic;
        ERPData = cell(length(StimAnnot(f).Uni),1);
        PlotERP = cell(length(StimAnnot(f).Uni),1);
        BaseData = ERPData;
        [DataTime, StimOffset, BaseOffset] = CCEPStimFreqDataTimeAllocation(DataStruct, StimAnnot, f);
        if ~isempty(ParallelPool)
            parfor r = 1:length(StimAnnot(f).Uni)
                
                %Get each of the ERP traces for the pulse train for each
                %channel and put them in cells for each channel
                for h = 1:length(StimAnnot(f).PulseTimes)
                    ERPData{r}(h,:) = ImportData(r).Data((StimAnnot(f).PulseTimes(h) + round(StimOffset * SamplingFreq)):(StimAnnot(f).PulseTimes(h) + ((DataTime +StimOffset)* SamplingFreq)));   %Put the raw data in an array
                    
                    %If this is the first ERP, shift the baseline segment back to account from the amplifier shut off
                    if h == 1
                        BaseData{r}(h,:) = ImportData(r).Data((StimAnnot(f).PulseTimes(h) - round((2 + DataTime + BaseOffset)* SamplingFreq)):(StimAnnot(f).PulseTimes(h) - ((2+ BaseOffset) * SamplingFreq)));  %Sample 2s before for the 1st ERP in case there is an amplifier shutoff
                        PlotERP{r}(h,:) = ImportData(r).Data((StimAnnot(f).PulseTimes(h) - round((DataTime + BaseOffset)* SamplingFreq)):(StimAnnot(f).PulseTimes(h) + ((DataTime +StimOffset)* SamplingFreq))); %Generate an ERP for
                    else
                        BaseData{r}(h,:) = ImportData(r).Data((StimAnnot(f).PulseTimes(h) - round((DataTime + BaseOffset)* SamplingFreq)):(StimAnnot(f).PulseTimes(h) - (BaseOffset * SamplingFreq)));  %Put the raw data in an array
                        PlotERP{r}(h,:) = ImportData(r).Data((StimAnnot(f).PulseTimes(h) - round((DataTime + BaseOffset)* SamplingFreq)):(StimAnnot(f).PulseTimes(h) + ((DataTime +StimOffset)* SamplingFreq))); %Generate an ERP for the user to be able to plot
                    end
                end
            end
        else
            for r = 1:length(StimAnnot(f).Uni)
                
                %Get each of the ERP traces for the pulse train for each
                %channel and put them in cells for each channel
                for h = 1:length(StimAnnot(f).PulseTimes)
                    ERPData{r}(h,:) = ImportData(r).Data((StimAnnot(f).PulseTimes(h) + round(StimOffset * SamplingFreq)):(StimAnnot(f).PulseTimes(h) + ((DataTime +StimOffset)* SamplingFreq)));   %Put the raw data in an array
                    
                    %If this is the first ERP, shift the baseline segment back to account from the amplifier shut off
                    if h == 1
                        BaseData{r}(h,:) = ImportData(r).Data((StimAnnot(f).PulseTimes(h) - round((2 + DataTime + BaseOffset)* SamplingFreq)):(StimAnnot(f).PulseTimes(h) - ((2+ BaseOffset) * SamplingFreq)));  %Sample 2s before for the 1st ERP in case there is an amplifier shutoff
                        PlotERP{r}(h,:) = ImportData(r).Data((StimAnnot(f).PulseTimes(h) - round((DataTime + BaseOffset)* SamplingFreq)):(StimAnnot(f).PulseTimes(h) + ((DataTime +StimOffset)* SamplingFreq))); %Generate an ERP for
                    else
                        BaseData{r}(h,:) = ImportData(r).Data((StimAnnot(f).PulseTimes(h) - round((DataTime + BaseOffset)* SamplingFreq)):(StimAnnot(f).PulseTimes(h) - (BaseOffset * SamplingFreq)));  %Put the raw data in an array
                        PlotERP{r}(h,:) = ImportData(r).Data((StimAnnot(f).PulseTimes(h) - round((DataTime + BaseOffset)* SamplingFreq)):(StimAnnot(f).PulseTimes(h) + ((DataTime +StimOffset)* SamplingFreq))); %Generate an ERP for the user to be able to plot
                    end
                end
            end
        end
        
        %Call the params structure
        [Params, StimAnnot(f).ParamSummary] = DistanceMetricParams(DataStruct, size(BaseData{1},2));
        
        %Init a blank structure for each stim section
        Struct = StimAnnot(f).Uni;
        if ~isempty(ParallelPool)
            parfor g = 1:length(StimAnnot(f).Uni)
                [DistStruct, ~] = CCEPSimilarityDistanceMetricsRMSOnly(DataStruct,ERPData{g},BaseData{g},Params,0);
                
                %Use the raw data for the StDev and RMS Data and kurtosis
                %             Struct(g).Label = DataStruct.Uni(g).Label;
                %             Struct(g).Anatomical = DataStruct.Uni(g).Anatomical;
                %             Struct(g).TemplateAnatomical = DataStruct.Uni(g).TemplateAnatomical;
                Struct(g).ERP = single(PlotERP{g});
                Struct(g).RMS = single(DistStruct.RMS);
                Struct(g).StDev = single(DistStruct.StDev);
                %             Struct(g).Kurtosis = single(DistStruct.Kurtosis);
                %             Struct(g).StimDist = single(pdist2(DataStruct.Uni(g).CoOrds,StimAnnot(f).CoOrds, 'euclidean'));
                Struct(g).StimDist = single(CoOrdDist(DataStruct.Uni(g).CoOrds,StimAnnot(f).CoOrds));
            end
        else
            for g = 1:length(StimAnnot(f).Uni)
                [DistStruct, ~] = CCEPSimilarityDistanceMetricsRMSOnly(DataStruct,ERPData{g},BaseData{g},Params,0);
                
                %Use the raw data for the StDev and RMS Data and kurtosis
                %             Struct(g).Label = DataStruct.Uni(g).Label;
                %             Struct(g).Anatomical = DataStruct.Uni(g).Anatomical;
                %             Struct(g).TemplateAnatomical = DataStruct.Uni(g).TemplateAnatomical;
                Struct(g).ERP = single(PlotERP{g});
                Struct(g).RMS = single(DistStruct.RMS);
                Struct(g).StDev = single(DistStruct.StDev);
                %             Struct(g).Kurtosis = single(DistStruct.Kurtosis);
                %             Struct(g).StimDist = single(pdist2(DataStruct.Uni(g).CoOrds,StimAnnot(f).CoOrds, 'euclidean'));
                Struct(g).StimDist = single(CoOrdDist(DataStruct.Uni(g).CoOrds,StimAnnot(f).CoOrds));
            end
        end

        StimAnnot(f).Uni = Struct;
        StimAnnot(f).ERPIndexes = (-DataTime*SamplingFreq):(DataTime*SamplingFreq);
        Time = toc;
        ProjectedFinishTime(Time,f,length(StimAnnot));
    end
    
    
    %Process the Unipolar baseline
    
    
    %Save to a  file after all electrodes are finished
    fprintf('Finished Computing Unipolar Distances\n');
    fprintf('Saving Unipolar Segment of File\n');
    save(DistFileName, 'StimAnnot','-v7.3');
    fprintf('Completed Unipolar Results File Save\n');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%           Bipolar Data Distance Calculation      %%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if strcmp(Reference,'All') || strcmp(Reference,'Bi')
    
    fprintf('Computing Bipolar Data \n');
    fprintf('Importing the Unipolar data and converting into Bipolar\n');
    clearvars ImportData;
    [~,~,~,ImportData] = CCEPEDFBatchDataImport('Patient',PatientName,'DataFile',DataFile,'Reference',Reference,'Electrodes',ElectrodeFile,'Annot',AnnotFile);
    ImportData = BipoImportDataConvert(ImportData,DataStruct);
    
    %Filter the bipolar data
    HPF = 1; %Cut the data above 1Hz
    LPF = 0.3*SamplingFreq; %Cut the data before the 150 Hz noise harmnoic
    DataStruct.Info(1).Filtering = [HPF LPF];
    B1 = fir1(500,[HPF/(SamplingFreq/2), LPF/(SamplingFreq/2)]); %Bandpass from 1-(0.3*Fs)Hz
    
    fprintf('Beginning filtering bipolar data\n');
    if ~isempty(ParallelPool)
        %Out of memory errors sometimes occur on large files, if the file
        %is too large, process the channels in blocks of (ChanInc)
        try
            parfor e = 1:length(ImportData)
                ImportData(e).Data = double(filtfilt(B1,1,double(ImportData(e).Data))); %Filter with a BPF
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
                    ImportData(e).Data = double(filtfilt(B1,1,double(ImportData(e).Data))); %Filter with a BPF
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
            ImportData(e).Data = double(filtfilt(B1,1,double(ImportData(e).Data))); %Filter with a BPF
            Time = toc;
            ProjectedFinishTime(Time,e,length(ImportData));
        end
    end
    fprintf('\nCompleted filtering bipolar data, beginning processing\n');
    
    %Process the RMS distances
    for f = 1:length(StimAnnot)
        tic;
        ERPData = cell(length(StimAnnot(f).Bi),1);
        PlotERP = cell(length(StimAnnot(f).Bi),1);
        BaseData = ERPData;
        [DataTime, StimOffset, BaseOffset] = CCEPStimFreqDataTimeAllocation(DataStruct, StimAnnot, f);
        if ~isempty(ParallelPool)
            parfor r = 1:length(StimAnnot(f).Bi)
                
                %Get each of the ERP traces for the pulse train for each
                %channel and put them in cells for each channel
                for h = 1:length(StimAnnot(f).PulseTimes)
                    ERPData{r}(h,:) = ImportData(r).Data((StimAnnot(f).PulseTimes(h) + round(StimOffset * SamplingFreq)):(StimAnnot(f).PulseTimes(h) + ((DataTime +StimOffset)* SamplingFreq)));   %Put the raw data in an array
                    
                    %If this is the first ERP, shift the baseline segment back to account from the amplifier shut off
                    if h == 1
                        BaseData{r}(h,:) = ImportData(r).Data((StimAnnot(f).PulseTimes(h) - round((2 + DataTime + BaseOffset)* SamplingFreq)):(StimAnnot(f).PulseTimes(h) - ((2+ BaseOffset) * SamplingFreq)));  %Sample 2s before for the 1st ERP in case there is an amplifier shutoff
                        PlotERP{r}(h,:) = ImportData(r).Data((StimAnnot(f).PulseTimes(h) - round((DataTime + BaseOffset)* SamplingFreq)):(StimAnnot(f).PulseTimes(h) + ((DataTime +StimOffset)* SamplingFreq))); %Generate an ERP for
                    else
                        BaseData{r}(h,:) = ImportData(r).Data((StimAnnot(f).PulseTimes(h) - round((DataTime + BaseOffset)* SamplingFreq)):(StimAnnot(f).PulseTimes(h) - (BaseOffset * SamplingFreq)));  %Put the raw data in an array
                        PlotERP{r}(h,:) = ImportData(r).Data((StimAnnot(f).PulseTimes(h) - round((DataTime + BaseOffset)* SamplingFreq)):(StimAnnot(f).PulseTimes(h) + ((DataTime +StimOffset)* SamplingFreq))); %Generate an ERP for the user to be able to plot
                    end
                end
            end
        else
            for r = 1:length(StimAnnot(f).Bi)
                
                %Get each of the ERP traces for the pulse train for each
                %channel and put them in cells for each channel
                for h = 1:length(StimAnnot(f).PulseTimes)
                    ERPData{r}(h,:) = ImportData(r).Data((StimAnnot(f).PulseTimes(h) + round(StimOffset * SamplingFreq)):(StimAnnot(f).PulseTimes(h) + ((DataTime +StimOffset)* SamplingFreq)));   %Put the raw data in an array
                    
                    %If this is the first ERP, shift the baseline segment back to account from the amplifier shut off
                    if h == 1
                        BaseData{r}(h,:) = ImportData(r).Data((StimAnnot(f).PulseTimes(h) - round((2 + DataTime + BaseOffset)* SamplingFreq)):(StimAnnot(f).PulseTimes(h) - ((2+ BaseOffset) * SamplingFreq)));  %Sample 2s before for the 1st ERP in case there is an amplifier shutoff
                        PlotERP{r}(h,:) = ImportData(r).Data((StimAnnot(f).PulseTimes(h) - round((DataTime + BaseOffset)* SamplingFreq)):(StimAnnot(f).PulseTimes(h) + ((DataTime +StimOffset)* SamplingFreq))); %Generate an ERP for
                    else
                        BaseData{r}(h,:) = ImportData(r).Data((StimAnnot(f).PulseTimes(h) - round((DataTime + BaseOffset)* SamplingFreq)):(StimAnnot(f).PulseTimes(h) - (BaseOffset * SamplingFreq)));  %Put the raw data in an array
                        PlotERP{r}(h,:) = ImportData(r).Data((StimAnnot(f).PulseTimes(h) - round((DataTime + BaseOffset)* SamplingFreq)):(StimAnnot(f).PulseTimes(h) + ((DataTime +StimOffset)* SamplingFreq))); %Generate an ERP for the user to be able to plot
                    end
                end
            end
        end
        %Call the params structure
        [Params, StimAnnot(f).ParamSummary] = DistanceMetricParams(DataStruct, size(BaseData{1},2));
        %Init a blank structure for each stim section
        Struct = StimAnnot(f).Bi;
        if ~isempty(ParallelPool)
            parfor g = 1:length(StimAnnot(f).Bi)
                [DistStruct, ~] = CCEPSimilarityDistanceMetricsRMSOnly(DataStruct,ERPData{g},BaseData{g},Params,0);
                
                %Use the raw data for the StDev and RMS Data and kurtosis
                %             Struct(g).Label = DataStruct.Uni(g).Label;
                %             Struct(g).Anatomical = DataStruct.Uni(g).Anatomical;
                %             Struct(g).TemplateAnatomical = DataStruct.Uni(g).TemplateAnatomical;
                Struct(g).ERP = single(PlotERP{g});
                Struct(g).RMS = single(DistStruct.RMS);
                Struct(g).StDev = single(DistStruct.StDev);
                %             Struct(g).Kurtosis = single(DistStruct.Kurtosis);
                %             Struct(g).StimDist = single(pdist2(DataStruct.Uni(g).CoOrds,StimAnnot(f).CoOrds, 'euclidean'));
                Struct(g).StimDist = single(CoOrdDist(DataStruct.Bi(g).CoOrds,StimAnnot(f).CoOrds));
            end
        else
            for g = 1:length(StimAnnot(f).Bi)
                [DistStruct, ~] = CCEPSimilarityDistanceMetricsRMSOnly(DataStruct,ERPData{g},BaseData{g},Params,0);
                
                %Use the raw data for the StDev and RMS Data and kurtosis
                %             Struct(g).Label = DataStruct.Uni(g).Label;
                %             Struct(g).Anatomical = DataStruct.Uni(g).Anatomical;
                %             Struct(g).TemplateAnatomical = DataStruct.Uni(g).TemplateAnatomical;
                Struct(g).ERP = single(PlotERP{g});
                Struct(g).RMS = single(DistStruct.RMS);
                Struct(g).StDev = single(DistStruct.StDev);
                %             Struct(g).Kurtosis = single(DistStruct.Kurtosis);
                %             Struct(g).StimDist = single(pdist2(DataStruct.Uni(g).CoOrds,StimAnnot(f).CoOrds, 'euclidean'));
                Struct(g).StimDist = single(CoOrdDist(DataStruct.Bi(g).CoOrds,StimAnnot(f).CoOrds));
            end
        end
        
        StimAnnot(f).Bi = Struct;
        StimAnnot(f).ERPIndexes = (-DataTime*SamplingFreq):(DataTime*SamplingFreq);
        
        Time = toc;
        ProjectedFinishTime(Time,f,length(StimAnnot));
    end
    
    %Save to a  file after all electrodes are finished
    fprintf('Finished Computing Bipolar Distances\n');
    fprintf('Saving Distance File\n');
    save(DistFileName, 'StimAnnot','DataStruct','-v7.3');
    fprintf('Completed File Save\n');
end