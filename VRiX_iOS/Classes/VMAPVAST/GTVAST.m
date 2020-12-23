//
//  GTVAST.m
//  GoxEntry
//
//  Created by Youngchang koo on 2016. 5. 10..
//  Copyright © 2016년 Youngchang koo. All rights reserved.
//
#define CLOSE_BUTTON_WIDTH 25

#import "GTVAST.h"
#import "GTGoxImporterUtil.h"
#import "GTGoxConstants.h"

#import "XMLDictionary.h"
#import <objc/message.h>

#import "NSString+InvalidChar.h"
#import "XMLDictionary.h"

#import "GXAdManager.h"
#import "Statistics.h"
#import "UIColor+HexColors.h"

#import <WebKit/WebKit.h>

#define GTVMAPCurrentEncoding NSUTF8StringEncoding
static GTGoxImporterUtil const  _vastAttributesImporterUtil[];
static NSInteger const          _vastNumberOfAttributesImporterUtil;
static GTGoxImporterUtil const  _vastElementImportUtil[];
static NSInteger const          _vastNumberOfElementImportUtil;

static GTGoxImporterUtil const  _vastAdAttributesImporterUtil[];
static NSInteger const          _vastAdNumberOfAttributesImporterUtil;

static GTGoxImporterUtil const  _vastCreativeAttributesImporterUtil[];
static NSInteger const          _vastCreativeNumberOfAttributesImporterUtil;

static GTGoxImporterUtil const  _mediaAttributesImporterUtil[];
static NSInteger const          _mediaNumberOfAttributesImporterUtil;

static GTGoxImporterUtil const  _iconAttributesImporterUtil[];
static NSInteger const          _iconNumberOfAttributesImporterUtil;

static GTGoxImporterUtil const  _nonlinearAttributesImporterUtil[];
static NSInteger const          _nonlinearNumberOfAttributesImporterUtil;

@interface GTVAST()
@property (nonatomic) BOOL canceExcute;
@property (nonatomic, strong) NSMutableArray<NSDictionary *>* userInfos;
@end
@implementation GTVAST
- (id)initWithElement:(NSDictionary *)element
{
    _adList = [[NSMutableArray alloc] init];
    
    self = [super initWithElement:element];
    
    return self;
}

- (BOOL) setPropertiesFromDocument
{
    NSDictionary *vastElement = self.xmlDocument;
    
    if(![vastElement isKindOfClass:[NSDictionary class]])
    {
        return NO;
    }
    
    for (NSString *elementName in [vastElement childNodes])
    {
        if ([elementName caseInsensitiveCompare:GTVMAPElementVASTError] == NSOrderedSame)
        {
            NSString *errorAddress = [vastElement valueForKey:elementName];
            
            NSURL *url = [NSURL URLWithString:errorAddress];
            if (url != nil)
            {
                [[Statistics sharedStatistics] sendStatisticToURL:url];
            }
            
            return NO;
            
        }
    }
    
    for(NSInteger index = 0; index < _vastNumberOfAttributesImporterUtil; index++)
    {
        GTGoxImporterUtil importerUtil = _vastAttributesImporterUtil[index];
        NSString *name = [NSDictionary changeAttributename:importerUtil.attributeName];
        id attributeValue = [vastElement valueForKeyPath:name];
        if(attributeValue != nil)
        {
            importerUtil.setter(self, importerUtil.propertyName, importerUtil.converter(attributeValue));
        }
    }
    
    for(NSInteger index = 0; index < _vastNumberOfElementImportUtil; index++)
    {
        GTGoxImporterUtil importerUtil = _vastElementImportUtil[index];
        for(id element in [vastElement arrayValueForKeyPath:importerUtil.attributeName])
        {
            importerUtil.setter(self, importerUtil.propertyName, importerUtil.converter(element));
        }
    }
    
    return YES;
}

- (id)initWithVASTString:(NSString*)vastString
{
    self = [super init];
    
    if(self != nil)
    {
        vastString = [vastString validXMLString];
        
        if([vastString length] > 0)
        {
            NSDictionary* xmlDocument = [NSDictionary dictionaryWithXMLString:vastString];
            
            if (xmlDocument == nil && vastString != nil)
            {
                //[self setGoxErrorCode:goxString];
                
                return self;
            }
            
            
            return [self initWithElement:xmlDocument];
        }
        else
        {
            return nil;
        }
    }
    
    return self;
}

- (id)initWithURL:(NSURL*)url
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request addValue:identifierForAdvertising() forHTTPHeaderField:GTGoxHeaderKeyAAID];
    [request setValue:[Statistics userAgent] forHTTPHeaderField:@"User-Agent"];
    
    NSData* data = [self sendSynchronousRequest:request returningResponse:nil error:nil];
    
    NSInteger length = [data length];
    char* newCString = (char*)malloc(length + 1);
    memset(newCString, 0, length + 1);
    memcpy(newCString, [data bytes], length);
    
    NSString* vastString = [NSString stringWithCString:newCString
                                             encoding:GTVMAPCurrentEncoding];
    free(newCString);
    
    if(vastString != nil)
    {
        self = [self initWithVASTString:vastString];
        return self;
    }
    
    return nil;
}

- (NSData *)sendSynchronousRequest:(NSURLRequest *)request
                 returningResponse:(__autoreleasing NSURLResponse **)responsePtr
                             error:(__autoreleasing NSError **)errorPtr
{
    dispatch_semaphore_t    sem;
    __block NSData *        result;
    
    result = nil;
    
    sem = dispatch_semaphore_create(0);
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:request
                                     completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                         if (errorPtr != NULL) {
                                             *errorPtr = error;
                                         }
                                         if (responsePtr != NULL) {
                                             *responsePtr = response;
                                         }
                                         if (error == nil) {
                                             result = data;
                                         }
                                         dispatch_semaphore_signal(sem);
                                     }] resume];
    
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    
    return result;
}

- (void) excuteVastTarget:(UIView *)view
   advertisementCompleted:(void (^)(BOOL result, NSString *networkType))adCompleted
               completion:(void (^)(BOOL, id))completion
{
    self.completion = completion;
    _canceExcute = NO;
    self.userInfos = [[NSMutableArray alloc] init];
    NSInteger index = 0;
    
    if (self.adList == nil || [self.adList count] ==0)
    {
        self.completion(NO, self);
    }
    
    for (GTAd *ad in self.adList)
    {
        if (ad.didDisplayed == NO && _canceExcute == NO)
        {
            _currentIndex = index;
            
            [self excuteAdTargetView:view atIndex:_currentIndex advertisementCompleted:^(BOOL result, NSString *networkType) {
                //
                adCompleted(result, networkType);
            }];
            continue;
        }
        
        index++;
    }
}

- (void) cancelExcuteVast
{
    _canceExcute = YES;
    _currentIndex = 0;
    
    [[GXAdManager sharedManager] stopPlay];
}

- (void) excuteAdTargetView:(UIView *)view
                    atIndex:(NSInteger)index
     advertisementCompleted:(void (^)(BOOL result, NSString* networkType))adCompleted
{
    GTAd *ad = [self.adList objectAtIndex:index];
    
    [ad excuteAdTarget:view completion:^(BOOL success, id userInfo)
     {
        //
        NSString *networkType = @"";
        GTExtension *extension = ad.extensions.firstObject;
        if (extension != nil) {
            networkType = extension.networkType;
        }
        
        adCompleted(success, networkType);
        
        if ([self.adList count] > ++self->_currentIndex)
        {
            if (userInfo != nil && [userInfo isKindOfClass:[NSDictionary class]]) {
                [self.userInfos addObject:userInfo];
            }
            
            [self excuteAdTargetView:view atIndex:self->_currentIndex advertisementCompleted:adCompleted];
        }
        else
        {
            if (userInfo != nil && [userInfo isKindOfClass:[NSDictionary class]]) {
                [self.userInfos addObject:userInfo];
            }
            
            self.completion(YES, self.userInfos);
        }
     }];
}

@end

@implementation GTAd
- (id)initWithElement:(NSDictionary *)element
{
    _impressionURLs     = [[NSMutableArray alloc] init];
    _creatives          = [[NSMutableArray alloc] init];
    _extensions         = [[NSMutableArray alloc] init];
    
    self = [super initWithElement:element];
    
    return self;
}

- (BOOL) setPropertiesFromDocument
{
    NSDictionary *adElement = self.xmlDocument;
    
    if(![adElement isKindOfClass:[NSDictionary class]])
    {
        return NO;
    }
    
    for(NSInteger index = 0; index < _vastAdNumberOfAttributesImporterUtil; index++)
    {
        GTGoxImporterUtil importerUtil = _vastAdAttributesImporterUtil[index];
        NSString *name = [NSDictionary changeAttributename:importerUtil.attributeName];
        id attributeValue = [adElement valueForKeyPath:name];
        if(attributeValue != nil)
        {
            importerUtil.setter(self, importerUtil.propertyName, importerUtil.converter(attributeValue));
        }
    }
    
    NSDictionary *inlineElement = [adElement dictionaryValueForKeyPath:GTVASTElementInLine];
    NSDictionary *wrapperElement = [adElement dictionaryValueForKeyPath:GTVASTElementWrapper];
    
    if (inlineElement != nil)
    {
        // 0.set default datas
        NSDictionary *adSystem = [inlineElement dictionaryValueForKeyPath:GTVASTElementAdSystem];
        _systemName = [adSystem innerText];
        
        _adTitle = [inlineElement valueForKeyPath:GTVASTElementAdTitle];
        
        
        // 1. set impression urls
        for (NSDictionary *impression in [inlineElement arrayValueForKeyPath:GTVASTElementAdImpression])
        {
            NSString *data = impression.innerText;
            NSURL *url = [NSURL URLWithString:data];
            if (url != nil)
            {
                [_impressionURLs addObject:url];
            }
        }
        
        // 2. set creative
        NSArray *creatives = [inlineElement arrayValueForKeyPath:GTVASTElementAdCreatives];
        for (NSDictionary *creativeElement in creatives)
        {
            
            GTCreative *creative = [[GTCreative alloc] initWithElement:[creativeElement valueForKeyPath:GTVASTElementAdCreative]];
            [_creatives addObject:creative];
        }
        
        // 3. set extentions
        NSArray *extentions = [inlineElement arrayValueForKeyPath:GTVASTElementAdExtentions];
        if(extentions != nil)
        {
            for (NSDictionary *extentionElement in extentions)
            {
                
                GTExtension *extention = [[GTExtension alloc] initWithElement:[extentionElement valueForKeyPath:GTVASTElementAdExtention]];
                [_extensions addObject:extention];
            }
        }
        
    }
    
    if (wrapperElement != nil)
    {
        //
    }
    return YES;
}

- (void) excuteAdTarget:(UIView *)view completion:(void (^)(BOOL, id))completion
{
    // 2. handling create
    for (GTCreative *creative in self.creatives)
    {
        if (creative.didDisplayed == NO)
        {
            GTCreativeElement *element = creative.element;
            
            if (self.extensions != nil && [self.extensions count] > 0)
            {
                [element setExtensions:self.extensions];
            }
            
            if ([element.elementName isEqualToString:@"Linear"])
            {
                GTLinear *linear = (GTLinear *)element;
                [linear setAd:self];
                
                [creative setDidDisplayed:YES];
                [linear playCreativeElement:view completion:^(BOOL success, id userInfo)
                 {
                     //[
                     completion(YES, userInfo);
                 }];

                break;
            }
            else if ([element.elementName isEqualToString:@"Compainon"])
            {
                GTCompainon *compainon = (GTCompainon *)element;
                [compainon playCreativeElement:view completion:^(BOOL success, id userInfo)
                 {
                     //
                 }];
                
                break;
            }
            else if ([element.elementName isEqualToString:@"NonLinearAds"])
            {
                GTNonLinearAds *nonLinearAds = (GTNonLinearAds *)element;
                [nonLinearAds setAd:self];
                
                [nonLinearAds playCreativeElement:view completion:^(BOOL success, id userInfo)
                 {
                     //
                     completion(YES, userInfo);
                 }];
                
                break;
            }
            else if ([element.elementName isEqualToString:@"NonLinear"])
            {
                GTNonLinear *noneLinear = (GTNonLinear *)element;
                [noneLinear playCreativeElement:view completion:^(BOOL success, id userInfo)
                 {
                     //
                 }];
                
                break;
            }
        }
    }
}

@end

@implementation GTCreative

- (BOOL) setPropertiesFromDocument
{
    NSDictionary *creativeElement = self.xmlDocument;
    self.extensions = [[NSMutableArray alloc] init];
    
    if(![creativeElement isKindOfClass:[NSDictionary class]])
    {
        return NO;
    }
    
    for(NSInteger index = 0; index < _vastCreativeNumberOfAttributesImporterUtil; index++)
    {
        GTGoxImporterUtil importerUtil = _vastCreativeAttributesImporterUtil[index];
        NSString *name = [NSDictionary changeAttributename:importerUtil.attributeName];
        id attributeValue = [creativeElement valueForKeyPath:name];
        if(attributeValue != nil)
        {
            importerUtil.setter(self, importerUtil.propertyName, importerUtil.converter(attributeValue));
        }
    }
    
    // set child element
    for (NSString *elementName in [creativeElement childNodes])
    {
        if([elementName isEqualToString:GTVASTElementLinear])
        {
            NSDictionary *element = [creativeElement valueForKey:elementName];
            GTLinear *linear = [[GTLinear alloc] initWithElement:element withElementName:elementName];
            if (linear != nil)
            {
                [self setElement:linear];
            }
        }   
        else if([elementName isEqualToString:GTVASTElementCompanion])
        {
            NSDictionary *element = [creativeElement valueForKey:elementName];
            GTCompainon *compainon = [[GTCompainon alloc] initWithElement:element withElementName:elementName];
            if (compainon != nil)
            {
                [self setElement:compainon];
            }
        }
        else if([elementName isEqualToString:GTVASTElementNonLinearAds])
        {
            NSDictionary *element = [creativeElement valueForKey:elementName];
            GTNonLinearAds *nonLinearAds = [[GTNonLinearAds alloc] initWithElement:element withElementName:elementName];
            if (nonLinearAds != nil)
            {
                [self setElement:nonLinearAds];
            }
        }
        else if([elementName isEqualToString:GTVASTElementNonLinear])
        {
            NSDictionary *element = [creativeElement valueForKey:elementName];
            GTNonLinear *nonLinear = [[GTNonLinear alloc] initWithElement:element withElementName:element.nodeName];
            if (nonLinear != nil)
            {
                [self setElement:nonLinear];
            }
        }
        else if([elementName isEqualToString:GTVASTElementCreativeExtensions])
        {
            NSDictionary *element = [creativeElement valueForKey:elementName];
            for (NSString *subElementName in [element childNodes])
            {
                NSDictionary *subElement = [element valueForKey:subElementName];
                GTExtension *extension = [[GTExtension alloc] initWithElement:subElement];
                
                [self.extensions addObject:extension];
            }
        }
        else
        {
            NSDictionary *element = [creativeElement valueForKey:elementName];
            GTCreativeElement *child = [[GTCreativeElement alloc] initWithElement:element withElementName:element.nodeName];
            if (child != nil)
            {
                [self setElement:child];
            }
        }
    }
    
    if (self.extensions != nil && self.extensions.count > 0) {
        [self.element setExtensions:self.extensions];
    }
    
    
    
    return YES;
}

@end

@interface GTCreativeElement()
@property (nonatomic, strong) NSString*                   elementName;
@end
@implementation GTCreativeElement

- (id)initWithElement:(NSDictionary *)element withElementName:(NSString *)name
{
    self = [super init];
    
    if(self != nil)
    {
        NSDictionary* xmlDocument = element;
        self.elementName = name;
        
        if([self GT_commonInitWithXMLDocument:xmlDocument] == NO)
        {
            return nil;
        }
    }
    
    return self;
}

- (BOOL)GT_commonInitWithXMLDocument:(NSDictionary *)xmlDocument
{
    if(xmlDocument != nil)
    {
        [self setXmlDocument:xmlDocument];
        
        return [self setPropertiesFromDocument];
    }
    return NO;
}

- (BOOL) setPropertiesFromDocument
{
    return YES;
}

- (void) playCreativeElement:(UIView *)targetView completion:(void (^)(BOOL, id))completion
{
    completion(YES, nil);
}

- (NSMutableArray<GTTracking *> *) findTracksEventName:(NSString *)eventName
{
    return nil;
}
- (GTTracking *) findTrackEventName:(NSString *)eventName
{
    return nil;
}
- (void) sendTracking:(GTTracking *)tracking
{
    if(tracking != nil)
    {
        NSURL *url = [NSURL URLWithString:tracking.referURL];
        
        
        if (url != nil)
        {
            [[Statistics sharedStatistics] sendStatisticToURL:url];
        }
        
    }
}

- (void) sendTrackings:(NSMutableArray <GTTracking *>*)trackings
{
    if(trackings != nil && [trackings count] > 0)
    {
        for (GTTracking *tracking in trackings)
        {
            [self sendTracking:tracking];
        }
    }
}
@end


@implementation GTLinear

- (BOOL) setPropertiesFromDocument
{
    NSDictionary *linearElement = self.xmlDocument;
    NSString *skipOffsetName = [NSDictionary changeAttributename:GTVASTAttributeSkipoffset];
    NSString *skipOffsetString = [linearElement valueForKey:skipOffsetName];
    
    NSNumber *timeInterval = GTConvertTimeIntervalFromString(skipOffsetString);
    
    _skipoffset = [timeInterval integerValue];
    
    NSString *clickTypeName = [NSDictionary changeAttributename:GTVASTAttributeClickType];
    _clickType = [linearElement valueForKey:clickTypeName];
    
    NSNumber *duration = GTConvertTimeIntervalFromString([linearElement valueForKeyPath:GTVASTElementDuration]);
    _duration = [duration integerValue];
    
    _trackingEvents = [[NSMutableArray alloc] init];
    NSString *keyPath = GTVASTElementTrackingEvents@"."GTVASTElementTracking;
    for (NSDictionary *trackingEventElement in [linearElement arrayValueForKeyPath:keyPath])
    {
        GTTracking *tracking = [[GTTracking alloc] initWithElement:trackingEventElement];
        [_trackingEvents addObject:tracking];
    }
    
    keyPath = GTVASTElementVideoClicks@"."GTVASTElementClickThrough;
    _clickThrough = [linearElement valueForKeyPath:keyPath];
    
    //keyPath =
    
    keyPath = GTVASTElementVideoClicks@"."GTVASTElementClickTracking;
    _clickTracking = [linearElement valueForKeyPath:keyPath];
    
    _mediaFiles = [[NSMutableArray alloc] init];
    keyPath = GTVASTElementMediaFiles@"."GTVASTElementMediaFile;
    for (NSDictionary *mediaFileElement in [linearElement arrayValueForKeyPath:keyPath])
    {
        GTMediaFile *mediaFile = [[GTMediaFile alloc] initWithElement:mediaFileElement];
        [_mediaFiles addObject:mediaFile];
    }
    
    _Icons = [[NSMutableArray alloc] init];
    keyPath = GTVASTElementIcons@"."GTVASTElementIcon;
    for (NSDictionary *iconElement in [linearElement arrayValueForKeyPath:keyPath])
    {
        GTIcon *icon = [[GTIcon alloc] initWithElement:iconElement];
        [_Icons addObject:icon];
    }

    return YES;
}

- (void) playCreativeElement:(UIView *)targetView completion:(void (^)(BOOL, id))completion
{
    GXAdManager *adManager = [GXAdManager sharedManager];
    
    [adManager playCreativeElement:self atTargetView:targetView completion:^(BOOL success, id userInfo)
     {
         //
         if (success == YES)
         {
             completion(success, userInfo);
         }
         else
         {
             // TODO: error
             completion(NO, userInfo);
         }
     }];
    
}

- (NSMutableArray<GTTracking *> *) findTracksEventName:(NSString *)eventName
{
    NSMutableArray *result = [[NSMutableArray alloc] init];
    
    for (GTTracking *tracking in self.trackingEvents)
    {
        if ([tracking.event isEqualToString:eventName])
        {
            [result addObject:tracking];
        }
    }
    
    return result;
}

- (GTTracking *) findTrackEventName:(NSString *)eventName
{
    for (GTTracking *tracking in self.trackingEvents)
    {
        if ([tracking.event isEqualToString:eventName])
        {
            return tracking;
        }
    }
    
    return nil;
}

- (void) sendTracking:(GTTracking *)tracking
{
    if(tracking != nil)
    {
        NSURL *url = [NSURL URLWithString:tracking.referURL];
        
        
        if (url != nil)
        {
            [[Statistics sharedStatistics] sendStatisticToURL:url];
        }
        
        // send후에 리스트에서 제거한다.
        [self.trackingEvents removeObject:tracking];
    }
}

- (void) sendTrackings:(NSMutableArray <GTTracking *>*)trackings
{
    if(trackings != nil && [trackings count] > 0)
    {
        for (GTTracking *tracking in trackings)
        {
            [self sendTracking:tracking];
        }
    }
}
@end

@implementation GTCompainon
- (void) playCreativeElement:(UIView *)targetView
{
    
}
@end

@implementation GTNonLinearAds

- (BOOL) setPropertiesFromDocument
{
    NSDictionary *nonLinearAds = self.xmlDocument;
    
    _trackingEvents = [[NSMutableArray alloc] init];
    NSString *keyPath = GTVASTElementTrackingEvents@"."GTVASTElementTracking;
    for (NSDictionary *trackingEventElement in [nonLinearAds arrayValueForKeyPath:keyPath])
    {
        GTTracking *tracking = [[GTTracking alloc] initWithElement:trackingEventElement];
        [_trackingEvents addObject:tracking];
    }
    
    _nonlinears = [[NSMutableArray alloc] init];
    keyPath = GTVASTElementNonLinear;
    
    for (NSDictionary *nonlinearElement in [nonLinearAds arrayValueForKeyPath:keyPath])
    {
        GTNonLinear *nonlinear = [[GTNonLinear alloc] initWithElement:nonlinearElement withElementName:GTVASTElementNonLinear];
        [_nonlinears addObject:nonlinear];
    }
    return YES;
}

- (void) playCreativeElement:(UIView *)targetView completion:(void (^)(BOOL, id))completion
{
    for (GTNonLinear *nonlinear in _nonlinears)
    {
        if(self.ad != nil) {

            [self sendImpressionUrls:self.ad];
            self.ad = nil;
        }
        
        NSMutableArray<GTTracking *>* trackings = [self findTracksEventName:GXTrainkinEventTypeStart];
        [self sendTrackings:trackings];
        
        [nonlinear playCreativeElement:targetView completion:^(BOOL success, id userInfo)
        {
            // success == YES 정상적인 종료
            if (success)
            {
                NSMutableArray<GTTracking *>* trackings = [self findTracksEventName:GXTrainkinEventTypeComplete];
                [self sendTrackings:trackings];
            }
            // success == NO close버튼 클릭
            else
            {
                NSMutableArray<GTTracking *>* trackings = [self findTracksEventName:GXTrainkinEventTypeClose];
                [self sendTrackings:trackings];
            }
            
            completion(success, userInfo);
        }];
    }
}

- (NSMutableArray<GTTracking *> *) findTracksEventName:(NSString *)eventName
{
    NSMutableArray *result = [[NSMutableArray alloc] init];
    
    for (GTTracking *tracking in self.trackingEvents)
    {
        if ([tracking.event isEqualToString:eventName])
        {
            [result addObject:tracking];
        }
    }
    
    return result;
}

- (GTTracking *) findTrackEventName:(NSString *)eventName
{
    for (GTTracking *tracking in self.trackingEvents)
    {
        if ([tracking.event isEqualToString:eventName])
        {
            return tracking;
        }
    }
    
    return nil;
}

- (void) sendTracking:(GTTracking *)tracking
{
    if(tracking != nil)
    {
        NSURL *url = [NSURL URLWithString:tracking.referURL];
        
        
        if (url != nil)
        {
            [[Statistics sharedStatistics] sendStatisticToURL:url];
        }
        
        // send후에 리스트에서 제거한다.
        [self.trackingEvents removeObject:tracking];
    }
}

- (void) sendTrackings:(NSMutableArray <GTTracking *>*)trackings
{
    if(trackings != nil && [trackings count] > 0)
    {
        for (GTTracking *tracking in trackings)
        {
            [self sendTracking:tracking];
        }
    }
}

- (void)sendImpressionUrls:(GTAd*)ad
{
    for(NSURL *url in ad.impressionURLs) {
        [[Statistics sharedStatistics] sendStatisticToURL:url];
    }
}


@end

@interface GTNonLinear()

@property (nonatomic)BOOL isClosed;
@property (nonatomic, strong) UIView *targetView;
@property (nonatomic, copy) GXAdManagerComplationHandler completion;
@end
@implementation GTNonLinear

- (BOOL) setPropertiesFromDocument
{
    NSDictionary *nonLinear = self.xmlDocument;
    
    for(NSInteger index = 0; index < _nonlinearNumberOfAttributesImporterUtil; index++)
    {
        GTGoxImporterUtil importerUtil = _nonlinearAttributesImporterUtil[index];
        NSString *name = [NSDictionary changeAttributename:importerUtil.attributeName];
        id attributeValue = [nonLinear valueForKeyPath:name];
        if(attributeValue != nil)
        {
            importerUtil.setter(self, importerUtil.propertyName, importerUtil.converter(attributeValue));
        }
    }
    
    NSString *keyPath = GTVASTElementNonLinearClickThrough;
    _clickThrough = [nonLinear valueForKeyPath:keyPath];
    
    //keyPath =
    
    keyPath = GTVASTElementNonLinearClickTracking;
    _clickTracking = [nonLinear valueForKeyPath:keyPath];
    
    keyPath = GTVASTElementHTMLResource;
    _htmlResource = [nonLinear valueForKeyPath:keyPath];
    
    keyPath = GTVASTElementStaticResource;
    NSDictionary *staticResource = [nonLinear valueForKeyPath:keyPath];
    if ([staticResource isKindOfClass:[NSDictionary class]])
    {
        self.staticResource = [staticResource valueForKey:XMLDictionaryTextKey];
    }
    else if ([_staticResource isKindOfClass:[NSString class]])
    {
        self.staticResource = (NSString *)staticResource;
    }
    else
    {
        self.staticResource = nil;
    }
    
    return YES;
}

- (void) setStaticResource:(NSString *)staticResource
{
    _staticResource = staticResource;
    
    NSURL *url = [NSURL URLWithString:_staticResource];
    if (url)
    {
        dispatch_queue_t queue = dispatch_queue_create("com.gretech.gom.imageDownload", DISPATCH_QUEUE_CONCURRENT);
        dispatch_async(queue, ^{
            NSData *data = [NSData dataWithContentsOfURL:url];
            
            UIImage *image = [UIImage imageWithData:data];
            
            self.staticResourceAsset = image;
        });
    }

}

- (void) playCreativeElement:(UIView *)targetView completion:(void (^)(BOOL, id))completion
{
    self.completion = completion;
    self.targetView = targetView;
    
    CGFloat xPoint = 0;
    CGFloat yPoint = 0;
//    CGFloat widthRatio = _targetView.frame.size.width / self.currentMedia.width;
//    CGFloat heightRatio = _targetView.frame.size.height / self.currentMedia.height;
    
    UIViewAutoresizing resizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin |
    UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    if ([_xPosition isEqualToString:@"left"])
    {
        xPoint = 0;
    }
    else if ([_xPosition isEqualToString:@"right"])
    {
        xPoint = targetView.frame.size.width - _width;
    }
    else if ([_xPosition isEqualToString:@"middle"] || [_xPosition isEqualToString:@"center"])
    {
        xPoint = (targetView.frame.size.width - _width) / 2;
    }
    else
    {
        
        xPoint = [_xPosition floatValue];
    }
    
    if ([_yPosition isEqualToString:@"bottom"])
    {
        yPoint = targetView.frame.size.height - _height;
    }
    else if ([_yPosition isEqualToString:@"middle"] || [_yPosition isEqualToString:@"center"])
    {
        yPoint = (targetView.frame.size.height - _height) / 2;
    }
    else if ([_yPosition isEqualToString:@"top"])
    {
        yPoint = 0;
    }
    else
    {
        yPoint = [_yPosition floatValue];
    }
    
    CGRect frame = CGRectMake(xPoint, yPoint, _width, _height);
    UIView *subView = nil;
    if (_staticResource && _staticResourceAsset)
    {
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:frame];
        
        [imageView setImage:_staticResourceAsset];

        subView = (UIView *)imageView;
    }
    else if (_htmlResource)
    {
//        UIWebView *webView = [[UIWebView alloc] initWithFrame:frame];
//        [webView setBackgroundColor:[UIColor clearColor]];
//        [webView setOpaque:NO];
//        [webView loadHTMLString:_htmlResource baseURL:nil];
//
//        subView = (UIView *)webView;
        WKWebView *webView = [[WKWebView alloc] initWithFrame:frame];
        [webView setBackgroundColor:[UIColor clearColor]];
        [webView setOpaque:NO];
        [webView loadHTMLString:_htmlResource baseURL:nil];
        
        subView = (UIView *)webView;
    }
    
    if (subView)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [targetView addSubview:subView];
            
            //
            // 광고글 클릭했을때 사용할 버튼
            //
            UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
            [button setFrame:subView.frame];
            [button setBackgroundColor:[UIColor clearColor]];
            [button setAutoresizingMask:resizingMask];
            [button addTarget:self action:@selector(creativeTriggerHandler:) forControlEvents:UIControlEventTouchUpInside];
            [targetView addSubview:button];
            
            //
            // 닫기 버튼은 규격에는 정의되어 있지 않지만 도의적으로 만들어준다.
            //
            UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [closeButton setFrame:CGRectMake(button.frame.size.width - CLOSE_BUTTON_WIDTH, button.frame.origin.y, CLOSE_BUTTON_WIDTH, CLOSE_BUTTON_WIDTH)];
            [closeButton setBackgroundColor:[UIColor clearColor]];
            [closeButton addTarget:self action:@selector(creativeCloseHandler:) forControlEvents:UIControlEventTouchUpInside];
            [closeButton setAutoresizingMask:resizingMask];
            [targetView addSubview:closeButton];
            
            
            NSURL *url = [NSURL URLWithString:self.clickTracking];
            [[Statistics sharedStatistics] sendStatisticToURL:url];
        });
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(_minSuggestedDuration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (self->_isClosed == NO)
            {
                [self close:YES];
            }
            
        });
    }
    

    
}

- (void) creativeTriggerHandler:(id)sender
{
    NSURL *url = [NSURL URLWithString:self.clickTracking];
    [[Statistics sharedStatistics] sendStatisticToURL:url];
    
    NSURL *clickThrough = [NSURL URLWithString:self.clickThrough];
    if (clickThrough)
    {
        [[UIApplication sharedApplication] openURL:clickThrough
                                           options:@{}
                                 completionHandler:nil];
    }
    
}

- (void) creativeCloseHandler:(id)sender
{
    [self close:NO];
}

- (void) close:(BOOL)completion
{
    for (UIView *subView in _targetView.subviews)
    {
        [subView removeFromSuperview];
    }
    self.isClosed = YES;
    
    self.completion(completion, nil);
}
@end


@implementation GTTracking

- (BOOL) setPropertiesFromDocument
{
    NSDictionary *trackingElement = self.xmlDocument;
    
    NSString *evnetName = [NSDictionary changeAttributename:GTVASTAttributeEvent];
    NSString *offsetName = [NSDictionary changeAttributename:GTVASTAttributeOffset];
    _event = [trackingElement valueForKeyPath:evnetName];
    
    NSString *trackingString = [trackingElement valueForKey:offsetName];
    if (trackingString != nil)
    {
        NSNumber *offsetNumber = GTConvertTimeIntervalFromString(trackingString);
        _offset = [offsetNumber floatValue];
    }
    else
    {
        _offset = 0;
    }
    
    
    _referURL = [trackingElement innerText];
    
    return YES;
}

@end

@implementation GTMediaFile

- (BOOL) setPropertiesFromDocument
{
    NSDictionary *mediaElement = self.xmlDocument;
    
    if(![mediaElement isKindOfClass:[NSDictionary class]])
    {
        return NO;
    }
    
    for(NSInteger index = 0; index < _mediaNumberOfAttributesImporterUtil; index++)
    {
        GTGoxImporterUtil importerUtil = _mediaAttributesImporterUtil[index];
        NSString *name = [NSDictionary changeAttributename:importerUtil.attributeName];
        id attributeValue = [mediaElement valueForKeyPath:name];
        if(attributeValue != nil)
        {
            importerUtil.setter(self, importerUtil.propertyName, importerUtil.converter(attributeValue));
        }
    }
    
    _referURL = [mediaElement innerText];
    return YES;
}

@end

@implementation GTIcon

- (BOOL) setPropertiesFromDocument
{
    NSDictionary *iconElement = self.xmlDocument;
    
    NSString *offsetString = [iconElement valueForKey:[NSDictionary changeAttributename:GTVASTAttributeOffset]];
    NSInteger offset = [GTConvertTimeIntervalFromString(offsetString) longValue];
    self.offset = offset;
    
    NSString *durationString = [iconElement valueForKey:[NSDictionary changeAttributename:GTVASTPropertyDuration]];
    NSInteger duration = [GTConvertTimeIntervalFromString(durationString) longValue];
    self.duration = duration;
    
    for(NSInteger index = 0; index < _iconNumberOfAttributesImporterUtil; index++)
    {
        GTGoxImporterUtil importerUtil = _iconAttributesImporterUtil[index];
        NSString *name = [NSDictionary changeAttributename:importerUtil.attributeName];

        id attributeValue = [iconElement valueForKeyPath:name];
        if(attributeValue != nil)
        {
            importerUtil.setter(self, importerUtil.propertyName, importerUtil.converter(attributeValue));
        }
        
    }
    NSString *keyPath = GTVASTElementStaticResource;
    NSDictionary *staticResource = [iconElement valueForKeyPath:keyPath];
    if ([staticResource isKindOfClass:[NSDictionary class]])
    {
        self.staticResource = [staticResource valueForKey:XMLDictionaryTextKey];
    }
    else if ([_staticResource isKindOfClass:[NSString class]])
    {
        self.staticResource = (NSString *)staticResource;
    }
    else
    {
        self.staticResource = nil;
    }
    
    keyPath = GTVASTElementHTMLResource;
    _htmlResource = [iconElement valueForKeyPath:keyPath];
    
    keyPath = GTVASTElementIconClicks@"."GTVASTElementIconClickThrough;
    _iconClickThrough = [iconElement valueForKeyPath:keyPath];

    keyPath = GTVASTElementIconClicks@"."GTVASTElementIconClickTracking;
    _iconClickTracking = [iconElement valueForKeyPath:keyPath];
    
    return YES;
}

- (void) setStaticResource:(NSString *)staticResource
{
    _staticResource = staticResource;
    
    NSURL *url = [NSURL URLWithString:_staticResource];
    if (url)
    {
        dispatch_queue_t queue = dispatch_queue_create("com.gretech.gom.imageDownload", DISPATCH_QUEUE_CONCURRENT);
        dispatch_async(queue, ^{
            NSData *data = [NSData dataWithContentsOfURL:url];
            
            UIImage *image = [UIImage imageWithData:data];
            
            self.staticResourceAsset = image;
        });
    }
    
}

@end

@implementation GTExtension
- (BOOL) setPropertiesFromDocument
{
    NSDictionary *extensionElement = self.xmlDocument;
    
    NSString *typeString = [extensionElement valueForKey:[NSDictionary changeAttributename:GTVASTAttributeType]];
    
    self.type = typeString;
    
    if ([self.type isEqualToString:GTVRIX]) {
        [self handlingVRiX:extensionElement];
    }
    return YES;
}

- (void) handlingVRiX:(NSDictionary*) vrixElement
{
    for (NSString *elementName in vrixElement.childNodes)
    {
        if ([elementName.lowercaseString isEqualToString:GTVASTElementAdExtentionLabel.lowercaseString])
        {
            NSDictionary *element = [vrixElement valueForKey:elementName];
            GTLabel *label = [[GTLabel alloc] initWithElement:element];
            
            self.extensionObject = label;
        } else if ([elementName.lowercaseString isEqualToString:GTVASTElementAdExtentionPositionFixed.lowercaseString]) {
            NSDictionary *element = [vrixElement valueForKey:elementName];
            GTPositionFixedFlag *flag = [[GTPositionFixedFlag alloc] initWithElement:element];
            
            self.postionFixedFlag = flag;
        } else if ([elementName.lowercaseString isEqualToString:GTVASTElementAdExtentionNetworkType.lowercaseString]) {
            NSDictionary *element = [vrixElement valueForKey:elementName];
            self.networkType = [element valueForKey:XMLDictionaryTextKey];
        }
    }
    
    
}
@end

@implementation GTVRiXExtensionObject
- (BOOL) setPropertiesFromDocument
{
    return YES;
}
@end

@implementation GTLabel
- (BOOL) setPropertiesFromDocument
{
    NSDictionary *labelElement = self.xmlDocument;
    self.fontname = [labelElement valueForKey:[NSDictionary changeAttributename:@"font"]];
    self.size = [[labelElement valueForKey:[NSDictionary changeAttributename:@"size"]] floatValue];
    self.style = [labelElement valueForKey:[NSDictionary changeAttributename:@"style"]];
    NSString *fontColorString = [[labelElement valueForKey:[NSDictionary changeAttributename:@"fontcolor"]] stringByReplacingOccurrencesOfString:@"#" withString:@""];
    self.fontcolor = [UIColor colorWithHexString:fontColorString];
    NSString *shadowColorString = [[labelElement valueForKey:[NSDictionary changeAttributename:@"shadowcolor"]]  stringByReplacingOccurrencesOfString:@"#" withString:@""];
    self.shadowcolor = [UIColor colorWithHexString:shadowColorString];
    self.shadowradius = [[labelElement valueForKey:[NSDictionary changeAttributename:@"shadowradious"]] floatValue];
    self.shadowopacity = [[labelElement valueForKey:[NSDictionary changeAttributename:@"shadowopacity"]] floatValue];
    self.shadowpathX = [[labelElement valueForKey:[NSDictionary changeAttributename:@"shadowpathX"]] floatValue];
    self.shadowpathY = [[labelElement valueForKey:[NSDictionary changeAttributename:@"shadowpathY"]] floatValue];
    self.action = [labelElement valueForKey:[NSDictionary changeAttributename:@"action"]];
    self.format = [labelElement valueForKey:[NSDictionary changeAttributename:@"format"]];
    self.xPosition = [labelElement valueForKey:[NSDictionary changeAttributename:@"xPosition"]];
    self.yPosition = [labelElement valueForKey:[NSDictionary changeAttributename:@"yPosition"]];
    self.value = [labelElement valueForKey:XMLDictionaryTextKey];
    
    self.leftMargin = [[labelElement valueForKey:[NSDictionary changeAttributename:@"leftMargin"]] floatValue];
    self.rightMargin = [[labelElement valueForKey:[NSDictionary changeAttributename:@"rightMargin"]] floatValue];
    self.topMargin = [[labelElement valueForKey:[NSDictionary changeAttributename:@"topMargin"]] floatValue];
    self.bottomMargin = [[labelElement valueForKey:[NSDictionary changeAttributename:@"bottomMargin"]] floatValue];
    
    return YES;
}
@end

@implementation GTPositionFixedFlag
- (BOOL) setPropertiesFromDocument
{
    NSDictionary *positionFixedFlag = self.xmlDocument;
    self.leftMargin = [[positionFixedFlag valueForKey:[NSDictionary changeAttributename:@"leftMargin"]] floatValue];
    self.rightMargin = [[positionFixedFlag valueForKey:[NSDictionary changeAttributename:@"rightMargin"]] floatValue];
    self.topMargin = [[positionFixedFlag valueForKey:[NSDictionary changeAttributename:@"topMargin"]] floatValue];
    self.bottomMargin = [[positionFixedFlag valueForKey:[NSDictionary changeAttributename:@"bottomMargin"]] floatValue];
    
    self.useFlag = [positionFixedFlag valueForKey:XMLDictionaryTextKey];
    
    return YES;
}
@end

#pragma mark - vast
static GTGoxImporterUtil const _vastAttributesImporterUtil[] =
{
    { GTGoxAttributeVersion,  GTGoxPropertyVersion,      GTGoxSetValue,                          GTGoxStringFromValue },
    
};
static NSInteger const _vastNumberOfAttributesImporterUtil = sizeof(_vastAttributesImporterUtil) / sizeof(_vastAttributesImporterUtil[0]);

static GTGoxImporterUtil const _vastElementImportUtil[] =
{
    { GTVMAPElementAd,          GTVASTPropertyAdList,           GTGoxAddObject,           GTVASTAdFromNode },
};

static NSInteger const _vastNumberOfElementImportUtil = sizeof(_vastElementImportUtil) / sizeof(_vastElementImportUtil[0]);

#pragma mark - vast:ad
static GTGoxImporterUtil const _vastAdAttributesImporterUtil[] =
{
    { GTVASTAttributeSequence,  GTVASTPropertySequence,      GTGoxSetValue,                          GTGoxStringFromValue },
    
};
static NSInteger const _vastAdNumberOfAttributesImporterUtil = sizeof(_vastAdAttributesImporterUtil) / sizeof(_vastAdAttributesImporterUtil[0]);


#pragma mark - vast:ad:creatives:creative
static GTGoxImporterUtil const _vastCreativeAttributesImporterUtil[] =
{
    { GTVASTAttributeSequence,  GTVASTPropertySequence,      GTGoxSetValue,                          GTGoxStringFromValue },
    { GTVASTAttributeAdId,      GTVASTPropertyAdId,         GTGoxSetValue,                           GTGoxStringFromValue },
    
};
static NSInteger const _vastCreativeNumberOfAttributesImporterUtil = sizeof(_vastCreativeAttributesImporterUtil) / sizeof(_vastCreativeAttributesImporterUtil[0]);

static GTGoxImporterUtil const _mediaAttributesImporterUtil[] =
{
    { GTVMAPAttributeId,        GTVMAPPropertyId,           GTGoxSetValue,                          GTGoxStringFromValue },
    { GTVASTAttributeDelivery,  GTVASTPropertyDelivery,     GTGoxSetValue,                          GTGoxStringFromValue },
    { GTGoxAttributeType,       GTVASTPropertyType,         GTGoxSetValue,                          GTGoxStringFromValue },
    { GTVASTAttributeBitrate,   GTVASTPropertybitrate,      GTGoxSetValue,                          GTGoxStringFromValue },
    { GTVASTAttributeWidth,     GTVASTPropertyWidth,        GTGoxSetFloat,                          GTGoxFloatFromValue },
    { GTVASTAttributeHeight,    GTVASTPropertyHeight,       GTGoxSetFloat,                          GTGoxFloatFromValue },
    
};
static NSInteger const _mediaNumberOfAttributesImporterUtil = sizeof(_mediaAttributesImporterUtil) / sizeof(_mediaAttributesImporterUtil[0]);

static GTGoxImporterUtil const _iconAttributesImporterUtil[] =
{
    { GTVASTAttributeProgram,   GTVASTAttributeProgram,     GTGoxSetValue,                          GTGoxStringFromValue },
    { GTVASTAttributeXRatio,    GTVASTPropertyXRatio,       GTGoxSetFloat,                          GTGoxFloatFromValue },
    { GTVASTAttributeYRatio,    GTVASTPropertyYRatio,       GTGoxSetFloat,                          GTGoxFloatFromValue },
    { GTVASTAttributeXPosition, GTVASTPropertyXPostion,     GTGoxSetValue,                          GTGoxStringFromValue },
    { GTVASTAttributeYPosition, GTVASTPropertyYPostion,     GTGoxSetValue,                          GTGoxStringFromValue },
    { GTVASTAttributeWidth,     GTVASTPropertyWidth,        GTGoxSetFloat,                          GTGoxFloatFromValue },
    { GTVASTAttributeHeight,    GTVASTPropertyHeight,       GTGoxSetFloat,                          GTGoxFloatFromValue },
};
static NSInteger const _iconNumberOfAttributesImporterUtil = sizeof(_iconAttributesImporterUtil) / sizeof(_iconAttributesImporterUtil[0]);

static GTGoxImporterUtil const _nonlinearAttributesImporterUtil[] =
{
    { GTVMAPAttributeId,        GTVMAPPropertyId,           GTGoxSetValue,                          GTGoxStringFromValue },
    { GTVASTAttributeWidth,     GTVASTPropertyWidth,        GTGoxSetFloat,                          GTGoxFloatFromValue },
    { GTVASTAttributeHeight,    GTVASTPropertyHeight,       GTGoxSetFloat,                          GTGoxFloatFromValue },
    { GTVASTAttributeExpandedWidth,     GTVASTPropertyExpandedWidth,        GTGoxSetFloat,                          GTGoxFloatFromValue },
    { GTVASTAttributeExpandedHeight,    GTVASTPropertyExpandedHeight,       GTGoxSetFloat,                          GTGoxFloatFromValue },
    { GTVASTAttributeScalable,    GTVASTPropertyScalable,       GTGoxSetBoolean,    GTGoxBooleanFromValue },
    { GTVASTAttributeMinSuggestedDuration,    GTVASTPropertyMinSuggestedDuration,       GTGoxSetFloat,                          GTConvertTimeIntervalFromString },
    { GTVASTAttributeXPosition, GTVASTPropertyXPostion,     GTGoxSetValue,                          GTGoxStringFromValue },
    { GTVASTAttributeYPosition, GTVASTPropertyYPostion,     GTGoxSetValue,                          GTGoxStringFromValue },
    
};
static NSInteger const _nonlinearNumberOfAttributesImporterUtil = sizeof(_nonlinearAttributesImporterUtil) / sizeof(_nonlinearAttributesImporterUtil[0]);

