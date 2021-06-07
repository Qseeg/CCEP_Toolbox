function OutputLabel = PrimaryAnatomicalLabel(InputLabel)
%OutputLabel = PrimaryAnatomicalLabel(InputLabel);
%Use this function to get the primary label of each of the anatomical sites
%listed. This will return everything before the first bracket '(' sign.


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


TempStr = strsplit(InputLabel, '(');
OutputLabel = strtrim(TempStr{1});

end