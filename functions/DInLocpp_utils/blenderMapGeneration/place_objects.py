bl_info = {
    "name": "Place objects to scene",
    "author": "Anna Zderadickova",
    "version": (1, 0),
    "blender": (2, 80, 0),
    "warning": "",
    "wiki_url": "",
}

import bpy
import sys
import os
from shutil import copyfile
import random

# params: path_to_scene path_to_folder_with_objects output_file
# blender.exe --background --python D:/Documents/Work/BlenderHelp/place_objects.py -- D:/Documents/Work/BlenderHelp/model.obj D:/Documents/Work/BlenderHelp/objects_categorized/Hospital/Bed/ D:/Documents/Work/BlenderHelp/room_output.obj

def register():
    argv = sys.argv
    argv = argv[argv.index("--") + 1:]
    print('args parsed')

    # Delete any startup objects
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete() 
    print('deleted startup objects')

    # Load model
    model_path = argv[0]
    print('loading scene ' + model_path)
    bpy.ops.import_scene.obj(filepath=model_path)

    # Get model bounding box
    room_boundbox = bpy.context.selected_objects[0].bound_box
    xmin = min([x[0] for x in room_boundbox])
    xmax = max([x[0] for x in room_boundbox])
    ymin = min([x[1] for x in room_boundbox])
    ymax = max([x[1] for x in room_boundbox])
    zmin = min([x[2] for x in room_boundbox])
    zmax = max([x[2] for x in room_boundbox])
    print((xmin, xmax))
    print((zmin, zmax))

    print('Walking folder')
    folder_path = argv[1]
    if not folder_path.endswith('/'):
        folder_path = folder_path + '/'
    
    for r, d, f in os.walk(folder_path):
        for file in f:
            if file.endswith('.obj') or file.endswith('.OBJ'):
                print('Found OBJ file')
                bpy.ops.object.select_all(action='DESELECT')
                bpy.ops.import_scene.obj(filepath= r + file)
                bpy.ops.object.origin_set(type='ORIGIN_GEOMETRY', center ='MEDIAN') 

                ay = random.uniform(0.0, 3.141592)
                # place object at random location inside the map bounding box
                obj_loc = bpy.context.selected_objects[0].location
                tx = random.uniform(xmin, xmax) 
                tz = random.uniform(zmin, zmax)
                bpy.context.selected_objects[0].location.x = tx
                bpy.context.selected_objects[0].location.z = tz
            

                


                        

    # Export as OBJ
    target_file = argv[2]

    bpy.ops.export_scene.obj(filepath=target_file)


    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete() 


                

def unregister():
    pass


if __name__ == "__main__":
    register()
