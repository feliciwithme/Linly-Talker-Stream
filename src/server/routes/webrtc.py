# Linly-Talker-Stream (https://github.com/Kedreamix/Linly-Talker-Stream). Copyright [Linly-talker-stream@kedreamix]. Apache-2.0.
# Based on LiveTalking (C) 2024 LiveTalking@lipku https://github.com/lipku/LiveTalking (Apache-2.0).

"""WebRTC 相关路由"""
import json
from aiohttp import web
from aiortc import RTCPeerConnection, RTCSessionDescription, RTCIceServer, RTCConfiguration
from aiortc.rtcrtpsender import RTCRtpSender
import asyncio

from src.utils.webrtc import HumanPlayer
from src.avatars.factory import create_avatar
from src.utils.logging import logger
from src.server.state import state
from src.server.utils import randN


async def offer(request):
    """处理 WebRTC offer 请求"""
    params = await request.json()
    offer = RTCSessionDescription(sdp=params["sdp"], type=params["type"])
    
    sessionid = randN(6)
    state.add_session(sessionid, None)
    logger.info('sessionid=%d, session num=%d', sessionid, len(state.avatar_streams))
    
    # 创建 avatar 可能耗时，放线程池
    avatar_stream = await asyncio.get_event_loop().run_in_executor(
        None, create_avatar, state.config, state.model, state.avatar, sessionid
    )
    state.add_session(sessionid, avatar_stream)
    
    ice_server = RTCIceServer(urls='stun:stun.miwifi.com:3478')
    pc = RTCPeerConnection(configuration=RTCConfiguration(iceServers=[ice_server]))
    state.add_peer_connection(pc)

    @pc.on("connectionstatechange")
    async def on_connectionstatechange():
        logger.info("Connection state is %s" % pc.connectionState)
        if pc.connectionState == "failed":
            await pc.close()
            state.remove_peer_connection(pc)
            state.remove_session(sessionid)
        if pc.connectionState == "closed":
            state.remove_peer_connection(pc)
            state.remove_session(sessionid)

    player = HumanPlayer(state.avatar_streams[sessionid])
    audio_sender = pc.addTrack(player.audio)
    video_sender = pc.addTrack(player.video)
    
    capabilities = RTCRtpSender.getCapabilities("video")
    preferences = list(filter(lambda x: x.name == "H264", capabilities.codecs))
    preferences += list(filter(lambda x: x.name == "VP8", capabilities.codecs))
    preferences += list(filter(lambda x: x.name == "rtx", capabilities.codecs))
    transceiver = pc.getTransceivers()[1]
    transceiver.setCodecPreferences(preferences)

    await pc.setRemoteDescription(offer)
    answer = await pc.createAnswer()
    await pc.setLocalDescription(answer)

    return web.Response(
        content_type="application/json",
        text=json.dumps(
            {"sdp": pc.localDescription.sdp, "type": pc.localDescription.type, "sessionid": sessionid}
        ),
    )
