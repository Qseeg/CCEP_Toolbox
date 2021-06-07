function [DataTime, StimOffset, BaseOffset] = CCEPStimFreqDataTimeAllocation(DataStruct, StimAnnot, Index)
%[DataTime StimOffset, BaseOffset] = CCEPStimFreqDataTimeAllocation(DataStruct, StimAnnot, Index)
%Use this function to pull down which data time to use for each ERP


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


SamplingFreq = DataStruct.Info.SamplingFreq;

if round(StimAnnot(Index).Frequency,1) <= 5
    DataTime = 0.1; %Set the time of ERP data to be (n) seconds (don't need much as you are just getting the stim artefact)
    StimOffset = 0.010; %Set the time after stimulation to ignore the stim artefact (default to 10ms)
    BaseOffset = 0.005;
    
elseif (StimAnnot(Index).Frequency > 5) && (StimAnnot(Index).Frequency < 40)
    DataTime = 0.030; %Set the time of ERP data to be (n) seconds (don't need much as you are just getting the stim artefact)
    StimOffset = 0.010; %Set the time after stimulation to ignore the stim artefact (defaukt to 10ms)
    BaseOffset = 0.005;    
    
    elseif StimAnnot(Index).Frequency >= 40
    DataTime = 0.008; %Set the time of ERP data to be (n) seconds (don't need much as you are just getting the stim artefact)
    StimOffset = 0.010; %Set the time after stimulation to ignore the stim artefact (defaukt to 10ms)
    BaseOffset = 0.005;
    
end