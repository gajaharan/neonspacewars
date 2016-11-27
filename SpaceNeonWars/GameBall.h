//
//  GameBall.h
//  SpaceNeonWars
//
//  Created by Gajaharan Satkunanandan on 20/11/2016.
//  Copyright © 2016 Gajaharan Satkunanandan. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@interface GameBall : SKSpriteNode

@property (nonatomic) SKEmitterNode *trail;
@property (nonatomic) int numBounces;
-(void)updateTrail;

@end
