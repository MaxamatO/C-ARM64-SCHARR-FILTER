//
//  Cscharr.c
//  ScharrFilter
//
//  Created by Maksymilian Pierchała on 13/10/2025.
//

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "ScharrFilter-Bridging-Header.h"
#include "math.h"

extern void hello(void);

void callHello(void){
    printf("Odpalam asm");
    hello();
}
/*
data: &pixelData,
width: width,
height: height,
bitsPerComponent: bitsPerComponent,
bytesPerRow: bytesPerRow,
space: colorSpace,
bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue */

int g_kernelDx[3][3] = {
    {3, 0, -3},
    {10, 0, -10},
    {3, 0, -3}};
int g_kernelDy[3][3] = {
    {3, 10, 3},
    {0, 0, 0},
    {-3, -10, -3}};

void calculateRows(uint8_t *p_greyScalePixels, int16_t *p_xScharrPixels, int width, int height, int bytesPerRow){
    for (int y = 1; y < height-1; y++) {
        for (int x = 1; x < width-1; x++){
            int indexUpperRow = (y-1)*width + x;
            int indexMiddleRow = y*width + x;
            int indexLowerRow = (y+1)*width + x;
            int scharrValue =
                g_kernelDx[0][0]*p_greyScalePixels[indexUpperRow-1] +
                g_kernelDx[1][0]*p_greyScalePixels[indexMiddleRow-1] +
                g_kernelDx[2][0]*p_greyScalePixels[indexLowerRow-1] +
                g_kernelDx[0][2]*p_greyScalePixels[indexUpperRow+1] +
                g_kernelDx[1][2]*p_greyScalePixels[indexMiddleRow+1] +
                g_kernelDx[2][2]*p_greyScalePixels[indexLowerRow+1];
            
            p_xScharrPixels[indexMiddleRow] = (int16_t)scharrValue;
        }
    }
}

void calculateColumns(uint8_t *p_greyScalePixels, int16_t *p_yScharrPixels, int width, int height, int bytesPerRow){
    for (int y = 1; y < height-1; y++) {
        for (int x = 1; x < width-1; x++){
            int indexUpperRow = (y-1)*width + x;
            int indexLowerRow = (y+1)*width + x;
            int scharrValue =
                g_kernelDy[0][0]*p_greyScalePixels[indexUpperRow-1] +
                g_kernelDy[0][1]*p_greyScalePixels[indexUpperRow] +
                g_kernelDy[0][2]*p_greyScalePixels[indexUpperRow+1] +
                g_kernelDy[2][0]*p_greyScalePixels[indexLowerRow-1] +
                g_kernelDy[2][1]*p_greyScalePixels[indexLowerRow] +
                g_kernelDy[2][2]*p_greyScalePixels[indexLowerRow+1];
            p_yScharrPixels[y*width + x] = (int16_t)scharrValue;
        }
    }
}

void combinePixels(int16_t *p_xScharrPixels, int16_t *p_yScharrPixels, uint8_t *p_combinedPixels, int width, int height){
    double combinedValue;
    int combinedFinalValue;
    uint8_t finalValue;
    for (int y=0; y < height; y++) {
        for (int x=0; x < width; x++) {
            int index = y*width + x;
            int16_t xCurrentPixel = p_xScharrPixels[index];
            int16_t yCurrentPixel = p_yScharrPixels[index];
            double x_sqrt = xCurrentPixel*xCurrentPixel;
            double y_sqrt = yCurrentPixel*yCurrentPixel;
            combinedValue = sqrt(x_sqrt + y_sqrt);
            combinedFinalValue = (int) combinedValue;
            if (combinedFinalValue >= 255){
                finalValue = 255;
            }else {
                finalValue = (uint8_t)combinedFinalValue;
            }
            p_combinedPixels[index] = finalValue;
        }
    }
}

void expandToRGBA(uint8_t *p_combinedPixels, uint8_t *p_scharrFilteredPixels, int width, int height, int bytesPerRow){
    for (int y=0; y < height; y++) {
        for (int x=0; x < width; x++) {
            int singleByteIndex = y*width + x;
            int fourByteIndex = y*bytesPerRow + x*4;
            p_scharrFilteredPixels[fourByteIndex] = p_combinedPixels[singleByteIndex];
            p_scharrFilteredPixels[fourByteIndex+1] = p_combinedPixels[singleByteIndex];
            p_scharrFilteredPixels[fourByteIndex+2] = p_combinedPixels[singleByteIndex];
            p_scharrFilteredPixels[fourByteIndex+3] = 255;
        }
    }
}



void convertToGreyScale(uint8_t *p_originalPixels, uint8_t *destination,int width, int height, int bytesPerRow){
    for (int y = 0; y < height; y++) {
        uint8_t *row = p_originalPixels + y * bytesPerRow;
        for (int x = 0; x < width; x++) {
            int fourByteIndex = x * 4;
            int singleByteIndex =y*width + x;
            int greyValue = (row[fourByteIndex + 0] * 77 + row[fourByteIndex + 1] * 150 + row[fourByteIndex + 2] * 29) >> 8;
            destination[singleByteIndex] = (uint8_t)greyValue;
        }
    }
}

struct CProcessedData processImage(uint8_t *p_pixels, int width, int height, int bytesPerRow) {
    
    int pixelsSize = height * width;
    uint8_t *p_greyScalePixels = (uint8_t*)malloc(pixelsSize);
    convertToGreyScale(p_pixels, p_greyScalePixels, width, height, bytesPerRow);
    int greyScaleBytesPerRow = width;
    int16_t *p_xScharrPixels = (int16_t*)malloc(greyScaleBytesPerRow*height*sizeof(int16_t));
    calculateRows(p_greyScalePixels,p_xScharrPixels, width, height, bytesPerRow);
    
    int16_t *p_yScharrPixels = (int16_t*)malloc(greyScaleBytesPerRow*height*sizeof(int16_t));
    calculateColumns(p_greyScalePixels,p_yScharrPixels, width, height, bytesPerRow);

    
    uint8_t *p_combinedPixels = (uint8_t*)malloc(greyScaleBytesPerRow*height);
    combinePixels(p_xScharrPixels, p_yScharrPixels, p_combinedPixels, width, height);
    
    uint8_t *p_scharrFilteredPixels = (uint8_t*)malloc(height*bytesPerRow);
    expandToRGBA(p_combinedPixels, p_scharrFilteredPixels, width, height, bytesPerRow);
    
    struct CProcessedData processedData = {
        .data = p_scharrFilteredPixels,
        .height = height,
        .width = width,
        .bytesPerRow = bytesPerRow,
        .bitsPerComponent = 8
    };
    free(p_greyScalePixels);
    free(p_xScharrPixels);
    free(p_yScharrPixels);
    free(p_combinedPixels);
    
    printf("C: processedData ptr=%p %dx%d\n", processedData.data, processedData.width, processedData.height);
    return processedData;
}
