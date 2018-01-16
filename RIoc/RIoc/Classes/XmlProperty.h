//
//  XmlProperty.h
//  RIoc
//
//  Created by 何霞雨 on 2018/1/16.
//

#import <Foundation/Foundation.h>

typedef NS_OPTIONS(NSUInteger, BEAN_LOAD) {
    
    BY_NAME =  0 ,//通过bean_id获取
    BY_TYPE =  1 //通过bean_class获取
    
};

@interface XmlProperty : NSObject

//属性名称
@property (nonatomic,strong) NSString * name;
//属性引用的类
@property (nonatomic,assign) Class ref_class;
//属性引用的beanId
@property (nonatomic,strong) NSString * ref;
//加载bean的方式,默认为by_name
@property (nonatomic,assign) BEAN_LOAD beanLoadType;

@end
