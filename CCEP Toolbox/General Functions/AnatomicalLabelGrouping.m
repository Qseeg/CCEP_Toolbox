function DataStruct = AnatomicalLabelGrouping(DataStruct)
%DataStruct = AnatomicalLabelGrouping(DataStruct);
%   Use this function to group anatomical labels in the data structure by
%   their anatomical site, by all text outside of the brackets i.e:
%   'Left FO' = 'Left FO (Dorsal)'
%   Then put this into the Unipolar and Bipolar Structures in DataStruct in
%   a field called 'ShortAnatomical'
%

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


%Check if the DataStructure has had left and right added to each label
%depending on the hemisphere it sits in CoOrd space in. If it 
if length(DataStruct.Uni(1).Anatomical) > 4
    if  ~strcmpi(DataStruct.Uni(1).Anatomical(1:4),'Left') && ~strcmpi(DataStruct.Uni(1).Anatomical(1:5),'Right')
        DataStruct = HemisphericReLabel(DataStruct);
    end
else
    DataStruct = HemisphericReLabel(DataStruct);
end

for u = 1:length(DataStruct.Uni)
    %Mark the original label and allocate a temp variable
    TempStruct(u).Original = DataStruct.Uni(u).Anatomical;
    InputStr = TempStruct(u).Original;
    FoundBrackets = {};
    SearchBrackets = {};
    
    %Find the Strings that are present both inside brackets and at the start of
    %the text
    Expr = '\w* sulcus*|(\w*?-\w*)|\w*';
    FoundSite = regexpi(InputStr, Expr,'match');
    
    %Find the text that is inside of the brackets only
    Expr = '(?<=\().*?(?=\))';
    FoundBrackets = regexpi(InputStr, Expr,'match');
    
    %Make cellstrings from the words inside the brackets so that you can
    %exclude them from the correct label using setdiff
    if ~isempty(FoundBrackets)
        for i = 1:length(FoundBrackets)
            C = strsplit(FoundBrackets{i});
            if length(C) == 1
                if ~strcmpi(C,'Left') && ~strcmpi(C,'Right')
                    SearchBrackets(end+1:end+length(C)) = C;
                end
            else
                SearchBrackets(end+1:end+length(C)) = C;
            end
        end
    else
        SearchBrackets = {};
    end
    %Find which labels are not in the brackets and keep them
    AnatomicalLabel = setdiff(FoundSite,SearchBrackets);
    
    %If Left or right is not in the first cell position, flip the cell
    %array and then concatenate them to make the original label, otherwise
    %just keep the order the same and concatenate the words to make the
    %label
    if ~strcmpi(AnatomicalLabel{1},'Left') && ~strcmpi(AnatomicalLabel{1},'Right')
        AnatomicalLabel = fliplr(AnatomicalLabel);
        AnatomicalLabel = strjoin(AnatomicalLabel);
    else
        AnatomicalLabel = strjoin(AnatomicalLabel);
    end
    
    %Allocate the correct temporary variables to the structure
    TempStruct(u).Found = AnatomicalLabel;
    TempStruct(u).Brackets = FoundBrackets;
    
end

%Look through all of the unqiue sampled sites (without specific bracketed
%identifiers) and go through and group them by overall anatomical structure
UniqueLabels = unique({TempStruct.Found});
for t = 1:length(UniqueLabels)
    FoundInds = StrFindCell({TempStruct.Found}, UniqueLabels(t));
    UniqueStruct(t).Label = UniqueLabels{t};
    UniqueStruct(t).Inds = FoundInds;
    
    for f = 1:length(FoundInds)
       DataStruct.Uni(FoundInds(f)).ShortAnatomical = UniqueLabels{t};
    end
end

for g = 1:length(DataStruct.Bi)
    TempInds = DataStruct.Bi(g).UnipolarContacts;
    
    if strcmp(DataStruct.Uni(TempInds(1)).ShortAnatomical,DataStruct.Uni(TempInds(2)).ShortAnatomical)
        DataStruct.Bi(g).ShortAnatomical = sprintf('%s',DataStruct.Uni(TempInds(1)).ShortAnatomical);    
    else
        DataStruct.Bi(g).ShortAnatomical = sprintf('%s - %s',DataStruct.Uni(TempInds(1)).ShortAnatomical,DataStruct.Uni(TempInds(2)).ShortAnatomical);
    end
end
