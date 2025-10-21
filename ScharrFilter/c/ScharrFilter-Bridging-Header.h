
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
