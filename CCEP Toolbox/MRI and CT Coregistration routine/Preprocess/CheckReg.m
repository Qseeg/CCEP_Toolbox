function CheckReg(InputImages)
%Simply opens a checkreg window for several images
for i = 1:length(InputImages)
    InputImages{i} = strcat(InputImages{i},',1');
end
spm_check_registration(char(InputImages));