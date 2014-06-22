//
//  TableViewCell.h
//  SocketTest
//
//  Created by Manuel Menzella on 12/22/13.
//  Copyright (c) 2013 Manuel Menzella. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TableViewCell : UITableViewCell

@property (nonatomic, strong)UILabel *label;

+ (float)height;

@end