"""
Module: common.utilities.image_display.imageVisualization
Description: Contains code that generates image visualization grids and colourbars.
"""
import math
import matplotlib
import matplotlib.pyplot as plt
from mpl_toolkits.axes_grid1 import make_axes_locatable
import nibabel as nib
import numpy as np
import os
import scipy.ndimage

class ImageDataset:
    """
    This is the datastructure that must be passed to the createImageGrid() function
    It comtains the 3D data as well as the following information:
        name   - the name of the dataset to appear at the top of this dataset's column
                 in the image grid.
        slices - The desired slice indices to select for adding to an image visualization.
        rot    - A desired rotation angle to rotate the in plane images by. Specified as a 
                 value between 0 and 360 and will apply a counter-clockwise rotation.
        vmin   - (Optional) The minimum value on the colourmap scale
        vmax   - (Optional) The maximum value on the colourmap scale
        cmap   - (Optional) A string representing the desired colourmap (eg viridis, magma, etc.)
                 A comprehensive list of available colourmaps can be found here:
                 https://matplotlib.org/3.1.0/tutorials/colors/colormaps.html
    """
    def __init__(self, data, slices, name, rot = 0, vmin = None, vmax = None, cmap = 'gray'):
        self.data = data
        self.name = name
        self.rot = rot
        self.vmin = vmin
        self.vmax = vmax
        self.cmap = cmap
        self.slices = slices


def crop3DDataset(dataset, ref_prctile = 100, min_frac = 1e-2):
    """
    crop a 3D dataset by cropping slice by slice and then padding to ensure each
    slice is the same size.

    Params:
        dataset     - a 3D numpy array of image data to be cropped.
        ref_prctile - Reference for calculating a minimum threshold (percentile between 0 and 100)
                      that is used to determine if a row or column of the image is completely empty.
                      (If pixels in an entire row or column are below the threshold it is considered empty)
        min_frac    - A fraction of the reference percentile used to calculate the threshold
                      described above.

    Returns: A 3D numpy array containing the cropped dataset. 
    """
    cropped_datasets = []
    
    # find max dimension, images will be padded to this after cropping
    maxDim = 0
    skipped_indices = []
    empty_thres = min_frac * np.percentile(dataset, ref_prctile)
    
    for i in range(dataset.shape[2]):
        img = dataset[:,:,i]
        non_empty_columns = np.where(img.max(axis=0)>empty_thres)[0]
        non_empty_rows = np.where(img.max(axis=1)>empty_thres)[0]
        #skip if slice is empty
        if len(non_empty_rows) > 0 and len(non_empty_columns) > 0:
            cropBox = (min(non_empty_rows), max(non_empty_rows), min(non_empty_columns), max(non_empty_columns))
            img = img[max(cropBox[0]-1,0):min(cropBox[1]+1, img.shape[0]), max(cropBox[2]-1,0):min(cropBox[3]+1, img.shape[1])]
            if max(img.shape) > maxDim:
                maxDim = max(img.shape)
        else:
            skipped_indices.append(i)
        cropped_datasets.append(img)

    # Now combine into a 3D np array instead of a list of images
    cropped3D = np.zeros((maxDim, maxDim, dataset.shape[2]))
    
    # loop through cropped data, pad and add to cropped3D
    for i in range(len(cropped_datasets)):
        img = cropped_datasets[i]
        
        if i not in skipped_indices:
            x_padding = maxDim - img.shape[0]
            y_padding = maxDim - img.shape[1]
            total_padding = ((int(x_padding/2) + x_padding%2, int(x_padding/2)),(int(y_padding/2) + y_padding%2, int(y_padding/2)))
            cropped3D[:,:,i] = np.pad(cropped_datasets[i], total_padding, mode='constant')
        else:
            # entire slice is just 0 so just need to resize, no padding necessary
            cropped3D[:,:,i] = np.zeros((maxDim, maxDim))
            
    return cropped3D


def createImageGrid(datasets, output_fname, colourBars = False,
                    plot_xz_ims = False, plot_yz_ims = False):
    """
    Creates an image montage of all or a subset of the provided datasets.
    Each dataset will be in its own column with each row representing a different slice.
    The last two rows may be the xz and yz view of the 3D dataset if desired.

    Params:
        datasets     - A list of ImageDataset objects.
        output_fname - The filename (including the path and extention) to which the image
                       grid will be saved. Note, must be in png format.
        colourBars   - A boolean indicating whether to include colour bars in the output image
        plot_xz_ims - A boolean indicating whether to include a xz view of the dataset
                       in the visualization
        plot_yz_ims - A boolean indicating whether to include a yz view of the dataset
                       in the visualization

    Output:
        A png file saved to the path indicated by fname
    """
    # Determine number of slices to plot. The visualization must have the same number
    # of slices per dataset, so if the lenghts of the slice index lists differ, we will
    # use the dataset with smallest number of slices to determine the number of slices
    # to plot, slices from datasets with longer slice index lists will be skipped.
    numSlices = math.inf
    for dataset in datasets:
        if len(dataset.slices) < numSlices:
            numSlices = len(dataset.slices)

    # Prepare grid
    plt.style.use('dark_background')
    numRows = numSlices + int(plot_xz_ims) + int(plot_yz_ims)
    fig, plots = plt.subplots(nrows = numRows, ncols = len(datasets))
    fig.set_size_inches(len(datasets)*5, numRows*5)
    
    col_idx = 0
    for dataset in datasets:
        # Apply rotations
        dataset.data = scipy.ndimage.rotate(dataset.data, dataset.rot, reshape=False, mode='nearest')

        # crop dataset
        data = crop3DDataset(dataset.data)
        row_idx = 0
        
        # Set background zero values to false
        # This ensures the background will be black
        data = np.nan_to_num(data)
        data = np.ma.masked_where(abs(data) < 1e-2, data)
        cmap = matplotlib.cm.get_cmap(dataset.cmap)
        cmap.set_bad('black')
        
        # Plot in plane images
        first_slice = True
        for i in range(numSlices):
            curr_slice = dataset.slices[i]
            img = data[:,:,curr_slice]
            if len(datasets) == 1:
                subplot = plots[row_idx]
            else:
                subplot = plots[row_idx][col_idx]
               
            curr_im = subplot.imshow(img, cmap = cmap, vmin = dataset.vmin, vmax = dataset.vmax)
            subplot.axes.get_xaxis().set_visible(False)
            subplot.axes.get_yaxis().set_visible(False)
            subplot.axis('off')
            
            if first_slice:
                subplot.set_title(dataset.name, fontsize = 25)
                first_slice = False
                
            row_idx = row_idx + 1

        # used to attach colourbar to
        lastplot = subplot

        # Plot xz and yz Images
        if len(datasets) == 1:
            xzplot = plots[row_idx + int(plot_xz_ims) - 1]
            yzplot = plots[row_idx + int(plot_xz_ims) + int(plot_yz_ims) - 1]
        else:
            xzplot = plots[row_idx + int(plot_xz_ims) - 1][col_idx]
            yzplot = plots[row_idx + int(plot_xz_ims) + int(plot_yz_ims) - 1][col_idx]
    
        if plot_xz_ims:
            lastplot = xzplot
            xz_img = np.transpose(data[:,int(data.shape[0]/2),:])
            curr_im = xzplot.imshow(xz_img, cmap = cmap, vmin = dataset.vmin, vmax = dataset.vmax, aspect=3)
            xzplot.axes.get_xaxis().set_visible(False)
            xzplot.axes.get_yaxis().set_visible(False)
            xzplot.axis('off')
        
        if plot_yz_ims:
            lastplot = yzplot
            yz_img = np.transpose(data[int(data.shape[1]/2),:,:])
            curr_im = yzplot.imshow(yz_img, cmap = cmap, vmin = dataset.vmin, vmax = dataset.vmax, aspect=3)
            yzplot.axes.get_xaxis().set_visible(False)
            yzplot.axes.get_yaxis().set_visible(False)
            yzplot.axis('off')

        if colourBars:
            divider = make_axes_locatable(lastplot)
            cax = divider.append_axes('bottom', size='7%', pad=0.5)
            cb = fig.colorbar(curr_im, cax = cax, orientation='horizontal')
        
        col_idx += 1
    
    plt.subplots_adjust(wspace=0, hspace=0)
    plt.savefig(output_fname)
