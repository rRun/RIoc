//
//  ApplicationContext.m
//  FBSnapshotTestCase
//
//  Created by 何霞雨 on 2018/1/14.
//

#import "ApplicationContext.h"
#import "XmlManager.h"

@interface ApplicationContext()

@property (nonatomic,strong) XmlManager *xmlManager;

@end

@implementation ApplicationContext


static id _sharedInstance;
+ (instancetype)sharedApplicationContext{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[[self class] alloc] init];
    });
    return _sharedInstance;
}


- (instancetype)init
{
    self = [super init];
    if (self) {
        self.xmlManager = [XmlManager sharedXMLManager];
        
    }
    return self;
}

- (NSObject *)getBean:(id)bean_id {
    XMLBean *xmlBean = [self.xmlManager getBeanById:bean_id];
    if (xmlBean) {
        return [xmlBean getObject];
    }
    return nil;
}

- (NSObject *)getBean:(NSString *)bean_id class:(Class)bean_clazz {
    XMLBean *xmlBean = [self.xmlManager getBeanById:bean_id];
    if (!xmlBean) {
        xmlBean = [self.xmlManager getBeanByClass:NSStringFromClass(bean_clazz)];
    }
    if (xmlBean) {
        return [xmlBean getObject];
    }
    return nil;
}

- (NSObject *)getBean:(NSString *)bean_id args:(NSArray *)args {
    return nil;
}

- (Boolean)containsBean:(NSString *)bean_name {
    return false;
}

- (Class)getType:(NSString *)bean_name {
    return nil;
}

- (Boolean)isSingleton:(NSString *)bean_name {
    return false;
}


- (Boolean)isTypeMatch:(NSString *)bean_name {
    return false;
}
- (Boolean)isPrototype:(NSString *)bean_name {
    return false;
    
}

- (NSArray<NSString *> *)getAliases:(NSString *)bean_name {
    return nil;
}


@end
