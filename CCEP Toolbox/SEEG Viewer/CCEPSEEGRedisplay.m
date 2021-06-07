
function CCEPSEEGRedisplay(varargin)
%SEEG Redisplay


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


%Get the handles to the important figure items
SEEGFig = findobj('Tag','SEEGFig');
AnnotEditorFig = findobj('Tag','AnnotEditorFig');
AmplitudeScaling = findall(SEEGFig, 'Tag', 'AmplitudePopUp');
TimeScaling = findall(SEEGFig, 'Tag', 'TimeSpanPopUp');
ChannelList = findall(SEEGFig, 'Tag', 'ChannelList');
Slider = findall(SEEGFig, 'Tag', 'SEEGSlider');
DataAxes = findall(SEEGFig, 'Tag', 'SEEGDataAxes');
RefSelect = findall(SEEGFig, 'Tag', 'RefSelectPopUp');
AnnotMenu = findall(SEEGFig, 'Tag', 'AnnotationPopUp');
CursorAcquire = findall(SEEGFig, 'Tag', 'CursorAcquire');
DataFilterButton = findobj(SEEGFig, 'Tag', 'DataFilterButton');
EditAnnotation = findobj(AnnotEditorFig, 'Tag', 'EditAnnotation');
AnnotList = findobj(AnnotEditorFig, 'Tag', 'AnnotList');
RemoveLastPulse = findobj(SEEGFig, 'Tag', 'RemoveLastPulse');
PulseCursor = findobj(SEEGFig, 'Tag', 'PulseCursor');
TimeCursor = findobj(SEEGFig, 'Tag', 'TimeCursor');
% TimeFreqMenu = findall(SEEGFig, 'Tag', 'TimeFreqPopupMenu');
% PulseTrainChannelMenu = findall(SEEGFig, 'Tag', 'PulseTrainChannelPopupMenu');

%If the data filtering button changes, engage the callback and erase and recompute
%the data
if DataFilterButton.Value == 0 && (SEEGFig.UserData.FilterFlag == 1)
    DataFilterButton.String = 'No filtering applied';
    SEEGFig.UserData.FilterFlag = 0;
    for r = 1:length(SEEGFig.UserData.ChannelInfo.Current)
        SEEGFig.UserData.ChannelInfo.Current(r).Data = [];
    end
    CCEPSEEGRedisplay;
elseif DataFilterButton.Value == 1 && (SEEGFig.UserData.FilterFlag == 0)
    DataFilterButton.String = 'Filtered Data';
    SEEGFig.UserData.FilterFlag = 1;
    for r = 1:length(SEEGFig.UserData.ChannelInfo.Current)
        SEEGFig.UserData.ChannelInfo.Current(r).Data = [];
    end
    CCEPSEEGRedisplay;
end

%Import the current data
ChannelInfo = SEEGFig.UserData.ChannelInfo;
DataStruct = SEEGFig.UserData.DataStruct;
SamplingFreq = ChannelInfo.Info.SamplingFreq;
DataLength = SEEGFig.UserData.ChannelInfo.Info.DataLength;

%Set the sliderstep as the samplingfreq changes
TimeBase = round(TimeScaling.UserData(TimeScaling.Value)*SamplingFreq);
if round(Slider.Value)+TimeBase >= DataLength
    Slider.Value = DataLength - (TimeBase + 1);
end
SmallStep = (TimeBase/2)/SEEGFig.UserData.DataLength; %Move 1/2 a page to when moving
LargeStep = (TimeBase)/SEEGFig.UserData.DataLength; %Move a ull page in the larger step
Slider.SliderStep = [SmallStep LargeStep];
Slider.Max = DataLength - TimeBase;

%If the annotations list was clicked - select an annotation and then reset
%it
if AnnotMenu.Value ~= AnnotMenu.UserData
    %Set the slider to move the annotation to the center of the page (or
    %the start if it is at the start
    if (SEEGFig.UserData.Annotations(AnnotMenu.Value).Time - TimeBase/2)>0
        Slider.Value = SEEGFig.UserData.Annotations(AnnotMenu.Value).Time - TimeBase/2;
    else
        Slider.Value = 1;
    end
    %Update which annotation is currently selected
    AnnotMenu.UserData = AnnotMenu.Value;
end


%If a pulse time is added, put it in a separate bank to the automatically
%acquired pulse times
if (PulseCursor.Value == 1) 
    PulseCursor.String = 'Select X Value';
    %Select the point to mark as a stim pulse
    [X, Y] = ginput(1);
    X = round(X);
    SEEGFig.UserData.TempPulseTimes(end+1) = X;   
    PulseCursor.Value = 0;
    PulseCursor.String = 'Mark pulse time';
end

%If the user requests the time, show it in the command window
if (TimeCursor.Value == 1) 
    TimeCursor.String = 'Select X Value';
    %Select the point in time to get the time for
    [X, Y] = ginput(1);
    X = round(X);
    TimeString = CCEPSample2TimeString(X, SEEGFig.UserData.SamplingFreq);
    disp(TimeString);
    TimeCursor.Value = 0;
    TimeCursor.String = 'Check the file time';
end

%If the last added pulse is requested to be removed, get rid of it if there
%are any cursor-acquired pulse times
if (RemoveLastPulse.Value == 1)
    if ~isempty(SEEGFig.UserData.TempPulseTimes)
        SEEGFig.UserData.TempPulseTimes = SEEGFig.UserData.TempPulseTimes(1:end-1);
    end
    RemoveLastPulse.Value = 0;
end


%Adjust the gain and offset and get the plotting times from the slider
TimeStart = round(Slider.Value);
TimeFinish = TimeStart + TimeBase;
Gain = 1/AmplitudeScaling.UserData(AmplitudeScaling.Value);

%Update the channelList with the current reference data
CurrentRef = RefSelect.String{RefSelect.Value};

%Switch the data if the reference changes
if strcmp(ChannelList.String{1},SEEGFig.UserData.ChannelInfo.Uni(1).Label) && ~strcmp(CurrentRef, 'Uni')
    SEEGFig.UserData.ChannelInfo.Current = SEEGFig.UserData.ChannelInfo.Bi;
    ChannelList.Value = [];
    ChannelList.String = {SEEGFig.UserData.ChannelInfo.Current.Label};
    
elseif strcmp(ChannelList.String{1},SEEGFig.UserData.ChannelInfo.Bi(1).Label) && ~strcmp(CurrentRef, 'Bi')
    SEEGFig.UserData.ChannelInfo.Current = SEEGFig.UserData.ChannelInfo.Uni;
    ChannelList.Value = [];
    ChannelList.String = {SEEGFig.UserData.ChannelInfo.Current.Label};
end

%Data Import and Export Code
switch CurrentRef
    case 'Bi'
        %Find which elements have data available
        DataInds = find(arrayfun(@(x) ~isempty(x.Data), SEEGFig.UserData.ChannelInfo.Current));
        EmptyDataInds = find(arrayfun(@(x) isempty(x.Data), SEEGFig.UserData.ChannelInfo.Current));
        
        %Find the channels to erase
        EraseChannels = setdiff(DataInds,ChannelList.Value);
        
        %Erase the data to free up memory
        for r = 1:length(EraseChannels)
            SEEGFig.UserData.ChannelInfo.Current(EraseChannels(r)).Data = [];
        end
        
        ImportInds = setdiff(ChannelList.Value,DataInds);
        BlankChannels = find(arrayfun(@(x) isempty(x.Label), SEEGFig.UserData.ChannelInfo.Current));
        ValidChanInds = setdiff(ImportInds,BlankChannels);
        
        %Organise and import the valid labels
        ValidLabels= {};
        for e = 1:length(ValidChanInds)
            %             ValidLabels(e,1:2) = SEEGFig.UserData.ChannelInfo.Current(ValidChanInds(e)).OriginalLabel(1:2);
            %             ValidLabels(e,1) = {SEEGFig.UserData.ChannelInfo.Uni(ValidChanInds(e)).Label};
            Ind = SEEGFig.UserData.ChannelInfo.Current(ValidChanInds(e)).UnipolarContacts;
            ValidLabels(e,1) = {SEEGFig.UserData.DataStruct.Uni(Ind(1)).Label};
            ValidLabels(e,2) = {SEEGFig.UserData.DataStruct.Uni(Ind(2)).Label};
        end
        
        %Get the unqiue valid labels and be sure they are in the correct
        %format for blockEdfLoad to read
        ValidLabels = unique(ValidLabels);
        if size(ValidLabels,1)>1
            ValidLabels = ValidLabels';
        end
        
        T = [];
        %Import the bipolar data by bringing in all unique channels first
        %and then stitching them together
        if ~isempty(ValidChanInds)
            %             ImportData = EDFLoading('File',SEEGFig.UserData.DataFile,'Labels',ValidLabels,'Freq',SamplingFreq);
            [~,~,~,ImportData] = CCEPSEEGDataImport('Name', SEEGFig.UserData.PatientName,'Data|EDF',SEEGFig.UserData.DataFile, 'Labels',ValidLabels,'struct',DataStruct);
            
            %Pre-alloc struct
            TempBipo(length(ValidChanInds)).Data = ImportData(1).Data;
            
            %Do the bipolar subtraction
            for t = 1:length(ValidChanInds)
                %                 T(1) = find(strcmp(SEEGFig.UserData.ChannelInfo.Current(ValidChanInds(t)).OriginalLabel{1},{ImportData.Labels}));
                %                 T(2) = find(strcmp(SEEGFig.UserData.ChannelInfo.Current(ValidChanInds(t)).OriginalLabel{2},{ImportData.Labels}));
                %                 T(1) = find(strcmp(SEEGFig.UserData.ChannelInfo.Current(ValidChanInds(t)).Label{1},{ImportData.Label}));
                %                 T(2) = find(strcmp(SEEGFig.UserData.ChannelInfo.Current(ValidChanInds(t)).Label{2},{ImportData.Label}));
                T(1) = find(strcmp(DataStruct.Uni(SEEGFig.UserData.ChannelInfo.Current(ValidChanInds(t)).UnipolarContacts(1)).Label,{ImportData.Label}));
                T(2) = find(strcmp(DataStruct.Uni(SEEGFig.UserData.ChannelInfo.Current(ValidChanInds(t)).UnipolarContacts(2)).Label,{ImportData.Label}));
                TempBipo(t).Data = ImportData(T(1)).Data - ImportData(T(2)).Data;
                TempBipo(t).Label = SEEGFig.UserData.ChannelInfo.Current(ValidChanInds(t)).Label;
            end
            %Filter the data if requested
            if DataFilterButton.Value == 1
                [~, TempBipo] = CCEPFilterFunction(DataStruct,TempBipo,'Bi');
            end
            
            %Then allocate the filtered data to the correct structure
            for t = 1:length(ValidChanInds)
                SEEGFig.UserData.ChannelInfo.Current(ValidChanInds(t)).Data = TempBipo(t).Data;
            end
        end
        clearvars ImportData TempBipo;
        
    case 'Uni'
        %Find which elements have data available
        DataInds = find(arrayfun(@(x) ~isempty(x.Data), SEEGFig.UserData.ChannelInfo.Current));
        EmptyDataInds = find(arrayfun(@(x) isempty(x.Data), SEEGFig.UserData.ChannelInfo.Current));
        
        %Find the channels to erase
        EraseChannels = setdiff(DataInds,ChannelList.Value);
        
        %Erase the data to free up memory
        for r = 1:length(EraseChannels)
            SEEGFig.UserData.ChannelInfo.Current(EraseChannels(r)).Data = [];
        end
        
        ImportInds = setdiff(ChannelList.Value,DataInds);
        BlankChannels = find(arrayfun(@(x) isempty(x.Label), SEEGFig.UserData.ChannelInfo.Current));
        ValidChanInds = setdiff(ImportInds,BlankChannels);
        %         ValidLabels = {SEEGFig.UserData.ChannelInfo.Current(ValidChanInds).OriginalLabel};
        ValidLabels = {SEEGFig.UserData.ChannelInfo.Current(ValidChanInds).Label};
        
        %Import the data using EDF load
        if ~isempty(ValidChanInds)
            %             ImportData = EDFLoading('File',SEEGFig.UserData.DataFile,'Labels',ValidLabels,'Freq',SamplingFreq);
            [~,~,~,ImportData] = CCEPSEEGDataImport('Name', SEEGFig.UserData.PatientName,'Data|EDF',SEEGFig.UserData.DataFile, 'Labels',ValidLabels,'struct',DataStruct);
            if DataFilterButton.Value == 1
                [~, ImportData] = CCEPFilterFunction(DataStruct,ImportData,'Uni');
            end
            for t = 1:length(ValidChanInds)
                SEEGFig.UserData.ChannelInfo.Current(ValidChanInds(t)).Data = ImportData(t).Data;
                ImportData(t).Data = [];
            end
        end
        clearvars ImportData;
end

%Perform the plotting routine if there are channels selected
if ~isempty(ChannelList.Value)
    %Find the channels to plot
    PlottingInds = find(arrayfun(@(x) ~isempty(x.Data), SEEGFig.UserData.ChannelInfo.Current));
    PlottingLabels = {SEEGFig.UserData.ChannelInfo.Current(PlottingInds).Label};
    ElectrodeList = {SEEGFig.UserData.ChannelInfo.Current(PlottingInds).Electrode};
    
    %Give the offsets
    OffsetIncrement = 20;
    CurrentOffset = 0;
    
    %Clear the axes and plot the data
    axes(DataAxes);
    cla;
    hold on;
    
    %Plot the data for each elected trace
    for f = 1:length(PlottingInds)
        %Find and plot the electrode data
        try
            TempPlotData = (SEEGFig.UserData.ChannelInfo.Current(PlottingInds(f)).Data(TimeStart:TimeFinish)*Gain) - CurrentOffset;
        catch
            error('End of file reached'); %If the user goes out of bounds with the  plotting
        end
        plot(TimeStart:TimeFinish,TempPlotData);
        text(TimeFinish, -CurrentOffset, PlottingLabels{f});
        
        %Get the temporary plotting limits
        if f == 1
            PlotMax = max(TempPlotData);
        end
        if f == length(PlottingInds)
            PlotMin = min(TempPlotData);
        end
        
        %Leave a blank space when the electrode changes and increment the
        %offset
        if f < length(PlottingInds) && ~strcmp(ElectrodeList{f},ElectrodeList{f+1})
            CurrentOffset = CurrentOffset + 2*OffsetIncrement;
        else
            CurrentOffset = CurrentOffset + OffsetIncrement;
        end
    end
    
    axis([TimeStart,TimeFinish, PlotMin, PlotMax]);
    DataAxes.YTick = {};
    
    %Plot 1s lines faintly onto the screen (if desired)
    TimeLinePlotMarks = TimeStart + find(mod(TimeStart:TimeFinish,1000) == 0);
    for w = 1:length(TimeLinePlotMarks)
        line([TimeLinePlotMarks(w),TimeLinePlotMarks(w)],[DataAxes.YLim(1), DataAxes.YLim(2)],'color',[0.9 0.9 0.9], 'linewidth',0.5,'linestyl','-.');
    end
end

%Annotation Plotting
AnnotInds = find([SEEGFig.UserData.Annotations.Times]> TimeStart & [SEEGFig.UserData.Annotations.Times] <TimeFinish);
if ~isempty(AnnotInds)
    for g = 1:length(AnnotInds)
        AnnotMod = mod(AnnotInds(g),4);
        line([SEEGFig.UserData.Annotations(AnnotInds(g)).Time, SEEGFig.UserData.Annotations(AnnotInds(g)).Time], [DataAxes.YLim(1), DataAxes.YLim(2)], 'color','red');
        TextYPos = double(DataAxes.YLim(2)- (diff([DataAxes.YLim(1),DataAxes.YLim(2)]))/(10 + AnnotMod*4) );
        text((SEEGFig.UserData.Annotations(AnnotInds(g)).Time),TextYPos,SEEGFig.UserData.Annotations(AnnotInds(g)).Comment,'FontSize',12);
    end
end

%Plot the pulse times on top of the data
PulseInds = find([SEEGFig.UserData.PulseTimes]> TimeStart & [SEEGFig.UserData.PulseTimes] <TimeFinish);
if ~isempty(PulseInds)
    for g = 1:length(PulseInds)
        line([SEEGFig.UserData.PulseTimes(PulseInds(g)), SEEGFig.UserData.PulseTimes(PulseInds(g))], [DataAxes.YLim(1), DataAxes.YLim(2)], 'color','black');
    end
end

%Acquire and plot the TempPulseInds (those gotten by cursor input) and plot
%them
TempPulseInds = find([SEEGFig.UserData.TempPulseTimes]> TimeStart & [SEEGFig.UserData.TempPulseTimes] <TimeFinish);
if ~isempty(TempPulseInds)
    for g = 1:length(TempPulseInds)
        line([SEEGFig.UserData.TempPulseTimes(TempPulseInds(g)), SEEGFig.UserData.TempPulseTimes(TempPulseInds(g))], [DataAxes.YLim(1), DataAxes.YLim(2)], 'color','black');
    end
end


% %Plot the cursor selection
% CursorInds = find([SEEGFig.UserData.Cursor.Time]> TimeStart & [SEEGFig.UserData.Cursor.Time] <TimeFinish);
% if ~isempty(CursorInds)
%     for g = 1:length(CursorInds)
%         CursorMod = mod(CursorInds(g),4);
%         line([SEEGFig.UserData.Cursor(CursorInds(g)).Time, SEEGFig.UserData.Cursor(CursorInds(g)).Time], [DataAxes.YLim(1), DataAxes.YLim(2)], 'color','blue','linestyle','-.');
%         TextYPos = double(DataAxes.YLim(2)- (diff([DataAxes.YLim(1),DataAxes.YLim(2)]))/(10 + CursorMod*4) );
%         text((SEEGFig.UserData.Cursor(CursorInds(g)).Time),TextYPos,SEEGFig.UserData.Cursor(CursorInds(g)).Comment,'FontSize',12);
%     end
%     clc;
%     TimeString = Sample2TimeString(SEEGFig.UserData.Cursor(1).Time,SEEGFig.UserData.Cursor(2).Time, SEEGFig.UserData.SamplingFreq);
%     disp(TimeString);
% end