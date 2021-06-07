function [DataStruct, StimAnnot, Baseline] = CCEPMakeRMSZScores(DataStruct, StimAnnot, Baseline, KurtosisThresh, StimDistThresh,EZIncludeFlag,ExcludeLabels)
%[DataStruct, StimAnnot, Baseline] = MakeRMSZScores(DataFile, KurtosisThresh, StimDistThresh,EZIncludeFlag,ExcludeLabels)
% Use this function to add the Z scores and choose which pulse trains are
% valid for inclusion in each of the insula stims files. It needs the following:
% DataStruct, StimAnnot and Baseline- Files saved to the RMS values file or
% processed using the CCEPProcessRMSFile
% KurtosisThresh- Thresold to exclude responses or baseline from stim
% (defaults to 6) - not being used in this version
% StimDistThresh - Distance to exclude response sites from, dfaults to 10mm
% (to include all except the stim site)
% EZIncludeFlag - check whether or not to include
% ExcludeLabels - List of labels which to get rid of in the Z score
% creation and ranking procedure
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


%Script to create the Z scores for each of the actual spulse train
%responses
% ActualFile = which(uigetfile('*(Valid).mat','Get the Valid RMS StimAnnot file'));

%If the actual file is not given, open up a uidialog box to select it
% if ~exist('DataFile','var')
%     DataFile = which(uigetfile('*.mat','Get the Valid RMS StimAnnot file'));
% else
%     if isempty(DataFile)
%         DataFile = which(uigetfile('*.mat','Get the Valid RMS StimAnnot file'));
%     end
% end
% [P,N,E] = fileparts(which(DataFile));

% %Get the baseline file which corresponds to the actual (data) file
% if ~exist('Baseline','var')
%     TempStr = strsplit(DataFile,' Values');
%     BaselineFile = which(sprintf('%s Baseline Distance Record Values%s',TempStr{1},E));
% else
%     if isempty(BaselineFile)
%         TempStr = strsplit(DataFile,' Values');
%         BaselineFile = which(sprintf('%s Baseline Distance Record Values%s',TempStr{1},E));
%     end
% end

%Set the default thresholds if they don't exist
if ~exist('KurtosisThresh','var')
    KurtosisThresh = 6;
else
    if isempty(KurtosisThresh)
        KurtosisThresh = 6;
    end
end
if ~exist('StimDistThresh','var')
    StimDistThresh = 10; %Stim distance exclusion radius in mm (default to 0mm)
else
    if isempty(StimDistThresh)
        StimDistThresh = 10;
    end
end
if ~exist('EZIncludeFlag','var')
    EZIncludeFlag = 1; %Stim distance exclusion radius in mm (default to 0mm)
else
    if isempty(EZIncludeFlag)
        EZIncludeFlag = 1;
    end
end

%Set the labels which are not valid (but are fairly sparsely occurring) to
%be excluded
CCEPGUIInitParameterFile = which('Current CCEP GUI Init Parameters.mat');
if ~isempty(CCEPGUIInitParameterFile)
    load(CCEPGUIInitParameterFile);
    TempExcludeLabels = CCEPGUIParams.AnatomicalExclude;
end
%Go through the conditions if exclusion labels are given as well if they
%are only found in the intialisation file
if ~exist('ExcludeLabels','var') && ~exist('TempExcludeLabels','var')
    ExcludeLabels = {'CYST','lesion','IH','ventricle','hetereotopia','hamartoma','gliosis','flat signal','tissue','sylfis'};
elseif ~exist('ExcludeLabels','var') && exist('TempExcludeLabels','var')     
    ExcludeLabels = TempExcludeLabels;
elseif exist('ExcludeLabels','var') && exist('TempExcludeLabels','var')     
    ExcludeLabels(end+1:end+length(TempExcludeLabels)) = TempExcludeLabels;    
end


%Load the structure for StimAnnot for the actual data (non-baseline)
% load(DataFile);
ActualData = StimAnnot;
BaseData = Baseline;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Write blank EZ, IZ and LZ data in for now (will have the option to put in
% EZ, LZ and IZ in later versions)
EZ = []; 
IZ = [];
LZ = [];

%Trim the kurtosis thresholded responses from the ControlDist structure
DataStruct = HemisphericReLabel(DataStruct);
DataStruct = RelabelDataStruct(DataStruct);
for d = 1:length(BaseData.Bi)
    
    %     TempKurtosis = [];
    %     Temp = [];
    %     TempKurtosis = [BaseData.Bi(d).Kurtosis];
    %     Temp(:,1) = TempKurtosis(:,1) <= KurtosisThresh & TempKurtosis(:,2) <= KurtosisThresh;
    %     GoodInds = find(double(Temp));
    %     BaseData.Bi(d).GoodInds = GoodInds;
    
    BaseData.Bi(d).GoodInds = 1:length(BaseData.PulseTimes);
    BaseData.Bi(d).Anatomical = DataStruct.Bi(d).Anatomical;
    
end
for d = 1:length(BaseData.Uni)
    
    %     TempKurtosis = [];
    %     Temp = [];
    %     TempKurtosis = [BaseData.Uni(d).Kurtosis];
    %     Temp(:,1) = TempKurtosis(:,1) <= KurtosisThresh & TempKurtosis(:,2) <= KurtosisThresh;
    %     GoodInds = find(double(Temp));
    %     BaseData.Uni(d).GoodInds = GoodInds;
    
    BaseData.Uni(d).GoodInds = 1:length(BaseData.PulseTimes);
    BaseData.Uni(d).Anatomical = DataStruct.Uni(d).Anatomical;
    
end


%Trim the actual data structure and reject the channels which have less
%than 5 pulses for each pulse train
for c = 1:length(ActualData)
    for d = 1:length(ActualData(c).Bi)
%         TempKurtosis = []; %Clear/Prealloc Temps
%         Temp = [];
%         TempKurtosis = [ActualData(c).Bi(d).Kurtosis];
%         Temp(:,1) = TempKurtosis(:,1) <= KurtosisThresh & TempKurtosis(:,2) <= KurtosisThresh;
        Temp = true(1,length(ActualData(c).PulseTimes));
        ActualData(c).Bi(d).NumValidPulses = sum(Temp);
        ActualData(c).Bi(d).ValidPulseInds = find(Temp);
        ActualData(c).Bi(d).Anatomical = DataStruct.Bi(d).Anatomical;
        ActualData(c).Bi(d).Label = DataStruct.Bi(d).Label;
        
        %If there is less than 5 pulses or the recording site is less than
        %the StimDist threshold away or the recording site is in the EZ, then
        %reject the entire pulse train and
        %indicate this. Otherwise, calculate the Z score from the pulse
        %train and the Z score, compared to the "BaseData" variable
        
        if (sum(Temp)<=5) || (ActualData(c).Bi(d).StimDist <= StimDistThresh) || ((sum(strcmp(DataStruct.Uni(DataStruct.Bi(d).UnipolarContacts(1)).Anatomical,'OUT'))>0)|(sum(strcmp(DataStruct.Uni(DataStruct.Bi(d).UnipolarContacts(2)).Anatomical,'OUT'))>0)) || (sum(strcmp(DataStruct.Bi(d).Anatomical,{'Left WM','Right WM'}))>0) || (sum(ismember(EZ,[DataStruct.Bi(d).UnipolarContacts]))>0) || (sum(strcmp(DataStruct.Bi(d).Anatomical,ActualData(c).Anatomical))>0) || (sum(~cellfun(@isempty, regexpi(ActualData(c).Bi(d).Anatomical, ExcludeLabels)))>0)
            ActualData(c).Bi(d).Valid = false;
            ActualData(c).Bi(d).ZScore = NaN;
            ActualData(c).Bi(d).RMSMean = NaN;
            ActualData(c).Bi(d).RMSMedian = NaN;
            ActualData(c).Bi(d).EZ = false;
            
            if (sum(ismember(EZ,[DataStruct.Bi(d).UnipolarContacts]))>0)
                ActualData(c).Bi(d).EZ = true;
                if EZIncludeFlag == 1
                    ActualData(c).Bi(d).Valid = true;
                    TempBase = BaseData.Bi(d).RMS((BaseData.Bi(d).GoodInds));
                    TempActual = ActualData(c).Bi(d).RMS((ActualData(c).Bi(d).ValidPulseInds));
                    
                    if (sum(isnan(TempActual)) >= length(TempActual)) || isempty(TempActual) || (sum(~cellfun(@isempty, regexpi(ActualData(c).Bi(d).Anatomical, ExcludeLabels)))>0)
                        ActualData(c).Bi(d).ZScore = NaN;
                        ActualData(c).Bi(d).RMSMean = NaN;
                        ActualData(c).Bi(d).RMSMedian = NaN;
                    else
                        try %If no statistics toolbox exists - just nan the zscore
                        [~,~,TempStats]= ranksum(TempActual, TempBase);
                        ActualData(c).Bi(d).ZScore = TempStats.zval;
                        catch
                            ActualData(c).Bi(d).ZScore = NaN;
                        end
                        ActualData(c).Bi(d).RMSMean = mean(TempActual);
                        ActualData(c).Bi(d).RMSMedian = median(TempActual);
                    end
                else
                    ActualData(c).Bi(d).Valid = false;
                    ActualData(c).Bi(d).ZScore = NaN;
                    ActualData(c).Bi(d).RMSMean = NaN;
                    ActualData(c).Bi(d).RMSMedian = NaN;
                end
            end
        else
            %If the data is good, do the Z score and then add all of the
            %relevant info
            ActualData(c).Bi(d).Valid = true;
            TempBase = BaseData.Bi(d).RMS((BaseData.Bi(d).GoodInds));
            TempActual = ActualData(c).Bi(d).RMS((ActualData(c).Bi(d).ValidPulseInds));
            try %If no statistics toolbox exists - just nan the zscore
                [~,~,TempStats]= ranksum(TempActual, TempBase);
                ActualData(c).Bi(d).ZScore = TempStats.zval;
            catch
                ActualData(c).Bi(d).ZScore = NaN;
            end
            ActualData(c).Bi(d).EZ = false;
            ActualData(c).Bi(d).RMSMean = mean(TempActual);
            ActualData(c).Bi(d).RMSMedian = median(TempActual);
        end
    end
    
    %Sort the ranks and then assign the normalised rank values for both the
    %RMS median and Mean, with the WM, Out and EZ contacts not included
    Temp = [ActualData(c).Bi.RMSMean];
    NanTemp = isnan(Temp);
    Temp(NanTemp) = -inf;
    [~, SortInds] =  sort(Temp,'descend');
    NumValidMean = sum(~isnan([ActualData(c).Bi.RMSMean]));
    for g = 1:length(ActualData(c).Bi)
        if g <= NumValidMean
            RankVal = (length(ActualData(c).Bi)- (g-1) - sum(NanTemp))/NumValidMean;
            ActualData(c).Bi(SortInds(g)).RMSMeanRank = RankVal;
            %Create the quartile values of the RMS index
            if RankVal > 0.75
                ActualData(c).Bi(SortInds(g)).RMSMeanQV = 4;
            elseif RankVal <= 0.75 && RankVal > 0.5
                ActualData(c).Bi(SortInds(g)).RMSMeanQV = 3;
            elseif RankVal <= 0.5 && RankVal > 0.25
                ActualData(c).Bi(SortInds(g)).RMSMeanQV = 2;
            elseif RankVal <= 0.25
                ActualData(c).Bi(SortInds(g)).RMSMeanQV = 1;
            end
        else
            ActualData(c).Bi(SortInds(g)).RMSMeanRank = NaN;
            ActualData(c).Bi(SortInds(g)).RMSMeanQV = NaN;
        end
    end
    
    %Repeat the ranking for the median of the pulse train data
    Temp = [ActualData(c).Bi.RMSMedian];
    NanTemp = isnan(Temp);
    Temp(NanTemp) = -inf;
    [~, SortInds] =  sort(Temp,'descend');
    NumValidMedian = sum(~isnan([ActualData(c).Bi.RMSMedian]));
    for g = 1:length(ActualData(c).Bi)
        if g <= NumValidMean
            RankVal = (length(ActualData(c).Bi)- (g-1) - sum(NanTemp))/NumValidMean;
            ActualData(c).Bi(SortInds(g)).RMSMedianRank = RankVal;
            %Create the quartile values of the RMS index
            if RankVal > 0.75
                ActualData(c).Bi(SortInds(g)).RMSMedianQV = 4;
            elseif RankVal <= 0.75 && RankVal > 0.5
                ActualData(c).Bi(SortInds(g)).RMSMedianQV = 3;
            elseif RankVal <= 0.5 && RankVal > 0.25
                ActualData(c).Bi(SortInds(g)).RMSMedianQV = 2;
            elseif RankVal <= 0.25
                ActualData(c).Bi(SortInds(g)).RMSMedianQV = 1;
            end
        else
            ActualData(c).Bi(SortInds(g)).RMSMedianRank = NaN;
            ActualData(c).Bi(SortInds(g)).RMSMedianQV = NaN;
        end
    end
    
    %Now do the unipolar cases
    for d = 1:length(ActualData(c).Uni)
%         TempKurtosis = []; %Clear/Prealloc Temps
%         Temp = [];
%         TempKurtosis = [ActualData(c).Uni(d).Kurtosis];
%         Temp(:,1) = TempKurtosis(:,1) <= KurtosisThresh & TempKurtosis(:,2) <= KurtosisThresh;
        Temp = true(1,length(ActualData(c).PulseTimes));
        ActualData(c).Uni(d).NumValidPulses = sum(Temp);
        ActualData(c).Uni(d).ValidPulseInds = find(Temp);
        ActualData(c).Uni(d).Anatomical = DataStruct.Uni(d).Anatomical;
        ActualData(c).Uni(d).Label = DataStruct.Uni(d).Label;
        
        %If there is less than 5 pulses or the recording site is less than
        %the StimDist threshold away or the recording site is in the EZ, then
        %reject the entire pulse train and
        %indicate this. Otherwise, calculate the Z score from the pulse
        %train and the Z score, compared to the "BaseData" variable
        
        if (sum(Temp)<=5) || (ActualData(c).Uni(d).StimDist <= StimDistThresh) || ((sum(strcmp(DataStruct.Uni(d).Anatomical,'OUT'))>0)|(sum(strcmp(DataStruct.Uni(d).Anatomical,'OUT'))>0)) || (sum(strcmp(DataStruct.Uni(d).Anatomical,{'Left WM','Right WM'}))>0) || (sum(ismember(EZ,d))>0) || (sum(~cellfun(@isempty, regexpi(ActualData(c).Uni(d).Anatomical, ExcludeLabels)))>0)
            ActualData(c).Uni(d).Valid = false;
            ActualData(c).Uni(d).ZScore = NaN;
            ActualData(c).Uni(d).RMSMean = NaN;
            ActualData(c).Uni(d).RMSMedian = NaN;
            ActualData(c).Uni(d).EZ = false;
            
            if (sum(ismember(EZ,d))>0)
                ActualData(c).Uni(d).EZ = true;
                if EZIncludeFlag == 1
                    ActualData(c).Uni(d).Valid = true;
                    TempBase = BaseData.Uni(d).RMS((BaseData.Uni(d).GoodInds));
                    TempActual = ActualData(c).Uni(d).RMS((ActualData(c).Uni(d).ValidPulseInds));
                    
                    if (sum(isnan(TempActual)) >= length(TempActual)) || isempty(TempActual) || (sum(~cellfun(@isempty, regexpi(ActualData(c).Uni(d).Anatomical, ExcludeLabels)))>0)
                        ActualData(c).Uni(d).ZScore = NaN;
                        ActualData(c).Uni(d).RMSMean = NaN;
                        ActualData(c).Uni(d).RMSMedian = NaN;
                    else
                        try %If no statistics toolbox exists - just nan the zscore
                        [~,~,TempStats]= ranksum(TempActual, TempBase);
                        ActualData(c).Uni(d).ZScore = TempStats.zval;
                        catch
                            ActualData(c).Uni(d).ZScore = NaN;
                        end
                        ActualData(c).Uni(d).RMSMean = mean(TempActual);
                        ActualData(c).Uni(d).RMSMedian = median(TempActual);
                    end
                else
                    ActualData(c).Uni(d).Valid = false;
                    ActualData(c).Uni(d).ZScore = NaN;
                    ActualData(c).Uni(d).RMSMean = NaN;
                    ActualData(c).Uni(d).RMSMedian = NaN;
                end
            end
        else
            %If the data is good, do the Z score and then add all of the
            %relevant info
            ActualData(c).Uni(d).Valid = true;
            TempBase = BaseData.Uni(d).RMS((BaseData.Uni(d).GoodInds));
            TempActual = ActualData(c).Uni(d).RMS((ActualData(c).Uni(d).ValidPulseInds));
            try %If no statistics toolbox exists - just nan the zscore
                [~,~,TempStats]= ranksum(TempActual, TempBase);
                ActualData(c).Uni(d).ZScore = TempStats.zval;
            catch
                ActualData(c).Uni(d).ZScore = NaN;
            end
            ActualData(c).Uni(d).EZ = false;
            ActualData(c).Uni(d).RMSMean = mean(TempActual);
            ActualData(c).Uni(d).RMSMedian = median(TempActual);
            
        end
    end
    
    %Sort the ranks and then assign the normalised rank values for both the
    %RMS median and Mean, with the WM, Out and EZ contacts not included
    Temp = [ActualData(c).Uni.RMSMean];
    NanTemp = isnan(Temp);
    Temp(NanTemp) = -inf;
    [~, SortInds] =  sort(Temp,'descend');
    NumValidMean = sum(~isnan([ActualData(c).Uni.RMSMean]));
    for g = 1:length(ActualData(c).Uni)
        if g <= NumValidMean
            RankVal = (length(ActualData(c).Uni)- (g-1) - sum(NanTemp))/NumValidMean;
            ActualData(c).Uni(SortInds(g)).RMSMeanRank = RankVal;
            %Create the quartile values of the RMS index
            if RankVal > 0.75
                ActualData(c).Uni(SortInds(g)).RMSMeanQV = 4;
            elseif RankVal <= 0.75 && RankVal > 0.5
                ActualData(c).Uni(SortInds(g)).RMSMeanQV = 3;
            elseif RankVal <= 0.5 && RankVal > 0.25
                ActualData(c).Uni(SortInds(g)).RMSMeanQV = 2;
            elseif RankVal <= 0.25
                ActualData(c).Uni(SortInds(g)).RMSMeanQV = 1;
            end
        else
            ActualData(c).Uni(SortInds(g)).RMSMeanRank = NaN;
            ActualData(c).Uni(SortInds(g)).RMSMeanQV = NaN;
        end
    end
    
    %Repeat the ranking for the median of the pulse train data
    Temp = [ActualData(c).Uni.RMSMedian];
    NanTemp = isnan(Temp);
    Temp(NanTemp) = -inf;
    [~, SortInds] =  sort(Temp,'descend');
    NumValidMedian = sum(~isnan([ActualData(c).Uni.RMSMedian]));
    for g = 1:length(ActualData(c).Uni)
        if g <= NumValidMean
            RankVal = (length(ActualData(c).Uni)- (g-1) - sum(NanTemp))/NumValidMean;
            ActualData(c).Uni(SortInds(g)).RMSMedianRank = RankVal;
            %Create the quartile values of the RMS index
            if RankVal > 0.75
                ActualData(c).Uni(SortInds(g)).RMSMedianQV = 4;
            elseif RankVal <= 0.75 && RankVal > 0.5
                ActualData(c).Uni(SortInds(g)).RMSMedianQV = 3;
            elseif RankVal <= 0.5 && RankVal > 0.25
                ActualData(c).Uni(SortInds(g)).RMSMedianQV = 2;
            elseif RankVal <= 0.25
                ActualData(c).Uni(SortInds(g)).RMSMedianQV = 1;
            end
        else
            ActualData(c).Uni(SortInds(g)).RMSMedianRank = NaN;
            ActualData(c).Uni(SortInds(g)).RMSMedianQV = NaN;
        end
    end
    
    %Sort the structures to provide something you can look through
    %     [~, SortInds] =  sort(abs([ActualData(c).Bi.ZScore]),'descend','MissingPlacement','last');
    %
    %     SortedStructs(c) = ActualData(c);
    %     SortedStructs(c).Bi = ActualData(c).Bi(SortInds);
end

%Save back into the output variable
StimAnnot = ActualData;

