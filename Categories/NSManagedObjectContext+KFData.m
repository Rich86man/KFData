//
// NSManagedObjectContext+KFData.m
// KFData
//
// Created by Kyle Fuller on 26/11/2012
// Copyright (c) 2012 Kyle Fuller. All rights reserved
//

#import "NSManagedObjectContext+KFData.h"

@implementation NSManagedObjectContext (KFData)

- (BOOL)save {
    BOOL saved = NO;

    if ([self hasChanges]) {
        NSError *error;

        @try {
            saved = [self save:&error];
        } @catch (NSException *exception) {
            NSLog(@"KFData - [NSManagedObjectContext save] (%@)", exception);
        }

        if (saved == NO) {
            NSLog(@"KFData - [NSManagedObjectContext save] (%@)", error);
        }
    }

    return saved;
}

- (BOOL)nestedSave:(NSError **)error {
    BOOL hasChanges = [self hasChanges];

    __block BOOL saved = [self save:error];

    if (saved && hasChanges) {
        NSManagedObjectContext *parentContext = [self parentContext];

        [parentContext performBlockAndWait:^{
            saved = [parentContext nestedSave:error];
        }];
    }

    return saved;
}

- (void)performSave {
    if ([self hasChanges]) {
        [self performBlock:^{
            BOOL saved = NO;
            NSError *error;
            
            @try {
                saved = [self save:&error];
            } @catch (NSException *exception) {
                NSLog(@"KFData - [NSManagedObjectContext save] (%@)", exception);
            }
            
            if (saved == NO) {
                NSLog(@"KFData - [NSManagedObjectContext save] (%@)", error);
            }
        }];
    }
}

- (void)performNestedSave {
    [self performBlock:^{
        if ([self save]) {
            NSManagedObjectContext *parentContext = [self parentContext];
            [parentContext performNestedSave];
        }
    }];
}

#pragma mark -

- (void)performWriteBlock:(void(^)(void))writeBlock {
    [self performBlock:^{
        writeBlock();

        NSError *error;
        [self nestedSave:&error];

        if (error) {
            @throw [NSException exceptionWithName:@"KFData performWriteBlock error"
                                           reason:[error localizedDescription]
                                         userInfo:@{@"error":error}];
        }
    }];
}

- (void)performWriteBlock:(void(^)(void))writeBlock
                  success:(void(^)(void))success
                  failure:(void(^)(NSError *error))failure
{
    [self performBlock:^{
        writeBlock();

        NSError *error;
        BOOL isSuccessful = [self nestedSave:&error];

        if (isSuccessful) {
            if (success) {
                success();
            }
        } else if (failure) {
            failure(error);
        }
    }];
}

@end

