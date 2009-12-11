package
{
    import flash.display.Graphics;
    import flash.display.Sprite;
    import flash.display.StageAlign;
    import flash.display.StageScaleMode;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.events.SampleDataEvent;
    import flash.events.TimerEvent;
    import flash.media.Microphone;
    import flash.media.Sound;
    import flash.media.SoundChannel;
    import flash.media.SoundMixer;
    import flash.utils.ByteArray;
    import flash.utils.Timer;
    
    import com.kingnare.skins.KButton;
    
    [SWF(width="480", height="320", backgroundColor="#222222", frameRate="36")]
    
    /**
     * 部分代码来自:
     * http://help.adobe.com/en_US/FlashPlatform/beta/reference/actionscript/3/flash/media/Microphone.html#event:sampleData
     * http://livedocs.adobe.com/flex/3/langref/flash/media/SoundMixer.html#computeSpectrum%28%29
     * 
     * @author king
     * 
     */    
    public class FirstApp extends Sprite
    {
        /**
         * 录制5秒钟
         */        
        protected const DELAY_LENGTH:int = 5000;
        
        protected const PLOT_HEIGHT:int = 200;
        protected const CHANNEL_LENGTH:int = 256;
        
        protected var mic:Microphone;
        protected var timer:Timer;
        protected var soundBytes:ByteArray;
        
        /**
         * 构造方法
         * 
         */        
        public function FirstApp()
        {
            if (stage)
                initApp();
            else 
                this.addEventListener(Event.ADDED_TO_STAGE, addToStageHandler);
        }
        
        /**
         * 
         * @param event
         * 
         */        
        private function addToStageHandler(event:Event):void
        {
            this.removeEventListener(Event.ADDED_TO_STAGE, addToStageHandler);
            
            initApp();
        }
        
        /**
         * 初始化
         * 
         */        
        private function initApp():void
        {
            stage.scaleMode = StageScaleMode.NO_SCALE;
            stage.align = StageAlign.TOP_LEFT;
            
            soundBytes = new ByteArray();
            
            mic = Microphone.getMicrophone();
            mic.setSilenceLevel(0, DELAY_LENGTH);
            mic.gain = 100;
            mic.rate = 44;
            
            timer = new Timer(DELAY_LENGTH);
            timer.addEventListener(TimerEvent.TIMER, timerHandler);
            
            var record:KButton = new KButton(60, 20, "Record");
            record.x = 20;
            record.y = 20;
            record.addEventListener(MouseEvent.CLICK, startRecord);
            addChild(record);
        }
        
        /**
         * 开始录制
         * @param event
         * 
         */        
        private function startRecord(event:MouseEvent = null):void
        {
            this.removeEventListener(Event.ENTER_FRAME, enterFrameHandler);
            
            mic.removeEventListener(SampleDataEvent.SAMPLE_DATA, micSampleDataHandler);
            mic.addEventListener(SampleDataEvent.SAMPLE_DATA, micSampleDataHandler);
            
            soundBytes.clear();
            
            timer.start();
        }
        
        /**
         * 播放的同时绘制波形图
         * @param event
         * 
         */        
        private function enterFrameHandler(event:Event):void 
        {
            var bytes:ByteArray = new ByteArray();
            SoundMixer.computeSpectrum(bytes, false, 0);
            drawSoundWave(bytes);
        }

        /**
         * MIC采样数据处理
         * 将采样数据写入soundBytes中, 同时绘制波形图
         * @param event
         * 
         */        
        private function micSampleDataHandler(event:SampleDataEvent):void
        {
            while(event.data.bytesAvailable)
            {
                var sample:Number = event.data.readFloat();
                soundBytes.writeFloat(sample);
            }
            
            var bytes:ByteArray = event.data;
            bytes.position = 0;
            
            drawSoundWave(bytes);
        }
        
        
        /**
         * 绘制波形图
         * @param bytes
         * 
         */        
        private function drawSoundWave(bytes:ByteArray):void
        {
            if(!bytes || bytes.bytesAvailable==0)
                return;
            
            var g:Graphics = this.graphics;
            g.clear();
            g.lineStyle(0, 0x6600CC);
            g.beginFill(0x6600CC);
            g.moveTo(0, PLOT_HEIGHT);
            
            var n:Number = 0;
            
            for (var i:int = 0; i < CHANNEL_LENGTH; i++) 
            {
                n = (bytes.readFloat() * PLOT_HEIGHT);
                g.lineTo(i * 2, PLOT_HEIGHT - n);
            }
            
            g.lineTo(CHANNEL_LENGTH * 2, PLOT_HEIGHT);
            g.endFill();
            
            g.lineStyle(0, 0xCC0066);
            g.beginFill(0xCC0066, 0.5);
            g.moveTo(CHANNEL_LENGTH * 2, PLOT_HEIGHT);
            
            for (i = CHANNEL_LENGTH; i > 0; i--) 
            {
                n = (bytes.readFloat() * PLOT_HEIGHT);
                g.lineTo(i * 2, PLOT_HEIGHT - n);
            }
            
            g.lineTo(0, PLOT_HEIGHT);
            g.endFill();
        }
        
        /**
         * 停止MIC监听, 停止定时器
         * 新建Sound, 并添加Event.ENTER_FRAME监听
         * @param event
         * 
         */        
        private function timerHandler(event:TimerEvent=null):void
        {        
            mic.removeEventListener(SampleDataEvent.SAMPLE_DATA, micSampleDataHandler);
            timer.stop();
            
            soundBytes.position = 0;
            
            var sound:Sound = new Sound();
            sound.addEventListener(SampleDataEvent.SAMPLE_DATA, playbackSampleHandler, false, 0, true);
            
            var channel:SoundChannel = sound.play();
            channel.addEventListener(Event.SOUND_COMPLETE, soundCompleteHandler, false, 0, true);
            
            this.addEventListener(Event.ENTER_FRAME, enterFrameHandler);
        }
        
        /**
         * 填充声音数据
         * @param event
         * 
         */        
        private function playbackSampleHandler(event:SampleDataEvent):void
        {
            
            for (var i:int = 0; i < 8192 && soundBytes.bytesAvailable > 0; i++) 
            {
                var sample:Number = soundBytes.readFloat();
                event.data.writeFloat(sample);
                event.data.writeFloat(sample);
            }
        }
        
        /**
         * 声音播放结束
         * @param event
         * 
         */        
        private function soundCompleteHandler(event:Event):void
        {
            this.removeEventListener(Event.ENTER_FRAME, enterFrameHandler);
        }
    }
}

