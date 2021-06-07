function CCEPAnnotationCallback(varargin)
%CCEPAnnotationCallback - works with the CCEPAnnotation function to alter
%all of the SEEGFig and annotation menu's and lists


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


AnnotEditorFig = findobj('Tag','AnnotEditorFig');
if isempty(AnnotEditorFig)
    AnnotEditorFig = figure('Name','Annotation Editor Figure','Tag','AnnotEditorFig','units','normalized','position',[0.2 0.2 0.2 0.5]);
else
    figure(AnnotEditorFig.Number);
end

%Get the caller function
Source = varargin{1}.Tag;

%Get the handles to the important figure items
SEEGFig = findobj('Tag','SEEGFig');
TimeScaling = findall(SEEGFig, 'Tag', 'TimeSpanPopUp');
ChannelList = findall(SEEGFig, 'Tag', 'ChannelList');
Slider = findall(SEEGFig, 'Tag', 'SEEGSlider');
DataAxes = findall(SEEGFig, 'Tag', 'SEEGDataAxes');
AnnotMenu = findall(SEEGFig, 'Tag', 'AnnotationPopUp');
AnnotList = findobj(AnnotEditorFig, 'Tag', 'AnnotList');
EditAnnotation = findobj(AnnotEditorFig, 'Tag', 'EditAnnotation');
ReplaceAnnotation = findobj(AnnotEditorFig, 'Tag', 'ReplaceAnnotation');
CreateAnnotation = findobj(AnnotEditorFig, 'Tag', 'CreateAnnotation');
SaveAnnotFileButton = findobj(AnnotEditorFig, 'Tag', 'SaveAnnotFileButton');
AutoPulseAcquire = findobj(AnnotEditorFig, 'Tag', 'AutoPulseAcquire');
Annotations = SEEGFig.UserData.Annotations;
DataStruct = SEEGFig.UserData.DataStruct;
PulseTimes = SEEGFig.UserData.PulseTimes;
DataFile = SEEGFig.UserData.DataFile;
PatientName = SEEGFig.UserData.PatientName;


%Get the buttons and the edit text fields from teh CCEPAnnotFig
switch Source
    %If an annot is selected from the list, simply put it in the
    %EditAnnotation string
    case 'AnnotList'
        EditAnnotation.String = AnnotList.String{AnnotList.Value};
        AnnotMenu.Value = AnnotList.Value;
        CCEPSEEGRedisplay;
        
        %Replace the annotation, and then update the SEEG data axes
    case 'ReplaceAnnotation'
        AnnotList.String{AnnotList.Value} = EditAnnotation.String;
        for a = 1:length(Annotations)
            Annotations(a).Comment = AnnotList.String{a};
        end
        AnnotMenu.String = {Annotations.Comment};
        SEEGFig.UserData.Annotations = Annotations;
        CCEPSEEGRedisplay;
        figure(AnnotEditorFig.Number);
        
        %If the current annotation is deleted, remove it from all menus and
        %then change the selected annotation
    case 'DeleteAnnotation'
        Annotations(AnnotList.Value) = [];
        if AnnotList.Value>1
           AnnotList.Value = AnnotList.Value - 1; 
           AnnotMenu.Value = AnnotMenu.Value - 1; 
        end
        AnnotList.String = {Annotations.Comment};
        AnnotMenu.String = {Annotations.Comment};
        EditAnnotation.String = '';
        SEEGFig.UserData.Annotations = Annotations;
        CCEPSEEGRedisplay;
        figure(AnnotEditorFig.Number);
        
        %Adding an annotation
    case 'CreateAnnotation'        
        PrevAnnotations = Annotations;
        figure(SEEGFig.Number);
        axes(DataAxes);
        [X, Y] = ginput(1);
        X = round(X);
              
        %Add the annotation in edit string and then increment
        Annotations(end+1).Times = X;
        Annotations(end).Time = X;
        Annotations(end).Comment = EditAnnotation.String;
        [~,Ind] = sort([Annotations.Times]);
        Annotations = Annotations(Ind);
        
        %Update the annotations on teh SEEGFig and on the AnnotList and
        %AnnotMenu
        SEEGFig.UserData.Annotations = Annotations;
        AnnotList.String = {Annotations.Comment};
        AnnotMenu.String = {Annotations.Comment};
        
        %If the time will go before your currently selected
        %annotation (therefore bumping your current Annot down the
        %line), increment the index to keep in sync
        AnnotListInd = PrevAnnotations(AnnotList.Value).Times;
        if X<=AnnotListInd
            AnnotList.Value = AnnotList.Value+1;
        end
        CCEPSEEGRedisplay;
        figure(AnnotEditorFig.Number);
        
        %If a user requests the pulsetimes be found automatically using
        %a channel, then import that channel, search it for very sharp
        %transitions and add them to the pulses already found (if any)
    case 'AutoPulseAcquire'
        [~,~,~,ImportData] = CCEPSEEGDataImport('Patient',PatientName,'DataFile',DataFile,'Struct',DataStruct,'Label',AutoPulseAcquire.String{AutoPulseAcquire.Value});
        Temp = StimPulseFinder(ImportData.Data);
        PulseTimes(end+1:end+length(Temp)) = Temp;
        fprintf('%i Pulses acquired automatically and concatenated \n',length(Temp));
        SEEGFig.UserData.PulseTimes = PulseTimes;
        
        %Save the annotations and pulse times into an annotations file for
        %later use
    case 'SaveAnnotFileButton'
        
        %Save the file next to the .edf data file
        [P,N,E] = fileparts(which(DataFile));
        TempName = sprintf('%s%s%s Annotations.mat',P,filesep,N);
        
        %Concat the pulsetimes
        PulseTimes = SEEGFig.UserData.PulseTimes;
        TempPulse = round(SEEGFig.UserData.TempPulseTimes);
        PulseTimes(end+1:end+length(TempPulse)) = TempPulse;
        save(TempName,'Annotations','PulseTimes','-v6');
        fprintf('Annotations File saved to %s\n',ShortFileName(TempName));
end