"""MuseTalk 音频流处理器 - 使用 Whisper 提取音频特征"""
import time
import numpy as np

import queue
from queue import Queue
from src.avatars.audio_stream_handler import BaseAudioStreamHandler
from src.avatars.musetalk.whisper.audio2feature import Audio2Feature


class MuseAudioStreamHandler(BaseAudioStreamHandler):
    """Whisper 音频特征提取器
    
    用于 MuseTalk Avatar 模型，提取 Whisper 音频特征。
    """
    def __init__(self, config, parent, audio_processor: Audio2Feature):
        super().__init__(config, parent)
        self.audio_processor = audio_processor

    def run_step(self):
        """执行一步音频特征提取"""
        start_time = time.time()
        for _ in range(self.batch_size * 2):
            audio_frame, type, eventpoint = self.get_audio_frame()
            self.frames.append(audio_frame)
            self.output_queue.put((audio_frame, type, eventpoint))
        
        if len(self.frames) <= self.stride_left_size + self.stride_right_size:
            return
        
        inputs = np.concatenate(self.frames)  # [N * chunk]
        whisper_feature = self.audio_processor.audio2feat(inputs)
        # for feature in whisper_feature:
        #     self.audio_feats.append(feature)        
        #print(f"processing audio costs {(time.time() - start_time) * 1000}ms, inputs shape:{inputs.shape} whisper_feature len:{len(whisper_feature)}")
        whisper_chunks = self.audio_processor.feature2chunks(
            feature_array=whisper_feature,
            fps=self.fps / 2,
            batch_size=self.batch_size,
            start=self.stride_left_size / 2
        )
        #print(f"whisper_chunks len:{len(whisper_chunks)},self.audio_feats len:{len(self.audio_feats)},self.output_queue len:{self.output_queue.qsize()}")
        #self.audio_feats = self.audio_feats[-(self.stride_left_size + self.stride_right_size):]
        self.feat_queue.put(whisper_chunks)
        # discard the old part to save memory
        self.frames = self.frames[-(self.stride_left_size + self.stride_right_size):]
