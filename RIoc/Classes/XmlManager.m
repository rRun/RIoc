//
//  XmlManager.m
//  FBSnapshotTestCase
//
//  Created by 何霞雨 on 2018/1/15.
//

#import "XmlManager.h"
#import "GDataXMLNode.h"


@interface XmlManager ()

@property (nonatomic,strong) GDataXMLDocument *rootXmlDoc;
@property (nonatomic,strong) GDataXMLElement *rootElement;
@property (nonatomic,strong) NSMutableArray<GDataXMLDocument*> *xmlDocArr;

@property (nonatomic,strong) NSMutableDictionary *iDBeanClassDic; //!< 将xml中所有的class通过ID缓存至字典
@property (nonatomic,strong) NSMutableDictionary *classBeanClassIDDic; //!< 将xml中所有的class通过classname缓存至字典
@property (nonatomic,strong) NSMutableArray *singletons; //!< 保存单例配置的对象
@property (nonatomic,strong) NSMutableArray *initializingClassPool; //!<初始化类池,非延迟创建

@end

#define __kBeanKey__ @"bean"
#define __kIdKey__ @"id"
#define __kClassNameKey__ @"class"
#define __kDelayInitKey__ @"delay-init"
#define __kScopeTypeSingleton__ @"singleton"
#define __kFactoryMethodKey__ @"factory-method"

#define __kPropertyKey__ @"property"
#define __kNameKey__ @"name"
#define __kRefKey__ @"ref"
#define __kRefClassKey__ @"ref-class"
#define __kAutowireKey__ @"autowire"


#define __kXMLPath__ @"c://"
@implementation XmlManager

static id _sharedInstance;
+ (instancetype)sharedXMLManager{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[[self class] alloc] init];
    });
    return _sharedInstance;
}

-(id)init{
    if (self) {
        //获取根xml
        self.rootXmlDoc = [self readXML:__kXMLPath__];
        self.rootElement = [self.rootXmlDoc rootElement];
        
        NSMutableArray<GDataXMLElement *> *mBeansArr = [NSMutableArray new];
        self.xmlDocArr = [NSMutableArray new];
        
        [self parseDocument:_rootElement];
        
        [self parseBeanElement];
        
        //启动时检查id及class
        self.iDBeanClassDic = [NSMutableDictionary new];
        self.classBeanClassIDDic = [NSMutableDictionary new];
        self.singletons = [NSMutableArray new];
        self.initializingClassPool = [NSMutableArray new];
        NSError *error;
        [self cacheClass:mBeansArr error:&error];
        if (error) {
            NSLog(@"%@",[[[error userInfo] allValues] objectAtIndex:0]);
        }
    }
    return self;
}

- (void)cacheClass:(NSArray<GDataXMLElement *> *) beans error:(NSError **)error{
    NSMutableDictionary *classDic = [NSMutableDictionary new];
    for (GDataXMLElement *element in beans)
    {
        XMLBean *beanClassModel = [XMLBean new];
        if ([element isMemberOfClass:[GDataXMLElement class]]) {
            //获取bean_id
            NSString *idValue = [[element attributeForName:__kIdKey__] stringValue];
            if (idValue) {
                if (![classDic valueForKey:idValue]) {
                    beanClassModel.ref_id = idValue;
                }else{
                    if (error) {
                        *error = [NSError errorWithDomain:@"com.ASTwinkle"
                                                     code:-1
                                                 userInfo:@{@"ErrorInfo":[NSString stringWithFormat:@"id<%@>重复定义",idValue]}];
                    }
                    return;
                }
            }
            
             //获取bean_class
            NSString *classNameValue = [[element attributeForName:__kClassNameKey__] stringValue];
            if (classNameValue) {
                Class class = NSClassFromString(classNameValue);
                
                if (!class) {
                    if (error) {
                        *error = [NSError errorWithDomain:@"com.fortis"
                                                     code:-1
                                                 userInfo:@{@"ErrorInfo":[NSString stringWithFormat:@"class<%@>加载失败",classNameValue]}];
                        return;
                    }
                }else{
                    beanClassModel.ref_class = class;
                }
            }
            
             //获取bean是否为单例
            NSString *singletonValue = [[element attributeForName:__kScopeTypeSingleton__] stringValue];
            Boolean isSingle = true;
            if ( singletonValue
                && ([[singletonValue uppercaseString] isEqualToString:@"TRUE"]
                    ||[[singletonValue uppercaseString] isEqualToString:@"FALSE"])) {
                    if ([[singletonValue uppercaseString] isEqualToString:@"FALSE"]) {
                        isSingle = false;
                    }
            }
            beanClassModel.singleton = isSingle;
        
            //获取bean是否延迟加载
            NSString * sDelayInitValue= [[element attributeForName:__kDelayInitKey__] stringValue];
            Boolean isDelayInit = true;
            if ( sDelayInitValue
                && ([[sDelayInitValue uppercaseString] isEqualToString:@"TRUE"]
                    ||[[sDelayInitValue uppercaseString] isEqualToString:@"FALSE"])) {
                    if ([[sDelayInitValue uppercaseString] isEqualToString:@"FALSE"]) {
                        isDelayInit = false;
                    }
                }
            beanClassModel.lazy_init = isDelayInit;
            
            NSMutableArray *propertysArray = [NSMutableArray new];
            //获取bean所在的属性
            if ([element children].count) {
                for (GDataXMLElement *childrenElement in element.children) {
                    XmlProperty *xmlProperty = [XmlProperty new];
                    if ([childrenElement isMemberOfClass:[GDataXMLElement class]] && [childrenElement.name isEqualToString:@"property"]) {
                        //获取属性名称
                        NSString *propertyNameValue = [[childrenElement attributeForName:__kNameKey__] stringValue];
                        if (propertyNameValue&& [propertyNameValue length]>0) {
                            xmlProperty.name = propertyNameValue;
                        } else{
                            if (error) {
                                *error = [NSError errorWithDomain:@"com.fortis"
                                                             code:-1
                                                         userInfo:@{@"ErrorInfo":[NSString stringWithFormat:@"id<%@>属性名称为空",idValue]}];
                            }
                            return;
                        }
                        
                        //加载属性的方式,默认为by_name
                        NSString * sScopeValue= [[element attributeForName:__kAutowireKey__] stringValue];
                        BEAN_LOAD loadType = BY_NAME;
                        if ( sScopeValue
                            && ([[sScopeValue uppercaseString] isEqualToString:@"BY_NAME"]
                                ||[[sScopeValue uppercaseString] isEqualToString:@"BY_TYPE"])) {
                                if ([[sScopeValue uppercaseString] isEqualToString:@"BY_TYPE"]) {
                                    loadType = BY_TYPE;
                                }
                            }
                        xmlProperty.beanLoadType = loadType;
                        
                        //获取bean_class
                        NSString *refclassNameValue = [[element attributeForName:__kRefClassKey__] stringValue];
                        if (refclassNameValue) {
                            Class class = NSClassFromString(refclassNameValue);
                            
                            if (class) {
                                xmlProperty.ref_class = class;
                                
                            }
                        };
                        
                        //获取属性引用bean
                        NSString *refNameValue = [[childrenElement attributeForName:__kRefKey__] stringValue];
                        if (refNameValue && [refNameValue length]>0) {
                            xmlProperty.ref = refNameValue;
                        }
                        
                        //判断异常
                        if (loadType == BY_TYPE) {
                            if (!xmlProperty.ref_class) {
                                if (error) {
                                    *error = [NSError errorWithDomain:@"com.fortis"
                                                                 code:-1
                                                             userInfo:@{@"ErrorInfo":[NSString stringWithFormat:@"class<%@>属性加载失败",refclassNameValue]}];
                                    return;
                                }
                            }
                        }else{
                            if (!xmlProperty.ref) {
                                if (error) {
                                    *error = [NSError errorWithDomain:@"com.fortis"
                                                                 code:-1
                                                             userInfo:@{@"ErrorInfo":[NSString stringWithFormat:@"id<%@>属性引用bean为空",refNameValue]}];
                                    return;
                                }
                            }
                        }
                        
                        [propertysArray addObject:xmlProperty];
                        beanClassModel.propertys = propertysArray;
                    }
                }
            }
            
            //判断是否加入classdic中
            if (beanClassModel.ref_id) {
                [self.iDBeanClassDic setObject:beanClassModel forKey:beanClassModel.ref_id];
            }
            
            if (beanClassModel.ref_class) {
                [self.classBeanClassIDDic setObject:beanClassModel forKey:NSStringFromClass(beanClassModel.ref_class)];
            }
            
            if (beanClassModel.singleton) {
                [self.singletons addObject:beanClassModel];
            }
            
            if (!beanClassModel.lazy_init) {
                [self.initializingClassPool addObject:beanClassModel];
            }
           
            //实现支持协议查找
//            if(beanClassModel)
            
            
            
            
        }
    }
}

/**
 * 解析所有的document
 */
-(void)parseDocument:(GDataXMLElement *) rootElement{
    for (GDataXMLElement *xmlElement in [rootElement nodesForXPath:@"import" error:nil]) {
        NSString *xmlPath = [[xmlElement attributeForName:@"path"] stringValue];
        GDataXMLDocument *XMLDocTemp = [self readXML:xmlPath];
        //需要将GDataXMLDocument对象保持
        [self.xmlDocArr addObject:XMLDocTemp];
        [self parseDocument:[XMLDocTemp rootElement]];
    }
}

/**
 * 解析所有bean的element
 */
-(void)parseBeanElement{
    NSMutableArray<GDataXMLElement *> *mBeansArr = [NSMutableArray new];
    for (GDataXMLDocument *rootElementTemp in self.xmlDocArr) {
        [mBeansArr addObjectsFromArray:[rootElementTemp nodesForXPath:@"beans/bean" error:nil]];
    }
}

/**
 * 读取所有的path路径下的xml
 */
- (GDataXMLDocument *)readXML:(NSString *)path{
    NSData *xmlData = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:path ofType:nil]];
    if (!xmlData) {
        NSLog(@"读取文件<%@>错误",path);
    }
    return [self readXmlData:xmlData];
}
/**
 * 读取所有的document
 */
- (GDataXMLDocument *)readXmlData:(NSData *) xmlData{
    NSError *error;
    GDataXMLDocument *document;
    
    if (xmlData) {
        
        document = [[GDataXMLDocument alloc] initWithData:xmlData options:0 error:&error];
        if (!error) {
            return document;
        }else{
            NSLog(@"%@",error.domain);
        }
        
    }
    return document;
}


- (XMLBean *)getBeanByClass:(NSString *)bean_Class{
    if (!self.classBeanClassIDDic) {
        return nil;
    }
    
    return [self.classBeanClassIDDic objectForKey:bean_Class];
}
- (XMLBean *)getBeanById:(NSString *)bean_id{
    if (!self.iDBeanClassDic) {
        return nil;
    }
    return [self.iDBeanClassDic objectForKey:bean_id];
}

- (Boolean)isSingle:(XMLBean *)xmlBean{
    if (!self.singletons) {
        return false;
    }
    return [self.singletons containsObject:xmlBean];
}

- (Boolean)isLazyInit:(XMLBean *)xmlBean{
    if (!self.initializingClassPool) {
        return false;
    }
    return [self.initializingClassPool containsObject:xmlBean];
}

@end
