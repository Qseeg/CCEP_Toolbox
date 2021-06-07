function CCEPProcessRMSFile(varargin)
% CCEPProcessRMSFile('Name',PatientName,'Number',PatientNumber,'DataFile|EDF',DataFile,'Annot',AnnotationsFile,'Elec',ElectrodeFile,'PulseTime',PulseTimeFile)
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
    %Look to see if there is a file created with the AnnotEditor
    [P,N,E] = fileparts(which(DataFile));
    TempName = which(sprintf('%s Annotations.mat',N));
    
    %If there is an altered annotations file, load that in
    if ~isempty(TempName)
        AnnotFile = TempName;
        load(AnnotFile);
        if ~isempty(PulseTimes)
            AllPulses = PulseTimes;
        end
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
        if ~isempty(PulseTimes)
            AllPulses = PulseTimes;
        end
    else
        AnnotFile = '';
    end
end

%Import the data and make the structure
if ~exist('Annotations','var')
[DataStruct, Files, StimAnnot, ImportData, Annotations] = CCEPEDFBatchDataImport('Patient',PatientName,'DataFile',DataFile,'Reference',Reference,'Electrodes',ElectrodeFile,'Annot',AnnotFile);
else
   [DataStruct, Files, StimAnnot, ImportData] = CCEPEDFBatchDataImport('Patient',PatientName,'DataFile',DataFile,'Reference',Reference,'Electrodes',ElectrodeFile,'Annot',AnnotFile); 
end
fprintf('Finished Importing Data\n');

%Make a file with an identical name to the EDF you are importing

[P,N,E] = fileparts(DataFile);
DistFileName = sprintf('%s%s%s RMS Values.mat',P,filesep,N);

%Get the electrode structure or file
if ~exist('SamplingFreq','var')
    SamplingFreq = 1000;
end


%Create a distribution of baseline times so that a control distribution of
%RMS values can be computed
NumBaselines = 300;
if ~isempty(StimAnnot)
    Baseline = StimAnnot;
    Baseline(2:end) = [];
    Baseline(1).Label = 'Baseline';
    BaselineTimes = CCEPBaselineTimeGrabber('Info',DataStruct, 'Stim',StimAnnot,'Annotations',Annotations,'Signal',ImportData(1),'NumBaseLines',NumBaselines,'Window',(0.2*SamplingFreq));
    Baseline(1).PulseTimes = single(round(mean(BaselineTimes,2)));
    Baseline(1).BaselineTimes = BaselineTimes;
    
else
    Baseline(1).Label = 'Baseline';
    BaselineTimes = CCEPBaselineTimeGrabber('Info',DataStruct, 'Stim',StimAnnot,'Annotations',Annotations,'Signal',ImportData(1),'NumBaseLines',NumBaselines,'Window',(0.2*SamplingFreq));
    Baseline(1).BaselineTimes = BaselineTimes;
    Baseline(1).PulseTimes = single(round(mean(BaselineTimes,2)));
    Baseline(1).Frequency = 0.5;
    Baseline(1).CoOrds = DataStruct.Uni(1).CoOrds;
    Baseline(1).MNICoOrds = DataStruct.Uni(1).MNICoOrds;
    Baseline(1).Name = DataStruct.Info.Name;
    Baseline(1).Patient = DataStruct.Info.Name;
    Baseline(1).Filtering = [1 0.3*SamplingFreq];
    Baseline(1).Anatomical = DataStruct.Uni(1).Anatomical;
    Baseline(1).TemplateAnatomical = DataStruct.Uni(1).TemplateAnatomical;
    
end


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
            %   StimAnnot(p).Uni(q).Kurtosis = single(rand(size(StimAnnot(p).PulseTimes,1),2));
            %             StimAnnot(p).Uni(q).ERP = [];
            StimAnnot(p).Uni(q).StimDist = single(rand(1));
        end
        
        %Also allocate the baseline data
        Baseline(1).Uni(q).Label = DataStruct.Uni(q).Label;
        Baseline(1).Uni(q).Anatomical = DataStruct.Uni(q).Anatomical;
        Baseline(1).Uni(q).TemplateAnatomical = DataStruct.Uni(q).TemplateAnatomical;
        Baseline(1).Uni(q).RMS = single(rand(NumBaselines,1));
        Baseline(1).Uni(q).StDev = single(rand(NumBaselines,1));
        %  Baseline(1).Uni(q).Kurtosis = single(rand(NumBaselines,2));
        %         Baseline(1).Uni(q).ERP = [];
        Baseline(1).Uni(q).StimDist = single(rand(1));
    end
    
    %If the bipolar data is required
    if strcmp(Reference,'All') || strcmp(Reference,'Bi')
        for k = 1:length(DataStruct.Bi)
            StimAnnot(p).Bi(k).Label = DataStruct.Bi(k).Label;
            StimAnnot(p).Bi(k).Anatomical = DataStruct.Bi(k).Anatomical;
            StimAnnot(p).Bi(k).TemplateAnatomical = DataStruct.Bi(k).TemplateAnatomical;
            StimAnnot(p).Bi(k).RMS = single(rand(size(StimAnnot(p).PulseTimes,1),1));
            StimAnnot(p).Bi(k).StDev= single(rand(size(StimAnnot(p).PulseTimes,1),1));
            %   StimAnnot(p).Bi(k).Kurtosis = single(rand(size(StimAnnot(p).PulseTimes,1),2));
            %             StimAnnot(p).Bi(k).ERP = [];
            StimAnnot(p).Bi(k).StimDist = single(rand(1));
        end
        %Also allocate the baseline data
        Baseline(1).Bi(k).Label = DataStruct.Bi(k).Label;
        Baseline(1).Bi(k).Anatomical = DataStruct.Bi(k).Anatomical;
        Baseline(1).Bi(k).TemplateAnatomical = DataStruct.Bi(k).TemplateAnatomical;
        Baseline(1).Bi(k).RMS = single(rand(NumBaselines,1));
        Baseline(1).Bi(k).StDev = single(rand(NumBaselines,1));
        %   Baseline(1).Bi(k).Kurtosis = single(rand(NumBaselines,2));
        %         Baseline(1).Bi(k).ERP = [];
        Baseline(1).Bi(k).StimDist = single(rand(1));
    end   
end
fprintf('Finished Preallocation of Data Structure\n');







%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%%%%%      Begin Data calculation    %%%%%%%%
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
    if ~exist('ImportData','var')
        [~,~,~,ImportData] = CCEPEDFBatchDataImport('Patient',PatientName,'DataFile',DataFile,'Struct',DataStruct,'Reference',Reference,'Electrodes',ElectrodeFile,'Annot',AnnotFile,'Labels',{DataStruct.Uni.Label});
    end
    
    %Filter the unipolar data
    [DataStruct, ImportData] = CCEPFilterFunction(DataStruct,ImportData,'Uni');
    fprintf('\nBeginning unipolar processing\n');
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%     Process  the unipolar RMS ERPs      %%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    for f = 1:length(StimAnnot)
        tic;
        ERPData = cell(length(StimAnnot(f).Uni),1);
        %         PlotERP = cell(length(StimAnnot(f).Uni),1);
        BaseData = ERPData;
        PlotERPInds = BaseData;
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
                        %                         PlotERP{r}(h,:) = horzcat((ImportData(r).Data((StimAnnot(f).PulseTimes(h) - round((2 + DataTime + BaseOffset)* SamplingFreq)):(StimAnnot(f).PulseTimes(h)- round((2)* SamplingFreq)))),...
                        %                             (ImportData(r).Data((StimAnnot(f).PulseTimes(h)+1):(StimAnnot(f).PulseTimes(h) + ((DataTime +StimOffset)* SamplingFreq)))));
                        PlotERPInds{r}(h,:) = horzcat((StimAnnot(f).PulseTimes(h) - round((2 + DataTime + BaseOffset)* SamplingFreq)):(StimAnnot(f).PulseTimes(h)- round((2)* SamplingFreq)),...
                            ((StimAnnot(f).PulseTimes(h)+1):(StimAnnot(f).PulseTimes(h) + ((DataTime +StimOffset)* SamplingFreq))));
                    else
                        BaseData{r}(h,:) = ImportData(r).Data((StimAnnot(f).PulseTimes(h) - round((DataTime + BaseOffset)* SamplingFreq)):(StimAnnot(f).PulseTimes(h) - (BaseOffset * SamplingFreq)));  %Put the raw data in an array
                        %                         PlotERP{r}(h,:) = ImportData(r).Data((StimAnnot(f).PulseTimes(h) - round((DataTime + BaseOffset)* SamplingFreq)):(StimAnnot(f).PulseTimes(h) + ((DataTime +StimOffset)* SamplingFreq))); %Generate an ERP for the user to be able to plot
                        PlotERPInds{r}(h,:) = (StimAnnot(f).PulseTimes(h) - round((DataTime + BaseOffset)* SamplingFreq)):(StimAnnot(f).PulseTimes(h) + ((DataTime +StimOffset)* SamplingFreq)); %Generate an ERP for the user to be able to plot
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
                        %                         PlotERP{r}(h,:) = horzcat((ImportData(r).Data((StimAnnot(f).PulseTimes(h) - round((2 + DataTime + BaseOffset)* SamplingFreq)):(StimAnnot(f).PulseTimes(h)- round((2)* SamplingFreq)))),...
                        %                             (ImportData(r).Data((StimAnnot(f).PulseTimes(h)+1):(StimAnnot(f).PulseTimes(h) + ((DataTime +StimOffset)* SamplingFreq)))));
                        PlotERPInds{r}(h,:) = horzcat((StimAnnot(f).PulseTimes(h) - round((2 + DataTime + BaseOffset)* SamplingFreq)):(StimAnnot(f).PulseTimes(h)- round((2)* SamplingFreq)),...
                            ((StimAnnot(f).PulseTimes(h)+1):(StimAnnot(f).PulseTimes(h) + ((DataTime +StimOffset)* SamplingFreq))));
                    else
                        BaseData{r}(h,:) = ImportData(r).Data((StimAnnot(f).PulseTimes(h) - round((DataTime + BaseOffset)* SamplingFreq)):(StimAnnot(f).PulseTimes(h) - (BaseOffset * SamplingFreq)));  %Put the raw data in an array
                        %                         PlotERP{r}(h,:) = ImportData(r).Data((StimAnnot(f).PulseTimes(h) - round((DataTime + BaseOffset)* SamplingFreq)):(StimAnnot(f).PulseTimes(h) + ((DataTime +StimOffset)* SamplingFreq))); %Generate an ERP for the user to be able to plot
                        PlotERPInds{r}(h,:) = (StimAnnot(f).PulseTimes(h) - round((DataTime + BaseOffset)* SamplingFreq)):(StimAnnot(f).PulseTimes(h) + ((DataTime +StimOffset)* SamplingFreq)); %Generate an ERP for the user to be able to plot
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
                [DistStruct, ~] = CCEPSimilarityDistanceMetricsRMSOnly(DataStruct,ERPData{g},BaseData{g});
                
                %Use the raw data for the StDev and RMS Data and kurtosis
                Struct(g).Label = DataStruct.Uni(g).Label;
                Struct(g).Anatomical = DataStruct.Uni(g).Anatomical;
                Struct(g).TemplateAnatomical = DataStruct.Uni(g).TemplateAnatomical;
                %             Struct(g).ERP = single(PlotERP{g});
                Struct(g).RMS = single(DistStruct.RMS);
                Struct(g).StDev = single(DistStruct.StDev);
                %             Struct(g).Kurtosis = single(DistStruct.Kurtosis);
                %             Struct(g).StimDist = single(pdist2(DataStruct.Uni(g).CoOrds,StimAnnot(f).CoOrds, 'euclidean'));
                Struct(g).StimDist = single(CoOrdDist(DataStruct.Uni(g).CoOrds,StimAnnot(f).CoOrds));
            end
        else
            for g = 1:length(StimAnnot(f).Uni)
                [DistStruct, ~] = CCEPSimilarityDistanceMetricsRMSOnly(DataStruct,ERPData{g},BaseData{g});
                
                %Use the raw data for the StDev and RMS Data and kurtosis
                Struct(g).Label = DataStruct.Uni(g).Label;
                Struct(g).Anatomical = DataStruct.Uni(g).Anatomical;
                Struct(g).TemplateAnatomical = DataStruct.Uni(g).TemplateAnatomical;
                %             Struct(g).ERP = single(PlotERP{g});
                Struct(g).RMS = single(DistStruct.RMS);
                Struct(g).StDev = single(DistStruct.StDev);
                %             Struct(g).Kurtosis = single(DistStruct.Kurtosis);
                %             Struct(g).StimDist = single(pdist2(DataStruct.Uni(g).CoOrds,StimAnnot(f).CoOrds, 'euclidean'));
                Struct(g).StimDist = single(CoOrdDist(DataStruct.Uni(g).CoOrds,StimAnnot(f).CoOrds));
            end
        end
        
        StimAnnot(f).Uni = Struct;
        StimAnnot(f).PlotERPIndexes = -((DataTime + BaseOffset)*SamplingFreq):((DataTime+StimOffset)*SamplingFreq);
        StimAnnot(f).ERPDataInds = PlotERPInds{1};
        Time = toc;
        ProjectedFinishTime(Time,f,length(StimAnnot));
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%   Process  the unipolar RMS baselines   %%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    for f = 1:length(Baseline)
        tic;
        ERPData = cell(length(Baseline(f).Uni),1);
        %         PlotERP = cell(length(Baseline(f).Uni),1);
        BaseData = ERPData;
        PlotERPInds = BaseData;
        [DataTime, StimOffset, BaseOffset] = CCEPStimFreqDataTimeAllocation(DataStruct, Baseline, f);
        if ~isempty(ParallelPool)
            parfor r = 1:length(Baseline(f).Uni)
                
                %Get each of the ERP traces for the pulse train for each
                %channel and put them in cells for each channel
                for h = 1:length(Baseline(f).PulseTimes)
                    ERPData{r}(h,:) = ImportData(r).Data((Baseline(f).PulseTimes(h) + round(StimOffset * SamplingFreq)):(Baseline(f).PulseTimes(h) + ((DataTime +StimOffset)* SamplingFreq)));   %Put the raw data in an array
                    BaseData{r}(h,:) = ImportData(r).Data((Baseline(f).PulseTimes(h) - round((DataTime + BaseOffset)* SamplingFreq)):(Baseline(f).PulseTimes(h) - (BaseOffset * SamplingFreq)));  %Put the raw data in an array
                    %                     PlotERP{r}(h,:) = ImportData(r).Data((Baseline(f).PulseTimes(h) - round((DataTime + BaseOffset)* SamplingFreq)):(Baseline(f).PulseTimes(h) + ((DataTime)* SamplingFreq))); %Generate an ERP for the user to be able to plot
                    PlotERPInds{r}(h,:) = (Baseline(f).PulseTimes(h) - round((DataTime + BaseOffset)* SamplingFreq)):(Baseline(f).PulseTimes(h) + ((DataTime +StimOffset)* SamplingFreq)); %Generate an ERP for the user to be able to plot
                end
            end
        else
            for r = 1:length(Baseline(f).Uni)
                
                %Get each of the ERP traces for the pulse train for each
                %channel and put them in cells for each channel
                for h = 1:length(Baseline(f).PulseTimes)
                    ERPData{r}(h,:) = ImportData(r).Data((Baseline(f).PulseTimes(h) + round(StimOffset * SamplingFreq)):(Baseline(f).PulseTimes(h) + ((DataTime +StimOffset)* SamplingFreq)));   %Put the raw data in an array
                    BaseData{r}(h,:) = ImportData(r).Data((Baseline(f).PulseTimes(h) - round((DataTime + BaseOffset)* SamplingFreq)):(Baseline(f).PulseTimes(h) - (BaseOffset * SamplingFreq)));  %Put the raw data in an array
                    %                     PlotERP{r}(h,:) = ImportData(r).Data((Baseline(f).PulseTimes(h) - round((DataTime + BaseOffset)* SamplingFreq)):(Baseline(f).PulseTimes(h) + ((DataTime)* SamplingFreq))); %Generate an ERP for the user to be able to plot
                    PlotERPInds{r}(h,:) = (Baseline(f).PulseTimes(h) - round((DataTime + BaseOffset)* SamplingFreq)):(Baseline(f).PulseTimes(h) + ((DataTime +StimOffset)* SamplingFreq)); %Generate an ERP for the user to be able to plot
                end
            end
        end
        
        %Call the params structure
        [Params, Baseline(f).ParamSummary] = DistanceMetricParams(DataStruct, size(BaseData{1},2));
        
        %Init a blank structure for each stim section
        Struct = Baseline(f).Uni;
        if ~isempty(ParallelPool)
            parfor g = 1:length(Baseline(f).Uni)
                [DistStruct, ~] = CCEPSimilarityDistanceMetricsRMSOnly(DataStruct,ERPData{g},BaseData{g});
                
                %Use the raw data for the StDev and RMS Data and kurtosis
                Struct(g).Label = DataStruct.Uni(g).Label;
                Struct(g).Anatomical = DataStruct.Uni(g).Anatomical;
                Struct(g).TemplateAnatomical = DataStruct.Uni(g).TemplateAnatomical;
                %             Struct(g).ERP = single(PlotERP{g});
                Struct(g).RMS = single(DistStruct.RMS);
                Struct(g).StDev = single(DistStruct.StDev);
                %             Struct(g).Kurtosis = single(DistStruct.Kurtosis);
                %             Struct(g).StimDist = single(pdist2(DataStruct.Uni(g).CoOrds,Baseline(f).CoOrds, 'euclidean'));
                Struct(g).StimDist = single(CoOrdDist(DataStruct.Uni(g).CoOrds,Baseline(f).CoOrds));
            end
        else
            for g = 1:length(Baseline(f).Uni)
                [DistStruct, ~] = CCEPSimilarityDistanceMetricsRMSOnly(DataStruct,ERPData{g},BaseData{g});
                
                %Use the raw data for the StDev and RMS Data and kurtosis
                Struct(g).Label = DataStruct.Uni(g).Label;
                Struct(g).Anatomical = DataStruct.Uni(g).Anatomical;
                Struct(g).TemplateAnatomical = DataStruct.Uni(g).TemplateAnatomical;
                %             Struct(g).ERP = single(PlotERP{g});
                Struct(g).RMS = single(DistStruct.RMS);
                Struct(g).StDev = single(DistStruct.StDev);
                %             Struct(g).Kurtosis = single(DistStruct.Kurtosis);
                %             Struct(g).StimDist = single(pdist2(DataStruct.Uni(g).CoOrds,Baseline(f).CoOrds, 'euclidean'));
                Struct(g).StimDist = single(CoOrdDist(DataStruct.Uni(g).CoOrds,Baseline(f).CoOrds));
            end
        end
        
        Baseline(f).Uni = Struct;
        Baseline(f).PlotERPIndexes = -((DataTime + BaseOffset)*SamplingFreq):((DataTime+StimOffset)*SamplingFreq);
        Baseline(f).ERPDataInds = PlotERPInds{1};
        Time = toc;
        ProjectedFinishTime(Time,length(StimAnnot)+1,length(StimAnnot)+1);
    end
    
    
    %Save to a  file after all electrodes are finished
    fprintf('Finished Computing Unipolar Distances\n');
    fprintf('Saving Unipolar Segment of File\n');
    save(DistFileName, 'DataStruct','StimAnnot','Baseline','-v6');
    fprintf('Completed Unipolar Results File Save\n');
end




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%           Bipolar Data Distance Calculation      %%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if strcmp(Reference,'All') || strcmp(Reference,'Bi')
    
    fprintf('Computing Bipolar Data \n');
    fprintf('Importing the Unipolar data and converting into Bipolar\n');
    
    %Decide whether to re-import the data, or to keep processing
    if ~exist('ImportData','var') && strcmp(Reference,'Bi')
        [~,~,~,ImportData] = CCEPEDFBatchDataImport('Patient',PatientName,'DataFile',DataFile,'Struct',DataStruct,'Reference',Reference,'Electrodes',ElectrodeFile,'Annot',AnnotFile,'Labels',{DataStruct.Uni.Label});
        
    elseif exist('ImportData','var') && strcmp(Reference,'Bi') %If the unipolar data was imported, but not yet filtered
        ImportData = CCEPBipoImportDataConvert(ImportData,DataStruct);
        
    elseif exist('ImportData','var') && (strcmp(Reference,'Uni') || strcmp(Reference,'All')) %If the unipolar data was filtered, re-import it
        clearvars ImportData;
        [~,~,~,ImportData] = CCEPEDFBatchDataImport('Patient',PatientName,'DataFile',DataFile,'Struct',DataStruct,'Reference',Reference,'Electrodes',ElectrodeFile,'Annot',AnnotFile,'Labels',{DataStruct.Uni.Label});
        ImportData = CCEPBipoImportDataConvert(ImportData,DataStruct);
    end
    
    %Filter the data
    [DataStruct, ImportData] = CCEPFilterFunction(DataStruct,ImportData,'Bi');
    fprintf('\nBeginning bipolar processing\n');
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%     Process  the Bipolar RMS ERPs       %%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    for f = 1:length(StimAnnot)
        tic;
        ERPData = cell(length(StimAnnot(f).Bi),1);
        %         PlotERP = cell(length(StimAnnot(f).Bi),1);
        BaseData = ERPData;
        PlotERPInds = BaseData;
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
                        %                         PlotERP{r}(h,:) = horzcat((ImportData(r).Data((StimAnnot(f).PulseTimes(h) - round((2 + DataTime + BaseOffset)* SamplingFreq)):(StimAnnot(f).PulseTimes(h)- round((2)* SamplingFreq)))),...
                        %                             (ImportData(r).Data((StimAnnot(f).PulseTimes(h)+1):(StimAnnot(f).PulseTimes(h) + ((DataTime +StimOffset)* SamplingFreq)))));
                        PlotERPInds{r}(h,:) = horzcat((StimAnnot(f).PulseTimes(h) - round((2 + DataTime + BaseOffset)* SamplingFreq)):(StimAnnot(f).PulseTimes(h)- round((2)* SamplingFreq)),...
                            ((StimAnnot(f).PulseTimes(h)+1):(StimAnnot(f).PulseTimes(h) + ((DataTime +StimOffset)* SamplingFreq))));
                    else
                        BaseData{r}(h,:) = ImportData(r).Data((StimAnnot(f).PulseTimes(h) - round((DataTime + BaseOffset)* SamplingFreq)):(StimAnnot(f).PulseTimes(h) - (BaseOffset * SamplingFreq)));  %Put the raw data in an array
                        %                         PlotERP{r}(h,:) = ImportData(r).Data((StimAnnot(f).PulseTimes(h) - round((DataTime + BaseOffset)* SamplingFreq)):(StimAnnot(f).PulseTimes(h) + ((DataTime +StimOffset)* SamplingFreq))); %Generate an ERP for the user to be able to plot
                        PlotERPInds{r}(h,:) = (StimAnnot(f).PulseTimes(h) - round((DataTime + BaseOffset)* SamplingFreq)):(StimAnnot(f).PulseTimes(h) + ((DataTime +StimOffset)* SamplingFreq)); %Generate an ERP for the user to be able to plot
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
                        %                         PlotERP{r}(h,:) = horzcat((ImportData(r).Data((StimAnnot(f).PulseTimes(h) - round((2 + DataTime + BaseOffset)* SamplingFreq)):(StimAnnot(f).PulseTimes(h)- round((2)* SamplingFreq)))),...
                        %                             (ImportData(r).Data((StimAnnot(f).PulseTimes(h)+1):(StimAnnot(f).PulseTimes(h) + ((DataTime +StimOffset)* SamplingFreq)))));
                        PlotERPInds{r}(h,:) = horzcat((StimAnnot(f).PulseTimes(h) - round((2 + DataTime + BaseOffset)* SamplingFreq)):(StimAnnot(f).PulseTimes(h)- round((2)* SamplingFreq)),...
                            ((StimAnnot(f).PulseTimes(h)+1):(StimAnnot(f).PulseTimes(h) + ((DataTime +StimOffset)* SamplingFreq))));
                    else
                        BaseData{r}(h,:) = ImportData(r).Data((StimAnnot(f).PulseTimes(h) - round((DataTime + BaseOffset)* SamplingFreq)):(StimAnnot(f).PulseTimes(h) - (BaseOffset * SamplingFreq)));  %Put the raw data in an array
                        %                         PlotERP{r}(h,:) = ImportData(r).Data((StimAnnot(f).PulseTimes(h) - round((DataTime + BaseOffset)* SamplingFreq)):(StimAnnot(f).PulseTimes(h) + ((DataTime +StimOffset)* SamplingFreq))); %Generate an ERP for the user to be able to plot
                        PlotERPInds{r}(h,:) = (StimAnnot(f).PulseTimes(h) - round((DataTime + BaseOffset)* SamplingFreq)):(StimAnnot(f).PulseTimes(h) + ((DataTime +StimOffset)* SamplingFreq)); %Generate an ERP for the user to be able to plot
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
                [DistStruct, ~] = CCEPSimilarityDistanceMetricsRMSOnly(DataStruct,ERPData{g},BaseData{g});
                
                %Use the raw data for the StDev and RMS Data and kurtosis
                Struct(g).Label = DataStruct.Uni(g).Label;
                Struct(g).Anatomical = DataStruct.Uni(g).Anatomical;
                Struct(g).TemplateAnatomical = DataStruct.Uni(g).TemplateAnatomical;
                %             Struct(g).ERP = single(PlotERP{g});
                Struct(g).RMS = single(DistStruct.RMS);
                Struct(g).StDev = single(DistStruct.StDev);
                %             Struct(g).Kurtosis = single(DistStruct.Kurtosis);
                %             Struct(g).StimDist = single(pdist2(DataStruct.Uni(g).CoOrds,StimAnnot(f).CoOrds, 'euclidean'));
                Struct(g).StimDist = single(CoOrdDist(DataStruct.Bi(g).CoOrds,StimAnnot(f).CoOrds));
            end
        else
            for g = 1:length(StimAnnot(f).Bi)
                [DistStruct, ~] = CCEPSimilarityDistanceMetricsRMSOnly(DataStruct,ERPData{g},BaseData{g});
                
                %Use the raw data for the StDev and RMS Data and kurtosis
                Struct(g).Label = DataStruct.Uni(g).Label;
                Struct(g).Anatomical = DataStruct.Uni(g).Anatomical;
                Struct(g).TemplateAnatomical = DataStruct.Uni(g).TemplateAnatomical;
                %             Struct(g).ERP = single(PlotERP{g});
                Struct(g).RMS = single(DistStruct.RMS);
                Struct(g).StDev = single(DistStruct.StDev);
                %             Struct(g).Kurtosis = single(DistStruct.Kurtosis);
                %             Struct(g).StimDist = single(pdist2(DataStruct.Uni(g).CoOrds,StimAnnot(f).CoOrds, 'euclidean'));
                Struct(g).StimDist = single(CoOrdDist(DataStruct.Bi(g).CoOrds,StimAnnot(f).CoOrds));
            end
        end
        
        StimAnnot(f).Bi = Struct;
        StimAnnot(f).PlotERPIndexes = -((DataTime + BaseOffset)*SamplingFreq):((DataTime+StimOffset)*SamplingFreq);
        StimAnnot(f).ERPDataInds = PlotERPInds{1};
        Time = toc;
        ProjectedFinishTime(Time,f,length(StimAnnot)+1);
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%   Process  the Bipolar RMS baselines   %%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    for f = 1:length(Baseline)
        tic;
        ERPData = cell(length(Baseline(f).Bi),1);
        PlotERP = cell(length(Baseline(f).Bi),1);
        BaseData = ERPData;
        PlotERPInds = BaseData;
        [DataTime, StimOffset, BaseOffset] = CCEPStimFreqDataTimeAllocation(DataStruct, Baseline, f);
        if ~isempty(ParallelPool)
            parfor r = 1:length(Baseline(f).Bi)
                
                %Get each of the ERP traces for the pulse train for each
                %channel and put them in cells for each channel
                for h = 1:length(Baseline(f).PulseTimes)
                    ERPData{r}(h,:) = ImportData(r).Data((Baseline(f).PulseTimes(h) + round(StimOffset * SamplingFreq)):(Baseline(f).PulseTimes(h) + ((DataTime +StimOffset)* SamplingFreq)));   %Put the raw data in an array
                    BaseData{r}(h,:) = ImportData(r).Data((Baseline(f).PulseTimes(h) - round((DataTime + BaseOffset)* SamplingFreq)):(Baseline(f).PulseTimes(h) - (BaseOffset * SamplingFreq)));  %Put the raw data in an array
                    %                     PlotERP{r}(h,:) = ImportData(r).Data((Baseline(f).PulseTimes(h) - round((DataTime + BaseOffset)* SamplingFreq)):(Baseline(f).PulseTimes(h) + ((DataTime)* SamplingFreq))); %Generate an ERP for the user to be able to plot
                    PlotERPInds{r}(h,:) = (Baseline(f).PulseTimes(h) - round((DataTime + BaseOffset)* SamplingFreq)):(Baseline(f).PulseTimes(h) + ((DataTime +StimOffset)* SamplingFreq)); %Generate an ERP for the user to be able to plot
                end
            end
        else
            for r = 1:length(Baseline(f).Bi)
                
                %Get each of the ERP traces for the pulse train for each
                %channel and put them in cells for each channel
                for h = 1:length(Baseline(f).PulseTimes)
                    ERPData{r}(h,:) = ImportData(r).Data((Baseline(f).PulseTimes(h) + round(StimOffset * SamplingFreq)):(Baseline(f).PulseTimes(h) + ((DataTime +StimOffset)* SamplingFreq)));   %Put the raw data in an array
                    BaseData{r}(h,:) = ImportData(r).Data((Baseline(f).PulseTimes(h) - round((DataTime + BaseOffset)* SamplingFreq)):(Baseline(f).PulseTimes(h) - (BaseOffset * SamplingFreq)));  %Put the raw data in an array
                    %                     PlotERP{r}(h,:) = ImportData(r).Data((Baseline(f).PulseTimes(h) - round((DataTime + BaseOffset)* SamplingFreq)):(Baseline(f).PulseTimes(h) + ((DataTime)* SamplingFreq))); %Generate an ERP for the user to be able to plot
                    PlotERPInds{r}(h,:) = (Baseline(f).PulseTimes(h) - round((DataTime + BaseOffset)* SamplingFreq)):(Baseline(f).PulseTimes(h) + ((DataTime +StimOffset)* SamplingFreq)); %Generate an ERP for the user to be able to plot
                end
            end
        end
        
        %Call the params structure
        [Params, Baseline(f).ParamSummary] = DistanceMetricParams(DataStruct, size(BaseData{1},2));
        
        %Init a blank structure for each stim section
        Struct = Baseline(f).Bi;
        if ~isempty(ParallelPool)
            parfor g = 1:length(Baseline(f).Bi)
                [DistStruct, ~] = CCEPSimilarityDistanceMetricsRMSOnly(DataStruct,ERPData{g},BaseData{g});
                
                %Use the raw data for the StDev and RMS Data and kurtosis
                Struct(g).Label = DataStruct.Bi(g).Label;
                Struct(g).Anatomical = DataStruct.Bi(g).Anatomical;
                Struct(g).TemplateAnatomical = DataStruct.Bi(g).TemplateAnatomical;
                %             Struct(g).ERP = single(PlotERP{g});
                Struct(g).RMS = single(DistStruct.RMS);
                Struct(g).StDev = single(DistStruct.StDev);
                %             Struct(g).Kurtosis = single(DistStruct.Kurtosis);
                %             Struct(g).StimDist = single(pdist2(DataStruct.Bi(g).CoOrds,Baseline(f).CoOrds, 'euclidean'));
                Struct(g).StimDist = single(CoOrdDist(DataStruct.Bi(g).CoOrds,Baseline(f).CoOrds));
            end
        else
            for g = 1:length(Baseline(f).Bi)
                [DistStruct, ~] = CCEPSimilarityDistanceMetricsRMSOnly(DataStruct,ERPData{g},BaseData{g});
                
                %Use the raw data for the StDev and RMS Data and kurtosis
                Struct(g).Label = DataStruct.Bi(g).Label;
                Struct(g).Anatomical = DataStruct.Bi(g).Anatomical;
                Struct(g).TemplateAnatomical = DataStruct.Bi(g).TemplateAnatomical;
                %             Struct(g).ERP = single(PlotERP{g});
                Struct(g).RMS = single(DistStruct.RMS);
                Struct(g).StDev = single(DistStruct.StDev);
                %             Struct(g).Kurtosis = single(DistStruct.Kurtosis);
                %             Struct(g).StimDist = single(pdist2(DataStruct.Bi(g).CoOrds,Baseline(f).CoOrds, 'euclidean'));
                Struct(g).StimDist = single(CoOrdDist(DataStruct.Bi(g).CoOrds,Baseline(f).CoOrds));
            end
        end
        
        Baseline(f).Bi = Struct;
        Baseline(f).PlotERPIndexes = -((DataTime + BaseOffset)*SamplingFreq):((DataTime+StimOffset)*SamplingFreq);
        Baseline(f).ERPDataInds = PlotERPInds{1};
        Time = toc;
        ProjectedFinishTime(Time,length(StimAnnot)+1,length(StimAnnot)+1);
    end
    
    %Save to a  file after all electrodes are finished
    fprintf('Finished Computing Bipolar Distances\n');
    fprintf('Saving Distance File\n');
    save(DistFileName, 'DataStruct','StimAnnot','Baseline','-v6');
    fprintf('Completed Bipolar File Save\n');
end

%Calculate the RMS distances and Z scores for the file, while you have it
fprintf('Computing Z score bootstraping, RMS ranking and bad area exclusion\n');
[DataStruct, StimAnnot, Baseline] = CCEPMakeRMSZScores(DataStruct, StimAnnot, Baseline, [], [] ,[]);
fprintf('Z score creation completed, saving file\n');
save(DistFileName, 'DataStruct','StimAnnot','Baseline','-v6');
fprintf('File save complete, %s file finished processing\n', ShortFileName(DistFileName));



