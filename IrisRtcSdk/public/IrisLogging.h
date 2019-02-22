/**
 * In order to provide fast and flexible logging, this project uses Cocoa Lumberjack.
 *
 * The GitHub project page has a wealth of documentation if you have any questions.
 * https://github.com/robbiehanson/CocoaLumberjack
 *
 * Here's what you need to know concerning how logging is setup for IRISFramework:
 *
 * There are 4 log levels:
 * - Error
 * - Warning
 * - Info
 * - Verbose
 *
 * In addition to this, there is a Trace flag that can be enabled.
 * When tracing is enabled, it spits out the methods that are being called.
 *
 * Please note that tracing is separate from the log levels.
 * For example, one could set the log level to warning, and enable tracing.
 *
 * All logging is asynchronous, except errors.
 * To use logging within your own custom files, follow the steps below.
 *
 * Step 1:
 * Import this header in your implementation file:
 *
 * #import "IrisLogging.h"
 *
 * Step 2:
 * Define your logging level in your implementation file:
 *
 * // Log levels: off, error, warn, info, verbose
 * static const int irisLogLevel = IRIS_LOG_LEVEL_VERBOSE;
 *
 * If you wish to enable tracing, you could do something like this:
 *
 * // Log levels: off, error, warn, info, verbose
 * static const int irisLogLevel = IRIS_LOG_LEVEL_INFO | IRIS_LOG_FLAG_TRACE;
 *
 * Step 3:
 * Replace your NSLog statements with IRISLog statements according to the severity of the message.
 *
 * NSLog(@"Fatal error, no dohickey found!"); -> IRISLogError(@"Fatal error, no dohickey found!");
 *
 * IRISLog has the same syntax as NSLog.
 * This means you can pass it multiple variables just like NSLog.
 *
 * You may optionally choose to define different log levels for debug and release builds.
 * You can do so like this:
 *
 * // Log levels: off, error, warn, info, verbose
 * #if DEBUG
 *   static const int irisLogLevel = IRIS_LOG_LEVEL_VERBOSE;
 * #else
 *   static const int irisLogLevel = IRIS_LOG_LEVEL_WARN;
 * #endif
 *
 * Xcode projects created with Xcode 4 automatically define DEBUG via the project's preprocessor macros.
 * If you created your project with a previous version of Xcode, you may need to add the DEBUG macro manually.
 **/

@import CocoaLumberjack;

// Global flag to enable/disable logging throughout the entire iris framework.


//For Debug build enable Iris logs
#ifdef DEBUG

#ifndef IRIS_LOGGING_ENABLED
#define IRIS_LOGGING_ENABLED 1
#endif

#endif

//For Release build disable Iris logs
#ifndef DEBUG

#ifndef IRIS_LOGGING_ENABLED
#define IRIS_LOGGING_ENABLED 1
#endif

#endif


// Define logging context for every log message coming from the IRIS framework.
// The logging context can be extracted from the DDLogMessage from within the logging framework.
// This gives loggers, formatters, and filters the ability to optionally process them differently.

#define IRIS_LOG_CONTEXT 5222

// Configure log levels.

#define IRIS_LOG_FLAG_ERROR   (1 << 0) // 0...00001
#define IRIS_LOG_FLAG_WARN    (1 << 1) // 0...00010
#define IRIS_LOG_FLAG_INFO    (1 << 2) // 0...00100
#define IRIS_LOG_FLAG_VERBOSE (1 << 3) // 0...01000

#define IRIS_LOG_LEVEL_OFF     0                                              // 0...00000
#define IRIS_LOG_LEVEL_ERROR   (IRIS_LOG_LEVEL_OFF   | IRIS_LOG_FLAG_ERROR)   // 0...00001
#define IRIS_LOG_LEVEL_WARN    (IRIS_LOG_LEVEL_ERROR | IRIS_LOG_FLAG_WARN)    // 0...00011
#define IRIS_LOG_LEVEL_INFO    (IRIS_LOG_LEVEL_WARN  | IRIS_LOG_FLAG_INFO)    // 0...00111
#define IRIS_LOG_LEVEL_VERBOSE (IRIS_LOG_LEVEL_INFO  | IRIS_LOG_FLAG_VERBOSE) // 0...01111

static const int irisLogLevel = IRIS_LOG_LEVEL_VERBOSE;
// Setup fine grained logging.
// The first 4 bits are being used by the standard log levels (0 - 3)
//
// We're going to add tracing, but NOT as a log level.
// Tracing can be turned on and off independently of log level.

#define IRIS_LOG_FLAG_TRACE     (1 << 4) // 0...10000

// Setup the usual boolean macros.

#define IRIS_LOG_ERROR   (irisLogLevel & IRIS_LOG_FLAG_ERROR)
#define IRIS_LOG_WARN    (irisLogLevel & IRIS_LOG_FLAG_WARN)
#define IRIS_LOG_INFO    (irisLogLevel & IRIS_LOG_FLAG_INFO)
#define IRIS_LOG_VERBOSE (irisLogLevel & IRIS_LOG_FLAG_VERBOSE)
#define IRIS_LOG_TRACE   (irisLogLevel & IRIS_LOG_FLAG_TRACE)

// Configure asynchronous logging.
// We follow the default configuration,
// but we reserve a special macro to easily disable asynchronous logging for debugging purposes.

#if DEBUG
#define IRIS_LOG_ASYNC_ENABLED  NO
#else
#define IRIS_LOG_ASYNC_ENABLED  YES
#endif

#define IRIS_LOG_ASYNC_ERROR     ( NO && IRIS_LOG_ASYNC_ENABLED)
#define IRIS_LOG_ASYNC_WARN      (YES && IRIS_LOG_ASYNC_ENABLED)
#define IRIS_LOG_ASYNC_INFO      (YES && IRIS_LOG_ASYNC_ENABLED)
#define IRIS_LOG_ASYNC_VERBOSE   (YES && IRIS_LOG_ASYNC_ENABLED)
#define IRIS_LOG_ASYNC_TRACE     (YES && IRIS_LOG_ASYNC_ENABLED)

// Define logging primitives.
// These are primarily wrappers around the macros defined in Lumberjack's DDLog.h header file.

#define IRIS_LOG_OBJC_MAYBE(async, lvl, flg, ctx, frmt, ...) \
do{ if(IRIS_LOGGING_ENABLED) LOG_MAYBE(async, lvl, flg, ctx, nil, sel_getName(_cmd), frmt, ##__VA_ARGS__); } while(0)

#define IRIS_LOG_C_MAYBE(async, lvl, flg, ctx, frmt, ...) \
do{ if(IRIS_LOGGING_ENABLED) LOG_MAYBE(async, lvl, flg, ctx, nil, __FUNCTION__, frmt, ##__VA_ARGS__); } while(0)


#define IRISLogError(frmt, ...)    IRIS_LOG_OBJC_MAYBE(IRIS_LOG_ASYNC_ERROR,   irisLogLevel, IRIS_LOG_FLAG_ERROR,  \
IRIS_LOG_CONTEXT, frmt, ##__VA_ARGS__)

#define IRISLogWarn(frmt, ...)     IRIS_LOG_OBJC_MAYBE(IRIS_LOG_ASYNC_WARN,    irisLogLevel, IRIS_LOG_FLAG_WARN,   \
IRIS_LOG_CONTEXT, frmt, ##__VA_ARGS__)

#define IRISLogInfo(frmt, ...)     IRIS_LOG_OBJC_MAYBE(IRIS_LOG_ASYNC_INFO,    irisLogLevel, IRIS_LOG_FLAG_INFO,    \
IRIS_LOG_CONTEXT, frmt, ##__VA_ARGS__)

#define IRISLogVerbose(frmt, ...)  IRIS_LOG_OBJC_MAYBE(IRIS_LOG_ASYNC_VERBOSE, irisLogLevel, IRIS_LOG_FLAG_VERBOSE, \
IRIS_LOG_CONTEXT, frmt, ##__VA_ARGS__)

#define IRISLogTrace()             IRIS_LOG_OBJC_MAYBE(IRIS_LOG_ASYNC_TRACE,   irisLogLevel, IRIS_LOG_FLAG_TRACE, \
IRIS_LOG_CONTEXT, @"%@: %@", THIS_FILE, THIS_METHOD)

#define IRISLogTrace2(frmt, ...)   IRIS_LOG_OBJC_MAYBE(IRIS_LOG_ASYNC_TRACE,   irisLogLevel, IRIS_LOG_FLAG_TRACE, \
IRIS_LOG_CONTEXT, frmt, ##__VA_ARGS__)


#define IRISLogCError(frmt, ...)      IRIS_LOG_C_MAYBE(IRIS_LOG_ASYNC_ERROR,   irisLogLevel, IRIS_LOG_FLAG_ERROR,   \
IRIS_LOG_CONTEXT, frmt, ##__VA_ARGS__)

#define IRISLogCWarn(frmt, ...)       IRIS_LOG_C_MAYBE(IRIS_LOG_ASYNC_WARN,    irisLogLevel, IRIS_LOG_FLAG_WARN,    \
IRIS_LOG_CONTEXT, frmt, ##__VA_ARGS__)

#define IRISLogCInfo(frmt, ...)       IRIS_LOG_C_MAYBE(IRIS_LOG_ASYNC_INFO,    irisLogLevel, IRIS_LOG_FLAG_INFO,    \
IRIS_LOG_CONTEXT, frmt, ##__VA_ARGS__)

#define IRISLogCVerbose(frmt, ...)    IRIS_LOG_C_MAYBE(IRIS_LOG_ASYNC_VERBOSE, irisLogLevel, IRIS_LOG_FLAG_VERBOSE, \
IRIS_LOG_CONTEXT, frmt, ##__VA_ARGS__)

#define IRISLogCTrace()               IRIS_LOG_C_MAYBE(IRIS_LOG_ASYNC_TRACE,   irisLogLevel, IRIS_LOG_FLAG_TRACE, \
IRIS_LOG_CONTEXT, @"%@: %s", THIS_FILE, __FUNCTION__)

#define IRISLogCTrace2(frmt, ...)     IRIS_LOG_C_MAYBE(IRIS_LOG_ASYNC_TRACE,   irisLogLevel, IRIS_LOG_FLAG_TRACE, \
IRIS_LOG_CONTEXT, frmt, ##__VA_ARGS__)

// Setup logging for IRISStream (and subclasses such as IRISStreamFacebook)

#define IRIS_LOG_FLAG_SEND      (1 << 5)
#define IRIS_LOG_FLAG_RECV_PRE  (1 << 6) // Prints data before it goes to the parser
#define IRIS_LOG_FLAG_RECV_POST (1 << 7) // Prints data as it comes out of the parser

#define IRIS_LOG_FLAG_SEND_RECV (IRIS_LOG_FLAG_SEND | IRIS_LOG_FLAG_RECV_POST)

#define IRIS_LOG_SEND      (irisLogLevel & IRIS_LOG_FLAG_SEND)
#define IRIS_LOG_RECV_PRE  (irisLogLevel & IRIS_LOG_FLAG_RECV_PRE)
#define IRIS_LOG_RECV_POST (irisLogLevel & IRIS_LOG_FLAG_RECV_POST)

#define IRIS_LOG_ASYNC_SEND      (YES && IRIS_LOG_ASYNC_ENABLED)
#define IRIS_LOG_ASYNC_RECV_PRE  (YES && IRIS_LOG_ASYNC_ENABLED)
#define IRIS_LOG_ASYNC_RECV_POST (YES && IRIS_LOG_ASYNC_ENABLED)

#define IRISLogSend(format, ...)     IRIS_LOG_OBJC_MAYBE(IRIS_LOG_ASYNC_SEND, irisLogLevel, \
IRIS_LOG_FLAG_SEND, IRIS_LOG_CONTEXT, format, ##__VA_ARGS__)

#define IRISLogRecvPre(format, ...)  IRIS_LOG_OBJC_MAYBE(IRIS_LOG_ASYNC_RECV_PRE, irisLogLevel, \
IRIS_LOG_FLAG_RECV_PRE, IRIS_LOG_CONTEXT, format, ##__VA_ARGS__)

#define IRISLogRecvPost(format, ...) IRIS_LOG_OBJC_MAYBE(IRIS_LOG_ASYNC_RECV_POST, irisLogLevel, \
IRIS_LOG_FLAG_RECV_POST, IRIS_LOG_CONTEXT, format, ##__VA_ARGS__)

