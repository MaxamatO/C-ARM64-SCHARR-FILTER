
#include <stdint.h>

typedef struct {
    void* data;
    int32_t height;
    int32_t width;
    int32_t bytesPerRow;
    int32_t bitsPerComponent;
} CProcessedData;

void callHello(void);

__attribute__((visibility("default")))
void processImage(uint8_t *p_pixels, int width, int height, int bytesPerRow, void *p_dataOut);
void convertToGreyScale(uint8_t *p_originalPixels, uint8_t *destination,int width, int height, int bytesPerRow);
void calculateRows(uint8_t *p_greyScalePixels, int16_t *p_xScharrPixels, int width, int height, int bytesPerRow);
void calculateColumns(uint8_t *p_greyScalePixels, int16_t *p_yScharrPixels, int width, int height, int bytesPerRow);
void combinePixels(int16_t *p_xScharrPixels, int16_t *p_yScharrPixels, uint8_t *p_combinedPixels, int width, int height);
void expandToRGBA(uint8_t *p_combinedPixels, uint8_t *p_scharrFilteredPixels,int width, int height, int bytesPerRow);
