//
//  GTGoxImporterUtil.h
//  TwoGOM
//
//  Created by Seung-Han Kim on 12. 4. 20..
//  Copyright (c) 2012년 le5na81@gmail.com. All rights reserved.
//
#import <UIKit/UIKit.h>

@class GTVMAP;

struct GTGoxImporterUtil
{
    __unsafe_unretained NSString*       attributeName;
    __unsafe_unretained NSString*       propertyName;
    
    void (*setter)(id, NSString*, id);
    id (*converter)(NSDictionary*);
};

SEL GTSelecterFromKey(NSString* key);

typedef struct GTGoxImporterUtil GTGoxImporterUtil;

void GTGoxSetValue(id owner, NSString* key, id value);
void GTGoxAddObject(id owner, NSString* key, id value);
void GTGoxSetInteger(id owner, NSString* key, id value);
void GTGoxSetBoolean(id owner, NSString* key, id value);
void GTGoxSetFloat(id owner, NSString* key, id value);
void GTGoxSetTimeIntervalFromMicroSecond(id owner, NSString* key, id value);
void GTGoxSetPoint(id owner, NSString* key, id value);

id GTGoxReferenceStringFromNode(NSDictionary* node);
id GTGoxDRMStringFromNode(NSDictionary* node);
id GTGoxElementFromNode(NSDictionary* node);


id GTGoxStringFromValue(NSString* value);
id GTGoxVrixDataStringFromNode(NSDictionary* node);
id GTGoxVrixReferenceStringFromNode(NSDictionary* node);

id GTVMAPAdBreakFromNode(NSDictionary* node);
id GTVMAPAdSourceFromNode(NSDictionary* node);
id GTVMAPVASTAdDataFromNode(NSDictionary* node);
id GTVMAPVASTFromNode(NSDictionary* node);
id GTVMAPAdTagURIFromNode(NSDictionary* node);

id GTVASTAdFromNode(NSDictionary* node);

id GTGoxFloatFromValue(NSString *value);
id GTGoxLongLongFromValue(NSString *value);
id GTGoxPointFromValue(NSString *value);
id GTGoxIntegerFromValue(NSString* value);
id GTGoxBooleanFromValue(NSString *value);

id GTConvertTimeIntervalTypeFromString(NSString *time);
id GTConvertTimeIntervalFromString(NSString *time);
          
NSString *identifierForAdvertising(void);
