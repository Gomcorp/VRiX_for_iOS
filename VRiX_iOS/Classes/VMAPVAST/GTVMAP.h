//
//  GTVMAP.h
//  GoxEntry
//
//  Created by Youngchang koo on 2016. 5. 10..
//  Copyright © 2016년 Youngchang koo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class GTVMAPAdBreak;

@interface GTNodeObject: NSObject

@property (nonatomic, strong)   NSDictionary*                       xmlDocument;

- (id)initWithElement:(NSDictionary *)element;
- (BOOL) setPropertiesFromDocument;

@end

@interface GTVMAP : GTNodeObject

- (id)initWithVMAPString:(NSString*)vmapString;
- (id)initWithURL:(NSURL*)url;

@property (nonatomic, strong)   NSMutableArray<GTVMAPAdBreak *>*    adBreakList;
@property (nonatomic, copy)     NSString*                           version;
@property (nonatomic, copy)     NSString*                           adsection;
@property (nonatomic, copy)     NSString*                           namespaceString;

- (BOOL) needShowADSection;

@end

enum _GTTimeOffsetType
{
    GTTimeOffsetTypeStart  = 0,
    GTTimeOffsetTypeMid    = 1,
    GTTimeOffsetTypeEnd    = 2,
    
};
typedef enum _GTTimeOffsetType GTTimeOffsetType;

enum _GTAdBreakStatus
{
    GTAdBreakStatusNotPlay  = 0,
    GTAdBreakStatusSkipped  = 1,
    GTAdBreakStatusPlayed   = 2,
    
};
typedef enum _GTAdBreakStatus GTAdBreakStatus;

@class GTVMAPAdSource;
@interface GTVMAPAdBreak : GTNodeObject

@property (nonatomic, strong) NSString*         breakType;
@property (nonatomic, strong) NSString*         breakId;

@property (nonatomic, assign) GTTimeOffsetType  offsetType;
@property (nonatomic, assign) NSTimeInterval    timeOffset;

@property (nonatomic, assign) GTAdBreakStatus   status;
@property (nonatomic, strong) GTVMAPAdSource*   adSource;

- (id)initWithElement:(NSDictionary *)element;
- (void) excuteAdAtTargetView:(UIView *)view
       advertisementCompleted:(void (^)(BOOL result, NSString *networkType))adCompleted
                   completion:(void (^)(BOOL, id))completion;
- (void) cancelExcute;
@end

@class GTVMAPAdTagURI;
@class GTVASTAdData;
@interface GTVMAPAdSource : GTNodeObject

@property (nonatomic) BOOL allowMultipleAds;
@property (nonatomic) BOOL followRedirects;
@property (nonatomic, strong) NSString *idValue;

@property (nonatomic, strong) GTVMAPAdTagURI *adTagURI;
@property (nonatomic, strong) GTVASTAdData *vastData;

- (id)initWithElement:(NSDictionary *)element;
@end

@class GTVAST;
@interface GTVMAPAdTagURI : GTNodeObject
@property (nonatomic, strong) NSString *teplateType;
@property (nonatomic, strong) NSString *vastURL;
@property (nonatomic, strong) GTVAST *vast;

- (id)initWithElement:(NSDictionary *)element;

@end

@class GTVAST;
@interface GTVASTAdData : GTNodeObject
@property (nonatomic, strong) GTVAST *vast;

- (id)initWithElement:(NSDictionary *)element;
@end
