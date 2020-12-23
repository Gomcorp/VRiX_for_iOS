//
//  UIColor+HexColors.h
//  VRiX
//
//  Created by GOMIMAC on 2018. 3. 22..
//  Copyright © 2018년 GOMIMAC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (HexColors)
+(UIColor *)colorWithHexString:(NSString *)hexString;
+(NSString *)hexValuesFromUIColor:(UIColor *)color;
@end
