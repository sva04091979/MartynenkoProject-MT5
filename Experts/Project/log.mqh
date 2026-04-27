#include "lib/tools/log.mqh"

#define PLATFORM_MODULE "Platform"
#define PLATFORM_INFO(_txt) Lib::TLogBase::Log(PLATFORM_MODULE, Lib::TLogBase::INFO, _txt)
#define PLATFORM_WARNING(_txt) Lib::TLogBase::Log(PLATFORM_MODULE, Lib::TLogBase::WARNING, _txt)
#define PLATFORM_ERROR(_txt) Lib::TLogBase::Log(PLATFORM_MODULE, Lib::TLogBase::ERROR, _txt)
