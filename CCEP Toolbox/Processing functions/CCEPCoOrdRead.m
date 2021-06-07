function [CoOrds,TissueProbs, MNICoOrds] = CCEPCoOrdRead(ElectrodeArray, SignalStruct)
%[CoOrds,TissueProbs, MNICoOrds] = CCEPCoOrdRead(PatientName, SignalStruct)
%Returns the unipolar co-ords of the patients input co-ordinates from the
%array of compiled patient electrodes If Tissue probabilities are assigned
%to each electrode, they will be available if you output a second argument


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



ENames = sort_nat(unique({ElectrodeArray.ElectrodeName})); %Get the unique electrode names
SNames = sort_nat(unique({SignalStruct.Electrode}));
        for y = 1:length(ENames)
            %Allocate the CoOrds for the unipolar signal
            EInds = find(strcmp(ENames{y},{ElectrodeArray.ElectrodeName})); %Find the labels in the electrode array file
            SInds = find(strcmp(ENames{y},{SignalStruct.Electrode})); %Find the labels in the results file
            
            for g = 1:length(SInds)
                TInds(g) = SignalStruct(SInds(g)).Contact; %Get the number of the contacts present in the signal files
            end
            
            for p = 1:length(SInds)
                CoOrds(SInds(p),:) = ElectrodeArray(EInds).PosMM(TInds(p),:); %Allocate the co-ord based on the number of the contact of the file
                
                %********Check if there are tissue probabilities assigned
                %to the structure
                if isfield(ElectrodeArray,'TissueProb') && (nargout>=2)
                    TissueProbs(SInds(p),:) = ElectrodeArray(EInds).TissueProb(TInds(p),:); %Allocate the co-ord based on the number of the contact of the file
                end
                
                %********Check if the MNI CoOrdinates are assigned to the
                %structure and have them outputting if so
                if isfield(ElectrodeArray,'PosMNI') && (nargout>=2)
                    MNICoOrds(SInds(p),:) = ElectrodeArray(EInds).PosMNI(TInds(p),:); %Allocate the co-ord based on the number of the contact of the file
                end 
            end
            clearvars SInds TInds
        end
    end


