function CCEPSPMCoOrdGUIInit(varargin)
%Use this script to make a series of push buttons that will make it easier
%to capture the electrode array
%ElectrodeArray = SPMGraphicsFig.UserData


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


GFig = findobj('Tag','Graphics');

PatientName = inputdlg('What is the name of the Patient in the Anatomical Map Spreadsheet?','Patient Name Input',1,{'Patient 1'});
if iscell(PatientName)
    PatientName = PatientName{1};
end

%Create the graphics figure in SPM to get the process started
if isempty(GFig)
    spm pet;
    pause (2);
    ImageFile = ShortFileName(uigetfile('*.nii','Get the CT Image in alignment with the MRI'));
    
    if isempty(ImageFile)
        error('You have selected that the MRI and CT have not yet been preprocessed. Aborting the CoOrd acquisition and starting the preprocessing run');
    end
    GFig = findobj('Tag','Graphics');
    [P,N,E] = fileparts(which(ImageFile));
    addpath(P);
    spm_image('Display',which(ImageFile));
else
    figure(GFig);
end

%Get the patient name and find the XLS map
ElectrodeArray(1).Patient = PatientName;

%*******Read in the Patient Map file
MapSearchName = sprintf('%s Map.xlsx',PatientName);
MapImportFlag = 1;

%Search for the electrode file based on the the patient name
if isempty(which(MapSearchName))
    MapImportFlag = 1;
else
    MapImportFlag = 0;
    [P,N,E] = fileparts(which(MapSearchName));
    addpath(P);
    MapFile = ShortFileName(MapSearchName);
end

%If no electrode file was found using the automatic routine, then ask the user to enter a file
if MapImportFlag == 1
    [MapFile, P] = uigetfile('*.xlsx','Get the anatomical map corresponding to the patient you are using');
    addpath(P);
end

%Read in the electrode inforamtion fropm the anatomical mapping spreadsheet
[ElectrodeLabel] = CCEPAnatomicalMapRead(MapFile); %If this fails, then check if you have correctly saved your anatomical maps spreadsheet

%Allocate the fields of the electrode structure
ElectrodeNames = unique({ElectrodeLabel.Electrode});
ElectrodeNames = strtrim(ElectrodeNames);

if strcmp(ElectrodeNames(1),' ');
    ElectrodeNames = ElectrodeNames(2:end);
end
ElectrodeNames = sort_nat(ElectrodeNames);


%Image Data files for the initial structure
ImageDataFile = ShortFileName(uigetfile('*.mat','Get the Pre-processed Image Structure'));
ImageFile = ShortFileName(uigetfile('*.nii','Get the Original MRI Image'));
DefFieldFile = ShortFileName(uigetfile('y_*.nii','Get the Deformation Field'));

%SPM Figure Information Acquisition
for i = 1:length(GFig.Children)
    Types{i} = GFig.Children(i).Type;
end
FoundInds = strcmp(Types,'uipanel');
InformationPanel = GFig.Children(min(find(FoundInds))); %Find the panel (should be the 1st panel that is in the graphics fig
CrossHairsDataPanel= GFig.Children(max(find(FoundInds))); %Find the 2nd panel (should be the 2nd and final panel)
InformationPanel = InformationPanel.Children(2); %Find the panel (should be the 1st panel that is in the graphics fig
OriginString = InformationPanel.Children(6).String;
OriginVoxel = str2num(OriginString);

%Make a note of the image dimensions
DimString = InformationPanel.Children(15).String;
[TempDim, Remainder] = strtok(DimString , 'x');
ImageDim(1) = abs(str2num(TempDim(1:end-1)));
[TempDim, Remainder] = strtok(Remainder, 'x');
ImageDim(2) = abs(str2num(TempDim(2:end-1)));
ImageDim(3) = abs(str2num(Remainder(2:end)));

%Make a note of the Voxel size
VoxString = InformationPanel.Children(8).String;
[TempVox, Remainder] = strtok(VoxString , 'x');
VoxSize(1) = abs(str2num(TempVox(1:end-1)));
[TempVox, Remainder] = strtok(Remainder, 'x');
VoxSize(2) = abs(str2num(TempVox(2:end-1)));
VoxSize(3) = abs(str2num(Remainder(2:end)));


%Allocate all initial information to the electrodes array
for t = 1:length(ElectrodeNames)
    ElectrodeArray(t).Patient = PatientName;
    ElectrodeArray(t).PatientNum = 1; %***********
    ElectrodeArray(t).ElectrodeName = ElectrodeNames{t};
    
    %Position related fields
    ElectrodeArray(t).NumContacts = 15;
    ElectrodeArray(t).PosMM = [];
    ElectrodeArray(t).PosVox = [];
    ElectrodeArray(t).PosMNI = [];
    ElectrodeArray(t).StartMM = [];
    ElectrodeArray(t).EndMM = [];
    ElectrodeArray(t).StartVox = [];
    ElectrodeArray(t).EndVox = [];
    
    %Image Related Fields
    ElectrodeArray(t).ImageDim = ImageDim;
    ElectrodeArray(t).VoxSize = VoxSize;
    ElectrodeArray(t).ImageFile = ImageFile;
    ElectrodeArray(t).DefField = DefFieldFile;
    ElectrodeArray(t).ImageData = ImageDataFile;
    
end


%Create another figure so that you can grab the information
CoOrdAcquireFig = figure('Name','CoOrdAcquireFig','Tag','CoOrdAcquireFig','units','normalized','position',[0.75 0.025 0.25 0.95]);

%Save the inital data and write it to the figure
[TempPath,~,~] = fileparts(which(ElectrodeArray(1).ImageFile));
ElectrodeFile = sprintf('%s%s%s Electrodes.mat',TempPath, filesep, ElectrodeArray(1).Patient);
save(ElectrodeFile, 'ElectrodeArray','-v6');
% GFig.UserData = ElectrodeArray;
CoOrdAcquireFig.UserData = ElectrodeArray;




%Create the patient name input box to get the name of the patient to save
%the file as
PatientNameText = uicontrol('style','text','string','Patient Name:','units','normalized','position',[0.01 0.90 0.3 0.1],'FontSize',15);
PatientNameInput = uicontrol('style','edit','string',PatientName,'Tag','PatientNameInput','units','normalized','position',[0.3 0.95 0.3 0.05],'FontSize',15);

%Initialise the Menu's on the side of the graphics figure
MenuWidth = 0.3;
MenuHeight = 0.04;
FontSize = 13;
% InitialPos = [0.8 0.95 MenuWidth MenuHeight];
InitialPos = [0.01 0.850 MenuWidth MenuHeight];
for t = 1:length(ElectrodeNames)
    
    %Initialise the pushbutton's for each of the electrode start and end
    %points
    TempYPos = InitialPos(2) - (MenuHeight * (length(ElectrodeNames)*((t-1)/length(ElectrodeNames))));
    TempXPos = InitialPos(1);
    TempTag = sprintf('StartButton%i',t);
    CompileButton = uicontrol('Style', 'pushbutton',...
        'String', sprintf('%s Start',ElectrodeNames{t}),...
        'Units', 'normalized',...
        'Position', [TempXPos TempYPos MenuWidth MenuHeight],...
        'background','white',...
        'UserData',TempTag,...
        'Tag', TempTag,...
        'background','white',...
        'Callback', @CCEPStartCoOrdAcquire,...
        'FontSize',FontSize);
    
    %The end CoOrd acquire button
    TempYPos = InitialPos(2) - (MenuHeight * (length(ElectrodeNames)*((t-1)/length(ElectrodeNames))));
    TempXPos = InitialPos(1) + (MenuWidth * 1);
    TempTag = sprintf('EndButton%i',t);
    CompileButton = uicontrol('Style', 'pushbutton',...
        'String', sprintf('%s End',ElectrodeNames{t}),...
        'Units', 'normalized',...
        'Position', [TempXPos TempYPos MenuWidth MenuHeight],...
        'background','white',...
        'UserData',TempTag,...
        'Tag', TempTag,...
        'background','white',...
        'Callback', @CCEPEndCoOrdAcquire,...
        'FontSize',FontSize);
    
    %Initialise the popup menu's for the number of electrode contacts
    TempYPos = InitialPos(2) - (MenuHeight * (length(ElectrodeNames)*((t-1)/length(ElectrodeNames))));
    TempXPos = InitialPos(1) + (MenuWidth * 2);
    TempTag = sprintf('NumContacts%i',t);
    TempStr = {};
    for u = 1:18
        TempStr{u} = u+2;
    end
    NumContactsSelect = uicontrol('Style', 'popup',...
        'String',TempStr,...
        'Units', 'normalized',...
        'Position', [TempXPos TempYPos MenuWidth MenuHeight],...
        'background','white',...
        'UserData',TempTag,...
        'Tag', TempTag,...
        'Value',13,...
        'background','white',...
        'FontSize',FontSize);
    
end

%Initialise the push button callback for plotting the electrodes as a check
TempYPos = InitialPos(2) - (MenuHeight * (length(ElectrodeNames)*(t/length(ElectrodeNames))));
TempXPos = InitialPos(1) + MenuWidth;
TempTag = 'PlotElectrodeButton';
PlotElectrodeButton = uicontrol('Style', 'pushbutton',...
    'String', 'Plot Electrodes ',...
    'Units', 'normalized',...
    'Position', [TempXPos TempYPos MenuWidth MenuHeight],...
    'background','white',...
    'UserData',TempTag,...
    'Tag', TempTag,...
    'background','white',...
    'Callback', @CCEPPlotElectrodeCall,...
    'FontSize',FontSize);


%Initialise the push button callback for processing the MNI and ROI coOrds
TempYPos = InitialPos(2) - (MenuHeight * (length(ElectrodeNames)*(t/length(ElectrodeNames))));
TempXPos = InitialPos(1);
TempTag = 'ProcessCoOrdsButton';
PlotElectrodeButton = uicontrol('Style', 'pushbutton',...
    'String', 'Process CoOrds',...
    'Units', 'normalized',...
    'Position', [TempXPos TempYPos MenuWidth MenuHeight],...
    'background','white',...
    'UserData',TempTag,...
    'Tag', TempTag,...
    'background','white',...
    'Callback', @CCEPProcessCoOrds,...
    'FontSize',FontSize);




