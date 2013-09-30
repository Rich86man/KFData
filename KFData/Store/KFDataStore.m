//
//  KFDataStore.m
//  KFData
//
//  Created by Kyle Fuller on 20/10/2012.
//  Copyright (c) 2012-2013 Kyle Fuller. All rights reserved.
//

#import "KFDataStoreInternal.h"


NSString * const KFDataManagedObjectContextWillReset = @"KFDataManagedObjectContextWillReset";
NSString * const KFDataManagedObjectContextDidReset = @"KFDataManagedObjectContextDidReset";

static NSString * const kKFDataStoreLocalFilename = @"localStore.sqlite";
static NSString * const kKFDataStoreCloudFilename = @"cloudStore.sqlite";

@implementation KFDataStore

+ (instancetype)storeWithConfigurationType:(KFDataStoreConfigurationType)configurationType {
    NSManagedObjectModel *managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
    return [KFDataStore storeWithConfigurationType:configurationType managedObjectModel:managedObjectModel];
}

+ (instancetype)storeWithConfigurationType:(KFDataStoreConfigurationType)configurationType managedObjectModel:(NSManagedObjectModel*)managedObjectModel {
    KFDataStore *store;

    switch (configurationType) {
        case KFDataStoreConfigurationTypeSingleStack:
            store = [[KFDataSingleStackStore alloc] initWithManagedObjectModel:managedObjectModel];
            break;

        case KFDataStoreConfigurationTypeDualStack:
            store = [[KFDataDualStackStore alloc] initWithManagedObjectModel:managedObjectModel];
            break;

        case KFDataStoreConfigurationTypeSingleResetStack:
            store = [[KFDataSingleResetStackStore alloc] initWithManagedObjectModel:managedObjectModel];
            break;

        case KFDataStoreConfigurationTypeDualResetStack:
            store = [[KFDataDualResetStackStore alloc] initWithManagedObjectModel:managedObjectModel];
            break;
    }

    return store;
}

+ (NSURL*)storesDirectoryURL {
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSURL *storesDirectoryURL = [NSURL fileURLWithPath:documentsDirectory];
    storesDirectoryURL = [storesDirectoryURL URLByAppendingPathComponent:@"DataStores"];

    NSFileManager *fileManager = [[NSFileManager alloc] init];
    if ([fileManager fileExistsAtPath:[storesDirectoryURL path]] == NO) {
        NSError *error;

        BOOL createSuccess = [fileManager createDirectoryAtURL:storesDirectoryURL
                                   withIntermediateDirectories:YES
                                                    attributes:nil
                                                         error:&error];

        if (createSuccess == NO) {
            NSLog(@"KFData: Unable to create application sandbox stores directory: %@\n\tError: %@", storesDirectoryURL, error);
        }
    }

    return storesDirectoryURL;
}

+ (instancetype)standardLocalDataStore {
    KFDataStore *dataStore = [KFDataStore storeWithConfigurationType:KFDataStoreConfigurationTypeDualStack];

    NSDictionary *options = @{
        NSMigratePersistentStoresAutomaticallyOption: @YES,
        NSInferMappingModelAutomaticallyOption: @YES,
    };

    [dataStore addLocalStore:kKFDataStoreLocalFilename configuration:nil options:options error:nil];

    return dataStore;
}

+ (instancetype)standardMemoryDataStore {
    KFDataStore *dataStore = [KFDataStore storeWithConfigurationType:KFDataStoreConfigurationTypeSingleStack];
    [dataStore addMemoryStore:nil error:nil];
    return dataStore;
}

+ (instancetype)standardCloudDataStore {
    KFDataStore *dataStore = [KFDataStore storeWithConfigurationType:KFDataStoreConfigurationTypeSingleStack];
    [dataStore addCloudStore:kKFDataStoreCloudFilename configuration:nil contentNameKey:@"cloudStore" error:nil];
    return dataStore;
}

#pragma mark -

- (instancetype)initWithManagedObjectModel:(NSManagedObjectModel *)managedObjectModel {
    return [super init];
}

#pragma mark - Stores

- (NSPersistentStore *)addPersistentStoreWithType:(NSString *)storeType configuration:(NSString *)configuration URL:(NSURL *)storeURL options:(NSDictionary *)options error:(NSError **)error {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"addPersistentStoreWithType:configuration:URL:options:error: must be overidden." userInfo:nil];
}

- (NSPersistentStore *)addMemoryStore:(NSString *)configuration error:(NSError **)error {
    return [self addPersistentStoreWithType:NSInMemoryStoreType configuration:configuration URL:nil options:nil error:error];
}

- (NSPersistentStore *)addLocalStore:(NSString *)filename configuration:(NSString *)configuration options:(NSDictionary *)options error:(NSError **)error {
    NSURL *storesDirectoryURL = [KFDataStore storesDirectoryURL];
    NSURL *storeURL = [storesDirectoryURL URLByAppendingPathComponent:filename];
    return [self addPersistentStoreWithType:NSSQLiteStoreType configuration:configuration URL:storeURL options:options error:error];
}

- (NSPersistentStore *)addCloudStore:(NSString *)filename configuration:(NSString *)configuration contentNameKey:(NSString *)contentNameKey error:(NSError **)error {
    NSParameterAssert(filename != nil);
    NSParameterAssert(contentNameKey != nil);

    NSURL *storesDirectoryURL = [KFDataStore storesDirectoryURL];
    NSURL *storeURL = [storesDirectoryURL URLByAppendingPathComponent:filename];

    NSDictionary *options = @{
        NSPersistentStoreUbiquitousContentNameKey: contentNameKey,
    };

    NSPersistentStore *persistentStore = [self addPersistentStoreWithType:NSSQLiteStoreType configuration:configuration URL:storeURL options:options error:error];

    return persistentStore;
}

#pragma mark -

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"persistentStoreCoordinator must be overidden." userInfo:nil];
}

- (NSManagedObjectContext *)managedObjectContext {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"managedObjectContext must be overidden." userInfo:nil];
}

- (NSManagedObjectContext *)backgroundManagedObjectContext {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"backgroundManagedObjectContext must be overidden." userInfo:nil];
}

#pragma mark -

- (void)performReadBlock:(void (^) (NSManagedObjectContext *managedObjectContext))readBlock {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"performReadBlock: must be overidden." userInfo:nil];
}

- (void)performWriteBlock:(void(^)(NSManagedObjectContext *managedObjectContext))writeBlock success:(void(^)(void))success failure:(void(^)(NSError *error))failure {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"performWriteBlock:success:failure: must be overidden." userInfo:nil];
}

- (void)performWriteBlock:(void(^)(NSManagedObjectContext *managedObjectContext))writeBlock {
    [self performWriteBlock:writeBlock success:nil failure:nil];
}

@end