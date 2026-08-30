import { AbilityConstant, UIAbility, Want, ConfigurationConstant, Configuration } from '@kit.AbilityKit';
import { ThemeManager } from '../utils/ThemeManager';
import { PreferencesUtil, setPreferencesContext } from '../utils/PreferencesUtil';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { backgroundTaskManager } from '@kit.BackgroundTasksKit';
import { wantAgent } from '@kit.AbilityKit';
import { PlaybackManager } from '../utils/PlaybackManager';

const DOMAIN: number = 0x0001;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, 'EntryAbility', 'onCreate');
    setPreferencesContext(this.context);
    AppStorage.setOrCreate('currentColorMode', this.context.config.colorMode);
    ThemeManager.refreshIsDark(this.context.config.colorMode ?? ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    // 应用已保存的主题模式（需先初始化 Preferences）
  }

  private async applySavedTheme(): Promise<void> {
    try {
      // 触发 Preferences 加载
      await PreferencesUtil.get('__warmup__', '');
      const mode = ThemeManager.getSavedMode();
      this.context.getApplicationContext().setColorMode(ThemeManager.modeToColorMode(mode));
    } catch (e) {
      hilog.error(DOMAIN, 'EntryAbility', 'applySavedTheme failed: %{public}s', JSON.stringify(e) ?? '');
    }
  }

  onConfigurationUpdate(newConfig: Configuration): void {
    AppStorage.setOrCreate('currentColorMode', newConfig.colorMode);
    ThemeManager.refreshIsDark(newConfig.colorMode ?? ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    this.updateSystemBarContentColor(AppStorage.get<boolean>('isDarkMode') ?? true);
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'EntryAbility', 'onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, 'EntryAbility', 'onWindowStageCreate');
    // 此时 ability context 已就绪，可安全读 Preferences 应用主题
    this.applySavedTheme();
    windowStage.loadContent('pages/HomePage', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'EntryAbility', 'Failed to load content. %{public}s', JSON.stringify(err) ?? '');
        return;
      }
      hilog.info(DOMAIN, 'EntryAbility', 'Succeeded in loading content.');
      this.enableImmersive(windowStage);
    });
  }

  private mainWindow: window.Window | null = null;

  private enableImmersive(windowStage: window.WindowStage): void {
    try {
      this.mainWindow = windowStage.getMainWindowSync();
      // 开启全屏沉浸式布局：内容延伸到状态栏/导航条区域
      this.mainWindow.setWindowLayoutFullScreen(true).catch((e: Object) => {
        hilog.error(DOMAIN, 'EntryAbility', 'setWindowLayoutFullScreen failed: %{public}s', JSON.stringify(e) ?? '');
      });
      // 状态栏/导航栏透明，图标颜色根据深浅色模式自适应
      this.updateSystemBarContentColor(AppStorage.get<boolean>('isDarkMode') ?? true);
    } catch (e) {
      hilog.error(DOMAIN, 'EntryAbility', 'enableImmersive error: %{public}s', JSON.stringify(e) ?? '');
    }
  }

  private updateSystemBarContentColor(isDark: boolean): void {
    if (!this.mainWindow) return;
    const barProps: window.SystemBarProperties = {
      statusBarColor: '#00000000',
      navigationBarColor: '#00000000',
      statusBarContentColor: isDark ? '#FFFFFF' : '#000000',
      navigationBarContentColor: isDark ? '#FFFFFF' : '#000000'
    };
    this.mainWindow.setWindowSystemBarProperties(barProps).catch((e: Object) => {
      hilog.error(DOMAIN, 'EntryAbility', 'setWindowSystemBarProperties failed: %{public}s', JSON.stringify(e) ?? '');
    });
  }
  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, 'EntryAbility', 'onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(DOMAIN, 'EntryAbility', 'onForeground');
    PlaybackManager.resumeFromBackground();
    this.context.eventHub.emit('app-foreground');
    this.stopBackgroundRunning();
  }

  onBackground(): void {
    hilog.info(DOMAIN, 'EntryAbility', 'onBackground');
    // 请求短时任务延迟挂起，确保 setVolume(0)/pause() 有时间生效
    try {
      const delayInfo: backgroundTaskManager.DelaySuspendInfo = backgroundTaskManager.requestSuspendDelay('PausePlayback', () => {
        hilog.info(DOMAIN, 'EntryAbility', 'Suspend delay expired');
      });
      PlaybackManager.pauseForBackground();
      this.context.eventHub.emit('app-background');
      setTimeout(() => {
        backgroundTaskManager.cancelSuspendDelay(delayInfo.requestId);
      }, 3000);
    } catch (_e) {}
    if (AppStorage.get<boolean>('isCasting') === true) {
      this.startBackgroundRunning();
    }
  }

  private async startBackgroundRunning(): Promise<void> {
    try {
      const info: wantAgent.WantAgentInfo = {
        wants: [{
          bundleName: this.context.abilityInfo.bundleName,
          abilityName: this.context.abilityInfo.name
        }],
        operationType: wantAgent.OperationType.START_ABILITY,
        requestCode: 0,
        wantAgentFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG]
      };
      const agent = await wantAgent.getWantAgent(info);
      await backgroundTaskManager.startBackgroundRunning(this.context, backgroundTaskManager.BackgroundMode.AUDIO_PLAYBACK, agent);
      hilog.info(DOMAIN, 'EntryAbility', 'startBackgroundRunning ok');
    } catch (e) {
      hilog.error(DOMAIN, 'EntryAbility', 'startBackgroundRunning failed: %{public}s', (e as Error).message);
    }
  }

  private async stopBackgroundRunning(): Promise<void> {
    try {
      await backgroundTaskManager.stopBackgroundRunning(this.context);
      hilog.info(DOMAIN, 'EntryAbility', 'stopBackgroundRunning ok');
    } catch (_e) {}
  }
}
