//
//  WebRTCUtil.h
//  XfinityVideoShare
//


#ifndef XfinityVideoShare_WebRTCUtil_h
#define XfinityVideoShare_WebRTCUtil_h
typedef enum
{
    outgoing,
    incoming,
    dataoutgoing,
    dataincoming,
    pstncall
}WebrtcSessionCallTypes;


typedef enum
{
    rtc_server_message,
    reg_server_message,
    auth_server_message,
} EventTypes;

typedef enum : NSInteger
{
    nonetwork,
    cellular2g,
    cellular3g,
    cellular4g,
    cellularLTE,
    wifi
    
} NetworkTypes;

typedef enum : NSInteger {
    Disconnected = 0,
    SocketConnecting,
    SocketConnected,
    SocketDisconnect,
    SocketReconnecting,
    SocketReconnected
} NetworkState;


typedef struct
{
    BOOL EnableDataSend;
    BOOL EnableDataRecv;
    BOOL EnableVideoSend;
    BOOL EnableVideoRecv;
    BOOL EnableAudioSend;
    BOOL EnableAudioRecv;
    
    BOOL EnableOneWay;
    BOOL EnableBroadcast;
    
}WebrtcSessionOptions_t;

typedef enum
{
    starting,
    active,
    call_connecting,
    ice_connecting,
    inactive
} State;

typedef enum
{
    WebRTCBadNetwork = 1,
    WebRTCPoorNetwork = 2,
    WebRTCFairNetwork = 3,
    WebRTCGoodNetwork = 4,
    WebRTCExcellentNetwork = 5
    
} NetworkQuality;

typedef enum
{
    NetworkQualityIndicator
    
} EventType;

#endif
