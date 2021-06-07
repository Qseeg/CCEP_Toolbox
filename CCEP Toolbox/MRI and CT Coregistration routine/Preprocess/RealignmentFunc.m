function [OutputImage, CleanUpFiles] = RealignmentFunc(varargin)
% [OutputImages, CleanUpFiles] = RealignmentFunc('Input', InputImage,'Smooth',SmoothKernel'Clean',FilestoDelete)
% 
%   This function takes in an image that has been coregistered and realigns 
%   the images that was coregistered with all other images on in the
%   sequence. The names of created images are passed back as well as the 
%   filenames of the images that can be deleted at the end of the batch script
% 
% [OutputImages] = FileNames and paths of created files to pass to the next step
% [CleanUpFiles] = Names of the output files to delete at the end of the script
% [] = (SourceImage,....) InputImage is the image to perform realignment on
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
    Input = upper(varargin{i});
    if ~isempty(regexpi(Input, 'in'))
        InputImage = varargin{i+1};
    elseif ~isempty(regexpi(Input, 'cle'))
        CleanUpFiles = varargin{i+1};
    elseif ~isempty(regexpi(Input, 'smoo'))
        SmoothKernel = varargin{i+1};
    end
end

if iscell(InputImage)
    InputImage = which(InputImage{1}); %take the data out of a cell
end

if ~exist('CleanUpFiles','var')
CleanUpFiles = {};
end

%Assign a Kernel value to the parameters
if ~exist('SmoothKernel','var')
SmoothKernel = 5;
end

%Realign Section

    matlabbatch = []; %Blank the input params matrix
    matlabbatch{1}.spm.spatial.realign.estwrite.data = {{strcat(which(InputImage),',1')}};
    matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.quality = 0.9;
    matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.sep = 4;
    matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.fwhm = SmoothKernel;
    matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.rtm = 1;
    matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.interp = 4;
    matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.wrap = [0 0 0];
    matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.weight = '';
    matlabbatch{1}.spm.spatial.realign.estwrite.roptions.which = [2 0];
    matlabbatch{1}.spm.spatial.realign.estwrite.roptions.interp = 4;
    matlabbatch{1}.spm.spatial.realign.estwrite.roptions.wrap = [0 0 0];
    matlabbatch{1}.spm.spatial.realign.estwrite.roptions.mask = 1;
    matlabbatch{1}.spm.spatial.realign.estwrite.roptions.prefix = 'Realigned';
    spm_jobman('run', matlabbatch); %Run the realign section

    [p,n,e] = fileparts(char(which(InputImage)));
    OutputImage = strcat(p,filesep,matlabbatch{1}.spm.spatial.realign.estwrite.roptions.prefix,n,e);
    CleanUpFiles{end+1} = OutputImage; %Mark the file for deletion
end
