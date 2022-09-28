The script "segmentation_labeling.py" build the masks of dynamic objects out of the number of matches and fixed list of static / dynamic classes. Note that this script also evaluate the success rate of the mask guess from matches. For such task, the gt_masks of query images are required. If you do not have the gt_masks, please comment the line 93 and further. 

The script "segmentation_labeling.py" needs:
- pickle
- numpy
- pillow
for running. There are also lines to vizualize the inputs, calculations, and gt masks. To generate this visualizations add libraries scipy, shutil and uncomment the lines 45-47 and 53-62. 

The result are image masks of dynamic objects for given set of thresholds "k" for number of inliers divided by object size in pixels. The parameter "k" may be different for diffent datasets. Please, select the masks, that correspond the dynamic objects at most and fix "k" for real-time processing.


Inputs (described at the begining of the script):
- query_localization_results.pkl   ... the HLOC localization log that contains the matches
- path_to_query_images ... the RGB images used as query images
- path_to_yolact_masks ... the YOLACT masks in form of RGB images -> each pixel is the id of individual object
- np_object2classes ... the txt file that maps objects to classes (with lines in format <object_id> <class_id> 
- path_to_masks_gt ... the masks in form of RGB images -> each pixel is the 0 or 1 for static or dynamic class
- [optional] dynamic_classes ... the id of classes that are always assumed as dynamic 
- [optional] static_classes ... the id of classes that are always assumed as static 

Output
- the masks as RGB images where each pixel is the 0 or 1 for static or dynamic class