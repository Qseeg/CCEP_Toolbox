function CCEPAnnotationEditor(varargin)
%CCEPAnnotation editor - works with the 

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


%Anotations rewrite editor

%New Annotation Window
%Make sure there are no other versions of the SEEGFig available
AnnotEditorFig = findobj('Tag','AnnotEditorFig');
if isempty(AnnotEditorFig)
    AnnotEditorFig = figure('Name','Annotation Editor Figure','Tag','AnnotEditorFig','units','normalized','position',[0.2 0.2 0.2 0.5]);
else
    figure(AnnotEditorFig.Number);
    return;
end

%Get the handles to the important figure items
SEEGFig = findobj('Tag','SEEGFig');
AmplitudeScaling = findall(SEEGFig, 'Tag', 'AmplitudePopUp');
TimeScaling = findall(SEEGFig, 'Tag', 'TimeSpanPopUp');
ChannelList = findall(SEEGFig, 'Tag', 'ChannelList');
Slider = findall(SEEGFig, 'Tag', 'SEEGSlider');
DataAxes = findall(SEEGFig, 'Tag', 'SEEGDataAxes');
RefSelect = findall(SEEGFig, 'Tag', 'RefSelectPopUp');
AnnotMenu = findall(SEEGFig, 'Tag', 'AnnotationPopUp');
AnnotList = findobj(AnnotEditorFig, 'Tag', 'AnnotList');

%Bring in some data that is needed
Annotations = SEEGFig.UserData.Annotations;
DataFile = SEEGFig.UserData.DataFile;

%Write the heading of the figure
HeadingText = uicontrol('Style','text','units','normalized','Position',[0.1 0.9 0.9 0.1],'String','Edit, add and save pulses & annotations','FontSize',16);

%Make the list of current annotations
ListText = uicontrol('Style','text','units','normalized','Position',[0.0 0.85 0.7 0.05],'String','Select annotation to alter','FontSize',14);
AnnotList = uicontrol('Style','list','units','normalized','Position',[0.05 0.35 0.9 0.5],'Max',1,'Min',0,'Tag','AnnotList','String',{Annotations.Comment},'Value',1,'CallBack',@CCEPAnnotationCallback,'FontSize',12);
AnnotEditorFig.UserData.CurrentAnnot = AnnotList.Value;


%Edit Annotation text
EditAnnotationText = uicontrol('Style','text','units','normalized','Position',[0 0.30 0.6 0.05],'String','Type the annotation below','FontSize',14);
EditAnnotation = uicontrol('Style','edit','String',Annotations(1).Comment,'units','normalized','Position', [0.01 0.255 0.98 0.05],'Tag','EditAnnotation','FontSize',12);

%Create buttons to input the annotation or alter the currently selected
%annotation
ReplaceAnnotation = uicontrol('Style','pushbutton','String','Replace current annot','units','normalized','Position', [0.01 0.20 0.48 0.05],'Tag','ReplaceAnnotation', 'CallBack',@CCEPAnnotationCallback,'FontSize',12);
DeleteAnnotation = uicontrol('Style','pushbutton','String','Delete current annot','units','normalized','Position', [0.51 0.20 0.48 0.05],'Tag','DeleteAnnotation', 'CallBack',@CCEPAnnotationCallback,'FontSize',12);
CreateAnnotation= uicontrol('Style','pushbutton','String','Create annotation (using cursor in SEEGFig)','units','normalized','Position', [0.01 0.15 0.98 0.05],'Tag','CreateAnnotation','CallBack',@CCEPAnnotationCallback,'FontSize',12);

%Automatically acquire all pulses using a trigger channel
AutoPulseAcquireText = uicontrol('Style','text','units','normalized','Position',[0 0.08 0.6 0.05],'String','Aquire pulse triggers from channel','FontSize',14);
[~, ChannelInfo] = EDF_Read(DataFile); %Get the specific labels for the channels present
AutoPulseAcquire = uicontrol('Style','popupmenu','String',{ChannelInfo.NewLabel},'units','normalized','Position', [0.6 0.08 0.39 0.05],'Value',1,'Tag','AutoPulseAcquire', 'CallBack',@CCEPAnnotationCallback,'FontSize',12);

%Save button
SaveAnnotFileButton = uicontrol('Style','pushbutton','String','Save annotations and pulse times in .mat file','units','normalized','Position', [0.01 0.025 0.98 0.05],'Tag','SaveAnnotFileButton', 'CallBack',@CCEPAnnotationCallback,'FontSize',12);

