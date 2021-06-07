
CCEPStimSafetyFig = findobj('Tag','CCEPStimSafetyFig');
figure(CCEPStimSafetyFig.Number);

%Define the areas
A1 = 0.0503; %SEEG area
R = 3.97; %Diameter in mm's
A2 = (((R/10)/2)^2)*pi; %Matsumoto area
R = 2.3; %Diameter in mm's
A3 = (((R/10)/2)^2)*pi; %Valentin area
A3 = 0.0426;

% Q = I.*t;
% 
% D = Q./A;

MaxD = 57e-6;

T = 0.01:0.01:3; %Pulse Width in us
T = T./1000; %Get it in ms

L1 = (MaxD*A1)./T; %Stim current in mA
L1 = L1.*1000; %Scale up to mA
X = T.*1000; %Change back to ms

L2 = (MaxD*A2)./T; %Stim current in mA
L2 = L2.*1000; %Scale up to mA

L3 = (MaxD*A3)./T; %Stim current in mA
L3 = L3.*1000; %Scale up to mA

plot(X, L1,'r'); 
hold on;
plot(X, L2,'-.k'); 
plot(X, L3,'--b'); 

% title('Pulse Levels of safe stimulation according to Gordon et al (1990)','FontSize',19);
title('Recommended stimulation settings (Gordon et al. (1990))','FontSize',17);
legend({'Maximum Charge Density for DIXI SEEG electrodes', 'Maximum Charge Density for 3.97mm Diameter Disc Electrodes','Maximum Charge Density for 2.3mm Diameter Disc Electrodes'},'FontSize',14);
xlabel('Pulse Width (ms)','FontSize',14);
ylabel('Stimulation Level (mA)','FontSize',14);


%Make the lines for 0.1ms 0.3ms, 1ms
A = zeros(2,1);
A(1) = find(round(X,5) == 0.3);
A(2) = find(round(X,5) == 1);
grid on;
grid minor;
CDepth = 0.4; %Depth of gray
% for h = 1:2
% line([X(A(h)) X(A(h))], [0 L1(A(h))], 'Color',[CDepth, CDepth,CDepth],'LineStyle','-.','LineWidth',1); %Vertical Line
% line([min(X) X(A(h))], [L1(A(h)) L1(A(h))], 'Color',[CDepth, CDepth,CDepth],'LineStyle','-.','LineWidth',1); %Horizontal Line 
% end
axis([min(X), max(X), 0, 15]);
Ax = gca;
Ax.FontSize = 32;
Ax.Title.FontSize = 35;
F = gcf;
Temp = findall(gcf, 'Type','Axes');
Temp.Units ='normalized';
Temp.Position = [0.0740 0.1405 0.6807 0.7627];

