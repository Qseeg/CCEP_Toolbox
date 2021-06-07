function CCEPStartCoOrdAcquire(Source, ~)
%Callback for the then start CoOrd of an electrode is acquired in the SPM12
%Graphics figure. 


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


%Acquire the inputs (calling function userdata will correspond to the index
%in the electrode array)
DigitInds = isstrprop(Source.UserData,'digit'); %Find the indexes that are numeric chars
Ind = str2double(Source.UserData(DigitInds)); %Get the Number of the electrode in the electrode array
GFig = findobj('Tag','Graphics'); %Find graphics figure
CoOrdAcquireFig = findobj('Tag','CoOrdAcquireFig'); %Find the CoOrdAcquireFig
ElectrodeArray = CoOrdAcquireFig.UserData; %Get the electrodearray
PatientNameInput = findobj('Tag','PatientNameInput'); 
PatientName = PatientNameInput.String;

%SPM Figure Information Acquisition
for i = 1:length(GFig.Children)
    Types{i} = GFig.Children(i).Type;
end
FoundInds = strcmp(Types,'uipanel');
InformationPanel = GFig.Children(min(find(FoundInds))); %Find the panel (should be the 1st panel that is in the graphics fig
CrossHairsDataPanel= GFig.Children(max(find(FoundInds))); %Find the 2nd panel (should be the 2nd and final panel)
InformationPanel = InformationPanel.Children(2); %Find the panel (should be the 1st panel that is in the graphics fig
OriginString = InformationPanel.Children(6).String;
OriginVoxel = str2num(OriginString);

%Make a note of the image dimensions
DimString = InformationPanel.Children(15).String;
[TempDim, Remainder] = strtok(DimString , 'x');
ImageDim(1) = abs(str2num(TempDim(1:end-1)));
[TempDim, Remainder] = strtok(Remainder, 'x');
ImageDim(2) = abs(str2num(TempDim(2:end-1)));
ImageDim(3) = abs(str2num(Remainder(2:end)));

%Make a note of the Voxel size
VoxString = InformationPanel.Children(8).String;
[TempVox, Remainder] = strtok(VoxString , 'x');
VoxSize(1) = abs(str2num(TempVox(1:end-1)));
[TempVox, Remainder] = strtok(Remainder, 'x');
VoxSize(2) = abs(str2num(TempVox(2:end-1)));
VoxSize(3) = abs(str2num(Remainder(2:end)));

%Use SPM to get the position of the cursor
Positionmm = str2num(CrossHairsDataPanel.Children(2).Children(3).String);
Positionvox = str2num(CrossHairsDataPanel.Children(2).Children(2).String);

%Record the CoOrd in the start array
ElectrodeArray(Ind).StartMM = Positionmm;
ElectrodeArray(Ind).StartVox = Positionvox;
ElectrodeArray(Ind).Patient = PatientName;

%Write it back into the SPM figure
CoOrdAcquireFig.UserData = ElectrodeArray;

%Change the color of the push button so that you dont hit it again
Source.BackgroundColor = 'green';
