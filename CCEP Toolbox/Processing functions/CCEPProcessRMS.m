function  CCEPProcessRMS(varargin)
%CCEPProcessRMS - Select and process one or many edf files and convert them
%into results files


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


RefChoice = 'All'; %Patched this, since it takes only a short while to do the processing, may as well do both refs

%Convert the multiple files option into a binary
MultipleFileFlag = questdlg('Do you want to add multiple files?','Add multiple Files?','Yes','No','Yes');
switch MultipleFileFlag
    case 'Yes'
        MultipleFileFlag = 1;
    case 'No'
        MultipleFileFlag = 0;
end

%Set the file count and break flag
FileCounter = 1;
AddFileFlag = 1;

%Generate blank list items to write into
PatientName = {};
DataFile = {};
ElectrodeFile = {};
AnnotFile = {};


%Perform Looping for adding additional files
while AddFileFlag == 1
    if FileCounter == 1
        
        %Input the patient name
        TempPatientName = inputdlg('What is the name of the Patient in the Anatomical Map Spreadsheet?','Patient Name Input',1,{'Patient 1'});
        if iscell(TempPatientName)
            TempPatientName = TempPatientName{1};
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%EDF File
        [TempDataFile, TempFilePath] = uigetfile('*.edf','Get the EDF file for the CCEP stimulation results');
        addpath(TempFilePath);
        
        %%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%Altered annotations file import
        %Ask the user if there are altered annotations for this file
        %         AnnotFileQuestion = questdlg('Do you want to import an altered annotations file for this .edf?','Altered Annotations File','Yes','No','Yes');
        %         switch AnnotFileQuestion
        %             case 'Yes'
        %                 AnnotFileFlag = 1;
        %             case 'No'
        %                 AnnotFileFlag = 0;
        %                 TempAnnotFile = '';
        %         end
        %****Patched this by automatically finding an Annot .mat file
        AnnotFileFlag = 0;
        TempAnnotFile = '';
        
        %If the user requests an altered annotations file, look for it
        %based on the name of the .edf data file, and if it can't be found,
        %then use a uigetfile
        if AnnotFileFlag == 1
            [~,TempDataName,~] = fileparts(which(TempDataFile));
            AnnotationsSearchName = sprintf('%s altered annotations.mat',TempDataName);
            
            %Search for an altered annotations file based on the the patient name
            if isempty(which(AnnotationsSearchName))
                AnnotImportFlag = 1;
            else
                AnnotImportFlag = 0;
                [P,N,E] = fileparts(which(AnnotationsSearchName));
                addpath(P);
                TempAnnotFile = ShortFileName(AnnotationsSearchName);
            end
            
            %If no annotations file was found using the automatic routine, then ask the user to enter a file
            if AnnotImportFlag == 1
                [TempAnnotFile, P] = uigetfile('*.mat','Get the annotations file corresponding to the patient you are using');
                addpath(P);
            end
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%Electrode File import
        ElectrodeSearchName = sprintf('%s Electrodes.mat',TempPatientName);
        ElectrodeImportFlag = 1;
        
        %Search for the electrode file based on the the patient name
        if isempty(which(ElectrodeSearchName))
            ElectrodeImportFlag = 1;
        else
            ElectrodeImportFlag = 0;
            [P,N,E] = fileparts(which(ElectrodeSearchName));
            addpath(P);
            TempElectrodeFile = ShortFileName(ElectrodeSearchName);
        end
        
        %If no electrode file was found using the automatic routine, then ask the user to enter a file
        if ElectrodeImportFlag == 1
            [TempElectrodeFile, P] = uigetfile('*.mat','Get the electrode file corresponding to the patient you are using');
            addpath(P);
        end
        
        %Add the files that were found by the user or program
        PatientName{end +1} = TempPatientName;
        DataFile{end +1} = TempDataFile;
        ElectrodeFile{end +1} = TempElectrodeFile;
        AnnotFile{end + 1} = TempAnnotFile;
        
        %Incremement the file acquisition number
        FileCounter = FileCounter +1;
        
        %If one file has been added and no more are required, break the
        %loop and being processing
        if MultipleFileFlag == 0
            AddFileFlag = 0;
        end
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%  Do the operation when subsequent files are being added  %%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    elseif MultipleFileFlag == 1 && FileCounter >= 2
        
        %Input the patient name
        TempPatientName = inputdlg('What is the name of the Patient in the Anatomical Map Spreadsheet?','Patient Name Input',1,{TempPatientName});
        if iscell(TempPatientName)
            TempPatientName = TempPatientName{1};
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%EDF File
        [TempDataFile, TempFilePath] = uigetfile('*.edf','Get the EDF file for the CCEP stimulation results');
        addpath(TempFilePath);
        
        %%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%Altered annotations file import
        %Ask the user if there are altered annotations for this file
        %         AnnotFileQuestion = questdlg('Do you want to import an altered annotations file for this .edf?','Altered Annotations File','Yes','No','Yes');
        %         switch AnnotFileQuestion
        %             case 'Yes'
        %                 AnnotFileFlag = 1;
        %             case 'No'
        %                 AnnotFileFlag = 0;
        %                 TempAnnotFile = '';
        %         end
        %****Patched this by automatically finding an Annot .mat file
        AnnotFileFlag = 0;
        TempAnnotFile = '';
        
        %If the user requests an altered annotations file, look for it
        %based on the name of the .edf data file, and if it can't be found,
        %then use a uigetfile
        if AnnotFileFlag == 1
            [~,TempDataName,~] = fileparts(which(TempDataFile));
            AnnotationsSearchName = sprintf('%s altered annotations.mat',TempDataName);
            
            %Search for an altered annotations file based on the the patient name
            if isempty(which(AnnotationsSearchName))
                AnnotImportFlag = 1;
            else
                AnnotImportFlag = 0;
                [P,N,E] = fileparts(which(AnnotationsSearchName));
                addpath(P);
                TempAnnotFile = ShortFileName(AnnotationsSearchName);
            end
            
            %If no annotations file was found using the automatic routine, then ask the user to enter a file
            if AnnotImportFlag == 1
                [TempAnnotFile, P] = uigetfile('*.mat','Get the annotations file corresponding to the patient you are using');
                addpath(P);
            end
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%Electrode File import
        ElectrodeSearchName = sprintf('%s Electrodes.mat',TempPatientName);
        ElectrodeImportFlag = 1;
        
        %Search for the electrode file based on the the patient name
        if isempty(which(ElectrodeSearchName))
            ElectrodeImportFlag = 1;
        else
            ElectrodeImportFlag = 0;
            [P,N,E] = fileparts(which(ElectrodeSearchName));
            addpath(P);
            TempElectrodeFile = ShortFileName(ElectrodeSearchName);
        end
        
        %If no electrode file was found using the automatic routine, then ask the user to enter a file
        if ElectrodeImportFlag == 1
            [TempElectrodeFile, P] = uigetfile('*.mat','Get the electrode file corresponding to the patient you are using');
            addpath(P);
        end
        
        %Add the files that were found by the user or program
        PatientName{end +1} = TempPatientName;
        DataFile{end +1} = TempDataFile;
        ElectrodeFile{end +1} = TempElectrodeFile;
        AnnotFile{end + 1} = TempAnnotFile;
        
        %Incremement the file acquisition number
        FileCounter = FileCounter +1;
        
        %Ask the user if another file is desired to be added
        AddFileQuestion = questdlg('Do you want to add another file?','Add another?','Yes','No','Yes');
        switch AddFileQuestion
            case 'Yes'
                AddFileFlag = 1;
            case 'No'
                AddFileFlag = 0;
        end
    end
end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %%%   Begin processing the selected input files here    %%%%%%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
for a = 1:length(PatientName)
    
    %For each of the input files, process the data files
    if ~isempty(AnnotFile{a})
        CCEPProcessRMSFile('Name',PatientName{a},'EDF',which(DataFile{a}),'Annnotations',AnnotFile{a},'Elec',ElectrodeFile{a},'Reference',RefChoice);
    else
        CCEPProcessRMSFile('Name',PatientName{a},'EDF',which(DataFile{a}),'Elec',ElectrodeFile{a},'Reference',RefChoice);
    end
end
















