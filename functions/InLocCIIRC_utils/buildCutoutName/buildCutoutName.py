import os
from pathlib import Path

def buildCutoutName(cutoutPath, extension):
    basename = Path(cutoutPath).stem
    spaceName = cutoutPath.split('/')[0]
    splitBasename = basename.split('_')
    name = splitBasename[0] + '_' + spaceName + '_' + '_'.join(splitBasename[1:]) + extension
    return name
