function [ImageData] = CCEPMRICTPreprocessing(varargin)
%CT to MR Coreg pipeline

%Validated at 18 Jan 2020

%CT to MR Coreg

%Validated at 18 Jan 2018

%******Load in the Patient Name
PatientName = inputdlg('What is the name of the Patient in the Anatomical Map Spreadsheet?','Patient Name Input',1,{'Patient 51'});
if iscell(PatientName)
    PatientName = PatientName{1};
end

% SurfaceFlag = questdlg('D')
SurfaceFlag = 0;

%Generate a question dialog asking if you want to additionally produce
%normalised forms of the 3 tissue type images
NormalisationFlag = questdlg('Do you want to produce normalised Images of the MRI and the 3 tissue types too??','Produce Normalised Images?','Yes','No','No');
switch NormalisationFlag
    case 'Yes'
        NormalisationFlag = 1;
    case 'No'
        NormalisationFlag = 0;
end

CleanUpFiles = {}; %Add a structure of files to delete


%%%%%%%%%%%%%%%%%%%%%%%
%Start the MRI and CT importing processes
CurrentMRI = sprintf('%s MRI',PatientName);
CurrentCT = sprintf('%s CT',PatientName);

%Get the Origin and reorient the MRI and CT scans 
%Firstly, the MRI
TempMRI = which(uigetfile({'*.nii';'*.img'},'Choose the .nii or .img MRI file'));
CurrentMRI = sprintf('%s.nii',CurrentMRI);
[P,N,E] = fileparts(TempMRI);
if ~strcmp(ShortFileName(TempMRI),CurrentMRI)
    try
        movefile(TempMRI, sprintf('%s%s%s',P,filesep,CurrentMRI));
    end
end
RawMRI = CurrentMRI;

% Button = questdlg(sprintf('Is the MRI you want to use still a dicom in a folder'));
% if strcmpi(Button, 'No')||strcmpi(Button, 'Cancel')
%     TempMRI = which(uigetfile({'*.nii';'*.img'},'Choose the .nii or .img MRI file'));
%     CurrentMRI = sprintf('%s.nii',CurrentMRI);
%     [P,N,E] = fileparts(TempMRI);
%     if ~strcmp(TempMRI, CurrentMRI) || ~strcmp(sprintf('%s.nii',TempMRI), CurrentMRI)
%         try
%         movefile(TempMRI, sprintf('%s%s%s',P,filesep,CurrentMRI));
%         end
%     end
% else
%     DicomDir = uigetdir(pwd, 'Choose the MRI directory with the dicom images');
%     CurrentMRI = DicomFunc(DicomDir,CurrentMRI);
% end


%Then, the CT
TempCT = which(uigetfile({'*.nii';'*.img'},'Choose the .nii or .img CT file'));
CurrentCT = sprintf('%s.nii',CurrentCT);
[P,N,E] = fileparts(TempCT);
if ~strcmp(ShortFileName(TempCT),CurrentCT)
    try
        movefile(TempCT, sprintf('%s%s%s',P,filesep,CurrentCT));
    end
end
RawCT = CurrentCT;

% Button = questdlg(sprintf('Is the CT you want to use still a dicom in a folder'));
% if strcmpi(Button, 'No')||strcmpi(Button, 'Cancel')
%     TempCT = which(uigetfile({'*.nii';'*.img'},'Choose the .nii or .img CT file'));
%     CurrentCT = sprintf('%s.nii',CurrentCT);
%     [P,N,E] = fileparts(TempCT);
%     if ~strcmp(TempCT, CurrentCT) || ~strcmp(sprintf('%s.nii',TempCT), CurrentCT)
%         try
%         movefile(TempCT, sprintf('%s%s%s',P,filesep,CurrentCT));
%         end
%     end
%     RawCT = CurrentCT;
% else
%     DicomDir = uigetdir(pwd, 'Choose the CT directory with the dicom images');
%     CurrentCT = DicomFunc(DicomDir,CurrentCT);
%     RawCT = CurrentCT;
% end


%Initialise SPM
spm_jobman('initcfg');
spm_image('Display', which(CurrentMRI));
[P,N,E] = fileparts(which(CurrentMRI));
uiwait(msgbox(sprintf('Set the origin of the MRI and save by reorienting and then click this button to move onto the CT scan'),'MRI Origin set message box'));

spm_image('Display', which(CurrentCT));
uiwait(msgbox(sprintf('Set the origin of the CT and save by reorienting and then click this button to start the preprocessing (which will take about an hour)'),'MRI Origin set message box'));

%*****Coregister the CT to the MRI
[CurrentCT, CleanUpFiles{end+1}] = CoregFunc('Ref', CurrentMRI, 'Target', CurrentCT,'Clean',CleanUpFiles);

%%%%%%%%%%%%
%Realign the CT
[CurrentCT] = RealignmentFunc('Input', CurrentCT);

%%%%%%%%%%%%
%Delete the temporary files not required for analysis
for a = 1:length(CleanUpFiles)
    if iscell(CleanUpFiles{a})
        CleanUpFiles{a} = char(CleanUpFiles{a});
    end 
    delete(which(CleanUpFiles{a}));
end

%%%%%%%%%%%%%%%%%
%Normalise the MRI and CT and record the TPM files (using VBM toolbox)
% [SegmentedImageNames, WarpedImageNames, DeformationFile, ~] = CCEPCATSegmentFunc('Input', CurrentMRI, 'Normalise', NormalisationFlag, 'surf', SurfaceFlag);
[SegmentedImageNames, WarpedImageNames, DeformationFile, ~] = CCEPSegmentFunc('Input', CurrentMRI, 'Normalise', NormalisationFlag);

% %******Save the Data structure and clean up uneeded files
% MRICleanUpFunction(CleanUpFiles); %Execute the Clean up of only the .nii, .img or .hdr files

ImageData.Name = PatientName; %Save the Data Structure
ImageData.RawMRI = CurrentMRI;
ImageData.RawCT = RawCT;
ImageData.FinalMRI = CurrentMRI;
ImageData.FinalCT = CurrentCT;
ImageData.GM = SegmentedImageNames{1};
ImageData.WM = SegmentedImageNames{2};
ImageData.CSF = SegmentedImageNames{3};

if ~isempty(WarpedImageNames) && NormalisationFlag
   ImageData.WarpedGM = WarpedImageNames{1}; 
   ImageData.WarpedWM = WarpedImageNames{2};
   ImageData.WarpedCSF = WarpedImageNames{3};
else
   ImageData.WarpedGM = {}; %Make the fields for consistency 
   ImageData.WarpedWM = {};
   ImageData.WarpedCSF = {};
end
ImageData.DefField = DeformationFile; %Get the DefField

%%%%%%%%%%%%%%%%%%%%%
%Save the data structure
ImageData.SurfFile = '';
StructFileName = sprintf('%s%s%s Imaging Information.mat',P,filesep, PatientName); 
save(StructFileName,'ImageData','-v6'); %Save the structure

%Re-Init the CCEP GUI
GFig = findobj('Tag','Graphics');
close(GFig);
clc;
fprintf('Completed MRI-CT preprocessing for %s\n',PatientName);
CCEPGUIInit;