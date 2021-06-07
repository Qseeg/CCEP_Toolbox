function BipoData = CCEPBipoImportDataConvert(ImportData,DataStruct)
%BipoData = CCEPBipoImportDataConvert(ImportData,DataStruct);
%Use this to convert imported data (as a block) without having to 
%make 2 copies at once (might crash RAM)
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


%Check that all labels are unipolar
if ~isempty(setdiff({ImportData.Label},{DataStruct.Uni.Label},'stable')) 
    error('Data passed to CCEPBipconvert that is not a unipolar channel');    
end
%Sort the unipolar data
for a = 1:length(ImportData)
   ImportData(a).UnipolarInd = find(strcmp({DataStruct.Uni.Label},{ImportData(a).Label}));
end
[~,Ind] = sort([ImportData.UnipolarInd]);
ImportData = ImportData(Ind);

%Get only the good inds for the bipolar channels which can be made from the
%unipolar data
BipoChan = false(1,length(DataStruct.Bi));
for a = 1:length(BipoChan)
    BipoChan(a) = sum(ismember([ImportData.UnipolarInd],DataStruct.Bi(a).UnipolarContacts))==2;
end

%Bring in the imported data, as well as dummy unipolar data for all of the 
%missing unipolar channels (copy the data from ImportData(1))
for a = 1:length(DataStruct.Uni) 
    Temp(a).Label = DataStruct.Uni(a).Label;
    Ind = find(strcmp({ImportData.Label},{DataStruct.Uni(a).Label}));
    if ~isempty(Ind)
        Temp(a).Data = ImportData(Ind).Data;
        Temp(a).GoodInd = 1;
    else
        Temp(a).Data = ImportData(1).Data;
        Temp(a).GoodInd = 0;
    end
    
    %Clear the data as you go (from the original datastruct) so as not to
    %get a memory error
    if Ind ~= 1
    ImportData(Ind).Data = [];
    end
end
ImportData = Temp;
clearvars Temp;

%Init the structure for the bipolar data
BipoData(length(DataStruct.Bi)).Label = DataStruct.Bi(end).Label;
BipoData(length(DataStruct.Bi)).Data = ImportData(end).Data;
BipoData(length(DataStruct.Bi)).GoodInd = ImportData(end).GoodInd;

%Compute the Data for the Bipolar Data
for e = 1:length(DataStruct.Bi)
   %Subtract the more lateral from the mesial contact
   BipoData(e).Data = ImportData(DataStruct.Bi(e).UnipolarContacts(1)).Data - ImportData(DataStruct.Bi(e).UnipolarContacts(2)).Data; 
   BipoData(e).Label = DataStruct.Bi(e).Label; 
   BipoData(e).GoodInd = ImportData(DataStruct.Bi(e).UnipolarContacts(1)).GoodInd + ImportData(DataStruct.Bi(e).UnipolarContacts(2)).GoodInd;
   
   %Clear data to free memory
   ImportData(DataStruct.Bi(e).UnipolarContacts(1)).Data = []; 
end

%Trim the data down to match only the valid data indexes (those which both
%had a unipolar channel present
Ind = [BipoData.GoodInd]==2;
BipoData = BipoData(Ind);
BipoData = rmfield(BipoData,'GoodInd');



