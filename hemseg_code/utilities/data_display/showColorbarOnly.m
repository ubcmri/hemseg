function h_fig = showColorbarOnly(h_fig,clim,cmap,varargin)

ip = inputParser;
ip.addRequired('h_fig');
ip.addRequired('clim');
ip.addRequired('cmap');
ip.addParameter('orientation','vertical');
ip.addParameter('fontsize',12);
ip.parse(h_fig,clim,cmap,varargin{:});

h_fig = ip.Results.h_fig;
clim = ip.Results.clim;
cmap = ip.Results.cmap;
orientation = ip.Results.orientation;
fontsize = ip.Results.fontsize;

if isnumeric(h_fig)
    h_fig = figure(h_fig);
end

caxis(clim);
colormap(cmap);
if strcmp(orientation,'horizontal')
    colorbar('Location','SouthOutside','FontSize',fontsize);
else
    colorbar('Location','EastOutside','FontSize',fontsize);
end
set(gca,'visible','off');
set(gcf,'Color','w');
