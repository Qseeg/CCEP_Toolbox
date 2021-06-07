function [AnatomicalLabels] = AnatomicalLabelFunc(PatientName,SignalLabels)
%[AnatomicalLabels] = AnatomicalSiteLabelFinder5(PatientName,SignalLabels)
%AnatomicalLabels = Cell of corresponding anatomical Label for the given
%signal labels
%PatientName = Pname from struct
%SignalLabels = Cell of all of the good labels i.e
%{'TP''1','TP''2',....'X''15'} which should just be a {SigStruct.Labels} input


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


%*******Read in the Patient Map file
[~, PatientText, ~] = xlsread(MapFile, SheetName); %Get the Mapfile and the specific sheet relevant to the patient
[Num_Rows, Num_Cols] = size(PatientText); %Use the dimensions to see the number of electrodes and contacts in the maximal one

%Make up a dummy electrode naming map to cross check the location of contacts
for p = 1:Num_Rows
    expression = '’'; %Change all of the bad invreted commas to matlab font
    replace = '''';
    EName = regexprep(PatientText{p,1},expression,replace);
    for o = 1:(Num_Cols -1)
        ElectrodeContactList{p,o} = sprintf('%s%i',EName,o);
    end
end

%***********Read in all of the data
Patient_Matrix = cell(Num_Rows, Num_Cols); %Pre alloc

%Patient data matrix
for i = 1:Num_Rows
    for j = 1:Num_Cols
        
        if strcmp(PatientText{i,j}, 'OUT')
            Temp_String = 'OUT';
            Patient_Matrix{i,j}= 'OUT';
            
        elseif ~isempty(PatientText{i,j})
            
            Temp_String = PatientText{i,j};
            Patient_Matrix{i,j} = Temp_String;
            
        elseif isempty(PatientText{i,j})
            
            Patient_Matrix{i,j} = Temp_String;
            
        end
    end
    Temp_String = 'OUT';
end

%********Rearrange to be in the correct reading format
Temp_Mat = fliplr(Patient_Matrix);

for i = 1:Num_Rows
    for j = 1:(Num_Cols-1)
        PatientFinal{i,j} = Temp_Mat{i,j}; %Get the final
    end
end

%***********Put the found labels in the correct locations
AnatomicalLabels = cell(1,numel(SignalLabels));
for u = 1:numel(SignalLabels)
    [Row,Col] = find(strcmp(SignalLabels{u}, ElectrodeContactList)); %Find all instances of each particular location
    AnatomicalLabels{u} = PatientFinal{Row(1),Col(1)}; %Allocate the labels to a structure
end

