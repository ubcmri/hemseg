function highlightClickBox(h_fig,cursor_handletag,row,col)
    pixelwidth = 1;
    pixelheight = 1;
    box_position = [col-pixelwidth/2,row-pixelheight/2,pixelwidth,pixelheight];
    figure(h_fig);
    h_rect = findobj(gca,'Type','rectangle','Tag',cursor_handletag);
   
    if ~isa(h_rect,'matlab.graphics.primitive.Rectangle')
        h_rect=rectangle('Position',box_position,'EdgeColor','g','Tag',cursor_handletag);
    else
        set(h_rect,'Position',box_position);
    end
end