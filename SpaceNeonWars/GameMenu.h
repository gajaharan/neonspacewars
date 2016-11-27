//
//  Menu.h
//  SpaceNeonWars
//
//  Created by Gajaharan Satkunanandan on 18/11/2016.
//  Copyright © 2016 Gajaharan Satkunanandan. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@interface GameMenu : SKNode

@property (nonatomic) int topScore;
@property (nonatomic) int score;
@property (nonatomic) BOOL touchable;
@property (nonatomic) BOOL musicPlaying;
-(void)hide;
-(void)show;

@end
