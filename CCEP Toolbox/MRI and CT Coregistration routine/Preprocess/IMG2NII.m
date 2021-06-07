function lastConvertedImage = IMG2NII(input)
%
% IMG2NII
% ________________________________________________________________________
%
% converts image files in ANALYZE format to NIFTI format
% and stores them in current directory
% requires SPM12
% 
% FORMAT analyze2nifti(image)
%___________________________________________________________
% Copyright (C) 2007, H.-J. Huppertz, Last update 2014/12/30


% check if SPM12 exists on the MATLAB path
if isempty(strfind(lower(path),'spm12')) == 1
    disp(' ')
    disp('This program requires algorithms of SPM12.')
    disp('The SPM12 directory was not found on the MATLAB path.');
    disp('Bailing out...');
    disp(' ')
    return; 
else
    Path_SPM12 = spm('Dir');                                 % path to SPM12
    addpath(genpath(Path_SPM12));
end


% start SPM12
fg = spm_figure('Findwin','Graphics');      
if isempty(fg)              % check if SPM12 window is already open
    spm('PET');             % if not, start SPM5
end    


% start program also in Command Window
disp(' ')
disp('analyze2nifti')
disp('=============')
disp(' ')     


% select image(s) and input parameters
if nargin == 0

    % select image(s)
    disp('Select ANALYZE images...')
    Selection = spm_select(Inf,'.img','Select ANALYZE images...');        % select ANALYZE file(s)    
    
    % check input
    if isempty(Selection)
        disp('Error:')
        disp('No input image or directory!')
        disp('Type "help analyze2nifti.m" for further explanation!')
        disp(' ')
        Message = {'Error:'...
            'No input image or directory!'...
            'Type "help analyze2nifti.m" for further explanation!'};
        spm('alert*',Message,'Warning','',0)
        beep
        return
    end
    
elseif nargin > 0 % command line input by help of vargin
    try
        if ~exist(char(deblank(input)),'file')
            disp('Error: Wrong input!')
            disp('Input image not found!')
            disp('Type "help analyze2nifti.m" for further explanation!')
            disp(' ')
            Message = {'Error: Wrong input!'...
                'Input image not found!'...
                'Type "help analyze2nifti.m" for further explanation!'};
            spm('alert*',Message,'Warning','',0)
            beep
            return
        else
            Selection = char(deblank(input));
        end
    catch
    end
else
    disp('Error: Wrong input!')
    disp(' ')
    Message = {'Error: Wrong input!'...
        'Usage: analyze2nifti(image)'...
        'Type "help analyze2nifti.m" for further explanation!'};
    spm('alert*',Message,'Warning','',0)
    beep
    return
end


% fill V with volume information 
for i = 1:1:length(Selection(:,1))
   V(i) = spm_vol(Selection(i,:));          % get volume information of ANALYZE/NIFTI image
end


% check if V is still empty
if ~exist('V','var')
    disp('Error: Wrong input!')
    disp('Could not get input image!')
    disp('Type "help analyze2nifti.m" for further explanation!')
    disp(' ')
    Message = {'Error: Wrong input!'...
        'Could not get input image!'...
        'Type "help analyze2nifti.m" for further explanation!'};
    spm('alert*',Message,'Warning','',0)
    beep
    return
end


% rotate thru input images
for ImageNr = 1:length(V)        
    
    disp('Image to work on: ')
    disp(V(ImageNr).fname)
    try
        if length(V(ImageNr).private.descrip) > 5
            try
                disp(V(ImageNr).private.descrip)        % display image description if possible
            catch
            end
        end
    catch
    end
    fprintf('Subject %d of %d',ImageNr, length(V))
    disp(' ')

    % get image information and create names
    image = V(ImageNr).fname;
    [pth,nme,~] = fileparts(image);
    convertedImage = fullfile(pth, [nme '.nii']);
     
    % do the job
    spm_imcalc(image,convertedImage,'i1',{[],[],[],[]}); % convert

end

lastConvertedImage = convertedImage;
disp(['Last converted image: ' lastConvertedImage])
disp(' ')


