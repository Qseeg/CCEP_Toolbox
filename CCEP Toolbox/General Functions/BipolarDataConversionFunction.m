function BipolarData = BipolarDataConversionFunction(DataStruct, Action)
%Sig = BipolarDataConversionFunction(Sig,Action)
%Sig = Data Structure (of Unipolar Data)
%Action = Optional to specify whether data should be recomputed, options
%include:
%Action = 'data' - return the signal data with the structure
%Action = 'info' - return the channel labels with no data (default)
%Outgoing fields
% Sig.Label
% Sig.Electrode
% Sig.Contact
% Sig.Anatomical
% Sig.OriginalLabel


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


%****************Create the Bipolar Data ***************************
Counter = 1; %Set the counter to read the new data and labels into
ElectrodeCounter = 1;

%*******Specify whether data processing is required
if (nargin > 1)
    if ~isempty(regexpi(Action, 'dat')) %Look for the phrase 'data'
        Action = 'Data';
    elseif ~isempty(regexpi(Action, 'lab|inf')); %Look for 'labels' or 'info' in the input string (action)
        Action = 'Info';
    else
        Action = 'Info'; %Defulat to just processing info
    end
end

if isfield(DataStruct,'Uni')
    DataStruct = DataStruct.Uni; %If the structure passed was only the signal struct, rename it to the right format
end

DataCounter = 1;
UnipolarData = DataStruct;
for r = 1:(length(UnipolarData)-1)
    
    
    CurrentLabel = UnipolarData(r).Label; %Get the label
    NextLabel = UnipolarData(r+1).Label;
    
    CurrentElectrode = UnipolarData(r).Electrode; %
    NextElectrode = UnipolarData(r+1).Electrode;
    
    CurrentContact = UnipolarData(r).Contact; %Get the numbers of the contacts under analysis
    NextContact = UnipolarData(r+1).Contact;
    
    DiffContact = NextContact - CurrentContact; %Get the difference in numbers between the
    
    if strcmpi(CurrentElectrode, NextElectrode) &&  DiffContact == 1
        BipolarData(DataCounter).Label = sprintf('%s-%s',CurrentLabel, NextLabel); %Get the label of both contacts and make a new one
        BipolarData(DataCounter).Electrode = CurrentElectrode; %Assignm the current electrode to the bipolar struct
        BipolarData(DataCounter).Contact = [CurrentContact, NextContact];
        if strcmpi(UnipolarData(r).Anatomical,UnipolarData(r+1).Anatomical) %If the anatomical label is the same, make it a single label
            BipolarData(DataCounter).Anatomical = UnipolarData(r).Anatomical;
        else %If labels are different, make a compound label
            BipolarData(DataCounter).Anatomical = sprintf('%s-%s',UnipolarData(r).Anatomical, UnipolarData(r+1).Anatomical);
        end
        
        %Get the bipolar labels of the template MNI coOrd found channels
        if isfield(UnipolarData,'TemplateAnatomical') %Check if teh labels acquired from the MNI template firstly exist, and if so apply the same process to them as the regular anatomical labels
            if strcmpi(UnipolarData(r).TemplateAnatomical,UnipolarData(r+1).TemplateAnatomical) %If the anatomical label is the same, make it a single label
                BipolarData(DataCounter).TemplateAnatomical = UnipolarData(r).TemplateAnatomical;
            else %If labels are different, make a compound label
                BipolarData(DataCounter).TemplateAnatomical = sprintf('%s-%s',UnipolarData(r).TemplateAnatomical, UnipolarData(r+1).TemplateAnatomical);
            end
        end
        
        %Create cells of the individual Original Labels for the Bipolar Data
        BipolarData(DataCounter).OriginalLabel = {UnipolarData(r).OriginalLabel, UnipolarData(r+1).OriginalLabel}; %Put teh original labes into a cell for later use
        
        %Get the CoOrdinate Data of the structures 
        BipolarData(DataCounter).CoOrds = mean([UnipolarData(r).CoOrds; UnipolarData(r+1).CoOrds],1); %Take the mean of the electrode locations
        
        if isfield(UnipolarData,'TissueProb') %Check if there are any tissue probabilities in the data structure
            BipolarData(DataCounter).TissueProb = mean([UnipolarData(r).TissueProb; UnipolarData(r+1).TissueProb],1); %Take the mean of the electrode locations
        end
        if isfield(UnipolarData,'MNICoOrds') %Check if there are MNI CoOrds assigned to the structure
            BipolarData(DataCounter).MNICoOrds = mean([UnipolarData(r).MNICoOrds; UnipolarData(r+1).MNICoOrds],1); %Take the mean MNI electrode locations
        end
        
        if isfield(UnipolarData,'FileName') %Check if there are the names of files allocated to the data
            BipolarData(DataCounter).FileName{1} = UnipolarData(r).FileName; 
            BipolarData(DataCounter).FileName{2} = UnipolarData(r+1).FileName; 
        end
        
        switch Action %Check if data is desired
            case 'Data'
                if isfield(UnipolarData, 'Data') %If data is already loaded (and processed) augment the data
                    BipolarData(DataCounter).Data = UnipolarData(r).Data - UnipolarData(r+1).Data;
                end
        end
        BipolarData(DataCounter).Type = 'Bipolar';
        BipolarData(DataCounter).UnipolarContacts = [r,r+1]; %Record the contacts used from the unipolar structure
        DataCounter = DataCounter +1;
    end
end
