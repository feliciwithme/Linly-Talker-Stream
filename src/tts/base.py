"""
TTS 基类模块

所有 TTS 引擎都应该继承 BaseTTS 并实现其抽象方法。
"""

from __future__ import annotations

import queue
from enum import Enum
from queue import Queue
from threading import Thread
from typing import TYPE_CHECKING

from src.utils.logging import logger

if TYPE_CHECKING:
    from src.avatars.base import BaseAvatar


class State(Enum):
    RUNNING = 0
    PAUSE = 1


class BaseTTS:
    """
    所有 TTS 引擎的基类，负责：
    - 统一的消息队列
    - 统一的渲染线程（process_tts）
    - 统一的采样率 / chunk 配置
    具体引擎只需要实现 txt_to_audio。
    """

    def __init__(self, config, parent: "BaseAvatar"):
        self.config = config
        self.parent = parent

        # 20ms 一帧
        self.fps = config.audio.fps
        self.sample_rate = 16000
        # 320 samples per chunk (20ms * 16000 / 1000)
        self.chunk = self.sample_rate // self.fps

        # 文本消息队列
        self.msgqueue: "Queue[tuple[str, dict]]" = Queue()
        self.state: State = State.RUNNING

    def flush_talk(self) -> None:
        """清空队列并暂停当前说话状态。"""
        self.msgqueue.queue.clear()
        self.state = State.PAUSE

    def put_msg_txt(self, msg: str, datainfo: dict | None = None) -> None:
        """外部入口：放入一条待合成的文本消息。"""
        if datainfo is None:
            datainfo = {}
        if len(msg) > 0:
            self.msgqueue.put((msg, datainfo))

    def render(self, quit_event) -> None:
        """启动独立线程持续消费队列，调用具体引擎的 txt_to_audio。"""
        process_thread = Thread(target=self.process_tts, args=(quit_event,))
        process_thread.start()

    def process_tts(self, quit_event) -> None:
        """循环从队列中取消息，并调用 txt_to_audio。"""
        while not quit_event.is_set():
            try:
                msg: tuple[str, dict] = self.msgqueue.get(block=True, timeout=1)
                self.state = State.RUNNING
            except queue.Empty:
                continue
            self.txt_to_audio(msg)
        logger.info("ttsreal thread stop")

    def txt_to_audio(self, msg: tuple[str, dict]):
        """
        子类必须实现：
            msg: (text, textevent)
        内部负责把音频分帧后，通过 parent.put_audio_frame(...) 推给上层。
        """
        raise NotImplementedError