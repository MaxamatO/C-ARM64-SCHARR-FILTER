//
//  Cscharr.c
//  ScharrFilter
//
//  Created by Maksymilian Pierchała on 13/10/2025.
//

#include <stdio.h>
#include "ScharrFilter-Bridging-Header.h"

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
struct CProcessedData processImage(uint8_t *pixels, int width, int height, int bytesPerRow) {
    for (int y = 0; y < height; y++) {
        uint8_t *row = pixels + y * bytesPerRow;

        for (int x = 0; x < width; x++) {
            int i = x * 4;
            row[i + 0] = 255 - row[i + 0];
            row[i + 1] = 255 - row[i + 1];
            row[i + 2] = 255 - row[i + 2];
        }
    }
    struct CProcessedData processedData = {
        .data = pixels,
        .height = height,
        .width = width,
        .bytesPerRow = bytesPerRow,
        .bitsPerComponent = 8
    };
    
    printf("C: processedData ptr=%p %dx%d\n", processedData.data, processedData.width, processedData.height);
    return processedData;
}
