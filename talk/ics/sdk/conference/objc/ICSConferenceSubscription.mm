//
//  Copyright (c) 2016 Intel Corporation. All rights reserved.
//

#include "talk/ics/sdk/conference/objc/ConferenceSubscriptionObserverObjcImpl.h"
#include "webrtc/rtc_base/checks.h"

#import "talk/ics/sdk/base/objc/ICSMediaFormat+Private.h"
#import "talk/ics/sdk/conference/objc/ICSConferenceSubscription+Private.h"
#import "webrtc/sdk/objc/Framework/Classes/PeerConnection/RTCLegacyStatsReport+Private.h"
#import "webrtc/sdk/objc/Framework/Classes/Common/NSString+StdString.h"
#import <ICS/ICSErrors.h>
#import <ICS/ICSConferenceErrors.h>

@implementation ICSConferenceSubscription {
  std::shared_ptr<ics::conference::ConferenceSubscription> _nativeSubscription;
  std::unique_ptr<
      ics::conference::ConferenceSubscriptionObserverObjcImpl,
      std::function<void(
          ics::conference::ConferenceSubscriptionObserverObjcImpl*)>>
      _observer;
}

- (instancetype)initWithNativeSubscription:
    (std::shared_ptr<ics::conference::ConferenceSubscription>)
        nativeSubscription {
  self = [super init];
  _nativeSubscription = nativeSubscription;
  return self;
}

- (void)stop {
  _nativeSubscription->Stop();
}

- (void)statsWithOnSuccess:(void (^)(NSArray<RTCLegacyStatsReport*>*))onSuccess
                 onFailure:(nullable void (^)(NSError*))onFailure {
  RTC_CHECK(onSuccess);
  _nativeSubscription->GetNativeStats(
      [onSuccess](const std::vector<const webrtc::StatsReport*>& reports) {
        NSMutableArray* stats =
            [NSMutableArray arrayWithCapacity:reports.size()];
        for (const auto* report : reports) {
          RTCLegacyStatsReport* statsReport =
              [[RTCLegacyStatsReport alloc] initWithNativeReport:*report];
          [stats addObject:statsReport];
        }
        onSuccess(stats);
      },
      [onFailure](std::unique_ptr<ics::base::Exception> e) {
        if (onFailure == nil)
          return;
        NSError* err = [[NSError alloc]
            initWithDomain:ICSErrorDomain
                      code:ICSConferenceErrorUnknown
                  userInfo:[[NSDictionary alloc]
                               initWithObjectsAndKeys:
                                   [NSString stringForStdString:e->Message()],
                                   NSLocalizedDescriptionKey, nil]];
        onFailure(err);
      });
}

- (void)mute:(ICSTrackKind)trackKind
    onSuccess:(nullable void (^)())onSuccess
    onFailure:(nullable void (^)(NSError*))onFailure {
  _nativeSubscription->Mute(
      [ICSTrackKindConverter cppTrackKindForObjcTrackKind:trackKind],
      [onSuccess]() {
        if (onSuccess)
          onSuccess();
      },
      [onFailure](std::unique_ptr<ics::base::Exception> e) {
        if (onFailure == nil)
          return;
        NSError* err = [[NSError alloc]
            initWithDomain:ICSErrorDomain
                      code:ICSConferenceErrorUnknown
                  userInfo:[[NSDictionary alloc]
                               initWithObjectsAndKeys:
                                   [NSString stringForStdString:e->Message()],
                                   NSLocalizedDescriptionKey, nil]];
        onFailure(err);
      });
}

- (void)unmute:(ICSTrackKind)trackKind
     onSuccess:(nullable void (^)())onSuccess
     onFailure:(nullable void (^)(NSError*))onFailure {
  _nativeSubscription->Unmute(
      [ICSTrackKindConverter cppTrackKindForObjcTrackKind:trackKind],
      [onSuccess]() {
        if (onSuccess)
          onSuccess();
      },
      [onFailure](std::unique_ptr<ics::base::Exception> e) {
        if (onFailure == nil)
          return;
        NSError* err = [[NSError alloc]
            initWithDomain:ICSErrorDomain
                      code:ICSConferenceErrorUnknown
                  userInfo:[[NSDictionary alloc]
                               initWithObjectsAndKeys:
                                   [NSString stringForStdString:e->Message()],
                                   NSLocalizedDescriptionKey, nil]];
        onFailure(err);
      });
}

- (void)applyOptions:(ICSConferenceSubscriptionUpdateOptions*)options
           onSuccess:(nullable void (^)())onSuccess
           onFailure:(nullable void (^)(NSError*))onFailure {
  _nativeSubscription->ApplyOptions(
      *[options nativeSubscriptionUpdateOptions].get(),
      [onSuccess]() {
        if (onSuccess)
          onSuccess();
      },
      [onFailure](std::unique_ptr<ics::base::Exception> e) {
        if (onFailure == nil)
          return;
        NSError* err = [[NSError alloc]
            initWithDomain:ICSErrorDomain
                      code:ICSConferenceErrorUnknown
                  userInfo:[[NSDictionary alloc]
                               initWithObjectsAndKeys:
                                   [NSString stringForStdString:e->Message()],
                                   NSLocalizedDescriptionKey, nil]];
        onFailure(err);
      });
}

-(void)setDelegate:(id<ICSConferenceSubscriptionDelegate>)delegate{
  _observer = std::unique_ptr<
      ics::conference::ConferenceSubscriptionObserverObjcImpl,
      std::function<void(ics::conference::ConferenceSubscriptionObserverObjcImpl*)>>(
      new ics::conference::ConferenceSubscriptionObserverObjcImpl(self, delegate),
      [&self](ics::conference::ConferenceSubscriptionObserverObjcImpl* observer) {
        self->_nativeSubscription->RemoveObserver(*observer);
      });
  _nativeSubscription->AddObserver(*_observer.get());
  _delegate = delegate;
}

@end

@implementation ICSConferenceAudioSubscriptionConstraints

- (std::shared_ptr<ics::conference::AudioSubscriptionConstraints>)
    nativeAudioSubscriptionConstraints {
  std::shared_ptr<ics::conference::AudioSubscriptionConstraints> constrains =
      std::shared_ptr<ics::conference::AudioSubscriptionConstraints>(
          new ics::conference::AudioSubscriptionConstraints());
  constrains->codecs =
      std::vector<ics::base::AudioCodecParameters>([_codecs count]);
  for (ICSAudioCodecParameters* codec in _codecs) {
    ics::base::AudioCodecParameters parameters(
        *[codec nativeAudioCodecParameters].get());
    constrains->codecs.push_back(parameters);
  }
  return constrains;
}

@end

@implementation ICSConferenceVideoSubscriptionConstraints

- (std::shared_ptr<ics::conference::VideoSubscriptionConstraints>)
    nativeVideoSubscriptionConstraints {
  std::shared_ptr<ics::conference::VideoSubscriptionConstraints> constrains =
      std::shared_ptr<ics::conference::VideoSubscriptionConstraints>(
          new ics::conference::VideoSubscriptionConstraints());
  constrains->codecs =
      std::vector<ics::base::VideoCodecParameters>([_codecs count]);
  for (ICSVideoCodecParameters* codec in _codecs) {
    ics::base::VideoCodecParameters parameters(
        *[codec nativeVideoCodecParameters].get());
    constrains->codecs.push_back(parameters);
  }
  constrains->resolution =
      ics::base::Resolution(_resolution.width, _resolution.height);
  constrains->frameRate = _frameRate;
  constrains->bitrateMultiplier = _bitrateMultiplier;
  constrains->keyFrameInterval = _keyFrameInterval;
  return constrains;
}

@end

@implementation ICSConferenceSubscribeOptions 

- (instancetype)initWithAudio:(ICSConferenceAudioSubscriptionConstraints*)audio
                        video:
                            (ICSConferenceVideoSubscriptionConstraints*)video {
  if ((self = [super init])) {
    _audio = audio;
    _video = video;
  }
  return self;
}

- (std::shared_ptr<ics::conference::SubscribeOptions>)nativeSubscribeOptions {
  std::shared_ptr<ics::conference::SubscribeOptions> options(
      new ics::conference::SubscribeOptions);
  if (_audio) {
    ics::conference::AudioSubscriptionConstraints audio(
        *[_audio nativeAudioSubscriptionConstraints].get());
    options->audio = audio;
  }
  if (_video) {
    ics::conference::VideoSubscriptionConstraints video(
        *[_video nativeVideoSubscriptionConstraints].get());
    options->video = video;
  }
  return options;
}

@end


@implementation ICSConferenceVideoSubscriptionUpdateConstraints

- (std::shared_ptr<ics::conference::VideoSubscriptionUpdateConstraints>)
    nativeVideoSubscriptionUpdateConstraints {
  std::shared_ptr<ics::conference::VideoSubscriptionUpdateConstraints> constrains =
      std::shared_ptr<ics::conference::VideoSubscriptionUpdateConstraints>(
          new ics::conference::VideoSubscriptionUpdateConstraints());
  constrains->resolution =
      ics::base::Resolution(_resolution.width, _resolution.height);
  constrains->frameRate = _frameRate;
  constrains->bitrateMultiplier = _bitrateMultiplier;
  constrains->keyFrameInterval = _keyFrameInterval;
  return constrains;
}

@end

@implementation ICSConferenceSubscriptionUpdateOptions

- (std::shared_ptr<ics::conference::SubscriptionUpdateOptions>)
    nativeSubscriptionUpdateOptions {
  std::shared_ptr<ics::conference::SubscriptionUpdateOptions> options =
      std::shared_ptr<ics::conference::SubscriptionUpdateOptions>(
          new ics::conference::SubscriptionUpdateOptions());
  if (_video) {
    ics::conference::VideoSubscriptionUpdateConstraints video(
        *[_video nativeVideoSubscriptionUpdateConstraints].get());
    options->video = video;
  }
  return options;
}

@end