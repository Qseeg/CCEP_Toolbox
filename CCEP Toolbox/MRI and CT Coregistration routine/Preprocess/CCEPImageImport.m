function OutImage = CCEPImageImport(PName, ImType, ImFormat)
%OutImage = ImageImport(PName, ImType, ImFormat)
%
%PName = Patient name as a string
%ImType = 'MR' or 'CT' as a string (this will go in the name)
%ImFormat = 'DICOM' or 'NIFTI' and is used to choose importing options


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


%********Choose depending on user input of Image format
if strcmpi(ImFormat,'DICOM')
    disp('Get the Output DICOM Folder  ');
    OutDicomDir = uigetdir(pwd, sprintf('Get the %s DICOM Directory', ImType));
    OutImageName = sprintf('%s %s',PName, ImType );
    RootPath = pwd;
    OutImage = DicomFunc(OutDicomDir, OutImageName); %Import Dicom
    
    %********The case where an image is already created
elseif strcmpi(ImFormat,'NIFTI')
    [OutImage,RootPath] = uigetfile('*.*', sprintf('Get the %s Image', ImType));
    disp('Get the Input Image  ');
    OutImage = fullfile(RootPath,OutImage);
    [p,n,ext] = fileparts(OutImage); %Get the correct fileparts
    
    %********Convert to Nifti if it is not already one
    if ~strcmp(ext,'.nii')
        ConvertedImage = ConvertIMG2NII(OutImage);
        delete(OutImage);
        delete(strcat(p,n,'.hdr'));
        OutImage = which(ConvertedImage);
        FileName = sprintf('%s\\%s %s.nii',p,PName,ImType); %Make the new name
        if ~strcmp(OutImage,FileName)
        movefile(OutImage,FileName); %Change the name to the correct format
        end
        OutImage = which(FileName); %Get the image just created and make it current
        
    else %If it is already nifti, make the name correct
        FileName = sprintf('%s\\%s %s.nii',p,PName,ImType); %Make the new name
        if ~strcmp(OutImage,FileName)
        movefile(OutImage,FileName); %Change the name to the correct format
        end
        OutImage = which(FileName); %Get the image just created and make it current
    end
        
%         A = dir;
%         FilestoDelete = {};
%         for u = 1:length(A)
%             Token = strtok(A(u).name, '.');
%             if ~isempty(strfind(OutImage,Token)) %Try to find the imagname in the file list
%                 FilestoDelete{end+1} = fullfile(A(u).folder , (A(u).name));
%             end
%         end
%         ConvertedImage = ConvertIMG2NII(OutImage);
%         delete(OutImage);
%         OutImage = which(ConvertedImage);
%         
%         [p,~,e] = fileparts(OutImage);
%         FileName = sprintf('%s %s.nii',PName,ImType);
%         NewName = strcat(p,'\',FileName)
%         
%         for p = 1:length(FilestoDelete)
%             delete(FilestoDelete{p});
%         end
%         [p,n,E] = fileparts(OutImage);
%         NewE = 'nii';
%         OutImage = strcat(p,'\',n, '.', NewE);
    end
%     
%     %********Rename the image if it is not in the correct format
%     TestString = sprintf('%s %s.nii',PName,ImType);
%     if ~strcmpi(OutImage, fullfile(which(TestString))) %If not the valid name, change the name
%         %Post Process the Image Name to a standard format
%         Temp = dir;
%         for i = 1:length(Temp)
%             if (Temp(i).isdir == 1)
%                 TempDates(i) = -inf;
%             else
%                 TempDates(i) = datenum(Temp(i).date);
%             end
%         end
%         [~,Ind] = max(TempDates);
%         StandardFile = which(Temp(Ind).name); %Find the name of the latest file created in the folder
%         NewFileName = TestString;
%         movefile(StandardFile, NewFileName); %Rename the file
%         %delete(OutImage);
%         OutImage = NewFileName; %Rename the outgoing filename
%     end
% end
%     
