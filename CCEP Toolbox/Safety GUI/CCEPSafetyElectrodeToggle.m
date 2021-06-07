function CCEPSafetyElectrodeToggle(varargin)
%Toggle the use of SEEG electrodes


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


CCEPStimSafetyFig = findobj('Tag','CCEPStimSafetyFig');
ElectrodeTypeButton = findobj('Tag','ElectrodeTypeButton');
ElectrodeLength = findobj('Tag','ElectrodeLength');
ElectrodeLengthText = findobj('Tag','ElectrodeLengthText');

if ElectrodeTypeButton.Value == 1
   ElectrodeTypeButton.String = 'SEEG';
   ElectrodeLength.Visible = 'on';
   ElectrodeLengthText.Visible = 'on';
else
    ElectrodeTypeButton.String = 'ECoG'; 
    ElectrodeLength.Visible = 'off';
    ElectrodeLengthText.Visible = 'off';
end