#include "ForthServer.h"

//------------------------------------------------------------------------------
// Main function
//------------------------------------------------------------------------------
int main(int argc, char* argv[]) {
    struct FMState forth_server = CreateForthServer();
    FM_run_file(&forth_server , "server.fth");
    //FM_run_string(&forth_server, ".\" Howdy\" .\" Everyone\" SWAP CONCAT");
    return 0;
}
