"""OpenAI 兼容的 LLM 引擎"""

from __future__ import annotations

import time
from typing import Generator, Optional

from openai import OpenAI, OpenAIError

from src.llm.base import BaseLLM
from src.utils.logging import logger


class OpenAILLM(BaseLLM):
    """OpenAI 兼容的 LLM 引擎，支持 OpenAI/DashScope/vLLM/Ollama 等"""
    
    def __init__(
        self, 
        config=None, 
        parent=None,
        api_key: str = None,
        base_url: str = "https://dashscope.aliyuncs.com/compatible-mode/v1",
        model: str = "qwen-plus"
    ):
        super().__init__(config, parent)
        
        if not api_key:
            raise ValueError("api_key is required")
        
        self.api_key = api_key
        self.base_url = base_url
        self.model = model
        
        logger.info(f"LLM initialized: model={self.model}, base_url={self.base_url}")
        self._client: Optional[OpenAI] = None
    
    @property
    def client(self) -> OpenAI:
        if self._client is None:
            # 延迟创建客户端，避免无效配置时提前报错
            self._client = OpenAI(api_key=self.api_key, base_url=self.base_url)
        return self._client
    
    def chat_stream(
        self,
        message: str,
        system_prompt: Optional[str] = None
    ) -> Generator[str, None, None]:
        start_time = time.perf_counter()
        system_prompt = system_prompt or self.system_prompt
        
        try:
            # 采用 OpenAI 兼容流式接口，逐块返回内容
            completion = self.client.chat.completions.create(
                model=self.model,
                messages=[
                    {'role': 'system', 'content': system_prompt},
                    {'role': 'user', 'content': message}
                ],
                stream=True,
                stream_options={"include_usage": True}
            )
            
            init_time = time.perf_counter()
            logger.info(f"LLM initialization time: {init_time - start_time:.3f}s")
            
            for chunk in completion:
                if chunk.choices and chunk.choices[0].delta.content:
                    yield chunk.choices[0].delta.content
            
        except OpenAIError as e:
            logger.error(f"LLM API error: {e}")
            raise
        except Exception as e:
            logger.error(f"Unexpected error in LLM: {e}")
            raise
