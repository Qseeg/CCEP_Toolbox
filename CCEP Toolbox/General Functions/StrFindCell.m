function [Output,Mask] = StrFindCell(InputData, Pattern, CaseSensitive)
%[Indexes,Mask] = StrFindCell(InputData, Pattern, CaseSensitive)
%StrFindCell

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
if ~exist('CaseSensitive','var')
    CaseSensitive = 1;
elseif isempty(CaseSensitive)
    CaseSenstive = 1;
else
    CaseSensitive = 0;
end

%Find which elements of a cellstring array have an element present
if CaseSensitive == 1
    Temp = strfind(InputData, Pattern);
else
    Temp = strfind(upper(InputData), upper(Pattern));
end
[~, Output] = find(~cellfun(@isempty, Temp));
Mask = ~cellfun(@isempty, Temp);
end





