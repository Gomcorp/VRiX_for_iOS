//
//  GTVMAP.m
//  GoxEntry
//
//  Created by Youngchang koo on 2016. 5. 10..
//  Copyright © 2016년 Youngchang koo. All rights reserved.
//

#import "GTVMAP.h"
#import "GTVAST.h"

#import "GTGoxImporterUtil.h"
#import "GTGoxConstants.h"

#import "XMLDictionary.h"
#import <objc/message.h>

#import "NSString+InvalidChar.h"
#import "XMLDictionary.h"

#import "Statistics.h"

#import "GXAdManager.h"

#import "VRiXManager.h"

#define GTVMAPCurrentEncoding NSUTF8StringEncoding

static GTGoxImporterUtil const  _vmapAttributesImporterUtil[];
static NSInteger const          _vmapNumberOfAttributesImporterUtil;
static GTGoxImporter2Util const  _vmapElementImportUtil[];
static NSInteger const          _vmapNumberOfElementImportUtil;

static GTGoxImporterUtil const  _adBreakAttributesImporterUtil[];
static NSInteger const          _adBreakNumberOfAttributesImporterUtil;
static GTGoxImporter2Util const  _adBreakElementImportUtil[];
static NSInteger const          _adBreakNumberOfElementImportUtil;

static GTGoxImporterUtil const  _adSourceAttributesImporterUtil[];
static NSInteger const          _adSourceNumberOfAttributesImporterUtil;
static GTGoxImporter2Util const  _adSourceElementImportUtil[];
static NSInteger const          _adSourceNumberOfElementImportUtil;

static GTGoxImporterUtil const  _adTagURIAttributesImporterUtil[];
static NSInteger const          _adTagURINumberOfAttributesImporterUtil;

static GTGoxImporterUtil const  _adDataAttributesImporterUtil[];
static NSInteger const          _adDataNumberOfAttributesImporterUtil;
static GTGoxImporter2Util const  _adDataElementImportUtil[];
static NSInteger const          _adDataNumberOfElementImportUtil;

@interface GTNodeObject ()

@end

@implementation GTNodeObject

- (id)initWithElement:(NSDictionary *)element
{
    self = [super init];
    
    if(self != nil)
    {
        NSDictionary* xmlDocument = element;
        
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
    // 반드시 상속받아 처리한다.
    return YES;
}

@end

@interface GTVMAP ()

@end

@implementation GTVMAP
- (BOOL)GT_setPropertiesFromDocument
{
    return YES;
}

- (id)initWithElement:(NSDictionary *)element
{
    _adBreakList = [[NSMutableArray alloc] init];
    
    if ([[element valueForKey:GTVMAPAttributeName] caseInsensitiveCompare:GTVMAPElementVMAP] == NSOrderedSame)
    {
        self = [super initWithElement:element];
    }
    else
    {
        GTVAST *vast = [[GTVAST alloc] initWithElement:element];
        
        // VAST로 바로 들어올경우
        if (vast !=nil)
        {
            GTVMAPAdBreak *adBreak = [[GTVMAPAdBreak alloc] init];
            [adBreak setOffsetType:GTTimeOffsetTypeStart];
            
            GTVMAPAdSource *adSource = [[GTVMAPAdSource alloc] init];
            GTVASTAdData *adData = [[GTVASTAdData alloc] init];
            
            [adData setVast:vast];
            
            for (int i = 0; i<vast.adList.count; i++) {
                [adSource setVastData:adData];
                [adBreak setAdSource:adSource];
            
                [self.adBreakList addObject:adBreak];
            }
        }
    }
    
    
    return self;
}

- (BOOL) setPropertiesFromDocument
{
    NSDictionary *vmapElement = self.xmlDocument;
    
    if(![vmapElement isKindOfClass:[NSDictionary class]])
    {
        return NO;
    }
    
    for(NSInteger index = 0; index < _vmapNumberOfAttributesImporterUtil; index++)
    {
        GTGoxImporterUtil importerUtil = _vmapAttributesImporterUtil[index];
        NSString *name = [NSDictionary changeAttributename:importerUtil.attributeName];
        id attributeValue = [vmapElement valueForKeyPath:name];
        if(attributeValue != nil)
        {
            importerUtil.setter(self, importerUtil.propertyName, importerUtil.converter(attributeValue));
        }
    }
    
    for(NSInteger index = 0; index < _vmapNumberOfElementImportUtil; index++)
    {
        GTGoxImporter2Util importerUtil = _vmapElementImportUtil[index];
        for(id element in [vmapElement arrayValueForKeyPath:importerUtil.attributeName])
        {
            importerUtil.setter(self, importerUtil.propertyName, importerUtil.converter(element));
        }
    }
    
    return YES;
}

- (id)initWithVMAPString:(NSString*)vmapString
{
    self = [super init];
    
    if(self != nil)
    {
        vmapString = [vmapString validXMLString];
        
        if([vmapString length] > 0)
        {
            NSDictionary* xmlDocument = [NSDictionary dictionaryWithXMLString:vmapString];
            
            if (xmlDocument == nil && vmapString != nil)
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
    NSHTTPURLResponse *response = nil;
    NSError *error = nil;
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    [request addValue:identifierForAdvertising() forHTTPHeaderField:GTGoxHeaderKeyAAID];
    [request setValue:[Statistics userAgent] forHTTPHeaderField:@"User-Agent"];
    
    NSData* data = [self sendSynchronousRequest:request
                              returningResponse:&response
                                          error:&error];
    
    if(data == nil) {
        NSError * stringError = nil;
        NSString * content = [NSString stringWithContentsOfFile:url.path encoding:NSUTF8StringEncoding error:&stringError];

        data = [content dataUsingEncoding:NSUTF8StringEncoding];
    }
    
    NSInteger length = [data length];
    char* newCString = (char*)malloc(length + 1);
    memset(newCString, 0, length + 1);
    memcpy(newCString, [data bytes], length);
    
    NSString* resultString = [NSString stringWithCString:newCString
                                                encoding:GTVMAPCurrentEncoding];
    
    if (resultString != nil && [resultString length] != 0)
    {
        self = [self initWithVMAPString:resultString];
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


- (BOOL) needShowADSection
{
    if (_adsection == nil || [_adsection isEqualToString:@"view"])
    {
        return YES;
    }
    
    return NO;
}
@end

@class GTVMAPAdSource;

@interface GTVMAPAdBreak()
@property (nonatomic, strong) GTVAST *currentVast;

@end

@implementation GTVMAPAdBreak 

- (id)initWithElement:(NSDictionary *)element
{
    self = [super initWithElement:element];
    
    if(self == nil)
    {
        return nil;
    }
    
    return self;
}

- (BOOL) setPropertiesFromDocument
{
    NSDictionary *vmapElement = self.xmlDocument;
    
    if(![vmapElement isKindOfClass:[NSDictionary class]])
    {
        return NO;
    }
    
    for(NSInteger index = 0; index < _adBreakNumberOfAttributesImporterUtil; index++)
    {
        GTGoxImporterUtil importerUtil = _adBreakAttributesImporterUtil[index];
        NSString *name = [NSDictionary changeAttributename:importerUtil.attributeName];
        id attributeValue = [vmapElement valueForKeyPath:name];
        if(attributeValue != nil)
        {
            importerUtil.setter(self, importerUtil.propertyName, importerUtil.converter(attributeValue));
        }
    }
    
    for(NSInteger index = 0; index < _adBreakNumberOfElementImportUtil; index++)
    {
        GTGoxImporter2Util importerUtil = _adBreakElementImportUtil[index];
        for(id element in [vmapElement arrayValueForKeyPath:importerUtil.attributeName])
        {
            importerUtil.setter(self, importerUtil.propertyName, importerUtil.converter(element));
        }
    }
    
    return YES;
}

- (void) setOffsetType:(GTTimeOffsetType)offsetType
{
    _offsetType = offsetType;
}

- (void) excuteAdAtTargetView:(UIView *)view
       advertisementCompleted:(void (^)(BOOL result, NSString *networkType))adCompleted
                   completion:(void (^)(BOOL, id))completion
{
    self.currentVast = self.adSource.vastData.vast;
    if (_currentVast == nil)
    {
        
        NSURL *url = [NSURL URLWithString:self.adSource.adTagURI.vastURL];
        if(url != nil)
        {
            [self.adSource.adTagURI setVast:[[GTVAST alloc] initWithURL:url]];
        }
    

        self.currentVast = self.adSource.adTagURI.vast;
    }
    
    
    if (self.currentVast == nil)
    {
        completion(NO, nil);
    }
    else
    {
        [_currentVast excuteVastTarget:view advertisementCompleted:adCompleted completion:^(BOOL success, id userInfo) {
            //
            completion(success, userInfo);
        }];
    }
}

- (void) cancelExcute
{
    [_currentVast cancelExcuteVast];
}


@end

@implementation GTVMAPAdSource
- (id)initWithElement:(NSDictionary *)element
{
    self = [super initWithElement:element];
    
    if(self == nil)
    {
        return nil;
    }
    
    return self;
}

- (BOOL) setPropertiesFromDocument
{
    NSDictionary *vmapElement = self.xmlDocument;
    
    if(![vmapElement isKindOfClass:[NSDictionary class]])
    {
        return NO;
    }
    
    for(NSInteger index = 0; index < _adSourceNumberOfAttributesImporterUtil; index++)
    {
        GTGoxImporterUtil importerUtil = _adSourceAttributesImporterUtil[index];
        NSString *name = [NSDictionary changeAttributename:importerUtil.attributeName];
        id attributeValue = [vmapElement valueForKeyPath:name];
        if(attributeValue != nil)
        {
            importerUtil.setter(self, importerUtil.propertyName, importerUtil.converter(attributeValue));
        }
    }
    
    for(NSInteger index = 0; index < _adSourceNumberOfElementImportUtil; index++)
    {
        GTGoxImporter2Util importerUtil = _adSourceElementImportUtil[index];
        for(id element in [vmapElement arrayValueForKeyPath:importerUtil.attributeName])
        {
            importerUtil.setter(self, importerUtil.propertyName, importerUtil.converter(element));
        }
    }
    
    return YES;
}
@end

@class GTVAST;
@implementation GTVMAPAdTagURI

- (id)initWithElement:(NSDictionary *)element
{
    self = [super initWithElement:element];
    
    if(self == nil)
    {
        return nil;
    }
    
    return self;
}

- (BOOL) setPropertiesFromDocument
{
    NSDictionary *vmapElement = self.xmlDocument;
    
    if(![vmapElement isKindOfClass:[NSDictionary class]])
    {
        return NO;
    }
    
    for(NSInteger index = 0; index < _adTagURINumberOfAttributesImporterUtil; index++)
    {
        GTGoxImporterUtil importerUtil = _adTagURIAttributesImporterUtil[index];
        NSString *name = [NSDictionary changeAttributename:importerUtil.attributeName];
        id attributeValue = [vmapElement valueForKeyPath:name];
        if(attributeValue != nil)
        {
            importerUtil.setter(self, importerUtil.propertyName, importerUtil.converter(attributeValue));
        }
    }
    
    _vastURL = [vmapElement innerText];
    
    return YES;
}


@end


@implementation GTVASTAdData

- (id)initWithElement:(NSDictionary *)element
{
    self = [super initWithElement:element];
    
    if(self == nil)
    {
        return nil;
    }
    
    return self;
}

- (BOOL) setPropertiesFromDocument
{
    NSDictionary *vmapElement = self.xmlDocument;
    
    if(![vmapElement isKindOfClass:[NSDictionary class]])
    {
        return NO;
    }
    
    for(NSInteger index = 0; index < _adDataNumberOfAttributesImporterUtil; index++)
    {
        GTGoxImporterUtil importerUtil = _adDataAttributesImporterUtil[index];
        NSString *name = [NSDictionary changeAttributename:importerUtil.attributeName];
        id attributeValue = [vmapElement valueForKeyPath:name];
        if(attributeValue != nil)
        {
            importerUtil.setter(self, importerUtil.propertyName, importerUtil.converter(attributeValue));
        }
    }
    
    for(NSInteger index = 0; index < _adDataNumberOfElementImportUtil; index++)
    {
        GTGoxImporter2Util importerUtil = _adDataElementImportUtil[index];
        for(id element in [vmapElement arrayValueForKeyPath:importerUtil.attributeName])
        {
            importerUtil.setter(self, importerUtil.propertyName, importerUtil.converter(element));
        }
    }
    
    return YES;
}

@end

#pragma mark - vmap
static GTGoxImporterUtil const _vmapAttributesImporterUtil[] =
{
    { GTGoxAttributeVersion,  GTGoxPropertyVersion,      GTGoxSetValue,                          GTGoxStringFromValue },
    { GTGoxAttributeADSection,GTGoxPropertyADSection,      GTGoxSetValue,                          GTGoxStringFromValue },
    
};
static NSInteger const _vmapNumberOfAttributesImporterUtil = sizeof(_vmapAttributesImporterUtil) / sizeof(_vmapAttributesImporterUtil[0]);

static GTGoxImporter2Util const _vmapElementImportUtil[] =
{
    { GTVMAPElementAdBreak,          GTVMAPPropertyAdBreak,           GTGoxAddObject,           GTVMAPAdBreakFromNode },
};

static NSInteger const _vmapNumberOfElementImportUtil = sizeof(_vmapElementImportUtil) / sizeof(_vmapElementImportUtil[0]);

#pragma mark - adBreak
static GTGoxImporterUtil const  _adBreakAttributesImporterUtil[] =
{
    { GTVMAPAttributeBreakType,         GTVMAPPropertyBreakType,            GTGoxSetValue,                          GTGoxStringFromValue },
    { GTVMAPAttributeBreakid,           GTVMAPPropertyBreakId,              GTGoxSetValue,                          GTGoxStringFromValue },
    { GTVMAPAttributeBreakTimeOffset,   GTVMAPPropertyBreakTimeOffsetType,  GTGoxSetInteger,                        GTConvertTimeIntervalTypeFromString },
    { GTVMAPAttributeBreakTimeOffset,   GTVMAPPropertyBreakTimeOffset,      GTGoxSetTimeIntervalFromMicroSecond,    GTConvertTimeIntervalFromString },
    
    
};

static NSInteger const          _adBreakNumberOfAttributesImporterUtil = sizeof(_adBreakAttributesImporterUtil) / sizeof(_adBreakAttributesImporterUtil[0]);

static GTGoxImporter2Util const  _adBreakElementImportUtil[] =
{
    { GTVMAPElementAdSource,          GTVMAPPropertyAdSource,        GTGoxSetValue,                 GTVMAPAdSourceFromNode },
};

static NSInteger const          _adBreakNumberOfElementImportUtil = sizeof(_adBreakElementImportUtil) / sizeof(_adBreakElementImportUtil[0]);

#pragma mark - adSource
static GTGoxImporterUtil const  _adSourceAttributesImporterUtil[] =
{
    { GTVMAPAttributeAllowMultipleAds,    GTVMAPPropertyAllowMultipleAds,     GTGoxSetValue,           GTGoxBooleanFromValue },
    { GTVMAPAttributeFollowRedirects,     GTVMAPPropertyFollowRedirects,      GTGoxSetValue,           GTGoxBooleanFromValue },
    { GTVMAPAttributeId,                  GTVMAPPropertyId,                   GTGoxSetValue,           GTGoxStringFromValue },
    
};
static NSInteger const          _adSourceNumberOfAttributesImporterUtil = sizeof(_adSourceAttributesImporterUtil) / sizeof(_adSourceAttributesImporterUtil[0]);

static GTGoxImporter2Util const  _adSourceElementImportUtil[] =
{
    { GTVMAPElementVASTAdData,      GTVMAPPropertyAdVASTAdData,             GTGoxSetValue,            GTVMAPVASTAdDataFromNode },
    { GTVMAPElementAdTagURI,        GTVMAPPropertyAdTagURI,                 GTGoxSetValue,            GTVMAPAdTagURIFromNode },
    
};

static NSInteger const          _adSourceNumberOfElementImportUtil = sizeof(_adSourceElementImportUtil) / sizeof(_adSourceElementImportUtil[0]);


#pragma mark - adTagURI
static GTGoxImporterUtil const  _adTagURIAttributesImporterUtil[] =
{
    { GTGoxAttributeVersion,  GTGoxPropertyVersion,      GTGoxSetValue,                          GTGoxStringFromValue },
    
};
static NSInteger const          _adTagURINumberOfAttributesImporterUtil = sizeof(_adTagURIAttributesImporterUtil) / sizeof(_adTagURIAttributesImporterUtil[0]);


#pragma mark - vastAdData
static GTGoxImporterUtil const  _adDataAttributesImporterUtil[] =
{
    { GTGoxAttributeVersion,  GTGoxPropertyVersion,      GTGoxSetValue,                          GTGoxStringFromValue },
    
};
static NSInteger const          _adDataNumberOfAttributesImporterUtil = sizeof(_adDataAttributesImporterUtil) / sizeof(_adDataAttributesImporterUtil[0]);
static GTGoxImporter2Util const  _adDataElementImportUtil[] =
{
    { GTVMAPElementVAST,      GTVMAPPropertyVAST,        GTGoxSetValue,                          GTVMAPVASTFromNode },    
};
static NSInteger const          _adDataNumberOfElementImportUtil = sizeof(_adDataElementImportUtil) / sizeof(_adDataElementImportUtil[0]);

