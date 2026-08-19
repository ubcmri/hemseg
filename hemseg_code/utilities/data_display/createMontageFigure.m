function varargout = createMontageFigure(im,varargin)
% createMontageFigure - display a compact grid of images
%
% Usage:
%   montage_im = createMontageFigure(im);
%   [montage_im,h_im] = createMontageFigure(im);
%   montage_im = createMontageFigure(im,h_fig);
%   montage_im = createMontageFigure(im,h_fig,climits);
%   montage_im = createMontageFigure(im,h_fig,ParamName,ParamVal) 
%
% Required arguments:
%   im:  if this is a regular numeric data matrix, must be at least 2
%   dimensions but will usually be 3.  All dimensions beyond the 3rd will
%   be stacked into the 3rd dimension.  If im is a cell array, the function
%   assumes that the cell dimension is the 3rd dimension.  Each image in
%   the cell dimension will be padded to make the sizes equal.
%
% Optional arguments:
%   h_fig:  handle of figure that is the target for montage creation.  If
%           this is not specified, a new figure is used.
%   climits:  two-element vector for min and max value of display range (if
%             empty, then autoscale between global 0 and 99th percentile
%             will be used).
%
% Parameter-value arguments:
%       'threshold_mode':  controls the meaning of climits
%       'percentile':  percentiles over each entire imageset (default)
%       'abs':  absolute values of display limits
%       'cmap':  name of colormap for display
%       'grid_size': [nrows ncolumns] of images in the montage. If not
%                   specified, will be determined automatically
%       'rotate_angle': degree of in-plane rotation (+ve values are ccw)
%       'overlay_mask': integer mask used for colour overlay
%       'mask_colors': cell array of MATLAB color strings for each index of
%                      the overlay mask
%       'isAutoCrop': automatically crop each slice, based on nonzero 
%                     extents of provided mask
%       'autocrop_pad': padding width of crop around object, if isAutoCrop
%                       and autocrop_size not specified
%       'autocrop_size': fixed cropping width, centered around mask
%                        centroid that was calculated by autocrop
%       'crop_dim': [min_x max_x min_y max_y] of individual slice to
%                   display
%
% Returns:
%   montage_image:  handle of graphic object containing the rendered montage
%   h_im: handle to image object
%   
% Example usage:
%   mag_dataset = get2dseq('/datadrive/bruker-backup/mriuser/nmr/BK02_HumanSCI1.Kz2/7');
%   createMontageFigure(mag_dataset.data,2);
%
% Notes:
%   wrapper for MATLAB montage function

ip = inputParser;
ip.addRequired('im');
ip.addOptional('h_fig',[]);
ip.addOptional('climits',[]);
ip.addParameter('threshold_mode','abs');
ip.addParameter('cmap','gray');
ip.addParameter('grid_size',[]);
ip.addParameter('crop_dim',[]);
ip.addParameter('isAutoCrop',false);
ip.addParameter('autocrop_pad',5);
ip.addParameter('autocrop_size',[]);
ip.addParameter('mask_colors',{'r','g','b'});
ip.addParameter('overlay_mask',[]);
ip.addParameter('rotate_angle',0);
ip.addParameter('isShowMask',true);

ip.parse(im,varargin{:});

climits = ip.Results.climits;
h_fig = ip.Results.h_fig;
threshold_mode = ip.Results.threshold_mode;
cmap = ip.Results.cmap;
grid_size = ip.Results.grid_size;
crop_dim = ip.Results.crop_dim;
isAutoCrop = ip.Results.isAutoCrop;
autocrop_pad = ip.Results.autocrop_pad;
autocrop_size = ip.Results.autocrop_size;
mask_colors = ip.Results.mask_colors;
overlay_mask = ip.Results.overlay_mask;
rotate_angle = ip.Results.rotate_angle;
isShowMask = ip.Results.isShowMask;

if isempty(overlay_mask)
    isMask = false;
    assert(~isAutoCrop,'auto crop only works if overlay_mask was specified');
else
    isMask = true;
end

if isAutoCrop
    if isempty(autocrop_size)
        autoCrop_mode = 'pad';
    else
        autoCrop_mode = 'fixed';
    end
end

if isempty(h_fig)
    h_fig= figure;
else
    figure(h_fig)
end


% use cell arrays if the images are not of equal size.  Pad all individual
% images so that they have equal dimension.
if iscell(im)
    im = cell2matDiffsize(im);
end
dim = size(im);
if length(dim) < 3
    n_slice = 1;
else
    n_slice = dim(3);
end

if rotate_angle ~= 0
    for i_slice=1:n_slice
        im(:,:,i_slice) = imrotate(im(:,:,i_slice),rotate_angle,'nearest','crop');
        if isMask
            overlay_mask(:,:,i_slice) = imrotate(overlay_mask(:,:,i_slice),rotate_angle,'nearest','crop');
        end
    end
end


if isAutoCrop
    % initialize crop borders to opposite sides
    right = 1;
    left = dim(2);
    bottom = 1;
    top = dim(1);
    
    for i_slice=1:n_slice
        binary_mask = logical(overlay_mask(:,:,i_slice));    
        row_projection = sum(binary_mask,2);
        row_detected_index = find(row_projection);
        col_projection = sum(binary_mask,1);
        col_detected_index = find(col_projection);
        
        if ~isempty(row_detected_index)
            if min(col_detected_index) < left
                left = min(col_detected_index);
            end
            if max(col_detected_index) > right
                right = max(col_detected_index);
            end
            if min(row_detected_index) < top
                top = min(row_detected_index);
            end
            if max(row_detected_index) > bottom
                bottom = max(row_detected_index);
            end
        end
    end

    if strcmp(autoCrop_mode,'pad')
        
        left = left-autocrop_pad;
        if left < 1
            left = 1;
        end
        
        right = right+autocrop_pad;
        if right > dim(2)
            right = dim(2);
        end
        
        top = top-autocrop_pad;
        if top < 1
            top = 1;
        end
        
        bottom = bottom + autocrop_pad;
        if bottom > dim(1)
            bottom = dim(1);
        end
    else
        ctr = round([(top+bottom)/2 (left+right)/2]);
        delta_row = round(autocrop_size(1)/2);
        delta_col = round(autocrop_size(2)/2);
        top = ctr(1) - delta_row;
        bottom = ctr(1) + delta_row;
        left = ctr(2) - delta_col;
        right = ctr(2) + delta_col;
        
    end
    
    crop_dim(1) = top;
    crop_dim(2) = bottom;
    crop_dim(3) = left;
    crop_dim(4) = right;
    
else
    if isempty(crop_dim)
        crop_dim = [1 dim(1) 1 dim(2)];
    end
end

% for grayscale images, you have to stick a singleton in the 3rd dimension
% in order to use MATLAB montage.
if isempty(climits)
    im = mat2gray(reshape(im,[dim(1:2) 1 dim(3:end)]));
else
    if strcmp(threshold_mode,'abs')
        im = mat2gray(reshape(im,[dim(1:2) 1 dim(3:end)]),climits);
    elseif strcmp(threshold_mode,'percentile')
        im = mat2gray(reshape(im,[dim(1:2) 1 dim(3:end)]),[prctile(climits(1)) prctile(climits(2))]);
    end
end

if isMask && isShowMask
   str2rgb = @(x)get(line('color',x),'color'); 
   im = repmat(im,[1 1 3 1]); 
   n_region = length(unique(overlay_mask))-1;
   for i_region=1:n_region
       color_vec = str2rgb(mask_colors{i_region})';
       for i_slice = 1:n_slice
           for i = 1:dim(1)
               for j = 1:dim(2)
                   if overlay_mask(i,j,i_slice) == i_region
                       im(i,j,:,i_slice) = color_vec;
                   end
               end
           end
       end
   end
   
   
end

im = im(crop_dim(1):crop_dim(2),crop_dim(3):crop_dim(4),:,:);

cmap_table = colormap(cmap);
if isstr(cmap)
    cmap_table = colormap(cmap);
elseif isnumeric(cmap)
    cmap_table = cmap;
end

n_cmap = size(cmap_table,1);

warning('off','images:initSize:adjustingMag');
if isMask
    %if overlay mask is specified, cmap choice will have no effect
    if isempty(grid_size)
        h_im = montage(im);
    else
        h_im = montage(im,'Size',grid_size);
    end
else
    if isempty(grid_size)
        h_im = montage(im*n_cmap,cmap_table);
    else
        h_im = montage(im*n_cmap,cmap_table,'Size',grid_size);
    end
end

montage_im = getimage(gcf);
varargout{1} = montage_im;
varargout{2} = h_im;