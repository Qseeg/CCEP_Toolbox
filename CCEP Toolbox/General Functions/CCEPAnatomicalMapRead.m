function [ElectrodeLabel] = CCEPAnatomicalMapRead(MapFile, SheetName)
%[AnatomicalLabels] = CCEPAnatomicalMapRead(PatientName,SignalLabels)
%AnatomicalLabels = Cell of corresponding anatomical Label for the given
%signal labels
%PatientName = Pname from struct
%SignalLabels = Cell of all of the good labels i.e
%{'TP''1','TP''2',....'X''15'} which should just be a {SigStruct.Labels} input

%Let the user know that the function has begun
fprintf('Loading Anatomical Map');

%Get whether the xlsx file is compatible and what the names of the sheets
%are
try %Try with xlsfinfo (might fail because of linux/mac using openoffice)
    [~,FoundSheetName] = xlsfinfo(MapFile);
    
    %Check which sheet you should be using, if the xlsx file contains the sheet
    %"Formatted"/"Valid"/"Final"
    if ~exist('SheetName','var')
        if sum(~cellfun(@isempty, (strfind(upper(FoundSheetName), 'FORMAT'))))==1
            SheetName = FoundSheetName{find(~cellfun(@isempty, (strfind(upper(FoundSheetName), 'FORMAT'))))};
        elseif sum(~cellfun(@isempty, (strfind(upper(FoundSheetName), 'VALID'))))==1
            SheetName = FoundSheetName{find(~cellfun(@isempty, (strfind(upper(FoundSheetName), 'VALID'))))};
        elseif sum(~cellfun(@isempty, (strfind(upper(FoundSheetName), 'FINAL'))))==1
            SheetName = FoundSheetName{find(~cellfun(@isempty, (strfind(upper(FoundSheetName), 'FINAL'))))};
        else
            SheetName = FoundSheetName{1};
        end
    end
catch
    warning(sprintf('xlsfinfo failed, using the "Sheet 1" sheetname of %s\nIf this does not exist, please change the sheetname in the correct spreadsheet file',MapFile));
    SheetName = 'Sheet 1';
end

%Look for a file that is within the folder you are wanting to process that
%is an xlsx and has the word map in the filename
[Number, MapText, ~] = xlsread(MapFile, SheetName); %Get the Mapfile and the specific sheet relevant to the patient
[NumRow, NumCol] = size(MapText); %Use the dimensions to see the number of electrodes and contacts in the maximal one

%Make up a dummy electrode naming map to cross check the location of contacts
for a = 1:NumRow
    Expression = '\W'; %Change all of the bad inverted commas to matlab font
    Replace = '''';
    ElectrodeName{a} = regexprep(MapText{a,1},Expression,Replace);
    for b = 1:length(Number)
        ElectrodeContactList{a,b} = sprintf('%s%i',ElectrodeName{a},b);
        ElectrodeList{a,b} = ElectrodeName{a};
        ContactList(a,b) = b;
    end
end

%Read in all of the data and create the patient data matrix
PatientMatrix = cell(NumRow, length(Number)); %Pre alloc
for a = 1:NumRow
    
    %For each contact, use the label before it (moving mesially) the same
    %as the previous one. If no label is contained in the most lateral
    %contact, make the label 
    for b = 1:NumCol
        if strcmp(MapText{a,b}, 'OUT')
            TempString = 'OUT';
            PatientMatrix{a,b}= 'OUT';
        elseif isempty(MapText{a,b}) && (b == 2)
            TempString = 'OUT';
            PatientMatrix{a,b}= 'OUT';
        elseif ~isempty(MapText{a,b})
            TempString = MapText{a,b};
            PatientMatrix{a,b} = TempString;
        elseif isempty(MapText{a,b})
            PatientMatrix{a,b} = TempString;
        end
    end
    
    %As you finish the current electrode, make the starting 
    %string 'OUT' just in case.
    TempString = 'OUT'; 
end

%Flip the data to be in the correct reading format (for concatenating the
%elctrode contacts in matlab)
PatientMatrix = fliplr(PatientMatrix);
for a = 1:NumRow
    for b = 1:length(Number)
        AnatomicalLabel{a,b} = PatientMatrix{a,b}; %Get the final
    end
end

%Create a concatenated structure with the corresponding electrode contact
%and the corresponding anatomical labels side by side
for a = 1:numel(ElectrodeContactList)
    ElectrodeLabel(a).Label = ElectrodeContactList{a};
    ElectrodeLabel(a).Anatomical = AnatomicalLabel{a};
    ElectrodeLabel(a).Electrode = ElectrodeList{a};
    ElectrodeLabel(a).Contact = ContactList(a);
    
end

%Reorder  the label list to be in the correct electrode groupings
[~,Reorder] = sort_nat({ElectrodeLabel.Label});
ElectrodeLabel = ElectrodeLabel(Reorder);

%Show that the function finished successfully
fprintf('\tComplete\n');



