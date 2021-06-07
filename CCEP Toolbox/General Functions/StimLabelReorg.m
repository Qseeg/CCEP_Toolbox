function NewLabel = StimLabelReorg(Label)
%NewLabel = StimLabelReorg(Label)
%Stim Label Reorganise
%Dave Prim 8 March 2017
[Tok, Remain] = strtok(Label, '-');
Tok2 = Remain(2:end);
if str2num(Tok(isstrprop(Tok,'digit'))) > str2num(Tok2(isstrprop(Tok2,'digit')))
NewLabel = sprintf('%s-%s',Tok2,Tok);
else
    NewLabel = Label;
end