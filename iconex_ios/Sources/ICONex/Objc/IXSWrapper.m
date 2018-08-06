//
//  IXSWrapper.m
//  ios-iCONex
//
//  Created by Jeonghwan Ahn on 09/07/2018.
//  Copyright © 2018 theloop, Inc. All rights reserved.
//

#import "IXSWrapper.h"
#import "iX.h"

@implementation IXSWrapper

+ (void)systemCheck:(NSError *__autoreleasing *)error
{
    struct ix_detected_pattern *patternInfo;
    int ret = ix_sysCheckStart(&patternInfo);
    
    if (ret == 1) {
        NSString *jbCode = [NSString stringWithUTF8String:patternInfo->pattern_type_id];
        
        if ([jbCode isEqualToString:@"0000"]) {
            *error = nil;
        } else {
            // Error code Check and App Exit.
            
            NSString *desc = [NSString stringWithUTF8String:patternInfo->pattern_desc];
            
            *error = [NSError errorWithDomain:desc code:-1 userInfo:@{@"code": jbCode}];
        }
    } else {
        *error = [NSError errorWithDomain:@"system check failed" code:ret userInfo:nil];
    }
}

+ (int)detectDebugger
{
    return ix_runAntiDebugger();
}

+ (void)intigrityCheck:(NSError *__autoreleasing *)error
{
    struct ix_init_info *initInfo = calloc(sizeof(struct ix_init_info), 1); // 초기값 및 옵션 셋팅
    struct ix_verify_info *verifyInfo; //결과 값
    
    initInfo->integrity_type = IX_INTEGRITY_LOCAL;
    int ret = ix_integrityCheck(initInfo, &verifyInfo);
    
    NSString *verifyData = [NSString stringWithCString:verifyInfo->verify_result encoding:NSUTF8StringEncoding];
    
    if (ret == 1) {
        NSString *succ = [NSString stringWithUTF8String:VERIFY_SUCC];
        if (![verifyData isEqualToString:succ]) {
            *error = [NSError errorWithDomain:verifyData code:-9999 userInfo:nil];
        }
    } else {
        *error = [NSError errorWithDomain:verifyData code:-9999 userInfo:nil];
    }
    
    if (initInfo) {
        free(initInfo);
        initInfo = NULL;
    }
}

+ (void)setDebug
{
    ix_set_debug();
}

@end
