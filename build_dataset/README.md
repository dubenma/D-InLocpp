# Creation of dataset

We provide an an automatic creation of a dataset for localization based on data provided after scanning with a Matterport 3D scanner (<https://matterport.com/>).

After scanning the scene download MatterPak. All additional files can be downloaded using the scripts in ``downloadMatterport``.
Then create perspective images (cutouts) using ``buildCutouts/generate_cutouts.m``.

For acquiring depth and semantic information we used AI Habitat simulator. Follow the instructions on their [site](https://aihabitat.org/) to install it.
You need to convert the .obj mesh form Matterpak file to .glb to use it and generate a navmesh using Habitat. 
Then clone the repository [gitlab.com/ferbrjan/habitat_ros_semantic_2](https://gitlab.com/ferbrjan/habitat_ros_semantic_2). And after adjusting paths run ``spring_simulation/generate_dataset_cutout.py``.

The last step is to get all the data to the correct format so that you can run Inloc. Use the script ``prepareDataset/prepareDataset.m`` to create a dababase. At the end  run `prepareDataset/splitQuery.m` to separate query data from the database.

