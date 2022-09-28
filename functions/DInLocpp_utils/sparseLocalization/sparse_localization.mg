{
    "header": {
        "pipelineVersion": "2.2",
        "releaseVersion": "2021.1.0",
        "fileVersion": "1.1",
        "nodesVersions": {
            "HlocQueryComposer": "0.1",
            "HlocLocalizer": "0.1"
        }
    },
    "graph": {
        "HlocLocalizer_1": {
            "nodeType": "HlocLocalizer",
            "position": [
                1630,
                -118
            ],
            "parallelization": {
                "blockSize": 0,
                "size": 1,
                "split": 1
            },
            "uids": {
                "0": "ad81093ea59837b1fd4fd70edb95deb943f98772"
            },
            "internalFolder": "{cache}/{nodeType}/{uid0}/",
            "inputs": {
                "hlocMapDir": "{HlocQueryComposer_1.hlocMapDir}",
                "queryFile": "{HlocQueryComposer_1.output}",
                "localSfM": "",
                "imageDescriptor": "netvlad",
                "keypointDetector": "superpoint-n4096-r1024",
                "matcher": "superglue",
                "imagesRig": false,
                "copyDensePts": false,
                "verboseLevel": "info"
            },
            "outputs": {
                "output": "{cache}/{nodeType}/{uid0}/",
                "image_pairs": "{cache}/{nodeType}/{uid0}/image_pairs.txt",
                "localization": "{cache}/{nodeType}/{uid0}/query_localization_results.txt",
                "densePts": "{cache}/{nodeType}/{uid0}/model.obj"
            }
        },
        "HlocQueryComposer_1": {
            "nodeType": "HlocQueryComposer",
            "position": [
                1418,
                -72
            ],
            "parallelization": {
                "blockSize": 0,
                "size": 1,
                "split": 1
            },
            "uids": {
                "0": "8afb33c168f10d8fd8a3731c3e9eb1b5bb191f31"
            },
            "internalFolder": "{cache}/{nodeType}/{uid0}/",
            "inputs": {
                "imageDir": "True",
                "images": [],
                "hlocMapDir": "",
                "queryImageDir": "/local/datasets/Matterport2COLMAP/SPRING_Demo/BrocaQueryRealistic/images",
                "sameCamera": "True",
                "intrinsics": [
                    {
                        "cameraModel": "SIMPLE_PINHOLE",
                        "width": 1344,
                        "height": 756,
                        "params": "1034.7892 672 378"
                    }
                ],
                "verboseLevel": "info"
            },
            "outputs": {
                "output": "{cache}/{nodeType}/{uid0}/hloc_queries.txt"
            }
        }
    }
}