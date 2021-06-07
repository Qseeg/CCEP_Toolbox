function [OutputPoints] = CylinderCreation(Radius,NumPoints)
%[OutputPoints] = CylinderCreation(Radius,NumPoints)
%OutputPoints = [X Y Z] CoOrds of the resultant cylinder


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


%Define a cyinder first
[X,Y,Z] = cylinder(Radius,NumPoints);

%****Convert the  cylinder matrix into a usable format (into an [X Y Z]
%matrix)
    OldPoints1(:,1) = X(1,:);
    OldPoints1(:,2) = Y(1,:);
    OldPoints1(:,3) = -1;
    
    
    OldPoints2(:,1) = X(1,:);
    OldPoints2(:,2) = Y(1,:);
    OldPoints2(:,3) = 0;
    
    OldPoints3(:,1) = X(1,:);
    OldPoints3(:,2) = Y(1,:);
    OldPoints3(:,3) = 1;

    OldPoints = [OldPoints1; OldPoints2; OldPoints3]; %Smash the cylinder points together
    
    %*****Define the rotaiont angles (in radians)
    a = 0;
    b = pi/2;
    c = 0;
    RotationAngles = [a b c];
    
    OutputPoints = RotationalAffine('Input',OldPoints,'Ang',RotationAngles); %Transform the circles as a matrix
    