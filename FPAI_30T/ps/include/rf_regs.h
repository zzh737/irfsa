#ifndef FPAI_30T_RF_REGS_H
#define FPAI_30T_RF_REGS_H
#include <stdint.h>
/* This project's new Custom Op map; NOT the old official adder map. */
#define RF_REG_BASE        UINT32_C(0x400c0000)
#define RF_INPUT_ADDR      0x00u
#define RF_OUTPUT_ADDR     0x04u
#define RF_INPUT_BYTES     0x08u
#define RF_OUTPUT_BYTES    0x0cu
#define RF_CONTROL         0x10u
#define RF_STATUS          0x14u
#define RF_FRAME_SEQ       0x18u
#define RF_ERROR_CODE      0x1cu
#define RF_VERSION         0x20u
#define RF_MODE            0x24u
#define RF_CAPABILITIES    0x28u
#define RF_WINDOW          0x2cu
#define RF_ACCEPTED_COUNT  0x30u
#define RF_COMPLETED_COUNT 0x34u
#define RF_ERROR_COUNT     0x38u
#define RF_DISPLAY_COUNT   0x3cu
#define RF_START           1u
#define RF_CLEAR_IDLE      2u
#define RF_BUSY            1u
#define RF_DONE            2u
#define RF_ERROR           4u
#define RF_VERSION_VALUE   UINT32_C(0x20261022)
#define RF_FRAME_BYTES     4096u
#define RF_MODE_FFT        0u /* 1024 uint32 natural-order power bins */
#define RF_MODE_COPY       1u
#define RF_WINDOW_RECTANGULAR 0u
#define RF_WINDOW_HANN        1u /* reset default */
#define RF_CAP_COPY        1u
#define RF_CAP_FFT_POWER   2u
#define RF_CAP_DISPLAY     4u /* rf_product_core only; bare Custom Op has 0x3 */
#define RF_ERROR_UNSUPPORTED 1u
#define RF_ERROR_PARAMETERS  2u
#define RF_ERROR_OVERLAP     3u
#define RF_DISPLAY_COMMIT   0x100u
#define RF_DISPLAY_STATUS   0x104u /* bit0 BUSY until frame-boundary swap ack */
#define RF_DISPLAY_CAPTURE  0x108u
#define RF_DISPLAY_SEQ      0x10cu
#define RF_DISPLAY_CLASS    0x110u /* V6: 0..17 labels; 255 UNKNOWN */
#define RF_DISPLAY_CONF     0x114u /* 0..1000 */
#define RF_DISPLAY_FLAGS    0x118u /* bit0 delivery gap; bit1 rejection */
#define RF_DISPLAY_PEAK     0x11cu
#define RF_DISPLAY_HEIGHTS  0x1000u /* 1024 words, 0..400, fftshift order */
#endif
