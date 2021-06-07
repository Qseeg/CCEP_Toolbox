function Dist = CoOrdDist(CoOrd1, CoOrd2)
%Get the euclidean distance between 2 XYZ points
Dist = sum((CoOrd1 - CoOrd2).^2)^(1/2);