//
//  XmlManager.h
//  FBSnapshotTestCase
//
//  Created by 何霞雨 on 2018/1/15.
//

#import <Foundation/Foundation.h>
#import "XMLBean.h"
#import "XmlProperty.h"

@interface XmlManager : NSObject

+ (instancetype)sharedXMLManager;

- (XMLBean *)getBeanByClass:(NSString *)bean_Class;
- (XMLBean *)getBeanById:(NSString *)bean_id;
- (Boolean)isSingle:(XMLBean *)xmlBean;
- (Boolean)isLazyInit:(XMLBean *)xmlBean;

@end
