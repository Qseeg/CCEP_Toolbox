% Matthew Woolfe 20-06-17
% VectorTangentNormXYZ1,XYZ2)
% Hand two XYZ points to the function and the unit vectors for the Normal,
% Tangent and Binormal tangent will be returned
%
% Inputs: XYZ1, XYZ2, These are 3 element matrixes with x,y,z values
% Outputs:  Normal Unit Vector      In the Same direction of the points
%           Tangent Unit Vector     90 Degrees to the Normal
%           Binormal Unit Vector    90 degrees to both Normal and Tangent
%
% use: [Normal, Tangent, Binormal] = VectorTangentNorm(XYZ1,XYZ2)
function [Normal, Tangent, Binormal] = VectorTangentNorm(XYZ1,XYZ2)
    
    %Orientation
    if(size(XYZ1,1) == 3)
        XYZ1 = XYZ1';
    end
    
    if(size(XYZ2,1) == 3)
        XYZ2 = XYZ2';
    end

    %Normal
    Normal = diff([XYZ1;XYZ2]);
    Normal = Normal./sqrt(sum(Normal.^2));          %Length of 1
    
    %Tangent
    Tangent = 1./Normal;
    Tangent(isinf(Tangent)) = 1;
    Tangent = Tangent./sqrt(sum(Tangent.^2));       %Length of 1
    
    %Binormal
    Binormal = cross(Normal,Tangent);
    Binormal(isinf(Binormal)) = 1;
    Binormal = Binormal./sqrt(sum(Binormal.^2));    %Length of 1

end