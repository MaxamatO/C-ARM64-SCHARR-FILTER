
#include <stdint.h>
struct CProcessedData {
    uint8_t *data;
    int width;
    int height;
    int bitsPerComponent;
    int bytesPerRow;
};

void callHello(void);
struct CProcessedData processImage(uint8_t *pixels, int width, int height, int bytesPerRow);
void convertToGreyScale(uint8_t *p_originalPixels, uint8_t *destination,int width, int height, int bytesPerRow);
void calculateRows(uint8_t *p_greyScalePixels, int16_t *p_xScharrPixels, int width, int height, int bytesPerRow);
void calculateColumns(uint8_t *p_greyScalePixels, int16_t *p_yScharrPixels, int width, int height, int bytesPerRow);
void combinePixels(int16_t *p_xScharrPixels, int16_t *p_yScharrPixels, uint8_t *p_combinedPixels, int width, int height);
