output_basepath = 'C:\Users\user\MRI\Hemorrhage Study\Analyzed NRRD files';
info_filepath =  'C:\Users\user\MRI\Hemorrhage Study\Input NRRD files\Otsu_hem_fileinfo.mat';
isOverwriteHemMask = false;
selected_index = 1;
included_slices = 27:192;

load(info_filepath);  %loads input_basepath and file_info
n_file = length(file_info);

se = strel('diamond',1);
%%
% STEP 3:  Set the index for the current dataset to segment by changing the
% selected_index variable as a single number

for i_file=selected_index
    input_path = [input_basepath filesep file_info{i_file}{2} filesep file_info{i_file}{7}];
    swi_nthresh = file_info{i_file}{9};
    swi_incl_label = file_info{i_file}{10};
    dataset = nrrdread(input_path);
    SWI_image = dataset.pixelData;
    n_slice = size(SWI_image,3);

    masked_cord = dataset.pixelData;

    dataset = nrrdread([output_basepath filesep file_info{i_file}{8}]);
    cordmask = logical(dataset.pixelData);

    masked_cord(~cordmask) = -1e4;
    
    labelmap_final = zeros(size(masked_cord));
    for i_slice = included_slices
        disp(num2str(i_slice))
        threshold_final = multithresh(masked_cord(:,:,i_slice),swi_nthresh);
        labelmap_final(:,:,i_slice) = imquantize(masked_cord(:,:,i_slice),threshold_final);
    end

    hemseg_filepath = [output_basepath file_info{i_file}{1} '_isotropic_SWI_hem_mask.nrrd'];
    if isOverwriteHemMask || ~exist(hemseg_filepath,'file')
        mask = false(size(masked_cord));
        for i_label = swi_incl_label
            mask(labelmap_final==i_label) = true;
        end
        mask(~cordmask) = false;
    else
        img = nrrdread(hemseg_filepath);
        mask = img.pixelData;
    end

    close all; imNav({masked_cord,labelmap_final,mask},'name','hem seg','label',{'cord','otsu labelmap','hem mask'},'cmap',{'gray','jet','jet'},'input_mask',mask);
    answer = '';
    while ~strcmp(answer,'done')
        disp(answer)
        answer = input('work on the hem mask, and tap "s" when done, and save the current mask in the mask variable.  Type done when finished:  ','s');
    end

    answer = input('Do you want to save hem mask as nrrd?','s');
    if strcmp(answer,'y')
        matData2Nrrd(masked_cord,output_basepath,['masked_' file_info{i_file}{7}],'geometry_nrrd_reference_path',input_path);
        matData2Nrrd(int16(mask),output_basepath,[basename '_isotropic_SWI_hem_mask.nrrd'],'geometry_nrrd_reference_path',input_path);
        matData2Nrrd(int16(labelmap_final),output_basepath,[basename '_isotropic_SWI_hem_classmap.nrrd'],'geometry_nrrd_reference_path',input_path);
    end
end

