#ifndef NFSMW_SCREEN_SIZE_H
#define NFSMW_SCREEN_SIZE_H

#include <stdlib.h>

/* Offscreen GLES size. R36S keeps 640x480 (Mali). TSP llvmpipe needs less. */
static inline int nfsmw_screen_width(void)
{
    static int value;
    const char *configured;
    int parsed;

    if (value != 0)
        return value;
    configured = getenv("NFSMW_WIDTH");
    parsed = configured != NULL ? atoi(configured) : 640;
    if (parsed < 160)
        parsed = 160;
    if (parsed > 1280)
        parsed = 1280;
    value = parsed;
    return value;
}

static inline int nfsmw_screen_height(void)
{
    static int value;
    const char *configured;
    int parsed;

    if (value != 0)
        return value;
    configured = getenv("NFSMW_HEIGHT");
    parsed = configured != NULL ? atoi(configured) : 480;
    if (parsed < 120)
        parsed = 120;
    if (parsed > 720)
        parsed = 720;
    value = parsed;
    return value;
}

#endif
