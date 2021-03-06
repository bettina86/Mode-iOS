// This is the license from the Flash version.
// 
// Copyright (c) 2009 Adam 'Atomic' Saltsman
//
// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following
// conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.
//
// NOTE FROM THE AUTHOR: As far as I know, you only have to include
// this license if you are redistributing source code that includes
// the Flixel library.  There is no need (or way, afaik) to include
// it in your compiled flash games and apps!
// 
// NOTE FROM THE iOS PORT CODER: I have only ported this game to iOS.
// I do not claim to own any copyright over this game. All ownership
// stays with the original author.

#import "PlayState.h"
#import "MenuState.h"
#import "VictoryState.h"
#import "Player.h"
#import "Spawner.h"
#import "Enemy.h"
#import "Bullet.h"
#import "EnemyBullet.h"
#import "Notch.h"

#define SCORE_TIMER 3
#define KILL_TIMER 1.75

#define BUTTON_START_ALPHA 0.1
#define BUTTON_PRESSED_ALPHA 0.5

#define NUMBER_OF_ENEMIES 8



static NSString * ImgTech = @"tech_tiles.png";
static NSString * ImgDirtTop = @"dirt_top.png";

static NSString * ImgDirt = @"dirt.png";

static NSString * SndMode = @"mode.mp3";
static NSString * SndJam = @"jam.caf";
static NSString * SndCount = @"countdown.caf";
static NSString * SndShoot = @"shoot.caf";

static NSString * ImgGibs = @"gibs.png";
static NSString * ImgSpawnerGibs = @"spawner_gibs.png";
//static NSString * ImgJet = @"jet.png";


static NSString * ImgButtonArrow = @"buttonArrow.png";
static NSString * ImgButtonA = @"buttonA.png";
static NSString * ImgButtonB = @"buttonB.png";

static float buttonAlphaStart = 0.1;

static float buttonAlphaPressed= 0.5;


static int bulletIndex;

static int spawnerCount;

int _oldScore;

static FlxEmitter * _littleEmitter = nil;
static FlxEmitter * _bigEmitter = nil;

//HUD/User Interface stuff
FlxText * _score;
FlxText * _score2;
CGFloat _scoreTimer;
CGFloat _jamTimer;
CGFloat _killTimer;

//virtual control pad vars
int previousNumberOfTouches;
BOOL newTouch;

BOOL _fading;
BOOL scoreChanged;

@implementation PlayState

//@synthesize gameCenterManager;

- (id) init
{
    if ((self = [super init])) {
        self.bgColor = 0xff131c1b;
        
        _blocks = [[FlxGroup alloc] init];
        _decorations = [[FlxGroup alloc] init];
        _enemies = [[FlxGroup alloc] init];
        _spawners = [[FlxGroup alloc] init];
        _hud = [[FlxGroup alloc] init];
        _enemyBullets = [[FlxGroup alloc] init];
        _bullets = [[FlxGroup alloc] init];
        _hazards = [[FlxGroup alloc] init];
        _objects = [[FlxGroup alloc] init];      
        _gunjam = [[FlxGroup alloc] init];
        _notches = [[FlxGroup alloc] init];
        
        
    }
    return self;
}

- (void) create
{
    
//    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
//    NSInteger currentZoom = [prefs integerForKey:@"ZOOM_FOR_CURRENT_GAME"];
    
    
//	if([GameCenterManager isGameCenterAvailable])
//	{
//		self.gameCenterManager= [[[GameCenterManager alloc] init] autorelease];
//		[self.gameCenterManager setDelegate: self];
//		//[self.gameCenterManager authenticateLocalUser];
//		
//		//[self updateCurrentScore];
//	}
//	else
//	{
//		[self showAlertWithTitle: @"Game Center Support Required!"
//						 message: @"The current device does not support Game Center."];
//	}
    
    //[self.gameCenterManager reportScore:100 forCategory:kModeLB];
    
    
    FlxG.touches.humanControlled = YES;
    
    buttonAlphaStart = BUTTON_START_ALPHA;
    buttonAlphaPressed = BUTTON_PRESSED_ALPHA;
    
    if (FlxG.gamePad != 0) {
        buttonAlphaPressed=0;
        buttonAlphaStart=0;
    }
    
    
    //gibs
    _littleGibs = [[FlxEmitter alloc] init];
    _littleGibs.delay = 0.02/3;
    _littleGibs.minParticleSpeed = CGPointMake(-150,
                                               150);
    _littleGibs.maxParticleSpeed = CGPointMake(150,
                                               0);
    _littleGibs.minRotation = -720;
    _littleGibs.maxRotation = 720;
    _littleGibs.gravity = 100;
    _littleGibs.particleDrag = CGPointMake(0, 0);
    _littleEmitter = [_littleGibs retain];
    [_littleGibs createSprites:ImgGibs quantity:20 bakedRotations:NO
                      multiple:YES collide:0 modelScale:1.0];
    
    
    // big gibs
    _bigGibs = [[FlxEmitter alloc] init];
    _bigGibs.delay = 0.02/3;
    _bigGibs.minParticleSpeed = CGPointMake(-200,
                                            200);
    _bigGibs.maxParticleSpeed = CGPointMake(200,
                                            0);
    _bigGibs.minRotation = -720;
    _bigGibs.maxRotation = 720;
    _bigGibs.gravity = 200;
    _bigGibs.particleDrag = CGPointMake(0, 0);
    _bigEmitter = [_bigGibs retain];
    [_bigGibs createSprites:ImgSpawnerGibs quantity:20 bakedRotations:NO
                   multiple:YES collide:0 modelScale:1.0];
    
    bulletIndex = 0;
    spawnerCount = 0;
    _killTimer = -1;
    
    player = [Player playerWithOrigin:CGPointMake(316,300) Bullets:_bullets Gibs:_littleGibs] ;
    player.dead = NO;
    [_objects add:player];
    
    
    //camera
    [FlxG followWithParam1:player param2:15];
    
    //set world size
    //param4 (y) is 660 to allow for extra room when on the bottom of the level.
    [FlxG followBoundsWithParam1:0 param2:0 param3:640 param4:700 param5:YES];
    
    for (int i=0; i<10; i++) {
        eb = [EnemyBullet enemyBulletWithOrigin:CGPointMake(1200,1200)  ];
        eb.dead = YES;
        [_enemyBullets add:eb];
        [_objects add:eb];
        [_hazards add:eb];
    }
    
    [self generateLevel:0];
    for (int i=0; i<NUMBER_OF_ENEMIES; i++) {
        enemy = [Enemy enemyWithOrigin:CGPointMake(-1000,-1000) Bullets:_enemyBullets Gibs:_littleGibs ThePlayer:player  ];
        enemy.dead = YES;
        //[self add:enemy];
        [_enemies add:enemy];
        [_hazards add:enemy];
        [_objects add:enemy];
    }
    
    for (int i=0; i<10; i++) {
        bullet = [Bullet bulletWithOrigin:CGPointMake(800,800)  ];
        bullet.dead = YES;
        [_bullets add:bullet];
        [_objects add:bullet];
    }
    
    
    [self add:_blocks];
    [self add:_decorations];
    [self add:_spawners];
    [self add:_enemies];
    [self add:player];
    
    [self add:_bullets];
    [self add:_enemyBullets];
    
    [self add:_littleEmitter];
    [self add:_bigEmitter];
    
    //From here on out we are making objects for the HUD,
    //that is, the player score, number of spawners left, etc.
    //First, we'll create a text field for the current score
    _score = [FlxText textWithWidth:FlxG.width/2
                               text:@"0"
                               font:nil
                               size:16.0];
    _score.color = 0xd8eba2;
    _score.alignment = @"center";
    _score.x = FlxG.width/4;
    _score.y = 0;
    _score.scrollFactor = CGPointMake(0, 0);
    [_hud add:_score];
    
    
    //Then for the player's highest and last scores
    //    if(FlxG.score > FlxG.scores[0])
    //        FlxG.scores[0] = FlxG.score;
    //    if(FlxG.scores[0] != 0)
    //    {
    //        _score2 = new FlxText(FlxG.width/2,0,FlxG.width/2);
    //        _score2.setFormat(null,8,0xd8eba2,"right",_score.shadow);
    //        _hud.add(_score2);
    //        _score2.text = "HIGHEST: "+FlxG.scores[0]+"\nLAST: "+FlxG.score;
    //    }
    
    FlxG.score = 0;
    _scoreTimer = 0;
    
    //Then we create the "gun jammed" notification
    
	temp = [FlxSprite spriteWithX:0 y:FlxG.height-22 graphic:nil];
	[temp createGraphicWithParam1:FlxG.width param2:24 param3:0xff131c1b];
    temp.scrollFactor = CGPointMake(0, 0);
	[_gunjam add:temp];
    temptext = [FlxText textWithWidth:FlxG.width
                                 text:@"GUN IS JAMMED"
                                 font:nil
                                 size:16.0];
    temptext.color = 0xd8eba2;
    temptext.alignment = @"center";
    temptext.x = 0;
    temptext.y = FlxG.height-22;
    //temptext.visible = NO;
    temptext.scrollFactor = CGPointMake(0, 0);
    [_gunjam add:temptext]; 
    
    for (int i=0; i<6; i++) {
        notch = [Notch notchWithOrigin:CGPointMake(4+i*10,4)  ];
        notch.scrollFactor = CGPointMake(0, 0);
        [_notches add:notch];
        [_hud add:notch];
    }
    
    
    //After we add all the objects to the HUD, we can go through
    //and set any property we want on all the objects we added
    //with this sweet function.  In this case, we want to set
    //the scroll factors to zero, to make sure the HUD doesn't
    //wiggle around while we play.
    //_hud.scrollFactor = CGPointMake(0, 0);
    //_hud.setAll("scrollFactor",new FlxPoint(0,0));
    // _hud.setAll("cameras",[FlxG.camera]);
    [self add:_hud];
    [self add:_gunjam];
    _gunjam.visible = NO;
    
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSInteger LAX = [prefs integerForKey:@"LEFT_ARROW_POSITION_X"];
    NSInteger LAY = [prefs integerForKey:@"LEFT_ARROW_POSITION_Y"];
    NSInteger RAX = [prefs integerForKey:@"RIGHT_ARROW_POSITION_X"];
    NSInteger RAY = [prefs integerForKey:@"RIGHT_ARROW_POSITION_Y"];
    
    NSInteger B1X = [prefs integerForKey:@"BUTTON_1_POSITION_X"];
    NSInteger B1Y = [prefs integerForKey:@"BUTTON_1_POSITION_Y"];
    NSInteger B2X = [prefs integerForKey:@"BUTTON_2_POSITION_X"];
    NSInteger B2Y = [prefs integerForKey:@"BUTTON_2_POSITION_Y"];
    
    //add buttons for the virtual control pad
    
    buttonLeft  = [FlxSprite spriteWithX:80 y:80 graphic:ImgButtonArrow];
    buttonLeft.x = LAX;
    buttonLeft.y = LAY;
    buttonLeft.alpha=BUTTON_START_ALPHA;
    //buttonLeft.fixed = YES;
    buttonLeft.scrollFactor = CGPointMake(0, 0);
	[self add:buttonLeft];
    
    buttonRight  = [FlxSprite spriteWithX:80 y:80 graphic:ImgButtonArrow];
    buttonRight.x = RAX;
    buttonRight.y = RAY;
    buttonRight.alpha=BUTTON_START_ALPHA;
    buttonRight.angle = 180;
    //buttonRight.fixed=YES;
    buttonRight.scrollFactor = CGPointMake(0, 0);
	[self add:buttonRight];
    
    
    buttonA  = [FlxSprite spriteWithX:80 y:80 graphic:ImgButtonB];
    buttonA.x = B2X;
    buttonA.y = B2Y;
    buttonA.alpha=BUTTON_START_ALPHA;
    //buttonA.fixed=YES;
    buttonA.scrollFactor = CGPointMake(0, 0);
	[self add:buttonA];
    
    buttonB  = [FlxSprite spriteWithX:80 y:80 graphic:ImgButtonA];
    buttonB.x = B1X;
    buttonB.y = B1Y;
    buttonB.alpha=BUTTON_START_ALPHA;
    //buttonB.fixed=YES;
    buttonB.scrollFactor = CGPointMake(0, 0);
	[self add:buttonB]; 
    
//    if (currentZoom==2) {
//        buttonLeft.scale=CGPointMake(0.5, 0.5);
//        buttonRight.scale=CGPointMake(0.5, 0.5);
//        buttonA.scale=CGPointMake(0.5, 0.5);
//        buttonB.scale=CGPointMake(0.5, 0.5);
//        
//        buttonLeft.x=-20;
//        buttonLeft.y=100;
//        
//        buttonRight.x=20;
//        buttonRight.y=100;
//        
//        buttonA.x=200;
//        buttonA.y=120;
//        
//        buttonB.x=160;
//        buttonB.y=120;
//
//    }
    
    _fading = NO;
    [FlxG playMusicWithParam1:SndMode param2:0.35];
    
}
//These next two functions look crazy, but all they're doing is generating
//the level structure and placing the enemy spawners.
- (void) generateLevel:(int)size
{
    uint r = 160;
    
    //First, we create the walls, ceiling and floors:
    b = [FlxTileblock tileblockWithX:0 y:0 width:640 height:16];
    [b  loadGraphic:ImgTech];
    [_blocks add:b];
    
    b = [FlxTileblock tileblockWithX:0 y:16 width:16 height:640-16];
    [b  loadGraphic:ImgTech];
    [_blocks add:b];
    
    b = [FlxTileblock tileblockWithX:640-16 y:16 width:16 height:640-16];
    [b  loadGraphic:ImgTech];
    [_blocks add:b];
    
    b = [FlxTileblock tileblockWithX:16 y:640-24 width:640-32 height:8];
    [b  loadGraphic:ImgDirtTop];
    [_blocks add:b];
    
    b = [FlxTileblock tileblockWithX:16 y:640-16 width:640-32 height:16];
    [b  loadGraphic:ImgDirt];
    [_blocks add:b];
    
    
    //Then we split the game world up into a 4x4 grid,
    //and generate some blocks in each area.  Some grid spaces
    //also get a spawner!
    
    [self buildRoom:r*0 withRY:r*0 withSpawners:YES];
    [self buildRoom:r*1 withRY:r*0 withSpawners:NO];
    [self buildRoom:r*2 withRY:r*0 withSpawners:NO];
    [self buildRoom:r*3 withRY:r*0 withSpawners:YES];
    [self buildRoom:r*0 withRY:r*1 withSpawners:YES];
    [self buildRoom:r*1 withRY:r*1 withSpawners:NO];
    [self buildRoom:r*2 withRY:r*1 withSpawners:NO];
    [self buildRoom:r*3 withRY:r*1 withSpawners:YES];
    [self buildRoom:r*0 withRY:r*2 withSpawners:NO];
    [self buildRoom:r*1 withRY:r*2 withSpawners:NO];
    [self buildRoom:r*2 withRY:r*2 withSpawners:NO];
    [self buildRoom:r*3 withRY:r*2 withSpawners:NO];
    [self buildRoom:r*0 withRY:r*3 withSpawners:YES];
    [self buildRoom:r*1 withRY:r*3 withSpawners:NO];
    [self buildRoom:r*2 withRY:r*3 withSpawners:NO];
    [self buildRoom:r*3 withRY:r*3 withSpawners:YES];
    
}

////Just plops down a spawner and some blocks - haphazard and crappy atm but functional!
- (void) buildRoom:(uint)RX withRY:(uint)RY withSpawners:(BOOL)spawners
{
    //    //first place the spawn point (if necessary)
    uint rw = 20;
    uint sx;   
    uint sy;
    if(spawners)
    {
        sx = 2+[FlxU random]*(rw-7);
        sy = 2+[FlxU random]*(rw-7);
    }
    
    //then place a bunch of blocks
    uint numBlocks = 3+[FlxU random]*4;
    if(!spawners) numBlocks++;
    uint maxW = 10;
    uint minW = 2;
    uint maxH = 8;
    uint minH = 1;
    uint bx;
    uint by;
    uint bw;
    uint bh;
    BOOL check;
    
    for(int i = 0; i < numBlocks; i++)
    {
        do
        {
            //keep generating different specs if they overlap the spawner
            bw = minW + [FlxU random]*(maxW-minW);
            bh = minH + [FlxU random]*(maxH-minH);
            bx = -1 + [FlxU random]*(rw+1-bw);
            by = -1 + [FlxU random]*(rw+1-bh);
            if(spawners)
                check = ((sx>bx+bw) || (sx+3<bx) || (sy>by+bh) || (sy+3<by));
            else
                check = true;
        } while(!check);
        
        b = [FlxTileblock tileblockWithX:RX+bx*8 y:RY+by*8 width:bw*8 height:bh*8];
        [b loadGraphic:ImgTech];
        [_blocks add:b];
        
        //If the block has room, add some non-colliding "dirt" graphics for variety
        if((bw >= 4) && (bh >= 5))
        {
            //b = new FlxTileblock(RX+bx*8+8,RY+by*8,bw*8-16,8);
            b = [FlxTileblock tileblockWithX:RX+bx*8+8 y:RY+by*8 width:bw*8-16 height:8];
            [b loadGraphic:ImgDirtTop];
            [_decorations add:b];      
            
            b = [FlxTileblock tileblockWithX:RX+bx*8+8 y:RY+by*8+8 width:bw*8-16 height:bh*8-24];
            [b loadGraphic:ImgDirt];
            [_decorations add:b];
        }
    }
    
    if(spawners)
    {
        //Finally actually add the spawner
        sp = [Spawner spawnerWithOrigin:CGPointMake(RX+sx*8,RY+sy*8) Gibs:_bigGibs Bots:_enemies BotBullets:nil BotGibs:_littleGibs ThePlayer:player Notches:_notches Index:spawnerCount] ;
        
        //debug to check VictoryState
        //sp.dead = YES;
        
        [_spawners add:sp];
        [_hazards add:sp];
        spawnerCount++;
        
    }
}

- (void) virtualControlPad 
{
    buttonRight.alpha = buttonAlphaStart;
    buttonLeft.alpha = buttonAlphaStart;
    buttonA.alpha = buttonAlphaStart;
    buttonB.alpha = buttonAlphaStart;
    
    if (FlxG.touches.vcpLeftArrow || FlxG.touches.iCadeLeft) {
        buttonLeft.alpha = buttonAlphaPressed;
        player.velocity = CGPointMake(-150, player.velocity.y);
        player.scale = CGPointMake(-1, 1);
    } else if (FlxG.touches.vcpRightArrow || FlxG.touches.iCadeRight) {
        buttonRight.alpha = buttonAlphaPressed;
        player.velocity = CGPointMake(150, player.velocity.y);
        player.scale = CGPointMake(1, 1);
    } 
    //button A jump
    if ((FlxG.touches.vcpButton2 && !player.velocity.y && FlxG.touches.newTouch ) || (FlxG.touches.iCadeBBegan && !player.velocity.y ) ) { //&& FlxG.touches.newTouch
        buttonA.alpha = buttonAlphaPressed;
        [player doJump];
        //pressedJump = YES;
        player.justLanded = YES;
        
        
    }
    BOOL nt = FlxG.touches.newTouch;
    if ((FlxG.touches.vcpButton1 && (nt || player.rapidFire) ) || (FlxG.touches.iCadeABegan && !FlxG.touches.iCadeDown && !FlxG.touches.iCadeUp)) { 
        buttonB.alpha = buttonAlphaPressed;
        if (!player.flickering) {
            //button D regular shoot
            [FlxG play:SndShoot];
            Bullet * bull = [_bullets.members objectAtIndex:bulletIndex];
            bull.x = player.x;
            bull.y = player.y;
            bull.visible=YES;
            bull.dead = NO;
            bull.drag = CGPointMake(0, 0);
            bull.scale = CGPointMake(1,1);
            
            if (player.scale.x < 0) {
                bull.velocity = CGPointMake(-300, 0);
                [bull play:@"left"];
            }
            else {
                bull.velocity = CGPointMake(300, 0);
                [bull play:@"right"];
                
                
            }
            bulletIndex++;
            if (bulletIndex>=_bullets.members.length) {
                bulletIndex = 0;	
            }
        }  
        else if (player.flickering){
            //NSLog(@"touch jam");
            [FlxG play:SndJam];
            _jamTimer = 1;
            _gunjam.visible = YES;
        }
    } 
    
    if(_jamTimer > 0)
    {
        if(!player.flickering)
            _jamTimer = 0;
        _jamTimer -= FlxG.elapsed;
        if(_jamTimer < 0)
            _gunjam.visible = NO;
    }
    
    //shoot up
    if ((FlxG.touches.swipedUp && !player.flickering ) || (FlxG.touches.iCadeUp && FlxG.touches.iCadeABegan  && !player.flickering)) {
        //up
        //[self fireWeapon];
        [FlxG play:SndShoot];

        Bullet * bull = [_bullets.members objectAtIndex:bulletIndex];
        bull.x = player.x;
        bull.y = player.y;
        bull.visible=YES;
        bull.dead = NO;
        bull.drag = CGPointMake(0, 0);
        bull.scale = CGPointMake(1,1);
        bull.velocity = CGPointMake(0, -300);
        [bull play:@"up"];
        bulletIndex++;
        if (bulletIndex>=_bullets.members.length) {
            bulletIndex = 0;	
        }
        //[player play:@"idle_up"];
    }
    
    //swiped down
    
    //else if (p.y > 40 && p.y < 80 && p.x < 320 && p.x > 276 && (newTouch || player.rapidFire) ) {
    else if ((FlxG.touches.swipedDown && !player.flickering)  || (FlxG.touches.iCadeDown && FlxG.touches.iCadeABegan  && !player.flickering) ){                   
        player.velocity = CGPointMake(player.velocity.x, player.velocity.y - 80);
        //was -36 in Flash game. changed it due to swipes being slower to execute.
        
        [FlxG play:SndShoot];

        Bullet * bull = [_bullets.members objectAtIndex:bulletIndex];
        bull.x = player.x;
        bull.y = player.y;
        bull.visible=YES;
        bull.dead = NO;
        bull.drag = CGPointMake(0, 0);
        bull.scale = CGPointMake(1,1);
        bull.velocity = CGPointMake(0, 300);
        [bull play:@"down"];
        bulletIndex++;
        if (bulletIndex>=_bullets.members.length) {
            bulletIndex = 0;	
        }
    }
    
    else if (FlxG.touches.swipedLeft && !player.flickering) { 
        //button D regular shoot
        [FlxG play:SndShoot];

        Bullet * bull = [_bullets.members objectAtIndex:bulletIndex];
        bull.x = player.x;
        bull.y = player.y;
        bull.visible=YES;
        bull.dead = NO;
        bull.drag = CGPointMake(0, 0);
        bull.scale = CGPointMake(1,1);
        bull.velocity = CGPointMake(-300, 0);
        [bull play:@"left"];            
        bulletIndex++;
        if (bulletIndex>=_bullets.members.length) {
            bulletIndex = 0;	
        }
    }
    
    //swiped to the right
    
    else if (FlxG.touches.swipedRight && !player.flickering) {   
        
        [FlxG play:SndShoot];

        
        Bullet * bull = [_bullets.members objectAtIndex:bulletIndex];
        bull.x = player.x;
        bull.y = player.y;
        bull.visible=YES;
        bull.dead = NO;
        bull.drag = CGPointMake(0, 0);
        bull.scale = CGPointMake(1,1);
        bull.velocity = CGPointMake(300, 0);
        [bull play:@"right"];
        bulletIndex++;
        if (bulletIndex>=_bullets.members.length) {
            bulletIndex = 0;	
        }
    }
    
    //if trying to shoot and gun is jammed
    else if ( ( FlxG.touches.swipedRight || FlxG.touches.swipedLeft || FlxG.touches.swipedUp || FlxG.touches.swipedDown || FlxG.touches.iCadeABegan) && player.flickering) {
        [FlxG play:SndJam];
        _jamTimer = 1;
        _gunjam.visible = YES;
    }            
    if(_jamTimer > 0)
    {
        if(!player.flickering)
            _jamTimer = 0;
        _jamTimer -= FlxG.elapsed;
        if(_jamTimer < 0)
            _gunjam.visible = NO;
    }
    
}




- (void) dealloc
{
    //[[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [_blocks release];
    //[b release];
    [_decorations release];
    [_enemies release];
    [_spawners release];
    [_hud release];
    [_enemyBullets release];
    [_bullets release];
    [_hazards release];
    [_objects release];    
    [_gunjam release];
    [_notches release];
    
    
    
    [super dealloc];
}


- (void) onVictory 
{
    //NSLog(@"VICTORY");
    FlxG.state = [[[VictoryState alloc] init] autorelease];
    return;
    
}

- (void) onDeath 
{
    //NSLog(@"Death");
    FlxG.state = [[[MenuState alloc] init] autorelease];
    return;
    
}


- (void) update
{    
    
    if (!player.dead) [self virtualControlPad];
    
    [super update];
    
    if (FlxG.touches.iCadeStartBegan || FlxG.touches.iCadeSelectBegan) {
        [FlxG pauseMusic];
        FlxG.state = [[[MenuState alloc] init] autorelease];
        return;
    }
    
// too slow!    
//    for (FlxObject * s in _bigGibs.members) {
//        //[FlxU collideObject:s withGroup:_blocks];
//        [FlxU alternateCollideWithParam1:s param2:_blocks];
//
//    }
    
    // check for collides between player/bullets/enemies and the level
    for (FlxObject * s in _objects.members) {
        //adding this check speeds up the game,
        //without it, the fps was horrible, around 10-15 fps
        
        if (!s.dead ) {
        //if (!s.dead && [s onScreen]) {
            [FlxU collideObject:s withGroup:_blocks];
        }
    }
    
    //check overlap between player and hazards (enemies/enemy bullets/spawners)
    for (FlxObject * s in _hazards.members) {
        if (!s.dead) {
            if ([ player overlapsWithOffset:s] ) {
                [player hurt:0];
                return;
                
            }
            //check hazards agains the players bullets;
            for (FlxObject * bb in _bullets.members) {
                if ([ s overlapsWithOffset:bb] ) {
                    if (!bb.dead) {
                        //[bb kill];
                        //[s kill];
                        bb.dead = YES;
                        bb.x = 1000;
                        bb.y = 1000;
                        
                        [s hurt:1];
                        
                        return;
                    }
                }
            }
        }
    }
    
    if(!_fading)
    {
        if (_oldScore != FlxG.score) {
            scoreChanged = YES;
        }
        else {
            scoreChanged = NO;
        }
        
        //Score + countdown stuffs
        if(scoreChanged) {
            _scoreTimer = SCORE_TIMER;
        }
        
        _scoreTimer -= FlxG.elapsed;
        if(_scoreTimer < 0)
        {
            
            if(FlxG.score > 0)
            {
                if(FlxG.score > 100) {
                    FlxG.score -= 100;
                }
                
                // YOU ARE DEAD
                
                else
                {
                    //NSLog(@"you are dead: kill timer %f", _killTimer);
                    _killTimer = 0;
                    [player hurt:100];
                    
                    player.dead = YES;
                    player.visible = NO;
                    [FlxG fadeOutMusic:1];
                    
                    
                    
                }
                _scoreTimer = 2;
                scoreChanged = YES;
                
                //Play loud beeps if your score is low
                CGFloat volume = 0.75;
                if(FlxG.score < 600)
                    volume = 1.0;
                [FlxG playWithParam1:SndCount param2:volume];
            }
//            if(_killTimer>=0) _killTimer += FlxG.elapsed;
//            if (_killTimer > KILL_TIMER) {
//                
//                NSLog(@"kill timer: %d", _killTimer);
//                
//                FlxG.score = 0;
//                FlxG.state = [[[MenuState alloc] init] autorelease];
//                //[self onDeath];
//                return;
//            }        
        }
        
        
        
        //Fade out to victory screen stuffs
        if([_spawners countLiving] <= 0)
        {
            _fading = YES;
            //FlxG.fade(0xffd8eba2,3,onVictory);
            //[[FlxG fade]startWithParam1:0xffd8eba2 param2:3 param3:[self onVictory] param4:YES ];
            //What's a flash function* ????
            [self onVictory];
            return;
        }
    }
    
    if (player.dead) {
        if(_killTimer>=0) _killTimer += FlxG.elapsed;
        //NSLog(@"kill timer: %f", _killTimer);
        
        if (_killTimer > KILL_TIMER) {
            
            //NSLog(@"OUT OF kill timer: %f", _killTimer);
            
            FlxG.score = 0;
            FlxG.state = [[[MenuState alloc] init] autorelease];
            //[self onDeath];
            return;
        } 
    }
    
    
    //actually update score text if it changed
    if(scoreChanged)
    {
        if(player.dead) FlxG.score = 0;
        NSString *intString = [NSString stringWithFormat:@"%d", FlxG.score];
        _score.text = (@"%@", intString);    
    }
    
    _oldScore = FlxG.score;
    
}





@end

