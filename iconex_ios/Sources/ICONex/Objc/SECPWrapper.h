//
//  SECPWrapper.h
//  ios-iCONex
//
//  Copyright © 2018 theloop, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <secp256k1_ios/secp256k1.h>
#import <secp256k1_ios/secp256k1_recovery.h>

@interface SECPWrapper : NSObject

+ (NSString *)ecdsa_create_publicKey:(NSString *)privateKey;
//+ (void)ecdsa_recoverable_sign:(NSString *)privateKey hashedMessage:(NSData *)hashed signature:(NSData **)sign rsign:(NSData **)rsign ser_rsign:(NSData **)ser_rsign;
+ (void)ecdsa_recoverable_sign:(NSString *)privateKey hashedMessage:(NSData *)hashed rsign:(NSData **)rsign ser_rsign:(NSData **)ser_rsign recid:(NSString **)recid;
+ (NSString *)ecdsa_verify_publickey:(NSData *)hashed rsign:(NSString *)rsign;

@end
