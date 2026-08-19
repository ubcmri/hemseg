function expandFig(h_fig,mode)

set(h_fig,'Units','normalized');
figpos = get(h_fig,'outerposition');

switch mode
    case 'vertical'
        figpos(2) = 0;
        figpos(4) = 1;
    case 'horizontal'
        figpos(1) = 0;
        figpos(3) = 1;
    case 'full'
        figpos = [0 0 1 1];
end

set(gcf,'outerposition',figpos);