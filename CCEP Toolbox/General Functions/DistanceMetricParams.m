function [Params, ParamSummary] = DistanceMetricParams(DataStruct, SeqLength)
%[Params, ParamSummary] = DistanceMetricParams(DataStruct, SeqLength)
%   Use this to give the parametric sweep for what is used to find the best
%   metrics (elastic and AR ones)


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


SamplingFreq = DataStruct.Info(1).SamplingFreq;

%DTW
Params.DTW = (linspace(0.01,0.25, 24)).*SeqLength; %Fraction of the sequence length to allow for warping
Params.DTW(end+1) = SeqLength;
ParamSummary.DTW = (linspace(0.01,0.25, 24));
ParamSummary.DTW(end+1) = 1;

%EDR
Params.EDR = linspace(0.02,1,25); %This is the edit penalty as a fraction of the standard deviation of the time series (stdev should be 1 based on the z-normalization)
ParamSummary.EDR = Params.EDR;

%TWED
Params.TWEDTime = repmat([0.0001 0.001 0.01 0.1 1], [5,1]); %TWED stiffness penalty as a base 10 logarithm spacing (nu Param)
Params.TWEDTime = reshape(Params.TWEDTime, [1,25]);
Params.TWEDAmp = repmat([0 0.25 0.5 0.75 1],[1,5]); %TWED dissimilarity (equivalent to epsilon in EDR)
ParamSummary.TWEDTime = Params.TWEDTime;
ParamSummary.TWEDAmp = Params.TWEDAmp;

%MJC
Params.MJC = linspace(0,24,24);
Params.MJC(end+1) = 10e10;
ParamSummary.MJC = Params.MJC;

%FC
Params.FC = floor(linspace(5,0.5*SamplingFreq, 25));
ParamSummary.FC = floor(linspace((5/SamplingFreq),(0.5*SamplingFreq), 25));

%AR
Params.AR = round(linspace(1,(SeqLength/4), 25));
ParamSummary.AR = Params.AR;