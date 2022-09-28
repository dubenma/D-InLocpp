import numpy as np
import os
import sys
import matplotlib.pyplot as plt
import scipy.io as sio
from PIL import Image
sys.path.insert(1, os.path.join(sys.path[0], '../functions'))
from InLocCIIRC_utils.buildCutoutName.buildCutoutName import buildCutoutName

def saveFigure(fig, path, width, height):
    plt.axis('off')
    fig.savefig(path, bbox_inches='tight', pad_inches=0)
    img = Image.open(path)
    img = img.resize((width, height), resample=Image.NEAREST)
    img.save(path)

def renderForQuery(queryId, shortlistMode, queryMode, experimentName, useTentativesInsteadOfInliers, topIdx):
    # shortlistMode is a list that can contain values of {'PV', 'PE'}
    # queryMode is one of {'s10e', 'HoloLens1', 'HoloLens2'}
    inlierColor = '#00ff00'
    inlierMarkerSize = 3
    extension = '.png'

    datasetDir = '/Volumes/GoogleDrive/Můj disk/ARTwin/InLocCIIRC_dataset'

    queryDir = os.path.join(datasetDir, f'query-{queryMode}')
    outputDir = os.path.join(datasetDir, f'outputs-{experimentName}')
    cutoutDir = os.path.join(datasetDir, 'cutouts')

    if shortlistMode == 'PV':
        shortlistPath = os.path.join(outputDir, 'densePV_top10_shortlist.mat')
    elif shortlistMode == 'PE':
        shortlistPath = os.path.join(outputDir, 'densePE_top100_shortlist.mat')
    else:
        raise 'Unsupported shortlistMode!'

    denseInlierDir = os.path.join(outputDir, 'PnP_dense_inlier')
    synthesizedDir = os.path.join(outputDir, 'synthesized')
    evaluationDir = os.path.join(datasetDir, f'evaluation-{experimentName}')
    queryPipelineDir = os.path.join(evaluationDir, 'queryPipeline')

    queryName = str(queryId) + '.jpg'
    queryPath = os.path.join(queryDir, queryName)
    query = plt.imread(queryPath)
    queryWidth = query.shape[1]
    queryHeight = query.shape[0]

    if not os.path.isdir(queryPipelineDir):
        os.mkdir(queryPipelineDir)
    
    shortlistModeDir = os.path.join(queryPipelineDir, shortlistMode)
    if not os.path.isdir(shortlistModeDir):
        os.mkdir(shortlistModeDir)

    thisParentQueryDir = os.path.join(shortlistModeDir, queryName)
    if not os.path.isdir(thisParentQueryDir):
        os.mkdir(thisParentQueryDir)

    ImgList = sio.loadmat(shortlistPath, squeeze_me=True)['ImgList']
    ImgListRecord = next((x for x in ImgList if x['queryname'] == queryName), None)
    topNname = ImgListRecord['topNname']
    if topNname.ndim == 1:
        cutoutNames = [topNname[topIdx]]
    else:
        cutoutNames = topNname[:,topIdx]

    if shortlistMode == 'PV':
        dbnamesId = ImgListRecord['dbnamesId'][0]
    elif shortlistMode == 'PE':
        dbnamesId = 1+topIdx

    synthPath = os.path.join(synthesizedDir, queryName, f'{1}.synth.mat')
    synthData = sio.loadmat(synthPath, squeeze_me=True)
    inlierPath = os.path.join(denseInlierDir, queryName, f'{dbnamesId}.pnp_dense_inlier.mat')
    inlierData = sio.loadmat(inlierPath)
    segmentLength = len(cutoutNames) # TODO: this might break if sequentialPV was used
    for i in range(segmentLength):
        thisQueryName = str(queryId - segmentLength + i + 1) + '.jpg'
        print(f'Processing query {thisQueryName}, as part of the segment')
        if segmentLength == 1:
            synth = synthData['RGBpersps']
            errmap = synthData['errmaps']
        else:
            synth = synthData['RGBpersps'][i]
            errmap = synthData['errmaps'][i]
        inls = inlierData['allInls'][0,i]
        tentatives_2d = inlierData['allTentatives2D'][0,i]
        cutoutName = cutoutNames[i]
        if useTentativesInsteadOfInliers:
            inls = np.ones((inls.shape[1],)).astype(np.bool)
        else:
            inls = np.reshape(inls, (inls.shape[1],)).astype(np.bool)
        inls_2d = tentatives_2d[:,inls] - 1 # MATLAB is 1-based
        thisQueryPath = os.path.join(queryDir, thisQueryName)
        thisQuery = plt.imread(thisQueryPath)

        cutout = plt.imread(os.path.join(cutoutDir, cutoutName))
        cutoutWidth = cutout.shape[1]
        cutoutHeight = cutout.shape[0]

        thisQueryPipelineDir = os.path.join(thisParentQueryDir, thisQueryName)
        if not os.path.isdir(thisQueryPipelineDir):
            os.mkdir(thisQueryPipelineDir)

        fig = plt.figure()
        plt.imshow(thisQuery)
        plt.plot(inls_2d[0,:], inls_2d[1,:], '.', markersize=inlierMarkerSize, color=inlierColor)
        thisQueryNameNoExt = thisQueryName.split('.')[0]
        queryStepPath = os.path.join(thisQueryPipelineDir, 'query_' + thisQueryNameNoExt + extension)
        saveFigure(fig, queryStepPath, queryWidth, queryHeight)
        plt.close(fig)

        fig = plt.figure()
        plt.imshow(cutout)
        plt.plot(inls_2d[2,:], inls_2d[3,:], '.', markersize=inlierMarkerSize, color=inlierColor)
        cutoutStepPath = os.path.join(thisQueryPipelineDir, 'chosen_' + buildCutoutName(cutoutName, extension))
        saveFigure(fig, cutoutStepPath, cutoutWidth, cutoutHeight)
        plt.close(fig)

        synthStepPath = os.path.join(thisQueryPipelineDir, 'synthesized' + '_PV' + extension)
        synth = np.asarray(synth)
        plt.imsave(synthStepPath, synth)

        errmapStepPath = os.path.join(thisQueryPipelineDir, 'errmap' + extension)
        errmap = np.asarray(errmap)
        plt.imsave(errmapStepPath, errmap, cmap='jet')

queryMode = 's10e'
experimentName = 's10e-v4.2'
shortlistModes = ['PE']
#queryIds = [1,127,200,250,100,300,165,55,330,223] # medium query sub-dataset
queryIds = [40]
useTentativesInsteadOfInliers = True # should be False for thesis visualization
topIdx = 6 # must be 0 for thesis visualization
for shortlistMode in shortlistModes:
    for queryId in queryIds:
        print(f'[{shortlistMode}] Processing query {queryId}.jpg segment')
        renderForQuery(queryId, shortlistMode, queryMode, experimentName, useTentativesInsteadOfInliers, topIdx)