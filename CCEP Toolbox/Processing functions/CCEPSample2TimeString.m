function [TimeStr] = CCEPSample2TimeString(Time, SamplingFreq )
%[TimeStr] = CCEPSample2TimeString(Time SamplingFreq )
%   Use this function to convert the sample numbers of an epoch into a time
%   string to orient you when looking at SEEG data
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


%Get the offsets for each time number
Hours = 3600 *SamplingFreq;
Mins = 60 *SamplingFreq;
Seconds = SamplingFreq;

% Start Time Numbers
Start.Hours = floor(Time/Hours);
Start.Mins = floor(Time/Mins);
Start.Secs = floor(Time/Seconds) - Start.Mins*60;
Start.Ms = rem(Time,Seconds);

%Create a string to print to the command line
TempStr = '';
if Start.Hours ~= 0
    NewStr = sprintf('%i Hrs ',Start.Hours);
    TempStr = sprintf('%s %s',TempStr, NewStr);
end
if Start.Hours ~= 0 || Start.Mins ~= 0
        NewStr = sprintf('%i mins ',Start.Mins);
        TempStr = sprintf('%s %s',TempStr, NewStr);
end
if Start.Hours ~= 0 || Start.Mins ~= 0 || Start.Secs ~= 0 || Start.Ms ~= 0
        NewStr = sprintf('%i.%0.3gs',Start.Secs,Start.Ms); 
        TempStr = sprintf('%s %s',TempStr, NewStr);
end
TimeStr = sprintf('Time From File Start: %s',TempStr);