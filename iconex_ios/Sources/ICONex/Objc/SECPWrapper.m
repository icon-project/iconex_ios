//
//  SECPWrapper.m
//  ios-iCONex
//
//  Copyright © 2018 theloop, Inc. All rights reserved.
//

#import "SECPWrapper.h"

@interface NSData (NSData_Conversion)

#pragma mark - String Conversion
- (NSString *)hexadecimalString;

@end

@implementation NSData (NSData_Conversion)

#pragma mark - String Conversion
- (NSString *)hexadecimalString {
    /* Returns hexadecimal string of NSData. Empty string if data is empty.   */
    
    const unsigned char *dataBuffer = (const unsigned char *)[self bytes];
    
    if (!dataBuffer)
        return [NSString string];
    
    NSUInteger          dataLength  = [self length];
    NSMutableString     *hexString  = [NSMutableString stringWithCapacity:(dataLength * 2)];
    
    for (int i = 0; i < dataLength; ++i)
        [hexString appendString:[NSString stringWithFormat:@"%02lx", (unsigned long)dataBuffer[i]]];
    
    return [NSString stringWithString:hexString];
}

@end

@interface NSString (NSString_HEX)

- (NSData *)dataFromHexString;

@end

@implementation NSString (NSString_HEX)

- (NSData *)dataFromHexString {
//    const char *chars = [self UTF8String];
//    int i = 0, len = self.length;
//
//    NSMutableData *data = [NSMutableData dataWithCapacity:len / 2];
//    char byteChars[3] = {'\0','\0','\0'};
//    unsigned long wholeByte;
//
//    while (i < len) {
//        byteChars[0] = chars[i++];
//        byteChars[1] = chars[i++];
//        wholeByte = strtoul(byteChars, NULL, 16);
//        [data appendBytes:&wholeByte length:1];
//    }
//
//    return data;
    
    NSMutableData *commandToSend= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    int i;
    for (i=0; i < [self length]/2; i++) {
        byte_chars[0] = [self characterAtIndex:i*2];
        byte_chars[1] = [self characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [commandToSend appendBytes:&whole_byte length:1];
    }
    
    return commandToSend;
}

@end

@implementation SECPWrapper

+ (void)test
{
    NSString *privateKey = @"e67ab3ed3b796cd1bee5410585b238d310b9648e7615f998875983f906d7bfd8";
    NSString *message = @"hello";
    
    NSData *prv = [privateKey dataFromHexString];
    NSData *msg = [message dataUsingEncoding:NSUTF8StringEncoding];
    int ret;
    
    uint32_t flags = SECP256K1_CONTEXT_SIGN | SECP256K1_CONTEXT_VERIFY;
    secp256k1_context *context = secp256k1_context_create(flags);
    
    secp256k1_ecdsa_signature sign;
    
    ret = secp256k1_ecdsa_sign(context, &sign, msg.bytes, prv.bytes, NULL, NULL);
    
//    NSLog(@"ret: %d", ret);
    
    if (ret == 1) {
//        NSData *data = [NSData dataWithBytes:sign.data length:64];
//        NSString *sig = [data hexadecimalString];
//        NSLog(@"sig: %lu\n%@", (unsigned long)sig.length, sig);
        
        size_t outputSize = 256;
        uint8_t* output = (uint8_t *)malloc(outputSize);
        ret = secp256k1_ecdsa_signature_serialize_der(context, output, &outputSize, &sign);
        
        secp256k1_context_destroy(context);
    }
}

+ (NSString *)ecdsa_create_publicKey:(NSString *)privateKey
{
    int ret;
    NSData *privKey = [privateKey dataFromHexString];
    uint32_t flags = SECP256K1_CONTEXT_SIGN;
    secp256k1_context *ctx = secp256k1_context_create(flags);
    
    secp256k1_pubkey rawPubkey;
    
    ret = secp256k1_ec_pubkey_create(ctx, &rawPubkey, privKey.bytes);
    
        uint8_t serializedPubkey[65];
        size_t serializedPubkeySize = sizeof(serializedPubkey);
    if (ret == 1) {
        ret = secp256k1_ec_pubkey_serialize(ctx, serializedPubkey, &serializedPubkeySize, &rawPubkey, SECP256K1_EC_UNCOMPRESSED);

//        NSData *raw = [NSData dataWithBytes:rawPubkey.data length:sizeof(rawPubkey.data)];
//        NSLog(@"raw pubkey: %@", [raw hexadecimalString]);
        
        secp256k1_context_destroy(ctx);
        return [[NSData dataWithBytes:serializedPubkey length:sizeof(serializedPubkey)] hexadecimalString];
    }
    
    secp256k1_context_destroy(ctx);
    return nil;
}

+ (void)ecdsa_recoverable_sign:(NSString *)privateKey hashedMessage:(NSData *)hashed rsign:(NSData *__autoreleasing *)rsign ser_rsign:(NSData *__autoreleasing *)ser_rsign recid:(NSString *__autoreleasing *)recoverId
{
    int ret = 0;
//    NSData *msg = [hashed dataUsingEncoding:NSUTF8StringEncoding];
    NSData *privkey = [privateKey dataFromHexString];
    uint32_t flags = SECP256K1_CONTEXT_SIGN | SECP256K1_CONTEXT_VERIFY;
    secp256k1_context* ctx = secp256k1_context_create(flags);
    
    secp256k1_ecdsa_recoverable_signature rsig;
    
    ret = secp256k1_ecdsa_sign_recoverable(ctx, &rsig, hashed.bytes, privkey.bytes, NULL, NULL);
    
    if (ret != 1) {
//        NSLog(@"sign_recoverble ret: %d", ret);
        secp256k1_context_destroy(ctx);
        return;
    }
    
    uint8_t ser_rsig[65];
    int recid;
    ret = secp256k1_ecdsa_recoverable_signature_serialize_compact(ctx, ser_rsig, &recid, &rsig);
    
    if (ret != 1) {
//        NSLog(@"signature_seraialize_compact ret: %d", ret);
        secp256k1_context_destroy(ctx);
        return;
    }
    
    *ser_rsign = [NSData dataWithBytes:ser_rsig length:sizeof(ser_rsig)];
    
//    NSLog(@"objc ser_rsign: %@, %d", *ser_rsign, recid);
    *recoverId = [NSString stringWithFormat:@"%d", recid];
    
//    secp256k1_ecdsa_signature sig;
//
//    ret = secp256k1_ecdsa_recoverable_signature_convert(ctx, &sig, &rsig);
//
//    NSLog(@"ret: %d", ret);
//    if (ret != 1) {
//        NSLog(@"signature_convert ret: %d", ret);
//        secp256k1_context_destroy(ctx);
//        return;
//    }
    
    secp256k1_pubkey pubkey;
    ret = secp256k1_ecdsa_recover(ctx, &pubkey, &rsig, hashed.bytes);
    
//    NSLog(@"ret2: %d", ret);
    if (ret != 1) {
//        NSLog(@"recover ret: %d", ret);
        secp256k1_context_destroy(ctx);
        return;
    }
    
//    NSData *pubKey = [NSData dataWithBytes:pubkey.data length:sizeof(pubkey.data)];
//    NSLog(@"recovered pubkey: %@", [pubKey hexadecimalString]);
    
    *rsign = [NSData dataWithBytes:rsig.data length:sizeof(rsig.data)];

    secp256k1_context_destroy(ctx);
}

+ (NSString *)ecdsa_verify_publickey:(NSData *)hashed rsign:(NSString *)rsign
{
    NSData *rsignData = [rsign dataFromHexString];
//    NSData *msg = [hashsed dataUsingEncoding:NSUTF8StringEncoding];
    uint32_t flags = SECP256K1_CONTEXT_VERIFY;
    
    secp256k1_context *ctx = secp256k1_context_create(flags);
    
    secp256k1_pubkey pubkey;
    secp256k1_ecdsa_recoverable_signature rsig;// = { (unsigned char)(rsignData.bytes) };
    
    [rsignData getBytes:rsig.data length:rsignData.length];
    
    int ret = secp256k1_ecdsa_recover(ctx, &pubkey, &rsig, hashed.bytes);
    
    uint8_t serializedPubkey[65];
    size_t serializedPubkeySize = sizeof(serializedPubkey);
    ret = secp256k1_ec_pubkey_serialize(ctx, serializedPubkey, &serializedPubkeySize, &pubkey, SECP256K1_EC_UNCOMPRESSED);
    
    secp256k1_context_destroy(ctx);
    
    return [[NSData dataWithBytes:serializedPubkey length:sizeof(serializedPubkey)] hexadecimalString];
}

+ (void)ecdsa_recoverable_sign_test:(NSString *)privateKey hashedMessage:(NSString *)hashed signature:(NSString **)sign
{
    int ret;
    NSData *msg = [hashed dataUsingEncoding:NSUTF8StringEncoding];
    NSData *privkey = [privateKey dataFromHexString];
    uint32_t flags = SECP256K1_CONTEXT_SIGN | SECP256K1_CONTEXT_VERIFY;
    secp256k1_context* ctx = secp256k1_context_create(flags);
    
    secp256k1_ecdsa_recoverable_signature rsig;
    
    secp256k1_pubkey rawPubkey;
    // Creation will fail if the secret key is invalid.
    ret = secp256k1_ec_pubkey_create(ctx, &rawPubkey, privkey.bytes);
    
//    NSLog(@"\npubkey_create: %d\n\t%@\n\n", ret, [[NSData dataWithBytes:rawPubkey.data length:sizeof(rawPubkey.data)] hexadecimalString]);
    
    
    uint8_t serializedPubkey[65];
    size_t serializedPubkeySize = sizeof(serializedPubkey);
    ret = secp256k1_ec_pubkey_serialize(ctx, serializedPubkey, &serializedPubkeySize, &rawPubkey, SECP256K1_EC_UNCOMPRESSED);
    
    

//    NSLog(@"\npubkey_serialize: %d\n\tserializedPubkey: %@\n\trawPubkey: %@\n\n", ret, [[NSData dataWithBytes:serializedPubkey length:sizeof(serializedPubkey)] hexadecimalString], [[NSData dataWithBytes:rawPubkey.data length:sizeof(rawPubkey)] hexadecimalString]);

    
    
    ret = secp256k1_ecdsa_sign_recoverable(ctx, &rsig, msg.bytes, privkey.bytes, NULL, NULL);

    
    
//    NSLog(@"\nsign_recoverable: %d\n\trsig: %@\n\n", ret, [[NSData dataWithBytes:rsig.data length:sizeof(rsig.data)] hexadecimalString]);
    
    
    
//    uint8_t ser_rsig[65];
//    int recid;
//    ret = secp256k1_ecdsa_recoverable_signature_serialize_compact(ctx, ser_rsig, &recid, &rsig);
//    
//    
//    
//    NSLog(@"\nsignature_serialize_compact: %d \n\tser_rsig: %@\n\trecid: %d\n\trsig: %@\n\n", ret, [[NSData dataWithBytes:ser_rsig length:sizeof(ser_rsig)] hexadecimalString], recid, [[NSData dataWithBytes:rsig.data length:sizeof(rsig.data)] hexadecimalString]);
    
    secp256k1_ecdsa_signature sig;
    
    ret = secp256k1_ecdsa_recoverable_signature_convert(ctx, &sig, &rsig);
    
    
    
//    NSLog(@"\nsignature_convert: %d\n\tsig: %@\n\trsig: %@\n\n", ret, [[NSData dataWithBytes:sig.data length:sizeof(sig.data)] hexadecimalString], [[NSData dataWithBytes:rsig.data length:sizeof(rsig.data)] hexadecimalString]);
    
    
    
    secp256k1_pubkey pubkey;
    ret = secp256k1_ecdsa_recover(ctx, &pubkey, &rsig, msg.bytes);
    
    
//    NSLog(@"\nrecover: %d\n\t%@", ret, [[NSData dataWithBytes:pubkey.data length:sizeof(pubkey.data)] hexadecimalString]);
    
    secp256k1_context_destroy(ctx);
}

@end

