//
//  TableViewCell.m
//  SocketTest
//
//  Created by Manuel Menzella on 12/22/13.
//  Copyright (c) 2013 Manuel Menzella. All rights reserved.
//

#import "TableViewCell.h"

@implementation TableViewCell

+ (float)height { return 20.0f; }

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.label = [[UILabel alloc] init];
        [self.contentView addSubview:self.label];
    }
    return self;
}

- (void)layoutSubviews
{
    static float paddingX = 8.0f, paddingY = 2.0f;
    self.label.frame = CGRectMake(paddingX, paddingY, self.contentView.bounds.size.width - 2 * paddingX, [TableViewCell height] - 2 * paddingY);
}

@end
