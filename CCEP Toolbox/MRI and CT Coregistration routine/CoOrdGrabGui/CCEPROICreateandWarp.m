function NewCoOrds = CCEPROICreateandWarp(varargin)
% NewCoOrds = CCEPROICreateandWarp('Image',MRIImageName,'CoOrds',CoOrdsforSphereCentre,'Deformation',DeformationField)
%******ROI creation, warp and find the corresponding MNI coOrd with the
%doefrmation field applied


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

    for i = 1:2:length(varargin) %Go through every 2nd value of the name-value pair argument
        InputStr = varargin{i}; %Pop the inputs into a string to get the information out
        if ~isempty(regexpi(InputStr,'ima'))
            InputImage = which(varargin{i+1});
        elseif ~isempty(regexpi(InputStr,'Co' ))  %Read in the CoOrds value
            CoOrds = varargin{i+1};
        elseif ~isempty(regexpi(InputStr,'def' ))  %Read in the CoOrds value
            DefField = which(varargin{i+1});
        elseif ~isempty(regexpi(InputStr,'labe' ))  %Read in the CoOrds value
            Label = varargin{i+1};
        elseif ~isempty(regexpi(InputStr,'box' ))  %Read in the CoOrds value
            BBox = varargin{i+1};
        end
    end

if ~exist('Label','var')
    ContactLabel = 'TempROI';
else
    ContactLabel = Label;
end

%*****Make the ROI sphere
%*****Batch from the build ROI function in Marsbar
c = CoOrds; 
r = 1.5; %Set the radius in mm of all of the files
d = ContactLabel;
l = ContactLabel;
o = maroi_sphere(struct('centre',c,'radius',r));
o = descrip(o,d);
o = label(o,l);

%******Make the ROI file as an image
ROIImage = (strcat(ContactLabel,'.nii')); %Make the Name of the File
SPMFoundVol = spm_vol(which(InputImage)); %Get the darta information for SPM's volume
Space = mars_space(SPMFoundVol); %Use the MarsSpace function to get the information to bend the deformation
save_as_image(o, ROIImage, Space); %Save the ROI bent into the patientspace image's space in a niftii file

%****Export the ROI sphere
%****Deform the image of the ROI sphere
matlabbatch = {};
matlabbatch{1}.spm.spatial.normalise.write.subj.def = {DefField};
matlabbatch{1}.spm.spatial.normalise.write.subj.resample = {strcat(ROIImage,',1')};

%*******If a bounding box is given, use that if not use the default
if ~exist('BBox','var') 
matlabbatch{1}.spm.spatial.normalise.write.woptions.bb = [-78 -112 -70
                                                           78 76 85];
else
    matlabbatch{1}.spm.spatial.normalise.write.woptions.bb = BBox;
end
matlabbatch{1}.spm.spatial.normalise.write.woptions.vox = [1 1 1];
matlabbatch{1}.spm.spatial.normalise.write.woptions.interp = 1;
spm_jobman('run',matlabbatch);

%*******ROI Finding code
%******Read in the deformed ROI Image
[p,n,e] = fileparts(which(ROIImage));
DeformedROIImage = strcat(p,'\w',n,e);
ROIVol = spm_vol(DeformedROIImage);
[TempData, XYZmm] = spm_read_vols(ROIVol);

%Find and record the locations that are close to the maximum deformation
TempInds = find(TempData>=0.99);

if isempty(TempInds) %Set a lower treshold if nothing is found before this
    TempInds = find(TempData>=0.95);
end
   
if isempty(TempInds) %Set a lower treshold if nothing is found before this
    error('CouldNotFindCoOrds for %01.1f %01.1f %01.1f\n',CoOrds(1),CoOrds(2),CoOrds(3));
else %Get the CoOrdinates
    NewCoOrds(1) = mean(XYZmm(1,TempInds));
    NewCoOrds(2) = mean(XYZmm(2,TempInds));
    NewCoOrds(3) = mean(XYZmm(3,TempInds));
end

% %Delete the ROIs to save space later on
delete(which(ROIImage));
delete(which(DeformedROIImage));
