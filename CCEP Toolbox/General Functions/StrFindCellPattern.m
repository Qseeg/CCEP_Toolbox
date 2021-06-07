function [Output,Mask] = StrFindCellPattern(InputData, Pattern, CaseSensitive)
%[Indexes,Mask] = StrFindCellPattern(InputData, Pattern, CaseSensitive)
%StrFindCellPattern

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


%Check if Case sensitivity is required
if exist('CaseSensitive','var')
    CaseSensitive = 1;
elseif isempty(CaseSensitive)
    CaseSenstive = 1;
else
    CaseSensitive = 0;
end

%If the pattern is not a cell, make it one
if ~iscell(Pattern)
    Pattern = {Pattern};
end

%Find which elements of the InputData data array have that correspond to
%elements of those found in pattern
Temp = zeros(1, length(Pattern));
if CaseSensitive == 1
    for a = 1:length(Pattern)
        Temp(a) = ~isempty(regexp(InputData, Pattern{a}));
    end
else
    for a = 1:length(Pattern)
        Temp(a) = ~isempty(regexpi(InputData, Pattern{a}));
    end
end
[~, Output] = find(Temp);
Mask = Temp;
end