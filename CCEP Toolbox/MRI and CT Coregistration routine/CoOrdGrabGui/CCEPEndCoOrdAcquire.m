function CCEPEndCoOrdAcquire(Source, ~)


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
GFig = findobj('Tag','Graphics'); %Not Graphics Fig current
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
ElectrodeArray(Ind).EndMM = Positionmm;
ElectrodeArray(Ind).EndVox = Positionvox;

%Get the number of electrode contacts on each electrode
TempTag = sprintf('NumContacts%i',Ind);
TempHandle = findobj('Tag',TempTag);
NumContacts = str2double(TempHandle.String{TempHandle.Value});
ElectrodeArray(Ind).NumContacts = NumContacts;

%Get the mm positions of each contact
PositionMatrixMM(:,1) = linspace(ElectrodeArray(Ind).StartMM(1),ElectrodeArray(Ind).EndMM(1),ElectrodeArray(Ind).NumContacts); %X co-ords
PositionMatrixMM(:,2) = linspace(ElectrodeArray(Ind).StartMM(2),ElectrodeArray(Ind).EndMM(2),ElectrodeArray(Ind).NumContacts); %Y co-ords
PositionMatrixMM(:,3) = linspace(ElectrodeArray(Ind).StartMM(3),ElectrodeArray(Ind).EndMM(3),ElectrodeArray(Ind).NumContacts); %Z co-ords
ElectrodeArray(Ind).PosMM = PositionMatrixMM; %Read the positions into the structure

%Get the Voxel Poisitions
PositionMatrixVox(:,1) = linspace(ElectrodeArray(Ind).StartVox(1),ElectrodeArray(Ind).EndVox(1),ElectrodeArray(Ind).NumContacts); %X co-ords
PositionMatrixVox(:,2) = linspace(ElectrodeArray(Ind).StartVox(2),ElectrodeArray(Ind).EndVox(2),ElectrodeArray(Ind).NumContacts); %Y co-ords
PositionMatrixVox(:,3) = linspace(ElectrodeArray(Ind).StartVox(3),ElectrodeArray(Ind).EndVox(3),ElectrodeArray(Ind).NumContacts); %Z co-ords
ElectrodeArray(Ind).PosVox = PositionMatrixVox; %Read the positions into the structure


%Create a Dummy MNI CoOrds Matrix
ElectrodeArray(Ind).PosMNI = zeros(NumContacts,3);

%Calculate the tangents
[Norm,Tangent,BiNormTangent] = VectorTangentNorm(PositionMatrixMM(1,:),PositionMatrixMM(NumContacts,:));
ElectrodeArray(Ind).Norm = Norm; %Save the num contacts in the electrode
ElectrodeArray(Ind).Tangent = Tangent; %Save the num contacts in the electrode
ElectrodeArray(Ind).BiNorm = BiNormTangent; %Save the num contacts in the electrode
ElectrodeArray(Ind).Patient = PatientName;

%Replace the patient name each time a CoOrd is completed
for e = 1:length(ElectrodeArray)
    ElectrodeArray(e).Patient = PatientName;
end

%Save the file and attach the updated results to the figure
[TempPath,~,~] = fileparts(which(ElectrodeArray(1).ImageFile));
FileName = sprintf('%s%s%s Electrodes.mat',TempPath, filesep, ElectrodeArray(1).Patient);
save(FileName,'ElectrodeArray','-v6');
CoOrdAcquireFig.UserData = ElectrodeArray;

%Change the color of the push button so that you dont hit it again
Source.BackgroundColor = 'green';