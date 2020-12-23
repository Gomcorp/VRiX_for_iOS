//
//  NSString+InvalidChar.m
//  TwoGOM
//
//  Created by Seung-Han Kim on 12. 4. 20..
//  Copyright (c) 2012년 le5na81@gmail.com. All rights reserved.
//

#import "NSString+InvalidChar.h"

@implementation NSString (InvalidChar)

- (NSString *)validXMLString
{
	// Not all UTF8 characters are valid XML.
	// See:
	// http://www.w3.org/TR/2000/REC-xml-20001006#NT-Char
	// (Also see: http://cse-mjmcl.cse.bris.ac.uk/blog/2007/02/14/1171465494443.html )
	//
	// The ranges of unicode characters allowed, as specified above, are:
	// Char ::= #x9 | #xA | #xD | [#x20-#xD7FF] | [#xE000-#xFFFD] | [#x10000-#x10FFFF] /* any Unicode character, excluding the surrogate blocks, FFFE, and FFFF. */
	//
	// To ensure the string is valid for XML encoding, we therefore need to remove any characters that
	// do not fall within the above ranges.
    
	// First create a character set containing all invalid XML characters.
	// Create this once and leave it in memory so that we can reuse it rather
	// than recreate it every time we need it.
	static NSCharacterSet *invalidXMLCharacterSet = nil;
    
	if (invalidXMLCharacterSet == nil)
	{
		// First, create a character set containing all valid UTF8 characters.
		NSMutableCharacterSet *XMLCharacterSet = [[NSMutableCharacterSet alloc] init];
		[XMLCharacterSet addCharactersInRange:NSMakeRange(0x9, 1)];
		[XMLCharacterSet addCharactersInRange:NSMakeRange(0xA, 1)];
		[XMLCharacterSet addCharactersInRange:NSMakeRange(0xD, 1)];
		[XMLCharacterSet addCharactersInRange:NSMakeRange(0x20, 0xD7FF - 0x20)];
		[XMLCharacterSet addCharactersInRange:NSMakeRange(0xE000, 0xFFFD - 0xE000)];
		[XMLCharacterSet addCharactersInRange:NSMakeRange(0x10000, 0x10FFFF - 0x10000)];
        
		// Then create and retain an inverted set, which will thus contain all invalid XML characters.
		invalidXMLCharacterSet = [XMLCharacterSet invertedSet];
	}
    
	// Are there any invalid characters in this string?
	NSRange range = [self rangeOfCharacterFromSet:invalidXMLCharacterSet];
    
	// If not, just return self unaltered.
	if (range.length == 0)
		return [self copy];
    
	// Otherwise go through and remove any illegal XML characters from a copy of the string.
	NSMutableString *cleanedString = [self mutableCopy];
    
	while (range.length > 0)
	{
		[cleanedString deleteCharactersInRange:range];
		range = [cleanedString rangeOfCharacterFromSet:invalidXMLCharacterSet];
	}
    
	return (NSString *)cleanedString;
}

- (BOOL)containsString:(NSString *)substring
{
    NSRange range = [self rangeOfString : substring];
    BOOL found = ( range.location != NSNotFound );
    return found;
}

@end
