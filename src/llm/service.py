"""LLM 服务模块"""

from typing import Optional

from src.avatars.base import BaseAvatar
from src.llm.engines import OpenAILLM
from src.utils.logging import logger
import os


def llm_response(
    message: str,
    avatar_stream: BaseAvatar,
    api_key: str = os.getenv("DASHSCOPE_API_KEY"),
    base_url: str = "https://dashscope.aliyuncs.com/compatible-mode/v1",
    model: str = "qwen-plus"
) -> str:
    """调用 LLM 并将响应流式推送到 avatar"""
    try:
        config = getattr(avatar_stream, 'config', None)
        
        # 每次调用独立创建实例，避免跨会话污染状态
        llm = OpenAILLM(
            config=config,
            parent=avatar_stream,
            api_key=api_key,
            base_url=base_url,
            model=model
        )
        
        return llm.generate_response(message, avatar_stream)
        
    except Exception as e:
        logger.error(f"Error in llm_response: {e}")
        raise


__all__ = ["llm_response"]
