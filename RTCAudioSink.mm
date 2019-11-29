#import "RTCAudioSink.h"
#include "api/media_stream_interface.h"

namespace webrtc {

void RTCAudioSinkCallback (void *object, const void *audio_data, int bits_per_sample, int sample_rate, size_t number_of_channels, size_t number_of_frames)
{
    AudioBufferList audioBufferList;
    AudioBuffer audioBuffer;
    audioBuffer.mData = (void*) audio_data;
    audioBuffer.mDataByteSize = bits_per_sample / 8 * number_of_channels * number_of_frames;
    audioBuffer.mNumberChannels = number_of_channels;
    audioBufferList.mNumberBuffers = 1;
    audioBufferList.mBuffers[0] = audioBuffer;
    AudioStreamBasicDescription audioDescription;
    audioDescription.mBytesPerFrame = bits_per_sample / 8 * number_of_channels;
    audioDescription.mBitsPerChannel = bits_per_sample;
    audioDescription.mBytesPerPacket = bits_per_sample / 8 * number_of_channels;
    audioDescription.mChannelsPerFrame = number_of_channels;
    audioDescription.mFormatID = kAudioFormatLinearPCM;
    audioDescription.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked;
    audioDescription.mFramesPerPacket = 1;
    audioDescription.mReserved = 0;
    audioDescription.mSampleRate = sample_rate;
    CMAudioFormatDescriptionRef formatDesc;
    CMAudioFormatDescriptionCreate(kCFAllocatorDefault, &audioDescription, 0, nil, 0, nil, nil, &formatDesc);
    CMSampleBufferRef buffer;
    CMSampleTimingInfo timing;
    timing.decodeTimeStamp = kCMTimeInvalid;
    timing.presentationTimeStamp = CMTimeMake(0, sample_rate);
    timing.duration = CMTimeMake(1, sample_rate);
    CMSampleBufferCreate(kCFAllocatorDefault, nil, false, nil, nil, formatDesc, number_of_frames * number_of_channels, 1, &timing, 0, nil, &buffer);
    CMSampleBufferSetDataBufferFromAudioBufferList(buffer, kCFAllocatorDefault, kCFAllocatorDefault, 0, &audioBufferList);
    @autoreleasepool {
        RTCAudioSink* sink = (__bridge RTCAudioSink*)(object);
        sink.format = formatDesc;
        [sink onData:buffer];
    }
}

class AudioSinkBridge : public webrtc::AudioTrackSinkInterface {
private:
    void* sink;

public:
    AudioSinkBridge(void* sink1) {
        sink = sink1;
    }
    void OnData(const void* audio_data,
                        int bits_per_sample,
                        int sample_rate,
                        size_t number_of_channels,
                        size_t number_of_frames)
    {
        RTCAudioSinkCallback(sink,
                             audio_data,
                             bits_per_sample,
                             sample_rate,
                             number_of_channels,
                             number_of_frames
        );
    };
};

}

@implementation RTCAudioSink {
    webrtc::AudioSinkBridge *_sinkBridge;
}

-(instancetype)init {
    if ([super init]) {
        _sinkBridge = new webrtc::AudioSinkBridge((void*)CFBridgingRetain(self));
    }
}

-(void) onData:(CMSampleBufferRef) buffer {
    NSLog(@"RTCAudioSink: onData");
};

@end
