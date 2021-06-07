function ProjectedFinishTime(Time,IterationNumber,TotalIterations)
%ProjectedFinishTime(Time,IterationNumber,TotalIterations)

PercentDone = IterationNumber/TotalIterations*100;
TimeRemaining = Time * (TotalIterations - IterationNumber);
Hours = floor(TimeRemaining/3600);
RemMins = mod(TimeRemaining,3600);
Mins = floor(RemMins/60);
RemSecs = mod(TimeRemaining,60);
Secs = floor(RemSecs);
if IterationNumber > 1
for t = 1:41
    fprintf('\b');
end
end
fprintf('%03.0f%%\n',PercentDone);
if IterationNumber == TotalIterations
fprintf('%02.0f Hours, %02.0f Mins, %02.0f Secs Remaining\n',Hours,Mins,Secs);
else
fprintf('%02.0f Hours, %02.0f Mins, %02.0f Secs Remaining',Hours,Mins,Secs);
end