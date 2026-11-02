#ifndef RF_PROTOCOL_V1_H
#define RF_PROTOCOL_V1_H

/* Wire offsets, never native packed structs. All headers/control fields are BE;
 * IQ int16 components are LE. CRC and UDP validation remain caller duties. */
#include <stdint.h>

#define RF_VERSION 1u
#define RF_DATA_PORT 40000u
#define RF_CONTROL_PORT 40001u
#define RFIQ_HEADER_BYTES 64u
#define RFIQ_PAYLOAD_BYTES 1024u
#define RFIQ_PACKET_BYTES 1088u
#define RFIQ_WINDOW_POINTS 1024u
#define RFIQ_FRAGMENT_POINTS 256u
#define RFIQ_FRAGMENT_COUNT 4u
#define RFIQ_WINDOW_BYTES 4096u
#define RFCT_HEADER_BYTES 32u
#define RFCT_SNAPSHOT_BYTES 96u
#define RFCT_RX_INFO_BYTES 32u
#define RFCT_SET_RF_BYTES 24u
#define RFCT_SET_STREAM_BYTES 28u
#define RFCT_START_BYTES 4u
#define RFCT_MAX_PAYLOAD_BYTES 1440u
#define RF_REASSEMBLY_TIMEOUT_MS 100u
#define RF_REASSEMBLY_DEPTH 256u
#define RFCT_RETRY_MS 500u
#define RFCT_MAX_RETRIES 12u
#define RFCT_START_TIMEOUT_MS 5000u
#define RFCT_STOP_TIMEOUT_MS 1000u

enum rf_iq_offset {
    RFIQ_MAGIC=0, RFIQ_VERSION=4, RFIQ_TYPE=5, RFIQ_HEADER_LEN=6,
    RFIQ_STREAM_ID=8, RFIQ_CAPTURE_ID=12, RFIQ_WINDOW_SEQ=16,
    RFIQ_FRAGMENT_INDEX=20, RFIQ_FRAGMENTS=22, RFIQ_SAMPLE_INDEX=24,
    RFIQ_LO_HZ=32, RFIQ_FS_EFF_HZ=40, RFIQ_BASEBAND_CENTER_HZ=44,
    RFIQ_ITEM_COUNT=48, RFIQ_FLAGS=50, RFIQ_RX_GAIN_MDB=52,
    RFIQ_PAYLOAD_CRC32=56, RFIQ_RESERVED=60
};
enum rf_control_offset {
    RFCT_MAGIC=0, RFCT_VERSION=4, RFCT_KIND=5, RFCT_HEADER_LEN=6,
    RFCT_REQUEST_ID=8, RFCT_CONFIG_ID=12, RFCT_OPCODE=16,
    RFCT_STATUS=18, RFCT_PAYLOAD_LEN=20, RFCT_BOOT_ID=24, RFCT_CRC32=28
};
enum rf_opcode {
    RF_SET_RF=1, RF_SET_STREAM=2, RF_START=3, RF_STOP=4, RF_GET_STATUS=5,
    RF_GET_RX_INFO=6
};
enum rf_rx_info_offset {
    RF_INFO_SCHEMA=0, RF_INFO_REQUEST_HIGH=4, RF_INFO_CONFIG_HIGH=8,
    RF_INFO_CAPTURE_HIGH=12, RF_INFO_ADC_RATE=16, RF_INFO_BANDWIDTH=20,
    RF_INFO_GAIN_MDB=24, RF_INFO_CAPABILITIES=28
};
enum rf_status {
    RF_OK=0, RF_BAD_COMMAND=1, RF_BAD_LENGTH=2, RF_BAD_PARAMETER=3,
    RF_BAD_STATE=4, RF_UNSUPPORTED=5, RF_BUSY=6, RF_HW_TIMEOUT=7,
    RF_HW_FAILURE=8, RF_BOOT_MISMATCH=9, RF_REQUEST_CONFLICT=10,
    RF_STALE_REQUEST=11, RF_CONFIG_CONFLICT=12, RF_CAPTURE_REUSED=13
};
enum rf_state { RF_IDLE=0, RF_STARTING=1, RF_RUNNING=2, RF_STOPPING=3, RF_ERROR=4 };
enum rf_kind { RF_REQUEST=0, RF_RESPONSE=1 };
enum rf_source { RF_SOURCE_AD9361=0, RF_SOURCE_REPLAY=1 };
enum rf_mode { RF_CONTINUOUS=0, RF_EVENT=1 };
enum rf_data_flags {
    RF_DISCONTINUITY=1, RF_FIRST_WINDOW=2, RF_OVERLOAD=4, RF_EVENT_WINDOW=8
};
enum rf_snapshot_flags { RF_READY=1, RF_LINK_UP=2, RF_CONFIG_VALID=4 };
enum rf_set_rf_offset {
    RF_CFG_LO_HZ=0, RF_CFG_ADC_RATE=8, RF_CFG_BANDWIDTH=12,
    RF_CFG_GAIN_MDB=16, RF_CFG_GAIN_MODE=20, RF_CFG_RX_CHANNEL=21, RF_CFG_RESERVED=22
};
enum rf_set_stream_offset {
    RF_STREAM_ID=0, RF_STREAM_FS_EFF=4, RF_STREAM_DECIMATION=8,
    RF_STREAM_BASEBAND_CENTER=12, RF_STREAM_HOP=16, RF_STREAM_WINDOW=20,
    RF_STREAM_MODE=22, RF_STREAM_SOURCE=23, RF_STREAM_MAX_WPS=24
};
enum rf_snapshot_offset {
    RF_SNAP_STATE=0, RF_SNAP_SOURCE=1, RF_SNAP_MODE=2, RF_SNAP_CHANNEL=3,
    RF_SNAP_CONFIG=4, RF_SNAP_CAPTURE=8, RF_SNAP_STREAM=12, RF_SNAP_LO=16,
    RF_SNAP_ADC_RATE=24, RF_SNAP_FS_EFF=28, RF_SNAP_BANDWIDTH=32,
    RF_SNAP_BASEBAND=36, RF_SNAP_GAIN=40, RF_SNAP_DECIMATION=44,
    RF_SNAP_HOP=48, RF_SNAP_WINDOW=52, RF_SNAP_FLAGS=54,
    RF_SNAP_LAST_ERROR=56, RF_SNAP_FIFO_LEVEL=60, RF_SNAP_SAMPLE_COUNT=64,
    RF_SNAP_TX_DATAGRAMS=72, RF_SNAP_DROP_WINDOWS=80, RF_SNAP_OVERFLOWS=88
};

static inline uint16_t rf_get_be16(const uint8_t *p) {
    return (uint16_t)(((uint16_t)p[0] << 8) | p[1]);
}
static inline uint32_t rf_get_be32(const uint8_t *p) {
    return ((uint32_t)p[0] << 24) | ((uint32_t)p[1] << 16) |
           ((uint32_t)p[2] << 8) | p[3];
}
static inline uint64_t rf_get_be64(const uint8_t *p) {
    return ((uint64_t)rf_get_be32(p) << 32) | rf_get_be32(p + 4);
}
static inline void rf_put_be16(uint8_t *p, uint16_t v) {
    p[0]=(uint8_t)(v >> 8); p[1]=(uint8_t)v;
}
static inline void rf_put_be32(uint8_t *p, uint32_t v) {
    p[0]=(uint8_t)(v >> 24); p[1]=(uint8_t)(v >> 16);
    p[2]=(uint8_t)(v >> 8); p[3]=(uint8_t)v;
}
static inline void rf_put_be64(uint8_t *p, uint64_t v) {
    rf_put_be32(p, (uint32_t)(v >> 32)); rf_put_be32(p+4, (uint32_t)v);
}
static inline int32_t rf_get_i32be(const uint8_t *p) {
    uint32_t v=rf_get_be32(p);
    return (v & UINT32_C(0x80000000)) ? (-1 - (int32_t)(~v)) : (int32_t)v;
}
static inline int16_t rf_get_i16le(const uint8_t *p) {
    uint16_t v=(uint16_t)(((uint16_t)p[1] << 8) | p[0]);
    return (int16_t)((v & 0x8000u) ? ((int32_t)v - 65536) : (int32_t)v);
}

#endif
