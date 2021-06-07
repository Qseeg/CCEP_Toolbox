function [AnatomicalLabels,ElectrodeLabels] = CCEPMapImport(PatientName,SignalLabels)
%[AnatomicalLabels,,ElectrodeLabels] = CCEPMapImport(PatientName,SignalLabels)
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
MapSearchName = sprintf('%s Map.xlsx',PatientName);
MapImportFlag = 1;

%Search for the electrode file based on the the patient name
if isempty(which(MapSearchName))
    MapImportFlag = 1;
else
    MapImportFlag = 0;
    [P,N,E] = fileparts(which(MapSearchName));
    addpath(P);
    MapFile = ShortFileName(MapSearchName);
end

%If no electrode file was found using the automatic routine, then ask the user to enter a file
if MapImportFlag == 1
    [MapFile, P] = uigetfile('*.xlsx','Get the anatomical map corresponding to the patient you are using');
    addpath(P);
end

%Check if there are sheetnames of 'Formatted' | 'Final', if there
%are, then default to using those
[~, SheetNames] = xlsfinfo(MapFile);
[~,Temp1] = StrFindCell(upper(SheetNames),'FORM');
[~,Temp2] = StrFindCell(upper(SheetNames),'FINA');
Ind = find(Temp1 | Temp2);

%Select those inds, and then use them to the data out if they are
%present
if ~isempty(Ind)
    if size(Ind, 1) > 1
        Ind = Ind(1);
    end
    [~,PatientText,~] = xlsread(MapFile,SheetNames{Ind});
    
    %Otherwise, if the sheetnames are only 'Sheet 1', 'Sheet 2' and
    %so on (left as default), look through those to see which has
    %data and then select the highest number with data in it, and
    %use that
else
    [Ind] = StrFindCell(upper(SheetNames),'SHEET');
    if ~isempty(Ind)
        
        PatientText = {};
        Flag = false(1,length(SheetNames));
        for a = 1:length(SheetNames)
            %Check the size of the data in each sheet
            [~,PatientText{a},~] = xlsread(MapFile,SheetNames{a});
            
            %If there is data in that sheet, and that data is
            %larger than a 5x5 dimension, then assign the data as
            %valid
            if ~isempty(PatientText{a})
                if size(PatientText{a},1)>5 && size(PatientText{a},2)>5
                    Flag(a) = true;
                else
                    Flag(a) = false;
                end
            end
        end
        
        %Check that at least one sheet has data in it, if none do,
        %throw an error
        if sum(Flag) == 0
            error(sprintf('No valid Map found or selected for %s', MapFile));
        else
            %Choose the highest sheetname with data in it to import the
            %data
            Ind = find(Flag == 1);
            Ind = Ind(end);
            PatientText = PatientText(Ind);
        end
        
    else
        error(sprintf('No valid Map found or selected for %s', MapFile));
    end
    
end

%Assign the number of rows and columns as temp vars
NumRows = size(PatientText,1);
NumCols = size(PatientText,2);

%Make up a dummy electrode naming map to cross check the location of contacts
for p = 1:NumRows
    expression = '’'; %Change all of the bad invreted commas to matlab font
    replace = '''';
    EName = regexprep(PatientText{p,1},expression,replace);
    for o = 1:(NumCols -1)
        ElectrodeContactList{p,o} = sprintf('%s%i',EName,o);
    end
end

%***********Read in all of the data
Patient_Matrix = cell(NumRows, NumCols); %Pre alloc

%Patient data matrix
for i = 1:NumRows
    for j = 1:NumCols
        
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
TempMat = fliplr(Patient_Matrix);

for i = 1:NumRows
    for j = 1:(NumCols-1)
        PatientFinal{i,j} = TempMat{i,j}; %Get the final
    end
end

%***********Put the found labels in the correct locations
if exist('SignalLabels','var')
    AnatomicalLabels = cell(1,length(SignalLabels));
    for u = 1:length(SignalLabels)
        [Row,Col] = find(strcmp(SignalLabels{u}, ElectrodeContactList)); %Find all instances of each particular location
        AnatomicalLabels{u} = PatientFinal{Row(1),Col(1)}; %Allocate the labels to a structure
    end
else
    AnatomicalLabels = {};
end
