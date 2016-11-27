//
//  Menu.m
//  SpaceNeonWars
//
//  Created by Gajaharan Satkunanandan on 18/11/2016.
//  Copyright © 2016 Gajaharan Satkunanandan. All rights reserved.
//

#import "GameMenu.h"

@implementation GameMenu {
    SKLabelNode *_scoreLabel;
    SKLabelNode *_topScoreLabel;
    SKSpriteNode *title;
    SKSpriteNode *playButton;
    SKSpriteNode *scoreBoard;
    SKSpriteNode *musicButton;
}

-(id) init {
    self = [super init];
    if(self) {
        title = [SKSpriteNode spriteNodeWithImageNamed:@"Title"];
        title.position = CGPointMake(0, 140);
        title.name=@"Title";
        [self addChild:title];
        
        scoreBoard = [SKSpriteNode spriteNodeWithImageNamed:@"ScoreBoard"];
        scoreBoard.position = CGPointMake(0, 70);
        scoreBoard.name=@"ScoreBoard";
        [self addChild:scoreBoard];
        
        playButton = [SKSpriteNode spriteNodeWithImageNamed:@"PlayButton"];
        playButton.position = CGPointMake(0, 0);
        playButton.name=@"Play";
        [self addChild:playButton];
        
        _scoreLabel = [SKLabelNode labelNodeWithFontNamed:@"DIN Alternate"];
        _scoreLabel.fontSize = 30;
        _scoreLabel.position = CGPointMake(-52, -20);
        
        [scoreBoard addChild: _scoreLabel];
        
        _topScoreLabel = [SKLabelNode labelNodeWithFontNamed:@"DIN Alternate"];
        _topScoreLabel.fontSize = 30;
        _topScoreLabel.position = CGPointMake(48, -20);
        
        [scoreBoard addChild: _topScoreLabel];
        
        musicButton = [SKSpriteNode spriteNodeWithImageNamed:@"MusicOnButton"];
        musicButton.name = @"Music";
        //musicButton.xScale = 2.0;
        //musicButton.yScale = 2.0;
        musicButton.position = CGPointMake(0, -50);
        [self addChild:musicButton];
        
        self.score = 0;
        self.topScore = 0;
        self.touchable = YES;        
    }
    
    return self;
}

-(void)setScore:(int)score {
    _score = score;
    _scoreLabel.text = [[NSNumber numberWithInt:score] stringValue];
}

-(void)setTopScore:(int)topScore {
    _topScore = topScore;
    _topScoreLabel.text = [[NSNumber numberWithInt:topScore] stringValue];
}

-(void)hide {
    self.touchable = NO;
    
    SKAction *animateMenu = [SKAction scaleTo:0.0 duration:0.5];
    animateMenu.timingMode = SKActionTimingEaseIn;
    [self runAction:animateMenu completion:^{
        self.hidden = YES;
        self.xScale = 1.0;
        self.yScale = 1.0;
    }];
}

-(void)show {
    self.hidden = NO;
    self.touchable = NO;
    
    /* Animate Title */
    title.position = CGPointMake(0, 280);
    title.alpha = 0;
    SKAction *animateTitle = [SKAction group:@[[SKAction moveToY:140 duration:0.5],
                                               [SKAction fadeInWithDuration:0.5]]];
    animateTitle.timingMode = SKActionTimingEaseOut;
    [title runAction:animateTitle];
    
    /* Animate Scoreboard */
    scoreBoard.xScale = 4.0;
    scoreBoard.yScale = 4.0;
    scoreBoard.alpha = 0;
    SKAction *animatScoreBoard = [SKAction group:@[[SKAction scaleTo:1.0 duration:0.5],
                                                   [SKAction fadeInWithDuration:0.5]]];
    animatScoreBoard.timingMode = SKActionTimingEaseOut;
    [scoreBoard runAction:animatScoreBoard];
    
    /* Animate play button */
    playButton.alpha = 0;
    SKAction *animatePlayButton = [SKAction fadeInWithDuration:2.0];
    animatePlayButton.timingMode = SKActionTimingEaseIn;
    [playButton runAction:animatePlayButton completion:^{
        self.touchable = YES;
    }];
    
    /* Music */
    musicButton.alpha = 0.0;
    [musicButton runAction:animatePlayButton];
}

-(void)setMusicPlaying:(BOOL)musicPlaying
{
    _musicPlaying = musicPlaying;
    if(musicPlaying) {
        musicButton.texture = [SKTexture textureWithImageNamed:@"MusicOnButton"];
    } else {
        musicButton.texture = [SKTexture textureWithImageNamed:@"MusicOffButton"];
    }
}

@end
