import pickle
import numpy
import pathlib
import scipy.io
import shutil
import cv2
from PIL import Image
temp = pathlib.PosixPath
pathlib.PosixPath = pathlib.WindowsPath

# setting - set the path to prickle log of the matches, images, masks_gt, and set of fixed static / dynamic classes
data = None
with open('SPRING_Demo/BrocaQueryRealistic/hloc_results/query_localization_results.txt_logs.pkl', 'rb') as pickle_file:
    data = pickle.load(pickle_file)
    assert data, 'Unable to load the log.'

yolact_dataset_name = 'BrocaQueryRealistic'
path_to_query_images = pathlib.Path(f'SPRING_Demo/{yolact_dataset_name}/images')
path_to_yolact_masks = pathlib.Path(f'SPRING_Demo/{yolact_dataset_name}/masks')
path_to_masks_gt = pathlib.Path(f'SPRING_Demo/{yolact_dataset_name}/masks_gt')

np_object2classes = numpy.loadtxt('SPRING_Demo/BrocaQueryRealistic/object2classes_real.txt', dtype=int)
object2classes = {}
for line in np_object2classes:
    object2classes[line[0]] = line[1]
object2classes[0] = -1
dynamic_classes = [0]   #[0, 60]
static_classes = [-1, 62, 72]   #[-1, 27, 56, 62, 63, 72, 73]

thresholds_k = numpy.arange(0.000000001,0.00003,0.0000005).tolist()


# 1) check the number of matches on masks of objects calculated by instance segmentation
# 2) if the number is larger than threshold "k" or object is in fixed class -> paint of hide mask from query image
# 3) evaluate the succes rate, i.e., the mask difference wrt. the ground truth mask  
for k in thresholds_k:
    correct_mask_px_count = 0
    all_px_count = 0

    path_to_output_masks = pathlib.Path(f'SPRING_Demo/{yolact_dataset_name}/final_masks_output_area_{k}')
    path_to_output_masks.mkdir(exist_ok=True)
    for query_name in data['loc']:
        path = pathlib.Path(path_to_query_images / query_name[6:])
        if(path.is_file()):
            # mat_data = scipy.io.loadmat(path_to_yolact_masks / (query_name[6:-4] + '.mat'))
            # instance_segmentation = numpy.array(mat_data['mask'])
            # instance_segmentation_image = Image.open(open(path_to_yolact_masks / (query_name[6:-4] + '.png'), 'rb'))
            instance_segmentation_image = cv2.imread(str(path_to_yolact_masks / (query_name[6:-4] + '.png')), cv2.IMREAD_UNCHANGED)
            instance_segmentation = numpy.array(instance_segmentation_image).astype("uint16")[:,:,0]
            tracks_count = dict.fromkeys(numpy.unique(instance_segmentation), 0)
            #print(tracks_count)

            # shutil.copy2(path_to_query_images / query_name[6:], path_to_output_masks / (query_name[6:-4] + '_1query.png'))
            # shutil.copy2(path_to_masks_gt / (query_name[6:-4] + '.png'), path_to_output_masks / (query_name[6:-4] + '_2mask_gt.png'))
            # instance_segmentation2 = numpy.copy(instance_segmentation)
            # for i, instance_id in enumerate(tracks_count):
            #     instance_segmentation2[instance_segmentation==instance_id] = i
            # if numpy.max(instance_segmentation2) == 0:
            #     segment_image = Image.fromarray(numpy.uint8(instance_segmentation2))
            # else:
            #     segment_image = Image.fromarray(numpy.uint8(instance_segmentation2*(255/numpy.max(instance_segmentation2))))
            # segment_image.save(path_to_output_masks / (query_name[6:-4] + '_3yolact.png'))


            query_data = data['loc'][query_name]
            for i, keypoint in enumerate(query_data['keypoints_query']):
                if query_data['PnP_ret']['success'] and query_data['PnP_ret']['inliers'][i] \
                    and len(query_data['keypoint_index_to_db'][1][i][1]) > 1:
                    image_coordinates = numpy.round(keypoint).astype(dtype=numpy.int32)
                    tracks_count[instance_segmentation[image_coordinates[1],image_coordinates[0]]] += 1
            
            dynamic_mask = numpy.copy(instance_segmentation)
            for instance_id in tracks_count: 
                area_size = numpy.sum(instance_segmentation==instance_id)
                obj_class = object2classes[instance_id]
                hardcoded_class = False
                if obj_class in static_classes:             # fixed static classes
                    hardcoded_class = True 
                    dynamic_mask[instance_segmentation==instance_id] = 0
                if obj_class in dynamic_classes:            # fixed dynamic classes
                    hardcoded_class = True
                    dynamic_mask[instance_segmentation==instance_id] = 1
                if not hardcoded_class:                     # unknown classes
                    if (tracks_count[instance_id] / area_size) > k:   # tracks_count[instance_id] > 2 and 
                        dynamic_mask[instance_segmentation==instance_id] = 0
                    else:
                        dynamic_mask[instance_segmentation==instance_id] = 1
            
            mask_uint8 = numpy.uint8(dynamic_mask*255)
            mask_image = Image.fromarray(mask_uint8)
            mask_image.save(path_to_output_masks / (query_name[6:-4] + '.png'))     # _4output

            mask_gt_image = Image.open(open(path_to_masks_gt / (query_name[6:-4] + '.png'), 'rb'))
            mask_gt = numpy.array(mask_gt_image)
            mask_dimensions = numpy.shape(dynamic_mask) 
            correct_mask_px_count += numpy.sum(mask_uint8 == mask_gt_image)
            all_px_count += (mask_dimensions[0] * mask_dimensions[1])
    
    correct_masks_proc = 100 * (correct_mask_px_count / all_px_count)
    print(f'Evaluation for k={k} the {correct_masks_proc}% of masks was correctly filtered.')