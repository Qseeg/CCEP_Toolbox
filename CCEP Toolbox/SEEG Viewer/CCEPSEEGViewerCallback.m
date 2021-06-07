function CCEPSEEGViewerCallback(varargin)
%CCEPSEEGViewerCallback - use with the CCEPGUIInit menu


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


%Input the patient name
PatientName = inputdlg('What is the name of the Patient in the Anatomical Map Spreadsheet?','Patient Name Input',1,{'Patient 1'});
if iscell(PatientName)
    PatientName = PatientName{1};
end

%Get the EDF File using a uigetfile (add to the path regardless)
[DataFile, TempFilePath] = uigetfile('*.edf','Select the EDF file you would like to view and change the annotations of');
addpath(TempFilePath);

%Begin processing
CCEPSEEGViewer('Name',PatientName,'Data',DataFile);










