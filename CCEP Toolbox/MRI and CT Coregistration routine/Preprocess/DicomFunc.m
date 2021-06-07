function OutputFile = DicomFunc(DicomDir, ImageName)
%Convert the Mater hospital PACS dicoms into a niftii file

RootDir = pwd;

NewFolder = DicomDir;
matlabbatch = [];
%In the case that the iogetdir is cancelled, 
if isempty(NewFolder)
   OutputFile = 'No File Selected';
   return;
end
cd(NewFolder);
FolderFiles = dir('I*'); %Look for files beggining with capital I (images)
if isempty(FolderFiles)
input('What file prefix do you want to search for??\n','s');
end

for u = 1:length(FolderFiles)
NewFiles{u,1} = strcat(NewFolder, filesep, FolderFiles(u).name);
end

matlabbatch{1}.spm.util.import.dicom.data = NewFiles;
matlabbatch{1}.spm.util.import.dicom.root = 'flat';
matlabbatch{1}.spm.util.import.dicom.outdir = {RootDir};
matlabbatch{1}.spm.util.import.dicom.protfilter = '.*';
matlabbatch{1}.spm.util.import.dicom.convopts.format = 'nii';
matlabbatch{1}.spm.util.import.dicom.convopts.icedims = 0;
spm_jobman('run', matlabbatch); %Run display section
cd(RootDir);

Temp = dir;
for i = 1:length(Temp)
    if (Temp(i).isdir == 1)
        TempDates(i) = -inf;
    else
        TempDates(i) = datenum(Temp(i).date);
    end
end
[~,Ind] = max(TempDates);
StandardFile = Temp(Ind).name; %Find the name of the latest file created in the folder
OutputFile = strcat(ImageName, '.', matlabbatch{1}.spm.util.import.dicom.convopts.format);
movefile(StandardFile, OutputFile); %Rename the file
delete(StandardFile); %Delete the original
OutputFile = strcat(pwd, filesep, OutputFile);




