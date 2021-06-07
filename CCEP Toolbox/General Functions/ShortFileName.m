function ShortName = ShortFileName(OriginalName)
%ShortName = ShortFileName(OriginalName)
%Looks for a file with the fullfile name given, and returns the current
%location of it. This solves file move errors.


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


[Path, Name, Ext] = fileparts(OriginalName);
ShortName = strcat(Name, Ext);
CurrentFullFile = which(ShortName);

if ~isempty(CurrentFullFile)
    return;
else %Throw an error if the file is not in the path
    ErrorMsg = sprintf('The File does not exist - the short name was "%s"',ShortName);
    error(ErrorMsg);
end