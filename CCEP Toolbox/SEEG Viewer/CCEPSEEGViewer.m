function CCEPSEEGViewer(varargin)
%CCEPSEEGViewer('Name',PatientName,'File',DataFile, 'Annotations',AnnotFile, 'Channels',ChannelInfo,'Pulse',PulseTimes);
%Can also give this function no input if you want to select the file inside
%the figure.
%Name = PatientName
%DataFile = A Matlab or EDF File
%Annotations = Annotations from the corresponding annot file or the
%stimdata annotations
%ChannelInfo = Returned data from the channel electrodes input file
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


%Parse Inputs to function
for i = 1:2:length(varargin) %Go through every 2nd value of the name-value pair argument
    InputStr = varargin{i}; %Pop the inputs into a string to get the information out
    if ~isempty(regexpi(InputStr,'name')) || ~isempty(regexpi(InputStr,'pat')) %Find the name of name of the patient
        PatientName = varargin{i+1};
    elseif ~isempty(regexpi(InputStr,'dat'))||~isempty(regexpi(InputStr,'file'))  %Find the name of the EDF file (only read in channel info though)
        DataFile = varargin{i+1}; %Find the file
        [P,N,E] = fileparts(DataFile);
        switch E
            case '.mat'
                DataType = 'MAT';
            case '.edf'
                DataType = 'EDF';
        end
        
    elseif ~isempty(regexpi(InputStr,'annot'))  %Find the name of the annotations
        if ischar(varargin{i+1})
            AnnotFile = varargin{i+1};
        elseif isstruct(varargin{i+1})
            Annotations = varargin{i+1}; %FRead in the annotations and comments
        end
        
    elseif ~isempty(regexpi(InputStr,'pulse'))
        PulseTimes = varargin{i+1}; %Load in the pulse times for the file
        
    elseif ~isempty(regexpi(InputStr,'chan'))  %Find the name of the EDF file (only read in channel info though)
        ChannelInfo = varargin{i+1}; %FRead in the annotations and comments
        
    elseif ~isempty(regexpi(InputStr,'ref'))
        Reference = varargin{i+1}; %FRead in the annotations and comments
    elseif ~isempty(regexpi(InputStr,'elec'))
        ElectrodeFile = varargin{i+1}; %Acquire the name of the electrode file if given
        
    end
end

%Give the Selectable Voltages gains and Time spacing options
Voltages = {'1 uV','2 uV','3 uV','5 uV','10 uV','15 uV','25 uV', '50 uV','100 uV', '250 uV','500 uV', '1000 uV'};
VoltageNums = [1 2 3 5 10 15 25 50 100 250 500 1000];
Times = {'1 Second','5 Seconds','10 Seconds','15 Seconds','20 Seconds','30 Seconds','60 Seconds','2 Minutes', '5 Minutes'};
TimeNums = [1 5 10 15 20 30 60 120 300];
%SamplingFrq default to 1000Hz
SamplingFreq = 1000;

%Make sure there are no other versions of the SEEGFig available
SEEGFig = findobj('Tag','SEEGDisplayFig');
if(~isempty(SEEGFig))
    for a = 1:length(SEEGFig)
        close(SEEGFig(a).Number);
    end
end

%If no file is selected, give the option to import one
if ~exist('DataFile','var')
    [DataFile, DataPath] = uigetfile('*.*','Get the DataFile to view the .EDF data for');
    
    %Check if the cancel button was pressed, if so, abort the load
    if DataFile == 0
        error('No Data File Selected, aborting SEEGFig creation');
    else
        addpath(DataPath); %Add the path of the DataFile
    end
    
end

%Create the Figure for Display (if a file was selected)
if exist('PatientName','var')
    SEEGFig = figure('Name',sprintf('%s %s',PatientName,DataFile),'Tag','SEEGFig', 'units','normalized','Position',[0 0 1 1],'MenuBar','none','NumberTitle','off','ToolBar','none');
else
    SEEGFig = figure('Name','SEEGDisplayFig','Tag','SEEGFig', 'units','normalized','Position',[0 0 1 1],'MenuBar','none','NumberTitle','off','ToolBar','none');
end

%Import the datastruct to get all of the channelinfo and electrode details
if exist('DataFile','var') && ~exist('ChannelInfo','var')
    if ~exist('ElectrodeFile','var')
        [DataStruct] = CCEPDataStructCreate('name', PatientName, 'data',DataFile);
    else
        [DataStruct] = CCEPDataStructCreate('name', PatientName, 'data',DataFile,'Electrode',ElectrodeFile);
    end
    ChannelInfo = DataStruct;
    ElectrodeFile = ChannelInfo.Info.ElectrodeFile;
else
    [DataStruct] = CCEPDataStructCreate('name', PatientName, 'data',DataFile);
    ElectrodeFile = ChannelInfo.Info.ElectrodeFile;
end
SamplingFreq = DataStruct.Info.SamplingFreq;
SEEGFig.UserData.DataStruct = DataStruct;


%Import the annotations and stimpulse data
if ~exist('AnnotFile','var')
    
    %Look to see if there is a file created with the AnnotEditor
    [P,N,E] = fileparts(which(DataFile));
    TempName = which(sprintf('%s Annotations.mat',N));
    
    %If there is an altered annotations file, load that in
    AllPulses = [];
    if ~isempty(TempName)
        AnnotFile = TempName;
        load(AnnotFile); %Will load Annotations and PulseTimes
    else
        AnnotFile = '';
    end
    
    %Import the stim channel, or the 1st unipolar channel if no stim label
    %is found
    try
        if ~exist('Annotations','var')
            [ChannelInfo, Files, StimAnnot, ImportData, Annotations] = CCEPSEEGDataImport('Patient',PatientName,'DataFile',DataFile,'Electrodes',ChannelInfo.Info.ElectrodeFile,'Struct',DataStruct,'Label',ChannelInfo.Stim(1).Label);
        else
            [ChannelInfo, Files, StimAnnot, ImportData] = CCEPSEEGDataImport('Patient',PatientName,'DataFile',DataFile,'Electrodes',ChannelInfo.Info.ElectrodeFile,'Struct',DataStruct,'Label',ChannelInfo.Stim(1).Label);
        end
        AllPulses = StimPulseFinder(ImportData.Data);
    catch
        fprintf('No Stim Data detected for %s, importing a random channel\n',DataFile);
        if ~exist('Annotations','var')
            [ChannelInfo, Files, StimAnnot, ImportData, Annotations] = CCEPSEEGDataImport('Patient',PatientName,'DataFile',DataFile,'Electrodes',ChannelInfo.Info.ElectrodeFile,'Struct',DataStruct,'Label',ChannelInfo.Uni(1).Label);
        else
            [ChannelInfo, Files, StimAnnot, ImportData] = CCEPSEEGDataImport('Patient',PatientName,'DataFile',DataFile,'Electrodes',ChannelInfo.Info.ElectrodeFile,'Struct',DataStruct,'Label',ChannelInfo.Uni(1).Label);
        end
        AllPulses = [];
    end
    %Patch the 'Times' field (just leave 'Times' in it though)
    if isfield(Annotations,'Times')
        for a = 1:length(Annotations)
            Annotations(a).Time = Annotations(a).Times;
        end
    end
    SEEGFig.UserData.Annotations = Annotations;
    SEEGFig.UserData.AnnotFile = [];
    SEEGFig.UserData.StimAnnot = StimAnnot;
    DataLength = length(ImportData(1).Data);
    if exist('PulseTimes','var')
        if ~isempty(PulseTimes)
            AllPulses = PulseTimes;
        end
    end
    
    %If an AnnotFile is give, use the Import function to get the
    %annotations
else
    AllPulses = [];
    [P,N,E] = fileparts(which(AnnotFile));
    if strcmp(E,'.txt')
        Annotations = AnnotationGrabber(AnnotFile,SamplingFreq);
    elseif strcmp(E,'.mat')
        load(AnnotFile);
    end
    %Patch the 'Times' field (just leave 'Times' in it though)
    if isfield(Annotations,'Times')
        for a = 1:length(Annotations)
            Annotations(a).Time = Annotations(a).Times;
        end
    end
    SEEGFig.UserData.Annotations = Annotations;
    SEEGFig.UserData.AnnotFile = AnnotFile;
    
    %Import the stim channel, or the 1st unipolar channel if no stim label
    %is found
    try
        if ~exist('Annotations','var')
            [ChannelInfo, Files, StimAnnot, ImportData, Annotations] = CCEPSEEGDataImport('Patient',PatientName,'DataFile',DataFile,'Electrodes',ChannelInfo.Info.ElectrodeFile,'Struct',DataStruct,'Label',ChannelInfo.Stim(1).Label);
        else
            [ChannelInfo, Files, StimAnnot, ImportData] = CCEPSEEGDataImport('Patient',PatientName,'DataFile',DataFile,'Electrodes',ChannelInfo.Info.ElectrodeFile,'Struct',DataStruct,'Label',ChannelInfo.Stim(1).Label);
        end
        AllPulses = StimPulseFinder(ImportData.Data);
    catch
        fprintf('No Stim Data detected for %s, importing a random channel\n',DataFile);
        if ~exist('Annotations','var')
            [ChannelInfo, Files, StimAnnot, ImportData, Annotations] = CCEPSEEGDataImport('Patient',PatientName,'DataFile',DataFile,'Electrodes',ChannelInfo.Info.ElectrodeFile,'Struct',DataStruct,'Label',ChannelInfo.Uni(1).Label);
        else
            [ChannelInfo, Files, StimAnnot, ImportData] = CCEPSEEGDataImport('Patient',PatientName,'DataFile',DataFile,'Electrodes',ChannelInfo.Info.ElectrodeFile,'Struct',DataStruct,'Label',ChannelInfo.Uni(1).Label);
        end
        AllPulses = [];
    end
    SEEGFig.UserData.StimAnnot = StimAnnot;
    DataLength = length(ImportData(1).Data);
    if exist('PulseTimes','var')
        if ~isempty(PulseTimes)
            AllPulses = PulseTimes;
        end
    end
end
DataStruct.Info.DataLength = DataLength;
figure(SEEGFig.Number);


%TimeSpan
TimeSpanPopUpText = uicontrol('Style','text','units','normalized','Position',[0.01 0.96 0.05 0.04],'String','Time span','FontSize',14);
TimeSpanPopUp = uicontrol('Style','popupmenu','units','normalized','Position',[0.06 0.95 0.08 0.05],'Value',3,'String',Times, 'UserData', TimeNums, 'Tag','TimeSpanPopUp','CallBack',@CCEPSEEGRedisplay,'FontSize',12);
TimeBase = TimeNums(3)*SamplingFreq;

%Slider for the time window
TimeSldr = uicontrol('Style','slider','units','normalized','Position',[0.02 0.01 0.98 0.03],'min',1,'max',(DataLength-TimeBase),'Value',1,'SliderStep',[0.01 0.1],...
    'Tag','SEEGSlider','Interruptible','off','CallBack',@CCEPSEEGRedisplay);

%Amplitude popup
AmplitudePopUpText = uicontrol('Style','text','units','normalized','Position',[0.14 0.96 0.08 0.04],'String','Voltage gain','FontSize',14);
AmplitudePopUp = uicontrol('Style','popupmenu','String',Voltages,'units','normalized','Position', [0.21 0.95 0.05 0.05],'Value',8,'Tag','AmplitudePopUp','UserData', VoltageNums, 'CallBack',@CCEPSEEGRedisplay,'FontSize',12);


%RefSelect
if ~exist('Reference','var')
    Reference = 'Bi'; %Default to bipolar referencing because it's an SEEG viewer
end
RefPopUpText = uicontrol('Style','text','units','normalized','Position',[0.27 0.96 0.06 0.04],'String','Referencing','FontSize',14);
if exist('Reference','var')
    switch Reference
        case 'Bi'
            RefSelectPopUp = uicontrol('Style','popupmenu','units','normalized','Position',[0.33 0.95 0.05 0.05],'Value',2,'String',{'Uni','Bi'},'Value',2,'Tag','RefSelectPopUp','CallBack',@CCEPSEEGRedisplay,'FontSize',12);
        case 'Uni'
            RefSelectPopUp = uicontrol('Style','popupmenu','units','normalized','Position',[0.33 0.95 0.05 0.05],'Value',1,'String',{'Uni','Bi'},'Value',1,'Tag','RefSelectPopUp','CallBack',@CCEPSEEGRedisplay,'FontSize',12);
    end
else
    RefSelectPopUp = uicontrol('Style','popupmenu','units','normalized','Position',[0.33 0.95 0.05 0.05], 'Value', 2 ,'String',{'Uni','Bi'}, 'Tag','RefSelectPopUp','CallBack',@CCEPSEEGRedisplay,'FontSize',12);
end

%Toggle for the filtering of the data
DataFilteringButton = uicontrol('Style','togglebutton','String','No filtering applied','units','normalized','Position', [0.39 0.97 0.08 0.03],'Value',0,'Tag','DataFilterButton', 'CallBack',@CCEPSEEGRedisplay,'FontSize',12);
SEEGFig.UserData.FilterFlag = 0;

%Annotation Selector
AnnotationPopUpText = uicontrol('Style','text','units','normalized','Position',[0.47 0.96 0.08 0.04],'String','Annotations List','FontSize',14);
if ~exist('Annotations','var')
    AnnotationPopUp = uicontrol('Style','popupmenu','String','Load an Annotations File','units','normalized','Position',[0.55 0.95 0.08 0.05],'Value',1,'UserData',1,'Tag','AnnotationPopUp','CallBack',@CCEPSEEGRedisplay,'FontSize',12);
else
    AnnotationPopUp = uicontrol('Style','popupmenu','String',{Annotations.Comment},'units','normalized','Position',[0.55 0.95 0.08 0.05],'Value',1,'UserData',1,'Tag','AnnotationPopUp','CallBack',@CCEPSEEGRedisplay,'FontSize',12);
end

%Display Figure
PlotAxes = axes('units','normalized','Position',[0.1 0.08 0.85 0.88],'Tag','SEEGDataAxes');

%Create a List of the Channels for Display
if ~exist('ChannelInfo','var')
    ChannelList = uicontrol('Style','list','units','normalized','Interruptible','off','Position',[0.01 0.05 0.08 0.9],'Max',2,'Tag','ChannelList','String','Load EDF File','Value',[],'CallBack',@CCEPSEEGRedisplay,'FontSize',12);
else
    %Put spaces in between the different electrode contacts
    Counter = 1;
    for f = 1:length(ChannelInfo.Uni)-1
        NewChannelInfo.Uni(Counter) = ChannelInfo.Uni(f);
        if ~strcmp(ChannelInfo.Uni(f).Electrode,ChannelInfo.Uni(f+1).Electrode)
            Counter = Counter + 1;
        end
        Counter = Counter + 1;
    end
    
    %Put spaces in between the different electrode contacts
    Counter = 1;
    for f = 1:length(ChannelInfo.Bi)-1
        NewChannelInfo.Bi(Counter) = ChannelInfo.Bi(f);
        if ~strcmp(ChannelInfo.Bi(f).Electrode,ChannelInfo.Bi(f+1).Electrode)
            Counter = Counter + 1;
        end
        Counter = Counter + 1;
    end
    clearvars ChannelInfo;
    ChannelInfo = NewChannelInfo;
    ChannelInfo.Uni(end).Data = [];
    ChannelInfo.Bi(end).Data = [];
    
    %Choose the referenced data to put on the chanel list
    if exist('Reference','var')
        switch Reference
            case 'Uni'
                ChannelList = uicontrol('Style','list','units','normalized','Interruptible','off','Position',[0.01 0.05 0.08 0.9],'Max',2,'Tag','ChannelList','String',{ChannelInfo.Uni.Label},'Value',[],'CallBack',@CCEPSEEGRedisplay,'FontSize',12);
            case 'Bi'
                ChannelList = uicontrol('Style','list','units','normalized','Interruptible','off','Position',[0.01 0.05 0.08 0.9],'Max',2,'Tag','ChannelList','String',{ChannelInfo.Bi.Label},'Value',[],'CallBack',@CCEPSEEGRedisplay,'FontSize',12);
        end
    else
        %Deault to using Unipolar Data
        ChannelList = uicontrol('Style','list','units','normalized','Interruptible','off','Position',[0.01 0.05 0.08 0.9],'Max',2,'Tag','ChannelList','String',{ChannelInfo.Uni.Label},'Value',[],'CallBack',@CCEPSEEGRedisplay,'FontSize',12);
    end
end
% %TimeFrequency Menu Button
% TimeFreqList = uicontrol('Style','popupmenu','units','normalized','Interruptible','off','Position',[0.25 0.975 0.05 0.025],'Tag','TimeFreqPopupMenu','String','Time Freq Channels','Value',1,'CallBack',@SEEGDisplayTimeFreq);

%Make pushbuttons for acquiring pulse times and opening the editor
PulseCursor = uicontrol('Style','pushbutton','String','Mark pulse time','units','normalized','Position', [0.635 0.97 0.07 0.03],'Value',0,'Tag','PulseCursor', 'CallBack',@CCEPSEEGRedisplay,'FontSize',12);
SEEGFig.UserData.TempPulseTimes = [];
RemoveLastPulse = uicontrol('Style','pushbutton','String','Remove Last Pulse','units','normalized','Position', [0.71 0.97 0.08 0.03],'Value',0,'Tag','RemoveLastPulse', 'CallBack',@CCEPSEEGRedisplay,'FontSize',12);
TimeCursor = uicontrol('Style','pushbutton','String','Check the file time','units','normalized','Position', [0.8 0.97 0.1 0.03],'Value',0,'Tag','TimeCursor', 'CallBack',@CCEPSEEGRedisplay,'FontSize',12);
AnnotEditor = uicontrol('Style','pushbutton','String','Annotation editor','units','normalized','Position', [0.91 0.97 0.08 0.03],'Value',0,'Tag','AnnotationEdit', 'CallBack',@CCEPAnnotationEditor,'FontSize',12);


%Append existing Data to it (if possible)
if exist('DataFile','var')
    SEEGFig.UserData.DataFile = DataFile;
    SEEGFig.UserData.DataLength = DataLength;
end
if exist('DataType','var')
    SEEGFig.UserData.DataType = DataType;
end
if exist('ChannelInfo','var')
    %Add some data to if my line works
    SEEGFig.UserData.ChannelInfo = ChannelInfo;
    if strcmp(Reference,'Uni')
        SEEGFig.UserData.ChannelInfo.Current = ChannelInfo.Uni;
    else
        SEEGFig.UserData.ChannelInfo.Current = ChannelInfo.Bi;
    end
    SEEGFig.UserData.ChannelInfo.Info = DataStruct.Info;
end

%Get the patient names and pulse times if they are available
if exist('PatientName','var')
    SEEGFig.UserData.PatientName = PatientName;
end
%PulseTimes - given ERP
if exist('PulseTimes','var')
    AllPulses = PulseTimes;
end
if exist('AllPulses','var')
    SEEGFig.UserData.PulseTimes = AllPulses;
else
    SEEGFig.UserData.PulseTimes = [];
end

%Get the sampling freq if given
if exist('SamplingFreq','var')
    SEEGFig.UserData.SamplingFreq = SamplingFreq;
else
    SEEGFig.UserData.SamplingFreq = 1000;
end


%Pull in the electrodes file if it is not given
if exist('ElectrodeFile','var')
    SEEGFig.UserData.ElectrodeFile = ElectrodeFile;
elseif ~exist('ElectrodeFile','var') && exist('DataFile','var')
    [~,PatInd] = find(strcmp(SEEGFig.UserData.PatientName,{Files.Patient}));
    ElectrodeFile = Files(PatInd).Elec(1).Full;
    SEEGFig.UserData.ElectrodeFile = ElectrodeFile;
end