
% FSE/RARE image, as well as the assumed number of Otsu intensity ranges,
% and an initial choice of which class indices to include as the
% hemorrhage segmentation.

% For each dataset, record the following as an individual cell element in the 
% the file_info array (using the example as a guide):
%      }


% <basename for output file and GUI labeling>,
% <location of the nrrd files for the current subject>,
% <name of the FSE nrrd file>,
% <number of Otsu thresholds>,
% <vector of indices that are considered as segmenting the cord
% <name of isotropic denoised MEDIC images>,
% <name of isotropic SWI image>,
% <name of original cord mask from FSE>,
% <name of cord mask, resampled on isotropic SWI image>,
% <number of Otsu thresholds on SWI to segment the cord>,
% <classmap indices on SWI to consider initially as hemorrhage>,



input_basepath = 'C:\Users\User\exampledata\Original NRRD files';
info_filepath =  'C:\Users\User\exampledata\Analyzed NRRD files\Otsu_hem_fileinfo.mat';


file_info = {

%Copy and paste the files to be analyzed below:

    {'Test',...
        'Test\Stitched',...
        'Test_FSE_ax_m0_stitched.nrrd',...
        3,[1 2],...
        'Test_MEDICcomb_iso_m-4_stitched.nrrd',... 
        'Test_MEDICcomb_iso_m-4_stitched.nrrd',...
        'Test_FSE_stitched_cordmask.nrrd',...
        'Test_MEDIC_stitched_cordmask_eroded.nrrd',...     
        4,[1 2],... 
        'Test_MEDIC_stitched_IPHseg.nrrd'},...


    {'2_Feldspar',...                                       %folder_name
        '2_Feldspar\Stitched',...                           %subfolder_name
        'Feldspar_FSE_ax_m4_stitched.nrrd',...              %FSE_stitched
        3,[1 2],...                                         
        'Feldspar_MEDICcomb_iso_m-4_stitched.nrrd',...      %MEDIC_stitched_mastervolume
        'Feldspar_MEDICcomb_iso_m-4_stitched.nrrd',...      %MEDIC_stitched_cropped
        'Feldspar_FSE_stitched_cordmask.nrrd',...           %FSE_SC_segmentation
        'Feldspar_MEDIC_stitched_cordmask_eroded.nrrd',...  %MEDIC_SC_segmentation_eroded
        4,[],...                                            %Number of Otsu classes [which classes are defined as IPH] for the IPH segmentation
        'Feldspar_MEDIC_stitched_IPHseg.nrrd'},...          %MEDIC_IPH_segmentation
    

   }

save(info_filepath,'file_info','input_basepath')