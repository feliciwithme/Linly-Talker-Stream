"""
Whisper ASR 引擎实现
支持 openai-whisper 和 transformers 两种实现
"""

import torch
from typing import Dict, Any

from src.utils.logging import logger
from src.asr.base import BaseASR


class WhisperASR(BaseASR):
    """
    Whisper ASR 引擎
    
    支持两种实现方式：
    1. openai-whisper（推荐）
    2. transformers pipeline（备用）
    """
    
    def __init__(self, config=None, model_size: str = "base"):
        """
        初始化 Whisper ASR
        
        Args:
            config: 配置对象
            model_size: 模型大小 ('tiny', 'base', 'small', 'medium', 'large')
        """
        super().__init__(config)
        
        self.model_size = model_size
        self.device = "cuda" if torch.cuda.is_available() else "cpu"
        self.model = None
        self.model_type = None
        
        logger.info(f'[Whisper] 模型大小: {model_size}, 设备: {self.device}')
    
    def _load_model(self):
        """加载 Whisper 模型"""
        try:
            # 优先尝试 openai-whisper
            import whisper
            logger.info(f'[Whisper] 正在加载 openai-whisper 模型: {self.model_size}')
            self.model = whisper.load_model(self.model_size, device=self.device)
            self.model_type = "openai-whisper"
            logger.info('[Whisper] openai-whisper 模型加载成功')
            
        except ImportError:
            logger.warning('[Whisper] openai-whisper 未安装，尝试使用 transformers')
            try:
                from transformers import pipeline
                model_name = f"openai/whisper-{self.model_size}"
                logger.info(f'[Whisper] 正在加载 transformers 模型: {model_name}')
                self.model = pipeline(
                    "automatic-speech-recognition",
                    model=model_name,
                    device=0 if self.device == "cuda" else -1
                )
                self.model_type = "transformers-whisper"
                logger.info('[Whisper] transformers whisper 模型加载成功')
                
            except Exception as e:
                logger.error(f'[Whisper] transformers whisper 加载失败: {e}')
                raise ImportError(
                    "请安装 Whisper 依赖:\n"
                    "  方式1: pip install openai-whisper\n"
                    "  方式2: pip install transformers torch"
                )
    
    def _transcribe(self, audio_path: str) -> Dict[str, Any]:
        """
        使用 Whisper 识别音频
        
        Args:
            audio_path: 音频文件路径
            
        Returns:
            识别结果字典
        """
        if self.model_type == "openai-whisper":
            return self._transcribe_openai(audio_path)
        else:
            return self._transcribe_transformers(audio_path)
    
    def _transcribe_openai(self, audio_path: str) -> Dict[str, Any]:
        """使用 openai-whisper 识别"""
        language = None if self.language == "auto" else self.language
        
        result = self.model.transcribe(
            audio_path,
            language=language,
            fp16=(self.device == "cuda")
        )
        
        return {
            "text": result["text"].strip(),
            "language": result.get("language", self.language),
            "segments": result.get("segments", [])
        }
    
    def _transcribe_transformers(self, audio_path: str) -> Dict[str, Any]:
        """使用 transformers pipeline 识别"""
        result = self.model(audio_path)
        
        return {
            "text": result["text"].strip(),
            "language": self.language
        }
    
    def get_info(self) -> Dict[str, Any]:
        """获取引擎信息"""
        info = super().get_info()
        info.update({
            "model_size": self.model_size,
            "model_type": self.model_type,
            "device": self.device
        })
        return info