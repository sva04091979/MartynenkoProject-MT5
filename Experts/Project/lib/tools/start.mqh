namespace Lib{

typedef ENUM_INIT_RETCODE(*FooInit)(int);
typedef void(*FooDeinit)(int);

class TStart{
public:
   static ENUM_INIT_RETCODE OnInit(FooInit _foo);
   static void OnDeinit(int _reason, FooDeinit _foo);
private:
   static int deinitReason_;
};

int TStart::deinitReason_ = 0;

ENUM_INIT_RETCODE TStart::OnInit(FooInit _foo){
   return _foo(deinitReason_);
}

void TStart::OnDeinit(int _reason, FooDeinit _foo){
   _foo(_reason);
   deinitReason_ = _reason;
}

}