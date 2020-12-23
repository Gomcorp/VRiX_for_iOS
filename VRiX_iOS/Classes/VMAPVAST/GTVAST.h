//
//  GTVAST.h
//  GoxEntry
//
//  Created by Youngchang koo on 2016. 5. 10..
//  Copyright © 2016년 Youngchang koo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "GTVMAP.h"

#define GXTrainkinEventTypeStart            @"start"
#define GXTrainkinEventTypeFirstQuartile    @"firstQuartile"
#define GXTrainkinEventTypeMidpoint         @"midpoint"
#define GXTrainkinEventTypeThirdQuartile    @"thirdQuartile"
#define GXTrainkinEventTypeComplete         @"complete"
#define GXTrainkinEventTypeSkip             @"skip"
#define GXTrainkinEventTypeProgress         @"progress"
#define GXTrainkinEventTypeClose            @"close"
/* 
    [## VAST대략적 구조 ##]
 
    <VAST>
        <AD>
            <InLine>
                <AdSystem>Vrixon</AdSystem>
                <AdTitle></AdTitle>
                <Impression>...</Impression>
                <Creatives>...</Creatives>
                <Extensions></Extensions>
            </InLine>
        </AD>
        <AD>
            <Wrapper></Wrapper>
        </AD>
        .
        .
    </VAST>
 */

/// VAST
typedef void(^GXVASTComplationHandler)(BOOL success, id userInfo);
@class GTAd;
@interface GTVAST : GTNodeObject

@property (nonatomic, strong) NSString *version;
@property (nonatomic, strong) NSMutableArray<GTAd *> *adList;
@property (nonatomic) NSInteger currentIndex;
@property (nonatomic, copy) GXVASTComplationHandler completion;

- (id)initWithVASTString:(NSString*)vastString;
- (id)initWithURL:(NSURL*)url;
- (id)initWithElement:(NSDictionary *)element;


- (void) excuteVastTarget:(UIView *)view
   advertisementCompleted:(void (^)(BOOL result, NSString *networkType))adCompleted
               completion:(void (^)(BOOL, id))completion;
- (void) cancelExcuteVast;

@end

@class GTCreative;
@class GTExtension;
/// AD의 자식노드는 InLine or Wrapper
@interface GTAd : GTNodeObject

/// attribute sequence
@property (nonatomic)         NSInteger sequence;

/// 첫번째 자식노드가 <Wrapper>일때 사용
@property (nonatomic, strong) NSURL         *vastAdTagURI;
/// 첫번째 자식노드가 <InLine>일때 사용
@property (nonatomic, strong) NSMutableArray<GTCreative *>  *creatives;
/// extentions ßeta
@property (nonatomic, strong) NSMutableArray<GTExtension *> *extensions;

/// element system name
@property (nonatomic, strong) NSString      *systemName;
/// element AD title
@property (nonatomic, strong) NSString      *adTitle;

/// 광고가 처음 나올때 tracking용으로 호출할 정보
@property (nonatomic, strong) NSMutableArray<NSURL *>  *impressionURLs;

/// 광고에 error가 있을때 호출할 정보
@property (nonatomic, strong) NSURL*                    errorURL;

@property (nonatomic) BOOL didDisplayed;

- (void) excuteAdTarget:(UIView *)view completion:(void (^)(BOOL, id))completion;
@end

/* 
    [## Creative Types ##]
 
    <Creative>
        <CretiveExtensions>
            <CretiveExtension type="vrix">
                <label font="sans-serif" size="10" style="bold" fontcolor="#FFFFFF" shadowcolor="#000000" shadowradius="1" shadowopacity="1" shadowpathX="1" shadowpathY="1" action="counterdown" format="mm:ss" xPosition="10" yPosition="667">60</label>
            </CretiveExtension>
        </CretiveExtensions>
 
        <Linear>
            <Duration></Duration>
            <TrackingEvents>...</TrackingEvents>
            <VideoClicks>...</VideoClicks>
            <MediaFiles>...</MediaFiles>
            <Icons>...</Icons>
        </Linear>
    </Creative>
 
    <Creative>
        <Compainon></Compainon>
    </Creative>
 
    <Creative>
        <NonlinerAds></NonlinerAds>
    </Creative>
 
    <Creative>
        <Nonliner></Nonliner>
    </Creative>
 */

@class GTVRiXExtensionObject;
@class GTPositionFixedFlag;
@interface GTExtension : GTNodeObject

@property (nonatomic, strong) NSString*                     type;
@property (nonatomic, strong) NSString*                     networkType;
@property (nonatomic, strong) GTVRiXExtensionObject*        extensionObject;
@property (nonatomic, strong) GTPositionFixedFlag*          postionFixedFlag;
@end

@interface GTVRiXExtensionObject : GTNodeObject
@end
@interface GTLabel : GTVRiXExtensionObject

@property (nonatomic, strong) NSString          *fontname;
@property (nonatomic, assign) CGFloat           size;
@property (nonatomic, strong) NSString          *style;
@property (nonatomic, strong) UIColor           *fontcolor;
@property (nonatomic, strong) UIColor           *shadowcolor;
@property (nonatomic, assign) CGFloat           shadowradius;
@property (nonatomic, assign) CGFloat           shadowopacity;
@property (nonatomic, assign) CGFloat           shadowpathX;
@property (nonatomic, assign) CGFloat           shadowpathY;
@property (nonatomic, strong) NSString          *action;
@property (nonatomic, strong) NSString          *format;
@property (nonatomic, strong) NSString          *xPosition;
@property (nonatomic, strong) NSString          *yPosition;
@property (nonatomic, assign) CGFloat           leftMargin;
@property (nonatomic, assign) CGFloat           rightMargin;
@property (nonatomic, assign) CGFloat           topMargin;
@property (nonatomic, assign) CGFloat           bottomMargin;
@property (nonatomic, strong) NSString          *value;
@end

@interface GTPositionFixedFlag : GTNodeObject
@property (nonatomic, assign) CGFloat           leftMargin;
@property (nonatomic, assign) CGFloat           rightMargin;
@property (nonatomic, assign) CGFloat           topMargin;
@property (nonatomic, assign) CGFloat           bottomMargin;
@property (nonatomic, assign) BOOL              useFlag;
@end

@class GTExtension;
@class GTCreativeElement;
@class GTTracking;
@interface GTCreative : GTNodeObject

@property (nonatomic, strong) NSString      *sequence;
@property (nonatomic, strong) NSString      *AdID;
@property (nonatomic, strong) GTCreativeElement *element;
/// extentionsß
@property (nonatomic, strong) NSMutableArray<GTExtension *> *extensions;
@property (nonatomic) BOOL didDisplayed;
@end

@interface GTCreativeElement : NSObject

@property (nonatomic, strong, readonly) NSString*                   elementName;
@property (nonatomic, strong)   NSDictionary*                       xmlDocument;
/// extentionsß
@property (nonatomic, strong) NSMutableArray<GTExtension *> *extensions;

- (id)initWithElement:(NSDictionary *)element withElementName:(NSString *)name;
- (BOOL) setPropertiesFromDocument;

- (void) playCreativeElement:(UIView *)targetView completion:(void (^)(BOOL, id))completion;

- (NSMutableArray<GTTracking *> *) findTracksEventName:(NSString *)eventName;
- (GTTracking *) findTrackEventName:(NSString *)eventName;
- (void) sendTracking:(GTTracking *)tracking;
- (void) sendTrackings:(NSMutableArray <GTTracking *>*)trackings;

@end

@class GTTracking;
@class GTMediaFile;
@class GTIcon;
@interface GTLinear : GTCreativeElement

@property (nonatomic) GTAd* ad;
@property (nonatomic, assign) NSTimeInterval                skipoffset;
@property (nonatomic, assign) NSTimeInterval                duration;

@property (nonatomic, strong) NSString                      *clickThrough;
@property (nonatomic, strong) NSString                      *clickTracking;
@property (nonatomic, strong) NSString                      *clickType;
@property (nonatomic, strong) NSMutableArray<GTTracking *>  *trackingEvents;
@property (nonatomic, strong) NSMutableArray<GTMediaFile *> *mediaFiles;
@property (nonatomic, strong) NSMutableArray<GTIcon *>      *Icons;


@end

@interface GTCompainon : GTCreativeElement
@end

@class GTNonLinear;
@interface GTNonLinearAds : GTCreativeElement
@property (nonatomic) GTAd* ad;
@property (nonatomic, strong) NSMutableArray<GTTracking *>  *trackingEvents;
@property (nonatomic, strong) NSMutableArray<GTNonLinear *> *nonlinears;

@end

@interface GTNonLinear : GTCreativeElement
@property (nonatomic, strong) NSString                      *idValue;
@property (nonatomic, assign) CGFloat                       width;
@property (nonatomic, assign) CGFloat                       height;
@property (nonatomic, assign) CGFloat                       expandedWidth;
@property (nonatomic, assign) CGFloat                       expandedHeight;
@property (nonatomic, assign) BOOL                          scalable;
@property (nonatomic, assign) NSTimeInterval                minSuggestedDuration;
@property (nonatomic, strong) NSString                      *xPosition;
@property (nonatomic, strong) NSString                      *yPosition;

@property (nonatomic, strong) NSString                      *htmlResource;
@property (nonatomic, strong) NSString                      *staticResource;
@property (nonatomic, strong) UIImage                       *staticResourceAsset;

@property (nonatomic, strong) NSString                      *clickThrough;
@property (nonatomic, strong) NSString                      *clickTracking;
@end

@interface GTTracking : GTNodeObject

@property (nonatomic, strong) NSString      *event;
@property (nonatomic, strong) NSString      *referURL;
@property (nonatomic) NSTimeInterval        offset;
@end


@interface GTMediaFile : GTNodeObject

@property (nonatomic, strong) NSString      *idValue;
@property (nonatomic, strong) NSString      *delivery;
@property (nonatomic, strong) NSString      *type;
@property (nonatomic, strong) NSString      *bitrate;
@property (nonatomic, assign) CGFloat       width;
@property (nonatomic, assign) CGFloat       height;
@property (nonatomic, strong) NSString      *referURL;
@end

@interface GTIcon : GTNodeObject

@property (nonatomic, strong) NSString          *program;
@property (nonatomic, assign) CGFloat           *xRatio;
@property (nonatomic, assign) CGFloat           *yRatio;
@property (nonatomic, strong) NSString          *xPosition;
@property (nonatomic, strong) NSString          *yPosition;
@property (nonatomic, assign) CGFloat           width;
@property (nonatomic, assign) CGFloat           height;

@property (nonatomic, assign) NSTimeInterval    offset;
@property (nonatomic, assign) NSTimeInterval    duration;

@property (nonatomic, strong) NSString          *htmlResource;
@property (nonatomic, strong) NSString          *staticResource;
@property (nonatomic, strong) UIImage           *staticResourceAsset;

@property (nonatomic, strong) NSString          *iconClickThrough;
@property (nonatomic, strong) NSString          *iconClickTracking;
@end


