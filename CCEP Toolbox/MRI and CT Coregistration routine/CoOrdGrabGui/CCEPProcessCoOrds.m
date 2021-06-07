function [ ElectrodeArray ] = CCEPProcessCoOrds( varargin )
%Use this function to get the MNI CoOrds directly from the GUI and the ROI
%data as well

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


%Get the data and pass it to the processing function
GFig = findobj('Tag','Graphics');
MenuFig = findobj('Tag','Menu');
InteractiveFig = findobj('Tag','Interactive');
CoOrdAcquireFig = findobj('Tag','CoOrdAcquireFig'); %Find the CoOrdAcquireFig
ElectrodeArray = CoOrdAcquireFig.UserData; %Get the electrodearray
ElectrodeArray = CCEPTissueProbCalc('Data',ElectrodeArray);

%Close the finished figures and then restart the CCEPGUI menu
close(CoOrdAcquireFig);
close(GFig);
if ~isempty(InteractiveFig)
close(InteractiveFig);
end
if ~isempty(MenuFig)
close(MenuFig);
end
clc;
fprintf('Completed electrode creation for %s\n',ElectrodeArray(1).Patient);
CCEPGUIInit;
end

