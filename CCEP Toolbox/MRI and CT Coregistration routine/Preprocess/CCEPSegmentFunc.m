function [SegmentedImageNames, NormalisedSegmentedImageNames, DeformationFile,  CleanUpFiles] = CCEPSegmentFunc(varargin)
% [SegmentedImageNames, NormalisedSegmentedImageNames, DeformationFile, CleanUpFiles] = CCEPSegmentFunc('Input', SourceImage,'Clean',FilestoDelete, 'Normalised', NormalisationFlag,'Bias', BiasCorrectionFlag)
%
%   This function takes the image that is going to be used as the warping mask
%   The names of created images are passed back as well as the
%   filenames of the images that can be deleted at the end of the batch script
%
% [OutputImages] = FileNames and paths of created files to pass to the next step
% [CleanUpFiles] = Names of the output files to delete at the end of the script
% [] = (SourceImage,....) InputImage is the image to perform realignment on
% [] = (Bias,....) Choose whether or not to output a bias corrected
% (intensity readjustment) version of the original image
% [] = (Normalisation,....) Choose whether or not to output the
% segmentation layers in different MNI space warping
% [] = (CleanUpFiles,...) CleanUpFiles are any pre-existing images that should be dleted at the end


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

%Set defaults
NF = 0;
BF = 0; %Default to having a bias corrected image
CleanUpFiles = {};

for i = 1:2:length(varargin)
    Input = upper(varargin{i});
    if ~isempty(regexpi(Input,'Sou|Inp'))
        SourceImage = which(varargin{i+1});
    elseif ~isempty(regexpi(Input,'cle'))
        CleanUpFiles = varargin{i+1};
    elseif ~isempty(regexpi(Input,'norm'))
        if (varargin{i+1} ~= 0) %NF = NormalisationFlag
            NF = 1;
        end
    elseif ~isempty(regexpi(Input,'bia'))
        BF = varargin{i+1}; %BF = BiasCorrectionFlag
    end
end


SPMDir = cellstr(which('spm.m','-ALL'));
[SPMDir,~,~] = fileparts(SPMDir{1});
matlabbatch = []; %Blank the input matrix

%Use the SPM batch operation to programmatically output the normalised and
%segmented MRI data
matlabbatch{1}.spm.spatial.preproc.channel.vols = {strcat(which(SourceImage),',1')};%Import the volume
matlabbatch{1}.spm.spatial.preproc.channel.biasreg = 0.001;
matlabbatch{1}.spm.spatial.preproc.channel.biasfwhm = 60;
matlabbatch{1}.spm.spatial.preproc.channel.write = [BF 0];
matlabbatch{1}.spm.spatial.preproc.tissue(1).tpm = {sprintf('%s%stpm%sTPM.nii,1',SPMDir,filesep,filesep)}; %Define the TPM based on the spm path
matlabbatch{1}.spm.spatial.preproc.tissue(1).ngaus = 2;
matlabbatch{1}.spm.spatial.preproc.tissue(1).native = [1 0];
matlabbatch{1}.spm.spatial.preproc.tissue(1).warped = [0 NF];
matlabbatch{1}.spm.spatial.preproc.tissue(2).tpm = {sprintf('%s%stpm%sTPM.nii,2',SPMDir,filesep,filesep)};
matlabbatch{1}.spm.spatial.preproc.tissue(2).ngaus = 2;
matlabbatch{1}.spm.spatial.preproc.tissue(2).native = [1 0];
matlabbatch{1}.spm.spatial.preproc.tissue(2).warped = [0 NF];
matlabbatch{1}.spm.spatial.preproc.tissue(3).tpm = {sprintf('%s%stpm%sTPM.nii,3',SPMDir,filesep,filesep)};
matlabbatch{1}.spm.spatial.preproc.tissue(3).ngaus = 2;
matlabbatch{1}.spm.spatial.preproc.tissue(3).native = [1 0];
matlabbatch{1}.spm.spatial.preproc.tissue(3).warped = [0 NF];
matlabbatch{1}.spm.spatial.preproc.tissue(4).tpm = {sprintf('%s%stpm%sTPM.nii,4',SPMDir,filesep,filesep)};
matlabbatch{1}.spm.spatial.preproc.tissue(4).ngaus = 3;
matlabbatch{1}.spm.spatial.preproc.tissue(4).native = [0 0];
matlabbatch{1}.spm.spatial.preproc.tissue(4).warped = [0 0];
matlabbatch{1}.spm.spatial.preproc.tissue(5).tpm = {sprintf('%s%stpm%sTPM.nii,5',SPMDir,filesep,filesep)};
matlabbatch{1}.spm.spatial.preproc.tissue(5).ngaus = 4;
matlabbatch{1}.spm.spatial.preproc.tissue(5).native = [0 0];
matlabbatch{1}.spm.spatial.preproc.tissue(5).warped = [0 0];
matlabbatch{1}.spm.spatial.preproc.tissue(6).tpm = {sprintf('%s%stpm%sTPM.nii,6',SPMDir,filesep,filesep)};
matlabbatch{1}.spm.spatial.preproc.tissue(6).ngaus = 2;
matlabbatch{1}.spm.spatial.preproc.tissue(6).native = [0 0];
matlabbatch{1}.spm.spatial.preproc.tissue(6).warped = [0 0];
matlabbatch{1}.spm.spatial.preproc.warp.mrf = 1;
matlabbatch{1}.spm.spatial.preproc.warp.cleanup = 1;
matlabbatch{1}.spm.spatial.preproc.warp.reg = [0 0.001 0.5 0.05 0.2];
matlabbatch{1}.spm.spatial.preproc.warp.affreg = 'mni';
matlabbatch{1}.spm.spatial.preproc.warp.fwhm = 0;
matlabbatch{1}.spm.spatial.preproc.warp.samp = 7;
matlabbatch{1}.spm.spatial.preproc.warp.write = [0 1];
spm('defaults', 'PET');
spm_jobman('run',matlabbatch);

%Write the name of the deformation field file if the normalised images are
%requested (clear the
[p,n,e] = fileparts(which(char(SourceImage)));
DeformationFile =  strcat(p,filesep,'y_',n,e);
matlabbatch = [];

if NF == 1
    matlabbatch{1}.spm.spatial.normalise.write.subj.def = {DeformationFile};
    matlabbatch{1}.spm.spatial.normalise.write.subj.resample = {strcat(which(SourceImage),',1')};
    matlabbatch{1}.spm.spatial.normalise.write.woptions.bb = [-78 -112 -70
        78 76 85];
    matlabbatch{1}.spm.spatial.normalise.write.woptions.vox = [1 1 1];
    matlabbatch{1}.spm.spatial.normalise.write.woptions.interp = 4;
    spm_jobman('run',matlabbatch);
end

%For each of the tissue types, get the image names and then add the prefix
%'c' to them to denote that they are segmented. If the normalised data is
%requested, then also give the names of the segmented files there
for k = 1:3
    SegmentedImageNames{k} = strcat(p,filesep,'c',num2str(k),n,e);
    CleanUpFiles{end+1} = SegmentedImageNames{k};
    
    if NF == 1
        NormalisedSegmentedImageNames{k} = strcat(p,filesep,'mwc',num2str(k),n,e);
        CleanUpFiles{end+1} = NormalisedSegmentedImageNames{k};
    else
        NormalisedSegmentedImageNames{k} = [];
    end
end

%Delete the segmentation data if it exists
if ~isempty(which(sprintf('%s_seg8.mat',n)))
    delete(which(sprintf('%s_seg8.mat',n)));
end

