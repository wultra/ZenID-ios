//
//  FaceLivenessWrapper.hpp
//  RecogLib-iOS
//
//  Created by Jiri Sacha on 19/05/2020.
//  Copyright © 2020 Marek Stana. All rights reserved.
//

#ifndef FaceLivenessWrapper_hpp
#define FaceLivenessWrapper_hpp

#include <stdio.h>
#include <string.h>
#include <CoreMedia/CoreMedia.h>
#include "CImageSignature.hpp"

#ifdef __cplusplus
extern "C" {
#endif

struct CFaceLivenessInfo {
    int state, orientation, language;
    struct CImageSignature signature;
};

struct CFaceLivenessAuxiliaryImage {
    const uint8_t *image;
    int imageSize;
};

typedef struct CFaceLivenessAuxiliaryImage CFaceLivenessAuxiliaryImage;

struct CFaceLivenessAuxiliaryInfo {
    const CFaceLivenessAuxiliaryImage *images;
    int imagesSize;
    const char *metadata;
    int metadataSize;
};

typedef struct CFaceLivenessInfo CFaceLivenessInfo;
typedef struct CFaceLivenessAuxiliaryInfo CFaceLivenessAuxiliaryInfo;

struct CFaceLivenessVerifierSettings {
    bool enableLegacyMode;
    int maxAuxiliaryImageSize;
};

typedef struct CFaceLivenessVerifierSettings CFaceLivenessVerifierSettings;

// Initialisation and loading models
const void * getFaceLivenessVerifier(const char* resourcesPath, CFaceLivenessVerifierSettings *settings);

// Verifying faces
bool verifyFaceLiveness(const void *object, CMSampleBufferRef _mat, CFaceLivenessInfo *faceDetector);
bool verifyFaceLivenessImage(const void *object, CVPixelBufferRef _cvBuffer, CFaceLivenessInfo *faceDetector);

// Auxiliary Images Info
CFaceLivenessAuxiliaryInfo getAuxiliaryInfo(const void *object);

// Reset
void faceLivenessVerifierReset(const void *object);

// Visualisation
char* getFaceLivenessRenderCommands(const void *object, int canvasWidth, int canvasHeight, CFaceLivenessInfo *faceDetector);
void setFaceLivenessDebugInfo(const void *object, bool show);

#ifdef __cplusplus
}
#endif

#endif /* FaceLivenessWrapper_hpp */
