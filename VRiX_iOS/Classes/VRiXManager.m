//
//  VRiXManager.m
//  VRiX
//
//  Created by GOMIMAC on 2017. 8. 8..
//  Copyright © 2017년 GOMIMAC. All rights reserved.
//

#import "VRiXManager.h"
#import "VRiX.h"
#import "GXAdManager.h"
#import "GTVMAP.h"
#import "GTVAST.h"

#import "GXADPlayer.h"

#import "Statistics.h"
#import "GTGoxImporterUtil.h"

typedef void(^VRiXManagerComplationHandler)(BOOL success, id userInfo);
@interface VRiXManager()
@property (nonatomic, strong) VRiX *vrix;
@property (nonatomic, strong) NSArray *prerolls;
@property (nonatomic, strong) NSArray *midrolls;
@property (nonatomic, strong) NSArray *postrolls;
@property (nonatomic, strong) NSString* keyValue;
@property (nonatomic, strong) NSString* hashKeyValue;
@property (nonatomic, strong) NSString* idfa;
@property (nonatomic, copy) VRiXManagerComplationHandler completion;
@end

@implementation VRiXManager

- (VRiXManager *) initWithKey:(NSString *)key hashKey:(NSString *)hashKey
{
    if([super init])
    {
        //NSLog(@"initWithKey");
        _keyValue = key;
        _hashKeyValue = hashKey;
        _idfa = identifierForAdvertising();
        [[Statistics sharedStatistics] userAgent];
        
        return self;
    }
    
    return nil;
}

- (void) fetchVRiX:(NSURL *)url
 completionHandler:(void (^)(BOOL success, NSError *error))handler
{
    self.vrix = [[VRiX alloc] initWithVRiXURL:url];
    if (_vrix)
    {
        self.prerolls = [self getAdBreaksByOffsetType:GTTimeOffsetTypeStart];
        self.midrolls = [self getAdBreaksByOffsetType:GTTimeOffsetTypeMid];
        self.postrolls = [self getAdBreaksByOffsetType:GTTimeOffsetTypeEnd];
        
        handler(YES, nil);
        return ;
    }
    
    NSError *error = [NSError errorWithDomain:@"com.gomcompany.VRiX"
                                         code:404
                                     userInfo:@{@"message":@"Unknown error"}];
    handler(NO, error);
}

- (void) stopCurrentAD
{
    [[GXAdManager sharedManager] stopPlay];
}

- (CGFloat) getCurrentAdDuration
{
    return [[GXAdManager sharedManager] currentAdDuration];
}

- (CGFloat) getCurrentAdPlaytime
{
    return [[GXAdManager sharedManager] currentAdPlayTime];
}

- (void) prerollAtView:(UIView *)targetView
  completionWithResult:(void (^)(NSString* adNames, NSInteger count, NSArray<NSDictionary *>* userInfos))completionHandler{
    
    __block NSInteger count = 0;
    __block NSString *networkTypes = @"";
    
    [self playAllAdBreak:_prerolls targetView:targetView advertisementCompleted:^(BOOL result, NSString *networkType) {
        //
        if (result == true) {
            count++;
            
            if (networkType != nil) {
                if ([networkTypes isEqualToString:@""]) {
                    networkTypes = networkType;
                } else {
                    networkTypes = [networkTypes stringByAppendingFormat:@",%@", networkType];
                }
            }
            
        }
    } totalCompletion:^(BOOL success, id userInfo) {
        //
        completionHandler(networkTypes, count, userInfo);
    }];
}

- (void) prerollAtView:(UIView *)view
     completionHandler:(void (^)(BOOL success, id userInfo))handler
{
    self.completion = handler;
    [self playAllAdBreak:_prerolls
              targetView:view
              completion:handler];
}

- (void) playAllAdBreak:(NSArray *)list
             targetView:(UIView *)view
 advertisementCompleted:(void (^)(BOOL result, NSString *networkType))adCompleted
        totalCompletion:(void (^)(BOOL success, id userInfo))completion
{
    GTVMAPAdBreak *adBreak = [self findNotPlayedBreak:list];
    
    [self excuteAdBreak:adBreak targetView:view advertisementCompleted:adCompleted completion:^(BOOL success, id userInfo)
     {
         //
        GTVMAPAdBreak *moreBreak = [self findNotPlayedBreak:self->_prerolls];
         if (moreBreak != nil)
         {
             [self playAllAdBreak:list targetView:view completion:completion];
         }
         else
         {
             completion(success, userInfo);
         }
         
     }];
}

- (void) playAllAdBreak:(NSArray *)list targetView:(UIView *)view completion:(void (^)(BOOL success, id userInfo))completion
{
    GTVMAPAdBreak *adBreak = [self findNotPlayedBreak:list];
    
    [self excuteAdBreak:adBreak
             targetView:view
 advertisementCompleted:^(BOOL result, NSString *networkType) {
        //
    }
             completion:^(BOOL success, id userInfo)
     {
         //
         GTVMAPAdBreak *moreBreak = [self findNotPlayedBreak:self->_prerolls];
         if (moreBreak != nil)
         {
             [self playAllAdBreak:list targetView:view completion:completion];
         }
         else
         {
             completion(success, userInfo);
         }
         
     }];
}

- (GTVMAPAdBreak *)findNotPlayedBreak:(NSArray *)list
{
    for (GTVMAPAdBreak *adBreak in list)
    {
        if (adBreak.status == GTAdBreakStatusNotPlay)
        {
            return adBreak;
        }
    }
    
    return nil;
}

- (NSInteger) prerollCount
{
    if (_prerolls == nil)
    {
        return 0;
    }
    
    return [_prerolls count];
}

- (void) midrollAtView:(UIView *)view
            timeOffset:(NSTimeInterval)offset
       progressHandler:(void (^)(BOOL whenItStart, GXAdBreakType breakType, NSAttributedString *message))progressHandler
     completionHandler:(void (^)(GXAdBreakType breakType))completionHandler
{
    for (GTVMAPAdBreak *adBreak in _midrolls)
    {
        if (adBreak.status == GTAdBreakStatusNotPlay)
        {
            GXAdBreakType breakType = [self convertStringToType:adBreak.breakType];
            
            // show message
            long timegap = offset - (adBreak.timeOffset * 1000);
            if (timegap > -6 && timegap <= 0)
            {
                NSInteger time = timegap * -1;
                NSString *message = @"[[잠시 후 광고가 시작됩니다.]]";
                if (timegap != 0)
                    message = [NSString stringWithFormat:@"[[%ld]]초 후 광고가 시작됩니다.", (long)time];
                
                NSAttributedString *messageString = [self message:message setTextColor:[UIColor orangeColor] startString:@"[[" endString:@"]]"];
                
                progressHandler(NO, breakType, messageString);
                return;
                
            }
            
            if (offset >= (adBreak.timeOffset * 1000))
            {
                // hide message
                progressHandler(NO, breakType, nil);
                
                // show AD
                GTVMAPAdBreak *adBreak = [self GT_getAdMidBreak:_midrolls currentOffset:offset];
                breakType = [self convertStringToType:adBreak.breakType];
                if (adBreak != nil)
                {
                    
                    progressHandler(YES, breakType, [[NSAttributedString alloc] initWithString:@""]);
                    
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(),
                    ^{
                        [self excuteAdBreak:adBreak
                                 targetView:view
                     advertisementCompleted:^(BOOL result, NSString *networkType) {
                            //
                        } completion:^(BOOL success, id userInfo)
                        {
                            completionHandler(breakType);
                        }];
                    });
                    
                    
                }
                
                
            }
        }
    }
    
    return;
}

- (GXAdBreakType) convertStringToType:(NSString *)breakTypeString
{
    if ([[breakTypeString lowercaseString] isEqualToString:@"linear"])
    {
        return GXAdBreakTypelinear;
    }
    else if ([[breakTypeString lowercaseString] isEqualToString:@"nonlinear"])
    {
        return GXAdBreakTypeNonlinear;
    }
    
    return GXAdBreakTypeUnknown;
}
- (NSInteger) midrollCount
{
    if (_midrolls == nil)
    {
        return 0;
    }
    
    return [_midrolls count];
}

- (void) postrollAtView:(UIView *)targetView
completionHandler:(void (^)(BOOL success, id userInfo))handler
{
    self.completion = handler;
    
    [self playAllAdBreak:_postrolls
              targetView:targetView
              completion:handler];
}

- (NSInteger) postrollCount
{
    if (_postrolls == nil)
    {
        return 0;
    }
    
    return [_postrolls count];
}

- (NSArray<GTVMAPAdBreak *> *) getAdBreaksByOffsetType:(GTTimeOffsetType)offsetType
{
    NSMutableArray<GTVMAPAdBreak *> *result = [[NSMutableArray alloc] init];
    GTVMAP *vmap = _vrix.vmap;
    if ([vmap.adBreakList count] > 0)
    {
        for (GTVMAPAdBreak *adBreak in vmap.adBreakList)
        {
            if (offsetType == adBreak.offsetType)
            {
                [result addObject:adBreak];
            }
        }
    }
    
    return [NSArray arrayWithArray:result];
}

- (void) excuteAdBreak:(GTVMAPAdBreak *)adBreak
            targetView:(UIView *)view
advertisementCompleted:(void (^)(BOOL result, NSString *networkType)) adCompleted
            completion:(void (^)(BOOL success, id userInfo))completion
{
    if (adBreak != nil && adBreak.status == GTAdBreakStatusNotPlay)
    {
        // linear인경우 광고 재생전에 플레이 됨으로 표기한다.
        [adBreak setStatus:GTAdBreakStatusPlayed];
        if ([[adBreak.breakType lowercaseString] isEqualToString:@"nonlinear"])
        {
            [adBreak setStatus:GTAdBreakStatusPlayed];
        }
        
        [adBreak excuteAdAtTargetView:view
               advertisementCompleted:^(BOOL result, NSString *networkType) {
                //
                adCompleted(result, networkType);
            }
                           completion:^(BOOL success, id userInfo)
         {
             if (adBreak.status == GTAdBreakStatusNotPlay)
             {
                 [adBreak setStatus:GTAdBreakStatusPlayed];
             }
             
             completion(success, userInfo);
         }];
    }
    
}

#pragma mark -
- (GTVMAPAdBreak *) GT_getAdMidBreak:(NSArray *)adList currentOffset:(NSTimeInterval)offset
{
    GTVMAPAdBreak *result = nil;
    NSArray<GTVMAPAdBreak *> *candidateList = [self GT_getAdCandidateList:adList offset:offset];
    
    if ([candidateList count] > 0)
    {
        result = [candidateList firstObject];
    }
    
    for (GTVMAPAdBreak *adBreak in adList)
    {
        if (![adBreak isEqual:result] &&
            offset >= (adBreak.timeOffset * 1000) &&
            adBreak.status == GTAdBreakStatusNotPlay &&
            adBreak.offsetType == GTTimeOffsetTypeMid)
        {
            [adBreak setStatus:GTAdBreakStatusSkipped];
        }
    }
    
    
    
    
    
    return result;
}

- (NSArray<GTVMAPAdBreak *> *) GT_getAdCandidateList:(NSArray *)targetList offset:(NSTimeInterval)offset
{
    NSMutableArray *tempList = [[NSMutableArray alloc] init];
    
    for (GTVMAPAdBreak *adBreak in targetList)
    {
        if (adBreak.status == GTAdBreakStatusNotPlay && adBreak.offsetType == GTTimeOffsetTypeMid)
        {
            if (offset >= (adBreak.timeOffset * 1000))
            {
                [tempList addObject:adBreak];
            }
        }
    }
    
    NSArray *sortedArray = [tempList sortedArrayUsingFunction:GT_compareAdBreakOffset context:(__bridge void * _Nullable)([NSNumber numberWithDouble:offset])];
    
    return sortedArray;
}

NSComparisonResult GT_compareAdBreakOffset(GTVMAPAdBreak* obj1, GTVMAPAdBreak* obj2, void *context)
{
    NSNumber *offset = (__bridge NSNumber *)(context);
    if ([offset isKindOfClass:[NSNumber class]])
    {
        //
        double current = [offset doubleValue];
        double firstDiff    = fabs(current - obj1.timeOffset);
        double secodeDiff   = fabs(current - obj2.timeOffset);
        
        if (firstDiff > secodeDiff)
        {
            return NSOrderedAscending;
        }
        else
        {
            return NSOrderedDescending;
        }
    }
    
    return NSOrderedAscending;
}

#pragma mark - 
- (NSAttributedString *) message:(NSString *)message setTextColor:(UIColor *)textColor startString:(NSString *) startString endString:(NSString *)endString
{
    NSString *text = [message copy];
    NSString *replacementedText = [text stringByReplacingOccurrencesOfString:startString withString:@""];
    replacementedText = [replacementedText stringByReplacingOccurrencesOfString:endString withString:@""];
    
    
    
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:replacementedText];
    NSRange range = NSMakeRange(0, attributedText.length);
    [attributedText addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:range];
    
    NSRange start = [text rangeOfString:startString];
    NSRange end = [text rangeOfString:endString];
    BOOL isContinue = YES;
    do
    {
        if (start.location != NSNotFound || end.location != NSNotFound)
        {
            start = [text rangeOfString:startString];
            text = [text stringByReplacingCharactersInRange:start withString:@""];
            end = [text rangeOfString:endString];
            text = [text stringByReplacingCharactersInRange:end withString:@""];
            
            // chage color in [[ ]]
            NSRange targetRange = NSUnionRange(start, end);
            targetRange.length = targetRange.length-start.length; // 길이 제외
            
            [attributedText addAttribute:NSForegroundColorAttributeName
                                   value:textColor
                                   range:targetRange];
            
        }
        else
        {
            isContinue = NO;
        }
        
        start = [text rangeOfString:startString];
        end = [text rangeOfString:endString];
    }
    while (isContinue == YES);
    
    
    [attributedText addAttributes:@{NSStrokeColorAttributeName:[UIColor blackColor],
                                    NSStrokeWidthAttributeName:[NSNumber numberWithFloat:-2.0],
                                    NSFontAttributeName:[UIFont systemFontOfSize:12]}
                            range:range];
    
    return attributedText;
    
}

/*!
@method            pauseCurrentAD
@discussion        현재의 광고를 pause한다.
*/
- (void) pause
{
    [[GXAdManager sharedManager] pause];
}

/*!
@method            resumeCurrentAD
@discussion        현재의 광고를 resume한다.
*/
- (void) resume
{
    [[GXAdManager sharedManager] resume];
}

@end
