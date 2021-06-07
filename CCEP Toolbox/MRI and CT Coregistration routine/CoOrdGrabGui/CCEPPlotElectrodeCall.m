function CCEPPlotElectrodeCall(varargin)
%Callback to plot the electrodes from an electrode file

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


%Acquire the patient Name from the figure
CoOrdAcquireFig = findobj('Tag','CoOrdAcquireFig');
ElectrodeArray = CoOrdAcquireFig.UserData;
PatientName = ElectrodeArray(1).Patient;
ElectrodeFile = strcat(PatientName, 'Electrodes.mat');
CCEPElectrodePlotter('Electrode',ElectrodeArray,'CoOrd','Patient');

end