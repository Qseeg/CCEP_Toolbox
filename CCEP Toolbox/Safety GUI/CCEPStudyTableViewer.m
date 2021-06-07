function CCEPStudyTableViewer(varargin)
%CCEPStudyTableViewer
%View key parameters from the listed CCEP studies (all I could find before
%late-ish 2019)


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


%Import the key table data from the
CCEPStimSafetyFig = findobj('Tag','CCEPStimSafetyFig');
CCEPStimSafetyTableFig = findobj('Tag','CCEPStimSafetyTableFig');
StudyList = findobj(CCEPStimSafetyFig,'Tag','StudyList');
StudyDetails = CCEPStimSafetyFig.UserData;

if isempty(CCEPStimSafetyTableFig)
    figure('Name','CCEPStimSafetyTableFig','Tag','CCEPStimSafetyTableFig','Units','normalized','Position',[0 0 1 1]);
else
    figure(CCEPStimSafetyTableFig)
    clf;
end

%Put a title up the top left of the figure
uicontrol('Style','text','units','normalized','position',[0.003 0.96 0.4 0.04], 'String','Stimulation and sampling parameters of chosen studies','FontSize',20);

%Create the table from the data selected in the Study List (in the main
%saefty figure)
Ind = StudyList.Value;
TableCounter = 1;
for a = 1:length(Ind)
    
    %Get the charge density
    ChargeDensity = StudyDetails(Ind(a)).PulseCharge/StudyDetails(Ind(a)).ElectrodeArea;
    
    %Plug in the Table Data
    TableData{TableCounter,1} = StudyDetails(Ind(a)).Publication;
    TableData{TableCounter,2} = StudyDetails(Ind(a)).NumPatient;
    TableData{TableCounter,3} = StudyDetails(Ind(a)).StudyPurpose;
    TableData{TableCounter,4} = num2str(StudyDetails(Ind(a)).AgeRange); %num2str those with multiple numbers in each cell
    TableData{TableCounter,5} = StudyDetails(Ind(a)).Modality;
    TableData{TableCounter,6} = StudyDetails(Ind(a)).WaveForm;
    TableData{TableCounter,7} = StudyDetails(Ind(a)).ElectrodeArea;
    TableData{TableCounter,8} = num2str(StudyDetails(Ind(a)).PulseTrainLength);
    TableData{TableCounter,9} = num2str(StudyDetails(Ind(a)).StimFreq);
    TableData{TableCounter,10} = StudyDetails(Ind(a)).MaxCurrent;
    TableData{TableCounter,11} = StudyDetails(Ind(a)).PW;
    TableData{TableCounter,12} = StudyDetails(Ind(a)).PulseCharge;
    TableData{TableCounter,13} = ChargeDensity;
    TableData{TableCounter,14} = num2str(StudyDetails(Ind(a)).SamplingFreq);
    TableData{TableCounter,15} = num2str(StudyDetails(Ind(a)).Filtering);
    
    TableCounter = TableCounter + 1;
    
end

%Make the columns and plot the uitable
CWidth = {180, 90, 200, 90, 120, 120, 90, 90, 90, 90, 90, 90, 90, 90, 150};
TempTable = uitable('Units','Normalized','Position',[0.01 0.01 0.95 0.95],'Tag','StimTable', 'ColumnName',{'Publication','NumPatients','Study Purpose','Age Range','Modality','Waveform','Electrode Area', 'Pulses per train','Stim Frequency', 'Max Current','Pulse Width', 'Charge', 'Charge Density','Sampling Freq', 'Filtering'},'ColumnWidth',CWidth,'Data',TableData,'FontSize',12);