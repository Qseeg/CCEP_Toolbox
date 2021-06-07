function [DistStruct, SquashedDistStruct, DataStruct] = CCEPSimilarityDistanceMetricsRMSOnly(DataStruct,ERPData,BaseData)
%[DistStruct, SquashedDistStruct, DataStruct] = CCEPSimilarityDistanceMetricsRMSOnly(DataStruct, ERPData, BaseData)
%This function takes in the time series data for all of the ERPs in a pulse
%train and compares them to their respective baselines
%Inputs are:
%DataStruct = The Data structure (Uni and Bipo channel info)
%ERPData = The time data for all ERPs in the pulse train, with each row
%corresponding to the response data for the time series.
%BaseData = The Baseline ERP time series corresponding to the baseline
%before each ERP (of an equivalent time length)
%Outputs  are:
%DistStruct =Average Distances between Raw Baselines  and Raw ERPs
%SquashedDistStruct =Average Distances between Zero mean and unit variance
%Baselines  and ERPs

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


%Convert the datatype just in case there is an error again
ERPData = double(ERPData);
BaseData = double(BaseData);

%Preallocate the structures
Dist(size(ERPData,1)).RMS = rand(1);
Dist(size(ERPData,1)).StDev = rand(1);
% Dist(size(ERPData,1)).Kurtosis = rand(1,2);

% SquashedDist = Dist;


%Compute the DTW average warping template on the squashed data - only do
%the raw one if requested
%Quickly compute the Kurtosis values of the ERPs to see which should go
%into the template
% for m = 1:(size(ERPData,1))
%     KurtosisVal(m) = kurtosis(ERPData(m,:));
% end
if isfield(DataStruct.Info, 'KurtosisThresh') %Check if the threshold is given in the data structure
    KurtosisThresh = DataStruct.Info.KurtosisThresh;
else %otherwise assume a number and assign it to the structure
    KurtosisThresh = 8;
    DataStruct.Info.KurtosisThresh = KurtosisThresh;
end

%For each of the ERPs, compute the ditance between it and the corresponding
%segment of Baseline
for c = 1:size(ERPData,1)
    
    %If a squashed response is infinite (StDev went to 0), it is because it was amplifier
    %shutoff, saturation or stim reset. Disregard this distance by setting the
    %Squashed Data to 0
    if (sum(~isfinite(ERPData(c,:)))>0)||(sum(~isfinite(BaseData(c,:)))>0)
        ERPData(c,:) = 0;
        BaseData(c,:) = 0;
    end
    
    %Get the RMS/Stdev and Kurtosis for the data in this section
    try
        Dist(c).RMS = rms(ERPData(c,:))/rms(BaseData(c,:));
    catch
        Dist(c).RMS =  sqrt(mean(ERPData(c,:).^2))/sqrt(mean(BaseData(c,:).^2));
    end
    Dist(c).StDev = std(ERPData(c,:))/std(BaseData(c,:));
%     Dist(c).Kurtosis = [kurtosis(ERPData(c,:)),kurtosis(BaseData(c,:))];
end

%The non squashed Dist Struct
DistStruct.RMS = [Dist.RMS]';
DistStruct.StDev = [Dist.StDev]';
% DistStruct.Kurtosis = reshape([Dist.Kurtosis]',[2,(size(ERPData,1))])';
SquashedDistStruct = [];