function imNav(data,varargin)
% imNav - simple GUI to navigate through image data, display profiles and
% output ROI masks.  Individual image sets can be displayed in
% separate windows.  Datasets must be between 2 and 5 dimensions.  First
% three dimensions define the volume, and the 4th dimension is considered
% the "frame" dimension (e.g. time, diffusion weighting, etc.).  The 5th
% dimension is a different group of frames (e.g. magnitude vs. phase).
% Each image set must have the same size.  In addition, a separate image
% set can be specified to provide profile information for each pixel of the
% main datasets (e.g. MWF is the main image, but the pixelwise T2
% distributions are specified for each pixel in the "profile" image set).
%
% An ROI mask defined per slice can be defined using the 'm' keystroke and
% saved in a workspace variable using the 's' keystroke.
%
% This is imNav 2.0, which revises the function to work as a non-modal GUI
% (program execution proceeds after imNav windows are created).  Therefore,
% there is no output variable for imNav, but the user can export the
% user-defined mask using the 's' keystroke (see below).  In addition, the
% function interface is improved to allow for an arbitrary number of image
% sets.
%
% Usage:
%   imNav(data);
%   imNav(data,xval);
%   imNav(data,xval,PARAM,VALUE);
%
% Required arguments:
%   data: either an individual image array or a cell array of image arrays.
%         Each image array can have up to 5 dimensions.  If 3 dimensions
%         are found, the third dimension is assumed to be the slice
%         direction.  4th dimension is the frame dimension.  5th dimension
%         is the frame group dimension.  All images in the cell array must
%         have equal dimensions.  imNav will create a navigable window for
%         each image set, with the current slice/frame/framegroup/cursor
%         being synchronized across all imNav windows.
%
% Optional arguments:
%   xval:  "x-axis" values along the frame dimensions (e.g. echo time,
%          repetition number, inversion time, b-value, etc.)
%
% Parameter-value arguments:
%   name:  specify figure window title.  By default, the figure that
%          contains imNav has no numbered title and is called "imNav" by
%          default.
%
%   threshold_mode:  controls way caxis limits and profile ylim are set
%       'percentile_curr':  percentiles based on currently displayed image
%       'percentile_all':  percentiles over each entire imageset (default)
%
%   prctile_range:  [min max] (default is [0 100])
%
%   clim:  absolute limits for images.  Either a two-element vector (if
%          there is only one image array), or a cell array thereof. (Note:
%          if any clim is set, all other image sets must have the clim
%          defined as well.  Overrides threshold_mode parameter
%
%   aspect_ratio:  [dx dy dz]
%
%   cmap:   name of matlab colormap (default: gray).  Can define colormap
%           for each image set if cell array of colormap names are provided
%
%   isSemilog_profile: if true, semilog scale on x axis of pixel profile
%                      (cell array can be provided if this setting is
%                      different for each image set)
%
%   isProfile_autoscale: flag to turn on autoscaling for profile window
%                        (if off, the profile y-axis takes on the intensity
%                        limits of the current figure)
%
%   input_mask:  integer mask array matching the first 3 dimensions of
%                data (label index can be 1 to 8, with zero meaning
%                unlabeled).  Initializes the mask (usually defined by "m"
%                key)
%
%   output_mask_name:  name of workspace variable to store output mask
%                      (saved using the 's' keystroke)
%
%   label: cell array containing names of image sets (for labeling
%          purposes).  If only one image set was defined and label is not
%          specified, the function will automatically use the variable name
%          as the label name (will only work if a straight variable name
%          was used).
%
%   fig_row_position: Two-element vector that controls the position of the
%   main row of images associated with this imNav instance.  The first
%   element describes the number of rows that divide up the vertical space
%   of the screen, and the second element denotes the ith row to display
%   the images.  All the image figures, frame-level profiles, and
%   alternative profiles set in the profile_data input parameter will be
%   displayed upon creation on the same row by default.  The user can move
%   them around later. By default, this option is turned off, and figures
%   are arranged automatically.
%
%   profile_data:  a cell array of structures which provides data for custom profile data
%                  (see Notes for explanation)
%           profile_data{<x>}.data: 4D array of profile data (first 3
%                            dimensions must be the same as image data).
%                            The 4th dimension contains the custom profile
%                            data, corresponding to one point in the volume
%           profile_data{<x>}.xval: vector of values defining x axis of the
%                            custom profile.  If xval is a vector, these x
%                            values are used for every profile.  xval can
%                            also be a 4D array (size must be same as .data)
%           profile_data{<x>}.figname: the data will be displayed in a
%                  figure with the main imNav name (specified by 'name' in
%                  the imNav call) concatenated to this .figname.  If the
%                  figure does not yet exist, it will be created.  Allows
%                  overlay of other profile data onto the same plot.
%           profile_data{<x>}.plotstyle: plot specifier string to control
%                                        color and marker/line style
%           profile_data{<x>}.label: legend label
%           profile_data{<x>}.isSemilog_profile: flag to turn on semilogx
%           on profile plot
%
% Returns:
%
% Example usage:
%   mag_dataset = get2dseq('/datadrive/bruker-backup/mriuser/nmr/CW4_201164.Kk1/10'); % MGE dataset (magnitude image in procno 1)
%   phase_dataset = get2dseq('/datadrive/bruker-backup/mriuser/nmr/CW4_201164.Kk1/10',2); % MGE dataset (phase in procno 2)
%   imNav({mag_dataset.data,phase_dataset.data},mag_dataset.methodparx.PVM_EchoTime,'label',{'mag','phase'});
%
%   results = loadMatSingleVar(['/datadrive2/processed-data/Kwon/Biobank_SCI/BK02_HSC_BB9_C1_Rl1/exp49_qT2_results.mat'],'results');
%   n_T2 = length(results.T2_times);
% 
%   profile_data{1}.data = results.T2distmap;
%   profile_data{1}.xval = 1000*results.T2_times;
%   profile_data{1}.figname = 'T2 distribution';
%   profile_data{1}.plotstyle = '-';
%   profile_data{1}.label = 'fixed';
%   profile_data{1}.isSemilogProfile = true;
% 
%   residuals = results.rawdata - results.decaypredmap;
%   profile_data{2}.data = residuals;
%   profile_data{2}.xval = 1:size(results.decaypredmap,4);
%   profile_data{2}.figname = 'echo decay';
%   profile_data{2}.plotstyle ='r-';
%   profile_data{2}.label = 'residuals';
%   profile_data{2}.isSemilogProfile = false;
% 
%   profile_data{3}.data = results.rawdata;
%   profile_data{3}.xval = 1:size(results.decaypredmap,4);
%   profile_data{3}.figname = 'echo decay';
%   profile_data{3}.plotstyle ='k.';
%   profile_data{3}.label = 'raw data';
%   profile_data{3}.isSemilogProfile = false;
% 
%   profile_data{4}.data = results.decaypredmap;
%   profile_data{4}.xval = 1:size(results.decaypredmap,4);
%   profile_data{4}.figname = 'echo decay';
%   profile_data{4}.plotstyle ='r-';
%   profile_data{4}.label = 'fitted decay';
%   profile_data{4}.isSemilogProfile = false;
% 
%   imNav({results.MWFmap,results.SNRmap},'profile_data',profile_data,'label',{'MWF','SNR'},'name',['qT2'],'fig_row_position',[3 3]);
% 
%
% Notes:
%   Navigation through data is achieved through keystrokes and mouse clicks
%   according to the following:
%
% KEYBOARD COMMANDS:
%   ,   (previous slice)
%   .   (next slice)
%   k   (previous frame)
%   l   (next frame)
%   i   (previous frame group)
%   o   (next frame group)
%   m   (start segmentation mask definition on current slice, using
%        roipoly. Dialog appears to specify current label index and flag to
%        switch on overwrite of previous mask labels.  Use zero index to
%        erase).
%   r   (calculate mean and stdev. in defined ROI for each frame series)
%   s   (save segmentation mask in a specified workspace variable)
%   t   (draw line across current image and display profile using improfile)
%   v   (visibility toggle for overlay of segmentation mask)
%   z   (display profile in slice direction of current frame)
%   arrows:  move in-plane cursor one pixel at a time
%
% MOUSE COMMANDS:
%   left click     display profile in frame dimension at current location, 
%                  and display custom profile data
%   middle click   drag to adjust window level

%  For further questions, please contact Andrew Yung at ayung@mail.ubc.ca
%  Major revision: Jan 23 2019

%% parse inputs



ip = inputParser;
ip.addRequired('data');
ip.addOptional('xval',1);
ip.addOptional('clim',[]);
ip.addParameter('name','imNav');
ip.addParameter('aspect_ratio',[1 1 1]);
ip.addParameter('threshold_mode','percentile_all');
ip.addParameter('prctile_range',[0.5 99.5]);
ip.addParameter('cmap','gray');
ip.addParameter('isSemilog_profile',false);
ip.addParameter('profile_data',{});
ip.addParameter('isProfile_autoscale',true);
ip.addParameter('label',{});
ip.addParameter('input_mask',[]);
ip.addParameter('output_mask_name','mask');
ip.addParameter('fig_row_position',[3 3 3]);
ip.addParameter('isAutoArrange',true);
ip.addParameter('histo_plot_prefix',[]);
ip.parse(data,varargin{:});

clim = ip.Results.clim;
frame_val = ip.Results.xval;
prctile_min = ip.Results.prctile_range(1);
prctile_max = ip.Results.prctile_range(2);
aspect_ratio = ip.Results.aspect_ratio;
threshold_mode = ip.Results.threshold_mode;
cmap = ip.Results.cmap;
input_mask = ip.Results.input_mask;
isSemilog_profile = ip.Results.isSemilog_profile;
profile_data = ip.Results.profile_data;
isProfile_autoscale = ip.Results.isProfile_autoscale;
name = ip.Results.name;
label = ip.Results.label;
fig_row_position = ip.Results.fig_row_position;
output_mask_name = ip.Results.output_mask_name;
isAutoArrange = ip.Results.isAutoArrange;
histo_plot_prefix = ip.Results.histo_plot_prefix;

format shortG


isProfileData = false;
if ~isempty(profile_data)
    isProfileData = true;
    n_profile = length(profile_data);
    for i_profile = 1:n_profile
        profile_image{i_profile} = profile_data{i_profile}.data;
        profile_xdata{i_profile} = profile_data{i_profile}.xval;
        profile_figname{i_profile} = profile_data{i_profile}.figname;
        profile_plotstyle{i_profile} = profile_data{i_profile}.plotstyle;
        profile_label{i_profile} = profile_data{i_profile}.label;
        profile_isSemilog{i_profile} = profile_data{i_profile}.isSemilogProfile;
        
    end
end

warning('off','MATLAB:legend:IgnoringExtraEntries');

%% input handling and assertions for multiple imagesets
if ~iscell(data)
    temp_data = data;
    clear data;
    data{1} = temp_data;
    
    temp_cmap = cmap;
    clear cmap;
    cmap{1} = temp_cmap;
    
    temp_clim = clim;
    clear clim;
    clim{1} = temp_clim;
    
    temp_isSemilog_profile = isSemilog_profile;
    clear isSemilog_profile;
    isSemilog_profile{1} = temp_isSemilog_profile;
end

n_data = length(data);
if iscell(cmap)
    if length(cmap) ~= n_data
        error('imNav: must define cmap for all datasets');
    end
else
    temp_cmap = cmap;
    clear cmap;
    for i_data = 1:n_data
        cmap{i_data} = temp_cmap;
    end
end

if iscell(clim)
    if length(clim) ~= n_data
        error('imNav: must define clim for all datasets');
    end
else
    temp_clim = clim;
    clear clim;
    for i_data = 1:n_data
        clim{i_data} = temp_clim;
    end
end

if iscell(isSemilog_profile)
    if length(isSemilog_profile) ~= n_data
        error('imNav: must define isSemilogProfile for all datasets');
    end
else
    temp_isSemilog_profile = isSemilog_profile;
    clear isSemilog_profile
    for i_data = 1:n_data
        isSemilog_profile{i_data} = temp_isSemilog_profile;
    end
end

for i_data = 1:n_data
    if islogical(data{i_data})
        data{i_data} = int16(data{i_data});
    end
end


dim = size(data{1});
for i_data = 2:n_data
    assert(isequal(size(data{i_data}),dim),'image data must be same size');
end

if isempty(input_mask)
    if length(dim) == 2
        input_mask = int16(zeros(dim));
    else
        input_mask = int16(zeros(dim(1:3)));
    end
else
    if length(dim) == 2
        assert(isequal(size(input_mask),dim(1:2)),...
            'input_mask size should match first 2 dimensions of data');
    else
        assert(isequal(size(input_mask),dim(1:3)),...
            'input_mask size should match first 3 dimensions of data');
    end
end

if isempty(label)
    if n_data == 1
        if isempty(inputname(1))
            data_name{1} = 'Im#1';
        else
            data_name{1} = inputname(1);
        end
    else
        for i_data = 1:n_data
            data_name{i_data} = ['Im#' num2str(i_data)];
        end
    end
else
    assert(n_data == length(label),'number of labels and images not the same');
    data_name = label;
end

%% redefine image dimensions (if number of dimensions of input data < 5)

if length(dim) == 2
    n_slice = 1;
    n_frame = 1;
    dim = [dim 1 1];
    frame_val = 1;
    n_framegroup = 1;
elseif length(dim) == 3
    n_slice = dim(3);
    n_frame = 1;
    dim = [dim 1];
    frame_val = 1;
    n_framegroup = 1;
elseif length(dim) == 4
    n_slice = dim(3);
    n_frame = dim(4);
    if length(frame_val) ~= n_frame
        frame_val = 1:n_frame;
    end
    n_framegroup = 1;
elseif length(dim) > 4
    n_slice = dim(3);
    n_frame = dim(4);
    if length(frame_val) ~= n_frame
        frame_val = 1:n_frame;
    end
    n_framegroup = dim(5);
end

set(0, 'DefaulttextInterpreter', 'none');

%% set up initial conditions
curr_frame = 1;
curr_framegroup = 1;
curr_slice = round(dim(3)/2);
ypos = round(dim(1)/2);
xpos = round(dim(2)/2);

for i_data = 1:n_data
    grayscale_limits_whole{i_data} = [prctile(data{i_data}(:),prctile_min),prctile(data{i_data}(:),prctile_max)];
    if ~isempty(clim{i_data})
        grayscale_limits_whole{i_data} = clim{i_data};
        threshold_mode = 'abs';
    end
end

isROIshow = false;

%% initialize figure windows (reuse windows if they are already defined)
for i_data=1:n_data
    fig_name{i_data} = [name ' ' data_name{i_data}];
    h_fig{i_data} = findobj('name',fig_name{i_data});
    if isempty(h_fig{i_data})
        h_fig{i_data}=figure('name',fig_name{i_data},'NumberTitle','off','Visible','on');
        if verLessThan('matlab','9.3.0.713579 (R2017b)')
            uimenu(h_fig{i_data},'Label','imNav Help','Callback',@help_fcn);
        else
            uimenu(h_fig{i_data},'Text','imNav Help','MenuSelectedFcn',@help_fcn);
        end
        enableWL(h_fig{i_data});
    end
end

if n_frame == 1
    n_improfile_fig = 0;
else
    n_improfile_fig = n_data;
end
if isProfileData
    altprofile_figname = unique(profile_figname);
    n_altprofile_fig = length(altprofile_figname);
else
    n_altprofile_fig = 0;
end
n_firstrow_fig = n_data + n_improfile_fig + n_altprofile_fig;

%% store the image data and configuration settings into handles stored with the figure
for i_data = 1:n_data
    % set callback functions for keyboard strokes and mouse commands
    set(h_fig{i_data},'KeyPressFcn',@imNavKeyPress,...
        'ButtonDownFcn',@imNavMouseClick);
    
    
    handles = guihandles(h_fig{i_data});
    handles.curr_slice = curr_slice;
    handles.curr_frame = curr_frame;
    handles.curr_framegroup = curr_framegroup;
    handles.n_slice = n_slice;
    handles.n_frame = n_frame;
    handles.n_framegroup = n_framegroup;
    handles.data = data{i_data};
    handles.data_name = data_name{i_data};
    handles.name = name;
    handles.grayscale_limits_whole = grayscale_limits_whole{i_data};
    handles.clim = clim{i_data};
    handles.cmap = cmap{i_data};
    handles.input_mask = input_mask;
    handles.ypos = ypos;
    handles.xpos = xpos;
    handles.isROIshow = isROIshow;
    handles.isSemilog_profile = isSemilog_profile{i_data};
    handles.threshold_mode = threshold_mode;
    handles.prctile_min = prctile_min;
    handles.prctile_max = prctile_max;
    handles.isFirstDisplay = true;
    handles.aspect_ratio = aspect_ratio;
    handles.frame_val = frame_val;
    handles.isProfile_autoscale = isProfile_autoscale;
    handles.isProfileData = isProfileData;
    if isProfileData
        handles.profile_image = profile_image;
        handles.profile_xdata = profile_xdata;
        handles.profile_figname = profile_figname;
        handles.profile_plotstyle = profile_plotstyle;
        handles.profile_label = profile_label;
        handles.profile_isSemilog = profile_isSemilog;
        handles.n_profile = n_profile;
        handles.h_altprofile_fig = cell(1,n_profile);
    end
    handles.all_fig_name = fig_name;
    handles.h_fig = h_fig;
    handles.fig_row_position = fig_row_position;
    handles.h_profile_fig = cell(1,n_data);
    handles.h_zprofile_fig = cell(1,n_data);
    handles.n_data = n_data;
    handles.output_mask_name = output_mask_name;
    handles.n_firstrow_fig = n_firstrow_fig;
    handles.isAutoArrange = isAutoArrange;
    handles.histo_plot_prefix = histo_plot_prefix;
    if isProfileData
        handles.altprofile_figname = altprofile_figname;
        handles.n_altprofile_fig = n_altprofile_fig;
    end
    guidata(h_fig{i_data},handles);
    
end

%% perform first image update
UpdateFig(h_fig);

end


%%

function help_fcn(src,~)
help_msg = ...
    {'KEYBOARD COMMANDS:',...
    ',   (previous slice)',...
    '.   (next slice)',...
    'k   (previous frame)',...
    'l   (next frame)',...
    'i   (previous frame group)',...
    'o   (next frame group)',...
    'm   (start segmentation mask definition on current slice, using',...
         'roipoly. Dialog appears to specify current label index and flag',...
         'to switch on overwrite of previous mask labels.  Use zero index',...
         'to erase).',...
    'r   (calculate mean and stdev. in defined ROI for each frame series)',...
    's   (save segmentation mask in a specified workspace variable)',...
    't   (draw line across current image and display profile using improfile)',...
    'v   (visibility toggle for overlay of segmentation mask)',...
    'z   (display profile in slice direction of current frame)',...
    'arrows:  move in-plane cursor one pixel at a time',...
    ' ',...
    'MOUSE COMMANDS:',...
    'left click     (display profile in frame dimension at current location, and display custom profile data)',...
    'middle click   (drag to adjust window level)'};


helpdlg(help_msg);
end

%%

function enableWL(hfig)
if nargin<1
    hfig=gcf;
end
G=get(hfig,'userdata');
G.oldWBMFcn = get(hfig,'WindowButtonMotionFcn');
set(hfig,'userdata',G);

set(hfig,'WindowButtonDownFcn',@WBDFcn);
set(hfig,'WindowButtonUpFcn',@WBUFcn);
end

%%

function WBDFcn(varargin)
fh=varargin{1};
if strcmp(get(fh,'SelectionType'),'extend')
    set(fh, 'WindowButtonMotionFcn',@AdjWL);
    G=get(fh,'userdata');
    
    G.initpnt=get(gca,'currentpoint');
    G.initClim = get(gca,'Clim');
    set (fh,'userdata',G);
end
end

%%

function WBUFcn(varargin)
fh=varargin{1};
if strcmp(get(gcf,'SelectionType'),'extend')
    G=get(fh,'userdata');
    
    set(fh,'WindowButtonMotionFcn',G.oldWBMFcn);
end
end

function AdjWL(varargin)

fh=varargin{1};
G=get(fh,'userdata');
G.cp=get(gca,'currentpoint');
G.x=G.cp(1,1);
G.y=G.cp(1,2);
G.xinit = G.initpnt(1,1);
G.yinit = G.initpnt(1,2);
G.dx = G.x-G.xinit;
G.dy = G.y-G.yinit;
G.clim = G.initClim+G.initClim(2).*[G.dx G.dy]./128;
try
    switch get(fh,'SelectionType')
        case 'extend' % Mid-button, shft+left button,
            set(gca,'Clim',G.clim);
    end
end

end

%%

function imNavKeyPress(src,event)

handles = guidata(gcbo);
curr_slice = handles.curr_slice;
curr_frame = handles.curr_frame;
curr_framegroup = handles.curr_framegroup;
n_slice = handles.n_slice;
n_frame = handles.n_frame;
n_framegroup = handles.n_framegroup;
data_name = handles.data_name;
name = handles.name;
n_data = handles.n_data;
all_fig_name = handles.all_fig_name;
input_mask = handles.input_mask;
isROIshow = handles.isROIshow;
gcbo_handles = guidata(gcbo);
h_fig = gcbo_handles.h_fig;
n_x = size(handles.data,2);
n_y = size(handles.data,1);
xpos = handles.xpos;
ypos = handles.ypos;


keyboard_value = double(event.Character);
if keyboard_value > 27 || keyboard_value < 32
    switch keyboard_value
        case 28 % left arrow
            if xpos > 2
                xpos = xpos - 1;
            end
        case 29 % right arrow
            if xpos < n_x-1
                xpos = xpos + 1;
            end
        case 30 % up arrow
            if ypos > 2
                ypos = ypos - 1;
            end
        case 31 % down arrow
            if ypos < n_y-1
                ypos = ypos + 1;
            end
    end
end
          

switch event.Character
    case {','}
        if (curr_slice==1)
            disp('reached 1st slice');
        else
            curr_slice=curr_slice-1;
            if ~isempty(handles.histo_plot_prefix)
                figure(100); 
                plot_filepath = [handles.histo_plot_prefix num2str(curr_slice) '.png'];
                if exist(plot_filepath,'file')
                    imshow(plot_filepath,'InitialMagnification',80,'Border','tight');
                else
                    clf
                end
            end
        end
    case {'.'}
        if (curr_slice==n_slice)
            disp('reached end slice');
        else
            curr_slice=curr_slice+1;
            if ~isempty(handles.histo_plot_prefix)
                figure(100); 
                plot_filepath = [handles.histo_plot_prefix num2str(curr_slice) '.png'];
                if exist(plot_filepath,'file')
                    imshow(plot_filepath,'InitialMagnification',80,'Border','tight');
                else
                    clf
                end
            end
        end
    case {'g'}
         answer = inputdlg({'Slice index:'},'Go to slice',1,{'1'});
         target_slice = str2num(answer{1});
         if target_slice < 1 || target_slice > n_slice
             warndlg('slice index out of bounds','warning');
         else
             curr_slice = target_slice;
             if ~isempty(handles.histo_plot_prefix)
                 figure(100);
                 plot_filepath = [handles.histo_plot_prefix num2str(curr_slice) '.png'];
                 if exist(plot_filepath,'file')
                     imshow(plot_filepath,'InitialMagnification',80,'Border','tight');
                 else
                     clf
                 end
             end
         end
    
    case {'k'}
        if (curr_frame==1)
            disp('reached 1st frame');
        else
            curr_frame=curr_frame-1;
        end
    case {'l'}
        if (curr_frame==n_frame)
            disp('reached last frame');
        else
            curr_frame=curr_frame+1;
        end
    case {'i'}
        if (curr_framegroup==1)
            disp('reached 1st framegroup');
        else
            curr_framegroup=curr_framegroup-1;
        end
    case {'o'}
        if (curr_framegroup==n_framegroup)
            disp('reached last framegroup');
        else
            curr_framegroup=curr_framegroup+1;
        end
    case {'r'}
        set(gca,'PickableParts','all');
        roi_mask = roipoly;
        set(gca,'PickableParts','none');
        mask = zeros(n_y,n_x,n_slice);
        mask(:,:,curr_slice) = roi_mask;
        UpdateProfile(h_fig,mask,curr_framegroup);
    case {'v'}
        isROIshow = ~isROIshow;
    case {'t'}
        h_currfig = figure(gcbo);
        [cx,cy,c1,xi,yi] = improfile;
        n_c = length(c1);
        
        for i_data=1:n_data
            figure(handles.h_fig{i_data});
            [cx,cy,c{i_data}] = improfile(getimage(gca),xi,yi);
        end
        
        fig_xyprofile_name = [name ' xy profile'];
        h_xyprofile = findobj('name',fig_xyprofile_name);
        if isempty(h_xyprofile)
            h_xyprofile = figure('name',fig_xyprofile_name,'NumberTitle','off');
        end
        figure(h_xyprofile);
        plot(cell2mat(c));
        legend(all_fig_name,'Interpreter','none');
        figure(gcbo);
    case {'m'}
        set(gca,'PickableParts','all');
        answer = inputdlg({'Labelmap index (1-8), 0 means erase:','Overwrite current label'},'mask definition',1,{'1','1'});
        if ~isempty(answer)
            mask_index = str2num(answer{1});
            isOverwrite = str2num(answer{2});
            
            if mask_index < 0 || mask_index > 7
                errordlg('label index must be 0 to 8');
            elseif isOverwrite ~= 0 && isOverwrite ~= 1
                errordlg('overwrite flag must be 0 or 1');
            else
                currslice_mask = roipoly;
                modified_mask = input_mask(:,:,curr_slice);
                if isOverwrite
                    modified_mask(currslice_mask) = mask_index;
                else
                    modified_mask(currslice_mask & modified_mask == 0) = mask_index;
                end
                input_mask(:,:,curr_slice) = modified_mask;
            end
        end
        set(gca,'PickableParts','none');
    case {'z'}
        [xpos,ypos] = ginput(1);
        xpos = round(xpos);
        ypos = round(ypos);
        if xpos < 1 || xpos > n_y || ypos < 1 || ypos > n_x
            return
        end
        
        for i_data=1:n_data
            curr_handle = guidata(handles.h_fig{i_data});
            h_zprofile_fig{i_data} = curr_handle.h_zprofile_fig{i_data};
            if isempty(h_zprofile_fig{i_data})
                fig_zprofile_name = [curr_handle.name ' ' curr_handle.data_name ' zprofile'];
                h_zprofile_fig{i_data} = figure('name',fig_zprofile_name,'NumberTitle','off');
            end
            figure(h_zprofile_fig{i_data});
            
            plot(1:curr_handle.n_slice,squeeze(curr_handle.data(ypos,xpos,:,curr_handle.curr_frame,curr_handle.curr_framegroup)),'+-');
            title(curr_handle.data_name);
            curr_handle.h_zprofile = h_zprofile_fig;
            guidata(handles.h_fig{i_data},curr_handle);
            figure(gcbo);
        end
    case {'s'}
        output_mask = handles.input_mask;
        answer = inputdlg('mask variable name:','Output mask to variable',1,{handles.output_mask_name});
        if ~isempty(answer)
            assignin('base',answer{1},output_mask);
        end
    case {'-'}
        set(gca,'PickableParts','all');

        [x,y] = ginput(1);
        x = round(x);
        y = round(y);

        %assume the mask in the penultimate element in h_fig
        h_labelfig = h_fig{end-1};
        labelfig_handles = guidata(h_labelfig);
        label_img = labelfig_handles.data(:,:,curr_slice,curr_frame,curr_framegroup);
        
        blob_mask = grayconnected(label_img,y,x,0);
        modified_mask = input_mask(:,:,curr_slice);
        modified_mask(blob_mask) = 0;
        input_mask(:,:,curr_slice) = modified_mask;

        %assume the mask is the last element in h_fig
        h_maskfig = h_fig{end};
        maskfig_handles = guidata(h_maskfig);
        maskfig_handles.data(:,:,curr_slice,curr_frame,curr_framegroup) = modified_mask;
        guidata(handles.h_fig{end},maskfig_handles);

        set(gca,'PickableParts','none');
    case {'='}
        set(gca,'PickableParts','all');

        [x,y] = ginput(1);
        x = round(x);
        y = round(y);

        %assume the mask in the penultimate element in h_fig
        h_labelfig = h_fig{end-1};
        labelfig_handles = guidata(h_labelfig);
        label_img = labelfig_handles.data(:,:,curr_slice,curr_frame,curr_framegroup);
        
        blob_mask = grayconnected(label_img,y,x,0);
        modified_mask = input_mask(:,:,curr_slice);
        modified_mask(blob_mask) = 1;
        input_mask(:,:,curr_slice) = modified_mask;

        %assume the mask is the last element in h_fig
        h_maskfig = h_fig{end};
        maskfig_handles = guidata(h_maskfig);
        maskfig_handles.data(:,:,curr_slice,curr_frame,curr_framegroup) = modified_mask;
        guidata(handles.h_fig{end},maskfig_handles);

        set(gca,'PickableParts','none');
end


for i_data = 1:n_data
    handles = guidata(handles.h_fig{i_data});
    handles.curr_slice = curr_slice;
    handles.curr_frame = curr_frame;
    handles.curr_framegroup = curr_framegroup;
    handles.xpos = xpos;
    handles.ypos = ypos;
    handles.n_slice = n_slice;
    handles.n_frame = n_frame;
    handles.n_framegroup = n_framegroup;
    handles.input_mask = input_mask;
    handles.isROIshow = isROIshow;
    if exist('h_zprofile_fig','var')
        handles.h_zprofile_fig = h_zprofile_fig;
    end
    guidata(handles.h_fig{i_data},handles);
end

UpdateFig(handles.h_fig);
UpdateProfile(h_fig,[ypos,xpos,gcbo_handles.curr_slice],gcbo_handles.curr_framegroup);

figure(gcbo);

end

%%

function imNavMouseClick(src,event)

gcbo_handles = guidata(gcbo);
n_data = gcbo_handles.n_data;
h_fig = gcbo_handles.h_fig;
n_x = size(gcbo_handles.data,2);
n_y = size(gcbo_handles.data,1);

click_type=get(gcf,'SelectionType');
ax_currentpoint = get(gca,'CurrentPoint');
ypos = round(ax_currentpoint(1,2));
xpos = round(ax_currentpoint(1,1));

if xpos < 1 || xpos > n_x || ypos < 1 || ypos > n_y
    return
end

if strcmp(click_type,'normal')
    UpdateProfile(h_fig,[ypos,xpos,gcbo_handles.curr_slice],gcbo_handles.curr_framegroup);
end

UpdateFig(gcbo_handles.h_fig);
figure(gcbo);
end

function UpdateProfile(h_fig,location,curr_framegroup)


n_data = length(h_fig);
for i_data=1:n_data
    h_currfig = h_fig{i_data};
    handles = guidata(h_currfig);
    disp([handles.data_name ':']);

    if length(location(:)) == 3 %location is the (x,y,z) position of a single point
        ypos = location(1);
        xpos = location(2);
        curr_slice = location(3);
        handles.ypos = ypos;
        handles.xpos = xpos;
        profile = squeeze(handles.data(ypos,xpos,curr_slice,:,curr_framegroup));
        disp(profile);
    else %location is a binary mask over the entire volume, denoting the points to consolidate
        mask = logical(location);
        for i_frame = 1:handles.n_frame
            curr_imvol = handles.data(:,:,:,i_frame,curr_framegroup);
            frame_pts{i_frame} = curr_imvol(mask);
            avg_signal(i_frame) = mean(frame_pts{i_frame});
            stdev_signal(i_frame) = std(frame_pts{i_frame});   
            ROI_statistic = 'mean';
            switch ROI_statistic
                case 'mean'
                    profile(i_frame) = avg_signal(i_frame);
                case 'stdev'
                    profile(i_frame) = std(frame_pts{i_frame});
            end
        end
        if handles.n_frame == 1
            disp(['mean= ' num2str(avg_signal) ' stdev= ' num2str(stdev_signal)]);
        else
            disp('mean:');
            disp(avg_signal');
            disp('stdev:');
            disp(stdev_signal');
        end
    end
    figure(h_currfig);
    guidata(h_currfig,handles);
    
    
    if handles.n_frame > 1
        h_profile = handles.h_profile_fig{i_data};
        if isempty(h_profile)
            fig_profile_name = [handles.name ' ' handles.data_name ' profile'];
            h_profile=figure('name',fig_profile_name,'NumberTitle','off');
            handles.h_profile_fig{i_data} = h_profile;
            screen_size = get(0,'screensize');
            
            profile_width = round(screen_size(3)/handles.n_firstrow_fig);
            profile_height =  round(profile_width*handles.aspect_ratio(1)/handles.aspect_ratio(2));
            profile_vertoffset = ((handles.fig_row_position(2))/handles.fig_row_position(1)*screen_size(4))-profile_height;
            outerpos = [profile_width*(2*i_data-1)+1 profile_vertoffset profile_width profile_height];
            set(h_profile,'OuterPosition',outerpos);
            if handles.isAutoArrange
                autoArrangeFigures();
            end
        end
        figure(h_profile);
        
        if ~handles.isSemilog_profile
            plot(handles.frame_val,profile,'+-');
        else
            semilogx(handles.frame_val,profile,'-');
            xlim([min(handles.frame_val) max(handles.frame_val)]);
        end
        if ~handles.isProfile_autoscale
           ylim(handles.clim); 
        end
        guidata(h_currfig,handles);
    end
end

if handles.isProfileData
    for i_profile = 1:handles.n_profile
        fig_altprofile_name = [handles.name ' ' handles.profile_figname{i_profile}];
        h_altprofile = findobj('name',fig_altprofile_name);
        if isempty(h_altprofile)
            h_altprofile = figure('name',fig_altprofile_name,'NumberTitle','off');
            screen_size = get(0,'screensize');
            profile_width = round(screen_size(3)/handles.n_firstrow_fig);
            profile_height =  round(profile_width*handles.aspect_ratio(1)/handles.aspect_ratio(2));
            profile_vertoffset = ((handles.fig_row_position(2))/handles.fig_row_position(1)*screen_size(4))-profile_height;
            profile_fig_offset = handles.n_firstrow_fig - handles.n_altprofile_fig;
            for i_handle = 1:handles.n_altprofile_fig
                if strcmp(handles.profile_figname{i_profile},handles.altprofile_figname{i_handle})
                    outerpos = [profile_width*(i_handle-1)+profile_fig_offset*profile_width + 1 profile_vertoffset profile_width profile_height];
                end
            end
            set(h_altprofile,'OuterPosition',outerpos);
            for i_data=1:n_data
                fig_handle = guidata(handles.h_fig{i_data});
                fig_handle.h_altprofile_fig{i_profile} = h_altprofile;
                guidata(handles.h_fig{i_data},fig_handle);
            end
            if handles.isAutoArrange
                autoArrangeFigures();
            end
        end
        figure(h_altprofile);
        set(gca,'Visible','On');
        
        userdata = get(h_altprofile,'UserData');
        if ~isempty(userdata)
            if userdata.shouldHold
                hold on;
            end
        end
        
        profile = [];
        xdata = handles.profile_xdata{i_profile};
        if ~isvector(xdata)
            xdata = squeeze(xdata(ypos,xpos,curr_slice,:));
        end
        
        n_profile_frame = length(handles.profile_xdata{i_profile});
        if length(location(:)) == 3 %location is the (x,y,z) position of a single point
            profile = squeeze(handles.profile_image{i_profile}(ypos,xpos,curr_slice,:));
        else %location is a binary mask over the entire volume, denoting the points to consolidate
            for i_frame = 1:n_profile_frame
                curr_imvol = handles.profile_image{i_profile}(:,:,:,i_frame);
                frame_pts{i_frame} = curr_imvol(mask);
                ROI_statistic = 'mean';
                switch ROI_statistic
                    case 'mean'
                        profile(i_frame) = mean(frame_pts{i_frame});
                    case 'stdev'
                        profile(i_frame) = mean(frame_pts{i_frame});
                end
            end
        end

        
        if ~handles.profile_isSemilog{i_profile}
            plot(xdata,profile,handles.profile_plotstyle{i_profile});
        else
            semilogx(xdata,profile,handles.profile_plotstyle{i_profile});
        end
        
        % if this is the first time the profile figure has been updated
        % since the click, then set the UserData.shouldHold to true to
        % denote that existing data should be held.
        if isempty(userdata)
            userdata.shouldHold = true;
            userdata.legend_txt = {handles.profile_label{i_profile}};
            legend(userdata.legend_txt,'Interpreter','none');
        else
            userdata.legend_txt = [userdata.legend_txt handles.profile_label{i_profile}];
            legend(userdata.legend_txt);
        end
        set(h_altprofile,'UserData',userdata);
    end
    
    % now that all profiles have been updated, reset the UserData to a
    % null variable (which will denote that the next time the user
    % right-clicks, then the figure should be cleared and refreshed.
    for i_profile = 1:handles.n_profile
        fig_altprofile_name = [handles.name ' ' handles.profile_figname{i_profile}];
        h_altprofile = findobj('name',fig_altprofile_name);
        set(h_altprofile,'UserData',[]);
        figure(h_altprofile); hold off;
        set(gca,'Visible','On');
    end
    
end


end

%%
function UpdateFig(h_allfig)

n_data = length(h_allfig);
for i_data = 1:n_data
    h_currfig = h_allfig{i_data};
    handles = guidata(h_currfig);
    figure(h_currfig);
    
    % intensity scaling
    display_im = squeeze(handles.data(:,:,handles.curr_slice,handles.curr_frame,handles.curr_framegroup));
    if strcmp(handles.threshold_mode,'percentile_curr')
        grayscale_limits = [prctile(display_im(:),handles.prctile_min),prctile(display_im(:),handles.prctile_max)];
    elseif strcmp(handles.threshold_mode,'percentile_all')
        grayscale_limits = handles.grayscale_limits_whole;
    elseif strcmp(handles.threshold_mode,'abs')
        grayscale_limits = handles.clim;
    end
    % grayscale limits can't be equal (which happens if image is flat)
    if grayscale_limits(1) == grayscale_limits(2)
        if isinteger(display_im)
            grayscale_limits(2) = grayscale_limits(1)+1;
        else
            grayscale_limits(2) = grayscale_limits(1)*1.01;
        end
    end
    handles.clim = grayscale_limits;
    
    if handles.isFirstDisplay
        h_im = imagesc(display_im,grayscale_limits); colormap(handles.cmap); colorbar;
        set(h_im,'Tag','main');
        hold on
        h_im2 = imagesc(zeros(size(display_im)));
        set(h_im2,'Tag','overlay','AlphaData',0);
        set(gca,'PickableParts','none');
        screen_size = get(0,'screensize');
        imNav_width = round(screen_size(3)/handles.n_firstrow_fig);
        imNav_height = round(imNav_width*handles.aspect_ratio(1)/handles.aspect_ratio(2));
        imNav_vertoffset = ((handles.fig_row_position(2))/handles.fig_row_position(1)*screen_size(4))-imNav_height;
        if handles.n_frame > 1
            outerpos = [imNav_width*2*(i_data-1)+1 imNav_vertoffset imNav_width imNav_height];
        else
            outerpos = [imNav_width*(i_data-1)+1 imNav_vertoffset imNav_width imNav_height];
        end
        set(h_currfig,'OuterPosition',outerpos);
        set(gca,'DataAspectRatio',handles.aspect_ratio);
        if handles.isAutoArrange
            autoArrangeFigures();
        end
        handles.isFirstDisplay = false;
    end
    h_im = findobj(gca,'Tag','main');
    set(h_im,'CData',display_im); caxis(grayscale_limits);
    
    data_value = display_im(handles.ypos,handles.xpos);
    title_txt = [' FG=' num2str(handles.curr_framegroup) ' F=' num2str(handles.frame_val(handles.curr_frame)) ' Z=' num2str(handles.curr_slice) ' X=' num2str(handles.xpos) ' Y=' num2str(handles.ypos) ' value=' num2str(data_value)];
    highlightClickBox(h_currfig,'cursor',handles.ypos,handles.xpos);
    title(title_txt,'FontSize',8);
    h_poly = findobj(gca,'Type','Line');
    if ~isempty(h_poly)
        delete(h_poly);
    end
    
    h_overlay = findobj(h_currfig,'Tag','overlay');
    if handles.isROIshow && i_data == 1
        curr_mask = handles.input_mask(:,:,handles.curr_slice);
        alpha = double(curr_mask~=0)*0.5;
        mask_rgb = ind2rgb(curr_mask,prism(8));
        set(h_overlay,'CData',mask_rgb,'AlphaData',alpha);
    else
        set(h_overlay,'AlphaData',0);
    end
    guidata(h_currfig,handles);
end



end