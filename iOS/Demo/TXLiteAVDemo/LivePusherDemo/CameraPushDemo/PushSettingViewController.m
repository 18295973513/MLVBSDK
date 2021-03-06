/**
 * Module:   PushSettingViewController
 *
 * Function: 推流相关的主要设置项
 */

#import "PushSettingViewController.h"
#import "UIView+Additions.h"
#import "ColorMacro.h"

/* 列表项 */
#define SECTION_QUALITY             0
#define SECTION_AUDIO_QUALITY       1
#define SECTION_BANDWIDTH_ADJUST    2
#define SECTION_HW                  3
#define SECTION_AUDIO_PREVIEW       4

/* 编号，请不要修改，写配置文件依赖这个 */
#define TAG_QUALITY                 1000
#define TAG_BANDWIDTH_ADJUST        1003
#define TAG_HW                      1004
#define TAG_AUDIO_PREVIEW           1005
#define TAG_AUDIO_QUALITY           1006

@interface PushSettingQuality : NSObject
@property (copy, nonatomic) NSString *title;
@property (assign, nonatomic) TX_Enum_Type_VideoQuality value;
@end

@implementation PushSettingQuality
@end

@interface PushSettingViewController () <UITableViewDelegate, UITableViewDataSource, UIActionSheetDelegate> {
    UISwitch *_bandwidthSwitch;
    UISwitch *_hwSwitch;
    UISwitch *_audioPreviewSwitch;

    NSArray<PushSettingQuality *> *_qualities;
    NSArray<NSString *> *_audioQualities;
}
@property (strong, nonatomic) UITableView *mainTableView;

@end

@implementation PushSettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"设置";

    NSArray<NSString *> * titleArray = @[@"蓝光", @"超清", @"高清", @"标清",
                                         @"连麦大主播", @"连麦小主播", @"实时音视频"];
    TX_Enum_Type_VideoQuality qualityArray[] = {
        VIDEO_QUALITY_ULTRA_DEFINITION,
        VIDEO_QUALITY_SUPER_DEFINITION,
        VIDEO_QUALITY_HIGH_DEFINITION,
        VIDEO_QUALITY_STANDARD_DEFINITION,
        VIDEO_QUALITY_LINKMIC_MAIN_PUBLISHER,
        VIDEO_QUALITY_LINKMIC_SUB_PUBLISHER,
        VIDEO_QUALITY_REALTIME_VIDEOCHAT
    };
    NSMutableArray *qualities = [[NSMutableArray alloc] initWithCapacity:titleArray.count];
    for (int i = 0; i < titleArray.count; ++i) {
        PushSettingQuality *quality = [[PushSettingQuality alloc] init];
        quality.title = titleArray[i];
        quality.value = qualityArray[i];
        [qualities addObject:quality];
    }
    _qualities = qualities;
    _audioQualities = @[@"语音", @"标准", @"音乐"];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"返回" style:UIBarButtonItemStylePlain target:self action:@selector(onClickedCancel:)];
    //self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"完成" style:UIBarButtonItemStylePlain target:self action:@selector(onClickedOK:)];
    
    _bandwidthSwitch = [self createUISwitch:TAG_BANDWIDTH_ADJUST on:[PushSettingViewController getBandWidthAdjust]];
    _hwSwitch = [self createUISwitch:TAG_HW on:[PushSettingViewController getEnableHWAcceleration]];
    _audioPreviewSwitch = [self createUISwitch:TAG_AUDIO_PREVIEW on:[PushSettingViewController getEnableAudioPreview]];
    
    _mainTableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStyleGrouped];
    _mainTableView.delegate = self;
    _mainTableView.dataSource = self;
    _mainTableView.separatorColor = [UIColor darkGrayColor];
    [self.view addSubview:_mainTableView];
    [_mainTableView setContentInset:UIEdgeInsetsMake(0, 0, 34, 0)];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.translucent = NO;
    [self.navigationController setNavigationBarHidden:NO animated:NO];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    self.navigationController.navigationBar.translucent = YES;
}

- (void)onClickedCancel:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)onClickedOK:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (UISwitch *)createUISwitch:(NSInteger)tag on:(BOOL)on {
    UISwitch *sw = [[UISwitch alloc] initWithFrame:CGRectZero];
    sw.tag = tag;
    sw.on = on;
    [sw addTarget:self action:@selector(onSwitchTap:) forControlEvents:UIControlEventTouchUpInside];
    return sw;
}

- (void)onSwitchTap:(UISwitch *)switchBtn {
    [PushSettingViewController saveSetting:switchBtn.tag value:switchBtn.on];
    
    if (switchBtn.tag == TAG_BANDWIDTH_ADJUST) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(onPushSetting:enableBandwidthAdjust:)]) {
            [self.delegate onPushSetting:self enableBandwidthAdjust:switchBtn.on];
        }
        
    } else if (switchBtn.tag == TAG_HW) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(onPushSetting:enableHWAcceleration:)]) {
            [self.delegate onPushSetting:self enableHWAcceleration:switchBtn.on];
        }
        
    } else if (switchBtn.tag == TAG_AUDIO_PREVIEW) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(onPushSetting:enableAudioPreview:)]) {
            [self.delegate onPushSetting:self enableAudioPreview:switchBtn.on];
        }
        
    }
}

- (NSString *)getQualityStr {
    TX_Enum_Type_VideoQuality quality = [PushSettingViewController getVideoQuality];
    for (PushSettingQuality *q in _qualities) {
        if (q.value == quality) {
            return q.title;
        }
    }
    return _qualities.firstObject.title;
}

- (NSString *)getAudioQualityStr {
    NSInteger value = [PushSettingViewController getAudioQuality];
    return [_audioQualities objectAtIndex:value];
}

+ (UIView *)buildAccessoryView {
    return [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"arrow"]];
}

- (void)_showQualityActionSheet {
    UIAlertController *controller = [UIAlertController alertControllerWithTitle:@"画质"
                                                                        message:nil
                                                                 preferredStyle:UIAlertControllerStyleActionSheet];
    __weak __typeof(self) wself = self;
    for (PushSettingQuality *q in _qualities) {
        UIAlertAction *action = [UIAlertAction actionWithTitle:q.title
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * _Nonnull action) {
            __strong __typeof(wself) self = wself; if (nil == self) return;
            [PushSettingViewController saveSetting:TAG_QUALITY value:q.value];
            id<PushSettingDelegate> delegate = self.delegate;
            if ([delegate respondsToSelector:@selector(onPushSetting:videoQuality:)]) {
                [delegate onPushSetting:self videoQuality:q.value];
            }
            [self.mainTableView reloadData];
        }];
        [controller addAction:action];
    }
    [controller addAction:[UIAlertAction actionWithTitle:@"取消"
                                                   style:UIAlertActionStyleCancel
                                                 handler:nil]];
    [self presentViewController:controller animated:YES completion:nil];
}

- (void)_showAudioQualityActionSheet {
    UIAlertController *controller = [UIAlertController alertControllerWithTitle:@"音质"
                                                                        message:nil
                                                                 preferredStyle:UIAlertControllerStyleActionSheet];
    __weak typeof(self) wsself = self;
    for (NSString *title in _audioQualities) {
        UIAlertAction *action = [UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            __strong typeof(wsself) self = wsself;
            if (self == nil) {
                return;
            }
            NSInteger qualityValue = [self->_audioQualities indexOfObject:title];
            [PushSettingViewController saveSetting:TAG_AUDIO_QUALITY value:qualityValue];
            id<PushSettingDelegate> delegate = self.delegate;
            if ([delegate respondsToSelector:@selector(onPushSetting:videoQuality:)]) {
                [delegate onPushSetting:self audioQuality:qualityValue];
            }
            [self.mainTableView reloadData];
        }];
        [controller addAction:action];
    }
    [controller addAction:[UIAlertAction actionWithTitle:@"取消"
                                                   style:UIAlertActionStyleCancel
                                                 handler:nil]];
    [self presentViewController:controller animated:YES completion:nil];
}

#pragma mark - UITableView delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 5;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithFrame:CGRectMake(0, 0, self.view.width, 40)];

    if (indexPath.section == SECTION_QUALITY) {
        cell.textLabel.text = [self getQualityStr];
        cell.accessoryView = [PushSettingViewController buildAccessoryView];
    } else if (indexPath.section == SECTION_AUDIO_QUALITY) {
        cell.textLabel.text = [self getAudioQualityStr];
        cell.accessoryView = [PushSettingViewController buildAccessoryView];
    } else if (indexPath.section == SECTION_BANDWIDTH_ADJUST) {
        cell.textLabel.text = @"开启带宽适应";
        cell.accessoryView = _bandwidthSwitch;
    } else if (indexPath.section == SECTION_HW) {
        cell.textLabel.text = @"开启硬件加速";
        cell.accessoryView = _hwSwitch;
    } else if (indexPath.section == SECTION_AUDIO_PREVIEW) {
        cell.textLabel.text = @"开启耳返";
        cell.accessoryView = _audioPreviewSwitch;
    }
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == SECTION_QUALITY) {
        return @"画质偏好";
    }
    if (section == SECTION_AUDIO_QUALITY) {
        return @"音质选择";
    }
    return @"";
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == SECTION_QUALITY) {
        [self _showQualityActionSheet];
    }
    if (indexPath.section == SECTION_AUDIO_QUALITY) {
        [self _showAudioQualityActionSheet];
    }
}

#pragma mark - 读写配置文件

+ (NSString *)getKey:(NSInteger)tag {
    return [NSString stringWithFormat:@"PUSH_SETTING_%ld", tag];
}

+ (void)saveSetting:(NSInteger)tag value:(NSInteger)value {
    NSString *key = [PushSettingViewController getKey:tag];
    [[NSUserDefaults standardUserDefaults] setObject:@(value) forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (BOOL)getBandWidthAdjust {
    NSString *key = [PushSettingViewController getKey:TAG_BANDWIDTH_ADJUST];
    NSNumber *d = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    if (d != nil) {
        return [d intValue];
    }
    return NO;
}

+ (BOOL)getEnableHWAcceleration {
    NSString *key = [PushSettingViewController getKey:TAG_HW];
    NSNumber *d = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    if (d != nil) {
        return [d intValue];
    }
    return YES;
}

+ (BOOL)getEnableAudioPreview {
    NSString *key = [PushSettingViewController getKey:TAG_AUDIO_PREVIEW];
    NSNumber *d = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    if (d != nil) {
        return [d intValue];
    }
    return NO;
}

+ (TX_Enum_Type_VideoQuality)getVideoQuality {
    NSString *key = [PushSettingViewController getKey:TAG_QUALITY];
    NSNumber *d = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    if (d != nil) {
        return [d intValue];
    }
    return VIDEO_QUALITY_SUPER_DEFINITION;
}

+ (NSInteger)getAudioQuality {
    NSString *key = [PushSettingViewController getKey:TAG_AUDIO_QUALITY];
    NSNumber *value = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    if (value != nil) {
        return [value integerValue];
    }
    return 2;
}

@end
