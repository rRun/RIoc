//
//  BeanFactory.h
//  FBSnapshotTestCase
//
//  Created by 何霞雨 on 2018/1/14.
//

#import <Foundation/Foundation.h>

@protocol BeanFactory <NSObject>

/**
 * 获取bean的方式
 */
-(NSObject *) getBean:(NSString *) bean_id;
-(NSObject *) getBean:(NSString *) bean_id args:(NSArray *)args;
-(NSObject *) getBean:(NSString *) bean_id class:(Class) bean_clazz;

//获取bean的类
-(Class)getType:(NSString *) bean_name;

//是否存在bean
-(Boolean)containsBean:(NSString *) bean_name;
//是否是单例
-(Boolean)isSingleton:(NSString *) bean_name;

//
-(Boolean)isPrototype:(NSString *) bean_name;
-(Boolean)isTypeMatch:(NSString *) bean_name;

@end
