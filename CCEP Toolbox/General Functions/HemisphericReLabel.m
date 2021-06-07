function DataStruct = HemisphericReLabel(DataStruct)
%DataStruct = HemisphericReLabel(DataStruct)
%   Use this function to put left and right in front of the anatomical
%   labels depending on the X Co-Ord of the Electrode CoOrd


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


%Check if the data struct is already left and right labeled, and if it is
%then break this function and continue as normal
ExitFlag = 0;
if length(DataStruct.Uni)<10
   
    [~,LeftMask] = StrFindCell({DataStruct.Uni(1:length(DataStruct.Uni)).Anatomical},'Left');
    [~,RightMask] = StrFindCell({DataStruct.Uni(1:length(DataStruct.Uni)).Anatomical},'Right');
    CombinedMask = LeftMask|RightMask;
    if sum(CombinedMask) == length(DataStruct.Uni)
        ExitFlag = 1;
    end
    
else
    [~,LeftMask] = StrFindCell({DataStruct.Uni(1:10).Anatomical},'Left');
    [~,RightMask] = StrFindCell({DataStruct.Uni(1:10).Anatomical},'Right');
    CombinedMask = LeftMask|RightMask;
    if sum(CombinedMask) == 10
        ExitFlag = 1;
    end
end
    
%Break tnhe function if you find that the data structure is already
%relabelled - but before doing so, just re-condition the labels so that
%excess Left and Right instances and spaces are removed
if ExitFlag == 1
    TempLabel = {DataStruct.Uni.Anatomical};
    for c = 1:length(TempLabel)
        %Get rid of dupplicate hemipheric labels and double spaces
        %which could throw labelling off
        TempLabel{c} = strrep(TempLabel{c}, '   ',' ');
        TempLabel{c} = strrep(TempLabel{c}, '  ',' ');
        TempLabel{c} = strrep(TempLabel{c}, 'Left Left','Left');
        TempLabel{c} = strrep(TempLabel{c}, 'Left Left Left','Left');
        TempLabel{c} = strrep(TempLabel{c}, 'Right Right','Right');
        TempLabel{c} = strrep(TempLabel{c}, 'Right Right Right','Right');
        DataStruct.Uni(c).Anatomical = TempLabel{c};
    end
    BipolarData = BipolarDataConversionFunction(DataStruct, 'Info');
    DataStruct.Bi = BipolarData;
    
    %Then return once that datastruct is conditioned
    return;
end

%Look through the unipolar labels and find which need to be redone
for f = 1:length(DataStruct.Uni)
    %Check if the contact is invalid or has already got a hemisphere assigned
    LeftFound = strfind(upper(DataStruct.Uni(f).Anatomical),'LEFT');
    RightFound = strfind(upper(DataStruct.Uni(f).Anatomical),'RIGHT');
    InvalidFound = strfind(upper(DataStruct.Uni(f).Anatomical),'OUT');
    
    if isempty(InvalidFound) %&& isempty(RightFound) && isempty(LeftFound)
        if DataStruct.Uni(f).CoOrds(1)<=0
            if ~isempty(RightFound)
                DataStruct.Uni(f).Anatomical = sprintf('Right %s',DataStruct.Uni(f).Anatomical);
            else
                DataStruct.Uni(f).Anatomical = sprintf('Left %s',DataStruct.Uni(f).Anatomical);
            end
        else
            if ~isempty(LeftFound)
                DataStruct.Uni(f).Anatomical = sprintf('Left %s',DataStruct.Uni(f).Anatomical);
            else
                DataStruct.Uni(f).Anatomical = sprintf('Right %s',DataStruct.Uni(f).Anatomical);
            end
        end
    end
end

%Condition the labels to remove spaces and also to get rid of extra 'Left'
%and 'Right' instances
TempLabel = {DataStruct.Uni.Anatomical}; 
for c = 1:length(TempLabel)
    %Get rid of dupplicate hemipheric labels and double spaces
    %which could throw labelling off
    TempLabel{c} = strrep(TempLabel{c}, '   ',' ');
    TempLabel{c} = strrep(TempLabel{c}, '  ',' ');
    TempLabel{c} = strrep(TempLabel{c}, 'Left Left','Left');
    TempLabel{c} = strrep(TempLabel{c}, 'Left Left Left','Left');
    TempLabel{c} = strrep(TempLabel{c}, 'Right Right','Right');
    TempLabel{c} = strrep(TempLabel{c}, 'Right Right Right','Right');
    DataStruct.Uni(c).Anatomical = TempLabel{c};
end
BipolarData = BipolarDataConversionFunction(DataStruct, 'Info');
DataStruct.Bi = BipolarData;