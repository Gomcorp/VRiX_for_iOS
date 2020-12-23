//
//  VRiXManager.h
//  VRiX
//
//  Created by GOMIMAC on 2017. 8. 8..
//  Copyright © 2017년 GOMIMAC. All rights reserved.
//
enum _GXAdBreakType {
    GXAdBreakTypeUnknown = 0,
    GXAdBreakTypelinear,
    GXAdBreakTypeNonlinear,
};
typedef enum _GXAdBreakType GXAdBreakType;

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

static NSString* VRIX_IOS_LIBRARY_VERSION = @"3.0.4";

@interface VRiXManager : NSObject

/*!
@method			initWithKey:hashKey:
@param          key 사용자별 키값
@param			hashKey 사용자별 시크릿 키값
@discussion		브릭스를 핸들링가능한 메니져를 init한다.
*/
- (VRiXManager *) initWithKey:(NSString *)key hashKey:(NSString *)hashKey;

/*!
 @method			fetchVRiX:completionHandler:
 @param				url VRiX주소
 @param				handler fetch 완료 호출될 block
 @discussion		브릭스서비스에서 광고 정보를 fetch한다..
 */
- (void) fetchVRiX:(NSURL *)url
 completionHandler:(void (^)(BOOL success, NSError *error))handler;

/*!
 @method			stopCurrentAD
 @discussion		현재 재생중인 광고를 중지 시킨다.
 */
- (void) stopCurrentAD;

/*!
 @method            getCurrentAdDuration
 @discussion        현재 재생중인 광고의 전체 재생시간.
 */
- (CGFloat) getCurrentAdDuration;

/*!
 @method            getCurrentAdPlayTime
 @discussion        현재 재생중인 광고의 play time
 */
- (CGFloat) getCurrentAdPlaytime;

/*!
 @method			prerollAtView:completionHandler
 @param				targetView 광고가 재생될 뷰
 @param				handler 광고재생 완료 후 호출될 block
 @discussion		프리롤 광고를 해당뷰에 재생시킨다.
 */
- (void) prerollAtView:(UIView *)targetView
     completionHandler:(void (^)(BOOL success, id userInfo))handler;

/*!
 @method            prerollAtView:completionHandler
 @param                targetView 광고가 재생될 뷰
 @param                completionHandler 광고재생 완료 후 호출될 block
 @discussion        프리롤 광고를 해당뷰에 재생시킨다.
 */
- (void) prerollAtView:(UIView *)targetView
  completionWithResult:(void (^)(NSString* adNames, NSInteger count, NSArray<NSDictionary *>* userInfos))completionHandler;
    
/*!
 @method			prerollCount
 @discussion		프리롤광고의 곗수를 리턴한다.
 */
- (NSInteger) prerollCount;

/*!
 @method			midrollAtView:timeOffset:progressHandler:completionHandler
 @param				targetView 광고가 재생될 뷰
 @param             offset 현재 재생중인 컨텐츠의 재생시간
 @param             progressHandler timeOffset에 따른 결과값 block 코드
 @param				completionHandler 광고재생 완료 후 호출될 block
 @discussion		미드롤 광고를 해당뷰에 재생한다.
 */
- (void) midrollAtView:(UIView *)targetView
            timeOffset:(NSTimeInterval)offset
       progressHandler:(void (^)(BOOL whenItStart, GXAdBreakType breakType, NSAttributedString *message))progressHandler
     completionHandler:(void (^)(GXAdBreakType breakType))completionHandler;

/*!
 @method			midrollCount
 @discussion		미드롤광고의 곗수를 리턴한다.
 */
- (NSInteger) midrollCount;

/*!
 @method			postrollAtView:completionHandler
 @param				targetView 광고가 재생될 뷰
 @param				handler 광고재생 완료 후 호출될 block
 @discussion		포스트롤 광고를 해당뷰에 재생시킨다.
 */
- (void) postrollAtView:(UIView *)targetView
      completionHandler:(void (^)(BOOL success, id userInfo))handler;

/*!
 @method			postrollCount
 @discussion		포스트롤광고의 곗수를 리턴한다.
 */
- (NSInteger) postrollCount;

/*!
@method            pauseCurrentAD
@discussion        현재의 광고를 pause한다.
*/
- (void) pause;

/*!
@method            resumeCurrentAD
@discussion        현재의 광고를 resume한다.
*/
- (void) resume;
@end
