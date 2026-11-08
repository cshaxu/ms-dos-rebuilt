/* Test the PCM stream creation used by SoftPC; emit no audio or UI. */
#include "lib/audio/pcm/stream_interface.h"
#include <stdio.h>

int main(void)
{
    lib_audio_pcm_stream_options options = {0};
    lib_audio_pcm_stream *stream = NULL;
    options.sample_rate = 48000u;
    options.channel_count = 1u;
    lib_status status = lib_audio_pcm_stream_create(&options, &stream);
    printf("pcm-create=%d\n", (int)status);
    if (status != LIB_STATUS_OK) return 1;
    status = lib_audio_pcm_stream_destroy(&stream);
    printf("pcm-destroy=%d\n", (int)status);
    return status == LIB_STATUS_OK ? 0 : 2;
}
