//
//  XMLClass.h
//  FBSnapshotTestCase
//
//  Created by 何霞雨 on 2018/1/15.
//

#import <Foundation/Foundation.h>

@interface XMLBean : NSObject

//唯一ID
@property (nonatomic,strong) NSString * ref_id;
//bean对象的class
@property (nonatomic,assign) Class ref_class;

//保存单例对象
@property (nonatomic,strong) NSObject * singletonBean;

//创建对象的工厂方法
@property (nonatomic,strong) NSString * factoryMethod;
@property (nonatomic,strong) NSArray * factoryArgs;

//是否创建为单例，默认为ture
@property (nonatomic,assign) Boolean singleton;
//是否延迟创建bean,默认为true
@property (nonatomic,assign) Boolean lazy_init;
//bean的属性
@property (nonatomic,strong) NSArray *propertys;

//判断是否继承于某类，或实现了某协议
-(Boolean)inheritClass:(NSString *) className;

//获取bean所属的对象
-(NSObject *)getObject;
//一般是通过单例工厂生成对象
-(NSObject *)getObject:(NSArray *)args;
@end
