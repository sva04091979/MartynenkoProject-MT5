namespace Lib{

struct TLogBase{
   enum ELevel{
      INFO,
      WARNING,
      ERROR
   };

public:
   static void Log(const string& _module, ELevel _level, const string& _txt);
   
private:
   static string Level(ELevel _level);
};

void TLogBase::Log(const string& _module, ELevel _level, const string& _txt){
   PrintFormat("==> %s\t%s\t%s", _module, Level(_level), _txt);
}

string TLogBase::Level(ELevel _level){
   switch(_level){
         case INFO: return "INFO";
         case WARNING: return "WARNING";
         case ERROR: return "ERROR" ;
         default: return "<UNKNOWN>";
   }
}

}

#ifdef __LIB_LOG__
#define TOOLS_MODULE "Lib::Tools"
#define TOOLS_INFO(_txt) Lib::TLogBase::Log(TOOLS_MODULE, Lib::TLogBase::INFO, _txt)
#define TOOLS_WARNING(_txt) Lib::TLogBase::Log(TOOLS_MODULE, Lib::TLogBase::WARNING, _txt)
#define TOOLS_ERROR(_txt) Lib::TLogBase::Log(TOOLS_MODULE, Lib::TLogBase::ERROR, _txt)
#else 
#define TOOLS_INFO(_txt)
#define TOOLS_WARNING(_txt)
#define TOOLS_ERROR(_txt)
#endif
