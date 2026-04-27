#include "../tools/log.mqh"

#ifdef __LIB_LOG__
#define CHART_MODULE "Lib::Chart"
#define CHART_INFO(_txt) Lib::TLogBase::Log(CHART_MODULE, Lib::TLogBase::INFO, _txt)
#define CHART_WARNING(_txt) Lib::TLogBase::Log(CHART_MODULE, Lib::TLogBase::WARNING, _txt)
#define CHART_ERROR(_txt) Lib::TLogBase::Log(CHART_MODULE, Lib::TLogBase::ERROR, _txt)
#else 
#define CHART_INFO(_txt)
#define CHART_WARNING(_txt)
#define CHART_ERROR(_txt)
#endif
