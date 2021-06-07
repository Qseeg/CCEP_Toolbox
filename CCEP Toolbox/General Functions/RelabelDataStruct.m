function [DataStruct] = RelabelDataStruct(DataStruct)
%[DataStruct] = RelabelDataStruct(DataStruct);
%   This function takes in the data structure and relabels it accordin to
%   which primary site is key. It rewrites only the anatomical
%   labels (not template) and the accordingly adjusts the Bipolar labels.
%   It then passes the data structure back.
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


% for u = 1:length(DataStruct.Uni)
%     TempLabel = DataStruct.Uni(u).Anatomical;
%     TempLabel = PrimaryAnatomicalLabel(TempLabel);
%     
%     Rename just the insula apex label
%     if ~isempty(regexpi(TempLabel,'(insula)|(apex)'))
%         if ~isempty(regexpi(TempLabel,'Left'))
%             TempLabel = 'Left Insula Apex';
%         else
%             TempLabel = 'Right Insula Apex';
%         end
%     end
%     
%     Also rename the Hippo head
%     if ~isempty(regexpi(TempLabel,'(hippo head)'))
%         if ~isempty(regexpi(TempLabel,'Left'))
%             TempLabel = 'Left Hippocampus';
%         else
%             TempLabel = 'Right Hippocampus';
%         end
%     end
%     
%     And parahippocampal gyrus
%     if ~isempty(regexpi(TempLabel,'(Parahippocampal)'))
%         if ~isempty(regexpi(TempLabel,'Left'))
%             TempLabel = 'Left PHG';
%         else
%             TempLabel = 'Right PHG';
%         end
%     end
%     
%     And parahippocampal gyrus
%     if ~isempty(regexpi(TempLabel,'(Pars Trianglulais)'))
%         if ~isempty(regexpi(TempLabel,'Left'))
%             TempLabel = 'Left PTri';
%         else
%             TempLabel = 'Right PTri';
%         end
%     end
%     DataStruct.Uni(u).Anatomical = TempLabel;
% end


%Now stitch the unipolar labels together corerctly (in the bipolar struct)
for v = 1:length(DataStruct.Bi)
    UniInds = DataStruct.Bi(v).UnipolarContacts;
    
    %If the labels are different, hyphenate them, if not just keep the only
    %unique one
    if strcmp(DataStruct.Uni(UniInds(1)).Anatomical, DataStruct.Uni(UniInds(2)).Anatomical)
        DataStruct.Bi(v).Anatomical = sprintf('%s',DataStruct.Uni(UniInds(1)).Anatomical);
    else
        DataStruct.Bi(v).Anatomical = sprintf('%s-%s',DataStruct.Uni(UniInds(1)).Anatomical, DataStruct.Uni(UniInds(2)).Anatomical);
    end
end
