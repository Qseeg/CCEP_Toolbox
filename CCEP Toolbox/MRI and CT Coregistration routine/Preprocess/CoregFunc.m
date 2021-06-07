function [OutputImages, CleanUpFiles] = CoregFunc(varargin)
% [OutputImages, CleanUpFiles] = CoregFunc('Ref', SourceImage, 'Target', OtherImages,'Clean',FilestoDelete)
%   This function takes in a source image and N other images and
%   coregisters the other images to the source Image. The names of created
%   images are passed back as well as the filenames of the images that can
%   be deleted at the end of the batch script
% 
% [OutputImages] = FileNames and paths of created files to pass to the next step
% [CleanUpFiles] = Names of the output files to delete at the end of the script
% [] = (SourceImage,....) SourceImage is the reference image, usually the MRI
% [] = (OtherImages,....) OtherImages are the images to warp into the same alignment as the source image
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


for i = 1:2:length(varargin)
    input = upper(varargin{i});
    if ~isempty(regexpi(input, 'sourc'))||~isempty(regexpi(input, 'ref'))
        SourceImage = varargin{i+1};
    elseif ~isempty(regexpi(input, 'othe'))||~isempty(regexpi(input, 'rest'))||~isempty(regexpi(input, 'targ'))
        OtherImages = varargin{i+1};
    elseif ~isempty(regexpi(input, 'cost'))
        CostFun = varargin{i+1};
    elseif ~isempty(regexpi(input, 'clea'))
        CleanUpFiles = varargin{i+1};
    end
end

if ~iscell(OtherImages)
    OtherImages = {OtherImages}; %Make it a cell if it is not
end

NumImages = length(OtherImages);
if ~exist('CleanUpFiles','var')
CleanUpFiles = {};
end

% CoregSection
matlabbatch = []; %Re init the matrix
matlabbatch{1}.spm.spatial.coreg.estwrite.ref = {strcat(which(SourceImage),',1')}; %MRI Image
matlabbatch{1}.spm.spatial.coreg.estwrite.source = {strcat(which(OtherImages{1,1}),',1')}; %1st CT or PET image

if NumImages >1
    for k = 2:NumImages
        matlabbatch{1}.spm.spatial.coreg.estwrite.other{k-1,1} = strcat(which(OtherImages{k}),',1'); %Following CT or Pet Images
    end
end
%Change the cost function if given, otherwise use the deafult
if ~exist('CostFun','var')
    matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions.cost_fun = 'nmi';
else
    matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions.cost_fun = CostFun;
end
matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions.sep = [4 2];
matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions.fwhm = [7 7];
matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.interp = 4;
matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.wrap = [0 0 0];
matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.mask = 0;
matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.prefix = 'Coreg';

spm_jobman('run', matlabbatch); %Run the coreg section
if NumImages > 1
    for k = 1:NumImages
        [p,n,e] = fileparts(char(OtherImages{k}));
        OutputImages{k}= strcat(p,filesep,matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.prefix, n,e); %Update what the next file passed will be
        CleanUpFiles{end+1} = char(OutputImages{k}); %Mark the file for deletion
    end
else
    [p,n,e] = fileparts(char(OtherImages));
    OutputImages= strcat(p,filesep,matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.prefix, n,e); %Update what the next file passed will be
    CleanUpFiles{end+1} = char(OutputImages); %Mark the file for deletion
end
    