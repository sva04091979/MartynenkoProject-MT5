#include "../tools/log.mqh"

#ifdef __LIB_LOG__
#define INDICATOR_MODULE "Lib::Indicator"
#define INDICATOR_INFO(_txt) Lib::TLogBase::Log(INDICATOR_MODULE, Lib::TLogBase::INFO, _txt)
#define INDICATOR_WARNING(_txt) Lib::TLogBase::Log(INDICATOR_MODULE, Lib::TLogBase::WARNING, _txt)
#define INDICATOR_ERROR(_txt) Lib::TLogBase::Log(INDICATOR_MODULE, Lib::TLogBase::ERROR, _txt)
#else 
#define INDICATOR_INFO(_txt)
#define INDICATOR_WARNING(_txt)
#define INDICATOR_ERROR(_txt)
#endif
