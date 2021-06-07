function StimAnnot = CCEPStimAnnotConvert(Annot,PulseTimes,SamplingFreq,AnnotFile,StimType)
%StimAnnot = CCEPStimAnnotConvert(Annot,PulseTimes,SamplingFreq,AnnotFile)
%Convert the found annotations to valid stim pulse train numbers - works
%off the output of AnnotGrabber


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


%Assign defaults to the function
if ~exist('SamplingFreq','var')
    SamplingFreq = 1000;
end
if ~exist('PulseTimes','var')
    PulseTimes = [];
end
if ~exist('AnnotFile','var')
    AnnotFile = [];
end
if ~exist('StimType','var')
    StimType = 'CCEP';
end

Counter = 1;
for t = 1:length(Annot)
    %Check if the start or end indicator is present and find the relevenant
    %info accordingly
    if ~isempty(regexpi(Annot(t).Comment,'Stim Start'))
        StimAnnot(Counter).TimeWindow(1) = Annot(t).Times;
        Words = regexpi(Annot(t).Comment,' ','split');
        StimAnnot(Counter).Label = StimLabelReorg(Words{3});
        try %If there is an error with the level annotation, record it as 0mA
            StimAnnot(Counter).Level = str2double(Words{4}); %(isstrprop(Words{4},'digit')
        catch
            StimAnnot(Counter).Level = 0; %(isstrprop(Words{4},'digit')
        end
        
        %Find the next stim stop annotation after the current 'Stim Start'
        %one
    elseif ~isempty(regexpi(Annot(t).Comment,'Stim Stop'))
        StimAnnot(Counter).TimeWindow(2) = Annot(t).Times;
        
        %Check if a valid annotation is present, by comparing the labels
        %(to the currently assessed stim annot), if this is the first
        %annotation, set GoodFlag to 0, since there was no stim start
        Words = regexpi(Annot(t).Comment,' ','split');
        try
        GoodFlag = strcmp(Words{3},StimLabelReorg(StimAnnot(Counter).Label));
        catch
        GoodFlag = 0;    
        end
        if GoodFlag ~= 1 || (StimAnnot(Counter).TimeWindow(1) == 0)
            continue;
        end
            
        %Get the pulse times that are in the train and then the stim
        %frequency
        PulseInds = find(PulseTimes> StimAnnot(Counter).TimeWindow(1) & PulseTimes <StimAnnot(Counter).TimeWindow(2));
        StimAnnot(Counter).PulseTimes = PulseTimes(PulseInds);
        if length(PulseInds)>2
            StimAnnot(Counter).Frequency = round(1/(round(mean(diff(StimAnnot(Counter).PulseTimes)))/SamplingFreq),2);
            if StimAnnot(Counter).Frequency > 0.4 && StimAnnot(Counter).Frequency < 0.6
                StimAnnot(Counter).Frequency = 0.5;
            end
        else
            if strcmp(StimType,'Clinical')
                StimAnnot(Counter).Frequency = 50;
            else
                StimAnnot(Counter).Frequency = 0.5;
            end
            StimAnnot(Counter).Frequency = 0.5;
        end
        Counter = Counter + 1;
    end
end
if ~exist('StimAnnot','var')
    StimAnnot = [];
end