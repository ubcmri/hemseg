function hf = persistentFig(figname)
% persistentFig - create or focus on a figure window with specified name.
% If a figure window has figname in its 'Name' property, then this figure
% will take the program focus.  If the figure does not exist, it will be
% created.  Allows working with persistent figures that won't be duplicated
% at every run of a function, without relying on hard-coded figure numbers.

hf = findobj('Name',figname);
if isempty(hf)
    hf = figure('Name',figname,'NumberTitle','off');
end
figure(hf);

end