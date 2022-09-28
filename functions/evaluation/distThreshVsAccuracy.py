import os
import pandas as pd

def getAccuracy(distanceThreshold, angularThreshold, errorsDf, blacklistedQueryInd):
    nCorrect = 0
    nQueries = len(errorsDf)
    nWhitelistedQueries = nQueries
    for i in range(nQueries):
        translationError = errorsDf['translation'][i]
        orientationError = errorsDf['orientation'][i]
        queryId = errorsDf['id'][i]
        if queryId in blacklistedQueryInd:
            nWhitelistedQueries -= 1
            continue
        if translationError < distanceThreshold and orientationError < angularThreshold:
            nCorrect += 1
    accuracy = nCorrect / nWhitelistedQueries * 100
    return accuracy

experimentName = 's10e-v4.2' # TODO: adjust

# TODO: keep in sync with params in InLocCIIRC_utils !!!
s10e_blacklistedQueryInd = []
HL1_blacklistedQueryInd = list(range(103,109+1)) + [162] + list(range(179,188+1)) + list(range(191,193+1)) + list(range(286,288+1))
#HL2_blacklistedQueryInd = TODO
blacklistedQueryInd = s10e_blacklistedQueryInd # TODO: adjust

angularThreshold = 10 # in degrees
datasetDir = '/Volumes/GoogleDrive/Můj disk/ARTwin/InLocCIIRC_dataset'
evaluationDir = os.path.join(datasetDir, 'evaluation-' + experimentName)
errorsPath = os.path.join(evaluationDir, 'errors.csv')
outputPath = os.path.join(evaluationDir, 'distThreshVsAccuracy-' + experimentName + '.csv')
inLocDataPath = 'evaluation/InLocDistThreshVsAccuracy.csv'

errorsDf = pd.read_csv(errorsPath, sep=',')
inLocDf = pd.read_csv(inLocDataPath, sep=';', header=None)
outputFile = open(outputPath, 'w')

for i in range(len(inLocDf)):
    distanceThreshold = inLocDf[0][i]
    accuracy = getAccuracy(distanceThreshold, angularThreshold, errorsDf, blacklistedQueryInd) # InLocCIIRC accuracy
    outputFile.write('%f; %f\n' % (distanceThreshold, accuracy))

outputFile.close()