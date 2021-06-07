function MRICleanUpFunction(FilesToDelete)
%MRICleanUpFunction(CleanUpFiles)
%
%Use this function to execute the delete of intermediary files that were
%made as part of the coregistration steps and the like. It will check that
%files are '.nii', '.img' or '.hdr' and only delete them if this is the
%case. Oherwise they will be left alone
%
%CleanUpFiles = Should be a cell of file names (fullfiles)


for r = 1:length(FilesToDelete)
    %******Check if the files are .nii or .img files
    [p,n,e] = fileparts(FilesToDelete{r});
    if strcmp(e, '.nii') || strcmp(e, '.img')|| strcmp(e, '.hdr')
        delete(FilesToDelete{r}); %Delete the File      
    end
end

