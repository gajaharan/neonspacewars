//
//  GameBall.m
//  SpaceNeonWars
//
//  Created by Gajaharan Satkunanandan on 20/11/2016.
//  Copyright © 2016 Gajaharan Satkunanandan. All rights reserved.
//

#import "GameBall.h"

@implementation GameBall

-(void)updateTrail {
    if (self.trail) {
        self.trail.position = self.position;
    }
}

-(void)removeFromParent {
    if (self.trail) {
        self.trail.particleBirthRate = 0;
        SKAction *remove = [SKAction sequence:@[[SKAction waitForDuration:self.trail.particleLifetime + self.trail.particleLifetimeRange],
                                                [SKAction removeFromParent]]];
        [self runAction:remove];
    }
    [super removeFromParent];
}

@end
