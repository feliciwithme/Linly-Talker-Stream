from __future__ import annotations

import asyncio
import time
from io import BytesIO

import edge_tts
import numpy as np
import resampy
import soundfile as sf

from src.tts.base import BaseTTS, State
from src.utils.logging import logger


class EdgeTTS(BaseTTS):
    def __init__(self, config, parent):
        super().__init__(config, parent)
        # EdgeTTS 需要 BytesIO 缓冲区来累积音频数据
        self.input_stream = BytesIO()

    def txt_to_audio(self, msg: tuple[str, dict]):
        voicename = self.config.tts.ref_file  # 比如 "zh-CN-YunxiaNeural"
        text, textevent = msg
        t = time.time()

        # 每次调用独立事件循环，避免和外部 loop 冲突
        asyncio.new_event_loop().run_until_complete(self.__main(voicename, text))
        logger.info(f"-------edge tts time:{time.time() - t:.4f}s")

        # Edge TTS 失败保护
        if self.input_stream.getbuffer().nbytes <= 0:
            logger.error("edgetts err!!!!!")
            return

        # 将 BytesIO 转为 float32 流，并按 chunk 推送给上层
        self.input_stream.seek(0)
        stream = self.__create_bytes_stream(self.input_stream)
        streamlen = stream.shape[0]
        idx = 0
        while streamlen >= self.chunk and self.state == State.RUNNING:
            eventpoint = {}
            streamlen -= self.chunk
            if idx == 0:
                # 首帧标记 start，方便前端做状态切换
                eventpoint = {"status": "start", "text": text}
                eventpoint.update(**textevent)
            elif streamlen < self.chunk:
                # 末帧标记 end
                eventpoint = {"status": "end", "text": text}
                eventpoint.update(**textevent)
            self.parent.put_audio_frame(stream[idx : idx + self.chunk], eventpoint)
            idx += self.chunk

        # 清空缓冲区，准备下一次调用
        self.input_stream.seek(0)
        self.input_stream.truncate()

    def __create_bytes_stream(self, byte_stream: BytesIO) -> np.ndarray:
        stream, sample_rate = sf.read(byte_stream)  # [T*sample_rate,] float64
        logger.info(f"[INFO]tts audio stream {sample_rate}: {stream.shape}")
        stream = stream.astype(np.float32)

        if stream.ndim > 1:
            logger.info(f"[WARN] audio has {stream.shape[1]} channels, only use the first.")
            stream = stream[:, 0]

        if sample_rate != self.sample_rate and stream.shape[0] > 0:
            logger.info(
                f"[WARN] audio sample rate is {sample_rate}, resampling into {self.sample_rate}."
            )
            stream = resampy.resample(
                x=stream, sr_orig=sample_rate, sr_new=self.sample_rate
            )

        return stream

    async def __main(self, voicename: str, text: str):
        try:
            communicate = edge_tts.Communicate(text, voicename)

            first = True
            async for chunk in communicate.stream():
                if first:
                    first = False
                if chunk["type"] == "audio" and self.state == State.RUNNING:
                    self.input_stream.write(chunk["data"])
                elif chunk["type"] == "WordBoundary":
                    pass
        except Exception:
            logger.exception("edgetts")
