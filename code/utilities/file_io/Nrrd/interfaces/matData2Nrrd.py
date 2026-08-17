"""
Module: common.utilities.file_io.Nrrd.matData2Nrrd
Description: Nipype interface for MATLAB function matData2Nrrd
             (see /data-processing/common/utilities/file_io/Nrrd/matData2Nrrd.m)
"""
from nipype.interfaces.base import traits, TraitedSpec, BaseInterface, BaseInterfaceInputSpec, File, isdefined
from nipype.interfaces.matlab import MatlabCommand
import os
import string

# custom modules
import common.utilities.constants

class MatData2NrrdInputSpec(BaseInterfaceInputSpec):
    dataIn = File(exists = True, mandatory = True, desc = 'Input .mat file which contains the image variable')
    dest_path = traits.Str(mandatory = True, desc = 'directory path to output .nrrd file')
    dest_filename = traits.Str(mandatory = True, desc = 'filename of output .nrrd file')
    struct_varname = traits.Str(desc = 'name of structure variable where image_varname is a field' \
                             '(if struct_name is not defined, image_varname assumed to be its own' \
                             'separate variable)')
    georef_nrrd_filepath = traits.Str(mandatory = True, desc = 'full file path of another nrrd file which shares' \
                                      'the same geometry.  Its geometry information will be copied to the new nrrd file')
    vox_size = traits.Float(desc = 'if there is no geometry_nrrd_reference_path, a voxel size in' \
                                   'mm can be defined (3 element vector).  If nothing specified' \
                                   'and no geometry reference, the voxel size is 1mm isotropic by default')
    

class MatData2NrrdOutputSpec(TraitedSpec):
    output_nrrd_file = File(exists = True, desc = 'converted nrrd file')

class MatData2Nrrd(BaseInterface):
    """
    Nipype interface that wraps matlab code
    """
    input_spec = MatData2NrrdInputSpec
    output_spec = MatData2NrrdOutputSpec

    def _run_interface(self, runtime):
        """
        This code will be run when the Interface or Node containing the interface's run() function is called.

        runtime contains a number of useful variables, such the current working directory. If possible, outputs
        should be saved to the current working directory, and then will be dealt with in a datasink later on.
        """
        self.basedir = runtime.cwd

        # Create paramValue string for any parameter-value arguments that are defined.

        mlab = MatlabCommand()
        paramValStr = ''
        if isdefined(self.inputs.vox_size):
            paramValStr += ', vox_size, {}'.format(self.inputs.vox_size)
#        if isdefined(self.inputs.georef_nrrd_filepath):
#            paramValStr += ', geometry_nrrd_reference_path, str({})'.format(self.inputs.georef_nrrd_filepath)
            
        mlabParams = dict(repoDir = common.utilities.constants.REPO_DIR,
                          src_path = self.inputs.dataIn,
                          dest_path = self.inputs.dest_path,
                          dest_filename = (self.inputs.dest_filename),
                          georef_nrrd_filepath = self.inputs.georef_nrrd_filepath,
                          paramValStr = paramValStr)

        script_str = string.Template("""
        addpath(genpath('$repoDir'));
        datastruct = load('$src_path');
        image_data = squeeze(datastruct.dataset.data);
        dim = size(image_data);
        if strcmp(datastruct.dataset.recoparx.RECO_image_type, 'COMPLEX_IMAGE') || length(size(image_data))>4
            re_data = image_data(:,:,:,:,1);
            im_data = image_data(:,:,:,:,2);
            image_data = re_data + 1i*im_data;
        end
        
        % protocol_name = datastruct.dataset.acqpparx.ACQ_protocol_name(2:end-1);
        matData2Nrrd(image_data,'$dest_path',strcat('$dest_filename','.nrrd'),'geometry_nrrd_reference_path','$georef_nrrd_filepath' $paramValStr);

        """).substitute(mlabParams)

        mlab.inputs.script = script_str
        result = mlab.run()
        return result.runtime

    def _list_outputs(self):
        """
        This is where the interface outputs are connected to variables or file locations.
        _run_interface().
        """
        outputs = self._outputs().get()
        input_filename = self.inputs.dataIn.split("/")[-1]
        basename = input_filename.split(".")[-1]
        outputs['output_nrrd_file'] = os.path.join(self.basedir, self.inputs.dest_filename + '.nrrd') # take extension from input filename
        return outputs

