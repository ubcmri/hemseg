clear
close all

output_basepath = 'C:\Users\User\exampledata\Analyzed NRRD files';
info_filepath =  'C:\Users\User\exampledata\Analyzed NRRD files\Otsu_hem_fileinfo.mat';

isOverwriteHemMask = false;
selected_index = 2; %Will analyze the animal defined as the corresponding element in the cell array defined in Otsu_segmentation_fileinfo_script.
included_slices = 100:200; %Slice range for the analysis

load(info_filepath);  %loads input_basepath and file_info
n_file = length(file_info);

histogram_dir = 'IPH_grey_value_histogram';

se = strel('diamond',1);
%%
% STEP 3:  Set the index for the current dataset to segment by changing the
% selected_index variable as a single number

ylim_histogram = 80; %Y-axis of the pixel intensity histograms for each slice
xlim_histogram = [0 250]; %X-axis of the pixel intensity histograms for each slice

for i_file=selected_index
    session_dirname = file_info{i_file}{2};
    input_path = [input_basepath filesep session_dirname filesep file_info{i_file}{6}]; %changed to element 6, because we are using the MEDIC stitched volume
    hemseg_path = [output_basepath filesep session_dirname];

	histogram_output_path = [hemseg_path filesep histogram_dir];
	if ~exist(histogram_output_path,'dir')
        mkdir(histogram_output_path);
    end

    basename = file_info{i_file}{1};
    targetim_nthresh = file_info{i_file}{10};
    targetim_incl_label = file_info{i_file}{11};
    dataset = nrrd_read(input_path);
    SWI_image = dataset.pixelData;
    n_slice = size(SWI_image,3);

    masked_cord = dataset.pixelData;

    dataset = nrrd_read([hemseg_path filesep file_info{i_file}{9}]);
    cordmask = logical(dataset.pixelData);

    maxval_global = max(masked_cord(:));
    masked_cord = masked_cord/maxval_global * 255;
    masked_cord(~cordmask) = -100;
    

    text_spacing = 0.05;
    labelmap_final = zeros(size(masked_cord));
    for i_slice = included_slices
        disp(num2str(i_slice))
        cord_pts = masked_cord(:,:,i_slice);
        cord_pts = cord_pts(cordmask(:,:,i_slice));
        threshold_final{i_slice} = multithresh(cord_pts,targetim_nthresh);
        labelmap_final(:,:,i_slice) = imquantize(masked_cord(:,:,i_slice),threshold_final{i_slice});

        histogram_pts = masked_cord(:,:,i_slice);
        histogram_pts = histogram_pts(:);
        histogram_pts(histogram_pts==-100) = [];
        slice_histogram_pts{i_slice} = histogram_pts;
        hf=figure(200); histogram(slice_histogram_pts{i_slice},100);
        n_thresh = length(threshold_final{i_slice});
        ylim([0 ylim_histogram])
        ytick = get(gca,'YTick');
        hold on
        for i_thresh = 1:n_thresh
            plot([threshold_final{i_slice}(i_thresh) threshold_final{i_slice}(i_thresh)],[0 ylim_histogram],'k');
            xlabel('Pixel intensity'); ylabel('Pixel count');
            xlim(xlim_histogram)
            text(threshold_final{i_slice}(i_thresh),ylim_histogram-ylim_histogram*text_spacing*i_thresh,num2str(threshold_final{i_slice}(i_thresh)))
        end
        if ~isempty(targetim_incl_label)
            if min(targetim_incl_label) == 1
                x1 = 0;
            else
                x1 = threshold_final{i_slice}(min(targetim_incl_label)-1);
            end
            x2 = threshold_final{i_slice}(max(targetim_incl_label));
            y1 = 0;
            y2 = ylim_histogram;
            hp=patch([x1 x1 x2 x2],[y1 y2 y2 y1],'y');
            set(hp,'FaceVertexAlphaData',0.01);
            set(hp,'FaceAlpha','flat');
        end
        hold off
        histo_plot_prefix = [histogram_output_path filesep basename '_hemseg_histogram_slice'];
        saveas(hf,[histogram_output_path filesep basename '_hemseg_histogram_slice' num2str(i_slice) '.png']);
    end
    labelmap_final(~cordmask) = 0;

    hem_mask_filepath = [hemseg_path filesep file_info{i_file}{12}];
    if isOverwriteHemMask || ~exist(hem_mask_filepath,'file')
        mask = false(size(masked_cord));
        for i_label = targetim_incl_label
            mask(labelmap_final==i_label) = true;
        end
        mask(~cordmask) = false;
    else
        img = nrrd_read(hem_mask_filepath);
        mask = img.pixelData;
    end

    close all; imNav2({masked_cord,labelmap_final,mask},'name','hem seg','label',{'cord','otsu labelmap','hem mask'},'cmap',{'gray','jet','jet'},'clim',{[0 255],[0 5],[0 1]},'input_mask',mask,'histo_plot_prefix',histo_plot_prefix);
    answer = '';
    while ~strcmp(answer,'done')
        disp(answer)
        answer = input('work on the hem mask, and tap "s" when done, and save the current mask in the mask variable.  Type done when finished:  ','s');
    end

    answer = input('Do you want to save hem segmentation files as nrrd?','s');
    if strcmp(answer,'y')
        matData2Nrrd(masked_cord,hemseg_path,['masked_' file_info{i_file}{7}],'geometry_nrrd_reference_path',input_path);
        matData2Nrrd(int16(mask),hemseg_path,file_info{i_file}{12},'geometry_nrrd_reference_path',input_path);
        matData2Nrrd(int16(labelmap_final),hemseg_path,[basename '_MEDIC_stitched_IPH_classmap.nrrd'],'geometry_nrrd_reference_path',input_path);
    end
end

