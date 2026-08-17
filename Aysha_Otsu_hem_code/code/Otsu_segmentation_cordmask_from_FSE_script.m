output_basepath = 'C:\Users\user\MRI\Hemorrhage Study\Analyzed NRRD files';
info_filepath =  'C:\Users\user\MRI\Hemorrhage Study\Input NRRD files\Otsu_hem_fileinfo.mat';


%%
% STEP 1: For each subject/experimental session, record the filename
% information and selected Otsu parameters in Otsu_segmentation_fileinfo.m
% and run that script. A matfile will be saved which is loaded into memory.
     
load(info_filepath);  %loads input_basepath and file_info
n_file = length(file_info);


%%
% STEP 2:  Set the index for the current dataset to segment by changing the
% selected_index variable, either as a single number (number 2 means the
% 2nd dataset defined in file_info) or a range of numbers for multiple
% datasets (eg. selected_index = 1:5)
selected_index = 1;
%%

se = strel('diamond',2);
for i_file=selected_index
    % per-dataset info load
    basename = file_info{i_file}{1};
    input_path = [input_basepath filesep file_info{i_file}{2} filesep file_info{i_file}{3}];
    reference_nthresh = file_info{i_file}{4};
    reference_incl_label = file_info{i_file}{5};

    % load reference data to segment the cord
    dataset = nrrdread(input_path);
    data = dataset.pixelData;
    mask  = false(size(data));
    labelmap1 = zeros(size(mask));

    dim = size(data);
    n_slice = dim(3);

    % apply Otsu thresholding with specified number of levels.  This is
    % done slice-by-slice (which helps if the edge of the image volume has
    % signal dropoff)
    for i_slice = 1:n_slice
        threshold = multithresh(data(:,:,i_slice),reference_nthresh);
        labelmap1(:,:,i_slice) = imquantize(data(:,:,i_slice),threshold);
    end

    % build the segmentation map of cord with the specified labelmap indices
    n_label = length(reference_incl_label);
    for i_label=reference_incl_label
        mask(labelmap1==i_label) = true;
    end

    % groom the raw mask through a series of image processing steps.
    % - "bwareaopen" removes any islands with pixels less than the specified
    %   number of pixels
    % - "imdilate" adds another shell of pixels (useful for filling gaps or
    %   to reverse the effect of imerode)
    % - "imfill" fills unsegmented holes
    % = "imerode" can remove or shrink small islands

    for i_slice = 1:n_slice
        curr_mask = mask(:,:,i_slice);
        curr_mask = imerode(curr_mask,se);
        curr_mask = imfill(curr_mask,'holes');
        
        [L,n] = bwlabel(curr_mask,4);
        cord_label = L(dim(1)/2,dim(2)/2);
        curr_mask(L~=cord_label) = 0;

        curr_mask = imdilate(curr_mask,se);

        mask(:,:,i_slice) = curr_mask;
    end


    masked_labelmap = labelmap1;
    masked_labelmap(mask) = 0;


    % final erode operation, to exclude the boundary of the cord.  We
    % should now have a mask that encompasses the cord, more or less.
    mask = imerode(mask,se);

%%
    % STEP 3:  if processing single datasets a time, the results of the
    % segmentation can be previewed by the imNav tool
    maxval = prctile(data(:),99);
    close all; imNav({data,labelmap1,masked_labelmap,mask},'cmap',{'gray','jet','jet','jet'},'clim',{[0 maxval],[0 4],[0 4],[0 1]});
%%
    matData2Nrrd(int16(mask),output_basepath,[basename '_RARE_cordmask.nrrd'],'geometry_nrrd_reference_path',input_path);
end


% expected output of MATLAB script:  a nrrd file that contains the integer classmap, stored
% in the specified output folder, with filename
% <basename>_RARE_cordmask.nrrd.  A resampled version of this classmap volume must be
% manually generated in Slicer to match the geometry and pixel matrix of
% the target image volume to be segmented (i.e. the isotropic MGE/SWI
% volumes)

